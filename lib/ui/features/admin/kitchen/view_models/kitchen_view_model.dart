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
  /// `sent → prep → cooked`. When the whole batch is `cooked`, each item
  /// is promoted `cooked → ready`. All steps go through
  /// [AdvanceTicketStatusUseCase] so server, repository, and KDS stay in
  /// lock-step.
  Future<void> toggleCooked(String tableId, String ticketId) async {
    final useCase = ref.read(advanceTicketStatusUseCaseProvider);
    final current = ref
        .read(ticketsProvider.notifier)
        .findTicket(tableId, ticketId);
    if (current == null) return;
    if (current.status == TicketStatus.cooked) return;
    if (current.status == TicketStatus.sent) {
      await useCase.call(tableId, ticketId, TicketStatus.prep);
    }
    await useCase.call(tableId, ticketId, TicketStatus.cooked);

    final list = ref.read(ticketsProvider)[tableId] ?? const <Ticket>[];
    final sentAt = current.sentAt;
    bool inBatch(Ticket t) =>
        t.station == current.station && t.sentAt == sentAt;
    bool active(Ticket t) =>
        t.status == TicketStatus.sent ||
        t.status == TicketStatus.prep ||
        t.status == TicketStatus.cooked;
    final batch = list.where((t) => inBatch(t) && active(t)).toList();
    if (batch.isNotEmpty &&
        batch.every((t) => t.status == TicketStatus.cooked)) {
      for (final t in batch) {
        await useCase.call(tableId, t.id, TicketStatus.ready);
      }
    }
  }
}

final kitchenViewModelProvider =
    StateNotifierProvider.autoDispose<KitchenViewModel, KitchenScreenState>(
        (ref) => KitchenViewModel(ref));
