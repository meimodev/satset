import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/ticket.dart';

/// The canonical ticket transition graph — **and** the capability each move
/// costs, in one table (ADR-0101).
///
/// A key's presence is what makes a move legal; its value is what the caller
/// must hold to make it. The two used to be separate structures — a
/// `Set<TicketStatus>` for legality on both the server and the client, and a
/// `switch` for the gate on the server — and a legal move whose arm nobody
/// wrote fell through to "no capability required". Four of them did.
///
/// Which is also why a move nobody makes does not get a row. `draft → sent`,
/// `acknowledged → prep` and `sent → held` were all legal here and written by
/// nothing: no route mints a `draft` or an `acknowledged` (see [TicketStatus]),
/// and pacing writes `held` at order time rather than walking a fired line
/// back. They were the ungated ones precisely because nobody exercised them.
/// Re-add a row the day a writer appears — with its capability, in the same
/// line.
///
/// Adding a move means adding a row here, which means naming its capability.
/// There is no arm to forget.
const ticketTransitions = <TicketStatus, Map<TicketStatus, Capability>>{
  TicketStatus.draft: {TicketStatus.voided: Capability.voidItem},
  TicketStatus.acknowledged: {TicketStatus.voided: Capability.voidItem},
  TicketStatus.sent: {
    TicketStatus.prep: Capability.viewKds,
    // The line may skip `prep` when a dish needs no staging.
    TicketStatus.cooked: Capability.viewKds,
    TicketStatus.voided: Capability.voidItem,
  },
  TicketStatus.held: {
    TicketStatus.sent: Capability.takeOrder,
    TicketStatus.voided: Capability.voidItem,
  },
  TicketStatus.prep: {
    TicketStatus.cooked: Capability.viewKds,
    TicketStatus.voided: Capability.voidItem,
  },
  TicketStatus.cooked: {
    TicketStatus.ready: Capability.viewKds,
    TicketStatus.voided: Capability.voidItem,
  },
  TicketStatus.ready: {
    TicketStatus.served: Capability.takeOrder,
    TicketStatus.voided: Capability.voidItem,
  },
  TicketStatus.served: {
    // `served → ready` is the canonical undo of a premature serve mark — no
    // local-only rewind.
    TicketStatus.ready: Capability.takeOrder,
    // Voiding something already served is a comp/refund, which is a manager
    // power rather than a waiter's own correction (ADR-0006).
    TicketStatus.voided: Capability.compItem,
  },
  TicketStatus.voided: <TicketStatus, Capability>{},
};

/// Whether [from] → [to] is a move the graph allows at all.
bool canTransition(TicketStatus from, TicketStatus to) =>
    ticketTransitions[from]?.containsKey(to) ?? false;

/// The capability [from] → [to] costs, or null when the move is illegal —
/// in which case the caller rejects it before ever asking.
Capability? capabilityForTransition(TicketStatus from, TicketStatus to) =>
    ticketTransitions[from]?[to];
