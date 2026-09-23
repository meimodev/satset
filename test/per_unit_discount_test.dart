import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/bill_recompute.dart';
import 'package:satset/ui/features/cashier/widgets/settle_pane.dart';

const cfg = TaxServiceConfig(
  taxEnabled: false,
  taxRateBps: 0,
  serviceEnabled: false,
  serviceMode: 'percent',
  serviceRateBps: 0,
  serviceFixedAmount: 0,
);

RcResult price({
  String? receiptId,
  int value = 5000,
  int first = 1,
  int second = 2,
}) => recomputeBill(
  lines: const [RcLine(ticketId: 'coffee', unitPrice: 20000, qty: 3)],
  receipts: const [
    RcReceipt(id: 'a', mode: 'itemized'),
    RcReceipt(id: 'b', mode: 'itemized'),
  ],
  assigns: [
    RcAssign(receiptId: 'a', ticketId: 'coffee', qtyUnits: first),
    RcAssign(receiptId: 'b', ticketId: 'coffee', qtyUnits: second),
  ],
  discounts: [
    RcDiscount(
      id: 'promo',
      receiptId: receiptId,
      ticketId: 'coffee',
      kind: 'fixed',
      value: value,
    ),
  ],
  paidByReceipt: const {},
  cfg: cfg,
);

void main() {
  test('per-unit preset follows split units and unassigned units', () {
    final split = price();
    expect(split.discountAmounts['promo'], 15000);
    expect(split.receiptDiscountAmounts['a']!['promo'], 5000);
    expect(split.receiptDiscountAmounts['b']!['promo'], 10000);
    expect(split.receipts['a']!.total, 15000);
    expect(split.receipts['b']!.total, 30000);
    expect(split.billTotal, 45000);
    expect(price(first: 2, second: 1).billTotal, 45000);
    expect(price(first: 0, second: 0).billTotal, 45000);
  });

  test('fixed discounts cap each unit and preserve legacy applications', () {
    expect(price(value: 25000).billTotal, 0);
    final legacy = price(receiptId: 'a', first: 3, second: 0);
    expect(legacy.billTotal, 55000);
    expect(legacy.discountAmounts['promo'], 5000);
  });

  test(
    'pending preview recalculates fixed and percent presets with quantity',
    () {
      const fixed = PendingLineDiscount(
        presetId: 'p',
        label: 'Promo',
        amount: 15000,
        kind: 'fixed',
        value: 5000,
        approverPin: null,
      );
      expect(fixed.amountFor(20000, 3), 15000);
      expect(fixed.amountFor(20000, 2), 10000);
      expect(fixed.amountFor(2000, 2), 4000);
      const percent = PendingLineDiscount(
        presetId: 'p',
        label: 'Promo',
        amount: 6000,
        kind: 'percent',
        value: 1000,
        approverPin: null,
      );
      expect(percent.amountFor(20000, 2), 4000);
    },
  );
}
