import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/bill_dto.dart';

/// A refund hands back money, so it is capped by money actually taken — never
/// by the receipt's paid total, which a `piutang` payment inflates without a
/// rupiah moving (ADR-0098). The server enforces the same sum on
/// `POST /settlement/receipts/<id>/refund`; this locks the client's copy, which
/// is what greys the button and prefills the amount.
void main() {
  BillPayment pay(String method, int amount, {bool isRefund = false}) =>
      BillPayment(
        id: 'p-$method-$amount',
        method: method,
        amount: amount,
        isRefund: isRefund,
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

  test('a tab-settled receipt has nothing to refund', () {
    final r = receipt([pay('piutang', 100000)]);
    expect(r.paidNet, 100000);
    expect(r.refundable, 0);
  });

  test('part cash, part tab refunds only the cash', () {
    expect(
      receipt([pay('tunai', 40000), pay('piutang', 60000)]).refundable,
      40000,
    );
  });

  test('an earlier refund nets out of the cap', () {
    final r = receipt([
      pay('tunai', 100000),
      pay('tunai', -30000, isRefund: true),
    ]);
    expect(r.refundable, 70000);
  });

  test('the cap never goes negative', () {
    expect(receipt([pay('tunai', -10000, isRefund: true)]).refundable, 0);
  });
}
