import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';

class OrderRow {
  final String tableId;
  final Ticket ticket;
  const OrderRow(this.tableId, this.ticket);
}

class OrdersScreenState {
  final List<OrderRow> ready;
  final List<OrderRow> active;
  final List<OrderRow> done;
  const OrdersScreenState({
    required this.ready,
    required this.active,
    required this.done,
  });
}

/// Groups tickets across all tables for the waiter Orders screen.
class OrdersViewModel extends StateNotifier<OrdersScreenState> {
  OrdersViewModel(this.ref)
      : super(const OrdersScreenState(ready: [], active: [], done: [])) {
    _recompute(ref.read(ticketsProvider));
    ref.listen(ticketsProvider, (_, next) => _recompute(next));
  }
  final Ref ref;

  void _recompute(Map<String, List<Ticket>> by) {
    final all = <OrderRow>[];
    by.forEach((key, list) {
      for (final t in list) {
        // Map is keyed by visitId (ADR-0034); a dine-in row identifies by its
        // real tableId, a takeaway line (empty tableId) by the visit key.
        all.add(OrderRow(t.tableId.isNotEmpty ? t.tableId : key, t));
      }
    });
    state = OrdersScreenState(
      ready: all.where((r) => r.ticket.status == TicketStatus.ready).toList(),
      active: all
          .where((r) =>
              r.ticket.status == TicketStatus.draft ||
              r.ticket.status == TicketStatus.acknowledged ||
              r.ticket.status == TicketStatus.sent ||
              r.ticket.status == TicketStatus.prep ||
              r.ticket.status == TicketStatus.cooked ||
              r.ticket.status == TicketStatus.held)
          .toList(),
      done: all
          .where((r) =>
              r.ticket.status == TicketStatus.served ||
              r.ticket.status == TicketStatus.voided)
          .toList(),
    );
  }
}

final ordersViewModelProvider =
    StateNotifierProvider.autoDispose<OrdersViewModel, OrdersScreenState>(
        (ref) => OrdersViewModel(ref));
