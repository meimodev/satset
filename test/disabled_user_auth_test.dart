// Disabling a staff member has to reach the device already in their hand.
//
// `signInWithPin` has always filtered on `disabled`, so a disabled member
// could not get a *new* token. The token they were already holding was a
// different question, and the answer was that it kept working for the rest of
// its twelve hours. Two things close that: `resolveBearer` checks the flag,
// and the route that sets it drops their sessions.
//
// Amends ADR-0102 — every route factory takes a non-null `ServerAuth`, and
// this is what that auth owes the caller in return.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reference_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> setDisabled(
    Router router,
    TestCaller admin,
    String userId,
    bool disabled,
  ) async {
    final res = await router.call(
      Request(
        'PATCH',
        Uri.parse('http://localhost/staff/$userId'),
        headers: {...admin.headers, 'content-type': 'application/json'},
        body: jsonEncode({'disabled': disabled}),
      ),
    );
    expect(res.statusCode, 200, reason: await res.readAsString());
  }

  test('a live bearer stops resolving the moment its user is disabled', () async {
    final caller = await signInForTest(db, userId: 'maya');
    final auth = caller.auth;

    expect(
      await auth.resolveBearer(caller.token),
      isNotNull,
      reason: 'a signed-in member resolves',
    );

    await (db.update(db.users)..where((u) => u.id.equals('maya'))).write(
      const UsersCompanion(disabled: Value(true)),
    );

    expect(
      await auth.resolveBearer(caller.token),
      isNull,
      reason: 'the token they already hold is no longer good for anything',
    );
  });

  test('disabling through the route drops their sessions', () async {
    final admin = await signInForTest(db, userId: 'admin');
    final maya = await signInForTest(db, userId: 'maya');
    // Both users share one ServerAuth in a real server; the helper builds one
    // each, so resolve through the admin's to prove it is the row that went.
    final auth = admin.auth;

    expect(
      await (db.select(
        db.sessions,
      )..where((s) => s.userId.equals('maya'))).get(),
      hasLength(1),
    );

    final router = referenceRoutes(db, null, auth);
    await setDisabled(router, admin, 'maya', true);

    expect(
      await (db.select(
        db.sessions,
      )..where((s) => s.userId.equals('maya'))).get(),
      isEmpty,
      reason: 'the session row is gone, not merely ignored',
    );
    expect(await auth.resolveBearer(maya.token), isNull);
  });

  test('re-enabling does not resurrect the old token', () async {
    final admin = await signInForTest(db, userId: 'admin');
    final maya = await signInForTest(db, userId: 'maya');
    final auth = admin.auth;
    final router = referenceRoutes(db, null, auth);

    await setDisabled(router, admin, 'maya', true);
    await setDisabled(router, admin, 'maya', false);

    expect(
      await auth.resolveBearer(maya.token),
      isNull,
      reason: 'a revoked session stays revoked; they sign in again',
    );
  });

  test('disabling one member leaves everyone else signed in', () async {
    final admin = await signInForTest(db, userId: 'admin');
    final budi = await signInForTest(
      db,
      userId: 'budi',
      caps: {Capability.takeOrder},
    );
    await signInForTest(db, userId: 'maya');
    final auth = admin.auth;
    final router = referenceRoutes(db, null, auth);

    await setDisabled(router, admin, 'maya', true);

    expect(await auth.resolveBearer(budi.token), isNotNull);
    expect(await auth.resolveBearer(admin.token), isNotNull);
  });
}
