# ADR-0070 — Discounts have a bill-level scope

## Status

Accepted. Extends ADR-0037 (cashier-stage catalog discounts) with a third scope, and
inherits ADR-0038's line-then-order stacking rule unchanged.

## Context

A discount preset carries `scope: order | line`, and an applied discount attaches to a
**receipt** or to one line within a receipt. Both are per-receipt in the end.

A table-wide promo is neither. "20% off for the whole table" is a fact about the
[[Bill (tab)]], and expressing it today means applying the same preset to every
receipt by hand — three times for a three-way split, with nothing tying the three
rows together and nothing stopping the cashier from missing one.

ADR-0067 sharpens this into a plain bug. Receipts are now minted at confirm time, so
at the moment the cashier reaches for the discount button there may be **no receipt to
attach it to**. The source puts `Diskon` in the bill header, before any receipt
exists, and it is right to.

## Decision

**Add `bill` as a third preset scope.** A bill discount attaches to the visit, reduces
the bill subtotal before any receipt claims anything, and then distributes across
receipts exactly the way an order discount already does through `splitItemized`.

Stacking is unchanged and inherited from ADR-0038: line discounts are part of how the
subtotal is derived, then the whole-bill reduction applies to that net, then service,
then tax, positioned by `taxAfterDiscount`. A bill discount sits where an order
discount sits — the only difference is what it is attached to and therefore how many
of them there are.

The existing scopes are untouched. `order` remains the right answer for "this guest
gets a discount"; `bill` is for "this table does".

## Consequences

- **At most one bill discount per bill**, matching ADR-0037's no-stacking rule at the
  other two scopes. A venue wanting two promos combines them into one preset, where
  the arithmetic can be checked once.
- The totals ladder gains a genuine bill-level discount row, which is what the source
  shows and what the printed slip needs. Previously a discounted split bill had a
  discount line on each receipt and none on the bill.
- Presets grow a scope the settings editor must offer, and the cashier's picker must
  filter on — the same mechanism that already stops "Potongan 50rb" reaching a 25k
  line.
- The manager step-up path is unchanged: a cashier without `applyDiscount` reaches a
  bill discount the same way they reach the other two, and the row records both who
  applied and who approved.
