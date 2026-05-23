import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';

class SubmittedOrder {
  final List<String> ticketIds;
  const SubmittedOrder(this.ticketIds);
}

/// Validates cart, generates an idempotency key, and forwards to the tickets
/// repository which speaks to `/orders`. Returns the created ticket ids so
/// callers can navigate to the "sent" screen.
class SubmitOrderUseCase {
  SubmitOrderUseCase(this._tickets);
  final TicketsRepository _tickets;

  Future<SubmittedOrder> call({
    required String tableId,
    required List<CartItem> cart,
  }) async {
    if (cart.isEmpty) {
      throw ArgumentError('cart is empty');
    }
    final lines = [
      for (final c in cart)
        CartLineDto(
          itemId: c.itemId,
          variantId: c.variantId,
          modifierOptionIds:
              c.modifierIds.values.expand((v) => v is List ? v.cast<String>() : <String>[]).toList(),
          specialInstructions: c.special.isEmpty ? null : c.special,
          course: c.course.name,
          qty: c.qty,
          unitPrice: c.unitPrice,
        ),
    ];
    final ids = await _tickets.submitOrder(
      tableId: tableId,
      idempotencyKey: const Uuid().v4(),
      lines: lines,
    );
    return SubmittedOrder(ids);
  }
}

final submitOrderUseCaseProvider = Provider<SubmitOrderUseCase>((ref) {
  return SubmitOrderUseCase(ref.watch(ticketsProvider.notifier));
});

// CourseId enum support
extension on CourseId {
  String get name => switch (this) {
        CourseId.drinksNow => 'drinks-now',
        CourseId.starters => 'starters',
        CourseId.mains => 'mains',
        CourseId.sides => 'sides',
        CourseId.desserts => 'desserts',
        CourseId.fireNow => 'fire-now',
      };
}
