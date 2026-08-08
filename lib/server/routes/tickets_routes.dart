import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tables_routes.dart'
    show ensureVisit, syncVisitMoney, createTakeawayVisit;
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/ticket.dart'
    show TicketStatus, ticketStatusFromKey;
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';

const _allowedTransitions = <TicketStatus, Set<TicketStatus>>{
  TicketStatus.draft: {TicketStatus.sent, TicketStatus.voided},
  TicketStatus.acknowledged: {TicketStatus.prep, TicketStatus.voided},
  TicketStatus.sent: {
    TicketStatus.prep,
    TicketStatus.cooked,
    TicketStatus.held,
    TicketStatus.voided,
  },
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
  // Pre-serve voids are self-served by any waiter holding voidItem (ADR-0006).
  // Voiding an already-served item is a comp/refund — a manager power — so it
  // routes through compItem instead.
  if (to == TicketStatus.voided) {
    return from == TicketStatus.served
        ? Capability.compItem
        : Capability.voidItem;
  }
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

/// Whether the caller holds [needed]. Unlike [_requireCap] this answers a
/// question rather than blocking — used for `overrideStock`, which changes what
/// a submit does instead of whether it is allowed.
Future<bool> _hasCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  // No auth helper configured (server-mode boot before the secret loads) means
  // nobody has *proved* they hold this. `_requireCap` opens up in that window
  // because it gates ordinary work; this one gates a safety bypass, and a
  // bypass that silently switches itself on is the wrong default.
  if (auth == null) return false;
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  final user = await auth.resolveBearer(token);
  if (user == null) return false;
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  if (role == null) return false;
  return (jsonDecode(role.capabilitiesJson) as List).cast<String>().contains(
    needed.name,
  );
}

/// Resolve the bearer-token user for void attribution. Null when no auth
/// helper is configured (server-mode boot before secret loaded).
Future<User?> _actor(Request req, AppDatabase db, ServerAuth? auth) async {
  if (auth == null) return null;
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  return auth.resolveBearer(token);
}

const _voidReasonLabels = <String, String>{
  'wrongOrder': 'Terkirim salah',
  'customerChange': 'Tamu berubah pikiran',
  'outOfStock': 'Stok habis',
  'kitchenError': 'Komplain / kualitas dapur',
  'comp': 'Kompensasi manajer',
  'other': 'Lainnya',
};

/// Persist + broadcast a void audit row stamped with the acting waiter.
///
/// A comp is a void carrying reason code `comp` (ADR-0006) — the same
/// transition, a different permission. It is typed as [AuditType.comp] here so
/// the venue log can count the two apart; without this split every giveaway
/// reads as a cancellation and the comp tile is stuck at zero. Rows written
/// before this existed stay `voidItem`.
Future<void> _emitVoidAudit(
  AppDatabase db,
  WsHub hub, {
  required Ticket ticket,
  required String reasonCode,
  required String? reasonText,
  String? actorUserId,
}) async {
  final reason = (reasonText != null && reasonText.trim().isNotEmpty)
      ? reasonText
      : (_voidReasonLabels[reasonCode] ?? reasonCode);
  final isComp = reasonCode == 'comp';
  final value = ticket.price * ticket.qty;
  final amount = auditRupiah(value);
  await writeAudit(
    db,
    hub: hub,
    type: isComp ? AuditType.comp : AuditType.voidItem,
    kind: isComp ? AuditKind.comp : AuditKind.voidItem,
    params: {'qty': '${ticket.qty}', 'name': ticket.name, 'amount': amount},
    tableId: ticket.tableId,
    reason: reason,
    actorUserId: actorUserId,
    amountCents: value,
  );
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
  'openedAt': t.openedAt?.toIso8601String(),
};

const _orderUuid = Uuid();

/// One submitted order, written exactly the way `POST /orders` writes it.
///
/// Extracted from the route handler so the [[Generic seed (sample data)|sample seed]]
/// can replay a month of service through the **production** path — idempotency
/// claim, visit resolution, recipe coverage, per-line stock rejection, ticket
/// insert, consumption, table transition — rather than inserting rows that
/// merely look like orders (ADR-0053 §5). The handler parses the request and
/// broadcasts; everything that touches the database lives here.
class SubmitOrderResult {
  final List<String> createdIds;
  final List<Ticket> createdRows;
  final List<Map<String, dynamic>> rejected;
  final VenueTable? tableRow;
  final String? visitId;
  final String? storedResponse;

  const SubmitOrderResult({
    required this.createdIds,
    required this.createdRows,
    required this.rejected,
    this.tableRow,
    this.visitId,
    this.storedResponse,
  });
}

Future<SubmitOrderResult> submitOrder(
  AppDatabase db, {
  required String tableId,
  required String idem,
  required List<Map<String, dynamic>> lines,
  bool takeaway = false,
  String? guestName,

  /// How a takeaway reached the venue, and whether an aggregator already
  /// settled it. Ignored for dine-in. ADR-0066.
  String takeawayChannel = 'bungkus',
  bool takeawayPrepaid = false,
  String? appendVisitId,
  String? actorId,
  bool canOverrideStock = false,

  /// Write these timestamps instead of "now". The demo seed replays a month
  /// through this function and must stamp each order at its own moment —
  /// without dragging the running app's clock around while it does
  /// (ADR-0053 §5). Production callers pass nothing.
  DateTime? at,

  /// Prefix applied to every id this call mints — tickets and their stock
  /// movements. The demo seed passes its tag so reset can delete by it
  /// (ADR-0053 §5); production callers pass nothing.
  String? idPrefix,
}) async {
  final stamp = at ?? SatClock.now();
  final createdIds = <String>[];
  final createdRows = <Ticket>[];
  final rejected = <Map<String, dynamic>>[];
  VenueTable? tableRow;
  String? storedResponse;
  String? orderVisitId;
  await db.transaction(() async {
    // Claim the idempotency key atomically; primary-key conflict means
    // a concurrent request already took it.
    final existing = await (db.select(
      db.idempotency,
    )..where((k) => k.key.equals(idem))).getSingleOrNull();
    if (existing != null) {
      storedResponse = existing.responseJson;
      return;
    }
    // Resolve the visit (the bill key). Dine-in lazily ensures the table's
    // visit; takeaway mints a brand-new table-less one. See ADR-0024/0026.
    final String visitId;
    if (takeaway) {
      if (appendVisitId != null && appendVisitId.isNotEmpty) {
        visitId = appendVisitId;
      } else {
        final v = await createTakeawayVisit(
          db,
          guestName: (guestName != null && guestName.isNotEmpty)
              ? guestName
              : 'Bawa pulang',
          actorId: actorId,
          // ADR-0066. Defaults to a walk-in wanting it wrapped, which is what
          // every takeaway was before the channel existed.
          channel: takeawayChannel,
          prepaid: takeawayPrepaid,
        );
        visitId = v.id;
      }
    } else {
      visitId = await ensureVisit(db, tableId, actorId: actorId);
    }
    orderVisitId = visitId;
    // Ingredient coverage (ADR-0041). Stock moves at **send** — the last
    // point at which refusing a line is still cheap. `running` is mutated as
    // lines are accepted, so two lines of the same order competing for the
    // last portion resolve consistently.
    final recipes = await loadRecipes(db);
    final ingredientRows = await db.select(db.ingredients).get();
    final running = {for (final i in ingredientRows) i.id: i.stockOnHand};
    final ingredientNames = {for (final i in ingredientRows) i.id: i.name};
    // Tickets carry the variant *name*, not its id, so the id is resolved
    // here against the menu as it reads right now.
    final variantNameMaps = <String, Map<String, String>>{};

    for (final l in lines) {
      final id = '${idPrefix ?? ''}${_orderUuid.v4()}';
      final course = l['course'] as String;
      // "Kirim ke dapur" is an explicit fire action: every line enters
      // the KDS queue as `sent`. Course pacing is purely a sort/grouping
      // hint for the kitchen, not a gate.
      final itemId = l['itemId'] as String;
      final lineQty = (l['qty'] as num?)?.toInt() ?? 1;
      final lineVariant = (l['variantName'] as String?) ?? '';
      if (!variantNameMaps.containsKey(itemId)) {
        final item = await (db.select(
          db.menuItems,
        )..where((i) => i.id.equals(itemId))).getSingleOrNull();
        variantNameMaps[itemId] = item == null
            ? const {}
            : variantIdsByName(item.variantsJson);
      }
      final need = await needForLine(
        db,
        itemId: itemId,
        variantName: lineVariant,
        optionIds: [
          for (final m in (l['modifiers'] as List? ?? const []))
            if (m is Map && (m['optionId'] as String?)?.isNotEmpty == true)
              m['optionId'] as String,
        ],
        qty: lineQty,
        recipes: recipes,
        running: running,
        ingredientNames: ingredientNames,
        variantIdsByName: variantNameMaps[itemId]!,
      );
      if (!need.covered && !canOverrideStock) {
        // Reject ONLY this line — one out-of-stock side dish must not kill a
        // twelve-item order the waiter would have to re-key (ADR-0041).
        rejected.add({
          'itemId': itemId,
          'name': (l['name'] as String?) ?? itemId,
          'variantName': lineVariant,
          'ingredients': need.shortNames,
        });
        continue;
      }

      final row = TicketsCompanion.insert(
        id: id,
        tableId: tableId,
        visitId: Value(visitId),
        itemId: itemId,
        name: (l['name'] as String?) ?? l['itemId'] as String,
        variantName: Value((l['variantName'] as String?) ?? ''),
        course: course,
        qty: Value((l['qty'] as num?)?.toInt() ?? 1),
        // Structured add-on snapshot, built client-side and stored
        // verbatim. See docs/adr/0011-ticket-modifier-snapshot.md.
        modifiersJson: Value(jsonEncode(l['modifiers'] ?? const [])),
        note: Value(l['note'] as String?),
        price: (l['unitPrice'] as num).toInt(),
        status: 'sent',
        sentAt: stamp,
        createdByUserId: Value(actorId),
      );
      await db.into(db.tickets).insert(row);
      // Deduct inside the existing idempotency-keyed transaction, so a
      // retried submit can never double-deduct (ADR-0041). An overridden
      // line still writes its movements — the balance goes negative on
      // purpose, as the "your counts are wrong" signal.
      if (need.need.isNotEmpty) {
        await consumeForTicket(
          db,
          at: at,
          idPrefix: idPrefix,
          ticketId: id,
          need: need.need,
          sourceLabel: [
            (l['name'] as String?) ?? itemId,
            if (lineVariant.isNotEmpty) lineVariant,
          ].join(' · '),
          userId: actorId,
        );
        for (final e in need.need.entries) {
          running[e.key] = (running[e.key] ?? 0) - e.value;
        }
      }
      createdIds.add(id);
      final full = await (db.select(
        db.tickets,
      )..where((t) => t.id.equals(id))).getSingle();
      createdRows.add(full);
    }
    await db
        .into(db.idempotency)
        .insert(
          IdempotencyCompanion.insert(
            key: idem,
            responseJson: jsonEncode({
              'ticketIds': createdIds,
              'visitId': visitId,
              if (rejected.isNotEmpty) 'rejected': rejected,
            }),
            createdAt: stamp,
          ),
        );
    // Every line rejected for stock ⇒ nothing was actually ordered, so the
    // table must not be flipped to `pending` with no lines behind it.
    if (!takeaway && createdIds.isNotEmpty) {
      // Mark the table `pending` in the same transaction so that all
      // clients observe ticket-creation and table-state changes together
      // and never see one without the other. Set openedAt only on the
      // first order (when the table transitions from available to pending).
      final tblCurrent = await (db.select(
        db.venueTables,
      )..where((t) => t.id.equals(tableId))).getSingleOrNull();
      await (db.update(
        db.venueTables,
      )..where((t) => t.id.equals(tableId))).write(
        VenueTablesCompanion(
          status: const Value('pending'),
          lastActorId: Value(actorId),
          openedAt: tblCurrent?.openedAt == null
              ? Value(stamp)
              : const Value.absent(),
        ),
      );
      tableRow = await (db.select(
        db.venueTables,
      )..where((t) => t.id.equals(tableId))).getSingleOrNull();
    }
  });
  return SubmitOrderResult(
    createdIds: createdIds,
    createdRows: createdRows,
    rejected: rejected,
    tableRow: tableRow,
    visitId: orderVisitId,
    storedResponse: storedResponse,
  );
}

Router ticketsRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

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
    // Takeaway (Bawa pulang): no table, a fresh `kind==takeaway` visit per
    // order, guestName required. The table mutation is skipped entirely.
    // See ADR-0026.
    final takeaway = body['takeaway'] == true;
    final tableId = takeaway ? '' : body['tableId'] as String;
    final guestName = (body['guestName'] as String?)?.trim();
    final appendVisitId = (body['visitId'] as String?)?.trim();
    final idem = body['idempotencyKey'] as String;
    final lines = (body['lines'] as List).cast<Map<String, dynamic>>();
    final actorId = body['actorId'] as String?;

    // `overrideStock` is the pressure valve for the venue whose counts have
    // drifted: it sends anyway and still writes the movement, so the balance
    // goes negative as a visible "go do an opname" signal (ADR-0041).
    final canOverrideStock = await _hasCap(
      req,
      db,
      auth,
      Capability.overrideStock,
    );

    final res = await submitOrder(
      db,
      tableId: tableId,
      idem: idem,
      lines: lines,
      takeaway: takeaway,
      guestName: guestName,
      takeawayChannel: (body['channel'] as String?) ?? 'bungkus',
      takeawayPrepaid: body['prepaid'] == true,
      appendVisitId: appendVisitId,
      actorId: actorId,
      canOverrideStock: canOverrideStock,
    );
    final createdIds = res.createdIds;
    final createdRows = res.createdRows;
    final rejected = res.rejected;
    final tableRow = res.tableRow;
    final orderVisitId = res.visitId;
    final storedResponse = res.storedResponse;

    if (storedResponse != null) {
      return Response.ok(
        storedResponse,
        headers: {'content-type': 'application/json'},
      );
    }
    for (final t in createdRows) {
      hub.broadcast(WsEventTypes.ticketCreated, _toJson(t));
    }
    if (tableRow != null) {
      hub.broadcast(WsEventTypes.tableUpdated, _tableToJson(tableRow));
    }
    if (orderVisitId != null) {
      // Dine-in: refresh the floor money badge. Takeaway: no attached table so
      // syncVisitMoney no-ops; nudge the cashier list/detail to re-fetch.
      if (takeaway) {
        hub.broadcast(WsEventTypes.billUpdated, {'visitId': orderVisitId});
      } else {
        await syncVisitMoney(db, hub, orderVisitId);
      }
    }
    // Re-broadcast the menu only when a derived habis flag actually flipped —
    // beras going 8.0 → 7.8 kg must stay silent (ADR-0040).
    if (createdIds.isNotEmpty && await stockFlags.refreshAndDetectFlip(db)) {
      hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'stock'});
    }
    return Response.ok(
      jsonEncode({
        'ticketIds': createdIds,
        'visitId': orderVisitId,
        if (rejected.isNotEmpty) 'rejected': rejected,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  /// Edit a line the kitchen does not yet own. Body: `{qty?, note?,
  /// modifiers?, unitPrice?}`.
  ///
  /// **Only a `held` line may change.** Once a line is fired it belongs to the
  /// station, and the cook's copy is the order — a waiter cannot rewrite what
  /// someone is already cooking, so from `sent` onward the sole remedy is a
  /// void with a reason. That freeze is the whole rule; this route enforces it
  /// with a 409 rather than trusting the UI to hide the button. See
  /// docs/adr/0071-kitchen-ownership-freezes-a-line.md.
  ///
  /// Variant is deliberately *not* editable: a different variant is a
  /// different dish at a different price, and often a different station.
  ///
  /// Like the create path, the client owns the modifier snapshot and its
  /// resolved unit price (ADR-0011) — the server stores both verbatim. The
  /// audit row carries the before/after value so a price that moves without a
  /// matching modifier change is visible after the fact.
  r.patch('/tickets/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.modifyOrder);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final current = await (db.select(
      db.tickets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (current == null) return Response.notFound('ticket not found');

    if (ticketStatusFromKey(current.status) != TicketStatus.held) {
      return Response(
        409,
        body: jsonEncode({
          'code': 'line_frozen',
          'message':
              'hanya pesanan tertahan yang bisa diubah — '
              'batalkan bila sudah masuk dapur',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final newQty = (body['qty'] as num?)?.toInt() ?? current.qty;
    if (newQty < 1) {
      return Response(
        400,
        body: jsonEncode({
          'code': 'bad_qty',
          'message': 'qty must be >= 1 — void the line instead',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final newNote = body.containsKey('note')
        ? (body['note'] as String?)
        : current.note;
    final modsChanged = body.containsKey('modifiers');
    final newModsJson = modsChanged
        ? jsonEncode(body['modifiers'] ?? const [])
        : current.modifiersJson;
    final newPrice = (body['unitPrice'] as num?)?.toInt() ?? current.price;

    final actor = await _actor(req, db, auth);
    Ticket? row;
    await db.transaction(() async {
      // Re-book stock from scratch rather than diffing: the line was never
      // touched by the kitchen, so the old consumption reverses cleanly, and a
      // modifier swap can change *which* ingredients are needed, not just how
      // many. `untouched: true` is safe precisely because of the held rule
      // above — nothing has been cooked, so nothing is wasted.
      if (newQty != current.qty || modsChanged) {
        await reverseTicketStock(
          db,
          ticketId: id,
          untouched: true,
          userId: actor?.id,
          note: 'Ubah pesanan',
        );
        final recipes = await loadRecipes(db);
        final ingredientRows = await db.select(db.ingredients).get();
        final item = await (db.select(
          db.menuItems,
        )..where((i) => i.id.equals(current.itemId))).getSingleOrNull();
        final need = await needForLine(
          db,
          itemId: current.itemId,
          variantName: current.variantName,
          optionIds: optionIdsOf(newModsJson),
          qty: newQty,
          recipes: recipes,
          running: {for (final i in ingredientRows) i.id: i.stockOnHand},
          ingredientNames: {for (final i in ingredientRows) i.id: i.name},
          variantIdsByName: item == null
              ? const {}
              : variantIdsByName(item.variantsJson),
        );
        if (need.need.isNotEmpty) {
          await consumeForTicket(
            db,
            ticketId: id,
            need: need.need,
            sourceLabel: current.name,
            userId: actor?.id,
          );
        }
      }

      await (db.update(db.tickets)..where((t) => t.id.equals(id))).write(
        TicketsCompanion(
          qty: Value(newQty),
          note: Value(newNote),
          modifiersJson: Value(newModsJson),
          price: Value(newPrice),
        ),
      );
      row = await (db.select(
        db.tickets,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
    });

    final before = current.price * current.qty;
    final after = newPrice * newQty;
    await writeAudit(
      db,
      hub: hub,
      type: AuditType.modify,
      kind: current.qty == newQty ? AuditKind.modify : AuditKind.modifyQty,
      params: {
        'name': current.name,
        if (current.qty != newQty) ...{
          'oldQty': '${current.qty}',
          'newQty': '$newQty',
        },
      },
      tableId: current.tableId,
      actorUserId: actor?.id,
      reason: before == after
          ? null
          : '${auditRupiah(before)} → ${auditRupiah(after)}',
      // The magnitude of the change, not the new total — the tile answers
      // "how much did edits move", which a full line value would drown.
      amountCents: (after - before).abs(),
    );

    if (row != null) hub.broadcast(WsEventTypes.ticketUpdated, _toJson(row!));
    return Response.ok(
      jsonEncode(_toJson(row!)),
      headers: {'content-type': 'application/json'},
    );
  });

  r.post('/tickets/<id>/transition', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final statusRaw = body['status'] as String;
    final current = await (db.select(
      db.tickets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (current == null) return Response.notFound('ticket not found');
    final from = ticketStatusFromKey(current.status);
    final to = ticketStatusFromKey(statusRaw);
    final allowed = _allowedTransitions[from] ?? const <TicketStatus>{};
    if (!allowed.contains(to)) {
      return Response(
        409,
        body: jsonEncode({
          'code': 'illegal_transition',
          'message': '${current.status} -> $statusRaw',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final needed = _requiredCap(from, to);
    if (needed != null) {
      final denied = await _requireCap(req, db, auth, needed);
      if (denied != null) return denied;
    }
    // Void requires a reason + canonical code so reports can attribute lost
    // revenue (ADR-0006). UI-only enforcement is insufficient now the manager
    // gate is gone.
    final isVoid = to == TicketStatus.voided;
    final voidReason = body['voidReason'] as String?;
    final voidReasonCode = body['voidReasonCode'] as String?;
    if (isVoid &&
        (voidReason == null ||
            voidReason.trim().isEmpty ||
            voidReasonCode == null ||
            voidReasonCode.trim().isEmpty)) {
      return Response(
        400,
        body: jsonEncode({
          'code': 'reason_required',
          'message': 'void requires voidReason and voidReasonCode',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final actor = isVoid ? await _actor(req, db, auth) : null;
    // Speed-of-service stamps (ADR-0013). readyAt set-once on first entry into
    // `ready` (so a served→ready undo never inflates prep time); servedAt
    // last-write on every entry into `served`.
    final stampNow = SatClock.now();
    final stampReady = to == TicketStatus.ready && current.readyAt == null;
    final stampServed = to == TicketStatus.served;
    // ADR-0043: firing a held line hands it to the kitchen now — the prep
    // clock starts here, not at `sentAt` (when the guest ordered it).
    final stampFired = from == TicketStatus.held && to == TicketStatus.sent;
    Ticket? row;
    VenueTable? tableRow;
    await db.transaction(() async {
      await (db.update(db.tickets)..where((t) => t.id.equals(id))).write(
        TicketsCompanion(
          status: Value(statusRaw),
          firedAt: stampFired ? Value(stampNow) : const Value.absent(),
          readyAt: stampReady ? Value(stampNow) : const Value.absent(),
          servedAt: stampServed ? Value(stampNow) : const Value.absent(),
          voidReason: Value(voidReason),
          voidReasonCode: Value(voidReasonCode),
          voidApprovedBy: Value(body['voidApprovedBy'] as String?),
          voidedByUserId: Value(actor?.id),
        ),
      );
      row = await (db.select(
        db.tickets,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return;
      if (isVoid) {
        // Restock only when the kitchen never started the line. The test is the
        // line's lifecycle status — a kitchen fact already on the ticket —
        // rather than the waiter's stated reason, which would wrongly restock a
        // `customerChange` on a plated dish (ADR-0041).
        await reverseTicketStock(
          db,
          ticketId: id,
          untouched: from == TicketStatus.sent,
          userId: actor?.id,
          note: voidReason,
        );
      }
      // Maintain table.readyCount and table.status atomically in the same
      // transition. Entering `ready` bumps the count and flips the table
      // to `ready`; leaving `ready` (served / voided) decrements it and
      // falls back to `occupied` once the last ready item clears.
      final tableId = row!.tableId;
      final tbl = await (db.select(
        db.venueTables,
      )..where((t) => t.id.equals(tableId))).getSingleOrNull();
      if (tbl == null) return;
      final wasReady = from == TicketStatus.ready;
      final isReady = to == TicketStatus.ready;
      if (!wasReady && isReady) {
        final n = tbl.readyCount + 1;
        await (db.update(
          db.venueTables,
        )..where((t) => t.id.equals(tableId))).write(
          VenueTablesCompanion(
            readyCount: Value(n),
            status: const Value('ready'),
          ),
        );
      } else if (wasReady && !isReady) {
        final n = (tbl.readyCount - 1).clamp(0, 1 << 30);
        final nextStatus = (tbl.status == 'ready' && n == 0)
            ? 'occupied'
            : tbl.status;
        await (db.update(
          db.venueTables,
        )..where((t) => t.id.equals(tableId))).write(
          VenueTablesCompanion(readyCount: Value(n), status: Value(nextStatus)),
        );
      }

      tableRow = await (db.select(
        db.venueTables,
      )..where((t) => t.id.equals(tableId))).getSingleOrNull();
    });
    if (row == null) return Response.notFound('ticket not found');
    if (isVoid) {
      await _emitVoidAudit(
        db,
        hub,
        ticket: row!,
        reasonCode: voidReasonCode!,
        reasonText: voidReason,
        actorUserId: actor?.id,
      );
    }
    hub.broadcast(WsEventTypes.ticketUpdated, _toJson(row!));
    if (tableRow != null) {
      hub.broadcast(WsEventTypes.tableUpdated, _tableToJson(tableRow!));
    }
    // Void/serve change the bill subtotal — refresh the floor money badge.
    final rvid = row!.visitId;
    if (rvid != null) await syncVisitMoney(db, hub, rvid);
    // A restocked void can make a habis item orderable again.
    if (isVoid && await stockFlags.refreshAndDetectFlip(db)) {
      hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'stock'});
    }
    return Response.ok(
      jsonEncode(_toJson(row!)),
      headers: {'content-type': 'application/json'},
    );
  });

  // Table-scoped course fire. Only flips `held` rows for the given
  // (tableId, course) so firing one table's course never leaks across
  // tables. Returns the updated ticket rows so the caller can merge them
  // alongside the WS broadcast.
  r.post('/tables/<tableId>/course/<course>/fire', (
    Request req,
    String tableId,
    String course,
  ) async {
    final denied = await _requireCap(req, db, auth, Capability.takeOrder);
    if (denied != null) return denied;
    final updated = <Ticket>[];
    await db.transaction(() async {
      await (db.update(db.tickets)..where(
            (t) =>
                t.tableId.equals(tableId) &
                t.course.equals(course) &
                t.status.equals('held'),
          ))
          // One write ⇒ every line of the course shares an identical
          // `firedAt`, which is what groups them as one course (ADR-0043).
          .write(
            TicketsCompanion(
              status: const Value('sent'),
              firedAt: Value(SatClock.now()),
            ),
          );
      final rows =
          await (db.select(db.tickets)..where(
                (t) =>
                    t.tableId.equals(tableId) &
                    t.course.equals(course) &
                    t.status.equals('sent'),
              ))
              .get();
      updated.addAll(rows);
    });
    for (final t in updated) {
      hub.broadcast(WsEventTypes.ticketUpdated, _toJson(t));
    }
    // Firing held→sent grows the bill — refresh the floor money badge.
    final fireVid = updated.isNotEmpty ? updated.first.visitId : null;
    if (fireVid != null) await syncVisitMoney(db, hub, fireVid);
    return Response.ok(
      jsonEncode({
        'fired': updated.length,
        'tickets': [for (final t in updated) _toJson(t)],
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}

Map<String, dynamic> _toJson(Ticket t) => {
  'id': t.id,
  'tableId': t.tableId,
  // The stable bill key, independent of tableId. Lets the client/KDS label
  // table-less (takeaway) lines via the visit. See ADR-0024 / ADR-0026.
  'visitId': t.visitId,
  'itemId': t.itemId,
  'name': t.name,
  'variantName': t.variantName,
  'course': t.course,
  'station': 'kitchen',
  'qty': t.qty,
  'modifiers': jsonDecode(t.modifiersJson),
  'note': t.note,
  'price': t.price,
  'status': t.status,
  'sentAt': t.sentAt.toIso8601String(),
  'firedAt': t.firedAt?.toIso8601String(),
  'readyAt': t.readyAt?.toIso8601String(),
  'servedAt': t.servedAt?.toIso8601String(),
  'voidReason': t.voidReason,
  'voidReasonCode': t.voidReasonCode,
  'voidApprovedBy': t.voidApprovedBy,
  'createdByUserId': t.createdByUserId,
  'voidedByUserId': t.voidedByUserId,
};
