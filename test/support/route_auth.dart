import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';

/// A signed-in caller for route tests.
///
/// Every route factory takes a non-null [ServerAuth] (ADR-0102) — a route that
/// cannot identify its caller refuses it, and there is no "no auth configured"
/// path that waves everyone through. A test that exercises a route therefore
/// signs in like a client does.
class TestCaller {
  TestCaller(this.auth, this.token, this.userId);

  final ServerAuth auth;
  final String token;
  final String userId;

  Map<String, String> get headers => {'authorization': 'Bearer $token'};
}

/// Seed a role holding [caps] (every capability by default), a user on it, and
/// sign in. Returns the auth helper the router wants plus the bearer token.
/// [pin] defaults to one derived from [userId], because `signInWithPin` looks
/// a user up *by PIN hash* with `getSingleOrNull` — two users sharing a PIN
/// makes sign-in throw for both of them, not merely pick the wrong one. A test
/// that signs in two callers must give them different PINs.
Future<TestCaller> signInForTest(
  AppDatabase db, {
  Set<Capability>? caps,
  String userId = 'test-user',
  String? pin,
}) async {
  pin ??= '${userId.hashCode.abs() % 900000 + 100000}';
  final auth = ServerAuth(db, secret: 'test-secret');
  final granted = caps ?? Capability.values.toSet();
  await db
      .into(db.roles)
      .insertOnConflictUpdate(
        RolesCompanion.insert(
          id: 'role-$userId',
          name: 'Role $userId',
          capabilitiesJson: Value(
            jsonEncode([for (final c in granted) c.name]),
          ),
        ),
      );
  await db
      .into(db.users)
      .insertOnConflictUpdate(
        UsersCompanion.insert(
          id: userId,
          name: userId,
          initials: userId.substring(0, 2).toUpperCase(),
          roleId: 'role-$userId',
          pinHash: auth.hashPin(pin),
        ),
      );
  final session = await auth.signInWithPin(pin: pin, deviceId: 'dev-$userId');
  return TestCaller(auth, session!.token, userId);
}
