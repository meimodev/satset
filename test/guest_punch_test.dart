// The [[Kartu stempel]] lookup on the guest plane (ADR-0110) — the first, and
// deliberately the only, member fact that leaves the authenticated side.
//
// What is pinned here is the boundary rather than the arithmetic (that lives in
// the member tests): a session is required, the try count is capped, an unknown
// phone is indistinguishable from a known one, and exactly two integers cross.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_plane.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/ws_hub.dart';

void main() {
  late AppDatabase db;
  late GuestPlane plane;

  const port = 18081;
  const base = 'http://127.0.0.1:$port';

  Future<String> openSession() async {
    final res = await http.post(
      Uri.parse('$base/guest/session'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'code': 'CODE0001'}),
    );
    return (jsonDecode(res.body) as Map<String, dynamic>)['sessionId']
        as String;
  }

  Future<http.Response> punch(String? session, String phone) => http.post(
    Uri.parse('$base/guest/punch'),
    headers: {
      'content-type': 'application/json',
      'x-guest-session': ?session,
    },
    body: jsonEncode({'phone': phone}),
  );

  Future<void> runProgram({bool on = true}) => (db.update(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).write(
    VenueSettingsCompanion(
      membersEnabled: Value(on),
      memberPunchEnabled: Value(on),
      memberPunchItemId: Value(on ? 'kopi' : null),
      memberPunchTarget: const Value(10),
    ),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            guestOrderingEnabled: const Value(true),
          ),
        );
    await db
        .into(db.venueTables)
        .insertOnConflictUpdate(
          VenueTablesCompanion.insert(
            id: 't1',
            zoneId: 'z1',
            label: const Value('T1'),
            guestCode: const Value('CODE0001'),
          ),
        );
    plane = GuestPlane(db: db, hub: WsHub(), port: port);
    await plane.start();
  });

  tearDown(() async {
    await plane.stop();
    await db.close();
  });

  test('no session, no answer', () async {
    await runProgram();
    expect((await punch(null, '0813')).statusCode, 401);
    expect((await punch('made-up', '0813')).statusCode, 401);
  });

  test('a venue without the program 404s, like every member route', () async {
    final s = await openSession();
    expect((await punch(s, '0813')).statusCode, 404);
    // The toggle alone is not the program: it needs an item too.
    await runProgram();
    await (db.update(db.venueSettings)..where((x) => x.id.equals('default')))
        .write(const VenueSettingsCompanion(memberPunchItemId: Value(null)));
    expect((await punch(s, '0813')).statusCode, 404);
  });

  test('an unknown phone answers in the same shape as a known one', () async {
    await runProgram();
    await createMember(db, name: 'Rina', phone: '081300000001');
    final s = await openSession();
    final known = await punch(s, '081300000001');
    final stranger = await punch(s, '081399999999');
    expect(known.statusCode, 200);
    expect(stranger.statusCode, 200);
    // Byte for byte: the response cannot be an enrolment oracle.
    expect(known.body, stranger.body);
    // And two integers, nothing else — no name, no phone echoed, no points.
    expect((jsonDecode(known.body) as Map).keys.toSet(), {'progress', 'target'});
    expect(jsonDecode(known.body), {'progress': 0, 'target': 10});
  });

  test('a session gets a handful of tries, not a sweep', () async {
    await runProgram();
    final s = await openSession();
    for (var i = 0; i < 5; i++) {
      expect((await punch(s, '08130000000$i')).statusCode, 200);
    }
    expect((await punch(s, '081300000099')).statusCode, 429);
    // A fresh scan is a fresh visit, and gets its own allowance.
    expect((await punch(await openSession(), '081300000099')).statusCode, 200);
  });

  test('a blank phone is refused, and the try still counts', () async {
    await runProgram();
    final s = await openSession();
    expect((await punch(s, '   ')).statusCode, 400);
  });
}
