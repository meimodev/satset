# ADR-0094 — A bill discount has a source

Status: accepted
Date: 2026-08-09

Amends [ADR-0070](0070-discounts-have-a-bill-level-scope.md). Does not change
[ADR-0037](0037-cashier-stage-catalog-discounts.md) or
[ADR-0038](0038-discount-tax-stacking-order.md).

## Context

[ADR-0070](0070-discounts-have-a-bill-level-scope.md) gave a
[[Diskon (discount)]] a bill scope and enforced **one bill discount per
visit** with a partial unique index on `visitId`. That rule exists so a
table-wide promo cannot be applied twice by two cashiers looking at the same
bill.

Membership brings two more bill-scope reductions:

- the **member tier discount**, which is a preset the owner nominates and the
  system applies because a [[Pelanggan (member)]] is attached, and
- a **[[Tukar poin (redeem)|points redemption]]**, which is money off bought
  with a points balance.

Three authorities, one slot. The options were:

**Relax the index** — allow any number of bill discounts per visit. This throws
away the only thing stopping the double-applied promo, which is the exact
failure ADR-0070 was written to prevent.

**Make them mutually exclusive** — the cashier picks one. This is the version a
guest experiences as being punished for membership: their card cancels the
Tuesday promo, and the cashier gets to explain it. It also makes redemption
compete with a discount the guest did not choose.

**Give the row a source** — keep the uniqueness rule, but scope it to who is
applying. Each authority holds its own slot, and stacking becomes explicit and
bounded at three rather than unbounded.

## Decision

`discounts` gains a **`source`** column: `manual` | `member` | `redeem`. The
partial unique index moves from `visitId` to **`(visitId, source)`** — one
manual bill discount per visit, one member discount, one redemption, and never
two of a kind.

Everything else is unchanged. Each row still snapshots its preset's name, kind
and value ([ADR-0037](0037-cashier-stage-catalog-discounts.md)); each still
distributes across receipts through the ADR-0070 machinery; each still cannot
push a total below zero, now checked over the stacked set. Order- and
line-scope discounts have **no** source — the concept is bill-scope only, where
the collision lives.

Existing rows backfill to `manual`, which is what they all are.

## Consequences

"One bill discount per visit" remains as true as it was for the thing that rule
protected: a cashier still cannot apply the same promo twice. The rule got
narrower, not weaker.

A member on a promo night receives both, deliberately. A venue that finds the
stack too generous fixes it by not nominating a member preset — the lever is
configuration, not arithmetic.

The three-slot ceiling is the design. A fourth bill-scope authority is a new
`source` value and a deliberate act, which is the point of naming them rather
than counting them.

Reporting gains the ability to say *why* money came off a bill — promo versus
membership versus redemption — which the members Reports section needs and
which an unsourced row could never answer.
