import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_item.dart';

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
    String? actorId,
  }) async {
    if (cart.isEmpty) {
      throw ArgumentError('cart is empty');
    }
    final lines = [
      for (final c in cart)
        CartLineDto(
          itemId: c.itemId,
          name: c.name,
          variantId: c.variantId,
          variantName: c.variantName,
          station: _stationKey(c.station),
          modifierOptionIds: c.modifierIds.values
              .expand((v) => v is List ? v.cast<String>() : <String>[])
              .toList(),
          specialInstructions: c.special.isEmpty ? null : c.special,
          course: _courseKey(c.course),
          qty: c.qty,
          unitPrice: c.unitPrice,
        ),
    ];
    final ids = await _tickets.submitOrder(
      tableId: tableId,
      idempotencyKey: const Uuid().v4(),
      lines: lines,
      actorId: actorId,
    );
    return SubmittedOrder(ids);
  }
}

final submitOrderUseCaseProvider = Provider<SubmitOrderUseCase>((ref) {
  return SubmitOrderUseCase(ref.watch(ticketsProvider.notifier));
});

/// Server contract is kebab-case. Cannot use enum `.name` because the
/// built-in `name` field shadows extensions, and would emit `drinksNow`.
String _courseKey(CourseId c) => switch (c) {
      CourseId.drinksNow => 'drinks-now',
      CourseId.starters => 'starters',
      CourseId.mains => 'mains',
      CourseId.sides => 'sides',
      CourseId.desserts => 'desserts',
      CourseId.fireNow => 'fire-now',
    };

String _stationKey(Station s) => switch (s) {
      Station.kitchen => 'kitchen',
      Station.bar => 'bar',
    };
