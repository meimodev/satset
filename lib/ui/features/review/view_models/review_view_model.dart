import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> submit(String tableId, List<CartItem> cart) async {
    state = const ReviewState(busy: true);
    try {
      final res = await ref
          .read(submitOrderUseCaseProvider)
          .call(tableId: tableId, cart: cart);
      state = ReviewState(busy: false, submittedTicketIds: res.ticketIds);
    } catch (e) {
      state = ReviewState(busy: false, error: e.toString());
    }
  }
}

final reviewViewModelProvider =
    StateNotifierProvider.autoDispose<ReviewViewModel, ReviewState>(
        (ref) => ReviewViewModel(ref));
