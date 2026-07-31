/// Bahan + resep for the prompted **generic restaurant** seed (ADR-0017), the
/// inventory half of that dataset (ADR-0042).
///
/// Everything here is authored in **display units** (kg, L, pcs, butir…) and
/// converted to the dimension's milli-base at seed time, so the numbers read
/// like a recipe card instead of like storage. See ADR-0040 for why quantities
/// are exact integers and why units never cross a dimension.
///
/// The cocktails and the wines are deliberately left with **no resep** —
/// `margarita`, `negroni`, `mojito`, `espresso-martini`, `rose`, `sauvignon`,
/// `shiraz`. An item without a recipe consumes nothing and is never auto-habis
/// (ADR-0040 §4); the seed shows that state on purpose, because a live venue
/// migrates one dish at a time.
///
/// **Prices** are per display unit and sit at roughly 1.0–1.5× Indonesian
/// market rates — tuned upward so that the derived recipe cost lands in the
/// same neighbourhood as the seeded `MenuItems.cost` (35% of menu price). The
/// fit is deliberately loose: this menu is priced at resort level, so the
/// honest food cost of a drink is ~11% and of a rendang ~36%. `MenuItems.cost`
/// stays authoritative either way (ADR-0040 §7) — the derived figure is only a
/// hint beside it.
library;

import '../../domain/models/stock_unit.dart';

/// One seeded bahan. [pricePerUnit] is rupiah per [unit]; [opening] and
/// [lowAt] are in [unit] too.
class SeedIngredient {
  final String id;
  final String name;
  final StockUnit unit;
  final double opening;
  final double? lowAt;
  final int pricePerUnit;

  /// Output of one production batch, in [unit]. Non-null ⇒ produced in-house
  /// from other bahan (see [seedIngredientRecipes]) rather than bought.
  final double? batchYield;

  const SeedIngredient(
    this.id,
    this.name,
    this.unit, {
    required this.opening,
    required this.pricePerUnit,
    this.lowAt,
    this.batchYield,
  });

  int get openingBase => unit.toBase(opening);
  int? get lowAtBase => lowAt == null ? null : unit.toBase(lowAt!);
  int? get batchYieldBase =>
      batchYield == null ? null : unit.toBase(batchYield!);
  int get costMicro => costMicroFromUnitPrice(pricePerUnit, unit);
}

/// One recipe line: [amount] of [unit] of [ingredientId]. [unit] only has to
/// share the bahan's *dimension* — 200 g against a bahan held in kg is fine,
/// and `seed_inventory_test.dart` proves every line does.
class SeedQty {
  final String ingredientId;
  final double amount;
  final StockUnit unit;

  const SeedQty(this.ingredientId, this.amount, this.unit);

  int get base => unit.toBase(amount);
}

/// The three recipe layers of one menu item (ADR-0040 §3): [base], a
/// per-variant list that **replaces** the base entirely, and per-option lists
/// that **add** on top of whichever won.
class SeedRecipe {
  final List<SeedQty> base;
  final Map<String, List<SeedQty>> byVariant;
  final Map<String, List<SeedQty>> byOption;

  const SeedRecipe({
    this.base = const [],
    this.byVariant = const {},
    this.byOption = const {},
  });
}

const _g = StockUnit.g;
const _kg = StockUnit.kg;
const _ml = StockUnit.ml;
const _l = StockUnit.l;
const _pcs = StockUnit.pcs;
const _butir = StockUnit.butir;
const _lembar = StockUnit.lembar;

/// The bahan catalogue. Opening stock is a plausible mid-week holding; only
/// **udang** is seeded below its reorder threshold, so the stock screen shows a
/// low badge on first open without anything being habis.
const seedIngredients = <SeedIngredient>[
  // — staples ————————————————————————————————————————————————
  SeedIngredient(
    'beras',
    'Beras',
    _kg,
    opening: 25,
    lowAt: 6,
    pricePerUnit: 23000,
  ),
  SeedIngredient(
    'mie',
    'Mie telur',
    _kg,
    opening: 8,
    lowAt: 2,
    pricePerUnit: 33000,
  ),
  SeedIngredient(
    'tepung',
    'Tepung terigu',
    _kg,
    opening: 6,
    lowAt: 2,
    pricePerUnit: 15500,
  ),
  SeedIngredient(
    'minyak',
    'Minyak goreng',
    _l,
    opening: 20,
    lowAt: 5,
    pricePerUnit: 27000,
  ),
  SeedIngredient(
    'garam',
    'Garam',
    _kg,
    opening: 3,
    lowAt: 1,
    pricePerUnit: 12000,
  ),
  SeedIngredient(
    'gula',
    'Gula pasir',
    _kg,
    opening: 8,
    lowAt: 2,
    pricePerUnit: 24000,
  ),
  SeedIngredient(
    'kecap',
    'Kecap manis',
    _l,
    opening: 5,
    lowAt: 1.5,
    pricePerUnit: 42000,
  ),
  SeedIngredient(
    'santan',
    'Santan',
    _l,
    opening: 6,
    lowAt: 1.5,
    pricePerUnit: 23000,
  ),

  // — protein ————————————————————————————————————————————————
  SeedIngredient(
    'telur',
    'Telur ayam',
    _butir,
    opening: 120,
    lowAt: 24,
    pricePerUnit: 4500,
  ),
  SeedIngredient(
    'ayam',
    'Daging ayam',
    _kg,
    opening: 12,
    lowAt: 3,
    pricePerUnit: 68000,
  ),
  SeedIngredient(
    'sapi',
    'Daging sapi',
    _kg,
    opening: 8,
    lowAt: 2,
    pricePerUnit: 162000,
  ),
  // Seeded below its threshold on purpose — the one low-stock badge.
  SeedIngredient(
    'udang',
    'Udang',
    _kg,
    opening: 1.2,
    lowAt: 1.5,
    pricePerUnit: 130000,
  ),
  SeedIngredient(
    'tahu',
    'Tahu',
    _pcs,
    opening: 60,
    lowAt: 15,
    pricePerUnit: 3500,
  ),
  SeedIngredient(
    'tempe',
    'Tempe (papan)',
    _pcs,
    opening: 30,
    lowAt: 8,
    pricePerUnit: 7000,
  ),

  // — sayur & buah ————————————————————————————————————————————
  SeedIngredient(
    'sayur',
    'Sayur campur',
    _kg,
    opening: 10,
    lowAt: 3,
    pricePerUnit: 27000,
  ),
  SeedIngredient(
    'kentang',
    'Kentang',
    _kg,
    opening: 10,
    lowAt: 3,
    pricePerUnit: 19500,
  ),
  SeedIngredient(
    'kacang-tanah',
    'Kacang tanah',
    _kg,
    opening: 5,
    lowAt: 1.5,
    pricePerUnit: 43000,
  ),
  SeedIngredient(
    'cabai',
    'Cabai merah',
    _kg,
    opening: 4,
    lowAt: 1,
    pricePerUnit: 84000,
  ),
  SeedIngredient(
    'bawang-merah',
    'Bawang merah',
    _kg,
    opening: 4,
    lowAt: 1,
    pricePerUnit: 60000,
  ),
  SeedIngredient(
    'bawang-putih',
    'Bawang putih',
    _kg,
    opening: 2.5,
    lowAt: 0.8,
    pricePerUnit: 57000,
  ),
  SeedIngredient(
    'pisang',
    'Pisang kepok',
    _pcs,
    opening: 80,
    lowAt: 20,
    pricePerUnit: 3000,
  ),

  // — dapur kering & bar ——————————————————————————————————————
  SeedIngredient(
    'krupuk',
    'Krupuk udang',
    _pcs,
    opening: 200,
    lowAt: 50,
    pricePerUnit: 1600,
  ),
  SeedIngredient(
    'kulit-lumpia',
    'Kulit lumpia',
    _lembar,
    opening: 200,
    lowAt: 50,
    pricePerUnit: 1100,
  ),
  SeedIngredient(
    'tusuk-sate',
    'Tusuk sate',
    _pcs,
    opening: 500,
    lowAt: 100,
    pricePerUnit: 200,
  ),
  SeedIngredient(
    'es-krim',
    'Es krim vanila',
    _l,
    opening: 4,
    lowAt: 1,
    pricePerUnit: 77000,
  ),
  SeedIngredient(
    'teh',
    'Teh melati',
    _kg,
    opening: 1.5,
    lowAt: 0.4,
    pricePerUnit: 135000,
  ),
  SeedIngredient(
    'es-batu',
    'Es batu',
    _kg,
    opening: 30,
    lowAt: 8,
    pricePerUnit: 4500,
  ),
  SeedIngredient(
    'patty-wagyu',
    'Patty wagyu',
    _pcs,
    opening: 24,
    lowAt: 6,
    pricePerUnit: 44000,
  ),
  SeedIngredient(
    'roti-burger',
    'Roti burger',
    _pcs,
    opening: 30,
    lowAt: 8,
    pricePerUnit: 8000,
  ),
  SeedIngredient(
    'keju',
    'Keju lembar',
    _lembar,
    opening: 60,
    lowAt: 15,
    pricePerUnit: 4000,
  ),
  // A bottled drink is a bahan whose recipe is one of itself (ADR-0040 §1) —
  // there is no separate "countable SKU" concept.
  SeedIngredient(
    'botol-bintang',
    'Bintang 330 ml',
    _pcs,
    opening: 48,
    lowAt: 12,
    pricePerUnit: 18500,
  ),
  SeedIngredient(
    'kombucha',
    'Kombucha rumahan',
    _l,
    opening: 12,
    lowAt: 3,
    pricePerUnit: 38000,
  ),
  SeedIngredient(
    'botol-balihai',
    'Bali Hai 330 ml',
    _pcs,
    opening: 48,
    lowAt: 12,
    pricePerUnit: 16000,
  ),
  SeedIngredient(
    'botol-guinness',
    'Guinness 330 ml',
    _pcs,
    opening: 24,
    lowAt: 6,
    pricePerUnit: 32000,
  ),
  SeedIngredient(
    'botol-air',
    'Air mineral 600 ml',
    _pcs,
    opening: 120,
    lowAt: 30,
    pricePerUnit: 4000,
  ),
  SeedIngredient('ikan', 'Ikan segar', _kg, opening: 9, lowAt: 2, pricePerUnit: 95000),
  SeedIngredient('bebek', 'Bebek', _kg, opening: 6, lowAt: 1.5, pricePerUnit: 88000),
  SeedIngredient(
    'kelapa-parut',
    'Kelapa parut',
    _kg,
    opening: 5,
    lowAt: 1,
    pricePerUnit: 28000,
  ),
  SeedIngredient(
    'jeruk-nipis',
    'Jeruk nipis',
    _kg,
    opening: 4,
    lowAt: 1,
    pricePerUnit: 26000,
  ),
  SeedIngredient(
    'daun-pisang',
    'Daun pisang',
    _lembar,
    opening: 100,
    lowAt: 25,
    pricePerUnit: 1500,
  ),
  SeedIngredient(
    'kopi',
    'Biji kopi',
    _kg,
    opening: 3,
    lowAt: 0.8,
    pricePerUnit: 185000,
  ),
  SeedIngredient('susu', 'Susu segar', _l, opening: 12, lowAt: 3, pricePerUnit: 22000),
  SeedIngredient(
    'gula-aren',
    'Gula aren',
    _kg,
    opening: 4,
    lowAt: 1,
    pricePerUnit: 38000,
  ),

  // — dibuat sendiri ——————————————————————————————————————————
  // Produced bahan: one level only, and habis does NOT cascade — sambal at
  // zero makes the dish habis even when cabai is plentiful (ADR-0040 §5).
  SeedIngredient(
    'sambal',
    'Sambal',
    _kg,
    opening: 2,
    lowAt: 0.5,
    pricePerUnit: 71000,
    batchYield: 2,
  ),
  SeedIngredient(
    'saus-kacang',
    'Saus kacang',
    _kg,
    opening: 1.5,
    lowAt: 0.4,
    pricePerUnit: 42500,
    batchYield: 1.5,
  ),
];

/// Recipes of the two produced bahan — what one batch of [SeedIngredient
/// .batchYield] consumes. Only non-produced bahan may appear here.
const seedIngredientRecipes = <String, List<SeedQty>>{
  'sambal': [
    SeedQty('cabai', 1.2, _kg),
    SeedQty('bawang-merah', 400, _g),
    SeedQty('bawang-putih', 150, _g),
    SeedQty('garam', 30, _g),
    SeedQty('minyak', 300, _ml),
  ],
  'saus-kacang': [
    SeedQty('kacang-tanah', 1, _kg),
    SeedQty('cabai', 100, _g),
    SeedQty('bawang-putih', 50, _g),
    SeedQty('gula', 150, _g),
    SeedQty('garam', 20, _g),
    SeedQty('minyak', 200, _ml),
  ],
};

/// Item resep, keyed by menu item id. **nasi-goreng** and **ayam-bakar** carry
/// all three layers; the rest are base-only, which is what most of a real menu
/// looks like. The cocktails and wines are absent on purpose.
const seedItemRecipes = <String, SeedRecipe>{
  'gado-gado': SeedRecipe(
    base: [
      SeedQty('sayur', 200, _g),
      SeedQty('tahu', 2, _pcs),
      SeedQty('tempe', 0.5, _pcs),
      SeedQty('telur', 1, _butir),
      SeedQty('saus-kacang', 80, _g),
    ],
  ),
  'lumpia': SeedRecipe(
    base: [
      SeedQty('kulit-lumpia', 5, _lembar),
      SeedQty('ayam', 120, _g),
      SeedQty('sayur', 60, _g),
      SeedQty('minyak', 50, _ml),
    ],
  ),
  'sate-ayam': SeedRecipe(
    base: [
      SeedQty('ayam', 250, _g),
      SeedQty('tusuk-sate', 4, _pcs),
      SeedQty('saus-kacang', 80, _g),
      SeedQty('beras', 100, _g),
    ],
  ),
  'nasi-goreng': SeedRecipe(
    base: [
      SeedQty('beras', 250, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('kecap', 20, _ml),
      SeedQty('minyak', 25, _ml),
      SeedQty('bawang-merah', 20, _g),
      SeedQty('bawang-putih', 10, _g),
      SeedQty('krupuk', 3, _pcs),
      SeedQty('garam', 4, _g),
    ],
    // A variant list REPLACES the base — "Besar" is a full list, not a delta
    // and not a multiplier (ADR-0040 §3). Only `lg` is overridden; `reg` falls
    // through to the base.
    byVariant: {
      'lg': [
        SeedQty('beras', 375, _g),
        SeedQty('telur', 2, _butir),
        SeedQty('kecap', 30, _ml),
        SeedQty('minyak', 35, _ml),
        SeedQty('bawang-merah', 30, _g),
        SeedQty('bawang-putih', 14, _g),
        SeedQty('krupuk', 4, _pcs),
        SeedQty('garam', 6, _g),
      ],
    },
    // Option lists ADD on top of whichever list won. `none` (Tanpa protein)
    // has no entry: it adds nothing.
    byOption: {
      'chicken': [SeedQty('ayam', 90, _g)],
      'beef': [SeedQty('sapi', 90, _g)],
      'prawn': [SeedQty('udang', 80, _g)],
      'tofu': [SeedQty('tahu', 2, _pcs)],
      'krupuk': [SeedQty('krupuk', 3, _pcs)],
      'satay': [
        SeedQty('ayam', 120, _g),
        SeedQty('tusuk-sate', 2, _pcs),
        SeedQty('saus-kacang', 40, _g),
      ],
      'egg': [SeedQty('telur', 1, _butir)],
      'sambal': [SeedQty('sambal', 30, _g)],
    },
  ),
  'rendang': SeedRecipe(
    base: [
      SeedQty('sapi', 240, _g),
      SeedQty('santan', 160, _ml),
      SeedQty('cabai', 30, _g),
      SeedQty('bawang-merah', 25, _g),
      SeedQty('bawang-putih', 12, _g),
      SeedQty('garam', 5, _g),
      SeedQty('beras', 200, _g),
    ],
  ),
  'mie-goreng': SeedRecipe(
    base: [
      SeedQty('mie', 200, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('sayur', 100, _g),
      SeedQty('kecap', 20, _ml),
      SeedQty('minyak', 25, _ml),
      SeedQty('bawang-merah', 20, _g),
    ],
  ),
  'burger': SeedRecipe(
    base: [
      SeedQty('patty-wagyu', 1, _pcs),
      SeedQty('roti-burger', 1, _pcs),
      SeedQty('keju', 1, _lembar),
      SeedQty('kentang', 150, _g),
      SeedQty('minyak', 30, _ml),
    ],
  ),
  'crispy-tempeh': SeedRecipe(
    base: [
      SeedQty('tempe', 1, _pcs),
      SeedQty('beras', 200, _g),
      SeedQty('sambal', 50, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('minyak', 35, _ml),
      SeedQty('sayur', 80, _g),
    ],
  ),
  'krupuk-side': SeedRecipe(base: [SeedQty('krupuk', 3, _pcs)]),
  'pisang': SeedRecipe(
    base: [
      SeedQty('pisang', 3, _pcs),
      SeedQty('tepung', 45, _g),
      SeedQty('minyak', 60, _ml),
      SeedQty('gula', 25, _g),
      SeedQty('es-krim', 70, _ml),
    ],
  ),
  'es-teh': SeedRecipe(
    base: [
      SeedQty('teh', 8, _g),
      SeedQty('gula', 25, _g),
      SeedQty('es-batu', 250, _g),
    ],
  ),
  'bintang': SeedRecipe(base: [SeedQty('botol-bintang', 1, _pcs)]),
  'kombucha': SeedRecipe(base: [SeedQty('kombucha', 330, _ml)]),

  // ---- Pembuka ----
  'tahu-isi': SeedRecipe(
    base: [
      SeedQty('tahu', 4, _pcs),
      SeedQty('sayur', 80, _g),
      SeedQty('tepung', 60, _g),
      SeedQty('minyak', 80, _ml),
    ],
  ),
  'perkedel': SeedRecipe(
    base: [
      SeedQty('kentang', 300, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('bawang-merah', 30, _g),
      SeedQty('minyak', 70, _ml),
    ],
  ),
  'sate-lilit': SeedRecipe(
    base: [
      SeedQty('ikan', 180, _g),
      SeedQty('kelapa-parut', 60, _g),
      SeedQty('tusuk-sate', 5, _pcs),
      SeedQty('cabai', 15, _g),
      SeedQty('bawang-merah', 20, _g),
    ],
  ),

  // ---- Utama ----
  'ayam-bakar': SeedRecipe(
    base: [
      SeedQty('ayam', 500, _g),
      SeedQty('kecap', 40, _ml),
      SeedQty('cabai', 25, _g),
      SeedQty('bawang-merah', 30, _g),
      SeedQty('beras', 200, _g),
    ],
    byVariant: {
      'whole': [
        SeedQty('ayam', 1000, _g),
        SeedQty('kecap', 70, _ml),
        SeedQty('cabai', 40, _g),
        SeedQty('bawang-merah', 50, _g),
        SeedQty('beras', 350, _g),
      ],
    },
    byOption: {
      'hot': [SeedQty('sambal', 30, _g)],
      'md': [SeedQty('sambal', 15, _g)],
    },
  ),
  'ikan-bakar': SeedRecipe(
    base: [
      SeedQty('ikan', 350, _g),
      SeedQty('sambal', 40, _g),
      SeedQty('jeruk-nipis', 30, _g),
      SeedQty('beras', 200, _g),
      SeedQty('minyak', 20, _ml),
    ],
  ),
  'bebek-goreng': SeedRecipe(
    base: [
      SeedQty('bebek', 400, _g),
      SeedQty('minyak', 150, _ml),
      SeedQty('sambal', 50, _g),
      SeedQty('sayur', 60, _g),
    ],
  ),
  'nasi-campur': SeedRecipe(
    base: [
      SeedQty('beras', 250, _g),
      SeedQty('ayam', 120, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('sayur', 80, _g),
      SeedQty('kelapa-parut', 30, _g),
      SeedQty('krupuk', 2, _pcs),
    ],
    byOption: {
      'hot': [SeedQty('sambal', 30, _g)],
      'md': [SeedQty('sambal', 15, _g)],
    },
  ),
  // Base carries no protein: each option adds one, the way nasi-goreng does.
  'cap-cay': SeedRecipe(
    base: [
      SeedQty('sayur', 250, _g),
      SeedQty('bawang-putih', 10, _g),
      SeedQty('minyak', 30, _ml),
      SeedQty('garam', 4, _g),
    ],
    byOption: {
      'prawn': [SeedQty('udang', 80, _g)],
      'chicken': [SeedQty('ayam', 90, _g)],
    },
  ),
  'soto-ayam': SeedRecipe(
    base: [
      SeedQty('ayam', 150, _g),
      SeedQty('mie', 80, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('bawang-merah', 25, _g),
      SeedQty('minyak', 20, _ml),
    ],
  ),
  'pepes-tahu': SeedRecipe(
    base: [
      SeedQty('tahu', 3, _pcs),
      SeedQty('daun-pisang', 2, _lembar),
      SeedQty('cabai', 15, _g),
      SeedQty('bawang-merah', 20, _g),
    ],
  ),

  // ---- Pendamping ----
  'nasi-putih': SeedRecipe(base: [SeedQty('beras', 180, _g)]),
  'kentang-goreng': SeedRecipe(
    base: [
      SeedQty('kentang', 250, _g),
      SeedQty('minyak', 100, _ml),
      SeedQty('garam', 5, _g),
      SeedQty('sambal', 20, _g),
    ],
  ),
  'sayur-urap': SeedRecipe(
    base: [
      SeedQty('sayur', 180, _g),
      SeedQty('kelapa-parut', 50, _g),
      SeedQty('cabai', 10, _g),
    ],
  ),
  'telur-balado': SeedRecipe(
    base: [
      SeedQty('telur', 2, _butir),
      SeedQty('sambal', 45, _g),
      SeedQty('minyak', 30, _ml),
    ],
  ),

  // ---- Penutup ----
  'es-campur': SeedRecipe(
    base: [
      SeedQty('es-batu', 300, _g),
      SeedQty('santan', 120, _ml),
      SeedQty('gula', 30, _g),
      SeedQty('es-krim', 80, _ml),
      SeedQty('pisang', 1, _pcs),
    ],
  ),
  'dadar-gulung': SeedRecipe(
    base: [
      SeedQty('tepung', 70, _g),
      SeedQty('kelapa-parut', 60, _g),
      SeedQty('gula', 40, _g),
      SeedQty('telur', 1, _butir),
      SeedQty('santan', 60, _ml),
    ],
  ),
  'panna-cotta': SeedRecipe(
    base: [
      SeedQty('santan', 150, _ml),
      SeedQty('gula-aren', 35, _g),
      SeedQty('kelapa-parut', 20, _g),
      SeedQty('es-krim', 40, _ml),
    ],
  ),

  // ---- Bir / Non-alkohol ----
  'bali-hai': SeedRecipe(base: [SeedQty('botol-balihai', 1, _pcs)]),
  'guinness': SeedRecipe(base: [SeedQty('botol-guinness', 1, _pcs)]),
  'air-mineral': SeedRecipe(base: [SeedQty('botol-air', 1, _pcs)]),
  'es-jeruk': SeedRecipe(
    base: [
      SeedQty('jeruk-nipis', 120, _g),
      SeedQty('gula', 25, _g),
      SeedQty('es-batu', 250, _g),
    ],
  ),
  'kopi-susu': SeedRecipe(
    base: [
      SeedQty('kopi', 18, _g),
      SeedQty('susu', 150, _ml),
      SeedQty('gula-aren', 20, _g),
      SeedQty('es-batu', 200, _g),
    ],
  ),
};

/// `{base, byVariant, byOption}` payload for `writeRecipes`.
Map<String, dynamic> seedRecipePayload(SeedRecipe r) => {
  'base': _lines(r.base),
  'byVariant': {for (final e in r.byVariant.entries) e.key: _lines(e.value)},
  'byOption': {for (final e in r.byOption.entries) e.key: _lines(e.value)},
};

List<Map<String, dynamic>> _lines(List<SeedQty> qs) => [
  for (final q in qs) {'ingredientId': q.ingredientId, 'qty': q.base},
];
