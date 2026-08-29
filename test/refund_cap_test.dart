import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/bill_dto.dart';

/// A refund names the **leg** it unwinds, so the cap is per leg and not per
/// struk (ADR-0121). A `piutang` leg counts: it hands nothing back from the
/// drawer — the refund writes a [[Piutang]] reversal — which is ADR-0098's rule
/// kept by inheriting the method rather than by hiding the leg. The server
/// enforces the same sum on `POST /settlement/receipts/<id>/refund`; this locks
/// the client's copy, which is what fills the picker and prefills the amount.
void main() {
  BillPayment pay(
    String id,
    String method,
    int amount, {
    bool isRefund = false,
    String? unwinds,
  }) => BillPayment(
    id: id,
    method: method,
    amount: amount,
    isRefund: isRefund,
    refundsPaymentId: unwinds,
    tendered: null,
    note: null,
    at: DateTime(2026, 8, 12),
    hasPhoto: false,
  );

  BillReceipt receipt(List<BillPayment> payments) => BillReceipt(
    id: 'r1',
    mode: 'itemized',
    label: 'A',
    subtotal: 100000,
    discountAmount: 0,
    serviceAmount: 0,
    taxAmount: 0,
    total: 100000,
    memberId: null,
    member: null,
    status: 'paid',
    paidNet: payments.fold(0, (a, p) => a + p.amount),
    lines: const [],
    payments: payments,
    discounts: const [],
  );

  test('a tab leg is refundable — it unwinds as a reversal', () {
    final r = receipt([pay('p1', 'piutang', 100000)]);
    expect(r.paidNet, 100000);
    expect(r.refundable, 100000);
    expect(r.refundableLegs.map((p) => p.id), ['p1']);
  });

  test('part cash, part tab offers both legs, each capped on its own', () {
    final r = receipt([
      pay('p1', 'tunai', 40000),
      pay('p2', 'piutang', 60000),
    ]);
    expect(r.refundableLegs.map((p) => p.id), ['p1', 'p2']);
    expect(r.refundableOf(r.payments[0]), 40000);
    expect(r.refundableOf(r.payments[1]), 60000);
    expect(r.refundable, 100000);
  });

  test('an earlier refund nets out of its own leg, not the other', () {
    final r = receipt([
      pay('p1', 'tunai', 60000),
      pay('p2', 'tunai', 40000),
      pay('p3', 'tunai', -30000, isRefund: true, unwinds: 'p1'),
    ]);
    expect(r.refundableOf(r.payments[0]), 30000);
    expect(r.refundableOf(r.payments[1]), 40000);
    expect(r.refundable, 70000);
  });

  test('a fully refunded leg drops out of the picker', () {
    final r = receipt([
      pay('p1', 'tunai', 50000),
      pay('p2', 'tunai', -50000, isRefund: true, unwinds: 'p1'),
    ]);
    expect(r.refundableOf(r.payments[0]), 0);
    expect(r.refundableLegs, isEmpty);
    expect(r.refundable, 0);
  });

  test('a refund row is never itself a refundable leg', () {
    final r = receipt([pay('p1', 'tunai', -10000, isRefund: true)]);
    expect(r.refundableLegs, isEmpty);
    expect(r.refundable, 0);
  });
}
