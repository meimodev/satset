// Revoking a device has to mean the device stops working, not that it loses
// the token it currently holds.
//
// `POST /devices/<id>/revoke` set the flag and dropped the sessions, which is
// the second half. The first half was missing: nothing asked the flag again.
// A revoked handset could sign in with any live PIN a second later, and could
// re-pair through `/pair/auto-claim` — the unauthenticated LAN door — and be
// told it succeeded. Both doors ask now.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/auth_routes.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pairDevice(String id, {bool revoked = false}) async {
    await db
        .into(db.devices)
        .insertOnConflictUpdate(
          DevicesCompanion.insert(
            id: id,
            label: id,
            publicKeyPem: '',
            pairedAt: DateTime.now(),
            revoked: Value(revoked),
          ),
        );
  }

  Future<Response> login(ServerAuth auth, String pin, String deviceId) =>
      authRoutes(auth).call(
        Request(
          'POST',
          Uri.parse('http://localhost/auth/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'pin': pin, 'deviceId': deviceId}),
        ),
      );

  test('a revoked device is refused a session, correct PIN and all', () async {
    final caller = await signInForTest(db, userId: 'maya', pin: '246813');
    await pairDevice('dev-maya', revoked: true);

    final res = await login(caller.auth, '246813', 'dev-maya');

    expect(res.statusCode, 403);
    expect(
      jsonDecode(await res.readAsString())['code'],
      'device_revoked',
      reason: 'not invalid_pin — the PIN was right, the handset is out',
    );
  });

  test('the same PIN still works on a device that was never revoked', () async {
    final caller = await signInForTest(db, userId: 'maya', pin: '246813');
    await pairDevice('dev-maya', revoked: true);
    await pairDevice('dev-spare');

    final res = await login(caller.auth, '246813', 'dev-spare');

    expect(res.statusCode, 200, reason: await res.readAsString());
  });

  test('a device id with no row at all is not revoked', () async {
    // The host signs in on a device that never paired with itself.
    final caller = await signInForTest(db, userId: 'maya', pin: '246813');
    expect(await caller.auth.deviceRevoked('never-seen'), isFalse);
    expect((await login(caller.auth, '246813', 'never-seen')).statusCode, 200);
  });

  test('the revoked check runs before the PIN is looked at', () async {
    // Otherwise the login door tells a revoked handset which PINs are live.
    final caller = await signInForTest(db, userId: 'maya', pin: '246813');
    await pairDevice('dev-maya', revoked: true);

    final res = await login(caller.auth, '000000', 'dev-maya');

    expect(res.statusCode, 403);
    expect(jsonDecode(await res.readAsString())['code'], 'device_revoked');
  });

  test('revoking survives the upsert that re-pairing would run', () async {
    // `/pair/auto-claim` is unauthenticated by design (ADR-0080) and upserts
    // the row. The companion never names `revoked`, so the flag has to still
    // be true afterwards — this pins the property the 403 in `server.dart`
    // depends on, without booting a TLS listener to ask it.
    await pairDevice('dev-maya', revoked: true);
    await db
        .into(db.devices)
        .insertOnConflictUpdate(
          DevicesCompanion.insert(
            id: 'dev-maya',
            label: 'satset-client',
            publicKeyPem: '',
            pairedAt: DateTime.now(),
          ),
        );

    final row = await (db.select(
      db.devices,
    )..where((d) => d.id.equals('dev-maya'))).getSingle();
    expect(row.revoked, isTrue);
  });
}
