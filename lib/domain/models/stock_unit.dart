/// Unit presets for [[Bahan (Ingredient)]] quantities.
///
/// Every quantity in the inventory system — stock on hand, recipe amounts,
/// movement deltas — is an **int in the dimension's milli-base**: milligram
/// for mass, microlitre for volume, milli-pcs for count. The same exact-integer
/// discipline the codebase uses for money; `double` is never used, because
/// drift accumulates over thousands of deductions and makes `<= 0` fuzzy.
///
/// A preset converts freely **within** its dimension and never across one.
/// Count presets are display labels only and are deliberately NOT
/// inter-convertible — a butir of telur and a siung of bawang are different
/// ingredients, not different units of one. See ADR-0037.
library;

enum StockDimension { mass, volume, count }

String stockDimensionLabel(StockDimension d) => switch (d) {
      StockDimension.mass => 'Berat',
      StockDimension.volume => 'Volume',
      StockDimension.count => 'Jumlah',
    };

/// A unit the admin can pick for an ingredient.
///
/// [perUnit] is how many milli-base units one of this unit is worth:
/// 1 kg = 1_000_000 mg, 1 L = 1_000_000 µl, 1 pcs = 1000 milli-pcs.
enum StockUnit {
  mg(StockDimension.mass, 'mg', 1),
  g(StockDimension.mass, 'g', 1000),
  kg(StockDimension.mass, 'kg', 1000000),
  ml(StockDimension.volume, 'ml', 1000),
  l(StockDimension.volume, 'L', 1000000),
  pcs(StockDimension.count, 'pcs', 1000),
  butir(StockDimension.count, 'butir', 1000),
  siung(StockDimension.count, 'siung', 1000),
  lembar(StockDimension.count, 'lembar', 1000),
  porsi(StockDimension.count, 'porsi', 1000);

  final StockDimension dimension;
  final String label;
  final int perUnit;
  const StockUnit(this.dimension, this.label, this.perUnit);

  /// Milli-base value of [amount] of this unit. Rounds, never truncates —
  /// milli-precision is already far past what a kitchen scale resolves.
  int toBase(double amount) => (amount * perUnit).round();

  /// The display value of [base] milli-base units in this unit.
  double fromBase(int base) => base / perUnit;

  /// Whether a quantity written in [other] can be stored against an ingredient
  /// measured in this unit. Count presets never cross-convert (see library doc).
  bool acceptsEntryIn(StockUnit other) => dimension == StockDimension.count
      ? other == this
      : other.dimension == dimension;
}

StockUnit stockUnitFromKey(String key) => StockUnit.values.firstWhere(
      (u) => u.name == key,
      orElse: () => StockUnit.pcs,
    );

/// Units offered when entering a quantity against an ingredient measured in
/// [unit] — its whole dimension for mass/volume, itself alone for count.
List<StockUnit> entryUnitsFor(StockUnit unit) =>
    unit.dimension == StockDimension.count
        ? [unit]
        : StockUnit.values.where((u) => u.dimension == unit.dimension).toList();

/// Format [base] milli-base units for display against [unit], auto-scaling
/// mass and volume up so a 12 kg sack never reads as `12000000 mg`.
String formatQty(int base, StockUnit unit) {
  final neg = base < 0;
  final abs = base.abs();
  var display = unit;
  if (unit.dimension != StockDimension.count) {
    final scale = unit.dimension == StockDimension.mass
        ? [StockUnit.kg, StockUnit.g, StockUnit.mg]
        : [StockUnit.l, StockUnit.ml];
    for (final u in scale) {
      if (abs >= u.perUnit) {
        display = u;
        break;
      }
      display = scale.last;
    }
  }
  final v = abs / display.perUnit;
  // Up to 3 decimals, trailing zeros stripped: 7.4 not 7.400.
  var s = v.toStringAsFixed(3);
  if (s.contains('.')) s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return '${neg ? '-' : ''}$s ${display.label}';
}

/// Money scale for [Ingredient.costMicro]: micro-money per milli-base unit.
/// A quantity's value is `qty * costMicro ~/ costMicroScale`.
const int costMicroScale = 1000000;

/// Money value of [qty] milli-base units at [costMicro].
int valueOf(int qty, int costMicro) => (qty * costMicro) ~/ costMicroScale;

/// Cost per one *display* unit (e.g. rupiah per kg) → [Ingredient.costMicro].
int costMicroFromUnitPrice(int pricePerUnit, StockUnit unit) =>
    (pricePerUnit * costMicroScale) ~/ unit.perUnit;

/// Inverse of [costMicroFromUnitPrice], for pre-filling the receive form.
int unitPriceFromCostMicro(int costMicro, StockUnit unit) =>
    (costMicro * unit.perUnit) ~/ costMicroScale;
