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

  const TaxServiceConfig({
    required this.taxEnabled,
    required this.taxRateBps,
    required this.serviceEnabled,
    required this.serviceMode,
    required this.serviceRateBps,
    required this.serviceFixedAmount,
  });
}

/// The computed money breakdown of one receipt (or a whole single-receipt bill).
class MoneyBreakdown {
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  const MoneyBreakdown({
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
  });
}

/// Service-then-tax stacking (ID PB1 convention): service applies to the
/// subtotal, then tax applies to (subtotal + service).
///
/// [serviceOverride] forces a fixed service amount (used when distributing a
/// per-bill fixed service charge proportionally across split receipts); when
/// null and the config is percent-mode, service is computed from [subtotal].
MoneyBreakdown computeBreakdown(
  int subtotal,
  TaxServiceConfig cfg, {
  int? serviceOverride,
}) {
  var service = 0;
  if (cfg.serviceEnabled) {
    if (serviceOverride != null) {
      service = serviceOverride;
    } else if (cfg.serviceMode == 'fixed') {
      service = cfg.serviceFixedAmount;
    } else {
      service = (subtotal * cfg.serviceRateBps) ~/ 10000;
    }
  }
  var tax = 0;
  if (cfg.taxEnabled) {
    tax = ((subtotal + service) * cfg.taxRateBps) ~/ 10000;
  }
  return MoneyBreakdown(
    subtotal: subtotal,
    serviceAmount: service,
    taxAmount: tax,
    total: subtotal + service + tax,
  );
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
List<MoneyBreakdown> splitItemized(
  List<int> subtotals,
  TaxServiceConfig cfg, {
  int? billTotalTarget,
}) {
  final n = subtotals.length;
  if (n == 0) return const [];
  final fixedShares = (cfg.serviceEnabled && cfg.serviceMode == 'fixed')
      ? distributeFixed(subtotals, cfg.serviceFixedAmount)
      : null;
  final out = <MoneyBreakdown>[
    for (var i = 0; i < n; i++)
      computeBreakdown(subtotals[i], cfg,
          serviceOverride: fixedShares?[i]),
  ];
  if (billTotalTarget != null) {
    final sum = out.fold<int>(0, (a, b) => a + b.total);
    final diff = billTotalTarget - sum;
    if (diff != 0) {
      final i = _largestIndex(subtotals);
      out[i] = MoneyBreakdown(
        subtotal: out[i].subtotal,
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
