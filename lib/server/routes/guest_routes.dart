import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/menu_routes.dart'
    show guestMenuSnapshot, menuItemPhotoBytes;
import 'package:satset/server/routes/tables_routes.dart' show ensureVisit;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Default course for guest self-order lines — staff re-course at approval
/// (ADR-0028). 'mains' is the venue's catch-all course slug.
const _guestDefaultCourse = 'mains';

const _maxNoteLen = 140;
const _maxQty = 99;

/// The guest self-order API (ADR-0027). Mounted **only** on the cleartext
/// guest listener — never the TLS staff router. Every route except
/// `/guest/session` requires a `guest`-scope token bound to a live dine-in
/// visit; the token can never satisfy the staff bearer path (no session row).
Router guestRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  // ── Mint a table-scoped guest session ───────────────────────────────────
  // POST /guest/session?table=<tableId>. Checks the venue master toggle + the
  // table opt-in, auto-opens the table's visit (self-seat), returns a 2h token.
  r.post('/guest/session', (Request req) async {
    final tableId = req.url.queryParameters['table'];
    if (tableId == null || tableId.isEmpty) {
      return _err(400, 'missing table');
    }
    final settings = await (db.select(db.venueSettings)
          ..where((s) => s.id.equals('default')))
        .getSingleOrNull();
    if (settings == null || !settings.guestOrderingEnabled) {
      return _err(403, 'guest_ordering_disabled');
    }
    final table = await (db.select(db.venueTables)
          ..where((t) => t.id.equals(tableId)))
        .getSingleOrNull();
    if (table == null) return _err(404, 'table_not_found');
    if (!table.guestOrderingEnabled) {
      return _err(403, 'table_disabled');
    }
    // Auto-open the table's live visit (self-seat). Dine-in only.
    final visitId = await ensureVisit(db, tableId);
    final token = auth.mintGuestToken(tableId: tableId, visitId: visitId);
    SatLog.srv('guest session table=$tableId visit=$visitId');
    return _json({
      'token': token,
      'tableId': tableId,
      'tableLabel': table.label,
      'visitId': visitId,
      'expiresInSec': ServerAuth.guestTokenTtl.inSeconds,
    });
  });

  // ── Guest-visible menu ───────────────────────────────────────────────────
  r.get('/guest/menu', (Request req) async {
    if (await _guest(req, db, auth) == null) return _err(401, 'unauthorized');
    return _json(await guestMenuSnapshot(db));
  });

  // ── Menu item photo (lazy-loaded by the SPA) ─────────────────────────────
  r.get('/guest/menu/photo/<itemId>', (Request req, String itemId) async {
    if (await _guest(req, db, auth) == null) return _err(401, 'unauthorized');
    final bytes = await menuItemPhotoBytes(db, itemId);
    if (bytes == null) return Response.notFound('no photo');
    return Response.ok(bytes, headers: {
      'content-type': 'image/jpeg',
      'cache-control': 'public, max-age=86400',
    });
  });

  // ── Submit a self-order batch ────────────────────────────────────────────
  // Lands as `pendingReview` tickets — never fires to the kitchen until a
  // waiter approves. Server is authoritative on price + required modifiers.
  r.post('/guest/orders', (Request req) async {
    final claims = await _guest(req, db, auth);
    if (claims == null) return _err(401, 'unauthorized');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final idem = (body['idempotencyKey'] as String?)?.trim();
    if (idem == null || idem.isEmpty) return _err(400, 'missing idempotencyKey');
    final rawLines = body['lines'];
    if (rawLines is! List || rawLines.isEmpty) return _err(400, 'empty order');

    // Rate-limit: at most one pending batch per visit (ADR-0028). A guest must
    // wait for staff to clear the current batch before sending another.
    final existingPending = await (db.select(db.tickets)
          ..where((t) =>
              t.visitId.equals(claims.visitId) &
              t.status.equals('pendingReview')))
        .get();
    if (existingPending.isNotEmpty) {
      return _err(429, 'pending_batch_open');
    }

    // Price + validate every line server-side before writing anything.
    final priced = <_PricedLine>[];
    for (final raw in rawLines) {
      if (raw is! Map) return _err(400, 'bad line');
      final res = await _priceLine(db, raw.cast<String, dynamic>());
      if (res.error != null) return _err(400, res.error!);
      priced.add(res.line!);
    }

    final createdIds = <String>[];
    final createdRows = <Ticket>[];
    String? storedResponse;
    await db.transaction(() async {
      final existing = await (db.select(db.idempotency)
            ..where((k) => k.key.equals(idem)))
          .getSingleOrNull();
      if (existing != null) {
        storedResponse = existing.responseJson;
        return;
      }
      // Re-check the visit is still orderable inside the txn (closed/detached
      // visit ⇒ the party left / bill locked ⇒ token is stale).
      final visit = await (db.select(db.visits)
            ..where((v) => v.id.equals(claims.visitId)))
          .getSingleOrNull();
      if (visit == null ||
          visit.billClosedAt != null ||
          visit.tableFreedAt != null) {
        throw _VisitClosed();
      }
      for (final pl in priced) {
        final id = _uuid.v4();
        await db.into(db.tickets).insert(TicketsCompanion.insert(
              id: id,
              tableId: claims.tableId,
              visitId: Value(claims.visitId),
              itemId: pl.itemId,
              name: pl.name,
              variantName: Value(pl.variantName),
              course: _guestDefaultCourse,
              qty: Value(pl.qty),
              modifiersJson: Value(jsonEncode(pl.modifiers)),
              note: Value(pl.note),
              price: pl.unitPrice,
              status: 'pendingReview',
              sentAt: DateTime.now(),
            ));
        createdIds.add(id);
        final full =
            await (db.select(db.tickets)..where((t) => t.id.equals(id)))
                .getSingle();
        createdRows.add(full);
      }
      await db.into(db.idempotency).insert(IdempotencyCompanion.insert(
            key: idem,
            responseJson: jsonEncode({'ticketIds': createdIds}),
            createdAt: DateTime.now(),
          ));
    }).catchError((Object e) {
      if (e is _VisitClosed) return;
      throw e;
    });

    if (storedResponse != null) {
      return _json(jsonDecode(storedResponse!) as Map<String, dynamic>);
    }
    if (createdRows.isEmpty) {
      // The txn bailed because the visit closed.
      return _err(409, 'visit_closed');
    }

    // Announce to the staff review queue.
    hub.broadcast(WsEventTypes.guestOrderSubmitted, {
      'tableId': claims.tableId,
      'visitId': claims.visitId,
      'ticketIds': createdIds,
    });
    SatLog.srv('guest order visit=${claims.visitId} lines=${createdIds.length}');
    return _json({'ticketIds': createdIds, 'status': 'pendingReview'});
  });

  // ── Poll order status for this guest session ─────────────────────────────
  r.get('/guest/orders', (Request req) async {
    final claims = await _guest(req, db, auth);
    if (claims == null) return _err(401, 'unauthorized');
    final rows = await (db.select(db.tickets)
          ..where((t) => t.visitId.equals(claims.visitId))
          ..orderBy([(t) => OrderingTerm(expression: t.sentAt)]))
        .get();
    return _json({
      'orders': [
        for (final t in rows)
          {
            'id': t.id,
            'name': t.name,
            'variantName': t.variantName,
            'qty': t.qty,
            'status': t.status,
          },
      ],
    });
  });

  return r;
}

/// Resolve + authorize a guest request: a valid `guest`-scope token bound to a
/// still-open dine-in visit. Returns null (caller → 401) otherwise.
Future<GuestClaims?> _guest(
    Request req, AppDatabase db, ServerAuth auth) async {
  final header = req.headers['authorization'];
  final token = header?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  final claims = auth.resolveGuest(token);
  if (claims == null) return null;
  final visit = await (db.select(db.visits)
        ..where((v) => v.id.equals(claims.visitId)))
      .getSingleOrNull();
  if (visit == null ||
      visit.billClosedAt != null ||
      visit.tableFreedAt != null) {
    return null;
  }
  return claims;
}

/// Server-authoritative pricing + modifier validation for one guest line.
/// Never trusts a client-sent price. Input: {itemId, variantId?, optionIds?,
/// qty?, note?}.
Future<_PriceResult> _priceLine(
    AppDatabase db, Map<String, dynamic> raw) async {
  final itemId = raw['itemId'];
  if (itemId is! String || itemId.isEmpty) return _PriceResult.err('bad itemId');
  final item =
      await (db.select(db.menuItems)..where((i) => i.id.equals(itemId)))
          .getSingleOrNull();
  if (item == null) return _PriceResult.err('item_not_found');
  if (item.unavailable) return _PriceResult.err('item_unavailable');
  if (item.autoSoldOutAtZero && (item.stockCount ?? 0) <= 0) {
    return _PriceResult.err('item_sold_out');
  }

  final qty = (raw['qty'] as num?)?.toInt() ?? 1;
  if (qty < 1 || qty > _maxQty) return _PriceResult.err('bad_qty');

  // Variant → base price (variant price is absolute, not a delta).
  final variants = (jsonDecode(item.variantsJson) as List).cast<Map>();
  var basePrice = item.basePrice;
  var variantName = '';
  final variantId = raw['variantId'];
  if (variants.isNotEmpty) {
    if (variantId is! String) return _PriceResult.err('variant_required');
    final v = variants.firstWhere(
      (x) => x['id'] == variantId,
      orElse: () => const {},
    );
    if (v.isEmpty) return _PriceResult.err('bad_variant');
    basePrice = (v['price'] as num).toInt();
    variantName = (v['name'] as String?) ?? '';
  } else if (variantId is String && variantId.isNotEmpty) {
    return _PriceResult.err('no_variants');
  }

  // Modifiers: validate against the item's embedded groups, build the frozen
  // snapshot ({groupId, optionId, label, priceDelta}), sum the deltas.
  final groups = (jsonDecode(item.modifierGroupsJson) as List).cast<Map>();
  final selectedIds =
      ((raw['optionIds'] as List?) ?? const []).whereType<String>().toSet();
  final snapshot = <Map<String, dynamic>>[];
  var modDelta = 0;
  final claimed = <String>{};
  for (final g in groups) {
    final opts = (g['options'] as List).cast<Map>();
    final chosen =
        opts.where((o) => selectedIds.contains(o['id'] as String)).toList();
    if ((g['required'] == true) && chosen.isEmpty) {
      return _PriceResult.err('modifier_required');
    }
    if ((g['multi'] != true) && chosen.length > 1) {
      return _PriceResult.err('modifier_single_only');
    }
    for (final o in chosen) {
      final delta = (o['priceDelta'] as num?)?.toInt() ?? 0;
      modDelta += delta;
      claimed.add(o['id'] as String);
      snapshot.add({
        'groupId': g['id'],
        'optionId': o['id'],
        'label': o['name'],
        'priceDelta': delta,
      });
    }
  }
  // Any selected id not belonging to a real group is rejected.
  if (!claimed.containsAll(selectedIds)) {
    return _PriceResult.err('unknown_modifier');
  }

  final unitPrice = basePrice + modDelta;
  if (unitPrice < 0) return _PriceResult.err('bad_price');

  var note = (raw['note'] as String?)?.trim();
  if (note != null) {
    note = note.replaceAll(RegExp("[\x00-\x1F\x7F]"), " ").trim();
    if (note.length > _maxNoteLen) note = note.substring(0, _maxNoteLen);
    if (note.isEmpty) note = null;
  }

  return _PriceResult.ok(_PricedLine(
    itemId: itemId,
    name: item.name,
    variantName: variantName,
    qty: qty,
    unitPrice: unitPrice,
    modifiers: snapshot,
    note: note,
  ));
}

class _PricedLine {
  _PricedLine({
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.modifiers,
    required this.note,
  });
  final String itemId;
  final String name;
  final String variantName;
  final int qty;
  final int unitPrice;
  final List<Map<String, dynamic>> modifiers;
  final String? note;
}

class _PriceResult {
  _PriceResult.ok(this.line) : error = null;
  _PriceResult.err(this.error) : line = null;
  final _PricedLine? line;
  final String? error;
}

class _VisitClosed implements Exception {}

Response _json(Map<String, dynamic> body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _err(int status, String code) => Response(
      status,
      body: jsonEncode({'code': code}),
      headers: {'content-type': 'application/json'},
    );
