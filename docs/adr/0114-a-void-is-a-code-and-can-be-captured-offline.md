# ADR-0114 — A void is a code, and it can be captured offline

Status: accepted
Date: 2026-08-28

Amends [ADR-0006](0006-self-served-void-with-per-waiter-accountability.md) and
extends [ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md).

## Context

Two separate faults met on the same screen, and between them the [[Void (item)]]
action was unusable for four of the five reasons the picker offers.

**The reason contract had drifted apart.** ADR-0006 made the server enforce
`voidReason` **and** `voidReasonCode` non-empty on a void, because the manager
PIN was gone and UI-only enforcement was no longer sufficient. At the time the
client satisfied that by sending the reason's **label** as the free text.
ADR-0085 then established that a code crosses a layer and a sentence never does
— the label was whichever language the waiter's handset happened to be in,
frozen into the row — so the client stopped sending it and began sending `''`
for every fixed reason. The server's guard was never revisited. From that
commit on, `wrongOrder`, `customerChange`, `outOfStock`, `kitchenError` and
`comp` all answered `400 reason_required`; only `other`, which carries typed
text, still worked. No test in the suite ever posted a void without free text.

**Nothing said so.** `_commitVoid` awaited the use case with no `try`, so the
400 became an unhandled future: the step never advanced, the sheet sat on the
reason list, and the waiter was left tapping a button that had stopped
responding. The same silence swallowed a `403` (a role without `voidItem`, or a
served line needing `compItem`), a `409` from a line the KDS had moved
underneath, and every transport failure.

And a void was the one correction a waiter could not make in the corner of the
terrace where the Wi-Fi dies. ADR-0090 gave `submitOrder` and `seat` an
[[Antrean kirim]]; a void threw. The guest changes their mind in exactly the
place the signal does not reach.

## Decision

### The code is the invariant; the sentence is not

`POST /tickets/<id>/transition` to `voided` requires a non-empty
`voidReasonCode`. It requires non-empty `voidReason` **only** when that code is
`other` — the one code that says nothing on its own. Every other code composes
its own words at read time (ADR-0085), and the audit writer already falls back
to the code's canonical label when the text is empty, so nothing downstream
loses a word.

This supersedes ADR-0006's consequence bullet reading "Server enforces
`voidReason` + `voidReasonCode` non-null".

### A refusal is answered in the sheet that caused it

The sheet gains a fourth step. It resolves the exception to a **code** —
`forbidden`, `forbidden_comp`, `illegal_transition`, `reason_required`,
`send_queue_full` — and `voidFailureText` composes the sentence, like every
other code that crosses the layer. Inline rather than a snackbar behind a
dismissed sheet: the waiter is standing in the thing that refused them, and half
of these are recoverable by picking a different reason.

The sheet, not the host, splits the two `403` flavours. The host answers a bare
`forbidden` for both; only the caller knows the line was already served, which
is the difference between "your role cannot do this" and "this one needs a
manager" — and a waiter told the wrong one either stops trying or goes looking
for the wrong person.

The void row is now **disabled with its reason**, not hidden and not offered
blind: `capabilityForTransition(status, voided)` already names what this
particular void costs (ADR-0101), so the client can say which of the two gates
is shut. The client gate decides what to *offer*; the server still decides what
is allowed.

### A void is offline-capable; nothing else on the graph is

`SendIntentKind.voidTicket`, replayed through the ordinary transition route.
Four things follow, and each of them is the decision rather than the plumbing:

- **Only a void.** Every other move on the graph is a kitchen fact. A queued
  `prep` would replay minutes after the dish left the pass, telling the room
  something that stopped being true.
- **A refused void must not stall the food.** The drain stalls the whole backlog
  on 401/403, because a bearer that cannot carry it must never be worked around.
  A void is the exception: `served → voided` costs `compItem`, which a waiter may
  simply not hold, and that is a business refusal about one line. Stalling on it
  strands every order queued behind a comp the venue was never going to allow.
  401 still stalls either way, and a 403 on an order still stalls.
- **`void-<ticketId>` is the intent id**, which makes the dedupe free — four taps
  on a dead socket leave one intent and one answer. There is no idempotency key
  on the transition route and there should not be: `voided` is terminal with no
  outgoing edge, so a replay of one the host already took comes back `409
  illegal_transition`. The 409 *is* the idempotency.
- **The waiter who voided is named in the body.** A drain runs under whoever is
  signed in when the socket returns. Without `actorId`, one waiter's backlog
  lands under the next one's name — in the per-waiter void rate that is ADR-0006's
  entire deterrent. A live void sends no `actorId` and still takes the bearer.

### A stranded void is louder than a stranded order

A queued void expires at the business day boundary like everything else, and the
drain report says so **naming the line** — which is why the intent carries the
line's name and qty even though it is about to tell the host that line is gone.
The asymmetry is the point: a stranded order never happened, but a stranded void
leaves a line that is still live and still on the guest's bill. Letting a void
outlive the day instead would be worse — the bill it belongs to is snapshotted
and immutable after close (ADR-0068), so the replay would fail anyway, later and
further from anyone who could act.

## Consequences

- The confirmation view carries a **queued** variant. It is not a cosmetic
  difference: the kitchen has not heard the void and may still plate the dish,
  and only the waiter standing there can go and say so.
- The local optimistic write marks the line terminal on this handset, so
  **Selesaikan Layanan** offers itself while the host still sees the line live.
  The server holds — `409 tickets_not_terminal` — and that code now resolves to
  a sentence on the table screen instead of the raw exception body.
- `TicketsRepository.transition` and `AdvanceTicketStatusUseCase.call` return
  `Future<bool>`: true when captured rather than delivered. A caller that
  ignores it silently claims the kitchen was told.
- `test/void_ticket_test.dart` pins the reason contract in both directions and
  the replay attribution. The first of its cases fails against the code this ADR
  replaces, which is the case that should have existed all along.
