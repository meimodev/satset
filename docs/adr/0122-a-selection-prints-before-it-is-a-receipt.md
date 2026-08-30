# ADR-0122 — A selection prints before it is a receipt

Status: accepted
Date: 2026-08-30

Reads [ADR-0067](0067-billing-mode-is-per-payment.md) — a receipt is minted at
confirm time — and declines to change it. Extends
[ADR-0023](0023-two-phase-settlement-and-split-bills.md), which gave the money
document its two granularities, with a third that persists nothing. Keeps
[ADR-0066](0066-cashier-bill-page-and-print-preview.md)'s look-before-you-print
rule.

## Context

Under **Per item** the cashier taps the lines one guest is paying for and hits
confirm; the receipt is minted and paid in one act, and only then can it be
printed. Everything after the mint has a slip. The tapped selection — the state
the guest actually wants to check — has none.

So the cashier reads the lines aloud, or turns the tablet around, or mints the
receipt to get a printout and then has to unwind it if the guest says "no, the
teh was hers". A slip in the guest's hand is what the whole Per item mode is
for, and it was the one thing the mode could not produce.

The obvious fix is to let the cashier mint an **unpaid** receipt and print that.
It costs no new document kind and reuses the existing per-receipt path exactly.
It also breaks ADR-0067's one good property: a mode the cashier tries and
abandons leaves nothing behind. A guest who changes their mind would leave an
orphan unpaid receipt claiming lines, and the next cashier would have to know
to delete it.

## Decision

**The selection prints as an ephemeral document.** Nothing is minted, nothing
is written, and printing twice produces two identical slips. The selection
survives the print, so the confirm button beneath it charges exactly what was on
the paper.

**It is a Tagihan, by the ordinary rule.** The Tagihan-vs-Struk-pembayaran state
is read off the document's payments and never chosen (ADR-0023). A selection has
no payments, so it renders as a Tagihan without anything deciding that it should.

**It reuses `BillDocKind.itemizedReceipt`.** Its shape *is* an itemized share —
priced lines, a prorated total, no payment block. A fifth kind would have earned
nothing but a second branch in the renderer.

**The `docLabel` is what says it is provisional** — "Tagihan sementara" where a
minted share prints "Bagian 1/3". The one failure this document can cause is a
guest or a second cashier reading it as evidence a share exists, and the label
is the only place on the slip that can prevent it.

**Its total is `Bill.prorate`, and the rule lives on `Bill`.** The Per item
confirm button and this slip must state the same number, so the proration is one
method on the bill rather than a copy on each side. Service and tax are split
proportionally and the rounding residual is absorbed by tax, so the printed rows
add up to the total the button charges.

**No `printVenue` route.** There is no receipt for the server to re-render, so a
venue-scope printer receives the bytes this device rendered — the path the
Piutang collection slip already uses. No server change, no new endpoint.

## Consequences

The money document now prints at **three** granularities, and the third one
persists nothing. `CONTEXT.md`'s "two granularities" sentence is amended.

The slip carries **no discount**. Discounts attach to a receipt, and there is no
receipt yet; a bill-scope discount applied afterwards only makes the guest's
real share smaller than the quote. That is the harmless direction, so printing
is not blocked on it. A quote that came out *low* would be the one worth
refusing, and cannot happen.

Two selection slips need not sum to the bill total to the rupiah — each is
rounded on its own. They are quotes, and the minted receipts are what the
arithmetic closes on.

The action lives in the Per item summary box in the settle pane, which is where
the selection is already priced. It appears only with a non-empty selection, on
an open bill, in that mode — the same conditions that make the selection exist
at all.

One check earns its place: build the doc from a selection and assert its total
is `bill.prorate` of the tapped subtotal, its own rows add up to that total, and
it carries no payments.
