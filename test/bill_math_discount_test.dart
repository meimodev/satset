import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/use_cases/bill_math.dart';

/// Money path — ADR-0038. Guards the two discount pipelines, the clamps, and
/// the split-bill invariant that receipts sum to the bill total exactly.
void main() {
  const svc5tax11 = TaxServiceConfig(
    taxEnabled: true,
    taxRateBps: 1100,
    serviceEnabled: true,
    serviceMode: 'percent',
    serviceRateBps: 500,
    serviceFixedAmount: 0,
  );

  group('no discount — ADR-0023 behaviour is unchanged', () {
    test('100k → +5% service → +11% tax = 116.55k', () {
      final b = computeBreakdown(100000, svc5tax11);
      expect(b.serviceAmount, 5000);
      expect(b.taxAmount, 11550);
      expect(b.total, 116550);
      expect(b.discountAmount, 0);
    });
  });

  group('taxAfterDiscount = true (default, DPP-correct)', () {
    test('discount reduces the base both add-ons compute from', () {
      final b = computeBreakdown(100000, svc5tax11, discount: 20000);
      // base 80k → service 4k → tax on 84k = 9240
      expect(b.subtotal, 100000);
      expect(b.discountAmount, 20000);
      expect(b.serviceAmount, 4000);
      expect(b.taxAmount, 9240);
      expect(b.total, 93240);
    });

    test('discount larger than subtotal clamps to subtotal, total >= 0', () {
      final b = computeBreakdown(50000, svc5tax11, discount: 999999);
      expect(b.discountAmount, 50000);
      expect(b.serviceAmount, 0);
      expect(b.taxAmount, 0);
      expect(b.total, 0);
    });
  });

  group('taxAfterDiscount = false (gross-then-promo)', () {
    const gross = TaxServiceConfig(
      taxEnabled: true,
      taxRateBps: 1100,
      serviceEnabled: true,
      serviceMode: 'percent',
      serviceRateBps: 500,
      serviceFixedAmount: 0,
      taxAfterDiscount: false,
    );

    test('add-ons on the full subtotal, discount off the grand total', () {
      final b = computeBreakdown(100000, gross, discount: 20000);
      // service/tax identical to the undiscounted bill
      expect(b.serviceAmount, 5000);
      expect(b.taxAmount, 11550);
      expect(b.discountAmount, 20000);
      expect(b.total, 96550); // 116550 − 20000
    });

    test('the two flags genuinely differ on the same inputs', () {
      final a = computeBreakdown(100000, svc5tax11, discount: 20000);
      final b = computeBreakdown(100000, gross, discount: 20000);
      expect(a.total, isNot(b.total));
    });

    test('discount larger than the grand total clamps, total >= 0', () {
      final b = computeBreakdown(100000, gross, discount: 999999);
      expect(b.discountAmount, 116550);
      expect(b.total, 0);
    });
  });

  group('negative and zero inputs', () {
    test('negative discount is treated as zero, never as a surcharge', () {
      final b = computeBreakdown(100000, svc5tax11, discount: -5000);
      expect(b.discountAmount, 0);
      expect(b.total, 116550);
    });
  });

  group('resolveDiscountAmount', () {
    test('percent reads bps', () {
      expect(
        resolveDiscountAmount(kind: 'percent', value: 1000, base: 50000),
        5000,
      );
    });
    test('percent clamps at 100%', () {
      expect(
        resolveDiscountAmount(kind: 'percent', value: 20000, base: 50000),
        50000,
      );
    });
    test('fixed clamps to base — cannot invent money', () {
      expect(
        resolveDiscountAmount(kind: 'fixed', value: 50000, base: 25000),
        25000,
      );
    });
    test('zero base or value yields nothing', () {
      expect(resolveDiscountAmount(kind: 'percent', value: 1000, base: 0), 0);
      expect(resolveDiscountAmount(kind: 'fixed', value: 0, base: 50000), 0);
    });
  });

  group('split bill', () {
    test('per-receipt discounts apply to their own receipt', () {
      final out = splitItemized(
        [60000, 40000],
        svc5tax11,
        discounts: [6000, 0],
      );
      expect(out[0].discountAmount, 6000);
      expect(out[1].discountAmount, 0);
      // untouched receipt matches a standalone computation
      final solo = computeBreakdown(40000, svc5tax11);
      expect(out[1].total, solo.total);
    });

    test('receipts sum to billTotalTarget exactly, remainder on largest', () {
      const target = 93240;
      final out = splitItemized(
        [33333, 33333, 33334],
        svc5tax11,
        billTotalTarget: target,
        discounts: [6667, 6667, 6666],
      );
      expect(out.fold<int>(0, (a, b) => a + b.total), target);
    });

    test('remainder push preserves discountAmount', () {
      final out = splitItemized(
        [33333, 66667],
        svc5tax11,
        billTotalTarget: 100000,
        discounts: [3333, 6667],
      );
      expect(out.map((b) => b.discountAmount), [3333, 6667]);
    });

    test('a fixed whole-bill discount fans out to sum exactly', () {
      final shares = distributeFixed([60000, 40000], 25000);
      expect(shares.fold<int>(0, (a, b) => a + b), 25000);
      expect(shares, [15000, 10000]);
    });
  });
}
