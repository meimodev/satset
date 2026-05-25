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
    SatLog.vm('ReviewVM submit table=${tableId.substring(0, tableId.length.clamp(0, 6))} items=${cart.length}');
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
}

final reviewViewModelProvider =
    StateNotifierProvider.autoDispose<ReviewViewModel, ReviewState>(
        (ref) => ReviewViewModel(ref));
