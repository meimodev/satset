import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/use_cases/bill_math.dart';

/// The invariant that matters: an even split never invents or loses money, and
/// never hands anyone a share of zero. ADR-0068.
void main() {
  group('distributeEvenRounded', () {
    test('sums to the bill total exactly', () {
      for (final total in [3000, 87334, 150000, 1, 99, 100, 250050, 1000000]) {
        for (var n = 1; n <= 12; n++) {
          final shares = distributeEvenRounded(total, n);
          expect(shares.length, n, reason: 'total=$total n=$n');
          expect(
            shares.fold<int>(0, (a, b) => a + b),
            total,
            reason: 'total=$total n=$n → $shares',
          );
        }
      }
    });

    test('no share is negative', () {
      for (final total in [3000, 87334, 150000, 100, 12345]) {
        for (var n = 1; n <= 12; n++) {
          final shares = distributeEvenRounded(total, n);
          expect(
            shares.every((s) => s >= 0),
            isTrue,
            reason: 'total=$total n=$n → $shares',
          );
        }
      }
    });

    test('the degenerate case the source gets wrong leaves nobody at zero', () {
      // Rp 3.000 across four heads. Rounding up to Rp 1.000 (the source's step)
      // and letting the last payer absorb gives [1000, 1000, 1000, 0] — head 4
      // owes nothing. Rp 100 with the surplus spread does not.
      final shares = distributeEvenRounded(3000, 4);
      expect(shares, [800, 800, 700, 700]);
      expect(shares.every((s) => s > 0), isTrue);
    });

    test(
      'earliest payers get round numbers, the last absorbs the ragged end',
      () {
        final shares = distributeEvenRounded(87334, 3);
        expect(shares.fold<int>(0, (a, b) => a + b), 87334);
        // Everyone but the last hands over a multiple of the step.
        for (final s in shares.take(shares.length - 1)) {
          expect(s % cashRoundingStep, 0, reason: '$shares');
        }
      },
    );

    test('an exact multiple splits flat', () {
      expect(distributeEvenRounded(400, 4), [100, 100, 100, 100]);
      expect(distributeEvenRounded(120000, 3), [40000, 40000, 40000]);
    });

    test('falls back to an exact split below the rounding floor', () {
      // Rp 50 across two heads: rounding to 100 could only invent money.
      expect(distributeEvenRounded(50, 2), distributeEven(50, 2));
      expect(distributeEvenRounded(50, 2).fold<int>(0, (a, b) => a + b), 50);
    });

    test('degenerate arguments', () {
      expect(distributeEvenRounded(10000, 0), isEmpty);
      expect(distributeEvenRounded(0, 3), [0, 0, 0]);
      expect(distributeEvenRounded(150000, 1), [150000]);
    });
  });
}
