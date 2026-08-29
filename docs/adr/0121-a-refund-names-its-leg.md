# ADR-0121 — A refund names its leg

Status: accepted
Date: 2026-08-30

Amends [ADR-0098](0098-a-tab-is-a-payment-method-not-a-write-off.md) — the
sentence "`piutang` may not be used as a refund method" survives literally and
loses its consequence: a `piutang` leg becomes reversible, because a refund no
longer picks a method at all. Reads
[ADR-0120](0120-a-tab-follows-the-struk.md) for which member a reversal lands
on and [ADR-0025](0025-mandatory-non-cash-payment-proof-photo.md) for why proof is
per payment.

## Context

`CONTEXT.md` has always described a receipt holding **multiple payments** —
"part Tunai + part Kartu, or part cash + part on account" — and a split tender
carrying "one photo each". The code did not. `lockedMethodFor` read every
payment on the bill and collapsed the method row to the first tender, so a
struk could hold two legs only in the glossary. That was drift, not a decision,
and removing it is a bug fix rather than an ADR; what the fix *exposes* is
this one.

`POST /settlement/receipts/<id>/refund` takes a **method** and a magnitude, and
sums `refundable` over the struk's non-`piutang` payments. Both worked only
because the lock guaranteed one method per struk. Once a struk can hold Tunai +
QRIS + `piutang` at once, "refund 40k by tunai" cannot say which leg it unwinds
— and with two `tunai` legs it cannot say even when the method is unambiguous.

The `piutang` ban was correct for the reason ADR-0098 gives: handing drawer
cash back for a promise pays a guest for a bill they still owe. But it was
enforced by banning a *method*, and the method is exactly the thing that stops
identifying anything under split tender.

## Decision

**A refund targets a `paymentId`.** The method is inherited from the leg, never
chosen. The amount is capped at that leg's unreversed remainder.

**A money leg refunds as it always did** — a negative `payments` row carrying
the leg's own method.

**A `piutang` leg refunds by reversal.** `MemberDebtKind.reversal` against the
member the charge named (ADR-0120), sized to the refund; no rupiah moves and
the drawer is untouched. ADR-0098's rule holds in its true form: you still
cannot hand cash back for a promise, and now it holds *because the cashier
never picks a method*, rather than because one chip is missing.

**Reversal becomes partial.** `reverseChargeForPayment` is idempotent today on
"a reversal row exists for this paymentId", which is what makes reopen safe. It
becomes a sum: reverse `charge − Σreversals`, never below zero. Reopen then
reverses the *remaining* unreversed amount per leg, so a partial refund
followed by a reopen nets to exactly the charge. Refusing a reopen on a struk
with partial reversals was the alternative and is rejected — it makes an
ordinary act fail because of an earlier correct one, and the ledger's own rule
is that it corrects forwards.

## Consequences

The refund sheet stops being a method picker and becomes a leg picker: the
struk's payment rows, each with method, amount, time and remaining refundable.
That is also what makes a `piutang` leg selectable without putting `piutang`
back among the refund chips.

`Capability.refund` is unchanged and needs no companion. It already gates
`/members/<id>/debt/write-off` and `/debt/adjust`, the two other routes that
reduce a tab without money arriving; collect is `settleBill`. A reversal
written from the till is the same authority as a reversal written from the
member's file.

A refund raises the struk's outstanding again, which meets the guard the same
fix adds on the way in: a payment may not exceed the receipt's outstanding
(`409 overpayment`). Nothing capped it before, because the mode computed the
amount and the lock computed the method; free amount entry removes both.

One check earns its place: charge a tab, refund part of it, reopen the struk,
assert the member's balance is exactly zero.
