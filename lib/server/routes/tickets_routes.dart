import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/ticket.dart' show TicketStatus, ticketStatusFromKey;
import 'package:satset/domain/models/capability.dart';

const _allowedTransitions = <TicketStatus, Set<TicketStatus>>{
  TicketStatus.draft: {TicketStatus.sent, TicketStatus.voided},
  TicketStatus.acknowledged: {TicketStatus.prep, TicketStatus.voided},
  TicketStatus.sent: {TicketStatus.prep, TicketStatus.cooked, TicketStatus.held, TicketStatus.voided},
  TicketStatus.held: {TicketStatus.sent, TicketStatus.voided},
  TicketStatus.prep: {TicketStatus.cooked, TicketStatus.voided},
  TicketStatus.cooked: {TicketStatus.ready, TicketStatus.voided},
  TicketStatus.ready: {TicketStatus.served, TicketStatus.voided},
  // `served → ready` is allowed so a waiter can undo a premature serve mark
  // through the same canonical transition path (no local-only rewind).
  TicketStatus.served: {TicketStatus.ready, TicketStatus.voided},
  TicketStatus.voided: <TicketStatus>{},
};

Capability? _requiredCap(TicketStatus from, TicketStatus to) {
  // Voids always go through the void-item capability regardless of source.
  if (to == TicketStatus.voided) return Capability.voidItem;
  // Waiter-driven transitions: serve, undo-serve, fire-from-hold.
  if (from == TicketStatus.ready && to == TicketStatus.served) {
    return Capability.takeOrder;
  }
  if (from == TicketStatus.served && to == TicketStatus.ready) {
    return Capability.takeOrder;
  }
  if (from == TicketStatus.held && to == TicketStatus.sent) {
    return Capability.takeOrder;
  }
  // KDS progression along the cook line.
  if (from == TicketStatus.sent && to == TicketStatus.prep) {
    return Capability.viewKds;
  }
  if (from == TicketStatus.prep && to == TicketStatus.cooked) {
    return Capability.viewKds;
  }
  if (from == TicketStatus.cooked && to == TicketStatus.ready) {
    return Capability.viewKds;
  }
  return null;
}

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
  final token = req.headers['authorization']?.replaceFirst(
      RegExp(r'^[Bb]earer\s+'), '');
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

Map<String, dynamic> _tableToJson(VenueTable t) => {
      'id': t.id,
      'zoneId': t.zoneId,
      'label': t.label,
      'pax': t.pax,
      'active': t.active,
      'status': t.status,
      'openAmount': t.openAmount,
      'readyCount': t.readyCount,
      'lastActorId': t.lastActorId,
      'lockedBy': t.lockedBy,
      'lockedByName': t.lockedByName,
      'lockedAt': t.lockedAt?.toIso8601String(),
      'lockExpiresAt': t.lockExpiresAt?.toIso8601String(),
    };

Router ticketsRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();
  const uuid = Uuid();

  r.get('/tickets', (Request req) async {
    final rows = await db.select(db.tickets).get();
    return Response.ok(
      jsonEncode([for (final t in rows) _toJson(t)]),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/orders', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final tableId = body['tableId'] as String;
    final idem = body['idempotencyKey'] as String;
    final lines = (body['lines'] as List).cast<Map<String, dynamic>>();
    final actorId = body['actorId'] as String?;

    final createdIds = <String>[];
    final createdRows = <Ticket>[];
    VenueTable? tableRow;
    String? storedResponse;
    await db.transaction(() async {
      // Claim the idempotency key atomically; primary-key conflict means
      // a concurrent request already took it.
      final existing = await (db.select(db.idempotency)
            ..where((k) => k.key.equals(idem)))
          .getSingleOrNull();
      if (existing != null) {
        storedResponse = existing.responseJson;
        return;
      }
      for (final l in lines) {
        final id = uuid.v4();
        final course = l['course'] as String;
        // "Kirim ke dapur" is an explicit fire action: every line enters
        // the KDS queue as `sent`. Course pacing is purely a sort/grouping
        // hint for the kitchen, not a gate.
        final row = TicketsCompanion.insert(
          id: id,
          tableId: tableId,
          itemId: l['itemId'] as String,
          name: (l['name'] as String?) ?? l['itemId'] as String,
          variantName: Value((l['variantName'] as String?) ?? ''),
          course: course,
          station: (l['station'] as String?) ?? 'kitchen',
          qty: Value((l['qty'] as num?)?.toInt() ?? 1),
          modifiersJson: Value(jsonEncode(l['modifierOptionIds'] ?? const [])),
          specialInstructions: Value(l['specialInstructions'] as String?),
          price: (l['unitPrice'] as num).toInt(),
          status: 'sent',
          sentAt: DateTime.now(),
        );
        await db.into(db.tickets).insert(row);
        createdIds.add(id);
        final full =
            await (db.select(db.tickets)..where((t) => t.id.equals(id)))
                .getSingle();
        createdRows.add(full);
      }
      await db.into(db.idempotency).insert(
            IdempotencyCompanion.insert(
              key: idem,
              responseJson: jsonEncode({'ticketIds': createdIds}),
              createdAt: DateTime.now(),
            ),
          );
      // Mark the table `pending` in the same transaction so that all
      // clients observe ticket-creation and table-state changes together
      // and never see one without the other.
      await (db.update(db.venueTables)..where((t) => t.id.equals(tableId)))
          .write(VenueTablesCompanion(
        status: const Value('pending'),
        lastActorId: Value(actorId),
      ));
      tableRow =
          await (db.select(db.venueTables)..where((t) => t.id.equals(tableId)))
              .getSingleOrNull();
    });

    if (storedResponse != null) {
      return Response.ok(storedResponse,
          headers: {'content-type': 'application/json'});
    }
    for (final t in createdRows) {
      hub.broadcast(WsEventTypes.ticketCreated, _toJson(t));
    }
    if (tableRow != null) {
      hub.broadcast(WsEventTypes.tableUpdated, _tableToJson(tableRow!));
    }
    return Response.ok(jsonEncode({'ticketIds': createdIds}),
        headers: {'content-type': 'application/json'});
  });

  r.post('/tickets/<id>/transition', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final statusRaw = body['status'] as String;
    final current = await (db.select(db.tickets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (current == null) return Response.notFound('ticket not found');
    final from = ticketStatusFromKey(current.status);
    final to = ticketStatusFromKey(statusRaw);
    final allowed = _allowedTransitions[from] ?? const <TicketStatus>{};
    if (!allowed.contains(to)) {
      return Response(409,
          body: jsonEncode({
            'code': 'illegal_transition',
            'message': '${current.status} -> $statusRaw',
          }),
          headers: {'content-type': 'application/json'});
    }
    final needed = _requiredCap(from, to);
    if (needed != null) {
      final denied = await _requireCap(req, db, auth, needed);
      if (denied != null) return denied;
    }
    Ticket? row;
    VenueTable? tableRow;
    await db.transaction(() async {
      await (db.update(db.tickets)..where((t) => t.id.equals(id))).write(
        TicketsCompanion(
          status: Value(statusRaw),
          voidReason: Value(body['voidReason'] as String?),
          voidApprovedBy: Value(body['voidApprovedBy'] as String?),
        ),
      );
      row = await (db.select(db.tickets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) return;
      // Maintain table.readyCount and table.status atomically in the same
      // transition. Entering `ready` bumps the count and flips the table
      // to `ready`; leaving `ready` (served / voided) decrements it and
      // falls back to `occupied` once the last ready item clears.
      final tableId = row!.tableId;
      final tbl =
          await (db.select(db.venueTables)..where((t) => t.id.equals(tableId)))
              .getSingleOrNull();
      if (tbl == null) return;
      final wasReady = from == TicketStatus.ready;
      final isReady = to == TicketStatus.ready;
      if (!wasReady && isReady) {
        final n = tbl.readyCount + 1;
        await (db.update(db.venueTables)..where((t) => t.id.equals(tableId)))
            .write(VenueTablesCompanion(
          readyCount: Value(n),
          status: const Value('ready'),
        ));
      } else if (wasReady && !isReady) {
        final n = (tbl.readyCount - 1).clamp(0, 1 << 30);
        final nextStatus =
            (tbl.status == 'ready' && n == 0) ? 'occupied' : tbl.status;
        await (db.update(db.venueTables)..where((t) => t.id.equals(tableId)))
            .write(VenueTablesCompanion(
          readyCount: Value(n),
          status: Value(nextStatus),
        ));
      }
      // Auto-release: when no live tickets remain on the table, clear it
      // back to `available`. Live = anything still moving through the
      // kitchen/serve graph; `served` and `voided` are terminal.
      const liveStatuses = [
        'draft',
        'acknowledged',
        'held',
        'sent',
        'prep',
        'cooked',
        'ready',
      ];
      final liveRemaining = await (db.select(db.tickets)
            ..where((t) =>
                t.tableId.equals(tableId) & t.status.isIn(liveStatuses)))
          .get();
      if (liveRemaining.isEmpty) {
        await (db.update(db.venueTables)..where((t) => t.id.equals(tableId)))
            .write(const VenueTablesCompanion(
          status: Value('available'),
          readyCount: Value(0),
          openAmount: Value(0),
        ));
      }
      tableRow =
          await (db.select(db.venueTables)..where((t) => t.id.equals(tableId)))
              .getSingleOrNull();
    });
    if (row == null) return Response.notFound('ticket not found');
    hub.broadcast(WsEventTypes.ticketUpdated, _toJson(row!));
    if (tableRow != null) {
      hub.broadcast(WsEventTypes.tableUpdated, _tableToJson(tableRow!));
    }
    return Response.ok(jsonEncode(_toJson(row!)),
        headers: {'content-type': 'application/json'});
  });

  // Table-scoped course fire. Only flips `held` rows for the given
  // (tableId, course) so firing one table's course never leaks across
  // tables. Returns the updated ticket rows so the caller can merge them
  // alongside the WS broadcast.
  r.post('/tables/<tableId>/course/<course>/fire',
      (Request req, String tableId, String course) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final updated = <Ticket>[];
    await db.transaction(() async {
      await (db.update(db.tickets)
            ..where((t) =>
                t.tableId.equals(tableId) &
                t.course.equals(course) &
                t.status.equals('held')))
          .write(TicketsCompanion(status: const Value('sent')));
      final rows = await (db.select(db.tickets)
            ..where((t) =>
                t.tableId.equals(tableId) &
                t.course.equals(course) &
                t.status.equals('sent')))
          .get();
      updated.addAll(rows);
    });
    for (final t in updated) {
      hub.broadcast(WsEventTypes.ticketUpdated, _toJson(t));
    }
    return Response.ok(
        jsonEncode({
          'fired': updated.length,
          'tickets': [for (final t in updated) _toJson(t)],
        }),
        headers: {'content-type': 'application/json'});
  });

  return r;
}

Map<String, dynamic> _toJson(Ticket t) => {
      'id': t.id,
      'tableId': t.tableId,
      'itemId': t.itemId,
      'name': t.name,
      'variantName': t.variantName,
      'course': t.course,
      'station': t.station,
      'qty': t.qty,
      'modifiers': jsonDecode(t.modifiersJson),
      'specialInstructions': t.specialInstructions,
      'price': t.price,
      'status': t.status,
      'sentAt': t.sentAt.toIso8601String(),
      'voidReason': t.voidReason,
      'voidApprovedBy': t.voidApprovedBy,
    };
