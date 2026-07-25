/// Pure money math for [[Bill]] settlement. No Flutter / IO. Integer rupiah
/// throughout. See docs/adr/0023-two-phase-settlement-and-split-bills.md and
/// CONTEXT.md "Tax & service charge".
library;

/// The venue tax/service configuration, mirrored from `VenueSettings`.
class TaxServiceConfig {
  final bool taxEnabled;
  final int taxRateBps; // basis points, e.g. 1100 = 11%
  final bool serviceEnabled;
  final String serviceMode; // 'percent' | 'fixed'
  final int serviceRateBps; // percent mode
  final int serviceFixedAmount; // fixed mode (per bill)

  /// Where a whole-order [[Diskon (discount)]] sits in the stack (ADR-0038).
  /// `true` (default, DPP-correct): the discount reduces the base **both**
  /// add-ons compute from. `false`: service+tax are computed on the gross
  /// subtotal and the discount comes off the grand total last.
  ///
  /// Line discounts are always pre-tax and are **not** governed by this flag —
  /// they are folded into [subtotal] by the caller before it reaches here.
  final bool taxAfterDiscount;

  const TaxServiceConfig({
    required this.taxEnabled,
    required this.taxRateBps,
    required this.serviceEnabled,
    required this.serviceMode,
    required this.serviceRateBps,
    required this.serviceFixedAmount,
    this.taxAfterDiscount = true,
  });
}

/// The computed money breakdown of one receipt (or a whole single-receipt bill).
class MoneyBreakdown {
  /// Line subtotal **already net of any line discounts**.
  final int subtotal;

  /// The whole-order discount actually applied, after clamping. May be less
  /// than the requested amount when the discount would drive the total below
  /// zero. Does **not** include line discounts (those are inside [subtotal]).
  final int discountAmount;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  const MoneyBreakdown({
    required this.subtotal,
    this.discountAmount = 0,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
  });
}

/// Service-then-tax stacking (ID PB1 convention): service applies to the
/// subtotal, then tax applies to (subtotal + service).
///
/// [subtotal] must already be **net of line discounts** — a line discount is a
/// price change and so is part of how the subtotal is derived (ADR-0038).
/// [discount] is the **whole-order** discount only; where it lands depends on
/// `cfg.taxAfterDiscount`:
///
/// ```
/// taxAfterDiscount = true          taxAfterDiscount = false
///   base = subtotal − discount       service = subtotal × rate
///   service = base × rate            tax     = (subtotal+service) × rate
///   tax     = (base+service) × rate  total   = subtotal+service+tax − discount
///   total   = base+service+tax
/// ```
///
/// The discount is clamped so the total can never go negative — a discount is
/// not a refund and must not push money outward. The amount actually applied
/// is reported on [MoneyBreakdown.discountAmount].
///
/// [serviceOverride] forces a fixed service amount (used when distributing a
/// per-bill fixed service charge proportionally across split receipts); when
/// null and the config is percent-mode, service is computed from the base.
MoneyBreakdown computeBreakdown(
  int subtotal,
  TaxServiceConfig cfg, {
  int? serviceOverride,
  int discount = 0,
}) {
  int serviceOn(int base) {
    if (!cfg.serviceEnabled) return 0;
    if (serviceOverride != null) return serviceOverride;
    if (cfg.serviceMode == 'fixed') return cfg.serviceFixedAmount;
    return (base * cfg.serviceRateBps) ~/ 10000;
  }

  int taxOn(int base, int service) =>
      cfg.taxEnabled ? ((base + service) * cfg.taxRateBps) ~/ 10000 : 0;

  final requested = discount < 0 ? 0 : discount;

  if (cfg.taxAfterDiscount) {
    // Discount reduces the base both add-ons compute from.
    final applied = requested > subtotal ? subtotal : requested;
    final base = subtotal - applied;
    final service = serviceOn(base);
    final tax = taxOn(base, service);
    return MoneyBreakdown(
      subtotal: subtotal,
      discountAmount: applied,
      serviceAmount: service,
      taxAmount: tax,
      total: base + service + tax,
    );
  }

  // Gross-then-promo: add-ons on the full subtotal, discount off the total.
  final service = serviceOn(subtotal);
  final tax = taxOn(subtotal, service);
  final gross = subtotal + service + tax;
  final applied = requested > gross ? gross : requested;
  return MoneyBreakdown(
    subtotal: subtotal,
    discountAmount: applied,
    serviceAmount: service,
    taxAmount: tax,
    total: gross - applied,
  );
}

/// Resolve a [[Preset diskon]]'s `{kind, value}` against a [base] into rupiah.
/// `percent` reads [value] as basis points (clamped to 100%); `fixed` reads it
/// as rupiah (clamped to [base]). Shared by the server and the cashier UI so
/// the quoted and the stored amount can never disagree.
int resolveDiscountAmount({
  required String kind,
  required int value,
  required int base,
}) {
  if (value <= 0 || base <= 0) return 0;
  if (kind == 'fixed') return value > base ? base : value;
  final bps = value > 10000 ? 10000 : value;
  return (base * bps) ~/ 10000;
}

/// Distribute a whole-bill fixed service charge across receipt subtotals
/// proportionally, pushing the integer rounding remainder onto the receipt
/// with the largest subtotal so the parts sum to [fixedTotal] exactly. Returns
/// a list aligned to [subtotals]. When the subtotals sum to 0, splits evenly.
List<int> distributeFixed(List<int> subtotals, int fixedTotal) {
  final n = subtotals.length;
  if (n == 0) return const [];
  final sumSub = subtotals.fold<int>(0, (a, b) => a + b);
  final out = List<int>.filled(n, 0);
  if (sumSub == 0) {
    final base = fixedTotal ~/ n;
    for (var i = 0; i < n; i++) {
      out[i] = base;
    }
  } else {
    for (var i = 0; i < n; i++) {
      out[i] = (fixedTotal * subtotals[i]) ~/ sumSub;
    }
  }
  // Push the remainder onto the largest-subtotal receipt.
  final assigned = out.fold<int>(0, (a, b) => a + b);
  final remainder = fixedTotal - assigned;
  if (remainder != 0) {
    out[_largestIndex(subtotals)] += remainder;
  }
  return out;
}

/// Per-receipt breakdowns for an itemized [[Split bill]]. Each receipt's
/// service+tax is computed on its own [subtotals] entry (service-then-tax);
/// for fixed-service mode the per-bill fixed charge is distributed across
/// receipts proportionally to subtotal. When [billTotalTarget] is given (the
/// bill is fully assigned), the integer rounding remainder is pushed onto the
/// largest-subtotal receipt so the receipts sum to the bill total exactly.
///
/// [discounts], when given, holds each receipt's own whole-order discount and
/// must align to [subtotals]. A percent order discount is resolved per receipt
/// by the caller; a fixed whole-bill one is fanned out with [distributeFixed]
/// before it gets here, so this function never sees a bill-level amount.
List<MoneyBreakdown> splitItemized(
  List<int> subtotals,
  TaxServiceConfig cfg, {
  int? billTotalTarget,
  List<int>? discounts,
}) {
  final n = subtotals.length;
  if (n == 0) return const [];
  final fixedShares = (cfg.serviceEnabled && cfg.serviceMode == 'fixed')
      ? distributeFixed(subtotals, cfg.serviceFixedAmount)
      : null;
  final out = <MoneyBreakdown>[
    for (var i = 0; i < n; i++)
      computeBreakdown(subtotals[i], cfg,
          serviceOverride: fixedShares?[i],
          discount: discounts == null ? 0 : discounts[i]),
  ];
  if (billTotalTarget != null) {
    final sum = out.fold<int>(0, (a, b) => a + b.total);
    final diff = billTotalTarget - sum;
    if (diff != 0) {
      final i = _largestIndex(subtotals);
      out[i] = MoneyBreakdown(
        subtotal: out[i].subtotal,
        discountAmount: out[i].discountAmount,
        serviceAmount: out[i].serviceAmount,
        taxAmount: out[i].taxAmount + diff,
        total: out[i].total + diff,
      );
    }
  }
  return out;
}

/// Even split of [billTotal] into [n] receipts, remainder onto the first.
List<int> distributeEven(int billTotal, int n) {
  if (n <= 0) return const [];
  final base = billTotal ~/ n;
  final out = List<int>.filled(n, base);
  out[0] += billTotal - base * n;
  return out;
}

int _largestIndex(List<int> xs) {
  var idx = 0;
  var best = xs.isEmpty ? 0 : xs[0];
  for (var i = 1; i < xs.length; i++) {
    if (xs[i] > best) {
      best = xs[i];
      idx = i;
    }
  }
  return idx;
}
