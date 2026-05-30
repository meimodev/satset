import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';

class KitchenCard {
  final String tableId;
  final List<Ticket> tickets;
  const KitchenCard(this.tableId, this.tickets);
  int get done => tickets.where((t) => t.status == TicketStatus.cooked).length;
}

class KitchenScreenState {
  final List<KitchenCard> cards;
  const KitchenScreenState(this.cards);
}

/// Groups active kitchen-station tickets by sentAt batch for the KDS.
class KitchenViewModel extends StateNotifier<KitchenScreenState> {
  KitchenViewModel(this.ref) : super(const KitchenScreenState([])) {
    _recompute(ref.read(ticketsProvider));
    ref.listen(ticketsProvider, (_, n) => _recompute(n));
  }
  final Ref ref;

  // KDS surfaces every cookable batch. The server creates fresh tickets
  // as `sent` (or `held` for paced courses), so `acknowledged` never
  // appears here — see `/orders` in tickets_routes.dart.
  static const _active = {
    TicketStatus.sent,
    TicketStatus.prep,
    TicketStatus.cooked,
  };

  void _recompute(Map<String, List<Ticket>> by) {
    final cards = <KitchenCard>[];
    by.forEach((tableId, list) {
      final active = list.where((t) => _active.contains(t.status)).toList();
      if (active.isEmpty) return;
      cards.add(KitchenCard(tableId, active));
    });
    state = KitchenScreenState(cards);
  }

  /// Walks a single kitchen line through the server transition graph:
  /// `sent → prep → cooked → ready`. Each item is promoted to `ready` the
  /// moment the cook marks it done, independent of the rest of its batch, so
  /// the waiter can serve finished items without waiting for the whole order.
  /// All steps go through [AdvanceTicketStatusUseCase] so server, repository,
  /// and KDS stay in lock-step.
  Future<void> toggleCooked(String tableId, String ticketId) async {
    final useCase = ref.read(advanceTicketStatusUseCaseProvider);
    final current = ref
        .read(ticketsProvider.notifier)
        .findTicket(tableId, ticketId);
    if (current == null) return;
    if (current.status == TicketStatus.ready ||
        current.status == TicketStatus.served) {
      return;
    }
    if (current.status == TicketStatus.sent) {
      await useCase.call(tableId, ticketId, TicketStatus.prep);
    }
    if (current.status != TicketStatus.cooked) {
      await useCase.call(tableId, ticketId, TicketStatus.cooked);
    }
    await useCase.call(tableId, ticketId, TicketStatus.ready);
  }
}

final kitchenViewModelProvider =
    StateNotifierProvider.autoDispose<KitchenViewModel, KitchenScreenState>(
        (ref) => KitchenViewModel(ref));

/// New-order count for the Antrian nav badge: number of `(table, sentAt)`
/// batches that still hold at least one untouched (`sent`) item — the cook's
/// "unstarted orders" inbox. A batch drops off once every item has been
/// started (`prep`/`cooked`) or finished. See CONTEXT.md › Batch.
final kitchenNewOrderCountProvider = Provider<int>((ref) {
  final by = ref.watch(ticketsProvider);
  var count = 0;
  by.forEach((_, list) {
    final newBatches = <String>{};
    for (final t in list) {
      if (t.status == TicketStatus.sent) newBatches.add(t.sentAt);
    }
    count += newBatches.length;
  });
  return count;
});
