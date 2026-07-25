import 'stock_unit.dart';

/// "Bahan" — a raw stock item the venue holds and counts. The only stock
/// entity: a bottled drink is an ingredient whose recipe is one of itself.
/// See CONTEXT.md and ADR-0040.
class Ingredient {
  final String id;
  final String name;
  final StockUnit unit;

  /// Milli-base units on hand. May be **negative** — an `overrideStock` send
  /// deliberately pushes it below zero to say "your counts are wrong".
  final int stockOnHand;

  /// Reorder threshold in milli-base units; null = no low-stock badge.
  final int? lowStockAt;

  /// Moving-average cost, micro-money per milli-base unit.
  final int costMicro;

  /// Output of one production batch, in milli-base units. Non-null ⇒ this
  /// ingredient is produced from others (sambal, kaldu) rather than bought.
  final int? batchYield;

  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    this.stockOnHand = 0,
    this.lowStockAt,
    this.costMicro = 0,
    this.batchYield,
  });

  bool get isProduced => batchYield != null;

  bool get isLow => lowStockAt != null && stockOnHand <= lowStockAt!;

  /// Money value of the stock currently held.
  int get stockValue => valueOf(stockOnHand, costMicro);

  String get onHandLabel => formatQty(stockOnHand, unit);

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        name: j['name'] as String,
        unit: stockUnitFromKey(j['unit'] as String),
        stockOnHand: (j['stockOnHand'] as num?)?.toInt() ?? 0,
        lowStockAt: (j['lowStockAt'] as num?)?.toInt(),
        costMicro: (j['costMicro'] as num?)?.toInt() ?? 0,
        batchYield: (j['batchYield'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit.name,
        'stockOnHand': stockOnHand,
        'lowStockAt': lowStockAt,
        'costMicro': costMicro,
        'batchYield': batchYield,
      };

  Ingredient copyWith({
    String? name,
    StockUnit? unit,
    int? stockOnHand,
    Object? lowStockAt = _unset,
    int? costMicro,
    Object? batchYield = _unset,
  }) =>
      Ingredient(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        stockOnHand: stockOnHand ?? this.stockOnHand,
        lowStockAt:
            identical(lowStockAt, _unset) ? this.lowStockAt : lowStockAt as int?,
        costMicro: costMicro ?? this.costMicro,
        batchYield:
            identical(batchYield, _unset) ? this.batchYield : batchYield as int?,
      );
}

/// Why stock moved. One uniform shape for every change (ADR-0041).
enum StockReason {
  sale('Terjual'),
  voidReturn('Batal — kembali'),
  waste('Terbuang'),
  receive('Terima barang'),
  adjust('Penyesuaian'),
  produce('Produksi');

  final String label;
  const StockReason(this.label);
}

StockReason stockReasonFromKey(String key) => StockReason.values.firstWhere(
      (r) => r.name == key,
      orElse: () => StockReason.adjust,
    );

/// One append-only row of the stock ledger. Self-contained on purpose: live
/// ticket rows are deleted at bill close, so [ticketId] dangles by design and
/// readers rely on [sourceLabel]. See ADR-0041.
class StockMovement {
  final String id;
  final String ingredientId;
  final int delta;
  final StockReason reason;
  final String? ticketId;
  final String sourceLabel;
  final String? userId;
  final String? note;
  final int costMicro;
  final String? batchId;
  final DateTime at;

  const StockMovement({
    required this.id,
    required this.ingredientId,
    required this.delta,
    required this.reason,
    required this.at,
    this.ticketId,
    this.sourceLabel = '',
    this.userId,
    this.note,
    this.costMicro = 0,
    this.batchId,
  });

  /// Money value of this movement at the cost it was priced at.
  int get value => valueOf(delta.abs(), costMicro);

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
        id: j['id'] as String,
        ingredientId: j['ingredientId'] as String,
        delta: (j['delta'] as num).toInt(),
        reason: stockReasonFromKey(j['reason'] as String),
        ticketId: j['ticketId'] as String?,
        sourceLabel: (j['sourceLabel'] as String?) ?? '',
        userId: j['userId'] as String?,
        note: j['note'] as String?,
        costMicro: (j['costMicro'] as num?)?.toInt() ?? 0,
        batchId: j['batchId'] as String?,
        at: DateTime.parse(j['at'] as String),
      );
}

/// One line of a recipe: how much of [ingredientId] a portion consumes.
class RecipeLine {
  final String id;
  final String ingredientId;

  /// Milli-base units of the referenced ingredient.
  final int qty;

  const RecipeLine({
    required this.id,
    required this.ingredientId,
    required this.qty,
  });

  factory RecipeLine.fromJson(Map<String, dynamic> j) => RecipeLine(
        id: (j['id'] as String?) ?? '',
        ingredientId: j['ingredientId'] as String,
        qty: (j['qty'] as num).toInt(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'ingredientId': ingredientId, 'qty': qty};
}

/// Every recipe attached to one menu item, keyed by scope.
///
/// A variant's list **replaces** [base] entirely; an option's list **adds** on
/// top of whichever won. An item with no lines anywhere consumes nothing and
/// never goes auto-habis — the correct default for a menu being migrated one
/// dish at a time (ADR-0040).
class ItemRecipes {
  final List<RecipeLine> base;
  final Map<String, List<RecipeLine>> byVariant;
  final Map<String, List<RecipeLine>> byOption;

  const ItemRecipes({
    this.base = const [],
    this.byVariant = const {},
    this.byOption = const {},
  });

  bool get isEmpty => base.isEmpty && byVariant.isEmpty && byOption.isEmpty;

  /// The lines a single portion of `variantId` (+ chosen `optionIds`) consumes,
  /// summed per ingredient.
  Map<String, int> resolve({String variantId = '', List<String> optionIds = const []}) {
    final chosen = byVariant[variantId] ?? base;
    final out = <String, int>{};
    for (final l in chosen) {
      out[l.ingredientId] = (out[l.ingredientId] ?? 0) + l.qty;
    }
    for (final o in optionIds) {
      for (final l in byOption[o] ?? const <RecipeLine>[]) {
        out[l.ingredientId] = (out[l.ingredientId] ?? 0) + l.qty;
      }
    }
    return out;
  }

  factory ItemRecipes.fromJson(Map<String, dynamic> j) => ItemRecipes(
        base: [
          for (final l in (j['base'] as List? ?? const []))
            RecipeLine.fromJson(l as Map<String, dynamic>),
        ],
        byVariant: {
          for (final e in (j['byVariant'] as Map? ?? const {}).entries)
            e.key as String: [
              for (final l in e.value as List)
                RecipeLine.fromJson(l as Map<String, dynamic>),
            ],
        },
        byOption: {
          for (final e in (j['byOption'] as Map? ?? const {}).entries)
            e.key as String: [
              for (final l in e.value as List)
                RecipeLine.fromJson(l as Map<String, dynamic>),
            ],
        },
      );

  Map<String, dynamic> toJson() => {
        'base': [for (final l in base) l.toJson()],
        'byVariant': {
          for (final e in byVariant.entries)
            e.key: [for (final l in e.value) l.toJson()],
        },
        'byOption': {
          for (final e in byOption.entries)
            e.key: [for (final l in e.value) l.toJson()],
        },
      };
}

const Object _unset = Object();
