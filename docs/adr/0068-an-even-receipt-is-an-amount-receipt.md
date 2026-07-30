# ADR-0068 — An even receipt is an amount receipt

## Status

Accepted. Generalizes the line-ownership rule ADR-0037 set and ADR-0063 leaned on.
Prerequisite for ADR-0067.

## Context

`receipts.mode` has always been per receipt, not per bill — `settlement_routes.dart`
writes `itemized` or `even` per row, and `_recompute` already walks the two kinds in
separate loops on the same visit. Mixed-mode is closer than it looks.

Two things stop it:

1. **`POST /split-even` replaces everything.** It calls `_clearReceipts` and inserts N
   fresh rows, so an even split cannot coexist with an itemized receipt — it deletes it.
2. **The two kinds are computed from different sources.** An itemized receipt's total is
   recomputed from the units it owns; an even receipt's is a `total` frozen at split
   time. Put one of each on a visit and the receipt totals no longer sum to the bill
   total, because the even share was cut from a whole the itemized receipt is also
   claiming.

`outstanding` survives this — it is `billBreak.total − paidNet`, computed bill-level,
so partial payments are already safe. What breaks is `fullyAssigned`, and through it
`fullySettled`.

## Decision

**Rename the concept to what it already is: a receipt owning no lines and holding a
frozen money claim.** An even share is the case where N of them are minted at once.

- The claim is drawn from the **untracked remainder** — the bill total less every
  itemized receipt's total and every other amount receipt's claim. Cutting from the
  remainder rather than from the whole is the entire fix: two kinds of receipt can no
  longer claim the same money.
- `POST /split-even` **mints N shares of the remainder** instead of wiping the visit.
- **`fullyAssigned` is redefined**: every unit is owned by an itemized receipt **or**
  covered by an amount receipt.
- The claim stays **frozen after minting**. A guest quoted a third of the bill is owed
  that number even if a line is voided afterwards; the correction belongs in a refund,
  which has an audit trail, not in a total that silently moves.

### Shares round to Rp 100, and the surplus spreads

`distributeEven` splits to the rupiah and drops the remainder on the first receipt,
which is exact and unpayable — nobody hands over Rp 87.334. The source rounds each
head up to Rp 1.000 and lets the last payer absorb the difference, which on a small
bill produces a payer who owes nothing.

So: **round each head up to the nearest Rp 100, then spread the surplus back across
the later heads.** Nobody is asked for coins, nobody owes zero, and no single payer
is the unlucky one. The UI states the rule rather than leaving unequal shares looking
like a bug.

`distributeEven` stays for callers that want an exact split; the rounded distribution
is a second function beside it, with a test covering the degenerate case
(Rp 3.000 across four heads) and the sum invariant.

## Consequences

- **`fullyAssigned` now gates whether a bill closes itself** (ADR-0069), so it earns a
  test of its own rather than a manual pass. It is the single predicate two decisions
  hang off.
- An amount receipt still carries no [[Receipt letter]] and no line discount —
  ADR-0063 and ADR-0037 are unchanged on both points. Renaming the concept does not
  give it an identity it never had.
- Deliberately **not** done: recomputing an amount receipt's claim when the bill
  changes. It would keep the arithmetic tidy and quietly re-quote a guest who has
  already been told a number.
