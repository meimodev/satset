import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_transitions.dart';

class IllegalTicketTransition implements Exception {
  final TicketStatus from;
  final TicketStatus to;
  const IllegalTicketTransition(this.from, this.to);
  @override
  String toString() => 'IllegalTicketTransition($from -> $to)';
}

/// Enforces the canonical waiter/KDS transition graph — the one in
/// [ticketTransitions], shared with the server route that re-checks it — and
/// delegates the
/// persisted move to [TicketsRepository.transition] which posts to
/// `/tickets/:id/transition`. All UI ticket mutations go through this so
/// server and clients converge.
class AdvanceTicketStatusUseCase {
  AdvanceTicketStatusUseCase(this._tickets);
  final TicketsRepository _tickets;

  /// Returns **true when the move was queued rather than delivered** — only a
  /// void can be, and only on a terputus handset (ADR-0090). The caller must
  /// say so: a queued void means the kitchen has not heard it yet.
  Future<bool> call(
    String tableId,
    String ticketId,
    TicketStatus to, {
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? actorId,
  }) async {
    final current = _tickets.findTicket(tableId, ticketId);
    if (current == null) {
      throw StateError('ticket not found: $ticketId');
    }
    if (!canTransition(current.status, to)) {
      throw IllegalTicketTransition(current.status, to);
    }
    return _tickets.transition(
      tableId,
      ticketId,
      to,
      voidReason: voidReason,
      voidReasonCode: voidReasonCode,
      voidApprovedBy: voidApprovedBy,
      actorId: actorId,
    );
  }
}

final advanceTicketStatusUseCaseProvider = Provider<AdvanceTicketStatusUseCase>(
  (ref) {
    return AdvanceTicketStatusUseCase(ref.watch(ticketsProvider.notifier));
  },
);
