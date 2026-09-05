# ADR-0138 — A serve is the waiter's own hand, and it queues

Status: accepted
Date: 2026-09-05

Amends [ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md) and
[ADR-0114](0114-a-void-is-a-code-and-can-be-captured-offline.md). Forced by
[ADR-0115](0115-a-venue-may-have-no-prep-queue.md).

## Context

ADR-0114 says it plainly: a void is "the **one** ticket transition with an
offline path", and the repository says why — "every other move on this graph is
a kitchen fact. A queued `prep` would replay minutes after the dish left the
pass, telling the room something that stopped being true." That reasoning is
right about `prep`, `cooked` and `ready`. Nobody checked it against `served`.

`ready → served` is not a kitchen fact. It is the waiter's own hand, recorded
on the very handset that went dark, about a plate they are holding. And
ADR-0115 made it the *only* ticket act most waiters perform: under `bypassKds`
a line is born `ready` at send, so on a venue with no prep queue the handover
tap is the entire ticket lifecycle a waiter touches.

A device run on emulator-5554 found what that costs. Offline, TANDAI DISAJIKAN
was a **silent dead button**: `TicketsRepository.transition` rethrew the
`SocketException`, `markServed` on `table_detail_screen.dart` awaited it with
no `catch`, and table detail is a root-navigator push — *above* `AppShell`,
which [ADR-0103](0103-a-transport-error-surfaces-through-the-shell.md) makes the app's only
error-bus subscriber. So the throw reached no snackbar, no disabled state, and
no queue. The tap did nothing, twice, with no trace but a log line. The same
screen's own action sheet already **hid** its serve row while offline, so one
screen shipped both postures for one act, and the honest one was hidden behind
a long-press.

Two other things were already true and made the fix cheaper than it looks: the
send queue's replay path is the ordinary route, and `served` has no outgoing
edge to itself, so a duplicate replay answers `409 illegal_transition` on its
own.

## Decision

**A serve queues, like a void.** `canQueue` in `TicketsRepository.transition`
becomes `{voided, served}`; `SendIntentKind.serveTicket` replays through the
same `/tickets/:id/transition` the online tap posts to. Four rules carry it.

**The intent never expires.** `intentExpires` drops an order at the business-day
rollover because food nobody wants this morning must not arrive tonight. A
serve is the opposite: dropping it leaves the line `ready` on the board
**forever** — no rollover clears that status, no close clears it, nothing does
but the transition itself. So it joins [[Pengeluaran kunjungan]] on the
never-expires side, from a third direction.

**It backdates its own stamp.** The route accepts an optional `capturedAt`,
**for `served` only**, and stamps `servedAt` from it. Without this the feature
poisons the metric it touches: Operasional's pickup lag is
`servedAt − readyAt`, so a 25-minute reconnect books 25 minutes of food dying
under the lamp against a waiter who served instantly. It is **clamped at both
ends**, and the lower clamp is the load-bearing one — a slow handset clock
would mint a negative lag, which `reports_routes` does not reject but silently
*discards*, so the sample vanishes rather than reading visibly wrong. Every
other stamp on that route is a fact the host observed itself and stays
unbackdatable.

**No idempotency key, keyed `serve-<ticketId>`.** The void's argument holds:
`served → served` is not on the graph, so a replay of one the host already took
returns `409 illegal_transition`, the drain records it and drops it — the 409
*is* the idempotency, and a key would be a second mechanism for one guarantee.
The id doubles as the dedupe for the failure that actually happens on a phone,
four taps on a dead socket.

**A 403 still stalls the drain.** `ready → served` costs `takeOrder`
([ADR-0101](0101-a-transition-and-its-capability-are-one-table.md)) — the same capability
the queued orders need — so a 403 here is a broken bearer, not a business
refusal about one line. It is deliberately *not* added to the `voidTicket` /
`tableExpense` exemption, whose whole point is that `compItem` and
`recordTableExpense` are grants a waiter may simply not hold.

**A line ordered offline still cannot be served offline**, and that is the
accepted boundary. A serve intent names a `ticketId`, and a ticket id is minted
by the host at drain, so the lines born in the queue are servable only once the
queue lands. Resolving `(intentId, lineIndex)` at drain time would put an
intent's target inside another intent's unminted output, which is exactly what
the intent contract forbids: "never the ticket ids, visit or stock decisions
that only the host may mint."

## Consequences

`/orders` and takeaway detail inherit the queueing the moment the repository
changed, because the rule lives in `transition` and not on a screen — a
per-screen list of who may queue is the shape ADR-0101 removed from ticket
transitions in the first place. Their `catch` blocks stop firing offline and
now speak only for a host that answered.

The action sheet's serve row comes back while terputus; **`unserve` stays
online-only**. Queueing both would make the pair reorderable in the queue for a
need nobody has — a waiter who mis-tapped offline can simply not carry the
plate.

Copy stopped interpolating the exception. `ordServeFailed` and `tkwServeFailed`
rendered `Gagal sajikan: ClientException with SocketException…` into a snackbar
a waiter reads mid-rush; both are gone, replaced by one `tktServeFailed` fed by
`serveFailureText`, a code resolver shaped like `voidFailureText` (ADR-0085).
A refused serve in the drain dialog now **names its line**, like a refused void,
for the same reason — the plate is on the table and the board still says it is
waiting at the pass.

`TableDetailViewModel` is deleted. It was watched by nothing and carried a
second, also-uncaught `markServed` — the copy a future reader would have fixed
instead of the live one.

`fireCourse` on table detail has the identical uncaught shape and stays
online-only and unqueued. Firing a course *is* a kitchen instruction, so
ADR-0090's original reasoning still applies to it; only its silence is a bug,
and it is not one this ADR fixes.

## Alternatives considered

**Leave it online-only and just show the error.** The smallest change, and it
was the recommendation until the `bypassKds` interaction surfaced. On a venue
with no prep queue it tells a waiter, correctly and repeatedly, that the one
act their job consists of is unavailable — which is a working error message
attached to a broken workflow.

**Disable the button while offline.** Honest, cheap, and consistent with
`onAdd`'s lock glyph. Still leaves the venue above with nothing to tap, and
adds a third posture (hidden in the sheet, disabled on the card, queued
everywhere else) to one act.

**Queue every transition.** Symmetrical and wrong: ADR-0090's reasoning about
`prep` is correct, and a replayed kitchen fact is worse than an unrecorded one
because the board asserts it confidently.

**Stamp `servedAt` at drain and accept the metric noise.** One less parameter
on the route. It makes the venue's own speed report read the outage as slow
service, permanently, in the one number an owner uses to judge the floor.
