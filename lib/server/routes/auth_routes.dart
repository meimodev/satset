import 'dart:convert';
import 'package:satset/server/demo_clock.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/firebase_token_verifier.dart';

/// [venueId] is this host's cloud venue (ADR-0017); [verifier] admits
/// admin-clients by their Firebase ID token. Both are empty/no-op on a legacy
/// un-gated server, which simply rejects `/auth/admin`.
Router authRoutes(
  ServerAuth auth, {
  String venueId = '',
  FirebaseTokenVerifier? verifier,
}) {
  final r = Router();

  // The host admin (the Main Device operator) is authed in-process — no HTTP.
  // OTHER admins of the same venue join over the LAN as admin-clients via
  // `/auth/admin`: they present a Firebase ID token, the host verifies it
  // offline (custom claims {role, venueId}) and issues a local admin JWT. The
  // local server stays the capability authority. See ADR-0017.
  r.post('/auth/admin', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final idToken = (body['idToken'] as String?) ?? '';
    final deviceId = (body['deviceId'] as String?) ?? '';
    if (idToken.isEmpty || deviceId.isEmpty) {
      return _err(400, 'bad_request', 'idToken+deviceId required');
    }
    if (venueId.isEmpty || verifier == null) {
      return _err(
        409,
        'no_venue_scope',
        'This server is not venue-scoped and cannot admit admins',
      );
    }
    final v = await verifier.verify(idToken);
    if (v == null) {
      return _err(401, 'invalid_token', 'Firebase token tidak valid');
    }
    if (v.role != 'admin' && v.role != 'super') {
      return _err(403, 'not_admin', 'Akun ini bukan admin');
    }
    if (v.venueId != venueId) {
      SatLog.srv('auth.admin wrong-venue token=${v.venueId} host=$venueId');
      return _err(403, 'wrong_venue', 'Admin bukan dari venue ini');
    }
    final userId = await auth.provisionAdminUser(
      firebaseUid: v.uid,
      name: v.name.isEmpty ? 'Admin' : v.name,
    );
    final session = await auth.mintSession(userId: userId, deviceId: deviceId);
    final me = await auth.resolveBearer(session.token);
    final role = me == null
        ? null
        : await (auth.db.select(
            auth.db.roles,
          )..where((rr) => rr.id.equals(me.roleId))).getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    SatLog.srv('auth.admin ok uid=${v.uid} venue=$venueId');
    return Response.ok(
      jsonEncode({
        'token': session.token,
        'userId': session.userId,
        'roleId': me?.roleId ?? '',
        'capabilities': caps,
        'expiresAt': session.expiresAt.toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/auth/login', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final pin = (body['pin'] as String?) ?? '';
    final deviceId = (body['deviceId'] as String?) ?? '';
    if (pin.isEmpty || deviceId.isEmpty) {
      return Response(
        400,
        body: jsonEncode({
          'code': 'bad_request',
          'message': 'pin+deviceId required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final session = await auth.signInWithPin(pin: pin, deviceId: deviceId);
    if (session == null) {
      return Response(
        401,
        body: jsonEncode({'code': 'invalid_pin', 'message': 'PIN salah'}),
        headers: {'content-type': 'application/json'},
      );
    }
    final me = await auth.resolveBearer(session.token);
    final role = me == null
        ? null
        : await (auth.db.select(
            auth.db.roles,
          )..where((r) => r.id.equals(me.roleId))).getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return Response.ok(
      jsonEncode({
        'token': session.token,
        'userId': session.userId,
        'roleId': me?.roleId ?? '',
        'capabilities': caps,
        'expiresAt': session.expiresAt.toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/auth/logout', (Request req) async {
    final t = _bearer(req);
    if (t != null) await auth.revoke(t);
    return Response(204);
  });

  /// User ids with a live [[Shift|staff session]] right now — sign-out deletes
  /// the session row, so this is "who could actually hear a cue".
  ///
  /// Exists for the "Belum dilayani" escalation (ADR-0044): the first cue is
  /// routed to the seating waiter, and if that waiter is signed out the cue
  /// must go floor-wide *immediately* rather than waiting out the escalation
  /// delay for a device that will never play it. Any authenticated staff
  /// member may read it — it carries no capability or identity detail beyond
  /// ids the caller already sees on the floor.
  r.get('/auth/online', (Request req) async {
    final user = await auth.resolveBearer(_bearer(req));
    if (user == null) return Response(401);
    final now = SatClock.now();
    final rows = await auth.db.select(auth.db.sessions).get();
    final live = rows
        .where((s) => s.expiresAt.isAfter(now))
        .map((s) => s.userId)
        .toSet()
        .toList();
    return Response.ok(
      jsonEncode({'userIds': live}),
      headers: {'content-type': 'application/json'},
    );
  });

  r.get('/auth/me', (Request req) async {
    final t = _bearer(req);
    final user = await auth.resolveBearer(t);
    if (user == null) {
      return Response(401);
    }
    final role = await (auth.db.select(
      auth.db.roles,
    )..where((rr) => rr.id.equals(user.roleId))).getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    return Response.ok(
      jsonEncode({
        'userId': user.id,
        'name': user.name,
        'initials': user.initials,
        'roleId': user.roleId,
        'zoneAssigned': user.zoneAssigned,
        'capabilities': caps,
        'avatarColorHex': user.avatarColorHex,
        // Demo clock offset (ADR-0053 §2). Rides the bootstrap as well as the
        // WS broadcast so a device that missed the event — or reconnected
        // after one — recovers the right clock on its own (ADR-0021).
        'demoClockOffsetSeconds': DemoClock.offsetSeconds(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}

String? _bearer(Request req) {
  final h = req.headers['authorization'];
  if (h == null) return null;
  if (!h.toLowerCase().startsWith('bearer ')) return null;
  return h.substring(7).trim();
}

Response _err(int status, String code, String message) => Response(
  status,
  body: jsonEncode({'code': code, 'message': message}),
  headers: {'content-type': 'application/json'},
);
