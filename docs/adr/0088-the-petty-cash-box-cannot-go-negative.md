# ADR-0088 — The petty cash box cannot go negative

Status: accepted
Date: 2026-08-08

Diverges deliberately from the rule ADR-0041 set for `stockOnHand`.

## Context

The [[Kas kecil]] box is an append-only ledger whose balance is `SUM(delta)`.
The question this ADR settles is what happens when a supervisor posts a
Rp 200.000 expense against a box holding Rp 150.000.

There is a precedent in the codebase pointing the other way. `writeMovement` in
`lib/server/stock.dart` carries an explicit comment refusing to clamp:

> Deliberately NOT clamped at zero: a negative balance is the `overrideStock`
> signal that the venue's counts are wrong (ADR-0041).

Copying that would be the consistent-looking choice, and it would be wrong,
because the two negatives mean different things.

**Stock goes negative because reality drifted from the recipe.** Every sent
line deducts ingredients by recipe, and recipes are approximations — a cook's
hand is heavier than the resep says. Nobody made a mistake; the model simply
lags the pan. The negative is genuine information, and clamping it would
discard the only evidence that an opname is overdue.

**Cash goes negative because somebody didn't write something down.** Physical
notes in a physical box cannot be fewer than zero. A negative balance is never
a fact about the money; it is always a missing row — most often a top-up the
owner handed over in person and nobody recorded. There is no reality for the
negative to be evidence *of*.

The two options were therefore:

1. **Allow it**, mirroring stock, and surface the negative as a "your ledger is
   incomplete" signal on the Kas screen.
2. **Reject it**, server-side and fail-closed, with the error naming what is
   wrong.

Option 1 is friendlier in the moment: the supervisor at the market records
their expense and moves on. But it defers the correction to nobody in
particular. A box sitting at −Rp 50.000 has lost the ability to answer the one
question it exists to answer — *how much cash is in the box right now* — and
the longer the missing top-up goes unrecorded the less likely anyone can
reconstruct it. The signal has no owner, and unowned signals decay into
wallpaper.

## Decision

**An expense that would drive the balance below zero is rejected**, server-side,
with error code `insufficient_cash`. The client surfaces the current balance
alongside the refusal so the next act is obvious.

A **reversal** is exempt from the check in one direction only: reversing a
top-up may take the balance negative if money has since been spent, because
refusing that would make an erroneous top-up permanently uncorrectable. That
case is a genuine mid-correction state, and it resolves as soon as the real
top-up is recorded.

An **opname** is likewise exempt: the counter is reporting what is physically
in the box, and a count lower than the ledger says is precisely the variance
worth keeping. A count cannot itself be below zero.

## Consequences

The refusal is the feature. A supervisor blocked from posting an expense goes
and asks the owner what they handed over and when, which is the conversation
that produces the missing row. Recording it takes seconds; reconstructing a
month of it does not.

Petty cash and stock now answer the same-shaped question differently, which
will look like an inconsistency to the next reader. It is documented here for
exactly that reader: the divergence is the point, and the tell is whether a
negative could ever describe something real.

`stockOnHand`'s behaviour is untouched. If per-cashier drawer floats arrive
later they are a third case and get their own decision — a drawer reconciling
short is a real and important fact, unlike a petty cash box holding negative
notes.
