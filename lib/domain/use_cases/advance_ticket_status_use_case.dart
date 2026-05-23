import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';

class IllegalTicketTransition implements Exception {
  final TicketStatus from;
  final TicketStatus to;
  const IllegalTicketTransition(this.from, this.to);
  @override
  String toString() => 'IllegalTicketTransition($from -> $to)';
}

/// Enforces the canonical waiter/KDS transition graph and delegates the
/// persisted move to [TicketsRepository.transition] which posts to
/// `/tickets/:id/transition`. All UI ticket mutations go through this so
/// server and clients converge.
class AdvanceTicketStatusUseCase {
  AdvanceTicketStatusUseCase(this._tickets);
  final TicketsRepository _tickets;

  static final _allowed = <TicketStatus, Set<TicketStatus>>{
    TicketStatus.draft: {TicketStatus.sent, TicketStatus.voided},
    TicketStatus.acknowledged: {TicketStatus.prep, TicketStatus.voided},
    TicketStatus.sent: {
      TicketStatus.prep,
      TicketStatus.cooked,
      TicketStatus.held,
      TicketStatus.voided,
    },
    TicketStatus.held: {TicketStatus.sent, TicketStatus.voided},
    TicketStatus.prep: {TicketStatus.cooked, TicketStatus.voided},
    TicketStatus.cooked: {TicketStatus.ready, TicketStatus.voided},
    TicketStatus.ready: {TicketStatus.served, TicketStatus.voided},
    // `served → ready` mirrors the server graph so the waiter "unserve"
    // action stays on the canonical transition path.
    TicketStatus.served: {TicketStatus.ready, TicketStatus.voided},
    TicketStatus.voided: <TicketStatus>{},
  };

  bool canTransition(TicketStatus from, TicketStatus to) =>
      _allowed[from]?.contains(to) ?? false;

  Future<void> call(
    String tableId,
    String ticketId,
    TicketStatus to, {
    String? voidReason,
    String? voidApprovedBy,
  }) async {
    final current = _tickets.findTicket(tableId, ticketId);
    if (current == null) {
      throw StateError('ticket not found: $ticketId');
    }
    if (!canTransition(current.status, to)) {
      throw IllegalTicketTransition(current.status, to);
    }
    await _tickets.transition(
      tableId,
      ticketId,
      to,
      voidReason: voidReason,
      voidApprovedBy: voidApprovedBy,
    );
  }
}

final advanceTicketStatusUseCaseProvider =
    Provider<AdvanceTicketStatusUseCase>((ref) {
  return AdvanceTicketStatusUseCase(ref.watch(ticketsProvider.notifier));
});
