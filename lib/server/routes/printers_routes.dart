import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

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

Map<String, dynamic> _printerJson(Printer p) => {
      'id': p.id,
      'label': p.label,
      'host': p.host,
      'port': p.port,
      'kind': p.kind,
      'enabled': p.enabled,
      'lastSeenAt': p.lastSeenAt?.toIso8601String(),
      'createdAt': p.createdAt.toIso8601String(),
    };

Router printersRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  r.get('/printers', (Request req) async {
    final rows = await db.select(db.printers).get();
    return Response.ok(
      jsonEncode([for (final p in rows) _printerJson(p)]),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/printers', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    await db.into(db.printers).insertOnConflictUpdate(
          PrintersCompanion.insert(
            id: id,
            label: body['label'] as String,
            host: body['host'] as String,
            port: Value((body['port'] as num?)?.toInt() ?? 9100),
            kind: Value((body['kind'] as String?) ?? 'escpos'),
            enabled: Value((body['enabled'] as bool?) ?? true),
            createdAt: DateTime.now(),
          ),
        );
    final row = await (db.select(db.printers)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub.broadcast(WsEventTypes.printerCreated, _printerJson(row));
    return Response.ok(jsonEncode(_printerJson(row)),
        headers: {'content-type': 'application/json'});
  });

  r.patch('/printers/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await (db.update(db.printers)..where((p) => p.id.equals(id))).write(
      PrintersCompanion(
        label: body.containsKey('label')
            ? Value(body['label'] as String)
            : const Value.absent(),
        host: body.containsKey('host')
            ? Value(body['host'] as String)
            : const Value.absent(),
        port: body.containsKey('port')
            ? Value((body['port'] as num).toInt())
            : const Value.absent(),
        kind: body.containsKey('kind')
            ? Value(body['kind'] as String)
            : const Value.absent(),
        enabled: body.containsKey('enabled')
            ? Value(body['enabled'] as bool)
            : const Value.absent(),
        lastSeenAt: body.containsKey('lastSeenAt')
            ? Value(body['lastSeenAt'] == null
                ? null
                : DateTime.tryParse(body['lastSeenAt'] as String))
            : const Value.absent(),
      ),
    );
    final row = await (db.select(db.printers)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('printer not found');
    hub.broadcast(WsEventTypes.printerUpdated, _printerJson(row));
    return Response.ok(jsonEncode(_printerJson(row)),
        headers: {'content-type': 'application/json'});
  });

  r.delete('/printers/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    await (db.delete(db.printers)..where((p) => p.id.equals(id))).go();
    hub.broadcast(WsEventTypes.printerDeleted, {'id': id});
    return Response.ok(jsonEncode({'id': id}),
        headers: {'content-type': 'application/json'});
  });

  // Stub: a future change will dispatch a real ESC/POS test page. For now,
  // log + bump lastSeenAt so the System screen flips the row to "Online".
  r.post('/printers/<id>/test', (Request req, String id) async {
    final row = await (db.select(db.printers)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('printer not found');
    SatLog.srv('printer test id=$id host=${row.host}:${row.port}');
    final now = DateTime.now();
    await (db.update(db.printers)..where((p) => p.id.equals(id))).write(
      PrintersCompanion(lastSeenAt: Value(now)),
    );
    final updated =
        await (db.select(db.printers)..where((p) => p.id.equals(id)))
            .getSingleOrNull();
    if (updated != null) {
      hub.broadcast(WsEventTypes.printerUpdated, _printerJson(updated));
    }
    return Response.ok(
      jsonEncode({'status': 'queued', 'at': now.toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
