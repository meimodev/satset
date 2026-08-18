import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth auth,
  Capability needed,
) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(
      403,
      body: jsonEncode({
        'code': 'forbidden',
        'message': 'missing capability ${needed.name}',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  return null;
}

Router devicesRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  /// Read-only list of paired devices joined with each device's most-recent
  /// session (if any). The System screen consumes this to render the
  /// "Perangkat aktif" card. `sessionActive` is true when the latest session
  /// has not yet expired.
  r.get('/devices', (Request req) async {
    final now = SatClock.now();
    final devices = await db.select(db.devices).get();
    final result = <Map<String, dynamic>>[];
    for (final d in devices) {
      final last =
          await (db.select(db.sessions)
                ..where((s) => s.deviceId.equals(d.id))
                ..orderBy([(s) => OrderingTerm.desc(s.issuedAt)])
                ..limit(1))
              .getSingleOrNull();
      result.add({
        'id': d.id,
        'label': d.label,
        'pairedAt': d.pairedAt.toIso8601String(),
        'revoked': d.revoked,
        'lastSessionAt': last?.issuedAt.toIso8601String(),
        'lastSessionUserId': last?.userId,
        'sessionActive': last != null && last.expiresAt.isAfter(now),
      });
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  });

  // Revoke a paired device. Drops every session belonging to it so the
  // bearer token cannot be reused.
  r.post('/devices/<id>/revoke', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    await (db.update(db.devices)..where((d) => d.id.equals(id))).write(
      const DevicesCompanion(revoked: Value(true)),
    );
    await (db.delete(db.sessions)..where((s) => s.deviceId.equals(id))).go();
    hub.broadcast(WsEventTypes.deviceRevoked, {'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
