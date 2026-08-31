/// The **one** rule that turns a [[Visit]]'s lines, receipts, discounts and
/// payments into money (ADR-0123). Pure: no Drift, no Flutter, no IO.
///
/// It exists because the same arithmetic now has two callers. The host runs it
/// over its own rows in `settlement_routes.dart`; a [[Terputus (client
/// disconnected)|terputus]] [[Cashier|kasir]] runs it over the cached bill plus
/// its [[Antrean setelmen]] to render a total for a guest standing at the
/// counter. A second implementation would quote two different numbers for one
/// bill with nothing to say which was right.
///
/// Integer rupiah throughout. Stacking order is ADR-0038's: line discounts fold
/// into the subtotal, the order discount comes off that, service then tax.
library;

import 'package:satset/domain/use_cases/bill_math.dart';

/// One sent, non-[[Void (item)|voided]] ticket line on the bill.
class RcLine {
  final String ticketId;
  final int unitPrice;
  final int qty;
  const RcLine({
    required this.ticketId,
    required this.unitPrice,
    required this.qty,
  });
}

/// One receipt off the bill. [amountTotal] is only read for `even` (amount)
/// receipts, whose claim was frozen at mint (ADR-0068) and is never recomputed.
class RcReceipt {
  final String id;
  final String mode; // 'itemized' | 'even'
  final int amountTotal;
  const RcReceipt({required this.id, required this.mode, this.amountTotal = 0});

  bool get isAmount => mode == 'even';
}

/// Units of one ticket line claimed by one receipt.
class RcAssign {
  final String receiptId;
  final String ticketId;
  final int qtyUnits;
  const RcAssign({
    required this.receiptId,
    required this.ticketId,
    required this.qtyUnits,
  });
}

/// A live [[Diskon (discount)]] row, still holding its snapshotted
/// `kind`/`value` (ADR-0037) rather than a resolved rupiah amount — the amount
/// is derived here, because a receipt's base moves as lines are reassigned.
///
/// [receiptId] null ⇒ **bill-scope** (ADR-0070/0094). [ticketId] null ⇒
/// whole-order rather than per-line.
class RcDiscount {
  final String id;
  final String? receiptId;
  final String? ticketId;
  final String kind; // 'percent' | 'fixed'
  final int value;
  const RcDiscount({
    required this.id,
    required this.receiptId,
    required this.ticketId,
    required this.kind,
    required this.value,
  });
}

/// One receipt's recomputed money.
class RcReceiptMoney {
  final int subtotal;

  /// The reporting figure the receipt row stores: line discounts (already
  /// inside [subtotal]) plus the whole-order one actually applied.
  final int discountAmount;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status; // 'paid' | 'unpaid'
  const RcReceiptMoney({
    required this.subtotal,
    required this.discountAmount,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
  });
}

/// Everything one recompute produced.
class RcResult {
  /// Recomputed money per **itemized** receipt id. An amount receipt keeps its
  /// frozen total and appears only in [statuses].
  final Map<String, RcReceiptMoney> receipts;

  /// Every discount row's resolved rupiah, by discount id — bill-scope rows
  /// included. The host persists these; the client renders them.
  final Map<String, int> discountAmounts;

  /// `paid` / `unpaid` for **every** receipt, amount receipts included.
  final Map<String, String> statuses;

  /// Units claimed per ticket id, so a caller can render `assignedUnits`
  /// without walking the assignments again.
  final Map<String, int> assignedUnits;

  final int billSubtotal;
  final int billLineDiscount;
  final int billOrderDiscount;
  final int billScopeDiscount;

  /// The whole bill's breakdown — what [[Bill (tab)]] `total` reports.
  final MoneyBreakdown billBreak;

  final bool allUnitsAssigned;
  final bool fullyAssigned;

  const RcResult({
    required this.receipts,
    required this.discountAmounts,
    required this.statuses,
    required this.assignedUnits,
    required this.billSubtotal,
    required this.billLineDiscount,
    required this.billOrderDiscount,
    required this.billScopeDiscount,
    required this.billBreak,
    required this.allUnitsAssigned,
    required this.fullyAssigned,
  });

  int get billTotal => billBreak.total;
}

int _sum(Iterable<int> xs) => xs.fold<int>(0, (a, b) => a + b);

/// Recompute a whole bill from its parts.
///
/// [paidByReceipt] is the **net** paid per receipt (payments minus refunds),
/// used only to decide `paid`/`unpaid`; it never changes an amount.
RcResult recomputeBill({
  required List<RcLine> lines,
  required List<RcReceipt> receipts,
  required List<RcAssign> assigns,
  required List<RcDiscount> discounts,
  required Map<String, int> paidByReceipt,
  required TaxServiceConfig cfg,
}) {
  final priceOf = {for (final l in lines) l.ticketId: l.unitPrice};

  final assignedUnits = <String, int>{};
  for (final a in assigns) {
    // An assignment naming a line that is gone (voided since) claims nothing.
    if (!priceOf.containsKey(a.ticketId)) continue;
    assignedUnits[a.ticketId] = (assignedUnits[a.ticketId] ?? 0) + a.qtyUnits;
  }
  final allUnitsAssigned = lines.every(
    (l) => (assignedUnits[l.ticketId] ?? 0) >= l.qty,
  );

  final resolved = <String, int>{};
  final itemized = [
    for (final r in receipts)
      if (!r.isAmount) r,
  ];

  // ── per-receipt: line discounts fold into the subtotal, order discounts
  //    resolve against that net (ADR-0038) ──
  final subtotals = <int>[];
  final lineDiscounts = <int>[];
  final orderDiscounts = <int>[];
  for (final rec in itemized) {
    final units = <String, int>{};
    var gross = 0;
    for (final a in assigns.where((a) => a.receiptId == rec.id)) {
      final price = priceOf[a.ticketId];
      if (price == null) continue;
      gross += price * a.qtyUnits;
      units[a.ticketId] = (units[a.ticketId] ?? 0) + a.qtyUnits;
    }
    final ds = [
      for (final d in discounts)
        if (d.receiptId == rec.id) d,
    ];
    // A line discount's base is the value of the units THIS receipt owns.
    var lineDisc = 0;
    for (final d in ds.where((d) => d.ticketId != null)) {
      final price = priceOf[d.ticketId] ?? 0;
      final base = price * (units[d.ticketId] ?? 0);
      final amt = resolveDiscountAmount(
        kind: d.kind,
        value: d.value,
        base: base,
      );
      resolved[d.id] = amt;
      lineDisc += amt;
    }
    final net = gross - lineDisc;
    var orderDisc = 0;
    for (final d in ds.where((d) => d.ticketId == null)) {
      final amt = resolveDiscountAmount(
        kind: d.kind,
        value: d.value,
        base: net,
      );
      resolved[d.id] = amt;
      orderDisc += amt;
    }
    subtotals.add(net);
    lineDiscounts.add(lineDisc);
    orderDiscounts.add(orderDisc);
  }

  final billSub = lines.fold<int>(0, (a, l) => a + l.unitPrice * l.qty);
  final assignedSub = _sum(subtotals) + _sum(lineDiscounts);

  // ── bill-scope: belongs to the visit, so it is fanned out across the
  //    itemized receipts before they can be totalled — the job
  //    `distributeFixed` does for a fixed service charge. Amount receipts are
  //    excluded: their claim froze at mint (ADR-0068).
  //
  //    Sources stack (ADR-0094) and every one resolves against the SAME base —
  //    a percentage never compounds on another source's give-away. ──
  final billDiscBase = billSub - _sum(lineDiscounts);
  var billScopeDiscount = 0;
  for (final d in discounts.where((d) => d.receiptId == null)) {
    final amt = resolveDiscountAmount(
      kind: d.kind,
      value: d.value,
      base: billDiscBase,
    );
    resolved[d.id] = amt;
    billScopeDiscount += amt;
  }
  // ponytail: the stack is clamped to the base rather than reconciled row by
  // row. Only reachable when the slots together exceed 100%, and the printed
  // rows stay honest about what each promised.
  var fanBase = billScopeDiscount;
  if (fanBase > billDiscBase) fanBase = billDiscBase < 0 ? 0 : billDiscBase;
  if (fanBase > 0 && itemized.isNotEmpty) {
    final fanned = distributeFixed(subtotals, fanBase);
    for (var i = 0; i < itemized.length; i++) {
      orderDiscounts[i] += fanned[i];
    }
  }

  // Whatever the amount receipts already claim is not the itemized side's to
  // account for, so it comes off the target they have to hit.
  final amountClaim = receipts
      .where((r) => r.isAmount)
      .fold<int>(0, (a, r) => a + r.amountTotal);
  final target = allUnitsAssigned
      ? computeBreakdown(
              billSub - _sum(lineDiscounts),
              cfg,
              discount: _sum(orderDiscounts),
            ).total -
            amountClaim
      : null;
  final breakdowns = splitItemized(
    subtotals,
    cfg,
    billTotalTarget: (assignedSub == billSub) ? target : null,
    discounts: orderDiscounts,
  );

  final money = <String, RcReceiptMoney>{};
  final statuses = <String, String>{};
  for (var i = 0; i < itemized.length; i++) {
    final rec = itemized[i];
    final b = breakdowns[i];
    final paid = paidByReceipt[rec.id] ?? 0;
    final status = b.total > 0 && paid >= b.total ? 'paid' : 'unpaid';
    money[rec.id] = RcReceiptMoney(
      subtotal: b.subtotal,
      discountAmount: lineDiscounts[i] + b.discountAmount,
      serviceAmount: b.serviceAmount,
      taxAmount: b.taxAmount,
      total: b.total,
      status: status,
    );
    statuses[rec.id] = status;
  }
  for (final rec in receipts.where((r) => r.isAmount)) {
    final paid = paidByReceipt[rec.id] ?? 0;
    statuses[rec.id] = rec.amountTotal > 0 && paid >= rec.amountTotal
        ? 'paid'
        : 'unpaid';
  }

  // ── bill level. Aggregates the RESOLVED amounts, not a second resolution:
  //    without this the bill total stays undiscounted while the receipts
  //    shrink, so `outstanding` never reaches zero and a fully-paid discounted
  //    bill never shows Lunas. ──
  final billLineDiscount = _sum(lineDiscounts);
  final billOrderDiscount = _sum([
    for (final d in discounts)
      if (d.receiptId != null && d.ticketId == null) (resolved[d.id] ?? 0),
  ]);
  final billScopeApplied = billScopeDiscount.clamp(
    0,
    billSub - billLineDiscount < 0 ? 0 : billSub - billLineDiscount,
  );
  final billBreak = computeBreakdown(
    billSub - billLineDiscount,
    cfg,
    discount: billOrderDiscount + billScopeApplied,
  );

  return RcResult(
    receipts: money,
    discountAmounts: resolved,
    statuses: statuses,
    assignedUnits: {
      for (final l in lines) l.ticketId: assignedUnits[l.ticketId] ?? 0,
    },
    billSubtotal: billSub,
    billLineDiscount: billLineDiscount,
    billOrderDiscount: billOrderDiscount,
    billScopeDiscount: billScopeApplied,
    billBreak: billBreak,
    allUnitsAssigned: allUnitsAssigned,
    fullyAssigned: isFullyAssigned(
      hasReceipts: receipts.isNotEmpty,
      allUnitsAssigned: allUnitsAssigned,
      receiptsClaim: receipts.fold<int>(
        0,
        (a, r) => a + (r.isAmount ? r.amountTotal : (money[r.id]?.total ?? 0)),
      ),
      billTotal: billBreak.total,
    ),
  );
}
