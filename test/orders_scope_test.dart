import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/features/orders/view_models/orders_scope.dart';

/// Ownership rule for the Pesanan board (ADR-0056). The board scopes by
/// *table handler*, with line authorship as a fallback, so these cases are the
/// ones that decide whether a waiter's food disappears mid-shift.
void main() {
  group('ownsOrderRow', () {
    test('the table handler owns the line, whoever typed it', () {
      // A sent the drinks, B now handles the table: the row is B's.
      expect(
        ownsOrderRow(meId: 'b', createdBy: 'a', tableActorId: 'b'),
        isTrue,
      );
    });

    test('the author keeps the line after the table moves on', () {
      // A's outstanding food stays on A's board even once B took the table.
      expect(
        ownsOrderRow(meId: 'a', createdBy: 'a', tableActorId: 'b'),
        isTrue,
      );
    });

    test("someone else's line on someone else's table is not mine", () {
      expect(
        ownsOrderRow(meId: 'c', createdBy: 'a', tableActorId: 'b'),
        isFalse,
      );
    });

    test('a takeaway line (no table) belongs to its author', () {
      expect(
        ownsOrderRow(meId: 'a', createdBy: 'a', tableActorId: null),
        isTrue,
      );
      expect(
        ownsOrderRow(meId: 'b', createdBy: 'a', tableActorId: null),
        isFalse,
      );
    });

    test('an approved guest line belongs to whoever seated the visit', () {
      // Guest lines carry no createdBy — guest_routes never stamps one.
      expect(
        ownsOrderRow(meId: 'a', createdBy: null, tableActorId: 'a'),
        isTrue,
      );
      expect(
        ownsOrderRow(meId: 'b', createdBy: null, tableActorId: 'a'),
        isFalse,
      );
    });

    test('an unowned line shows to everyone rather than to no one', () {
      expect(
        ownsOrderRow(meId: 'a', createdBy: null, tableActorId: null),
        isTrue,
      );
      expect(
        ownsOrderRow(meId: 'b', createdBy: null, tableActorId: null),
        isTrue,
      );
    });

    test('no signed-in user degrades to the old venue-wide board', () {
      expect(
        ownsOrderRow(meId: null, createdBy: 'a', tableActorId: 'b'),
        isTrue,
      );
      expect(ownsOrderRow(meId: '', createdBy: 'a', tableActorId: 'b'), isTrue);
    });
  });
}
