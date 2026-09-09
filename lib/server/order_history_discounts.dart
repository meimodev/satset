import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/db/database.dart';

/// Allocated reporting shares, never a reprice of historical settlement.
/// Null means the snapshots cannot support a complete, reconciling item split.
Map<String, ({int direct, int shared})>? orderHistoryDiscountShares({
  required List<TableSessionTicket> tickets,
  required List<TableSessionReceipt> receipts,
  required List<TableSessionReceiptLine> assignments,
  required List<TableSessionDiscount> discounts,
  required int discountTotal,
}) {
  final active = {
    for (final t in tickets)
      if (t.status != 'voided') t.ticketId: t,
  };
  final out = {for (final id in active.keys) id: (direct: 0, shared: 0)};
  final receiptDiscount = receipts.fold<int>(
    0,
    (sum, r) => sum + r.discountAmount,
  );
  if (discountTotal == 0 && receiptDiscount == 0) return out;
  if (discountTotal < 0 ||
      receiptDiscount != discountTotal ||
      receipts.isEmpty) {
    return null;
  }
  // ponytail: one unreliable receipt makes the visit's item split unavailable;
  // retain receipt totals, add partial allocation only if history needs it.
  if (receipts.any((r) => r.mode != 'itemized')) return null;
  final receiptIds = receipts.map((r) => r.receiptId).toSet();
  final units = <String, Map<String, int>>{};
  final assigned = <String, int>{};
  for (final a in assignments) {
    if (!receiptIds.contains(a.receiptId) || a.qtyUnits <= 0) return null;
    if (!active.containsKey(a.ticketId)) {
      if (tickets.any(
        (t) => t.ticketId == a.ticketId && t.status == 'voided',
      )) {
        continue;
      }
      return null;
    }
    final byTicket = units.putIfAbsent(a.receiptId, () => {});
    byTicket[a.ticketId] = (byTicket[a.ticketId] ?? 0) + a.qtyUnits;
    assigned[a.ticketId] = (assigned[a.ticketId] ?? 0) + a.qtyUnits;
  }
  if (active.values.any(
    (t) => t.price < 0 || t.qty <= 0 || assigned[t.ticketId] != t.qty,
  )) {
    return null;
  }
  for (final r in receipts) {
    final owned = units[r.receiptId] ?? const <String, int>{};
    final ids = owned.keys.toList()..sort();
    final direct = <int>[];
    final bases = <int>[];
    for (final id in ids) {
      final gross = active[id]!.price * owned[id]!;
      final stack = discounts
          .where((d) => d.receiptId == r.receiptId && d.ticketId == id)
          .fold<int>(0, (sum, d) => sum + d.amount);
      if (stack < 0) return null;
      final deduction = stack.clamp(0, gross);
      direct.add(deduction);
      bases.add(gross - deduction);
    }
    final directTotal = direct.fold<int>(0, (a, b) => a + b);
    final base = bases.fold<int>(0, (a, b) => a + b);
    final sharedTotal = r.discountAmount - directTotal;
    if (base != r.subtotal || sharedTotal < 0 || sharedTotal > base) {
      return null;
    }
    final shares = distributeFixed(bases, sharedTotal);
    for (var i = 0; i < ids.length; i++) {
      // The shared rounding helper puts the remainder on the largest base.
      // Refuse a pathological tiny-base split rather than report a negative line.
      if (shares[i] > bases[i]) return null;
      final previous = out[ids[i]]!;
      out[ids[i]] = (
        direct: previous.direct + direct[i],
        shared: previous.shared + shares[i],
      );
    }
  }
  return out;
}
