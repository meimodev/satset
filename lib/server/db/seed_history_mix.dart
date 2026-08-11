/// The hand-authored order mix behind the [[Generic seed (sample data)]]'s
/// fabricated month (ADR-0053 §6, carried into ADR-0073).
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
  'nasi-campur': 6.5,
  'ayam-bakar': 5.5,
  'soto-ayam': 4.5,
  'crispy-tempeh': 4.0,
  'rendang': 3.5,
  'cap-cay': 3.0,
  'ikan-bakar': 2.8,
  'pepes-tahu': 2.2,
  'burger': 2.0,
  'bebek-goreng': 1.8,
  // Starters — roughly half of tables take one, satay leading.
  'sate-ayam': 5.5,
  'lumpia': 3.5,
  'gado-gado': 3.0,
  'tahu-isi': 2.6,
  'perkedel': 2.2,
  'sate-lilit': 1.8,
  // Sides — cheap, frequent, often added late.
  'krupuk-side': 6.0,
  'nasi-putih': 5.5,
  'kentang-goreng': 4.0,
  'sayur-urap': 2.0,
  'telur-balado': 1.8,
  // Desserts — one table in three, and almost always the same one.
  'pisang': 5.0,
  'es-campur': 3.0,
  'dadar-gulung': 1.6,
  'panna-cotta': 1.2,
  // Drinks — iced tea is ordered more than everything else combined.
  'es-teh': 14.0,
  'air-mineral': 7.0,
  'bintang': 6.0,
  'es-jeruk': 5.0,
  'kopi-susu': 4.0,
  'kombucha': 2.5,
  'bali-hai': 2.2,
  'margarita': 2.0,
  'rose': 1.5,
  'mojito': 1.4,
  'sauvignon': 1.2,
  'guinness': 1.1,
  'negroni': 1.0,
  'espresso-martini': 0.9,
  'shiraz': 0.8,
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

/// How one seeded staff member turns up (ADR-0097) — the shape behind the Jam
/// kerja block.
///
/// A flat month is the tell here in the same way a flat arrival curve is one on
/// the sales side: four people with near-identical hours teach an owner nothing,
/// and the whole reason the block exists is to tell a diligent shift apart from
/// a slack one. So the roster is deliberately uneven, and it deliberately
/// contains forgotten sign-outs — a flag nobody has ever seen is a flag nobody
/// will understand the first time it appears for real.
class StaffAttendance {
  /// Share of days this person does not turn up at all. They take no orders on
  /// those days either: a waiter with bills and no shift is a contradiction the
  /// report would surface as a mystery.
  final double absentRate;

  /// Minutes on shift before their first order of the day — prep, setup,
  /// standing about. Low means they clocked in barely in time.
  final int earlyMin;
  final int earlyMax;

  /// Share of days they never sign out. The row is left open; the next day's
  /// sign-in retires it at its own rollover, exactly as the live path does.
  final double forgetRate;

  /// Share of days split in two by a handover — one stretch, a gap, another.
  /// Only worth giving to somebody: with none, "hari" and "shift" are the same
  /// number on every row and the distinction never shows itself.
  final double splitRate;

  const StaffAttendance({
    required this.absentRate,
    required this.earlyMin,
    required this.earlyMax,
    required this.forgetRate,
    required this.splitRate,
  });
}

/// Keyed by seeded user id. A staff row absent from this map takes the default
/// below, which is the unremarkable middle of the four.
const staffAttendance = <String, StaffAttendance>{
  // Reliable. Early, present, signs out, and hands the handset over mid-shift
  // often enough that their days and shifts read as different numbers.
  'seed-waiter': StaffAttendance(
    absentRate: 0.0,
    earlyMin: 38,
    earlyMax: 55,
    forgetRate: 0.03,
    splitRate: 0.32,
  ),
  // The contrast: turns up as service starts, misses roughly a day a week, and
  // forgets to sign out often enough to make the flag worth reading.
  'seed-waiter-2': StaffAttendance(
    absentRate: 0.14,
    earlyMin: 2,
    earlyMax: 12,
    forgetRate: 0.12,
    splitRate: 0.0,
  ),
  // Opens the kitchen — on well before the first order lands.
  'seed-kitchen': StaffAttendance(
    absentRate: 0.02,
    earlyMin: 55,
    earlyMax: 80,
    forgetRate: 0.04,
    splitRate: 0.0,
  ),
};

const defaultAttendance = StaffAttendance(
  absentRate: 0.05,
  earlyMin: 15,
  earlyMax: 30,
  forgetRate: 0.05,
  splitRate: 0.0,
);

/// Minutes on shift after the last order of the day — closing down, cashing up.
const closingDownMin = 20;
const closingDownMax = 45;

/// The seeded [[Pelanggan (member)]] roster.
///
/// Forty names, ordered by how often they come in: the list is walked with a
/// long-tail weight, so the first handful are the regulars whose punch cards
/// fill and whose points are worth redeeming, while the tail visited once and
/// never came back. A roster where everyone visits equally teaches the owner
/// nothing about their own directory.
///
/// Phones are the `0812-xxxx-xxxx` shape a cashier actually types and are
/// deliberately unique — the number is the identity (ADR-0092), so a duplicate
/// here would silently collapse two people into one at seed time.
const sampleMembers = <(String, String)>[
  ('Budi Santoso', '081233440001'),
  ('Siti Rahayu', '081233440002'),
  ('Agus Wijaya', '081233440003'),
  ('Dewi Lestari', '081233440004'),
  ('Rudi Hartono', '081233440005'),
  ('Nurul Aini', '081233440006'),
  ('Bambang Sutrisno', '081233440007'),
  ('Rina Marlina', '081233440008'),
  ('Hendra Gunawan', '081233440009'),
  ('Fitri Handayani', '081233440010'),
  ('Joko Susilo', '081233440011'),
  ('Maya Puspita', '081233440012'),
  ('Andi Pratama', '081233440013'),
  ('Lina Kurniawati', '081233440014'),
  ('Doni Setiawan', '081233440015'),
  ('Ratna Sari', '081233440016'),
  ('Eko Prasetyo', '081233440017'),
  ('Yuni Astuti', '081233440018'),
  ('Tono Wibowo', '081233440019'),
  ('Sri Wahyuni', '081233440020'),
  ('Gilang Ramadhan', '081233440021'),
  ('Indah Permata', '081233440022'),
  ('Faisal Rahman', '081233440023'),
  ('Wulan Sari', '081233440024'),
  ('Adi Nugroho', '081233440025'),
  ('Tia Anggraini', '081233440026'),
  ('Reza Firmansyah', '081233440027'),
  ('Sinta Dewi', '081233440028'),
  ('Yoga Saputra', '081233440029'),
  ('Mega Utami', '081233440030'),
  ('Bayu Kurnia', '081233440031'),
  ('Nadia Safitri', '081233440032'),
  ('Irfan Maulana', '081233440033'),
  ('Vina Oktaviani', '081233440034'),
  ('Surya Dharma', '081233440035'),
  ('Anisa Rahmawati', '081233440036'),
  ('Krisna Adi', '081233440037'),
  ('Putri Ayu', '081233440038'),
  ('Hasan Basri', '081233440039'),
  ('Laras Widya', '081233440040'),
];

/// Share of seeded bills that carry a member. A third is a program running
/// well without being the whole room — high enough that the Keanggotaan report
/// has something to compare, low enough that the walk-in average is real.
const memberAttachRate = 0.34;

/// Share of member bills that spend points. Rare on purpose: a guest saves for
/// several visits before a redemption is worth anything, so a ledger where
/// every visit redeems is a ledger nobody would believe.
const memberRedeemRate = 0.09;
