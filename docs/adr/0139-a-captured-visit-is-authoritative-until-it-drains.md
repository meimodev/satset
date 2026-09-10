# A captured visit is authoritative until it drains

**Status:** Accepted — 2026-09-08 — **amends** [0090](0090-an-offline-order-is-an-intent-not-a-row.md) and [0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md).

**Clarified by [ADR-0140](0140-missing-bill-history-is-not-an-empty-bill.md):** an adopted visit with missing earlier bill history continues to capture orders, but cannot take payment or close until that history is recovered. A stale cached bill remains usable.

**Clarified by [ADR-0141](0141-a-refused-visit-stays-read-only-until-resolved.md):** an explicit host refusal makes the affected visit read-only until resolution; transport interruption alone does not.

ADR-0090 drew a line through the middle of a [[Visit]]: an offline order is an
**intent**, never a row, and — in as many words — *"a bill must not be able to
reach it."* ADR-0123 then moved money to the other side of that line: a
[[Cashier|kasir]] captures settlement into a journal, reads it back, and the
[[Visit]] stays [[Kunjungan otoritatif-lokal|local-authoritative]] until the
chain drains.

The result was a device that could take an order dark and settle a bill dark,
but could not do both to the *same* [[Visit]]. A waiter keys three plates on a
handset with no socket; the same handset opens `/kasir` and the [[Bill (tab)]]
is short by three plates, with no error and no badge. The kasir settles it. The
guest pays for two plates and eats five.

This ADR takes the line out. A device may own a [[Visit]] **end to end** while
dark — seat it, order onto it, void from it, settle it, print it — and the host
learns the whole thing at drain. That visit is a **[[Kunjungan tertangkap]]**.

0090's two load-bearing sentences are overturned by name, and both are
overturned by their own reasoning rather than in spite of it. See §Amendments.

## Context

The failure is not a slip. Every piece behaves exactly as designed, and the
design has a hole in the middle of it.

`submitOrder` on a dark client parks a `SendIntent` in the [[Antrean kirim]] —
a prefs JSON blob — and returns `const []`. **No row is written anywhere on the
device.** The bill, meanwhile, is a different mechanism entirely: a cached
`/settlement/visits/<id>/bill` snapshot with the [[Antrean setelmen]]'s events
projected onto it. Two backlogs, no bridge, and `projectBill` has never heard
of an order.

So the bill renders, cleanly, missing the captured lines — and it *settles*.
There is no refusal to notice, no empty state, no thrown error. The money is
simply less than the food. ADR-0090 anticipated a cousin of this and accepted
it: *"A kasir can still settle a bill while lines sit on a dark handset.
Nothing can prevent that — the device is unreachable by definition."* That is
true of a **second** device and false of this one. Here the queue is on the
same handset as the bill; it is not unreachable, it is unread.

Three forces pushed the answer past "show a warning".

**The venue shape most likely to be dark is the one with one device.** A
[[Kedai]] running `menuHome` has no floor, one handset, and — often — a phone
hotspot. For that venue, "the cashier should walk toward the router" is not a
degradation, it is a stop. ADR-0090's takeaway refusal was written when money
could not be captured at all; ADR-0123 removed that premise and nobody
revisited the refusal.

**The client already prices dine-in orders.** `POST /orders` takes `unitPrice`
straight off the wire for staff orders — only the guest plane reprices
server-side (ADR-0105). So a captured line's money needs no new trust
relationship; it needs the bill to look at it.

**ADR-0123 already minted ids on the client** — receipt, payment, discount,
refund — and ADR-0129 already taught the host to accept a client-minted id
when the request carries a `capturedAt`. A visit and a ticket are the same kind
of object one level up. The mechanism exists; it had simply never been pointed
at the floor.

Against all of that stood one real objection, and it is the reason this ADR is
long: **an order is not money.** Money captured offline is a fact about the
past — the cash is in the drawer, and the host's only job is to record it. An
order captured offline is a *claim about the world* the host may want to refuse:
there is no stock, the capability was revoked, the table changed guests. 0090's
"the host always wins" exists for that, and it is right — right up until the
guest has eaten the food and paid for it, at which point refusing is arguing
with the past. The whole of §Decision is about where that switch flips.

## Decision

A **[[Kunjungan tertangkap]]** is a [[Visit]] this device minted, or adopted,
while it could not reach the host, and which it owns until its chain drains.
The client may seat it, order onto it, void from it, apply a
[[Diskon (discount)]], take payment, close it and print it. **One store, one
chain, one drain order.**

### 1. One store. The [[Antrean kirim]] is deleted.

Order and seat events move into the [[Antrean setelmen]] alongside money, in
the client database (ADR-0124). So do `voidTicket` and `tableExpense`. The
prefs blob and `SendQueue` go away entirely.

0090 named this exit condition itself: *"The queue is a prefs blob because a
shift's backlog is tens of intents. If it ever needs querying rather than
draining, that is the moment for Drift on the client, and not before."* A bill
that must reach its captured lines queries it, per visit, on every render. That
moment has arrived.

The alternative — keep both stores and bridge them — fails on **ordering**, not
on effort. The seat must land before the order, the order before the void, the
void before the payment. Two backlogs with independent sequences carrying one
causal chain is a race with no single place to fix it. Merging them makes the
ordering structural instead of coordinated.

It also collapses `Kunjungan otoritatif-lokal`'s test for free. That condition
is `journal.isNotEmpty || wsConnState != open`; with orders in the journal, a
visit holding captured lines and no money is local-authoritative **without a
second predicate**. Under a bridge it would not have been, and `fetchBill`
would have cached the host's correct-but-short answer over the truth. If the
test needs widening, the merge was not done.

### 2. Ids are client-minted, and `capturedAt` is the signal.

Visit and ticket ids join receipt, payment, discount and refund: minted on the
client, **online too**, doubling as the idempotency key. The sender's standing
refusal — *"A local key must not cross the wire"* — is lifted for a request
that carries `capturedAt`, which is exactly ADR-0129's switch for an offline
enrolment: *"folding is switched on by the request carrying both `id` and
`capturedAt`, which is what an offline capture looks like."* One signal, one
precedent, no new mechanism.

Minting server-side and rewriting the local id at drain was the alternative,
and it has its own precedent (`rewriteMemberId`). It loses on the **struk**: a
receipt printed offline names a visit id, the guest walks out holding it, and
a rewrite makes that document name something that no longer exists.

### 3. A captured line is not refused for stock. It is audited.

At drain the host **does not validate stock** for a line carrying a past-dated
`capturedAt`. Stock goes negative, and [[Stok opname|opname]] reconciles it.

Stock refusal exists to stop a waiter *promising* food the kitchen does not
have. Once the guest has eaten it and paid for it, the refusal has no subject
left. The honest reading of "we sold what we did not have on the books" is a
negative figure, not a missing line — and a missing line is far worse, because
it is money collected against something that exists in no ledger at all.

Two guards keep this from becoming a hole:

- **The bypass needs a past-dated `capturedAt`**, older than a threshold
  (60s), not merely a present one. `capturedAt: now` gets ordinary
  enforcement. Without this, a buggy client — or the wrong clock on cheap
  Android hardware, which is a real failure mode and not a hypothetical —
  silently disables a venue-wide control with nobody seeing an error.
- **A bypassed line writes an audit row** naming the item and the shortfall.
  Negative stock with no explanation is a bug report; negative stock with a row
  saying *sold dark at 19:42, no stock* is a reconciliation. Opname needs that
  row to close the variance.

The same posture applies to a `403`: a captured order whose capability was
revoked mid-shift still lands. The food is eaten. Authorship is recorded as it
always is (ADR-0056), and the venue takes it up with the human.

### 4. A captured price stands, and writes no row.

The line carries the price the cached menu held when the waiter keyed it. If
the owner edits the menu during the outage, the host books the **captured**
price at drain — which is today's behaviour for staff orders and needs no
server change.

Repricing at drain was the alternative and is disqualified by the drawer: it
makes the day's cash not foot, in order to correct a discrepancy that harmed
nobody and that a printed receipt already settles. Deliberately **no audit
row** here, unlike §3 — a price change is the owner's own act with its own
trail, and a row on every line of every captured bill after any price edit is
noise that trains people to ignore audit rows.

### 5. A drained ticket is minted at `ready`. Always.

Not `sent`, because the food is history and a 40-minute-old ticket landing on a
hot line is noise at best and a duplicate dish at worst. Not `served`, because
ADR-0115 already reasoned that one out: `served → voided` costs `compItem` and
`ready → voided` costs `voidItem`, so a ticket born `served` needs a manager to
correct a mis-key in the one-person shop that has none. `ready` is also simply
true — the food was ready; nobody is claiming a [[KDS / Antrian Persiapan|KDS]]
saw it.

This mints at a status rather than walking `ticketTransitions`, and that is
deliberate. The graph gates **moves** (ADR-0101); a drain is not a person
taking an action, it is a replay of one already taken. Replaying four
transitions to reach a status already known would be more code and more audit
rows for no additional truth.

**A captured visit still unsettled at drain is a different case**: its lines go
to the host as ordinary `sent` orders and reach the KDS, because that food
genuinely still needs cooking. The bill's own state is the discriminator.

### 6. A void never collapses.

A line captured dark and voided dark sends **both** events. The host records
the order and the void, with its `voidReasonCode`.

Annihilating them in the journal is cheaper and reads as obviously correct —
the kitchen never saw the food and the guest was never billed. It is refused
anyway, because a void is the venue's fraud control. ADR-0006 and ADR-0114 make
it reasoned, capability-gated and audited precisely because *"the line was
removed before anyone saw it"* is the shape of theft. Collapsing would make the
one device nobody can observe the one device where add-then-remove leaves no
trace. The cost is some `voided` rows for genuine mis-keys, which is what
`voidReasonCode` is for.

### 7. Collisions land loudly. Nothing is swallowed.

Two dark devices can each mint a visit for meja 7. Both land, as **two
visits**, and a human merges or voids. This is ADR-0116's posture — *"made
loud at drain, not prevented"* — one layer down from the two-islanded-tills
case it was written for. A per-table lease was reconsidered and refused on
0116's own grounds: a lease granted by a host that just vanished is not a
lease.

`tables.currentVisitId` points at one visit, so the slot is resolved
explicitly:

- A captured visit that this device **settled** never claims the slot. It is
  history; nobody is sitting there.
- A captured visit still **unsettled** yields to a live visit and lands
  **table-less**, surfaced on `/kasir` for a human to place or void. The device
  cannot know whether its guests are still at the table; landing it visible and
  unplaced is the loud-not-lossy answer.

A live visit must never lose its slot to a replay.

### 8. Expiry is chain-scoped: money in the chain, the chain survives.

`intentExpires` retired an undelivered order captured before the current
business day, and that rule was right — *an order nobody wants this morning is
right to drop*. It now applies to the **chain**, not the event: if any event in
a visit's chain is money, none of them expire. ADR-0130 drew the same line for
the [[Pengeluaran kunjungan]] (*"money already spent is not"*).

Stated per-event this would let a seat expire out from under a settled bill,
leaving a visit that was never seated.

### 9. A drain past its business day backdates, orders included.

ADR-0123 already backdates settlement from `capturedAt` and audits it as
`AuditKind.settlementArrivedLate`. Orders follow the same rule, with their own
audit kind.

Booking orders at arrival while their payments backdate would split one bill
across two business days — a payment referencing a line that is not in that
day's revenue, and a closed day that does not foot. An owner reconciling a day
that moved needs to see why, hence the kind.

### 10. Only the manager step-up stays online-only.

ADR-0123 held back two acts; ADR-0129 released member lookup. This releases the
rest, including [[Piutang]], which 0123 fenced off. Cash, non-cash, print,
split, assign, reopen, discount, points and debt all capture.

Non-cash needs saying explicitly: the payment method is a string on a row, and
the terminal is a separate physical device the app has never spoken to. There
was never a technical dependency there.

The **step-up stands**, on ADR-0099's grounds unchanged: a PIN hash is the
host's, and caching one on a shared handset buys convenience with a security
regression.

**Debt gets a local ceiling.** The credit limit is enforced in a transaction
that re-reads `SUM(delta)`, with a comment that describes offline exactly:
*"two tills… could each read a balance that clears the limit and both land,
which is how a credit limit stops being one."* Offline that is not a race, it
is the guaranteed case. So the till checks the limit against the
[[Salinan pelanggan]]'s last-known balance before capturing. Multi-device
overage remains possible and lands as an over-limit member on the Piutang
report; the ordinary single-device case stays enforced. A control that
evaporates under the exact condition it matters most is not a control.

### 11. The struk prints provisional points.

Earning is server-side at bill close and cannot run until drain. A guest paying
dark gets the figure plus a word saying it posts when the till reconnects.
Their real question is *did my visit count*, and the answer is yes; the number
is a courtesy that must not become a claim to walk back. Redemption is
unaffected — it was always projected client-side as a fixed give-back.

### 12. A shift will not close while this device holds undrained money.

A blocking sheet, naming the count. This is the one place in the design that
refuses rather than captures, and it is deliberate: everything else says
*capture now, reconcile later* because the alternative is losing the
transaction. A shift close has no urgency and a human standing at the machine.
Allowing it means a shift's reported total changes after somebody signed off on
the drawer count — which is precisely the artifact an owner uses to detect
theft.

### 13. Dine-in and takeaway. Not guest self-order.

A captured takeaway visit is the *easier* half — no seat, no table, no
`currentVisitId` contest — and it serves the venue shape with the worst
network. 0090's takeaway refusal does not survive its own reasoning: it existed
because money could not be captured, and ADR-0123 removed that.

Guest self-order is out by physics. The guest plane is a cleartext socket on
the host (ADR-0105); a device that cannot reach the host cannot serve it.

### 14. No gate.

Not a [[Modul]], not a mode key, not a settings boolean.

A mode key fails closed (ADR-0109), which would disable this on the venue that
never phoned home — the venue that needs it most. ADR-0129 reached for a plain
boolean rather than a mode key for that exact reason. This goes one step
further: a mirror is a data-sharing choice an owner may legitimately decline,
but *can this till keep working when the wifi drops* is not a preference. It is
the app's stated promise. A switch here only ever gets found by someone turning
it off by mistake.

## Amendments

**ADR-0090**, two sentences:

- *"A pesanan tertunda is rendered from the queue, never faked into the ticket
  map: it is not a ticket, the kitchen has never seen it, and a bill must not be
  able to reach it."* — **overturned.** A captured line has a client-minted
  ticket id, it is billable and settleable, and the guest pays for it. It
  renders as an ordinary line, badged, on the bill, on table detail and on
  `/orders`; the separate "pesanan tertunda" block is retired. Keeping two
  visual vocabularies for one object means every screen needs an answer to
  *which kind is this*, and the badge already carries the only fact that still
  differs — the host has not seen it.
- *"The queue is a prefs blob… If it ever needs querying rather than draining,
  that is the moment for Drift on the client."* — **triggered**, per §1.

0090's takeaway refusal is lifted (§13). Its *"the host always wins"* stands
everywhere except stock and capability on an already-settled visit (§3), which
is not the host losing an argument but the host being told what happened.

**ADR-0123**, one bullet: its member-lookup fence was already lifted by
ADR-0129; its **debt** fence is lifted here with a local ceiling (§10). Its
one-money-function rule (`recomputeBill` pure, both sides call it) is
**untouched and load-bearing** — captured lines enter as synthesized
`BillLine`s and the projection may still never compute money.

## Consequences

A device can now sell food, take cash and close a bill the host has never heard
of. That is the point, and it is worth stating plainly.

Stock can go negative, and an owner will see it. The audit row (§3) is what
turns that from a defect report into a reconciliation, so it is not optional
polish — it is the thing that makes §3 survivable.

Two visits on one table is a row a human has to resolve. It is rare, it is
visible, and it is strictly better than a swallowed visit.

`test/settlement_offline_parity_test.dart` extends to order events: one
sequence through the routes, one through the projection, compared. That test is
now the guard on considerably more surface than money.

The client database gains a version. The prefs queue is imported once on first
boot and the key deleted — a device updating mid-shift with a backlog must not
lose it, and there is no way to gate an install on a drained queue (ADR-0130:
Android never reports an install back). The 200-event cap survives as a smoke
alarm with its original justification gone: 200 undelivered events means
something is broken, not that a shift was busy.

## Alternatives considered

**Warn only.** A banner on the bill naming the captured lines, settlement stays
legal. Leaves the money loss intact and asks the cashier to do arithmetic
during a rush.

**Block settlement while this device holds captured lines.** The smallest fix
that removes the loss, and it was the initial recommendation. Refused because
it makes the single-handset venue stop working, which is the venue this whole
offline story exists for.

**Show captured lines without counting them.** The worst of both: the cashier
sees food they cannot charge for.

**Keep two stores, bridge them for the bill.** Refused on ordering (§1).

**Server-minted ids with a rewrite pass at drain.** Refused on the struk (§2).

**Collapse a captured order with its captured void.** Refused on fraud (§6).

**A per-table lease to prevent visit collisions.** Refused on ADR-0116's own
grounds (§7).

**Gate the whole thing behind a mode key.** Refused (§14) — it would fail
closed on the venue that needs it.
