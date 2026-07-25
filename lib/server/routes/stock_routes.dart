import 'dart:convert';

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
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Resolve the caller and their capabilities once. Returns `(userId, caps)`,
/// or null when unauthenticated.
Future<(String?, Set<String>)?> _actor(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
) async {
  if (auth == null) return (null, Capability.values.map((c) => c.name).toSet());
  final token =
      req.headers['authorization']?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  final user = await auth.resolveBearer(token);
  if (user == null) return null;
  final role = await (db.select(db.roles)..where((r) => r.id.equals(user.roleId)))
      .getSingleOrNull();
  final caps = role == null
      ? <String>{}
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>().toSet();
  return (user.id, caps);
}

Response _forbidden(Capability c) => Response(403,
    body: jsonEncode(
        {'code': 'forbidden', 'message': 'missing capability ${c.name}'}),
    headers: {'content-type': 'application/json'});

Response _json(Object body) => Response.ok(jsonEncode(body),
    headers: {'content-type': 'application/json'});

/// Ingredient CRUD, the movement ledger, and the stock report.
///
/// Bahan data is deliberately **not** mirrored into a client repository — only
/// derived habis flags ride the cached, broadcast menu snapshot. These routes
/// are fetched on demand by the one screen that needs them, gated by capability
/// rather than by app mode so an admin-client can run stock without hunting for
/// the host tablet (ADR-0040).
Router stockRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
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
    final rows = await (db.select(db.ingredients)
          ..where((i) => i.archivedAt.isNull())
          ..orderBy([(i) => OrderingTerm(expression: i.name)]))
        .get();
    return _json([for (final i in rows) ingredientRowToJson(i)]);
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
    final existing =
        await (db.select(db.ingredients)..where((i) => i.id.equals(id)))
            .getSingleOrNull();
    final companion = IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value((body['unit'] as String?) ?? 'pcs'),
      lowStockAt: body.containsKey('lowStockAt')
          ? Value((body['lowStockAt'] as num?)?.toInt())
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
      await (db.update(db.ingredients)..where((i) => i.id.equals(id)))
          .write(companion);
    }
    await broadcastIfFlipped();
    final out = await (db.select(db.ingredients)..where((i) => i.id.equals(id)))
        .getSingle();
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
      await (db.update(db.ingredients)..where((i) => i.id.equals(id)))
          .write(IngredientsCompanion(archivedAt: Value(DateTime.now())));
      await (db.delete(db.recipeLines)
            ..where((l) => l.ingredientId.equals(id)))
          .go();
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
    final limit =
        int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 100;
    final rows = await (db.select(db.stockMovements)
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
    final row = await (db.select(db.ingredients)
          ..where((i) => i.id.equals(ingredientId)))
        .getSingleOrNull();
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

  // Stok opname. Body carries the **absolute** counted quantity; the written
  // `adjust` delta is the variance (ADR-0041).
  r.post('/stock/count', (Request req) async {
    final actor = await _actor(req, db, auth);
    if (actor == null) return Response(401);
    if (!actor.$2.contains(Capability.manageIngredients.name)) {
      return _forbidden(Capability.manageIngredients);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final counts = (body['counts'] as List?) ?? const [];
    final deltas = <String, int>{};
    await db.transaction(() async {
      for (final raw in counts) {
        final c = raw as Map<String, dynamic>;
        final id = c['ingredientId'] as String;
        deltas[id] = await recordCount(
          db,
          ingredientId: id,
          counted: (c['counted'] as num).toInt(),
          userId: actor.$1,
          note: c['note'] as String? ?? body['note'] as String?,
        );
      }
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
      return Response(400,
          body: jsonEncode({
            'code': 'not_produced',
            'message': 'ingredient has no batch yield',
          }),
          headers: {'content-type': 'application/json'});
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
    await db.transaction(() => writeRecipes(db, ownerId, body, ownerKind: kind));
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
    final from = DateTime.tryParse(q['from'] ?? '') ??
        DateTime.now().subtract(const Duration(days: 7));
    final to = DateTime.tryParse(q['to'] ?? '') ?? DateTime.now();
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
  final rows = await (db.select(db.stockMovements)
        ..where((m) => m.at.isBiggerOrEqualValue(from) & m.at.isSmallerThanValue(to)))
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
        wasteQty[m.ingredientId] = (wasteQty[m.ingredientId] ?? 0) + m.delta.abs();
        wasteValue[m.ingredientId] =
            (wasteValue[m.ingredientId] ?? 0) + valueOf(m.delta.abs(), m.costMicro);
      case StockReason.adjust:
        varianceQty[m.ingredientId] = (varianceQty[m.ingredientId] ?? 0) + m.delta;
        varianceValue[m.ingredientId] =
            (varianceValue[m.ingredientId] ?? 0) + valueOf(m.delta, m.costMicro);
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
            'value': value?[e.key] ?? valueOf(e.value.abs(), byId[e.key]!.costMicro),
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
    'totalWasteValue':
        wasteValue.values.fold<int>(0, (a, b) => a + b),
    'totalStockValue': valuation.fold<int>(0, (a, m) => a + (m['value'] as int)),
    'totalVarianceValue':
        varianceValue.values.fold<int>(0, (a, b) => a + b),
  };
}

StockReason stockReasonFrom(String key) => StockReason.values
    .firstWhere((r) => r.name == key, orElse: () => StockReason.adjust);
