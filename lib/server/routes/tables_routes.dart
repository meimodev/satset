import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';

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

Router tablesRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  // Read-only: any authenticated user can list tables.
  r.get('/tables', (Request req) async {
    final rows = await db.select(db.venueTables).get();
    return Response.ok(
      jsonEncode([for (final t in rows) _toJson(t)]),
      headers: {'content-type': 'application/json'},
    );
  });

  r.patch('/tables/<id>/pax', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final pax = (body['pax'] as num).toInt();
    final actorId = body['actorId'] as String?;
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        pax: Value(pax),
        lastActorId: actorId == null ? const Value.absent() : Value(actorId),
      ),
    );
    return _broadcast(db, hub, id);
  });

  r.patch('/tables/<id>/handler', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final userId = body['userId'] as String?;
    await (db.update(db.venueTables)..where((t) => t.id.equals(id)))
        .write(VenueTablesCompanion(lastActorId: Value(userId)));
    return _broadcast(db, hub, id);
  });

  r.post('/tables/<id>/pending', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final actorId = body['actorId'] as String?;
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        status: const Value('pending'),
        lastActorId: actorId == null ? const Value.absent() : Value(actorId),
      ),
    );
    return _broadcast(db, hub, id);
  });

  r.post('/tables/<id>/ready/decrement', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>?;
    final actorId = body == null ? null : body['actorId'] as String?;
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    final n = (row.readyCount - 1).clamp(0, 1 << 30);
    // When the last `ready` item is cleared the table moves back to
    // `occupied` so the floor view does not strand a stale ready badge.
    final nextStatus =
        (row.status == 'ready' && n == 0) ? 'occupied' : row.status;
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        readyCount: Value(n),
        status: Value(nextStatus),
        lastActorId: actorId == null ? const Value.absent() : Value(actorId),
      ),
    );
    return _broadcast(db, hub, id);
  });

  return r;
}

Future<Response> _broadcast(AppDatabase db, WsHub hub, String id) async {
  final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
  if (row == null) return Response.notFound('table not found');
  hub.broadcast(WsEventTypes.tableUpdated, _toJson(row));
  return Response.ok(jsonEncode(_toJson(row)),
      headers: {'content-type': 'application/json'});
}

Map<String, dynamic> _toJson(VenueTable t) => {
      'id': t.id,
      'zoneId': t.zoneId,
      'label': t.label,
      'pax': t.pax,
      'active': t.active,
      'status': t.status,
      'openAmount': t.openAmount,
      'readyCount': t.readyCount,
      'lastActorId': t.lastActorId,
    };
