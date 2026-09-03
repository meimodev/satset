// A line holds one [[Diskon (discount)]] row per source since ADR-0126 — a
// [[Pemilik tiket]]'s tier and the cashier's promo stack — so `recomputeBill`
// has to clamp the *stack* against the line's own base. Clamping row by row is
// how 10% + 100% takes 110% of a dish and drives the receipt negative.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/bill_recompute.dart';

const _noAddOns = TaxServiceConfig(
  taxEnabled: false,
  taxRateBps: 0,
  serviceEnabled: false,
  serviceMode: 'percent',
  serviceRateBps: 0,
  serviceFixedAmount: 0,
  taxAfterDiscount: true,
);

RcResult _run(List<RcDiscount> discounts) => recomputeBill(
  // One dish, Rp 20.000, wholly claimed by receipt `r1`.
  lines: const [RcLine(ticketId: 'tk1', unitPrice: 20000, qty: 1)],
  receipts: const [RcReceipt(id: 'r1', mode: 'itemized')],
  assigns: const [RcAssign(receiptId: 'r1', ticketId: 'tk1', qtyUnits: 1)],
  discounts: discounts,
  paidByReceipt: const {},
  cfg: _noAddOns,
);

void main() {
  test('a tier and a manual promo stack on one line', () {
    final out = _run(const [
      RcDiscount(
        id: 'd-member',
        receiptId: 'r1',
        ticketId: 'tk1',
        kind: 'percent',
        value: 1000, // 10%
      ),
      RcDiscount(
        id: 'd-manual',
        receiptId: 'r1',
        ticketId: 'tk1',
        kind: 'fixed',
        value: 5000,
      ),
    ]);

    // 20.000 − 2.000 − 5.000. Neither row locks the other out.
    expect(out.receipts['r1']!.subtotal, 13000);
    expect(out.discountAmounts['d-member'], 2000);
    expect(out.discountAmounts['d-manual'], 5000);
  });

  test('the stack is clamped to the line, so a receipt cannot go negative', () {
    final out = _run(const [
      RcDiscount(
        id: 'd-member',
        receiptId: 'r1',
        ticketId: 'tk1',
        kind: 'percent',
        value: 1000, // 10%
      ),
      RcDiscount(
        id: 'd-manual',
        receiptId: 'r1',
        ticketId: 'tk1',
        kind: 'fixed',
        value: 30000, // more than the dish is worth on its own
      ),
    ]);

    // Together they promise 32.000 against a 20.000 dish. The receipt lands at
    // zero, never below it.
    expect(out.receipts['r1']!.subtotal, 0);
    expect(out.receipts['r1']!.total, 0);
    // The rows stay honest about what each promised — the clamp is on the
    // stack, not reconciled back into the rows.
    expect(out.discountAmounts['d-member'], 2000);
    expect(out.discountAmounts['d-manual'], 20000);
  });

  test('a line discount is still priced on the units this receipt owns', () {
    final out = recomputeBill(
      lines: const [RcLine(ticketId: 'tk1', unitPrice: 20000, qty: 3)],
      receipts: const [RcReceipt(id: 'r1', mode: 'itemized')],
      // Only one of the three units is on this receipt.
      assigns: const [RcAssign(receiptId: 'r1', ticketId: 'tk1', qtyUnits: 1)],
      discounts: const [
        RcDiscount(
          id: 'd1',
          receiptId: 'r1',
          ticketId: 'tk1',
          kind: 'percent',
          value: 5000, // 50%
        ),
      ],
      paidByReceipt: const {},
      cfg: _noAddOns,
    );

    expect(out.receipts['r1']!.subtotal, 10000);
    expect(out.discountAmounts['d1'], 10000);
  });
}
