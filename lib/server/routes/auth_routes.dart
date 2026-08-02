import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/shift.dart';

/// Staff PIN sessions only. The host admin (the one admin this venue has) is
/// authed in-process, not over HTTP — and since ADR-0077 there is no second
/// admin device to admit, so the old `/auth/admin` ID-token door is gone along
/// with the offline Firebase verifier that guarded it.
Router authRoutes(ServerAuth auth) {
  final r = Router();

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
    final shiftStartedAt = await resumeOrOpenShift(auth.db, session.userId);
    return Response.ok(
      jsonEncode({
        'token': session.token,
        'userId': session.userId,
        'roleId': me?.roleId ?? '',
        'capabilities': caps,
        'expiresAt': session.expiresAt.toIso8601String(),
        'shiftStartedAt': shiftStartedAt.toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  /// Drops the staff session. `{"endShift": true}` additionally closes the
  /// shift — the difference between "Keluar" (hand the handset over, shift
  /// keeps running) and "Akhiri shift & keluar". Both effects land in one
  /// request so there is no window where the session is gone but the shift
  /// is still open. See ADR-0065.
  r.post('/auth/logout', (Request req) async {
    final t = _bearer(req);
    // Resolve before revoking — afterwards the token no longer identifies anyone.
    final user = await auth.resolveBearer(t);
    var alsoEndShift = false;
    try {
      final raw = await req.readAsString();
      if (raw.isNotEmpty) {
        final body = jsonDecode(raw) as Map<String, dynamic>;
        alsoEndShift = body['endShift'] == true;
      }
    } catch (_) {
      // A bodiless or malformed logout is still a logout; it just keeps the
      // shift open, which is the non-destructive reading.
    }
    if (alsoEndShift && user != null) await endShift(auth.db, user.id);
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
    // Read-only: a profile fetch must not *start* a shift, so a stamp older
    // than today's rollover reports as null rather than being re-anchored.
    // Matters on session restore — a token that survives overnight would
    // otherwise hand the client yesterday's clock. Only a login opens a shift.
    final shift = await openShiftOf(auth.db, user.id);
    return Response.ok(
      jsonEncode({
        'userId': user.id,
        'name': user.name,
        'initials': user.initials,
        'roleId': user.roleId,
        'zoneAssigned': user.zoneAssigned,
        'capabilities': caps,
        'avatarColorHex': user.avatarColorHex,
        'shiftStartedAt': shift?.toIso8601String(),
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

