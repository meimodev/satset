import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/order_dto.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/use_cases/submit_order_use_case.dart';

class ReviewState {
  final bool busy;
  final String? error;
  final List<String>? submittedTicketIds;
  final List<RejectedLineDto> rejected;
  const ReviewState({
    this.busy = false,
    this.error,
    this.submittedTicketIds,
    this.rejected = const [],
  });
}

/// Match host refusals back to local cart identities. Older hosts omit the
/// identity; retain every matching configuration rather than discard one.
List<CartItem> refusedCartLines(
  List<CartItem> cart,
  List<RejectedLineDto> rejected,
) {
  final ids = {
    for (final line in rejected)
      if (line.clientLineId != null) line.clientLineId!,
  };
  final legacy = rejected.where((line) => line.clientLineId == null);
  return [
    for (final line in cart)
      if (ids.contains(line.id) ||
          legacy.any(
            (r) => r.itemId == line.itemId && r.variantName == line.variantName,
          ))
        line,
  ];
}

/// Preserve the host's refusal with each unsent line across review routes.
List<CartItem> retainedRejectedCartLines(
  List<CartItem> cart,
  List<RejectedLineDto> rejected,
) {
  final matched = refusedCartLines(cart, rejected);
  // An older host may omit a usable identity. Keep the cart rather than
  // silently losing a line when its refusal cannot be matched.
  final remaining = matched.isEmpty && rejected.isNotEmpty ? cart : matched;
  return remaining.map((line) {
    final refusal = rejected.firstWhere(
      (r) =>
          r.clientLineId == line.id ||
          (r.clientLineId == null &&
              r.itemId == line.itemId &&
              r.variantName == line.variantName),
      orElse: () => rejected.first,
    );
    return line.copyWith(
      rejectionReason: refusal.reason,
      rejectionIngredients: refusal.ingredients,
    );
  }).toList();
}

class ReviewViewModel extends StateNotifier<ReviewState> {
  ReviewViewModel(this.ref) : super(const ReviewState());
  final Ref ref;

  Future<void> submit(
    String tableId,
    List<CartItem> cart, {
    String? actorId,
  }) async {
    SatLog.vm(
      'ReviewVM submit table=${tableId.substring(0, tableId.length.clamp(0, 6))} items=${cart.length}',
    );
    state = const ReviewState(busy: true);
    try {
      final res = await ref
          .read(submitOrderUseCaseProvider)
          .call(tableId: tableId, cart: cart, actorId: actorId);
      SatLog.vm('ReviewVM submit ok tickets=${res.ticketIds.length}');
      state = ReviewState(
        busy: false,
        submittedTicketIds: res.ticketIds,
        rejected: res.rejected,
      );
    } catch (e) {
      SatLog.vm('ReviewVM submit fail $e');
      state = ReviewState(busy: false, error: e.toString());
    }
  }

  /// Submit (or append to) a takeaway (Bawa pulang) order. Returns the takeaway
  /// visit id on success, or null on failure (error surfaced via state). See
  /// ADR-0026.
  Future<String?> submitTakeaway(
    List<CartItem> cart, {
    String guestName = '',

    /// How the order reached us, and whether an aggregator already settled it.
    /// Ignored when appending to an existing takeaway — the visit already has
    /// them. ADR-0066.
    String channel = 'bungkus',
    bool prepaid = false,
    String? existingVisitId,
    String? actorId,
  }) async {
    SatLog.vm(
      'ReviewVM submitTakeaway items=${cart.length} append=${existingVisitId != null}',
    );
    state = const ReviewState(busy: true);
    try {
      final res = await ref
          .read(submitOrderUseCaseProvider)
          .takeaway(
            cart: cart,
            guestName: guestName,
            channel: channel,
            prepaid: prepaid,
            existingVisitId: existingVisitId,
            actorId: actorId,
          );
      state = ReviewState(
        busy: false,
        submittedTicketIds: res.ticketIds,
        rejected: res.rejected,
      );
      return res.visitId;
    } catch (e) {
      SatLog.vm('ReviewVM submitTakeaway fail $e');
      state = ReviewState(busy: false, error: e.toString());
      return null;
    }
  }
}

final reviewViewModelProvider =
    StateNotifierProvider.autoDispose<ReviewViewModel, ReviewState>(
      (ref) => ReviewViewModel(ref),
    );
