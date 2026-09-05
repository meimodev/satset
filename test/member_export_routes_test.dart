// The membership exports over the wire (ADR-0137).
//
// The whole point of these three routes is that they answer with the cap
// lifted, so what is pinned here is the difference between them and the reads
// they mirror:
//
// 1. `/members/export` returns rows past the directory's 500, and is matched
//    before `/members/<id>` rather than being read as a member called "export".
// 2. It gates `manageMembers` alone — narrower than `GET /members`, which the
//    till and the booking form also read. A `takeOrder` device is refused here
//    before masking is even a question (ADR-0129).
// 3. It writes exactly one audit row. The two report exports write none.
// 4. Past the ceiling every one of them **refuses** rather than truncating,
//    which is the failure the whole design exists to avoid.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/audit_kind.dart';
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
          ),
        );
  });
  tearDown(() => db.close());

  final now = DateTime.now().toUtc();

  /// Straight into the table rather than through [createMember]: these tests
  /// need hundreds or thousands of rows and none of them care about the
  /// enrolment path, which has its own tests.
  Future<void> seedMembers(int n) => db.batch((b) {
    b.insertAll(db.members, [
      for (var i = 0; i < n; i++)
        MembersCompanion.insert(
          id: 'm$i',
          name: 'Member $i',
          // Unique and phone-shaped; the column is indexed unique.
          phone: '0812${i.toString().padLeft(7, '0')}',
          joinedAt: now.subtract(const Duration(days: 30)),
        ),
    ]);
  });

  /// A settled bill, which is the only thing that gives a member a
  /// `lastVisitAt` — it is derived from trade, never a column (ADR-0129).
  Future<void> closeBill(String id, String memberId, int daysAgo) => db
      .into(db.tableSessions)
      .insert(
        TableSessionsCompanion.insert(
          id: id,
          tableId: 't1',
          zoneId: 'z1',
          closedAt: now.subtract(Duration(days: daysAgo)),
          memberId: Value(memberId),
          settledTotal: const Value(100000),
          kind: const Value('dineIn'),
        ),
      );

  Future<(int, dynamic)> get(TestCaller caller, String path) async {
    final router = membersRoutes(db, WsHub(), caller.auth).call;
    final res = await router(
      Request('GET', Uri.parse('http://x$path'), headers: caller.headers),
    );
    final body = await res.readAsString();
    return (res.statusCode, body.isEmpty ? null : jsonDecode(body));
  }

  test('the export reaches past the directory cap', () async {
    final caller = await signInForTest(db);
    await seedMembers(501);

    // The screen's own read stops at 500 no matter what it asks for — which is
    // exactly why exporting from loaded state would ship a short file.
    final (capStatus, capped) = await get(caller, '/members?limit=99999');
    expect(capStatus, 200);
    expect((capped as List).length, 500);

    final (status, all) = await get(caller, '/members/export');
    expect(status, 200);
    expect((all as List).length, 501);
  });

  test('the export arm is not read as a member called "export"', () async {
    final caller = await signInForTest(db);
    await seedMembers(1);
    final (status, body) = await get(caller, '/members/export');
    expect(status, 200);
    expect(body, isA<List>(), reason: 'a member-by-id answer is a Map');
  });

  test('taking the roster is the directory keeper alone', () async {
    await seedMembers(1);
    final keeper = await signInForTest(
      db,
      caps: {Capability.manageMembers},
      userId: 'keeper',
    );
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

    expect((await get(keeper, '/members/export')).$1, 200);
    // Both of these read `GET /members` happily. Finding one guest at the till
    // is not taking the customer list off the device.
    expect((await get(till, '/members/export')).$1, 403);
    expect(
      (await get(waiter, '/members/export')).$1,
      403,
      reason: 'a masked device must not reach an unmasked file',
    );
  });

  test('the export carries the filters the screen is holding', () async {
    final caller = await signInForTest(db);
    await db.batch((b) {
      b.insertAll(db.members, [
        MembersCompanion.insert(
          id: 'recent',
          name: 'Datang',
          phone: '081200000001',
          joinedAt: now,
        ),
        MembersCompanion.insert(
          id: 'lapsed',
          name: 'Hilang',
          phone: '081200000002',
          joinedAt: now,
        ),
      ]);
    });
    await closeBill('s-recent', 'recent', 2);
    await closeBill('s-lapsed', 'lapsed', 200);

    final (status, rows) = await get(caller, '/members/export?lapsedDays=90');
    expect(status, 200);
    expect((rows as List).length, 1);
    expect((rows.single as Map)['id'], 'lapsed');
  });

  test('the roster export audits itself; the report exports do not', () async {
    final caller = await signInForTest(db);
    await seedMembers(3);

    await get(caller, '/members/export');
    await get(caller, '/members/report/export?range=d30');
    await get(caller, '/members/m0/report/export?range=d30');

    final rows = await db.select(db.auditEntries).get();
    expect(rows.length, 1);
    expect(rows.single.kind, AuditKind.memberDirectoryExported.name);
    expect(
      jsonDecode(rows.single.params ?? '{}'),
      containsPair('rows', '3'),
    );
  });

  test('the ranked export drops the truncation count', () async {
    final caller = await signInForTest(db);
    await seedMembers(1);

    final (_, screen) = await get(caller, '/members/report?range=d30');
    expect((screen as Map).containsKey('membersTruncated'), isTrue);

    final (status, file) = await get(caller, '/members/report/export?range=d30');
    expect(status, 200);
    expect(
      (file as Map).containsKey('membersTruncated'),
      isFalse,
      reason: 'on an uncapped payload it could only ever say zero',
    );
  });

  test('the report exports open to either reporting or keeping', () async {
    await seedMembers(1);
    final reader = await signInForTest(
      db,
      caps: {Capability.viewReports},
      userId: 'reader',
    );
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'waiter',
    );

    expect((await get(reader, '/members/report/export')).$1, 200);
    expect((await get(reader, '/members/m0/report/export')).$1, 200);
    expect((await get(waiter, '/members/report/export')).$1, 403);
    expect((await get(waiter, '/members/m0/report/export')).$1, 403);
  });

  test('membership off hides the exports like every other member route',
      () async {
    final caller = await signInForTest(db);
    await db
        .update(db.venueSettings)
        .write(const VenueSettingsCompanion(membersEnabled: Value(false)));

    for (final path in [
      '/members/export',
      '/members/report/export',
      '/members/anyone/report/export',
    ]) {
      final (status, body) = await get(caller, path);
      expect(status, 404, reason: path);
      expect((body as Map)['code'], 'members_disabled');
    }
  });

  test('past the ceiling it refuses instead of truncating', () async {
    final caller = await signInForTest(db);
    await seedMembers(kMemberExportMax + 1);

    final (status, body) = await get(caller, '/members/export');
    expect(status, 413);
    expect((body as Map)['code'], 'export_too_large');
    expect(
      body['limit'],
      kMemberExportMax,
      reason: 'the refusal names the ceiling so the copy can suggest a fix',
    );
    // And nothing was filed: a refused export is not an export.
    expect(await db.select(db.auditEntries).get(), isEmpty);
  });
}
