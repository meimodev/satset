# ADR-0067 — Billing mode is per payment, not per bill

## Status

Accepted. Amends ADR-0023, which introduced the mode chooser and made the choice a
property of the bill. Depends on ADR-0068, which is what makes a mixed-mode bill
arithmetically coherent.

## Context

ADR-0023 asks the cashier one question up front — Bayar penuh, Split per item, or
Split rata — and mints receipts from the answer. Changing the answer means
`resetBilling()`, which deletes every receipt and is refused the instant any money
has landed. `_ResetMethodButton` exists solely to walk that back while it is still
free.

The question is asked at the wrong time. At the moment the cashier picks, nobody has
paid, so the mode is a *prediction* about how the table will behave. Tables do not
behave. Two friends go halves, a third pays for his own steak, and a fourth settles
the rest on a card. Under ADR-0023 that table is unbillable without deleting
receipts, and once the first payment lands it is unbillable at all.

The design source asks the question per payment instead. Its mode row is local UI
state — a lens on the remaining balance, chosen fresh each time someone reaches for a
wallet — and each confirmed payment appends to a flat record list.

## Decision

**Mode is a receipt-creation strategy evaluated at confirm time. It is not a
property the bill remembers.**

- **Penuh** — mint one receipt claiming the whole remainder, pay it.
- **Per item** — mint a receipt owning the tapped lines, pay it.
- **Bagi rata** — mint one [[Amount receipt]] per share of the remainder, pay the
  next unpaid one.

A bill is a bag of receipts, and they need not agree about how they were made.

The source's flat `pay.records[]` is **not** adopted. It has no payer identity, so it
cannot support receipt letters (ADR-0063), per-receipt discounts, refunds, reopen, or
a per-guest printed slip — all of which ship today. Keeping the `Receipt` entity and
changing only *when* it is minted gets the source's behaviour at none of that cost.

### Pre-assignment survives

Tap-to-select-and-pay is the fast path, but it can only build one receipt at a time.
Building receipts A, B and C, assigning every line, printing three slips and *then*
collecting is a real workflow and the reason ADR-0037's per-unit assignment exists.
So `Tambah struk` and the assign row stay, minting the same `Receipt` the fast path
mints. Two entry points, one object — the layout is what makes the fast path read as
primary.

## Consequences

- `bill.mode` stops being meaningful and `resetBilling` loses its reason to exist:
  there is no committed choice left to undo. Deleting an individual unpaid receipt
  remains available and is now the whole of that story.
- `_ModeChooser`'s "choose once" framing is replaced by a row that is genuinely
  switchable between payments — which is what it already looked like.
- The server must tolerate a visit holding itemized and amount receipts at once.
  ADR-0068 is that change; without it the two kinds double-count the bill.
- A mode picked and then abandoned leaves nothing behind, because nothing is minted
  until confirm. This is the main practical gain: the cashier can explore what a split
  would look like without committing the table to it.
