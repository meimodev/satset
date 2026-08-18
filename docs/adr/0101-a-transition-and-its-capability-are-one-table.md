# ADR-0101 — A transition and its capability are one table

Status: accepted
Date: 2026-08-18

## Context

A ticket's life is a small state machine — draft, sent, held, prep, cooked,
ready, served, voided — and every move along it costs a capability. Who may
mark a dish served is not the same as who may put a course back on hold, and
neither is the same as who may void something the guest has already eaten
([ADR-0006](0006-self-served-void-with-per-waiter-accountability.md)).

Until now that was three structures:

1. `_allowedTransitions` in `lib/server/routes/tickets_routes.dart` — a
   `Map<TicketStatus, Set<TicketStatus>>` saying which moves are legal.
2. `_requiredCap` in the same file — a chain of `if`s returning the capability
   a move costs, ending in `return null`.
3. `AdvanceTicketStatusUseCase._allowed` — a byte-for-byte copy of (1) on the
   client, so the UI can grey out a move rather than watch it 409.

Structure (2) is the problem. `return null` at the end of a capability lookup
means "this move is free", and it is reached by every legal move nobody wrote
an arm for. Four were: `draft → sent`, `acknowledged → prep`, `sent → cooked`
and `sent → held`. Each was a legal, reachable move that any paired device
could make with no capability at all — including `draft → sent`, which is the
act of putting an order into the kitchen.

Nothing about (1) and (2) makes them notice each other. A move added to the
graph is legal the moment it is written; it becomes *gated* only if somebody
also remembers a second edit in a second structure, and the failure mode of
forgetting is silent and open.

## Decision

**One table: `ticketTransitions` in `lib/domain/models/ticket_transitions.dart`,
of type `Map<TicketStatus, Map<TicketStatus, Capability>>`.** A key's presence
makes the move legal; its value is what the move costs. Both facts are one
entry, so adding a move *is* naming its capability — there is no second place
to forget and no arm to fall through.

**It lives in `domain/`, and both sides import it.** The server route checks it
to decide legality and to gate; the client use case checks the same constant to
decide what to offer. The copy is gone, so the two cannot drift.

**The client's copy is still not a security boundary.** The server re-checks
every move against the same table, because a client is a thing an attacker
controls. Sharing the table removes a drift bug, not a trust boundary.

**A missing entry means illegal, not free.** `capabilityForTransition` returns
null only for a move the graph does not have, and the route rejects that with
409 before any capability question is asked. The null that used to mean
"allowed, ungated" no longer exists.

## Considered options

**Keep two structures, add the four missing arms.** The small fix, and it would
have closed today's hole. Rejected: it leaves the shape that produced the hole
intact, and the fifth missing arm gets written the same way as the first four.

**Make `_requiredCap` exhaustive with a `switch` over pairs.** Dart's analyzer
cannot check exhaustiveness over a pair of enums, so this buys the appearance of
a compiler guarantee without the guarantee.

**Derive the capability from the destination status alone.** Tempting —
`prep`/`cooked`/`ready` look like the kitchen's, `served` like the waiter's —
but it is wrong at both ends: `voided` costs `voidItem` or `compItem` depending
where you came *from*, and `sent` is reached both by a waiter sending a draft
and by a waiter firing a held course. The origin carries meaning.

**Generate the client graph from the server at runtime.** Rejected: it makes an
offline client's UI depend on a fetch, in an app whose premise is that it works
when the network does not.

## Consequences

Four transitions are now gated that were not, which is a behaviour change on an
already-deployed venue: a role holding neither `takeOrder` nor `viewKds` could
previously drive those moves and now gets a 403. Every seeded role holds the
capability its own work needs, so this bites only a hand-edited role — and the
role sheet is where it is fixed.

The transition graph is now a domain constant rather than a server detail,
which is where the other shared vocabularies (`Capability`, `TicketStatus`)
already live.
