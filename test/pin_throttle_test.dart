// A wrong PIN costs time, and the time doubles (ADR-0112).
//
// The login route is on the LAN, answers in milliseconds and would happily
// take a million requests — which is under a day for a six-digit space. The
// clock is the whole defence: there is deliberately no lockout, because on a
// shared floor device a lockout is a denial of service anybody can perform on
// a colleague mid-rush.
//
// Timing is injected rather than waited on, so nothing here sleeps.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/auth_routes.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Response> login(ServerAuth auth, String pin, String deviceId) =>
      authRoutes(auth).call(
        Request(
          'POST',
          Uri.parse('http://localhost/auth/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'pin': pin, 'deviceId': deviceId}),
        ),
      );

  group('the backoff curve', () {
    late ServerAuth auth;
    final t0 = DateTime(2026, 8, 22, 9);

    setUp(() async {
      auth = (await signInForTest(db, userId: 'maya', pin: '246813')).auth;
    });

    test('two fat fingers are free', () {
      expect(auth.pinThrottle('dev', now: t0), isNull);
      auth.notePinFailure('dev', now: t0);
      expect(auth.pinThrottle('dev', now: t0), isNull);
      auth.notePinFailure('dev', now: t0);
      expect(
        auth.pinThrottle('dev', now: t0),
        isNull,
        reason: 'the mistake everybody makes carries no penalty',
      );
    });

    test('the third try starts the clock, and it doubles', () {
      const expected = [1, 2, 4, 8, 16, 32, 60, 60];
      for (var i = 0; i < ServerAuth.pinFreeAttempts; i++) {
        auth.notePinFailure('dev', now: t0);
      }
      for (final seconds in expected) {
        auth.notePinFailure('dev', now: t0);
        expect(
          auth.pinThrottle('dev', now: t0)?.inSeconds,
          seconds,
          reason: 'after ${ServerAuth.pinFreeAttempts} free ones',
        );
      }
    });

    test('the wait is capped at a minute, not raised forever', () {
      for (var i = 0; i < 40; i++) {
        auth.notePinFailure('dev', now: t0);
      }
      expect(auth.pinThrottle('dev', now: t0), ServerAuth.pinMaxBackoff);
    });

    test('waiting it out clears the wait', () {
      for (var i = 0; i < ServerAuth.pinFreeAttempts + 1; i++) {
        auth.notePinFailure('dev', now: t0);
      }
      expect(auth.pinThrottle('dev', now: t0)?.inSeconds, 1);
      expect(
        auth.pinThrottle('dev', now: t0.add(const Duration(seconds: 2))),
        isNull,
      );
    });

    test('a right PIN clears the slate', () {
      for (var i = 0; i < 10; i++) {
        auth.notePinFailure('dev', now: t0);
      }
      expect(auth.pinThrottle('dev', now: t0), isNotNull);
      auth.notePinSuccess('dev');
      expect(auth.pinThrottle('dev', now: t0), isNull);
    });

    test('one device serving its wait does not throttle the next table', () {
      for (var i = 0; i < 10; i++) {
        auth.notePinFailure('dev-a', now: t0);
      }
      expect(auth.pinThrottle('dev-a', now: t0), isNotNull);
      expect(auth.pinThrottle('dev-b', now: t0), isNull);
    });
  });

  group('through the login route', () {
    test('a run of wrong PINs earns a 429, and never a lockout', () async {
      final auth = (await signInForTest(db, userId: 'maya', pin: '246813')).auth;

      for (var i = 0; i <= ServerAuth.pinFreeAttempts; i++) {
        expect((await login(auth, '000000', 'dev')).statusCode, 401);
      }
      final res = await login(auth, '000000', 'dev');
      expect(res.statusCode, 429);
      final body = jsonDecode(await res.readAsString()) as Map;
      expect(body['code'], 'too_many_attempts');
      expect(body['retryAfterMs'], greaterThan(0));
      expect(res.headers['retry-after'], isNotNull);

      // No lockout: the throttle is a clock, so the right PIN opens the door
      // the moment the wait is over. Clearing the counter stands in for the
      // wait, which is the same state the wait leaves behind.
      auth.notePinSuccess('dev');
      expect((await login(auth, '246813', 'dev')).statusCode, 200);
    });

    test('a wrong PIN is audited with the device and the attempt', () async {
      final auth = (await signInForTest(db, userId: 'maya', pin: '246813')).auth;

      await login(auth, '000000', 'dev-front');
      await login(auth, '111111', 'dev-front');

      final rows = await (db.select(
        db.auditEntries,
      )..where((a) => a.kind.equals(AuditKind.signInFailed.name))).get();
      expect(rows, hasLength(2));
      final params = rows
          .map((r) => jsonDecode(r.params ?? '{}') as Map<String, dynamic>)
          .toList();
      expect(params.map((p) => p['attempt']), ['1', '2']);
      expect(params.every((p) => p['device'] == 'dev-front'), isTrue);
      expect(
        rows.every((r) => r.actorUserId == null),
        isTrue,
        reason: 'a wrong PIN names nobody — that is the point of the row',
      );
      expect(
        rows.every((r) => !(r.params ?? '').contains('000000')),
        isTrue,
        reason: 'the PIN tried is never written down',
      );
    });

    test('the throttle answers before any hashing happens', () async {
      // The scan is O(staff) PBKDF2 rounds. A throttled device must not be
      // able to keep the host tablet busy with it.
      final auth = (await signInForTest(db, userId: 'maya', pin: '246813')).auth;
      for (var i = 0; i <= ServerAuth.pinFreeAttempts; i++) {
        await login(auth, '000000', 'dev');
      }
      final before = await db.select(db.auditEntries).get();
      final res = await login(auth, '000000', 'dev');
      expect(res.statusCode, 429);
      final after = await db.select(db.auditEntries).get();
      expect(
        after.length,
        before.length,
        reason: 'a refused attempt is not a counted one',
      );
    });
  });
}
