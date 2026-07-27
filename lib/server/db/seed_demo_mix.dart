/// The hand-authored order mix behind the [[Demo seed (venue mid-service)]]
/// (ADR-0053 §6).
///
/// Routing the seed through the production order path fixes *how* rows are
/// written; it does nothing for what they contain. Uniform random baskets
/// produce a flat hourly chart and cocktails outselling rice — visibly
/// synthetic to anyone who reads the reports. These weights are what make a
/// generated month look like a traded one.
///
/// Authored by hand, deliberately: the failure mode is a human looking at a
/// report and saying "nobody orders that much rendang", and only an explicit
/// table lets them fix it. Tuned against the generic menu — an item with no
/// entry falls back to [defaultWeight] and will look under-ordered.
library;

/// Relative popularity per seeded item. A cheap staple outsells a signature
/// dish several times over; the wagyu burger and the aged spirits are the
/// occasional splurge that carries the average check.
const itemWeights = <String, double>{
  // Mains — the rice and noodle plates are what the room actually eats.
  'nasi-goreng': 10.0,
  'mie-goreng': 7.5,
  'crispy-tempeh': 4.0,
  'rendang': 3.5,
  'burger': 2.0,
  // Starters — roughly half of tables take one, satay leading.
  'sate-ayam': 5.5,
  'lumpia': 3.5,
  'gado-gado': 3.0,
  // Sides — cheap, frequent, often added late.
  'krupuk-side': 6.0,
  // Desserts — one table in three, and almost always the same one.
  'pisang': 5.0,
  // Drinks — iced tea is ordered more than everything else combined.
  'es-teh': 14.0,
  'bintang': 6.0,
  'kombucha': 2.5,
  'margarita': 2.0,
  'rose': 1.5,
  'negroni': 1.0,
};

/// Weight for an item the table does not name (a venue that added its own
/// before seeding). Low on purpose — an unweighted item should look like a
/// slow seller, not silently dominate the mix.
const defaultWeight = 1.0;

/// How often a **cover** takes something from each course. Drinks are near
/// universal; desserts are the minority decision that makes the dessert
/// column non-zero without making it look like a patisserie.
const courseAttachRate = <String, double>{
  'drinks-now': 0.92,
  'starters': 0.48,
  'mains': 0.96,
  'sides': 0.35,
  'desserts': 0.30,
};

/// Share of covers arriving in each hour of the trading day (11:00–21:00),
/// as a lunch hump and a larger dinner hump with a genuine lull between.
/// A flat curve is the single most obvious tell in a fabricated report.
const arrivalCurve = <int, double>{
  11: 0.04,
  12: 0.11,
  13: 0.13,
  14: 0.07,
  15: 0.03,
  16: 0.03,
  17: 0.06,
  18: 0.12,
  19: 0.17,
  20: 0.16,
  21: 0.08,
};

/// Party sizes, weighted. Pairs dominate, solo diners are real, and the big
/// group is rare enough that its bill stands out on the report the way it
/// does in a real venue.
const partySizeWeights = <int, double>{
  1: 0.12,
  2: 0.38,
  3: 0.16,
  4: 0.20,
  5: 0.07,
  6: 0.05,
  8: 0.02,
};

/// Multiplier on covers per weekday (Mon=1). Weekends carry the week; Monday
/// is the quiet day every restaurant recognises.
const weekdayLoad = <int, double>{
  1: 0.72,
  2: 0.80,
  3: 0.88,
  4: 0.95,
  5: 1.30,
  6: 1.55,
  7: 1.35,
};

/// Share of lines ordered at qty 2+ — sharing plates, rounds of the same
/// drink. Most lines are singles.
const multiQtyRate = 0.22;

/// Share of lines voided. Rare, but never zero: the void column on the report
/// should have something in it.
const voidRate = 0.018;

/// Share of bills that walk out unpaid (tak tertagih).
const walkoutRate = 1 / 120;
