# ADR-0098 — A tab is a payment method, not a write-off

Status: accepted
Date: 2026-08-11

Fifth act of the ledger story [ADR-0088](0088-the-petty-cash-box-cannot-go-negative.md),
[ADR-0089](0089-petty-cash-is-not-revenue.md) and
[ADR-0095](0095-points-earn-at-bill-close-and-never-expire.md) told. Widens the
definition of a [[Payment (manual confirmation)]]; changes no revenue figure.

## Context

A regular eats, and pays at the end of the month. The venue already knows who
they are — they are a [[Pelanggan (member)]] — and already trusts them, because
that trust is the whole reason the membership feature exists. Today the app has
no way to record it.

A [[Bill (tab)]] closes exactly two ways
([ADR-0024](0024-visit-decoupled-from-table-and-bill-close.md)): fully settled, or written
off as *tak tertagih* with the outstanding recorded as `lossAmount`. Neither
fits. Pushing a tab through the write-off path is wrong three separate times: it
books a loss against money the venue fully expects to collect, it suppresses the
member's points earn (which is gated on `loss <= 0`, ADR-0095), and it leaves
nothing behind to settle against when the guest comes back with cash.

The obvious alternative — leave the visit open and settle it for real later — is
not available and it is worth writing down why, because it is the first idea
everyone has. There is no `bills` table; **a visit *is* the bill**, and
`snapshotVisitAndDelete` hard-deletes it at close. A visit that never closes is
a bill whose discounts stay editable indefinitely, whose revenue never reaches
`table_sessions` (so tonight is understated and some future night is inflated),
and which sits on the cashier's active list forever. The architecture that makes
a closed bill immutable is the same architecture that forbids an eternal one.

That leaves the question of where the unpaid claim goes once the bill has
closed. It cannot stay on the receipt, because the receipt is snapshotted and
frozen. It has to move onto the member.

### The uncomfortable part

Making this work means a `payments` row carrying `method: 'piutang'`, and
`CONTEXT.md` defined a Payment as *"a cashier-recorded attestation that money
changed hands"*. A tab attests the opposite. It would also flip the receipt to
`paid` when nobody paid anything.

That is a genuine contradiction and it deserved a straight answer rather than a
quiet edit. Two ways out:

**Add a second bill-close mode** — `performBillClose(onAccount: true)` beside
the existing `writeOff: true`. Payments stay purely about money. The cost is a
new column on `visits` *and* on `table_sessions`, a relaxed `not_settled` guard,
a second close path to keep in step with the first forever, no way to split a
bill part-cash part-tab, and Piutang invisible in the payment mix — the one
place a cashier would look to see how much went out on trust tonight.

**Widen the definition of a Payment.** A Payment attests that the receipt's
claim was **discharged** — by money, or by transfer to the member's Piutang.

The second is not a euphemism for the first, and the tell is that the table was
never really about cash arriving. A **refund** is already stored as a *negative*
payment. `payments` has always been a table of money *events* against a
receipt's claim, not a table of money received. And `paid` already means
precisely "this receipt no longer claims anything" — which, when the claim has
moved to a member's ledger, is exactly true.

## Decision

`piutang` becomes a sixth payment method. A payment carrying it discharges the
receipt's claim and, in the same transaction, writes a `charge` row into a new
per-member **[[Piutang]]** ledger. Everything downstream — auto-close, the
ADR-0068 freeze, the snapshot, the payment mix — works untouched, because
nothing downstream ever cared where the money came from.

The `Payment` definition in `CONTEXT.md` is amended to say *discharged* rather
than *money changed hands*.

Four rules follow, and each exists because its absence destroys something:

**A charge cannot exceed the member's credit limit.** Per-member, falling back
to a venue-wide default, both shipping at `0` — so enabling the feature grants
nobody a tab until an owner deliberately trusts a named person. The limit is
the only thing standing between "we do tabs" and an unbounded receivable, and
it is checked at payment time *and* shown on the till from the moment the member
is attached to the bill. Discovering "over limit" after the guest has eaten is
not a control, it is an ambush.

**The ledger has five kinds, not three.** `charge`, `payment`, `reversal`
(automatic, when a receipt is reopened), `writeOff` (gave up collecting) and
`adjust` (a hand correction, mandatory note, gated `refund`).

`adjust` looks redundant until you follow the snapshot. Once
`snapshotVisitAndDelete` runs there is no visit and no receipt, so there is
nothing to reopen and `reversal` is unreachable. Without `adjust`, a cashier who
fat-fingers an amount can only fix it with a `writeOff` — and then the bad-debt
figure, the single number an owner reads to decide whether to keep extending
credit at all, is a mix of real losses and typos. It is the same reason
[[Poin]] carries both `adjust` and `reversal`.

**A member who owes money cannot be deleted.** `DELETE /members/<id>` returns
`409 has_outstanding_debt` while the balance is non-zero. ADR-0092 already holds
that a delete anonymises rather than erases, and never erases money; extending
the existing hard-delete of the points ledger to the debt ledger would destroy a
receivable and leave no record of its size. Collect it or write it off first —
both are one route away — and the delete then carries a zero balance and is
harmless. The point is to force the owner to say *which* it was, instead of
burying a financial decision inside a delete button. A **merge** needs no such
guard: repointing the ledger folds the balance in, exactly as it does for
points.

**A collection is not revenue, but a bad debt is a loss.** The revenue was
booked at bill close and stays booked; `settledTotal` keeps the frozen meaning
ADR-0039 gave it. Collections read through their own **Piutang** section, the
arrangement ADR-0089 built for Kas kecil.

But the isolation stops there, and this is a deliberate departure from ADR-0089
rather than an oversight. A petty-cash top-up genuinely is not income. A bad
debt genuinely *is* a loss, against revenue this app already recognised. So the
Sales section carries one read-only **Piutang tak tertagih** line sourced from
the Piutang section's `writtenOff`. No figure is recomputed and nothing is
netted — a reader who is shown the sale is also shown that it evaporated.

## Consequences

Tonight's payment mix gains a `Piutang` row, which is the honest picture: the
drawer should hold the cash total, and the difference went out on trust.

A cash collection lands in the drawer but appears only in the Piutang section,
not in the payment mix of the day it arrives — a shift reconciliation is
`payment-mix tunai + Piutang collected (tunai)`. This is the same one-subtraction
cost ADR-0089 accepted, paid by the reader who wants the combined number. If it
proves annoying, the fix is a line on shift close, not a change here.

A bill can be split part-cash part-tab for free, because a tab is just a payment
with an amount and a receipt has always accepted several.

A bill still belongs to **one** member (`visits.member_id`), so a table cannot
be split across two guests' tabs. That assumption is load-bearing across points,
the ADR-0094 discount source slot and the frozen snapshot, and this ADR does not
disturb it.

Refunding *by* piutang is refused. The refund route validates against the same
method set, so adding the method would otherwise have silently legalised a
negative piutang payment with no ledger counterpart — an error that would have
been found in production rather than in review.

Nothing here needs a new [[Capability]]. Charging and collecting are
`settleBill`, because both happen at the till mid-transaction; writing off and
adjusting are `refund`, the capability that already means *a manager is
accepting that money is gone*; setting a credit limit is `manageMembers`. Every
act mapped onto an authority that already existed, which is what spares every
already-seeded venue a role backfill.
