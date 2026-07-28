import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';

import 'db/database.dart';

const _uuid = Uuid();

/// Ingredient-level inventory: recipe resolution, coverage checks, and the
/// movement ledger. See docs/adr/0040 and docs/adr/0041.
///
/// Every function that writes assumes it is called **inside** a `db.transaction`
/// so the ledger row and the denormalised `stockOnHand` can never diverge.

// ---------------------------------------------------------------- recipes

/// Every recipe scope attached to one owner (a menu item, or a produced
/// ingredient). Quantities are already summed per ingredient, in milli-base.
class ResolvedRecipes {
  final Map<String, int> base;
  final Map<String, Map<String, int>> byVariant;
  final Map<String, Map<String, int>> byOption;

  const ResolvedRecipes({
    this.base = const {},
    this.byVariant = const {},
    this.byOption = const {},
  });

  bool get isEmpty => base.isEmpty && byVariant.isEmpty && byOption.isEmpty;

  /// What one portion of `variantId` with `optionIds` consumes. The variant
  /// list **replaces** the base; option lists **add** on top (ADR-0040).
  Map<String, int> resolve({
    String variantId = '',
    Iterable<String> optionIds = const [],
  }) {
    final out = <String, int>{...(byVariant[variantId] ?? base)};
    for (final o in optionIds) {
      for (final e in (byOption[o] ?? const <String, int>{}).entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }
    return out;
  }
}

/// Load recipes grouped by owner id. Pass [ownerId] to scope to one owner.
Future<Map<String, ResolvedRecipes>> loadRecipes(
  AppDatabase db, {
  String ownerKind = 'item',
  String? ownerId,
}) async {
  final q = db.select(db.recipeLines)
    ..where((l) => l.ownerKind.equals(ownerKind));
  if (ownerId != null) q.where((l) => l.ownerId.equals(ownerId));
  final rows = await q.get();

  final base = <String, Map<String, int>>{};
  final variant = <String, Map<String, Map<String, int>>>{};
  final option = <String, Map<String, Map<String, int>>>{};
  for (final l in rows) {
    final Map<String, int> bucket;
    if (l.optionId.isNotEmpty) {
      bucket = (option[l.ownerId] ??= {})[l.optionId] ??= {};
    } else if (l.variantId.isNotEmpty) {
      bucket = (variant[l.ownerId] ??= {})[l.variantId] ??= {};
    } else {
      bucket = base[l.ownerId] ??= {};
    }
    bucket[l.ingredientId] = (bucket[l.ingredientId] ?? 0) + l.qty;
  }
  return {
    for (final id in {...base.keys, ...variant.keys, ...option.keys})
      id: ResolvedRecipes(
        base: base[id] ?? const {},
        byVariant: variant[id] ?? const {},
        byOption: option[id] ?? const {},
      ),
  };
}

/// Replace every recipe scope for one owner in a single write. `payload` is the
/// [ItemRecipes] JSON shape: `{base: [...], byVariant: {...}, byOption: {...}}`.
Future<void> writeRecipes(
  AppDatabase db,
  String ownerId,
  Map<String, dynamic> payload, {
  String ownerKind = 'item',
}) async {
  await (db.delete(db.recipeLines)..where(
        (l) => l.ownerKind.equals(ownerKind) & l.ownerId.equals(ownerId),
      ))
      .go();
  Future<void> insert(String variantId, String optionId, List lines) async {
    for (final raw in lines) {
      final l = raw as Map<String, dynamic>;
      final qty = (l['qty'] as num).toInt();
      if (qty <= 0) continue;
      await db
          .into(db.recipeLines)
          .insert(
            RecipeLinesCompanion.insert(
              id: _uuid.v4(),
              ownerKind: ownerKind,
              ownerId: ownerId,
              variantId: Value(variantId),
              optionId: Value(optionId),
              ingredientId: l['ingredientId'] as String,
              qty: qty,
            ),
          );
    }
  }

  await insert('', '', (payload['base'] as List?) ?? const []);
  for (final e in ((payload['byVariant'] as Map?) ?? const {}).entries) {
    await insert(e.key as String, '', e.value as List);
  }
  for (final e in ((payload['byOption'] as Map?) ?? const {}).entries) {
    await insert('', e.key as String, e.value as List);
  }
}

/// The `{base, byVariant, byOption}` JSON for one owner — what the item editor
/// loads and posts back.
Future<Map<String, dynamic>> recipesJson(
  AppDatabase db,
  String ownerId, {
  String ownerKind = 'item',
}) async {
  final rows =
      await (db.select(db.recipeLines)..where(
            (l) => l.ownerKind.equals(ownerKind) & l.ownerId.equals(ownerId),
          ))
          .get();
  List<Map<String, dynamic>> lines(Iterable<RecipeLineRow> rs) => [
    for (final l in rs)
      {'id': l.id, 'ingredientId': l.ingredientId, 'qty': l.qty},
  ];
  final byVariant = <String, List<RecipeLineRow>>{};
  final byOption = <String, List<RecipeLineRow>>{};
  final base = <RecipeLineRow>[];
  for (final l in rows) {
    if (l.optionId.isNotEmpty) {
      (byOption[l.optionId] ??= []).add(l);
    } else if (l.variantId.isNotEmpty) {
      (byVariant[l.variantId] ??= []).add(l);
    } else {
      base.add(l);
    }
  }
  return {
    'base': lines(base),
    'byVariant': {for (final e in byVariant.entries) e.key: lines(e.value)},
    'byOption': {for (final e in byOption.entries) e.key: lines(e.value)},
  };
}

// ------------------------------------------------------------ derived habis

/// Derived availability for one item. Nothing here is stored — it is recomputed
/// from ingredient stock, so receiving un-habises an item automatically and no
/// one ever has to clear a flag (ADR-0040).
class ItemStockFlags {
  final bool autoSoldOut;
  final Set<String> soldOutVariantIds;
  final Set<String> soldOutOptionIds;

  const ItemStockFlags({
    this.autoSoldOut = false,
    this.soldOutVariantIds = const {},
    this.soldOutOptionIds = const {},
  });

  bool get isClear =>
      !autoSoldOut && soldOutVariantIds.isEmpty && soldOutOptionIds.isEmpty;

  /// Compact identity used to detect a **flip**. Stock ticking down inside a
  /// bucket must not change this — only crossing a threshold may.
  String get signature =>
      '$autoSoldOut|'
      '${(soldOutVariantIds.toList()..sort()).join(",")}|'
      '${(soldOutOptionIds.toList()..sort()).join(",")}';

  Map<String, dynamic> toJson() => {
    'autoSoldOut': autoSoldOut,
    'soldOutVariantIds': soldOutVariantIds.toList(),
    'soldOutOptionIds': soldOutOptionIds.toList(),
  };
}

bool _covers(Map<String, int> need, Map<String, int> onHand) {
  for (final e in need.entries) {
    if ((onHand[e.key] ?? 0) < e.value) return false;
  }
  return true;
}

/// Recompute derived habis for every menu item.
Future<Map<String, ItemStockFlags>> deriveStockFlags(AppDatabase db) async {
  final recipes = await loadRecipes(db);
  if (recipes.isEmpty) return const {};
  final onHand = {
    for (final i in await db.select(db.ingredients).get()) i.id: i.stockOnHand,
  };
  final items = await (db.selectOnly(
    db.menuItems,
  )..addColumns([db.menuItems.id, db.menuItems.variantsJson])).get();

  final out = <String, ItemStockFlags>{};
  for (final row in items) {
    final id = row.read(db.menuItems.id)!;
    final r = recipes[id];
    // No recipe anywhere ⇒ consumes nothing ⇒ never auto-habis. The correct
    // default for a menu being migrated one dish at a time.
    if (r == null || r.isEmpty) continue;

    final variantIds = [
      for (final v in jsonDecode(row.read(db.menuItems.variantsJson)!) as List)
        (v as Map<String, dynamic>)['id'] as String,
    ];
    final soldOutVariants = <String>{};
    bool autoSoldOut;
    if (variantIds.isEmpty) {
      autoSoldOut = !_covers(r.resolve(), onHand);
    } else {
      for (final v in variantIds) {
        if (!_covers(r.resolve(variantId: v), onHand)) soldOutVariants.add(v);
      }
      // The item itself is habis only when no configuration is makeable.
      autoSoldOut = soldOutVariants.length == variantIds.length;
    }
    final soldOutOptions = <String>{
      for (final e in r.byOption.entries)
        if (!_covers(e.value, onHand)) e.key,
    };
    final flags = ItemStockFlags(
      autoSoldOut: autoSoldOut,
      soldOutVariantIds: soldOutVariants,
      soldOutOptionIds: soldOutOptions,
    );
    if (!flags.isClear) out[id] = flags;
  }
  return out;
}

/// Flip detector for the menu broadcast.
///
/// Every sale changes stock, but beras going 8.0 → 7.8 kg changes nothing
/// anyone can see. Broadcasting per movement would flood the LAN mid-service,
/// so the menu snapshot is re-broadcast **only when a derived flag actually
/// flips** (ADR-0040).
///
/// ponytail: one process-wide instance — the embedded server owns exactly one
/// database. If SatSet ever hosts two DBs in one process, key this by db.
class StockFlagCache {
  Map<String, String> _signatures = {};

  /// Recompute flags; true when any item's availability changed.
  Future<bool> refreshAndDetectFlip(AppDatabase db) async {
    final flags = await deriveStockFlags(db);
    final next = {for (final e in flags.entries) e.key: e.value.signature};
    final flipped =
        next.length != _signatures.length ||
        next.entries.any((e) => _signatures[e.key] != e.value);
    _signatures = next;
    return flipped;
  }

  /// Drop the memo so the next check re-broadcasts (menu edits change which
  /// recipes exist, so cached signatures no longer describe the same menu).
  void invalidate() => _signatures = {};
}

final stockFlags = StockFlagCache();

// ------------------------------------------------------------- the ledger

/// Append one movement and move the balance, in the caller's transaction.
///
/// [costMicro] defaults to the ingredient's current moving average so waste and
/// usage can be valued historically without re-pricing.
Future<void> writeMovement(
  AppDatabase db, {
  required String ingredientId,
  required int delta,
  required StockReason reason,
  String? ticketId,
  String sourceLabel = '',
  String? userId,
  String? note,
  String? batchId,
  int? costMicro,
  // Backdating + id injection exist for the demo seed (ADR-0052), which
  // replays a month of service through this path: `at` places the row in the
  // past, `id` carries the `demo-` tag its reset deletes by. Production
  // callers pass neither.
  DateTime? at,
  String? id,
}) async {
  final ing = await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
  if (ing == null) return;
  await db
      .into(db.stockMovements)
      .insert(
        StockMovementsCompanion.insert(
          id: id ?? _uuid.v4(),
          ingredientId: ingredientId,
          delta: delta,
          reason: reason.name,
          ticketId: Value(ticketId),
          sourceLabel: Value(sourceLabel),
          userId: Value(userId),
          note: Value(note),
          batchId: Value(batchId),
          costMicro: Value(costMicro ?? ing.costMicro),
          at: at ?? SatClock.now(),
        ),
      );
  // Deliberately NOT clamped at zero: a negative balance is the `overrideStock`
  // signal that the venue's counts are wrong (ADR-0041).
  await (db.update(db.ingredients)..where((i) => i.id.equals(ingredientId)))
      .write(IngredientsCompanion(stockOnHand: Value(ing.stockOnHand + delta)));
}

/// Receive goods, optionally re-pricing the moving average.
Future<void> receiveStock(
  AppDatabase db, {
  required String ingredientId,
  required int qty,
  int? unitCostMicro,
  String? userId,
  String sourceLabel = '',
  String? note,
  DateTime? at,
  String? id,
}) async {
  final ing = await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
  if (ing == null || qty <= 0) return;
  if (unitCostMicro != null) {
    // Moving average. A price spike smears across subsequent sales rather than
    // landing on the batch that caused it — FIFO layers only pay off alongside
    // expiry tracking (ADR-0040).
    final held = ing.stockOnHand > 0 ? ing.stockOnHand : 0;
    final total = held + qty;
    final blended = total <= 0
        ? unitCostMicro
        : ((held * ing.costMicro) + (qty * unitCostMicro)) ~/ total;
    await (db.update(db.ingredients)..where((i) => i.id.equals(ingredientId)))
        .write(IngredientsCompanion(costMicro: Value(blended)));
  }
  await writeMovement(
    db,
    ingredientId: ingredientId,
    delta: qty,
    reason: StockReason.receive,
    userId: userId,
    sourceLabel: sourceLabel,
    note: note,
    costMicro: unitCostMicro,
    at: at,
    id: id,
  );
}

/// Stok opname: the counter enters an **absolute** count and the system writes
/// the difference. That difference *is* the variance between what recipes said
/// should be there and what was actually found (ADR-0041).
Future<int> recordCount(
  AppDatabase db, {
  required String ingredientId,
  required int counted,
  String? userId,
  String? note,
}) async {
  final ing = await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
  if (ing == null) return 0;
  final delta = counted - ing.stockOnHand;
  if (delta == 0) return 0;
  await writeMovement(
    db,
    ingredientId: ingredientId,
    delta: delta,
    reason: StockReason.adjust,
    userId: userId,
    sourceLabel: 'Opname',
    note: note,
  );
  return delta;
}

/// Produce `batches` of a made-in-house ingredient: deduct its inputs, credit
/// its yield, and price the output from what went in. One level only — a
/// produced ingredient's recipe may reference non-produced ingredients (ADR-0040).
Future<String?> produceBatch(
  AppDatabase db, {
  required String ingredientId,
  required int batches,
  String? userId,
  String? note,
}) async {
  final ing = await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
  final yieldQty = ing?.batchYield;
  if (ing == null || yieldQty == null || yieldQty <= 0 || batches <= 0) {
    return null;
  }
  final recipe =
      (await loadRecipes(
        db,
        ownerKind: 'ingredient',
        ownerId: ingredientId,
      ))[ingredientId] ??
      const ResolvedRecipes();
  final batchId = _uuid.v4();
  var inputValue = 0;
  for (final e in recipe.base.entries) {
    final qty = e.value * batches;
    final src = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(e.key))).getSingleOrNull();
    inputValue += valueOf(qty, src?.costMicro ?? 0);
    await writeMovement(
      db,
      ingredientId: e.key,
      delta: -qty,
      reason: StockReason.produce,
      userId: userId,
      batchId: batchId,
      sourceLabel: ing.name,
      note: note,
    );
  }
  final produced = yieldQty * batches;
  final outCostMicro = produced > 0
      ? (inputValue * costMicroScale) ~/ produced
      : ing.costMicro;
  await (db.update(db.ingredients)..where((i) => i.id.equals(ingredientId)))
      .write(IngredientsCompanion(costMicro: Value(outCostMicro)));
  await writeMovement(
    db,
    ingredientId: ingredientId,
    delta: produced,
    reason: StockReason.produce,
    userId: userId,
    batchId: batchId,
    sourceLabel: 'Produksi',
    note: note,
    costMicro: outCostMicro,
  );
  return batchId;
}

// -------------------------------------------------------- sale & void paths

/// What one order line needs, and whether stock covers it.
class LineStockNeed {
  final Map<String, int> need;

  /// Names of the ingredients that fall short — surfaced to the waiter so the
  /// rejection says *what* ran out, not just "no".
  final List<String> shortNames;

  const LineStockNeed(this.need, this.shortNames);

  bool get covered => shortNames.isEmpty;
}

/// Resolve one submitted line against the menu and the running stock view.
///
/// [running] is the in-transaction balance map, mutated as lines are accepted,
/// so two lines in the same order competing for the last portion resolve
/// consistently.
Future<LineStockNeed> needForLine(
  AppDatabase db, {
  required String itemId,
  required String variantName,
  required List<String> optionIds,
  required int qty,
  required Map<String, ResolvedRecipes> recipes,
  required Map<String, int> running,
  required Map<String, String> ingredientNames,
  Map<String, String> variantIdsByName = const {},
}) async {
  final r = recipes[itemId];
  if (r == null || r.isEmpty) return const LineStockNeed({}, []);
  final per = r.resolve(
    variantId: variantIdsByName[variantName] ?? '',
    optionIds: optionIds,
  );
  final need = {for (final e in per.entries) e.key: e.value * qty};
  final short = <String>[
    for (final e in need.entries)
      if ((running[e.key] ?? 0) < e.value) ingredientNames[e.key] ?? e.key,
  ];
  return LineStockNeed(need, short);
}

/// Variant **name** → id for one item. Tickets carry the name, not the id, so
/// the id is resolved at send against the menu as it reads right then.
Map<String, String> variantIdsByName(String variantsJson) => {
  for (final v in jsonDecode(variantsJson) as List)
    (v as Map<String, dynamic>)['name'] as String: v['id'] as String,
};

/// Option ids out of a ticket's frozen modifier snapshot
/// (`{groupId, optionId, label, priceDelta}` — ADR-0011).
List<String> optionIdsOf(String modifiersJson) => [
  for (final m in jsonDecode(modifiersJson) as List)
    if (m is Map && (m['optionId'] as String?)?.isNotEmpty == true)
      m['optionId'] as String,
];

/// Deduct one accepted line and record it against the ticket.
Future<void> consumeForTicket(
  AppDatabase db, {
  required String ticketId,
  required Map<String, int> need,
  required String sourceLabel,
  String? userId,
  DateTime? at,

  /// Prefix for the movement ids. The demo seed replays through this path and
  /// its rows must carry the demo tag, or reset deletes the purchases and
  /// leaves the sales behind — driving every balance deeply negative.
  String? idPrefix,
}) async {
  for (final e in need.entries) {
    await writeMovement(
      db,
      ingredientId: e.key,
      delta: -e.value,
      reason: StockReason.sale,
      ticketId: ticketId,
      sourceLabel: sourceLabel,
      userId: userId,
      at: at,
      id: idPrefix == null ? null : '$idPrefix${_uuid.v4()}',
    );
  }
}

/// Reverse a voided line's consumption.
///
/// Restock only when the kitchen never touched it. From `prep` onward the
/// ingredients are physically gone, so the sale is reversed **and** an equal
/// `waste` is booked — net zero on the balance, but the loss is now visible and
/// countable instead of hiding inside "sold" (ADR-0041).
Future<void> reverseTicketStock(
  AppDatabase db, {
  required String ticketId,
  required bool untouched,
  String? userId,
  String? note,
}) async {
  final sales =
      await (db.select(db.stockMovements)..where(
            (m) =>
                m.ticketId.equals(ticketId) &
                m.reason.equals(StockReason.sale.name),
          ))
          .get();
  if (sales.isEmpty) return;
  // Already reversed (double-void, retry) — the ledger is append-only, so guard
  // on the reversal existing rather than on ticket status alone.
  final reversed =
      await (db.select(db.stockMovements)..where(
            (m) =>
                m.ticketId.equals(ticketId) &
                m.reason.equals(StockReason.voidReturn.name),
          ))
          .get();
  if (reversed.isNotEmpty) return;

  for (final s in sales) {
    await writeMovement(
      db,
      ingredientId: s.ingredientId,
      delta: -s.delta,
      reason: StockReason.voidReturn,
      ticketId: ticketId,
      sourceLabel: s.sourceLabel,
      userId: userId,
      note: note,
      costMicro: s.costMicro,
    );
    if (!untouched) {
      await writeMovement(
        db,
        ingredientId: s.ingredientId,
        delta: s.delta,
        reason: StockReason.waste,
        ticketId: ticketId,
        sourceLabel: s.sourceLabel,
        userId: userId,
        note: note,
        costMicro: s.costMicro,
      );
    }
  }
}

// ------------------------------------------------------- reverse recipe index

/// The recipe links the stock list shows on every card, keyed by ingredient id.
///
/// `usedBy` is the reverse of [loadRecipes]: which menu items and produced
/// ingredients consume this one — i.e. what stops selling when it runs out.
/// `madeFrom` is the forward direction, and only exists for produced
/// ingredients. Names are resolved once here rather than per row.
class RecipeLinks {
  final Map<String, List<String>> usedBy;
  final Map<String, List<String>> madeFrom;

  const RecipeLinks({this.usedBy = const {}, this.madeFrom = const {}});
}

Future<RecipeLinks> loadRecipeLinks(AppDatabase db) async {
  final lines = await db.select(db.recipeLines).get();
  if (lines.isEmpty) return const RecipeLinks();

  final itemNames = {
    for (final m in await db.select(db.menuItems).get()) m.id: m.name,
  };
  final ingredientNames = {
    for (final i in await db.select(db.ingredients).get()) i.id: i.name,
  };

  // Sets, because a recipe may touch the same ingredient across several
  // variant/option scopes and the card must not repeat the chip.
  final usedBy = <String, Set<String>>{};
  final madeFrom = <String, Set<String>>{};

  for (final l in lines) {
    final ownerName = l.ownerKind == 'item'
        ? itemNames[l.ownerId]
        : ingredientNames[l.ownerId];
    final ingredientName = ingredientNames[l.ingredientId];
    // Dangling line (owner or ingredient hard-deleted) — nothing to label.
    if (ownerName == null || ingredientName == null) continue;

    (usedBy[l.ingredientId] ??= <String>{}).add(ownerName);
    if (l.ownerKind == 'ingredient') {
      (madeFrom[l.ownerId] ??= <String>{}).add(ingredientName);
    }
  }

  List<String> sorted(Set<String> s) =>
      s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return RecipeLinks(
    usedBy: {for (final e in usedBy.entries) e.key: sorted(e.value)},
    madeFrom: {for (final e in madeFrom.entries) e.key: sorted(e.value)},
  );
}

/// Newest `receive` movement per ingredient — the "Terakhir terima" column.
Future<Map<String, DateTime>> loadLastReceived(AppDatabase db) async {
  final at = db.stockMovements.at.max();
  final q = db.selectOnly(db.stockMovements)
    ..addColumns([db.stockMovements.ingredientId, at])
    ..where(db.stockMovements.reason.equals(StockReason.receive.name))
    ..groupBy([db.stockMovements.ingredientId]);
  return {
    for (final r in await q.get())
      if (r.read(at) != null)
        r.read(db.stockMovements.ingredientId)!: r.read(at)!,
  };
}

// ------------------------------------------------------------------- JSON

Map<String, dynamic> ingredientRowToJson(IngredientRow i) => {
  'id': i.id,
  'name': i.name,
  'unit': i.unit,
  'stockOnHand': i.stockOnHand,
  'lowStockAt': i.lowStockAt,
  'costMicro': i.costMicro,
  'batchYield': i.batchYield,
};

Map<String, dynamic> movementRowToJson(StockMovementRow m) => {
  'id': m.id,
  'ingredientId': m.ingredientId,
  'delta': m.delta,
  'reason': m.reason,
  'ticketId': m.ticketId,
  'sourceLabel': m.sourceLabel,
  'userId': m.userId,
  'note': m.note,
  'costMicro': m.costMicro,
  'batchId': m.batchId,
  'at': m.at.toIso8601String(),
};
