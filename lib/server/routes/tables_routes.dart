import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/printing/struk_data.dart';
import 'package:satset/core/printing/struk_renderer.dart';
import 'package:satset/core/printing/struk_socket.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/use_cases/bill_math.dart';

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

/// Ensure the table has a live [[Visit]] and return its id. Created lazily by
/// whichever of seat / first-order lands first (the order flow can occupy a
/// table without an explicit seat). Idempotent: returns the existing current
/// visit when one is still live. See ADR-0024.
Future<String> ensureVisit(AppDatabase db, String tableId,
    {String? actorId}) async {
  final t = await (db.select(db.venueTables)..where((x) => x.id.equals(tableId)))
      .getSingleOrNull();
  final cur = t?.currentVisitId;
  if (cur != null && cur.isNotEmpty) {
    final v =
        await (db.select(db.visits)..where((x) => x.id.equals(cur))).getSingleOrNull();
    if (v != null) return v.id;
  }
  final id = _uuid.v4();
  final now = DateTime.now().toUtc();
  // Tolerant of a missing table row (synthetic/test order paths) — fall back
  // to a bare visit so order submission never fails on table lookup.
  await db.into(db.visits).insert(VisitsCompanion.insert(
        id: id,
        tableId: tableId,
        tableLabel: Value(t?.label),
        zoneId: Value(t?.zoneId ?? ''),
        pax: Value(t?.pax ?? 0),
        openedAt: Value(t?.openedAt ?? now),
        guestName: Value(t?.guestName),
        guestNotes: Value(t?.guestNotes),
        reservationId: Value(t?.reservationId),
        lastActorId: Value(actorId ?? t?.lastActorId),
        createdAt: now,
      ));
  if (t != null) {
    await (db.update(db.venueTables)..where((x) => x.id.equals(tableId)))
        .write(VenueTablesCompanion(currentVisitId: Value(id)));
  }
  return id;
}

/// Mint a takeaway (Bawa pulang) [[Visit]] — `kind == takeaway`, no table row,
/// `pax = 0`, `tableFreedAt` null at creation. The pickup number comes from the
/// per-business-day [DailyCounters] (`Bawa pulang #N`). The lifecycle reuses
/// ADR-0024's two axes with handover ("Serahkan") stamping `tableFreedAt` in
/// place of table-close. See ADR-0026.
Future<Visit> createTakeawayVisit(
  AppDatabase db, {
  required String guestName,
  String? guestNotes,
  String? actorId,
}) async {
  final now = DateTime.now();
  final nowUtc = now.toUtc();
  final s = await (db.select(db.venueSettings)
        ..where((x) => x.id.equals('default')))
      .getSingleOrNull();
  final hour = s?.businessDayStartHour ?? 4;
  // Anchor to the business day so the running number resets at the configured
  // rollover hour, matching how reports bucket "today".
  final bod = DateTime(now.year, now.month, now.day, hour);
  final anchor = now.isBefore(bod) ? now.subtract(const Duration(days: 1)) : now;
  String two(int n) => n.toString().padLeft(2, '0');
  final dateStr = '${anchor.year}-${two(anchor.month)}-${two(anchor.day)}';
  final id = _uuid.v4();
  var n = 1;
  await db.transaction(() async {
    final c = await (db.select(db.dailyCounters)
          ..where((x) => x.dateStr.equals(dateStr)))
        .getSingleOrNull();
    n = c?.takeawayNext ?? 1;
    await db.into(db.dailyCounters).insertOnConflictUpdate(
          DailyCountersCompanion.insert(
            dateStr: dateStr,
            takeawayNext: Value(n + 1),
          ),
        );
    await db.into(db.visits).insert(VisitsCompanion.insert(
          id: id,
          tableId: '',
          tableLabel: Value('Bawa pulang #$n'),
          zoneId: const Value(''),
          pax: const Value(0),
          openedAt: Value(nowUtc),
          guestName: Value(guestName),
          guestNotes: Value(guestNotes),
          lastActorId: Value(actorId),
          createdAt: nowUtc,
          kind: const Value('takeaway'),
        ));
  });
  final v = await (db.select(db.visits)..where((x) => x.id.equals(id)))
      .getSingleOrNull();
  return v!;
}

/// Snapshot a [[Visit]] into TableSessions(+children) and hard-delete the live
/// visit + its tickets/receipts/payments. Called only once BOTH axes have
/// completed (table freed AND bill closed) — the visit's terminal point. The
/// table row is already freed by the detach path before this runs. Broadcasts
/// `tableSession.closed`. See ADR-0024. `lossAmount` records a walkout
/// write-off (tak tertagih); 0 for a normal Lunas close.
Future<void> snapshotVisitAndDelete(AppDatabase db, WsHub hub, Visit visit,
    {String? billClosedBy, int lossAmount = 0}) async {
  await db.transaction(() async {
    final tickets = await (db.select(db.tickets)
          ..where((t) => t.visitId.equals(visit.id)))
        .get();
    final now = DateTime.now().toUtc();
    final openedAt = visit.openedAt;
    final durationSec = openedAt == null
        ? 0
        : now.difference(openedAt).inSeconds.clamp(0, 1 << 31);
    var subtotal = 0;
    var voidAmount = 0;
    for (final t in tickets) {
      final line = t.price * t.qty;
      if (t.status == 'voided') {
        voidAmount += line;
      } else {
        subtotal += line;
      }
    }
    final s = await (db.select(db.venueSettings)
          ..where((t) => t.id.equals('default')))
        .getSingleOrNull();
    final cfg = TaxServiceConfig(
      taxEnabled: s?.taxEnabled ?? false,
      taxRateBps: s?.taxRateBps ?? 1100,
      serviceEnabled: s?.serviceEnabled ?? false,
      serviceMode: s?.serviceMode ?? 'percent',
      serviceRateBps: s?.serviceRateBps ?? 500,
      serviceFixedAmount: s?.serviceFixedAmount ?? 0,
    );
    final breakdown = computeBreakdown(subtotal, cfg);
    final sessionId = _uuid.v4();
    await db.into(db.tableSessions).insert(TableSessionsCompanion.insert(
          id: sessionId,
          tableId: visit.tableId,
          tableLabel: Value(visit.tableLabel),
          zoneId: visit.zoneId,
          pax: Value(visit.pax),
          openedAt: Value(openedAt),
          closedAt: now,
          durationSec: Value(durationSec),
          actorUserId: Value(visit.lastActorId),
          subtotal: Value(subtotal),
          voidAmount: Value(voidAmount),
          serviceAmount: Value(breakdown.serviceAmount),
          taxAmount: Value(breakdown.taxAmount),
          netTotal: Value(breakdown.total),
          ticketCount: Value(tickets.length),
          lossAmount: Value(lossAmount),
          billClosedBy: Value(billClosedBy),
          // Freeze the visit kind so reports can split takeaway out of
          // per-cover / turn-time / occupancy metrics. See ADR-0026.
          kind: Value(visit.kind),
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
              qty: Value(t.qty),
              modifiersJson: Value(t.modifiersJson),
              note: Value(t.note),
              price: t.price,
              status: t.status,
              sentAt: t.sentAt,
              readyAt: Value(t.readyAt),
              servedAt: Value(t.servedAt),
              voidReason: Value(t.voidReason),
              voidReasonCode: Value(t.voidReasonCode),
              voidApprovedBy: Value(t.voidApprovedBy),
              createdByUserId: Value(t.createdByUserId),
              voidedByUserId: Value(t.voidedByUserId),
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
        if (firedAt == null || t.sentAt.isBefore(firedAt)) firedAt = t.sentAt;
        if (t.status == 'served') {
          if (servedAt == null || t.sentAt.isAfter(servedAt)) servedAt = t.sentAt;
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
    final recs = await (db.select(db.receipts)
          ..where((rc) => rc.visitId.equals(visit.id)))
        .get();
    for (final rec in recs) {
      await db.into(db.tableSessionReceipts).insert(
            TableSessionReceiptsCompanion.insert(
              id: _uuid.v4(),
              sessionId: sessionId,
              receiptId: rec.id,
              mode: Value(rec.mode),
              label: Value(rec.label),
              subtotal: Value(rec.subtotal),
              serviceAmount: Value(rec.serviceAmount),
              taxAmount: Value(rec.taxAmount),
              total: Value(rec.total),
              status: Value(rec.status),
            ),
          );
      final pays = await (db.select(db.payments)
            ..where((p) => p.receiptId.equals(rec.id)))
          .get();
      for (final p in pays) {
        await db.into(db.tableSessionPayments).insert(
              TableSessionPaymentsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                receiptId: rec.id,
                method: p.method,
                amount: p.amount,
                isRefund: Value(p.isRefund),
                cashierUserId: Value(p.cashierUserId),
                at: p.at,
                // Carry the proof photo into immutable history (ADR-0025).
                photo: Value(p.photo),
              ),
            );
      }
      await (db.delete(db.receiptLines)..where((x) => x.receiptId.equals(rec.id)))
          .go();
      await (db.delete(db.payments)..where((x) => x.receiptId.equals(rec.id)))
          .go();
    }
    await (db.delete(db.receipts)..where((rc) => rc.visitId.equals(visit.id))).go();
    await (db.delete(db.tickets)..where((t) => t.visitId.equals(visit.id))).go();
    await (db.delete(db.visits)..where((v) => v.id.equals(visit.id))).go();
  });
  hub.broadcast(WsEventTypes.tableSessionClosed, {
    'tableId': visit.tableId,
    'visitId': visit.id,
  });
}

/// Recompute the ATTACHED table's denormalised money badge (outstanding +
/// state) for a visit and broadcast it, so the floor shows live
/// Sebagian/outstanding without subscribing to bills. No-op for a detached or
/// gone visit (its money shows only on the cashier). See ADR-0024.
Future<void> syncVisitMoney(AppDatabase db, WsHub hub, String visitId) async {
  final table = await (db.select(db.venueTables)
        ..where((t) => t.currentVisitId.equals(visitId)))
      .getSingleOrNull();
  if (table == null) return;
  final tickets = await (db.select(db.tickets)
        ..where((t) => t.visitId.equals(visitId)))
      .get();
  final sent =
      tickets.where((t) => t.status != 'voided' && t.status != 'draft');
  final subtotal = sent.fold<int>(0, (a, t) => a + t.price * t.qty);
  int outstanding = 0;
  String? state;
  if (subtotal > 0) {
    final s = await (db.select(db.venueSettings)
          ..where((x) => x.id.equals('default')))
        .getSingleOrNull();
    final cfg = TaxServiceConfig(
      taxEnabled: s?.taxEnabled ?? false,
      taxRateBps: s?.taxRateBps ?? 1100,
      serviceEnabled: s?.serviceEnabled ?? false,
      serviceMode: s?.serviceMode ?? 'percent',
      serviceRateBps: s?.serviceRateBps ?? 500,
      serviceFixedAmount: s?.serviceFixedAmount ?? 0,
    );
    final total = computeBreakdown(subtotal, cfg).total;
    final recs = await (db.select(db.receipts)
          ..where((rc) => rc.visitId.equals(visitId)))
        .get();
    var paid = 0;
    for (final rec in recs) {
      final pays = await (db.select(db.payments)
            ..where((p) => p.receiptId.equals(rec.id)))
          .get();
      paid += pays.fold<int>(0, (a, p) => a + p.amount);
    }
    outstanding = (total - paid).clamp(0, 1 << 31);
    state = paid <= 0 ? null : (outstanding <= 0 ? 'paid' : 'partial');
  }
  await (db.update(db.venueTables)..where((t) => t.id.equals(table.id))).write(
    VenueTablesCompanion(
      openAmount: Value(outstanding),
      moneyState: Value(state),
    ),
  );
  final fresh = await (db.select(db.venueTables)..where((t) => t.id.equals(table.id)))
      .getSingleOrNull();
  if (fresh != null) hub.broadcast(WsEventTypes.tableUpdated, _toJson(fresh));
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

  // Active takeaway (Bawa pulang) visits for the Floor strip + KDS labelling. A
  // live Visits row with kind==takeaway is active (snapshot deletes it).
  // Read-only like `/tables` — any authenticated client (waiter or kitchen)
  // needs it to resolve table-less labels. ADR-0026.
  r.get('/takeaway/visits', (Request req) async {
    final rows = await (db.select(db.visits)
          ..where((v) => v.kind.equals('takeaway'))
          ..orderBy([(v) => OrderingTerm.asc(v.createdAt)]))
        .get();
    return Response.ok(
      jsonEncode([for (final v in rows) _visitToJson(v)]),
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

  r.post('/tables/<id>/seat', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    if (row.status != 'available') {
      return Response(409,
          body: jsonEncode({
            'code': 'already_seated',
            'message': 'table is already in use',
            'table': _toJson(row),
          }),
          headers: {'content-type': 'application/json'});
    }
    final paxIn = (body['pax'] as num?)?.toInt();
    final pax = paxIn == null
        ? row.pax
        : paxIn.clamp(0, row.capacity < 1 ? 1 : row.capacity);
    final actorId = body['actorId'] as String?;
    final actorName = body['actorName'] as String?;
    final guestName = body['guestName'] as String?;
    final guestNotes = body['guestNotes'] as String?;
    final reservationId = body['reservationId'] as String?;
    final acquireLock = body['acquireLock'] == true;
    final now = DateTime.now();
    await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
      VenueTablesCompanion(
        status: const Value('occupied'),
        pax: Value(pax),
        openedAt: Value(row.openedAt ?? now.toUtc()),
        lastActorId: actorId == null ? const Value.absent() : Value(actorId),
        guestName: Value(guestName),
        guestNotes: Value(guestNotes),
        reservationId: Value(reservationId),
        lockedBy: acquireLock && actorId != null
            ? Value(actorId)
            : const Value.absent(),
        lockedByName: acquireLock && actorId != null
            ? Value(actorName)
            : const Value.absent(),
        lockedAt: acquireLock && actorId != null
            ? Value(now)
            : const Value.absent(),
        lockExpiresAt: acquireLock && actorId != null
            ? Value(now.add(const Duration(seconds: 7)))
            : const Value.absent(),
      ),
    );
    // A seated table always has a live visit (the bill keys off it). ADR-0024.
    await ensureVisit(db, id, actorId: actorId);
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

  // Table close (detach): the WAITER frees the table back to `available` for a
  // new party. It does NOT snapshot and does NOT settle money — the visit's
  // bill lives on (detached) for the cashier until bill-close. Guarded by
  // takeOrder; rejects 409 unless every ticket is terminal (served | voided) —
  // you can't free a table with food in flight. If the cashier already locked
  // the bill (billClosedAt set), detach is the SECOND axis and completes the
  // visit: snapshot + delete. See ADR-0024.
  r.post('/tables/<id>/close', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final tableRow = await (db.select(db.venueTables)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (tableRow == null) return Response.notFound('table not found');
    final visitId = tableRow.currentVisitId;
    if (visitId == null || visitId.isEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'no_tickets',
            'message': 'nothing to close: table has no live visit',
          }),
          headers: {'content-type': 'application/json'});
    }
    final tickets = await (db.select(db.tickets)
          ..where((t) => t.visitId.equals(visitId)))
        .get();
    if (tickets.isEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'no_tickets',
            'message': 'nothing to settle: table has no tickets',
          }),
          headers: {'content-type': 'application/json'});
    }
    final hasLive =
        tickets.any((t) => t.status != 'served' && t.status != 'voided');
    if (hasLive) {
      return Response(409,
          body: jsonEncode({
            'code': 'tickets_not_terminal',
            'message': 'all tickets must be served or voided before close',
          }),
          headers: {'content-type': 'application/json'});
    }
    // Free the table + mark the visit detached. Keep the bill alive.
    await db.transaction(() async {
      await (db.update(db.visits)..where((v) => v.id.equals(visitId)))
          .write(VisitsCompanion(tableFreedAt: Value(DateTime.now().toUtc())));
      await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
        const VenueTablesCompanion(
          status: Value('available'),
          openAmount: Value(0),
          readyCount: Value(0),
          pax: Value(0),
          lastActorId: Value(null),
          lockedBy: Value(null),
          lockedByName: Value(null),
          lockedAt: Value(null),
          lockExpiresAt: Value(null),
          openedAt: Value(null),
          guestName: Value(null),
          guestNotes: Value(null),
          reservationId: Value(null),
          currentVisitId: Value(null),
          billClosedAt: Value(null),
          moneyState: Value(null),
        ),
      );
    });
    // If the bill was already closed, detach is the second axis — snapshot now.
    final visit = await (db.select(db.visits)..where((v) => v.id.equals(visitId)))
        .getSingleOrNull();
    if (visit != null && visit.billClosedAt != null) {
      await snapshotVisitAndDelete(db, hub, visit,
          billClosedBy: visit.billClosedBy, lossAmount: visit.lossAmount);
    } else if (visit != null) {
      // Still-open detached bill — tell the cashier to refresh its flag.
      hub.broadcast(WsEventTypes.billUpdated, {'visitId': visit.id});
    }
    return _broadcast(db, hub, id);
  });

  // Release: return a seated table to `available` WITHOUT settling a session.
  // For guests who leave before ordering — no tickets exist, so there is
  // nothing to snapshot. Rejects 409 if any ticket is present; that path must
  // go through /close so the bill is recorded.
  r.post('/tables/<id>/release', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('table not found');
    final visitId = row.currentVisitId;
    final ticketCount = visitId == null
        ? 0
        : await (db.select(db.tickets)..where((t) => t.visitId.equals(visitId)))
            .get()
            .then((rows) => rows.length);
    if (ticketCount > 0) {
      return Response(409,
          body: jsonEncode({
            'code': 'has_tickets',
            'message': 'table has tickets; use /close to settle',
          }),
          headers: {'content-type': 'application/json'});
    }
    await db.transaction(() async {
      // No tickets ⇒ no bill: drop the empty visit outright (nothing to keep
      // on the cashier, nothing to snapshot). See ADR-0024.
      if (visitId != null) {
        await (db.delete(db.visits)..where((v) => v.id.equals(visitId))).go();
      }
      await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
        const VenueTablesCompanion(
          status: Value('available'),
          openAmount: Value(0),
          readyCount: Value(0),
          pax: Value(0),
          lastActorId: Value(null),
          lockedBy: Value(null),
          lockedByName: Value(null),
          lockedAt: Value(null),
          lockExpiresAt: Value(null),
          openedAt: Value(null),
          guestName: Value(null),
          guestNotes: Value(null),
          reservationId: Value(null),
          currentVisitId: Value(null),
          billClosedAt: Value(null),
          moneyState: Value(null),
        ),
      );
    });
    return _broadcast(db, hub, id);
  });

  // Pindah meja (move table): transfer a whole live session from a source
  // table onto an empty target. Atomic: re-points every ticket, copies the
  // session fields, wipes the source, sets the target lock to the mover, and
  // writes a `tableMoved` audit row. See ADR-0019.
  r.post('/tables/<id>/move', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final targetId = body['targetId'] as String?;
    if (targetId == null || targetId.isEmpty) {
      return Response(400,
          body: jsonEncode(
              {'code': 'bad_request', 'message': 'targetId required'}),
          headers: {'content-type': 'application/json'});
    }
    if (targetId == id) {
      return Response(400,
          body: jsonEncode(
              {'code': 'same_table', 'message': 'source and target are equal'}),
          headers: {'content-type': 'application/json'});
    }
    // Resolve the mover from the bearer when auth is on; fall back to the
    // body actorId (dev / no-auth) so the lock check + audit stay accurate.
    String? moverId = body['actorId'] as String?;
    final moverName = body['actorName'] as String?;
    if (auth != null) {
      final token = req.headers['authorization']
          ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
      final u = await auth.resolveBearer(token);
      moverId = u?.id ?? moverId;
    }
    final source = await (db.select(db.venueTables)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (source == null) return Response.notFound('source table not found');
    if (source.status == 'available') {
      return Response(409,
          body: jsonEncode({
            'code': 'source_not_occupied',
            'message': 'source table is empty',
          }),
          headers: {'content-type': 'application/json'});
    }
    final now = DateTime.now();
    final srcLockedByOther = source.lockedBy != null &&
        source.lockedBy!.isNotEmpty &&
        source.lockedBy != moverId &&
        source.lockExpiresAt != null &&
        source.lockExpiresAt!.isAfter(now);
    if (srcLockedByOther) {
      return Response(409,
          body: jsonEncode({
            'code': 'table_locked',
            'message': 'source table is locked by another user',
            'table': _toJson(source),
          }),
          headers: {'content-type': 'application/json'});
    }
    final target = await (db.select(db.venueTables)
          ..where((t) => t.id.equals(targetId)))
        .getSingleOrNull();
    if (target == null) return Response.notFound('target table not found');
    if (target.status != 'available' || !target.active) {
      return Response(409,
          body: jsonEncode({
            'code': 'target_unavailable',
            'message': 'target table is not an empty, active table',
            'table': _toJson(target),
          }),
          headers: {'content-type': 'application/json'});
    }
    String? auditId;
    final movingVisitId = source.currentVisitId;
    await db.transaction(() async {
      // Re-point the live visit + its tickets/receipts from source → target.
      // The visit is the bill key; tableId/tableLabel are kept current for
      // display. KDS/reports resolve by tableId live, so nothing else changes.
      await (db.update(db.tickets)..where((t) => t.tableId.equals(id)))
          .write(TicketsCompanion(tableId: Value(targetId)));
      if (movingVisitId != null) {
        await (db.update(db.visits)..where((v) => v.id.equals(movingVisitId)))
            .write(VisitsCompanion(
          tableId: Value(targetId),
          tableLabel: Value(target.label),
        ));
        await (db.update(db.receipts)..where((rc) => rc.visitId.equals(movingVisitId)))
            .write(ReceiptsCompanion(tableId: Value(targetId)));
      }
      // Copy the session onto the target + hand the lock to the mover.
      await (db.update(db.venueTables)..where((t) => t.id.equals(targetId)))
          .write(VenueTablesCompanion(
        status: Value(source.status),
        pax: Value(source.pax),
        openAmount: Value(source.openAmount),
        readyCount: Value(source.readyCount),
        openedAt: Value(source.openedAt),
        lastActorId: Value(source.lastActorId),
        guestName: Value(source.guestName),
        guestNotes: Value(source.guestNotes),
        reservationId: Value(source.reservationId),
        currentVisitId: Value(movingVisitId),
        billClosedAt: Value(source.billClosedAt),
        moneyState: Value(source.moneyState),
        lockedBy: moverId == null ? const Value(null) : Value(moverId),
        lockedByName: Value(moverName),
        lockedAt: moverId == null ? const Value(null) : Value(now),
        lockExpiresAt: moverId == null
            ? const Value(null)
            : Value(now.add(const Duration(seconds: 7))),
      ));
      // Wipe the source back to kosong.
      await (db.update(db.venueTables)..where((t) => t.id.equals(id))).write(
        const VenueTablesCompanion(
          status: Value('available'),
          openAmount: Value(0),
          readyCount: Value(0),
          pax: Value(0),
          lastActorId: Value(null),
          lockedBy: Value(null),
          lockedByName: Value(null),
          lockedAt: Value(null),
          lockExpiresAt: Value(null),
          openedAt: Value(null),
          guestName: Value(null),
          guestNotes: Value(null),
          reservationId: Value(null),
          currentVisitId: Value(null),
          billClosedAt: Value(null),
          moneyState: Value(null),
        ),
      );
      auditId = _uuid.v4();
      final srcLabel = source.label ?? source.id;
      final tgtLabel = target.label ?? target.id;
      await db.into(db.auditEntries).insert(AuditEntriesCompanion.insert(
            id: auditId!,
            type: AuditType.tableMoved.name,
            title: 'Pindah meja $srcLabel → $tgtLabel',
            tableId: Value(targetId),
            at: now,
            actorUserId: Value(moverId),
          ));
    });
    // Broadcast both table rows + the audit row.
    final srcRow = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    final tgtRow = await (db.select(db.venueTables)
          ..where((t) => t.id.equals(targetId)))
        .getSingleOrNull();
    if (srcRow != null) hub.broadcast(WsEventTypes.tableUpdated, _toJson(srcRow));
    if (tgtRow != null) hub.broadcast(WsEventTypes.tableUpdated, _toJson(tgtRow));
    if (auditId != null) {
      final a = await (db.select(db.auditEntries)
            ..where((e) => e.id.equals(auditId!)))
          .getSingleOrNull();
      if (a != null) {
        hub.broadcast(WsEventTypes.auditCreated, {
          'id': a.id,
          'type': a.type,
          'title': a.title,
          'tableId': a.tableId,
          'at': a.at.toIso8601String(),
          'approvedBy': a.approvedBy,
          'reason': a.reason,
          'actorUserId': a.actorUserId,
        });
      }
    }
    if (tgtRow == null) return Response.notFound('target table not found');
    return Response.ok(jsonEncode(_toJson(tgtRow)),
        headers: {'content-type': 'application/json'});
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

  // Print a guest order-confirmation struk for this table to a VENUE printer.
  // Server renders + sends (ADR-0020); any authenticated staff may trigger it.
  r.post('/tables/<id>/print', (Request req, String id) async {
    if (auth != null) {
      final token = req.headers['authorization']
          ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
      final user = await auth.resolveBearer(token);
      if (user == null) return Response(401);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final printerId = body['printerId'] as String?;
    if (printerId == null || printerId.isEmpty) {
      return Response(400,
          body: jsonEncode(
              {'code': 'bad_request', 'message': 'printerId required'}),
          headers: {'content-type': 'application/json'});
    }
    final printer =
        await (db.select(db.printers)..where((p) => p.id.equals(printerId)))
            .getSingleOrNull();
    if (printer == null) return Response.notFound('printer not found');
    final table =
        await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (table == null) return Response.notFound('table not found');
    // Scope to the table's CURRENT visit so a reseated table never prints a
    // prior detached visit's lines (which keep this tableId). See ADR-0024.
    final curVisit = table.currentVisitId;
    final tickets = curVisit == null
        ? <Ticket>[]
        : await (db.select(db.tickets)..where((t) => t.visitId.equals(curVisit)))
            .get();
    final venueRows = await db.select(db.venueSettings).get();
    final v = venueRows.isEmpty ? null : venueRows.first;

    final lines = <StrukLine>[];
    for (final t in tickets) {
      if (t.status == 'voided') continue;
      final mods = <String>[];
      try {
        for (final m in (jsonDecode(t.modifiersJson) as List)) {
          final lbl = (m as Map)['label'];
          if (lbl is String && lbl.trim().isNotEmpty) mods.add(lbl.trim());
        }
      } catch (_) {}
      lines.add(StrukLine(
        qty: t.qty,
        name: t.name,
        variant: t.variantName,
        modifiers: mods,
        note: (t.note ?? '').trim(),
      ));
    }
    if (lines.isEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'no_lines',
            'message': 'tidak ada pesanan untuk dicetak',
          }),
          headers: {'content-type': 'application/json'});
    }

    final data = StrukData(
      venueName: v?.displayName ?? 'SatSet',
      header: v?.receiptHeader ?? '',
      footer: v?.receiptFooter ?? '',
      address: v?.address ?? '',
      phone: v?.phone ?? '',
      tableLabel: table.label ?? id,
      pax: table.pax,
      guestName: table.guestName ?? '',
      guestNote: table.guestNotes ?? '',
      at: DateTime.now(),
      lines: lines,
    );

    try {
      final bytes = await StrukRenderer.render(data);
      await StrukSocket.send(printer.host, printer.port, bytes);
    } catch (e) {
      SatLog.srv('print fail printer=$printerId ${printer.host}:${printer.port} $e');
      return Response(502,
          body: jsonEncode({
            'code': 'print_failed',
            'message': 'printer tak terhubung',
          }),
          headers: {'content-type': 'application/json'});
    }

    final now = DateTime.now();
    await (db.update(db.printers)..where((p) => p.id.equals(printerId)))
        .write(PrintersCompanion(lastSeenAt: Value(now)));
    final updated =
        await (db.select(db.printers)..where((p) => p.id.equals(printerId)))
            .getSingleOrNull();
    if (updated != null) {
      hub.broadcast(WsEventTypes.printerUpdated, {
        'id': updated.id,
        'label': updated.label,
        'host': updated.host,
        'port': updated.port,
        'kind': updated.kind,
        'enabled': updated.enabled,
        'lastSeenAt': updated.lastSeenAt?.toIso8601String(),
        'createdAt': updated.createdAt.toIso8601String(),
      });
    }
    return Response.ok(jsonEncode({'status': 'printed'}),
        headers: {'content-type': 'application/json'});
  });

  // Takeaway handover ("Serahkan"): the first axis for a Bawa pulang visit,
  // replacing table-close. Stamps `tableFreedAt`; gated by takeOrder (waiter or
  // cashier) and the all-tickets-terminal rule (can't hand over food still
  // cooking). If the bill is already closed (pay-upfront), handover is the
  // SECOND axis and completes the visit — snapshot + delete. Otherwise the
  // detached bill lives on for the cashier. See ADR-0026 + ADR-0024.
  r.post('/visits/<id>/handover', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final visit = await (db.select(db.visits)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
    if (visit == null) return Response.notFound('visit not found');
    if (visit.tableFreedAt != null) {
      return Response.ok(
          jsonEncode({'status': 'already_handed_over', 'visitId': id}),
          headers: {'content-type': 'application/json'});
    }
    final tickets = await (db.select(db.tickets)
          ..where((t) => t.visitId.equals(id)))
        .get();
    if (tickets.isEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'no_tickets',
            'message': 'nothing to hand over',
          }),
          headers: {'content-type': 'application/json'});
    }
    final hasLive =
        tickets.any((t) => t.status != 'served' && t.status != 'voided');
    if (hasLive) {
      return Response(409,
          body: jsonEncode({
            'code': 'tickets_not_terminal',
            'message': 'all tickets must be served or voided before handover',
          }),
          headers: {'content-type': 'application/json'});
    }
    await (db.update(db.visits)..where((v) => v.id.equals(id)))
        .write(VisitsCompanion(tableFreedAt: Value(DateTime.now().toUtc())));
    final fresh = await (db.select(db.visits)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
    if (fresh != null && fresh.billClosedAt != null) {
      await snapshotVisitAndDelete(db, hub, fresh,
          billClosedBy: fresh.billClosedBy, lossAmount: fresh.lossAmount);
    } else {
      hub.broadcast(WsEventTypes.billUpdated, {'visitId': id});
    }
    return Response.ok(jsonEncode({'status': 'handed_over', 'visitId': id}),
        headers: {'content-type': 'application/json'});
  });

  return r;
}

/// Public table→JSON for other route files (e.g. settlement broadcasting a
/// table row after mirroring bill-close state for the floor Lunas pill).
Map<String, dynamic> tableJson(VenueTable t) => _toJson(t);

Future<Response> _broadcast(AppDatabase db, WsHub hub, String id) async {
  final row = await (db.select(db.venueTables)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
  if (row == null) return Response.notFound('table not found');
  hub.broadcast(WsEventTypes.tableUpdated, _toJson(row));
  return Response.ok(jsonEncode(_toJson(row)),
      headers: {'content-type': 'application/json'});
}

/// Active takeaway visit → JSON for the Floor strip + detail. Lean: status is
/// derived client-side from the visit's tickets. See ADR-0026.
Map<String, dynamic> _visitToJson(Visit v) => {
      'id': v.id,
      'tableLabel': v.tableLabel,
      'guestName': v.guestName,
      'guestNotes': v.guestNotes,
      'openedAt': v.openedAt?.toIso8601String(),
      'tableFreedAt': v.tableFreedAt?.toIso8601String(),
      'billClosedAt': v.billClosedAt?.toIso8601String(),
    };

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
      'guestName': t.guestName,
      'guestNotes': t.guestNotes,
      'reservationId': t.reservationId,
      'billClosedAt': t.billClosedAt?.toIso8601String(),
      'moneyState': t.moneyState,
    };
