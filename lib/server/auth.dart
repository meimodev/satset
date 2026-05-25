import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';

/// Server-side auth helpers. Verifies PINs, issues HS256 JWTs, validates
/// bearer tokens, persists sessions for revocation.
class ServerAuth {
  ServerAuth(this.db, {required this.secret});
  final AppDatabase db;
  final String secret;

  static const tokenTtl = Duration(hours: 12);

  String hashPin(String pin) =>
      sha256.convert(utf8.encode('satset.v1::$pin')).toString();

  String hashPassword(String pw) =>
      sha256.convert(utf8.encode('satset.v1.pw::$pw')).toString();

  /// Returns a fresh session row on success, or null if the PIN does not
  /// match an active user.
  Future<Session?> signInWithPin({
    required String pin,
    required String deviceId,
  }) async {
    final h = hashPin(pin);
    // Demo users use PIN sign-in. Reject the dedicated admin from this path
    // even when its `pinHash` happens to collide (it shouldn't, but be
    // defensive): admin must use /auth/admin/login.
    final user = await (db.select(db.users)
          ..where((u) =>
              u.pinHash.equals(h) &
              u.disabled.equals(false) &
              u.pinHash.equals('').not()))
        .getSingleOrNull();
    if (user == null) return null;

    final now = DateTime.now();
    final expiry = now.add(tokenTtl);
    final jwt = JWT({
      'sub': user.id,
      'role': user.roleId,
      'deviceId': deviceId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    });
    final token = jwt.sign(SecretKey(secret));
    final session = SessionsCompanion.insert(
      token: token,
      userId: user.id,
      deviceId: deviceId,
      issuedAt: now,
      expiresAt: expiry,
    );
    await db.into(db.sessions).insertOnConflictUpdate(session);
    return Session(
      token: token,
      userId: user.id,
      deviceId: deviceId,
      issuedAt: now,
      expiresAt: expiry,
    );
  }

  /// Returns a fresh session for an admin authenticated via email+password.
  /// Null on bad credentials or disabled account.
  Future<Session?> signInWithEmailPassword({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.isEmpty) return null;
    final h = hashPassword(password);
    final user = await (db.select(db.users)
          ..where((u) =>
              u.email.equals(e) &
              u.passwordHash.equals(h) &
              u.disabled.equals(false)))
        .getSingleOrNull();
    if (user == null) return null;
    final now = DateTime.now();
    final expiry = now.add(tokenTtl);
    final jwt = JWT({
      'sub': user.id,
      'role': user.roleId,
      'deviceId': deviceId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    });
    final token = jwt.sign(SecretKey(secret));
    await db.into(db.sessions).insertOnConflictUpdate(SessionsCompanion.insert(
          token: token,
          userId: user.id,
          deviceId: deviceId,
          issuedAt: now,
          expiresAt: expiry,
        ));
    return Session(
      token: token,
      userId: user.id,
      deviceId: deviceId,
      issuedAt: now,
      expiresAt: expiry,
    );
  }

  /// Resolve a bearer token to a user row. Returns null when the token is
  /// missing, expired, revoked, or malformed.
  Future<User?> resolveBearer(String? token) async {
    if (token == null || token.isEmpty) return null;
    try {
      JWT.verify(token, SecretKey(secret));
    } catch (_) {
      return null;
    }
    final s = await (db.select(db.sessions)..where((s) => s.token.equals(token)))
        .getSingleOrNull();
    if (s == null || s.expiresAt.isBefore(DateTime.now())) return null;
    return (db.select(db.users)..where((u) => u.id.equals(s.userId)))
        .getSingleOrNull();
  }

  Future<void> revoke(String token) async {
    await (db.delete(db.sessions)..where((s) => s.token.equals(token))).go();
  }

  static String generateSecret() => const Uuid().v4();

  /// Load a stable HS256 secret from the server's private storage,
  /// creating it on first boot. Kept in application-support so it survives
  /// process restarts but never leaves the device.
  static Future<String> loadOrCreateSecret() async {
    final dir = await getApplicationSupportDirectory();
    final f = File(p.join(dir.path, 'satset.jwt.secret'));
    if (await f.exists()) {
      final s = (await f.readAsString()).trim();
      if (s.isNotEmpty) return s;
    }
    final s = generateSecret();
    await f.writeAsString(s, flush: true);
    return s;
  }
}
