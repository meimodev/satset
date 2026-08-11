import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';
import 'shift.dart';

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
    // defensive): the venue's one admin is authed in-process by Firebase,
    // never by PIN (ADR-0077).
    final user =
        await (db.select(db.users)..where(
              (u) =>
                  u.pinHash.equals(h) &
                  u.disabled.equals(false) &
                  u.pinHash.equals('').not(),
            ))
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

  /// Provision (or refresh) the local admin user row bound to a Firebase
  /// [firebaseUid]. All Firebase admins map to the shared admin role; per-uid
  /// rows exist only for audit identity. Capabilities stay local — never
  /// carried by Firebase. Returns the local userId. See ADR-0015.
  Future<String> provisionAdminUser({
    required String firebaseUid,
    required String name,
    int? avatarColorHex,
  }) async {
    final cleanName = name.trim();
    final initials = _initialsFor(cleanName);
    final existing = await (db.select(
      db.users,
    )..where((u) => u.firebaseUid.equals(firebaseUid))).getSingleOrNull();
    if (existing != null) {
      await (db.update(db.users)..where((u) => u.id.equals(existing.id))).write(
        UsersCompanion(
          name: Value(cleanName.isEmpty ? existing.name : cleanName),
          initials: Value(cleanName.isEmpty ? existing.initials : initials),
          avatarColorHex: Value(avatarColorHex),
          roleId: Value(adminRoleId),
          disabled: const Value(false),
        ),
      );
      return existing.id;
    }
    final id = const Uuid().v4();
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: id,
            name: cleanName.isEmpty ? 'Admin' : cleanName,
            initials: initials.isEmpty ? 'AD' : initials,
            roleId: adminRoleId,
            pinHash: '',
            firebaseUid: Value(firebaseUid),
            avatarColorHex: Value(avatarColorHex),
          ),
        );
    return id;
  }

  /// Mint a session + JWT for an already-resolved local [userId]. Used by the
  /// in-process admin sign-in (no HTTP, no token round-trip — same process,
  /// same device, loopback only). See ADR-0015.
  ///
  /// **Opens the shift too**, because a shift *is* a signed-in session
  /// (ADR-0096) and this path never touches `POST /auth/login`, where the other
  /// one is opened. Without it the host's own attendance is the only attendance
  /// the report cannot see — and the app bar still counted up, off a local
  /// fallback stamp, so nothing on screen said the row was missing.
  Future<Session> mintSession({
    required String userId,
    required String deviceId,
  }) async {
    final user = await (db.select(
      db.users,
    )..where((u) => u.id.equals(userId))).getSingle();
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
    await db
        .into(db.sessions)
        .insertOnConflictUpdate(
          SessionsCompanion.insert(
            token: token,
            userId: user.id,
            deviceId: deviceId,
            issuedAt: now,
            expiresAt: expiry,
          ),
        );
    await openShift(db, user.id);
    return Session(
      token: token,
      userId: user.id,
      deviceId: deviceId,
      issuedAt: now,
      expiresAt: expiry,
    );
  }

  static const adminRoleId = 'role-admin';

  static String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final letters = parts.map((p) => p[0].toUpperCase()).take(2).join();
    return letters;
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
    final s = await (db.select(
      db.sessions,
    )..where((s) => s.token.equals(token))).getSingleOrNull();
    if (s == null || s.expiresAt.isBefore(DateTime.now())) return null;
    return (db.select(
      db.users,
    )..where((u) => u.id.equals(s.userId))).getSingleOrNull();
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
