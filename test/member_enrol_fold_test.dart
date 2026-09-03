// A [[Pendaftaran terlipat]] — an offline enrolment whose number was already
// known (ADR-0129).
//
// The rule under test is ADR-0092's, read back at drain time: the phone number
// **is** the identity, so two dark tills enrolling the same walk-in did not
// create two people. Refusing would be wrong rather than safe — there is nobody
// at the counter left to ask which record to use — so the standing one wins and
// the queue says so in the audit trail.
//
// The audit kind is deliberately its own. `memberMerged` means a person chose
// to merge two records; an owner reading their directory back has to be able to
// tell that from "the queue reconciled these".
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
          ),
        );
  });
  tearDown(() => db.close());

  final captured = DateTime.utc(2026, 9, 1, 19, 30);

  Future<(int, Map<String, dynamic>)> enrol(
    TestCaller caller,
    Map<String, dynamic> body,
  ) async {
    final router = membersRoutes(db, WsHub(), caller.auth).call;
    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/members'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    final out = await res.readAsString();
    return (
      res.statusCode,
      out.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(out) as Map).cast<String, dynamic>(),
    );
  }

  Future<List<String>> auditKinds() async {
    final rows = await db.select(db.auditEntries).get();
    return [for (final r in rows) r.kind ?? ''];
  }

  test('two dark tills enrolling one walk-in leave one member', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );

    final (firstStatus, first) = await enrol(till, {
      'id': 'client-minted-a',
      'name': 'Budi',
      'phone': '081200000501',
      'capturedAt': captured.toIso8601String(),
    });
    expect(firstStatus, 200);
    expect(first['id'], 'client-minted-a');
    expect(first['folded'], false);

    // The other till was dark too, and typed the same number.
    final (secondStatus, second) = await enrol(till, {
      'id': 'client-minted-b',
      'name': 'Budi S',
      'phone': '081200000501',
      'capturedAt': captured.toIso8601String(),
    });
    expect(secondStatus, 200);
    expect(
      second['id'],
      'client-minted-a',
      reason: 'the standing record wins, and the device rewrites its own id',
    );
    expect(second['folded'], true);
    expect(
      second['name'],
      'Budi',
      reason: 'a fold does not write the arrival over the record it folded into',
    );

    final rows = await db.select(db.members).get();
    expect(rows.length, 1);
    expect(
      await auditKinds(),
      containsAll([
        AuditKind.memberCreated.name,
        AuditKind.memberEnrolFoldedAtDrain.name,
      ]),
    );
    expect(
      await auditKinds(),
      isNot(contains(AuditKind.memberMerged.name)),
      reason: 'nobody chose to merge — the queue reconciled it',
    );
  });

  test('a replayed enrolment is the same enrolment', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );
    final body = {
      'id': 'client-minted-c',
      'name': 'Sri',
      'phone': '081200000502',
      'capturedAt': captured.toIso8601String(),
    };

    await enrol(till, body);
    // The first attempt committed and then the socket died, so the drain sends
    // it again. The id is the idempotency key.
    final (status, again) = await enrol(till, body);

    expect(status, 200);
    expect(again['folded'], false);
    expect((await db.select(db.members).get()).length, 1);
    expect(
      (await auditKinds()).where((k) => k == AuditKind.memberCreated.name).length,
      1,
      reason: 'a replay writes no second enrolment row',
    );
  });

  test('an online enrolment still refuses a duplicate number', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.settleBill},
      userId: 'till',
    );
    await createMember(db, name: 'Budi', phone: '081200000503');

    // No `id`, no `capturedAt` — a cashier standing at the counter, who can be
    // offered the standing record instead. Folding here would silently discard
    // the name they just typed.
    final (status, body) = await enrol(till, {
      'name': 'Budi Lain',
      'phone': '081200000503',
    });
    expect(status, 400);
    expect(body['code'], 'phone_taken');
    expect(body['memberId'], isNotNull);
  });
}
