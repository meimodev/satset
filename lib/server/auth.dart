import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';
import 'pin.dart' as pin_lib;
import 'shift.dart';
import 'package:satset/core/time/sat_clock.dart';

/// Server-side auth helpers. Verifies PINs, issues HS256 JWTs, validates
/// bearer tokens, persists sessions for revocation.
class ServerAuth {
  ServerAuth(this.db, {required this.secret});
  final AppDatabase db;
  final String secret;

  static const tokenTtl = Duration(hours: 12);

  /// Wrong guesses, per device, since the last success or the last restart.
  ///
  /// In memory on purpose. A restart clears it, and a restart is a physical act
  /// by somebody holding the host tablet — an attacker on the LAN cannot
  /// perform one, and a manager who genuinely needs the wait gone can.
  final Map<String, ({int count, DateTime last})> _pinFails = {};

  /// Two fat fingers are free. A waiter mid-rush gets no penalty for the
  /// mistake everybody makes; the third try is where guessing starts.
  static const pinFreeAttempts = 2;

  /// The ceiling on the doubling. A minute a guess turns a million candidates
  /// into two years, which is enough — and it is short enough that a member of
  /// staff who genuinely forgot can wait it out rather than needing a manager.
  static const pinMaxBackoff = Duration(seconds: 60);

  /// How long [deviceId] must wait before its next PIN is looked at, or null
  /// when it may try now.
  ///
  /// There is deliberately **no lockout** (ADR-0112): on a shared floor device
  /// a lockout is a denial of service anyone can perform on a colleague
  /// mid-service, in an app whose whole promise is working when other things
  /// do not. The clock is the whole defence.
  Duration? pinThrottle(String deviceId, {DateTime? now}) {
    final f = _pinFails[deviceId];
    if (f == null || f.count <= pinFreeAttempts) return null;
    final steps = f.count - pinFreeAttempts - 1;
    final delay = Duration(
      seconds: steps >= 6 ? pinMaxBackoff.inSeconds : 1 << steps,
    );
    final capped = delay > pinMaxBackoff ? pinMaxBackoff : delay;
    final waited = (now ?? SatClock.realNow()).difference(f.last);
    final left = capped - waited;
    return left > Duration.zero ? left : null;
  }

  /// Count a wrong PIN. Returns which attempt it was, for the audit row.
  int notePinFailure(String deviceId, {DateTime? now}) {
    final f = _pinFails[deviceId];
    final count = (f?.count ?? 0) + 1;
    _pinFails[deviceId] = (count: count, last: now ?? SatClock.realNow());
    return count;
  }

  /// A right PIN clears the slate. The throttle exists to price guessing, and
  /// somebody who knows the PIN is not guessing.
  void notePinSuccess(String deviceId) => _pinFails.remove(deviceId);

  /// Hash a PIN for storage. Delegates to [pin_lib.hashPin] — the one hasher
  /// (ADR-0112) — and is kept here only because the routes already reach for
  /// auth to do it.
  String hashPin(String pin) => pin_lib.hashPin(pin);

  String hashPassword(String pw) =>
      sha256.convert(utf8.encode('satset.v1.pw::$pw')).toString();

  /// Every candidate a PIN could belong to. Delegates to [pin_lib.usersForPin]
  /// — the one scanner (ADR-0112) — and is kept here because the routes
  /// already reach for auth to ask PIN questions.
  Future<List<User>> usersForPin(String pin, {bool onlyEnabled = true}) =>
      pin_lib.usersForPin(db, pin, onlyEnabled: onlyEnabled);

  /// The single user [pin] identifies, or null when it identifies none — or
  /// more than one. See [pin_lib.userForPin].
  Future<User?> userForPin(String pin, {bool onlyEnabled = true}) =>
      pin_lib.userForPin(db, pin, onlyEnabled: onlyEnabled);

  /// Whether a device the admin took out of service is asking for something.
  ///
  /// Revoking a device drops the sessions it holds, which is the whole of what
  /// revocation used to mean — the device could sign in again with any valid
  /// PIN a second later, or re-pair through `/pair/auto-claim` and get a fresh
  /// row. Both doors ask this now. An id with no row at all is *not* revoked:
  /// the host device signs in before it has ever paired with itself.
  Future<bool> deviceRevoked(String deviceId) async {
    if (deviceId.isEmpty) return false;
    final dev = await (db.select(
      db.devices,
    )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
    return dev?.revoked ?? false;
  }

  /// Returns a fresh session row on success, or null if the PIN does not
  /// match an active user.
  Future<Session?> signInWithPin({
    required String pin,
    required String deviceId,
  }) async {
    final user = await userForPin(pin);
    if (user == null) return null;

    final now = SatClock.realNow();
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
  /// (ADR-0097) and this path never touches `POST /auth/login`, where the other
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
    final now = SatClock.realNow();
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
  /// missing, expired, revoked, malformed, or belongs to a disabled user.
  ///
  /// The disabled check is not redundant with the one in [signInWithPin].
  /// That one stops a disabled member getting a *new* token; this one stops
  /// the token they already hold, which otherwise stays good for the rest of
  /// its twelve hours. [revokeAllFor] closes the same hole from the other
  /// side, but a session row is not the only way a token can be presented, so
  /// the check lives here too — the row is the cache, the flag is the truth.
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
    if (s == null || s.expiresAt.isBefore(SatClock.realNow())) return null;
    return (db.select(db.users)
          ..where((u) => u.id.equals(s.userId) & u.disabled.equals(false)))
        .getSingleOrNull();
  }

  Future<void> revoke(String token) async {
    await (db.delete(db.sessions)..where((s) => s.token.equals(token))).go();
  }

  /// Drop every live session a user holds. Called when they are disabled, so
  /// the device in their hand stops working now rather than whenever its
  /// token happens to expire.
  Future<void> revokeAllFor(String userId) async {
    await (db.delete(db.sessions)..where((s) => s.userId.equals(userId))).go();
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
