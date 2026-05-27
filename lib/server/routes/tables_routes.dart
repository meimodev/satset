import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';

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

  // Admin CRUD: create / update / delete tables. Floor management requires
  // editSettings. WS broadcasts keep every client in sync.
  r.post('/tables', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    final capacity = (body['capacity'] as num?)?.toInt() ?? 2;
    final paxIn = (body['pax'] as num?)?.toInt() ?? 0;
    await db.into(db.venueTables).insertOnConflictUpdate(
          VenueTablesCompanion.insert(
            id: id,
            zoneId: body['zoneId'] as String,
            label: Value(body['label'] as String?),
            pax: Value(paxIn.clamp(0, capacity)),
            capacity: Value(capacity < 1 ? 1 : capacity),
            active: Value((body['active'] as bool?) ?? true),
          ),
        );
    final row =
        await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub.broadcast(WsEventTypes.tableCreated, _toJson(row));
    return Response.ok(jsonEncode(_toJson(row)),
        headers: {'content-type': 'application/json'});
  });

  r.patch('/tables/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    // Capacity changes can shrink below the current pax; clamp pax down
    // in the same write so we never leave pax > capacity.
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    int? nextCap;
    if (body.containsKey('capacity')) {
      final c = (body['capacity'] as num).toInt();
      nextCap = c < 1 ? 1 : c;
    }
    int? nextPax;
    if (body.containsKey('pax')) {
      nextPax = (body['pax'] as num).toInt();
    }
    final effectiveCap = nextCap ?? row.capacity;
    if (nextPax != null) {
      nextPax = nextPax.clamp(0, effectiveCap);
    } else if (nextCap != null && row.pax > effectiveCap) {
      nextPax = effectiveCap;
    }
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        label: body.containsKey('label')
            ? Value(body['label'] as String?)
            : const Value.absent(),
        pax: nextPax == null ? const Value.absent() : Value(nextPax),
        capacity:
            nextCap == null ? const Value.absent() : Value(nextCap),
        zoneId: body.containsKey('zoneId')
            ? Value(body['zoneId'] as String)
            : const Value.absent(),
        active: body.containsKey('active')
            ? Value(body['active'] as bool)
            : const Value.absent(),
      ),
    );
    return _broadcast(db, hub, id);
  });

  r.delete('/tables/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    await (db.delete(db.venueTables)..where((t) => t.id.equals(id))).go();
    hub.broadcast(WsEventTypes.tableDeleted, {'id': id});
    return Response.ok(jsonEncode({'id': id}),
        headers: {'content-type': 'application/json'});
  });

  r.patch('/tables/<id>/pax', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final pax = (body['pax'] as num).toInt();
    final actorId = body['actorId'] as String?;
    // Clamp to [1, capacity] server-side; the UI gates this too but never
    // trust client clamping for a multi-device flow.
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    final clamped = pax.clamp(0, row.capacity < 1 ? 1 : row.capacity);
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        pax: Value(clamped),
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

  // Acquire (or refresh own) lock. Returns 409 with current holder payload
  // when another active session holds the table. Lease length is supplied by
  // the client; default 30s.
  r.post('/tables/<id>/lock', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final userId = body['userId'] as String?;
    final userName = body['userName'] as String?;
    if (userId == null || userId.isEmpty) {
      return Response(400,
          body: jsonEncode({'code': 'bad_request', 'message': 'userId required'}),
          headers: {'content-type': 'application/json'});
    }
    final ttl = (body['ttlSeconds'] as num?)?.toInt() ?? 7;
    final now = DateTime.now();
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    final held = row.lockedBy != null &&
        row.lockedBy!.isNotEmpty &&
        row.lockedBy != userId &&
        row.lockExpiresAt != null &&
        row.lockExpiresAt!.isAfter(now);
    if (held) {
      return Response(409,
          body: jsonEncode({
            'code': 'table_locked',
            'message': 'table is locked by another user',
            'table': _toJson(row),
          }),
          headers: {'content-type': 'application/json'});
    }
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        lockedBy: Value(userId),
        lockedByName: Value(userName),
        lockedAt: Value(now),
        lockExpiresAt: Value(now.add(Duration(seconds: ttl))),
      ),
    );
    return _broadcast(db, hub, id);
  });

  // Refresh the lease. 409 when the caller isn't the current holder so the
  // client can drop into read-only mode immediately.
  r.post('/tables/<id>/lock/heartbeat', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final userId = body['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return Response(400,
          body: jsonEncode({'code': 'bad_request', 'message': 'userId required'}),
          headers: {'content-type': 'application/json'});
    }
    final ttl = (body['ttlSeconds'] as num?)?.toInt() ?? 7;
    final now = DateTime.now();
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    if (row.lockedBy != userId) {
      return Response(409,
          body: jsonEncode({
            'code': 'lock_lost',
            'message': 'caller is not the current lock holder',
            'table': _toJson(row),
          }),
          headers: {'content-type': 'application/json'});
    }
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        lockExpiresAt: Value(now.add(Duration(seconds: ttl))),
      ),
    );
    return _broadcast(db, hub, id);
  });

  // Release the lock. Idempotent: a stale caller (already lost the lease)
  // still gets 200 so dispose paths never throw. The caller is resolved from
  // the bearer token so DELETE doesn't need a request body.
  r.delete('/tables/<id>/lock', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    String? userId;
    if (auth != null) {
      final token = req.headers['authorization']
          ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
      final user = await auth.resolveBearer(token);
      userId = user?.id;
    }
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    if (userId != null && row.lockedBy != null && row.lockedBy != userId) {
      // Different user holds it — nothing to release on our side. Echo the
      // current row so the caller can sync its view.
      return Response.ok(jsonEncode(_toJson(row)),
          headers: {'content-type': 'application/json'});
    }
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      const VenueTablesCompanion(
        lockedBy: Value(null),
        lockedByName: Value(null),
        lockedAt: Value(null),
        lockExpiresAt: Value(null),
      ),
    );
    return _broadcast(db, hub, id);
  });

  // Settle + close: snapshots the session into TableSessions(+children),
  // hard-deletes the live tickets, then returns the table to `available`.
  // Guarded by takeOrder; UI gates this behind "all tickets terminal".
  r.post('/tables/<id>/close', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = await req.readAsString();
    final actorId = body.isEmpty
        ? null
        : (jsonDecode(body) as Map<String, dynamic>)['actorId'] as String?;
    String? sessionIdForBroadcast;
    await db.transaction(() async {
      final tableRow = await (db.select(db.venueTables)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (tableRow == null) return;
      final tickets = await (db.select(db.tickets)
            ..where((t) => t.tableId.equals(id)))
          .get();
      final now = DateTime.now().toUtc();
      final openedAt = tableRow.openedAt;
      final durationSec = openedAt == null
          ? 0
          : now.difference(openedAt).inSeconds.clamp(0, 1 << 31);
      var subtotal = 0;
      var voidAmount = 0;
      for (final t in tickets) {
        final line = t.price * t.qty;
        if (t.status == 'void') {
          voidAmount += line;
        } else {
          subtotal += line;
        }
      }
      final sessionId = _uuid.v4();
      sessionIdForBroadcast = sessionId;
      await db.into(db.tableSessions).insert(TableSessionsCompanion.insert(
            id: sessionId,
            tableId: tableRow.id,
            tableLabel: Value(tableRow.label),
            zoneId: tableRow.zoneId,
            pax: Value(tableRow.pax),
            openedAt: Value(openedAt),
            closedAt: now,
            durationSec: Value(durationSec),
            actorUserId: Value(actorId),
            subtotal: Value(subtotal),
            voidAmount: Value(voidAmount),
            netTotal: Value(subtotal),
            ticketCount: Value(tickets.length),
          ));
      for (final t in tickets) {
        await db.into(db.tableSessionTickets).insert(
              TableSessionTicketsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                ticketId: t.id,
                itemId: t.itemId,
                name: t.name,
                variantName: Value(t.variantName),
                course: t.course,
                station: t.station,
                qty: Value(t.qty),
                modifiersJson: Value(t.modifiersJson),
                specialInstructions: Value(t.specialInstructions),
                price: t.price,
                status: t.status,
                sentAt: t.sentAt,
                voidReason: Value(t.voidReason),
                voidApprovedBy: Value(t.voidApprovedBy),
                createdByUserId: Value(t.createdByUserId),
              ),
            );
      }
      final byCourse = <String, List<Ticket>>{};
      for (final t in tickets) {
        byCourse.putIfAbsent(t.course, () => []).add(t);
      }
      for (final entry in byCourse.entries) {
        final courseTickets = entry.value;
        DateTime? firedAt;
        DateTime? servedAt;
        for (final t in courseTickets) {
          if (firedAt == null || t.sentAt.isBefore(firedAt)) {
            firedAt = t.sentAt;
          }
          if (t.status == 'served') {
            if (servedAt == null || t.sentAt.isAfter(servedAt)) {
              servedAt = t.sentAt;
            }
          }
        }
        await db.into(db.tableSessionCourses).insert(
              TableSessionCoursesCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                courseId: entry.key,
                firedAt: Value(firedAt),
                servedAt: Value(servedAt),
                ticketCount: Value(courseTickets.length),
              ),
            );
      }
      await (db.delete(db.tickets)..where((t) => t.tableId.equals(id))).go();
      await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
        VenueTablesCompanion(
          status: const Value('available'),
          openAmount: const Value(0),
          readyCount: const Value(0),
          pax: const Value(0),
          lastActorId:
              actorId == null ? const Value.absent() : Value(actorId),
          lockedBy: const Value(null),
          lockedByName: const Value(null),
          lockedAt: const Value(null),
          lockExpiresAt: const Value(null),
          openedAt: const Value(null),
        ),
      );
    });
    if (sessionIdForBroadcast != null) {
      hub.broadcast(WsEventTypes.tableSessionClosed, {
        'tableId': id,
        'sessionId': sessionIdForBroadcast,
      });
    }
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
      'capacity': t.capacity,
      'active': t.active,
      'status': t.status,
      'openAmount': t.openAmount,
      'readyCount': t.readyCount,
      'lastActorId': t.lastActorId,
      'lockedBy': t.lockedBy,
      'lockedByName': t.lockedByName,
      'lockedAt': t.lockedAt?.toIso8601String(),
      'lockExpiresAt': t.lockExpiresAt?.toIso8601String(),
      'openedAt': t.openedAt?.toIso8601String(),
    };
