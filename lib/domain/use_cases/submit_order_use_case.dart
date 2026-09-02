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
    String? actorId,
  }) async {
    if (cart.isEmpty) {
      throw ArgumentError('cart is empty');
    }
    final ids = await _tickets.submitOrder(
      tableId: tableId,
      idempotencyKey: const Uuid().v4(),
      lines: _lines(cart),
      actorId: actorId,
    );
    return SubmittedOrder(ids);
  }

  /// Submit (or append to) a table-less takeaway (Bawa pulang) order. Returns
  /// the created ticket ids + the takeaway visit id. See ADR-0026.
  Future<({List<String> ticketIds, String visitId})> takeaway({
    required List<CartItem> cart,
    String guestName = '',
    String channel = 'bungkus',
    bool prepaid = false,
    String? existingVisitId,
    String? actorId,
  }) async {
    if (cart.isEmpty) {
      throw ArgumentError('cart is empty');
    }
    return _tickets.submitTakeawayOrder(
      idempotencyKey: const Uuid().v4(),
      lines: _lines(cart),
      guestName: guestName,
      channel: channel,
      prepaid: prepaid,
      existingVisitId: existingVisitId,
      actorId: actorId,
    );
  }

  List<CartLineDto> _lines(List<CartItem> cart) => [
    for (final c in cart)
      CartLineDto(
        itemId: c.itemId,
        name: c.name,
        variantId: c.variantId,
        variantName: c.variantName,
        memberId: c.memberId,
        modifiers: [
          for (final m in c.selectedModifiers)
            CartModifierDto(
              groupId: m.groupId,
              optionId: m.optionId,
              label: m.label,
              priceDelta: m.priceDelta,
            ),
        ],
        note: c.note.isEmpty ? null : c.note,
        course: _courseKey(c.course),
        qty: c.qty,
        unitPrice: c.unitPrice,
      ),
  ];
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
