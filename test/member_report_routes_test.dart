// The member report over the wire (ADR-0119).
//
// Three things are pinned here that no unit test can reach:
//
// 1. `/members/report` is matched **before** `/members/<id>` — the word
//    "report" is a legal member id as far as shelf_router is concerned, and the
//    day the arms swap order the report answers 404 and nothing says why.
// 2. `range=all` resolves to an open window on this route and only this route,
//    so "Semua" really does reach the venue's first bill.
// 3. The drill answers for a **deleted** member, where `GET /members/<id>`
//    correctly 404s. That difference is the whole of ADR-0092 read back: the
//    person is gone, the trade the venue did is not.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart' hide Member;
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
            memberPointsEnabled: const Value(true),
            memberPointValue: const Value(1000),
          ),
        );
  });
  tearDown(() => db.close());

  final now = DateTime.now().toUtc();

  Future<void> closeBill(
    String id, {
    required String memberId,
    required int daysAgo,
    int settled = 100000,
  }) => db
      .into(db.tableSessions)
      .insert(
        TableSessionsCompanion.insert(
          id: id,
          tableId: 't1',
          zoneId: 'z1',
          closedAt: now.subtract(Duration(days: daysAgo)),
          memberId: Value(memberId),
          settledTotal: Value(settled),
          kind: const Value('dineIn'),
        ),
      );

  Future<(int, Map<String, dynamic>)> get(
    TestCaller caller,
    String path,
  ) async {
    final router = membersRoutes(db, WsHub(), caller.auth).call;
    final res = await router(
      Request('GET', Uri.parse('http://x$path'), headers: caller.headers),
    );
    final body = await res.readAsString();
    return (
      res.statusCode,
      body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map).cast<String, dynamic>(),
    );
  }

  test('the report route is not swallowed by the member-by-id arm', () async {
    final caller = await signInForTest(db);
    final m = await createMember(db, name: 'Budi', phone: '08120000001');
    await closeBill('s1', memberId: m.id, daysAgo: 1);

    final (status, body) = await get(caller, '/members/report?range=d7');
    expect(status, 200);
    expect(body['members'], isA<List>());
    expect(body['activeMembers'], 1);
    // The by-id arm still works, and still means a member.
    final (idStatus, _) = await get(caller, '/members/${m.id}');
    expect(idStatus, 200);
  });

  test('either reporting or keeping the directory opens it', () async {
    final reader = await signInForTest(
      db,
      caps: {Capability.viewReports},
      userId: 'reader',
    );
    final keeper = await signInForTest(
      db,
      caps: {Capability.manageMembers},
      userId: 'keeper',
    );
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
    );

    expect((await get(reader, '/members/report')).$1, 200);
    expect((await get(keeper, '/members/report')).$1, 200);
    expect(
      (await get(waiter, '/members/report')).$1,
      403,
      reason: 'taking orders is not reading what the venue earned',
    );
  });

  test('range=all reaches past every capped window', () async {
    final caller = await signInForTest(db);
    final m = await createMember(db, name: 'Budi', phone: '08120000001');
    // Well outside the 92-day cap the accounting report enforces.
    await closeBill('s-old', memberId: m.id, daysAgo: 400, settled: 40000);
    await closeBill('s-new', memberId: m.id, daysAgo: 1, settled: 60000);

    final (_, narrow) = await get(caller, '/members/report?range=d30');
    expect(narrow['memberNet'], 60000);

    final (_, wide) = await get(caller, '/members/report?range=all');
    expect(wide['memberNet'], 100000);
    expect(
      wide['earliestClosedAt'],
      isNotNull,
      reason: 'an open window labels itself with the venue\'s real first day',
    );
  });

  test('a deleted member keeps a history where the record 404s', () async {
    final caller = await signInForTest(db);
    final m = await createMember(db, name: 'Budi', phone: '08120000001');
    await closeBill('s1', memberId: m.id, daysAgo: 1, settled: 80000);
    await deleteMember(db, id: m.id);

    final (recordStatus, _) = await get(caller, '/members/${m.id}');
    expect(recordStatus, 404, reason: 'the person is gone');

    final (reportStatus, body) = await get(
      caller,
      '/members/${m.id}/report?range=all',
    );
    expect(reportStatus, 200, reason: 'the trade is not');
    expect(body['spend'], 80000);
    expect(
      body['member'],
      isNull,
      reason: 'no directory row to carry lifetime figures — the client says so',
    );
  });

  test('the whole feature 404s when the program is off', () async {
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(false),
          ),
        );
    final caller = await signInForTest(db);
    expect(
      (await get(caller, '/members/report')).$1,
      404,
      reason: 'a client cannot tell an opted-out venue from an old server',
    );
  });
}
