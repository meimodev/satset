# ADR-0120 — A tab follows the struk

Status: superseded by ADR-0125
Date: 2026-08-30

Amends [ADR-0098](0098-a-tab-is-a-payment-method-not-a-write-off.md) — a
`piutang` payment no longer requires a member on the *bill*, it charges the
member on the *struk*. Completes
[ADR-0118](0118-member-attribution-rides-the-receipt.md) for the one member
fact it left on the visit, and reads
[ADR-0119](0119-a-member-report-reads-what-they-bought.md) for the
receipt-else-bill rule it copies. Does not change
[ADR-0092](0092-a-member-is-a-phone-number.md) or
[ADR-0100](0100-a-ledger-guard-is-only-real-inside-a-transaction.md).

## Context

ADR-0118 moved attribution to the receipt: points, the tier discount, a
redemption and the product rollup all read `receipts.member_id`, falling back
to `visits.member_id` for anything no share claims. `memberUnitsOf` states that
rule once so two screens cannot disagree about the same split bill.

Debt was left behind. `POST /settlement/receipts/<id>/payments` reads
`visit.memberId` and charges that member, whatever the receipt says. So on a
[[Split bill]] where three regulars split a table, a share named to Budi and
paid on account lands on Ani's [[Piutang]] ledger — because Ani was seated
first. Nothing surfaces it: the payment succeeds, the struk prints, the bill
closes, and the discrepancy is discovered weeks later when the wrong person is
asked for money.

The failure is not that debt was forgotten. It is that a bill had two answers
to *whose struk is this* — one for points, one for money — and only one of them
was written down.

## Decision

**A tab charges the [[Pemilik struk]], falling back to the
[[Pemilik tagihan]].** `rec.memberId ?? visit.memberId`, the same subtraction
`memberUnitsOf` and `pointsBaseByMember` already make. Money on a share nobody
named is the bill owner's, exactly as units and rupiah already are.

Four rules follow.

**1. One member field, not two.** The tab reads `receipts.member_id` — the
column ADR-0118 minted for attribution. A debt-only member beside it was
available and is rejected: it is the two-answers problem again, one level down,
and the first report that disagrees with the ledger is the one nobody can
reconcile. If a cashier genuinely wants Budi's food on Ani's tab, that is Ani's
struk with Budi's food on it, which the line picker already expresses.

**2. The headroom guard moves with the charge.** `chargeDebt`'s credit-limit
check reads the struk's member, and stays inside `db.transaction` for the
reason ADR-0100 gives: the balance is `SUM(delta)` and no constraint can hold
it. The client's pre-gate reads the same member's `debtHeadroom` — which ships
on any serialized member already, since `memberJson` carries `debt` and
`debtLimit`.

**3. A struk is born named.** `POST /settlement/visits/<id>/receipts` gains
`memberId` on the body. The settle pane mints at confirm on purpose — a mode
the cashier tries and abandons leaves nothing behind — so at chip-tap time
there is no receipt to attach a member to, and a mint-then-attach-then-pay
sequence would open a window where a named struk is half-made. The member rides
in with the lines, in the transaction that already builds the receipt.

**4. The picker is gated on `memberSplit`, and the fallback carries the rest.**
ADR-0118's rule holds unchanged: the mode key gates the write and the picker,
never a read. Mode off means no picker, no `receipts.member_id`, and every tab
falls back to the bill owner — which is today's behaviour, byte for byte, at
every venue that never held the mode.

## Consequences

`receipts.member_id` is a weak reference (ADR-0092): a deleted member leaves it
dangling, and a `member_debts` row already outlives its member for the same
reason. Anonymising does not rewrite who owed what.

A venue running `members` + debt but **not** `memberSplit` sees no change at
all. The feature is only reachable where the picker is.

Reversal follows attribution automatically: `reverseChargeForPayment` is keyed
on `paymentId` and reads the charge row it wrote, so a reopen unwinds whichever
member was charged without knowing the rule.
