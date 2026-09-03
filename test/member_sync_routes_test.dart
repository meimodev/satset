// The [[Salinan pelanggan]] over the wire (ADR-0129).
//
// Four things are pinned here, and each of them is a way the mirror goes wrong
// silently rather than loudly:
//
// 1. **The masking is per capability.** A device that may only take orders gets
//    no number, and a till gets the whole record. Get this wrong and the venue's
//    customer list is on the most-lost hardware in the building — which is the
//    exact risk ADR-0129 accepted only for the till.
// 2. **The cursor converges.** A device that keeps calling with the cursor it
//    was given sees every change once. A row that falls between two pages is
//    a member who is simply missing from a handset forever.
// 3. **A departure travels.** `members` has no soft delete, so without the
//    tombstone stream a dark device offers a person the venue has forgotten.
// 4. **The switch is a 404**, like membership itself — a client cannot tell an
//    unmirrored venue from a server that never had the route.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/member.dart' show normalizePhone;
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/member_sync.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/members_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
          ),
        );
  });
  tearDown(() => db.close());

  Future<(int, Map<String, dynamic>)> sync(
    TestCaller caller, {
    String? since,
    int? limit,
  }) async {
    final router = membersRoutes(db, WsHub(), caller.auth).call;
    final q = <String>[
      if (since != null) 'since=${Uri.encodeQueryComponent(since)}',
      if (limit != null) 'limit=$limit',
    ].join('&');
    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/members/sync${q.isEmpty ? '' : '?$q'}'),
        headers: caller.headers,
      ),
    );
    final body = await res.readAsString();
    return (
      res.statusCode,
      body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map).cast<String, dynamic>(),
    );
  }

  List<Map<String, dynamic>> members(Map<String, dynamic> page) => [
    for (final m in page['members'] as List) (m as Map).cast<String, dynamic>(),
  ];

  test('a till gets the number and a handset gets a hash', () async {
    await createMember(db, name: 'Budi', phone: '081200000199');
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
    );

    final (tillStatus, tillPage) = await sync(till);
    expect(tillStatus, 200);
    expect(tillPage['masked'], false);
    expect(members(tillPage).single['phone'], normalizePhone('081200000199'));
    expect(
      tillPage['salt'],
      isNull,
      reason: 'a caller that gets numbers has nothing to hash',
    );

    final (waiterStatus, waiterPage) = await sync(waiter);
    expect(waiterStatus, 200);
    expect(waiterPage['masked'], true);
    final row = members(waiterPage).single;
    expect(row['phone'], '');
    expect(row['phoneTail'], '0199');
    expect(row['note'], isNull);
    expect(row['birthday'], isNull);
    final salt = waiterPage['salt'] as String;
    expect(salt, isNotEmpty);
    // The hash is the search key: typing the whole number on the handset has
    // to find the same person the till sees.
    expect(row['phoneHash'], memberPhoneHash('081200000199', salt));
  });

  test('reporting alone does not open the mirror', () async {
    final reader = await signInForTest(
      db,
      caps: {Capability.viewReports},
      userId: 'reader',
    );
    expect(
      (await sync(reader)).$1,
      403,
      reason: 'a reporting screen reads live; it keeps no copy on disk',
    );
  });

  test('the cursor walks every change exactly once', () async {
    for (var i = 0; i < 5; i++) {
      await createMember(db, name: 'M$i', phone: '08120000010$i');
    }
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );

    final seen = <String>[];
    String? cursor;
    var pages = 0;
    while (pages < 10) {
      final (status, page) = await sync(till, since: cursor, limit: 2);
      expect(status, 200);
      seen.addAll([for (final m in members(page)) m['id'] as String]);
      cursor = page['cursor'] as String?;
      pages++;
      if (page['hasMore'] != true) break;
    }
    expect(seen.length, 5);
    expect(seen.toSet().length, 5, reason: 'no row is handed out twice');

    // And a device that is already caught up is told so rather than handed the
    // directory again.
    final (_, quiet) = await sync(till, since: cursor);
    expect(members(quiet), isEmpty);
    expect(quiet['hasMore'], false);
  });

  test('a delete and a merge both reach the device', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill, Capability.manageMembers},
      userId: 'till',
    );
    final gone = await createMember(db, name: 'Pergi', phone: '081200000201');
    final absorbed = await createMember(db, name: 'Dobel', phone: '081200000202');
    final survivor = await createMember(db, name: 'Asli', phone: '081200000203');

    final (_, first) = await sync(till);
    final cursor = first['cursor'] as String?;

    await deleteMember(db, id: gone.id);
    await mergeMembers(db, fromId: absorbed.id, toId: survivor.id);

    final (status, page) = await sync(till, since: cursor);
    expect(status, 200);
    final tombs = {
      for (final t in page['gone'] as List)
        (t as Map)['id'] as String: (t)['mergedInto'] as String?,
    };
    expect(tombs[gone.id], isNull, reason: 'a delete points nowhere');
    expect(
      tombs[absorbed.id],
      survivor.id,
      reason: 'a merge names the survivor so a local reference can follow it',
    );
  });

  test('a point movement re-syncs the member', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );
    final m = await createMember(db, name: 'Budi', phone: '081200000301');
    final (_, first) = await sync(till);
    final cursor = first['cursor'] as String?;

    await adjustPoints(db, memberId: m.id, delta: 40, note: 'koreksi');

    final (_, page) = await sync(till, since: cursor);
    final row = members(page).single;
    expect(
      row['points'],
      40,
      reason:
          'a balance is SUM(delta) and the mirror carries it, so the ledger '
          'writer must stamp the member or the copy never re-reads it',
    );
  });

  test('the switch answers 404, not 403', () async {
    await createMember(db, name: 'Budi', phone: '081200000401');
    await db
        .update(db.venueSettings)
        .write(const VenueSettingsCompanion(memberMirrorEnabled: Value(false)));
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );
    final (status, body) = await sync(till);
    expect(status, 404);
    expect(body['code'], 'member_mirror_disabled');
  });
}
