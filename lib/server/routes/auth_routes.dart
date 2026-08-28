import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/audit_log.dart';
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
    // A device the admin revoked is out of service, and a correct PIN does
    // not put it back. Checked before the PIN so a revoked device cannot use
    // this door to probe which PINs are live.
    if (await auth.deviceRevoked(deviceId)) {
      return Response(
        403,
        body: jsonEncode({
          'code': 'device_revoked',
          'message': 'device revoked',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    // Guessing costs time, and the time doubles (ADR-0112). Asked before the
    // PIN is verified, so a device serving out its wait cannot keep the host
    // tablet busy hashing — the scan is O(staff) PBKDF2 rounds, which is the
    // one expensive thing on this route.
    final wait = auth.pinThrottle(deviceId);
    if (wait != null) {
      return Response(
        429,
        body: jsonEncode({
          'code': 'too_many_attempts',
          'message': 'too many attempts',
          'retryAfterMs': wait.inMilliseconds,
        }),
        headers: {
          'content-type': 'application/json',
          'retry-after': '${(wait.inMilliseconds / 1000).ceil()}',
        },
      );
    }
    final session = await auth.signInWithPin(pin: pin, deviceId: deviceId);
    if (session == null) {
      final attempt = auth.notePinFailure(deviceId);
      // Audited without an actor, because a wrong PIN names nobody — that is
      // the whole reason the row exists. The device and the attempt number are
      // what make a run of them legible; the PIN tried is never written.
      await writeAudit(
        auth.db,
        type: AuditType.signInFailed,
        kind: AuditKind.signInFailed,
        params: {'device': deviceId, 'attempt': '$attempt'},
      );
      return Response(
        401,
        body: jsonEncode({'code': 'invalid_pin', 'message': 'PIN salah'}),
        headers: {'content-type': 'application/json'},
      );
    }
    // Somebody who knows the PIN is not guessing.
    auth.notePinSuccess(deviceId);
    final me = await auth.resolveBearer(session.token);
    final role = me == null
        ? null
        : await (auth.db.select(
            auth.db.roles,
          )..where((r) => r.id.equals(me.roleId))).getSingleOrNull();
    final caps = role == null
        ? const <String>[]
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
    final shiftStartedAt = await openShift(auth.db, session.userId);
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

  /// Drops the staff session **and closes the shift** — one and the same act
  /// since ADR-0097. Both effects land in one request so there is no window
  /// where the session is gone but the shift is still open.
  ///
  /// There is no longer a body: the old `{"endShift": true}` field chose
  /// between the two exits, and there is only one exit now.
  r.post('/auth/logout', (Request req) async {
    final t = _bearer(req);
    // Resolve before revoking — afterwards the token no longer identifies anyone.
    final user = await auth.resolveBearer(t);
    if (user != null) await endShift(auth.db, user.id);
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
    // A profile fetch must never *start* a shift — only a login does that. It
    // does retire a forgotten one: a row left open past its own rollover is
    // closed here and reports as null, so a token that survives overnight
    // cannot hand the client yesterday's clock.
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
        // Says the null above is an answer, not a shrug — see `MeDto`.
        'shiftTracked': true,
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
