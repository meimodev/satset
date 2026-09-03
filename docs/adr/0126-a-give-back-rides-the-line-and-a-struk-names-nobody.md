# ADR-0126 — A give-back rides the line, and a struk names nobody

Status: accepted
Date: 2026-09-03

Retires the **Siapa** step of [ADR-0118](0118-member-attribution-rides-the-receipt.md)
and [ADR-0120](0120-a-tab-follows-the-struk.md), whose live half
[ADR-0125](0125-member-attribution-rides-the-ticket.md) had already replaced.
Amends ADR-0125's line-discount clause into something the code actually holds,
and its `piutang` clause with a suggestion. Keeps
[ADR-0067](0067-billing-mode-is-per-payment.md)'s mint-at-confirm rule, which is
what makes the rest of this possible, and
[ADR-0037](0037-cashier-applies-preset-discounts.md)'s freeze-at-payment rule.

## Context

**Per item** had grown a two-step confirm. The cashier tapped a guest's lines,
hit `Tinjau struk`, and the pane minted an unpaid receipt and opened its sheet —
because a line [[Diskon (discount)]] is a `discounts` row with a `receipt_id`,
and until a receipt existed there was nowhere to hang one. The payment then
happened a screen away, in a sheet the cashier had to know to look inside.

That is a detour built around a schema fact, not around the till. It also
contradicted ADR-0067 twice over: a mode the cashier tried and abandoned now
left an orphan unpaid receipt claiming lines, and the *one gesture* the mode
exists for had become two.

Beside it sat the **Siapa** step. Under ADR-0118 a receipt could name a
[[Pemilik struk]] — a member labelling that share — and the pane offered the
picker whenever a split appeared. ADR-0125 then moved loyalty attribution down
onto the Ticket, where a chip on each line names its [[Pemilik tiket]]. Both
gestures survived, side by side, both asking a cashier "whose is this" and
meaning different things: one decided who ate the dish and earned for it, the
other decided whose name printed on a slip and nothing else. The picker's own
gate had drifted too — `_canName` never checked the attribution version, so the
Siapa row rendered on the settle pane of every venue holding `memberSplit`,
including the ones already answering the question on the line above.

The third thread is the line discount itself. ADR-0125 said line rows stack one
slot per source; `idx_discounts_line_uniq` agreed; the route did not — its
`discount_exists` check queried `(receipt_id, ticket_id)` across every source
and refused. So a member's automatic tier locked the cashier's promo out of the
same dish, and the UI grew a `lockedByAutomaticDiscount` state to explain the
refusal. A guest was punished for holding a membership. Worse, that check used
`getSingleOrNull`: the day two rows of different sources did land on one ticket
it would throw rather than refuse.

## Decision

**A give-back is picked on the line, whether or not a receipt exists yet.** The
lines pane carries a discount chip beside the [[Pemilik tiket]] chip — the same
row shape, because "whose is this" and "what came off this" are asked of the
same thing. Units a receipt already owns write through the existing
receipt-scoped route immediately. Free units hold the pick **pending** in the
pane, next to the tapped-units selection, and it is written at confirm. Nothing
new is stored: a pending pick is client state that either becomes a `discounts`
row or is thrown away, exactly like the selection beside it.

**Per item mints, discounts and pays in one gesture again.** At confirm the pane
chains `mintReceipt` → `applyDiscount` per pending line → `recordPayment`, every
call naming an id this side minted (ADR-0123). The chain is deliberately not one
fat endpoint: the same sequence replays through the [[Antrean setelmen]] with no
new event kind, and the [[Rincian pilihan]] slip now quotes the pending
give-backs so the paper and the confirm button cannot disagree.

**A line stacks one row per source, and the stack is clamped to the line.** The
route's refusal is scoped to the `manual` slot it is the only writer of, so a
tier and a promo coexist. `recomputeBill` groups a receipt's line rows by ticket
and clamps their **sum** against that line's own base — clamping row by row lets
10% + 100% take 110% of a dish and drive the receipt negative. Each row still
resolves and prints what it promised; only the fold is clamped, the same shape
bill scope already used.

**A receipt names nobody.** The Siapa sheet, its card, its auto-prompt and the
`memberId` on mint are gone. `receipts.member_id` is kept and still read — a
bill that closed under ADR-0118 reports and prints its owners unchanged — but
nothing writes one, and `attachReceiptMember` stays in the journal enum because
those names are persisted.

**A `piutang` debtor is suggested, never derived.** When every line about to be
charged shares one [[Pemilik tiket]], the debtor row offers them as one tap into
a pre-filtered lookup. The cashier still picks the person, because that tap is
the agreement to owe and eating a dish is not one — ADR-0125's rule stands, with
the typing removed. The row now appears in every mode and only for `piutang`,
rather than in Per item and only under `memberSplit`.

## Considered options

- **Keep `Tinjau struk`, move only the Siapa step:** rejected. The detour's cost
  is the orphan receipt and the second screen, neither of which Siapa caused.
- **Fold the discounts into `mintReceipt` as an array:** the atomic version, and
  the upgrade path. Rejected for now: it costs a wire field, a journal payload,
  a parity-test arm and a `recomputeBill` branch to remove a failure whose blast
  radius is an unpaid receipt sitting visibly in the struk list.
- **A fourth discount scope (`visit_id` + `ticket_id`, no receipt):** rejected.
  It makes a pending pick durable, which is the property ADR-0067 spent a
  receipt to avoid, and it needs a migration and a new recompute branch to store
  something the cashier may abandon in ten seconds.
- **Derive the `piutang` debtor from the lines' owners, one leg per owner:**
  rejected for now. It needs a proration rule, a story for units nobody owns,
  and an answer for the half-posted receipt when guest B is over their limit
  while A went through. It sits cleanly on top of the suggestion later.
- **One reduction per line, as `CONTEXT.md` had it:** rejected. It is the
  version that penalises a member, and both the index and ADR-0125 already said
  otherwise — the code was the odd one out.
- **Migrating open ADR-0118 visits to Ticket attribution:** rejected. Every
  visit opened since ADR-0125 is already version 2; the population is a few
  hours of in-flight bills, and a migration that rewrites attribution on a
  half-paid bill is a worse risk than the ones it saves.

## Consequences

Per item is one gesture end to end, and the settle pane shows the method row and
the cash pad in that mode like any other. The lines pane is now the single place
a line is attributed and discounted, and the receipt sheet keeps both as the
precise way in — a line split across two receipts still discounts through the
sheet, since the chip resolves to the first receipt claiming it.

A closed bill's numbers do not move: receipt owners still read, line rows still
resolve, and switching `memberSplit` off still freezes rather than deletes. New
bills carry no receipt owner, so the slip's owner list renders empty and an
[[Amount receipt]] prints `Bagian 1/3` again rather than a name — the one
user-visible loss, and the shares were interchangeable by design anyway
(ADR-0063).

The confirm chain is not atomic. A refused discount leaves a minted, unpaid
receipt standing in the struk list, which the cashier pays or deletes; offline
it halts that visit's chain, which is exactly what ADR-0123 built the refusal
path for.
