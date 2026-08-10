import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/domain/models/capability.dart';

const _allowedStatuses = {'pending', 'seated', 'noShow', 'cancelled'};

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
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

Map<String, dynamic> _toJson(Reservation r) => {
  'id': r.id,
  'name': r.name,
  'phone': r.phone,
  'partySize': r.partySize,
  'expectedAt': r.expectedAt.toIso8601String(),
  'status': r.status,
  'zoneId': r.zoneId,
  'tableId': r.tableId,
  'notes': r.notes,
  // The [[Pelanggan (member)]] this booking was made against, if any. `name`
  // and `phone` above stay the snapshot of what was booked — a later rename in
  // the directory never rewrites a booking.
  'memberId': r.memberId,
  'createdAt': r.createdAt.toIso8601String(),
  'updatedAt': r.updatedAt?.toIso8601String(),
};

Router reservationsRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();
  const uuid = Uuid();

  r.get('/reservations', (Request req) async {
    final qp = req.url.queryParameters;
    final fromStr = qp['from'];
    final toStr = qp['to'];
    final query = db.select(db.reservations);
    if (fromStr != null && toStr != null) {
      final from = DateTime.parse(fromStr);
      final to = DateTime.parse(toStr);
      query.where((t) => t.expectedAt.isBetweenValues(from, to));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.expectedAt)]);
    final rows = await query.get();
    return Response.ok(
      jsonEncode([for (final x in rows) _toJson(x)]),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/reservations', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      return Response(
        400,
        body: jsonEncode({'code': 'bad_request', 'message': 'name required'}),
        headers: {'content-type': 'application/json'},
      );
    }
    final expectedAtRaw = body['expectedAt'] as String?;
    if (expectedAtRaw == null) {
      return Response(
        400,
        body: jsonEncode({
          'code': 'bad_request',
          'message': 'expectedAt required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final id = uuid.v4();
    final now = SatClock.now();
    await db
        .into(db.reservations)
        .insert(
          ReservationsCompanion.insert(
            id: id,
            name: name,
            phone: Value((body['phone'] as String?)?.trim()),
            partySize: Value((body['partySize'] as num?)?.toInt() ?? 1),
            expectedAt: DateTime.parse(expectedAtRaw),
            status: const Value('pending'),
            zoneId: Value((body['zoneId'] as String?)?.trim()),
            tableId: Value((body['tableId'] as String?)?.trim()),
            notes: Value((body['notes'] as String?)?.trim()),
            memberId: Value((body['memberId'] as String?)?.trim()),
            createdAt: now,
          ),
        );
    final row = await (db.select(
      db.reservations,
    )..where((t) => t.id.equals(id))).getSingle();
    final payload = _toJson(row);
    hub.broadcast(WsEventTypes.reservationCreated, payload);
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  });

  r.patch('/reservations/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final existing = await (db.select(
      db.reservations,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return Response(404);
    final statusRaw = body['status'] as String?;
    if (statusRaw != null && !_allowedStatuses.contains(statusRaw)) {
      return Response(
        400,
        body: jsonEncode({'code': 'bad_request', 'message': 'invalid status'}),
        headers: {'content-type': 'application/json'},
      );
    }
    await (db.update(db.reservations)..where((t) => t.id.equals(id))).write(
      ReservationsCompanion(
        name: body.containsKey('name')
            ? Value((body['name'] as String).trim())
            : const Value.absent(),
        phone: body.containsKey('phone')
            ? Value((body['phone'] as String?)?.trim())
            : const Value.absent(),
        partySize: body.containsKey('partySize')
            ? Value((body['partySize'] as num).toInt())
            : const Value.absent(),
        expectedAt: body.containsKey('expectedAt')
            ? Value(DateTime.parse(body['expectedAt'] as String))
            : const Value.absent(),
        status: statusRaw != null ? Value(statusRaw) : const Value.absent(),
        // Set-once on the first flip into `seated` — a later edit must not
        // move it, or lateness stops being measurable (ADR-0044).
        seatedAt: statusRaw == 'seated' && existing.seatedAt == null
            ? Value(SatClock.now())
            : const Value.absent(),
        zoneId: body.containsKey('zoneId')
            ? Value((body['zoneId'] as String?)?.trim())
            : const Value.absent(),
        tableId: body.containsKey('tableId')
            ? Value((body['tableId'] as String?)?.trim())
            : const Value.absent(),
        notes: body.containsKey('notes')
            ? Value((body['notes'] as String?)?.trim())
            : const Value.absent(),
        // Set or clear — an explicit null unlinks the booking and never touches
        // the member record. Hosts fix mis-taps.
        memberId: body.containsKey('memberId')
            ? Value((body['memberId'] as String?)?.trim())
            : const Value.absent(),
        updatedAt: Value(SatClock.now()),
      ),
    );
    final row = await (db.select(
      db.reservations,
    )..where((t) => t.id.equals(id))).getSingle();
    final payload = _toJson(row);
    hub.broadcast(WsEventTypes.reservationUpdated, payload);
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  });

  r.delete('/reservations/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final existing = await (db.select(
      db.reservations,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return Response(404);
    // Cancel-then-delete policy: forbid direct delete of `seated` rows so the
    // audit trail keeps a cancellation event before disappearance.
    if (existing.status == 'seated') {
      return Response(
        409,
        body: jsonEncode({
          'code': 'conflict',
          'message': 'cancel before delete',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    await (db.delete(db.reservations)..where((t) => t.id.equals(id))).go();
    hub.broadcast(WsEventTypes.reservationDeleted, {'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}
