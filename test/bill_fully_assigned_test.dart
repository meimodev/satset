import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/use_cases/bill_math.dart';

/// `isFullyAssigned` decides whether a bill can be settled AND — since
/// ADR-0069 — whether it **closes itself**. Two decisions on one predicate, on
/// the money path, so it is pinned rather than trusted.
///
/// The cases that matter are the ones where the two readings disagree: a bill
/// holding an amount receipt (which owns no units) and a bill holding an
/// itemized one (which owns no money claim beyond its lines).
void main() {
  group('isFullyAssigned', () {
    test('a bill with no receipts is never fully assigned', () {
      // Nobody has claimed anything, whatever the arithmetic says. Without this
      // guard a zero-total bill would report itself covered and auto-close.
      expect(
        isFullyAssigned(
          hasReceipts: false,
          allUnitsAssigned: true,
          receiptsClaim: 0,
          billTotal: 0,
        ),
        isFalse,
      );
      expect(
        isFullyAssigned(
          hasReceipts: false,
          allUnitsAssigned: false,
          receiptsClaim: 999999,
          billTotal: 100000,
        ),
        isFalse,
      );
    });

    test('purely itemized: the unit reading carries it', () {
      // Every unit placed. `splitItemized` targets the bill total once this is
      // true, so the money reading agrees — but the unit reading is what
      // answers first, and must, because receipt totals are recomputed.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: true,
          receiptsClaim: 116550,
          billTotal: 116550,
        ),
        isTrue,
      );
    });

    test('itemized with units still loose is not covered', () {
      // Half the table assigned. This is the state that must NOT auto-close:
      // one guest has paid, the rest of the food is unclaimed.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 50000,
          billTotal: 116550,
        ),
        isFalse,
      );
    });

    test('an amount receipt covers money, not units', () {
      // Bagi rata: no unit is assigned to anything, and the bill is still
      // fully covered. The pre-ADR-0068 unit-only reading got this wrong.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 116550,
          billTotal: 116550,
        ),
        isTrue,
      );
    });

    test('mixed: an itemized receipt plus shares of the remainder', () {
      // One guest paid for his own steak (itemized, 40k of a 116,550 bill) and
      // the rest went bagi rata. Units are not all assigned; the money is.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 40000 + 76550,
          billTotal: 116550,
        ),
        isTrue,
      );
    });

    test('mixed but short of the total is not covered', () {
      // The split was taken before every line landed — a drink arrived after.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 100000,
          billTotal: 116550,
        ),
        isFalse,
      );
    });

    test('over-claiming still counts as covered', () {
      // Rounding up per head (ADR-0068) can leave the shares summing slightly
      // over. Covered is covered — `outstanding` is computed bill-level and
      // clamps, so an over-claim cannot invent money.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 116600,
          billTotal: 116550,
        ),
        isTrue,
      );
    });

    test('a zero-total bill with a receipt is covered', () {
      // Everything on the bill was voided but a receipt exists. It has nothing
      // to collect, so it is settled — not stuck open forever.
      expect(
        isFullyAssigned(
          hasReceipts: true,
          allUnitsAssigned: false,
          receiptsClaim: 0,
          billTotal: 0,
        ),
        isTrue,
      );
    });
  });
}
