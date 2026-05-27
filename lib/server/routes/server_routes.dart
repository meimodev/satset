import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/server.dart';

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
  final token = req.headers['authorization']
      ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(db.roles)
        ..where((r) => r.id.equals(user.roleId)))
      .getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(403,
        body: jsonEncode({
          'code': 'forbidden',
          'message': 'missing capability ${needed.name}',
        }),
        headers: {'content-type': 'application/json'});
  }
  return null;
}

/// Lightweight runtime status surface for the System screen. Read-only.
Map<String, dynamic> buildServerStatus(ServerRuntime rt) {
  final stats = rt.latencyStats;
  return {
    'startedAt': rt.startedAt.toIso8601String(),
    'uptimeMs': rt.uptime.inMilliseconds,
    'listenAddress': '0.0.0.0',
    'port': rt.port,
    'tlsCertExpiry': rt.tls.certExpiry.toIso8601String(),
    'tlsCertIssuedAt': rt.tls.certIssuedAt.toIso8601String(),
    'tlsFingerprint': rt.tls.fingerprint,
    'requestCountRecent': stats.requestCountRecent,
    'p50LatencyMs': stats.p50,
    'p95LatencyMs': stats.p95,
  };
}

Future<Map<String, dynamic>> buildServerStatusWithCounts(
  ServerRuntime rt,
) async {
  final now = DateTime.now();
  final activeSessions = await rt.db.customSelect(
    'SELECT COUNT(*) AS c FROM sessions WHERE expires_at > ?',
    variables: [Variable.withDateTime(now)],
  ).getSingle();
  final pairedDevices = await rt.db.customSelect(
    'SELECT COUNT(*) AS c FROM devices WHERE revoked = 0',
  ).getSingle();
  return {
    ...buildServerStatus(rt),
    'activeSessions': activeSessions.read<int>('c'),
    'pairedDevices': pairedDevices.read<int>('c'),
  };
}

Router serverRoutes(ServerRuntime rt) {
  final r = Router();

  // Any authenticated user can read status (the auth middleware enforces
  // the bearer token outside this router).
  r.get('/server/status', (Request req) async {
    final body = await buildServerStatusWithCounts(rt);
    return Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  });

  // Restart requires manageStaff. Kicks the restart in a microtask so the
  // 202 response can flush before the listener closes.
  r.post('/server/restart', (Request req) async {
    final denied =
        await _requireCap(req, rt.db, rt.auth, Capability.manageStaff);
    if (denied != null) return denied;
    // Notify everyone *before* the request returns; the listener tears
    // down right after this response is written.
    rt.hub.broadcast(WsEventTypes.serverRestarting, {
      'at': DateTime.now().toIso8601String(),
    });
    scheduleMicrotask(() => rt.restart());
    return Response(
      202,
      body: jsonEncode({
        'status': 'restarting',
        'fingerprint': rt.tls.fingerprint,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
