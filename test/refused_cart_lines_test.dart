import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/models/order_dto.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/ui/features/review/view_models/review_view_model.dart';

CartItem _line(String id, String itemId) => CartItem(
  id: id,
  itemId: itemId,
  name: itemId,
  variantId: 'v1',
  variantName: 'Regular',
  course: CourseId.mains,
  unitPrice: 10000,
);

void main() {
  test('retains only the refused local line after partial acceptance', () {
    final cart = [_line('a', 'rice'), _line('b', 'rice'), _line('c', 'tea')];
    final remaining = refusedCartLines(cart, [
      const RejectedLineDto(itemId: 'rice', clientLineId: 'b'),
    ]);
    expect(remaining.map((line) => line.id), ['b']);
  });

  test('retained refusal keeps the host reason on the unsent line', () {
    final remaining = retainedRejectedCartLines(
      [_line('a', 'rice'), _line('b', 'tea')],
      const [
        RejectedLineDto(
          itemId: 'rice',
          clientLineId: 'a',
          reason: 'ingredients',
          ingredients: ['Beras'],
        ),
      ],
    );
    expect(remaining.map((line) => line.id), ['a']);
    expect(remaining.single.rejectionReason, 'ingredients');
    expect(remaining.single.rejectionIngredients, ['Beras']);
  });

  test('unmatched older refusal does not discard the cart', () {
    final cart = [_line('a', 'rice')];
    final remaining = retainedRejectedCartLines(cart, const [
      RejectedLineDto(itemId: 'rice', reason: 'sold_out'),
    ]);
    expect(remaining.single.id, 'a');
    expect(remaining.single.rejectionReason, 'sold_out');
  });

  test(
    'older host refusal keeps all matching lines rather than losing one',
    () {
      final cart = [_line('a', 'rice'), _line('b', 'rice'), _line('c', 'tea')];
      final remaining = refusedCartLines(cart, [
        const RejectedLineDto(itemId: 'rice', variantName: 'Regular'),
      ]);
      expect(remaining.map((line) => line.id), ['a', 'b']);
    },
  );
}
