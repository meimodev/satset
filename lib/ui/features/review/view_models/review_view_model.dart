import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/use_cases/submit_order_use_case.dart';

class ReviewState {
  final bool busy;
  final String? error;
  final List<String>? submittedTicketIds;
  const ReviewState({this.busy = false, this.error, this.submittedTicketIds});
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
      state = ReviewState(busy: false, submittedTicketIds: res.ticketIds);
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
            existingVisitId: existingVisitId,
            actorId: actorId,
          );
      state = ReviewState(busy: false, submittedTicketIds: res.ticketIds);
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
