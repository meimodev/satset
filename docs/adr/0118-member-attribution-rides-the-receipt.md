# ADR-0118 — Member attribution rides the receipt

Status: accepted
Date: 2026-08-29

Amends [ADR-0094](0094-a-bill-discount-has-a-source.md) (the order-scope
uniqueness index gains a source), [ADR-0095](0095-points-earn-at-bill-close-and-never-expire.md)
(earn is once per *receipt*, not once per bill, when the mode is on) and
[ADR-0068](0068-an-even-receipt-is-an-amount-receipt.md) (an amount receipt may
now carry a declared member, though still no letter). Reads
[ADR-0107](0107-a-module-is-an-entitlement-beside-the-plan.md) and
[ADR-0109](0109-counter-mode-is-a-preset-of-switches-and-its-key-fails-closed.md)
for how the key is shaped; does not change
[ADR-0067](0067-billing-mode-is-per-payment.md) or
[ADR-0092](0092-a-member-is-a-phone-number.md).

## Context

A [[Pelanggan (member)]] attaches to the [[Visit]]. One bill, one member: the
[[Poin]] earn fires once at [[Bill close (Tutup tagihan)|bill close]], the
member tier discount and a [[Tukar poin (redeem)|redemption]] each hold a
bill-scope slot keyed on `visits.member_id`, and every member figure in Reports
reads the single `table_sessions.member_id` frozen at snapshot.

That model is correct for the case it was written for and wrong for the case
venues actually have: four regulars eat together, split the bill, and three of
them are members. Today exactly one of them can be recognised. The other two
pay their own share, earn nothing, and their standing discount is unreachable —
the cashier's only move is to close four separate bills, which loses the table,
the [[Split bill]] and the turn-time in one go.

The [[Split bill]] machinery already answers a neighbouring question well.
`Receipts` + `ReceiptLines` divide a bill by **who pays**, at qty grain, and a
bill may hold itemized and [[Amount receipt|amount]] receipts at once
(ADR-0067). What was missing was **who it is for**.

Three shapes were on the table.

**A member per ticket line** (`tickets.member_id`). The finest grain, and the
one the request arrived as. It creates a *second* splitting axis beside the
receipt, free to disagree with it: a line attributed to Budi can sit on a
receipt Ani is paying, and every downstream question — which member's discount
reduces which receipt's total, what a struk prints, what the points base is —
has to reconcile two independent partitions of the same bill. It also needs its
own qty-level join table to be as expressive as `ReceiptLines` already is.

**A member per receipt** (`receipts.member_id`). Reuses the existing partition
whole. Splitting the bill *is* splitting the attribution, so the two can never
disagree, and every number a receipt needs — `total`, `serviceAmount`,
`taxAmount` — is already computed and stored on it. The cost is that one guest
paying for everyone collapses to one attributee: the payer.

**Neither — one member per bill, as today.** Rejected: it is the problem.

## Decision

**Attribution rides the receipt.** `receipts.member_id` names the
[[Pemilik struk]] — the member this receipt is *for*.

Six rules follow, and they are the whole of it.

**1. The visit keeps its member, as owner and as default.**
`visits.member_id` is unchanged and still means the [[Pemilik tagihan]]. It
holds the party's identity on the floor, fills an empty `guestName`, rides the
[[Reservation]] link, and prints in the bill struk header. Money on no receipt
belongs to the owner: a bill nobody split has no receipts at all until payment,
so **the unclaimed remainder earns to the bill owner**. A venue that never
splits therefore behaves exactly as it does today, byte for byte.

**2. The points base is the receipt's own money.**
`receipt.total − receipt.serviceAmount − receipt.taxAmount` — the same formula
ADR-0095 applies to a bill, evaluated one level down. No allocation, no
apportionment, no rounding rule: a receipt already carries all three figures
because ADR-0038 computes service and tax per receipt. Earn still fires **once,
at bill close**, and a write-off still earns nothing; what changes is that a
close now writes one `member_points` row per attributed receipt plus one for
the owner's remainder, where it used to write one.

**3. An amount receipt may carry a member.**
This is the point of the feature — "split it evenly, two of us are members" is
the common case and it mints nothing but amount receipts. It does **not**
overturn ADR-0068's rule that an amount receipt has no [[Receipt letter]] and
no per-guest identity, because those two facts are different in kind: **a
letter is *derived* (from the lines the receipt owns, which an even share has
none of); a member is *declared*, by a cashier, about a person standing at the
till.** The old rule forbids *inferring* an identity a share does not have.
Declaring one is a different act, and the instant it happens the two shares
stop being interchangeable — which is why an attributed share prints its
member's name where an unattributed one prints `Bagian 1/3`. Its claim stays
frozen at minting (ADR-0068), which serves the guest here too: the points match
the number they were quoted.

**4. The member's give-backs move down to receipt scope.**
With the mode on, the tier discount and a redemption are applied against the
[[Pemilik struk]]'s **own receipt**, not the bill. Attaching a member to the
*visit* stops auto-applying a bill-scope `member` discount, because the owner
is now just another receipt's member and a bill-scope slot would discount them
twice. `redeemMin` consequently gates each member separately — four guests may
redeem four times the floor on one bill, which is correct: they are four
balances.

This requires the ADR-0094 move one level down. `idx_discounts_order_uniq` is
today on `receipt_id` **alone** — one order discount per receipt, whatever its
source — so a cashier's manual promo and a member discount cannot coexist on
one receipt. It widens to `(receipt_id, source)`, for the reason ADR-0094 gives
verbatim: three authorities, one slot, and making them exclusive is the version
the guest experiences as being punished for membership.

**5. Attribution freezes when the receipt does.**
A receipt is frozen at its first payment (ADR-0068), and its member freezes
with it. Earn genuinely does not mint until close, so leaving attribution
editable until then was available and is rejected: the member's *discount* is
money already collected under that name, and letting the name change while the
money does not is how the struk and the ledger come to disagree. One gate for
everything on a receipt. Correcting a paid receipt's member goes through the
existing, audited receipt reopen.

**6. Reports keep counting bills, and gain a finer figure.**
`memberBills` / `guestBills` keep counting **bills**, keyed on the owner, so
every saved comparison still means what it meant. The per-member rollup that
feeds the ranked list moves to receipt grain, which is what makes a
part-member, part-guest bill representable at all. Turning the mode off
**freezes and never deletes** (the ADR-0107 rule): stored attributions stay,
the picker vanishes, earn falls back to owner-only, and a window that was
attributed keeps reporting as attributed — a closed month's numbers must not
change because someone unticked a box today.

### The key

`memberSplit`, a **mode** key in `venueModeKeys` (and `MODE_MODULES` in
`functions/index.js`, the list it must stay equal to). It fails **closed**
through `venueHasMode`, not open through `venueHasModule`, and is composed once
into `MemberConfig.splitEnabled` alongside the `members` module and the owner's
own `membersEnabled` — so no route asks about modules for itself, the rule
`server/modules.dart` already states.

Fail-closed is the whole reason it is a mode and not a sellable module. The
fail-open in `venueHasModule` protects a feature a venue *paid for* from a cold
boot; applied here it would render a per-receipt member picker at a venue that
never mirrored, and the failure mode of a wrongly-offered picker is
**mis-attributed rows in a points ledger that never expires**. A missing button
is recoverable in one tick. A wrong ledger row is a reversal and a conversation.

Like both existing mode keys it stays **out of the trial grant**
(`functions/index.js` gives a trial `[...MODULES]`), so an operator ticks it to
demo it.

### Persistence

`receipts.member_id`, `table_session_receipts.member_id`, and a new
`table_session_receipt_lines` snapshot mirroring `ReceiptLines`
(`session_id, receipt_id, ticket_id, qty_units`). The snapshot table is the
awkward one and it is not optional: nothing today records which lines sat on
which receipt after close, and [[Stempel]] counts a member's punch items by
joining sessions to tickets. Flattening the link onto `table_session_tickets`
instead would have been one nullable column pair, but it loses the qty split —
a `qty:3` punch item divided 2+1 between two members would credit one of them
for all three, silently and unnoticeably. Punch is a counting path; it gets the
faithful mirror.

`member_id` on both receipt tables is a **weak reference**, like
`visits.member_id`: a deleted member leaves it dangling on purpose (ADR-0092),
because the receipt *was* theirs and history does not rewrite.

## Consequences

`reverseEarnForVisit` reverses exactly one row today (`_earnRowFor` is
singular). A visit now holds N earn rows, so it must reverse all of them — a
reopen that reverses one keeps three of four guests paid, and nothing would
surface it.

Settlement has no offline path (`SendIntentKind` is `seatTable | submitOrder |
voidTicket`), so attribution is online-only by construction; no new intent, and
[[Antrean kirim]] is untouched. The guest plane is likewise untouched: the
[[Stempel]] count remains the only member fact that crosses it (ADR-0110).

A report spanning the moment the mode was flipped shows two shapes. That is
honest and it is marked, rather than smoothed over by recomputing history.

The [[Split bill]] gains a fourth question at the till — who each share is for
— and it gets its own step rather than being folded into the existing member
panel, which stays the bill owner's surface.
