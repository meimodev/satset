import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/stock.dart';
import 'package:satset/server/stock_counts.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Resolve the caller and their capabilities once. Returns `(userId, caps)`,
/// or null when unauthenticated.
Future<(String?, Set<String>)?> _actor(
  Request req,
  AppDatabase db,
  ServerAuth auth,
) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  final user = await auth.resolveBearer(token);
  if (user == null) return null;
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  final caps = role == null
      ? <String>{}
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>().toSet();
  return (user.id, caps);
}

Response _forbidden(Capability c) => Response(
  403,
  body: jsonEncode({
    'code': 'forbidden',
    'message': 'missing capability ${c.name}',
  }),
  headers: {'content-type': 'application/json'},
);

Response _json(Object body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

/// Ingredient CRUD, the movement ledger, and the stock report.
///
/// Bahan data is deliberately **not** mirrored into a client repository — only
/// derived habis flags ride the cached, broadcast menu snapshot. These routes
/// are fetched on demand by the one screen that needs them, gated by capability
/// rather than by app mode so an admin-client can run stock without hunting for
/// the host tablet (ADR-0040).
Router stockRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  /// Re-broadcast the menu only when a derived availability flag flipped.
  Future<void> broadcastIfFlipped() async {
    if (await stockFlags.refreshAndDetectFlip(db)) {
      hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'stock'});
    }
  }

  // ---------------------------------------------------------- ingredients

  // Readable by recipe authors too — the item editor needs the list to pick
  // ingredients from.
  r.get('/stock/ingredients', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name) &&
        !actor.$2.contains(Capability.editMenu.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final rows =
        await (db.select(db.ingredients)
              ..where((i) => i.archivedAt.isNull())
              ..orderBy([(i) => OrderingTerm(expression: i.name)]))
            .get();
    // Recipe links + last receive ride along so the stock card can show what
    // an ingredient feeds without a fetch per row.
    final links = await loadRecipeLinks(db);
    final lastReceived = await loadLastReceived(db);
    return _json([
      for (final i in rows)
        {
          ...ingredientRowToJson(i),
          'usedBy': links.usedBy[i.id] ?? const <String>[],
          'madeFrom': links.madeFrom[i.id] ?? const <String>[],
          'lastReceivedAt': lastReceived[i.id]?.toIso8601String(),
        },
    ]);
  });

  r.post('/stock/ingredients', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    final name = (body['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return Response(400, body: 'name required');
    final existing = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    final companion = IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value((body['unit'] as String?) ?? 'pcs'),
      lowStockAt: body.containsKey('lowStockAt')
          ? Value((body['lowStockAt'] as num?)?.toInt())
          : const Value.absent(),
      parLevel: body.containsKey('parLevel')
          ? Value((body['parLevel'] as num?)?.toInt())
          : const Value.absent(),
      batchYield: body.containsKey('batchYield')
          ? Value((body['batchYield'] as num?)?.toInt())
          : const Value.absent(),
    );
    if (existing == null) {
      // Opening stock, if any, is booked as a movement so the ledger explains
      // the balance from the very first row.
      await db.transaction(() async {
        await db.into(db.ingredients).insert(companion);
        final opening = (body['stockOnHand'] as num?)?.toInt() ?? 0;
        if (opening != 0) {
          await writeMovement(
            db,
            ingredientId: id,
            delta: opening,
            reason: StockReason.receive,
            userId: actor.$1,
            sourceLabel: 'Stok awal',
          );
        }
      });
    } else {
      await (db.update(
        db.ingredients,
      )..where((i) => i.id.equals(id))).write(companion);
    }
    await broadcastIfFlipped();
    final out = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(id))).getSingle();
    return _json(ingredientRowToJson(out));
  });

  // Archive rather than delete: movement history and recipe lines must keep
  // resolving a name for rows already written.
  r.delete('/stock/ingredients/<id>', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    await db.transaction(() async {
      await (db.update(db.ingredients)..where((i) => i.id.equals(id))).write(
        IngredientsCompanion(archivedAt: Value(SatClock.now())),
      );
      await (db.delete(
        db.recipeLines,
      )..where((l) => l.ingredientId.equals(id))).go();
    });
    await broadcastIfFlipped();
    return _json({'ok': true});
  });

  // ------------------------------------------------------------ movements

  r.get('/stock/ingredients/<id>/movements', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 100;
    final rows =
        await (db.select(db.stockMovements)
              ..where((m) => m.ingredientId.equals(id))
              ..orderBy([
                (m) => OrderingTerm(expression: m.at, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return _json([for (final m in rows) movementRowToJson(m)]);
  });

  // Receive goods. `unitPrice` is money per *display* unit (e.g. rupiah per kg)
  // and re-prices the moving average; omit it to receive without re-pricing.
  r.post('/stock/receive', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ingredientId = body['ingredientId'] as String;
    final qty = (body['qty'] as num?)?.toInt() ?? 0;
    if (qty <= 0) return Response(400, body: 'qty must be positive');
    final row = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
    if (row == null) return Response.notFound('ingredient not found');
    final unitPrice = (body['unitPrice'] as num?)?.toInt();
    await db.transaction(() async {
      await receiveStock(
        db,
        ingredientId: ingredientId,
        qty: qty,
        unitCostMicro: unitPrice == null
            ? null
            : costMicroFromUnitPrice(unitPrice, stockUnitFromKey(row.unit)),
        userId: actor.$1,
        sourceLabel: (body['supplier'] as String?)?.trim() ?? 'Terima barang',
        note: body['note'] as String?,
      );
    });
    await broadcastIfFlipped();
    return _json({'ok': true});
  });

  // ------------------------------------------------------------------ buang
  //
  // Two shapes, one writer. `ingredientId` bins a bahan directly; `itemId`
  // (+ optional `variantId`) explodes the resep and bins what one portion
  // consumes. An item with no resep is refused rather than silently binning
  // nothing — the fix is [[Jual satuan]], and the client says so.
  r.post('/stock/waste', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final qty = (body['qty'] as num?)?.toInt() ?? 0;
    if (qty <= 0) return Response(400, body: 'qty must be positive');
    final note = (body['note'] as String?)?.trim();

    final Map<String, int> need;
    final String label;
    final ingredientId = body['ingredientId'] as String?;
    if (ingredientId != null) {
      final row = await (db.select(
        db.ingredients,
      )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
      if (row == null) return Response.notFound('ingredient not found');
      need = {ingredientId: qty};
      label = row.name;
    } else {
      final itemId = body['itemId'] as String?;
      if (itemId == null) return Response(400, body: 'ingredientId or itemId');
      final item = await (db.select(
        db.menuItems,
      )..where((i) => i.id.equals(itemId))).getSingleOrNull();
      if (item == null) return Response.notFound('item not found');
      final recipes = (await loadRecipes(db, ownerId: itemId))[itemId];
      final per = recipes?.resolve(
        variantId: (body['variantId'] as String?) ?? '',
      );
      if (per == null || per.isEmpty) return Response(400, body: 'no_recipe');
      need = {for (final e in per.entries) e.key: e.value * qty};
      label = item.name;
    }

    final value = await wasteStock(
      db,
      qtyByIngredient: need,
      sourceLabel: label,
      userId: actor.$1,
      note: note,
      hub: hub,
    );
    await broadcastIfFlipped();
    return _json({'ok': true, 'value': value});
  });

  // ------------------------------------------------------------ stok opname
  //
  // An opname is a session, not a burst of adjustments (ADR-0096). It opens,
  // takes lines one at a time, and writes its movements only at close — so a
  // forty-minute walk of the pantry survives the tablet sleeping.

  /// The archive plus whatever is open right now. Readable by a supervisor who
  /// will never count anything: `viewReports` **or** `manageIngredients`, the
  /// list-of-capabilities shape `/kas` uses.
  r.get('/stock/counts', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.viewReports.name) &&
        !actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.viewReports);
    }
    final q = req.url.queryParameters;
    final rows = await listCounts(
      db,
      from: DateTime.tryParse(q['from'] ?? ''),
      to: DateTime.tryParse(q['to'] ?? ''),
      limit: int.tryParse(q['limit'] ?? '') ?? 100,
    );
    // The list carries each session's totals, because a list of opnames with
    // no variance figures is a list of dates.
    final counts = <Map<String, dynamic>>[];
    for (final c in rows) {
      counts.add(countRowToJson(c, lines: await countLines(db, c.id)));
    }
    final open = await openCountSession(db);
    return _json({
      'counts': counts,
      'open': open == null
          ? null
          : countRowToJson(open, lines: await countLines(db, open.id)),
    });
  });

  /// One session as a document — header plus every line, including the ones
  /// found correct.
  r.get('/stock/counts/<id>', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.viewReports.name) &&
        !actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.viewReports);
    }
    final row = await countById(db, id);
    if (row == null) return Response.notFound('count not found');
    final lines = await countLines(db, id);
    final ings = await db.select(db.ingredients).get();
    return _json(
      countRowToJson(
        row,
        lines: lines,
        names: {for (final i in ings) i.id: i.name},
        units: {for (final i in ings) i.id: i.unit},
      ),
    );
  });

  /// Open a session. 409 if one is already open — two overlapping walks each
  /// freeze expectations the other is moving, and neither figure would mean
  /// anything.
  r.post('/stock/counts', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final existing = await openCountSession(db);
    if (existing != null) {
      return Response(
        409,
        body: jsonEncode({'code': 'countAlreadyOpen', 'countId': existing.id}),
        headers: {'content-type': 'application/json'},
      );
    }
    final body =
        jsonDecode(await req.readAsString()) as Map<String, dynamic>? ??
        const {};
    final id = await openCount(
      db,
      userId: actor.$1,
      scope: stockCountScopeFromKey(body['scope'] as String?),
      blind: body['blind'] as bool? ?? true,
      note: body['note'] as String?,
    );
    final row = await countById(db, id);
    return _json(countRowToJson(row!, lines: const []));
  });

  /// Enter one counted bahan. Absolute quantity, as it always was — the server
  /// derives the variance, and freezes the expectation at this moment.
  r.put('/stock/counts/<id>/lines', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final line = await recordCountLine(
      db,
      countId: id,
      ingredientId: body['ingredientId'] as String,
      counted: (body['counted'] as num).toInt(),
      note: body['note'] as String?,
    );
    if (line == null) {
      return Response.notFound('count closed or ingredient not found');
    }
    return _json(countLineRowToJson(line));
  });

  r.delete('/stock/counts/<id>/lines/<ingredientId>', (
    Request req,
    String id,
    String ingredientId,
  ) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    await removeCountLine(db, countId: id, ingredientId: ingredientId);
    return _json({'ok': true});
  });

  /// Abandon an open session. A walk that was never finished is not evidence,
  /// so it leaves no document — unlike a close, which is permanent.
  r.delete('/stock/counts/<id>', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    await discardCount(db, id);
    return _json({'ok': true});
  });

  /// Close: movements, header stamp and the single audit row, in one
  /// transaction. 409 on an already-closed session — the ledger already holds
  /// its movements and a second close would double them.
  r.post('/stock/counts/<id>/close', (Request req, String id) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    // No wrapper here any more: `closeCount` opens its own, which is what lets
    // this read like the one call it is.
    final result = await closeCount(
      db,
      countId: id,
      closedBy: actor.$1,
      hub: hub,
    );
    if (result == null) {
      return Response(
        409,
        body: jsonEncode({'code': 'countClosed'}),
        headers: {'content-type': 'application/json'},
      );
    }
    await broadcastIfFlipped();
    final row = await countById(db, id);
    return _json({
      ...countRowToJson(row!, lines: await countLines(db, id)),
      'movements': result.movements,
      'deltas': result.deltas,
    });
  });

  /// The one-shot opname the pre-v52 client sends: open, line, close, in one
  /// transaction. Kept so an un-upgraded handset keeps working, and routed
  /// through the same writer so the invariants have exactly one home.
  r.post('/stock/count', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final counts = (body['counts'] as List?) ?? const [];
    var deltas = <String, int>{};
    await db.transaction(() async {
      final countId = await openCount(
        db,
        userId: actor.$1,
        note: body['note'] as String?,
        // A one-shot submission saw the numbers on the list it was typed over.
        blind: false,
      );
      for (final raw in counts) {
        final c = raw as Map<String, dynamic>;
        await recordCountLine(
          db,
          countId: countId,
          ingredientId: c['ingredientId'] as String,
          counted: (c['counted'] as num).toInt(),
          note: c['note'] as String? ?? body['note'] as String?,
        );
      }
      final result = await closeCount(
        db,
        countId: countId,
        closedBy: actor.$1,
        hub: hub,
      );
      deltas = result?.deltas ?? {};
    });
    await broadcastIfFlipped();
    return _json({'deltas': deltas});
  });

  // Produce a batch of a made-in-house ingredient.
  r.post('/stock/produce', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    String? batchId;
    await db.transaction(() async {
      batchId = await produceBatch(
        db,
        ingredientId: body['ingredientId'] as String,
        batches: (body['batches'] as num?)?.toInt() ?? 1,
        userId: actor.$1,
        note: body['note'] as String?,
      );
    });
    if (batchId == null) {
      return Response(
        400,
        body: jsonEncode({
          'code': 'not_produced',
          'message': 'ingredient has no batch yield',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    await broadcastIfFlipped();
    return _json({'batchId': batchId});
  });

  // -------------------------------------------------------------- recipes

  r.get('/stock/recipes/<ownerId>', (Request req, String ownerId) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    final kind = req.url.queryParameters['kind'] ?? 'item';
    return _json(await recipesJson(db, ownerId, ownerKind: kind));
  });

  r.put('/stock/recipes/<ownerId>', (Request req, String ownerId) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    final kind = req.url.queryParameters['kind'] ?? 'item';
    // Recipe authoring is menu authoring for items; ingredient batch recipes
    // belong to whoever runs stock.
    final needed = kind == 'item'
        ? Capability.editMenu
        : Capability.manageIngredients;
    if (!actor.$2.contains(needed.name)) return _forbidden(needed);
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await db.transaction(
      () => writeRecipes(db, ownerId, body, ownerKind: kind),
    );
    // Which recipes exist just changed, so cached signatures no longer describe
    // the same menu — force the next check to re-broadcast.
    stockFlags.invalidate();
    await broadcastIfFlipped();
    return _json(await recipesJson(db, ownerId, ownerKind: kind));
  });

  // --------------------------------------------------------------- report

  r.get('/stock/report', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.viewReports.name) &&
        !actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.viewReports);
    }
    final q = req.url.queryParameters;
    final from =
        DateTime.tryParse(q['from'] ?? '') ??
        SatClock.now().subtract(const Duration(days: 7));
    final to = DateTime.tryParse(q['to'] ?? '') ?? SatClock.now();
    return _json(await stockReport(db, from: from, to: to));
  });

  return r;
}

/// Usage, waste, valuation, and opname-to-opname variance.
///
/// Variance is anchored to **opname events**, not to the caller's date range: a
/// variance figure over a window that starts and ends mid-count is meaningless
/// (ADR-0041). Every `adjust` movement *is* one variance observation.
Future<Map<String, dynamic>> stockReport(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final ingredients = await db.select(db.ingredients).get();
  final byId = {for (final i in ingredients) i.id: i};
  final rows =
      await (db.select(db.stockMovements)..where(
            (m) =>
                m.at.isBiggerOrEqualValue(from) & m.at.isSmallerThanValue(to),
          ))
          .get();

  final usedQty = <String, int>{};
  final wasteQty = <String, int>{};
  final wasteValue = <String, int>{};
  final varianceQty = <String, int>{};
  final varianceValue = <String, int>{};
  for (final m in rows) {
    switch (stockReasonFrom(m.reason)) {
      // sale is negative, voidReturn positive — summing both gives net sold.
      case StockReason.sale:
      case StockReason.voidReturn:
        usedQty[m.ingredientId] = (usedQty[m.ingredientId] ?? 0) - m.delta;
      case StockReason.waste:
        wasteQty[m.ingredientId] =
            (wasteQty[m.ingredientId] ?? 0) + m.delta.abs();
        wasteValue[m.ingredientId] =
            (wasteValue[m.ingredientId] ?? 0) +
            valueOf(m.delta.abs(), m.costMicro);
      case StockReason.adjust:
        varianceQty[m.ingredientId] =
            (varianceQty[m.ingredientId] ?? 0) + m.delta;
        varianceValue[m.ingredientId] =
            (varianceValue[m.ingredientId] ?? 0) +
            valueOf(m.delta, m.costMicro);
      case StockReason.receive:
      case StockReason.produce:
        break;
    }
  }

  List<Map<String, dynamic>> rank(
    Map<String, int> qty, {
    Map<String, int>? value,
    bool byAbs = false,
  }) {
    final out = [
      for (final e in qty.entries)
        if (e.value != 0 && byId[e.key] != null)
          {
            'ingredientId': e.key,
            'name': byId[e.key]!.name,
            'unit': byId[e.key]!.unit,
            'qty': e.value,
            'value':
                value?[e.key] ?? valueOf(e.value.abs(), byId[e.key]!.costMicro),
          },
    ];
    out.sort((a, b) {
      final av = (a['value'] as int), bv = (b['value'] as int);
      return byAbs ? bv.abs().compareTo(av.abs()) : bv.compareTo(av);
    });
    return out;
  }

  final valuation = [
    for (final i in ingredients)
      if (i.archivedAt == null)
        {
          'ingredientId': i.id,
          'name': i.name,
          'unit': i.unit,
          'qty': i.stockOnHand,
          'value': valueOf(i.stockOnHand, i.costMicro),
          'low': i.lowStockAt != null && i.stockOnHand <= i.lowStockAt!,
          'negative': i.stockOnHand < 0,
        },
  ]..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

  return {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'usage': rank(usedQty),
    'waste': rank(wasteQty, value: wasteValue),
    'variance': rank(varianceQty, value: varianceValue, byAbs: true),
    'valuation': valuation,
    'totalWasteValue': wasteValue.values.fold<int>(0, (a, b) => a + b),
    'totalStockValue': valuation.fold<int>(
      0,
      (a, m) => a + (m['value'] as int),
    ),
    'totalVarianceValue': varianceValue.values.fold<int>(0, (a, b) => a + b),
  };
}

StockReason stockReasonFrom(String key) => StockReason.values.firstWhere(
  (r) => r.name == key,
  orElse: () => StockReason.adjust,
);
