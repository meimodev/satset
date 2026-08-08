# ADR-0089 — Petty cash is not revenue

Status: accepted
Date: 2026-08-08

Third act of the story [ADR-0038](0038-discount-tax-stacking-order.md) and
[ADR-0039](0039-settled-total-over-redefining-net-total.md) started. Does not
change either.

## Context

The [[Kas kecil]] box moves money, and every existing money figure in the app
was tempting to reuse for it.

The temptations, each of which someone will propose again:

- An **expense** looks like negative revenue. It is money leaving the venue on
  a day the venue also took money in, so netting it against sales produces a
  single tidy number.
- A **top-up** looks like income. Cash appears in the venue and gets recorded.
- The **payment mix** already breaks money down by method, and `tunai` is
  sitting right there.

All three are wrong, and the reason is the same one that produced ADR-0039.
`netTotal` was redefined once — first meaning `subtotal`, then
`subtotal − void + service + tax` — and the cost was that no reader could tell
which meaning a historical row carried. The fix was not another redefinition
but a **second, separately named figure**: `settledTotal` answers "what did we
collect", `netTotal` answers "what did we ring up net of voids", and `netTotal`
was frozen permanently so it could never learn a third meaning.

Folding petty cash into either would be that third meaning. A `settledTotal`
that quietly nets off the ice money is no longer the amount collected, and
every export, snapshot and owner report reading it starts lying — including the
rows already written under the old meaning.

There is a real accounting argument that petty cash outflows *are* an expense
line that belongs in a P&L beside revenue. That argument is correct and it is
about a different document. This app reports **trade** — what was sold, to how
many covers, at what discount, with what waste. It does not produce a P&L, and
the day it does, the Kas ledger is the clean input it draws from precisely
because it was never smeared into the sales figures.

## Decision

Petty cash is **fully isolated** from every sales figure. Specifically it never
enters `netTotal`, `settledTotal`, Bruto, the discount figure, the write-off
figure, the payment mix, or the covers/average-per-cover arithmetic.

It reads through **one dedicated Kas section** in Reports, carrying: opening
balance, total in, total out, a per-category breakdown of outgoings, and closing
balance, over whatever range the report is showing.

The opening balance is `SUM(delta)` over every movement strictly before the
range start, where the boundary respects **`businessDayStartHour`** — the same
04:00 rollover sales buckets on. Without that, a 02:00 expense falls in a
different day from the sales it sat beside and an owner reconciling one night's
trading reads two.

## Consequences

An owner wanting "revenue minus petty cash" performs one subtraction across two
sections. That is the intended cost, and it is paid by the reader who wants the
combined number rather than by every reader who wants either number alone.

The Kas section is a pure read over `cash_entries`. Export and the off-site
owner snapshot can each add it later without redesign, since neither requires
touching the figures they already carry.

`netTotal` stays frozen. If a future P&L feature wants to combine the two, it
composes them at the top rather than redefining anything underneath — which is
the whole reason ADR-0039 chose a new name over a new meaning.
