# ADR-0093 — Membership pays out at settlement

Status: accepted
Date: 2026-08-09

## Context

Every restaurant loyalty scheme anyone has seen shows a **member price on the
menu**. The obvious build is therefore: attach the
[[Pelanggan (member)]] when the waiter seats the party, and let the menu, the
cart, the review screen and the [[Estimasi (cart estimate)|estimate]] all price
themselves for a member.

[ADR-0037](0037-cashier-stage-catalog-discounts.md) already decided the
opposite for discounts generally: a reduction is a **settlement-stage** act, a
waiter can neither apply nor preview one, and the
[[Estimasi (cart estimate)|Estimasi]] deliberately promises *more* than the
bill will ask for. Making membership the one exception forks price resolution
across the menu, cart, review, sent and KDS surfaces — every place a rupiah is
rendered gains a "for whom" parameter — and it hands the waiter a discount
authority the capability model spent four ADRs keeping away from them.

It also makes attachment urgent. If the price depends on the member being
known before the first tap, then a member who mentions their card at the till
has to have their whole order re-priced, which is a reopen in everything but
name.

The countervailing argument is real: a guest who does not *see* a member price
is less motivated to be a member. The answer is that they see it on the
receipt, at the moment it is charged, which is where the evidence lands
anyway.

## Decision

**All four membership benefits resolve at settlement.** The member tier
discount, [[Tukar poin (redeem)|redemption]], [[Poin]] earning and
[[Kartu stempel (punch card)]] progress are computed at the till, on the
[[Bill (tab)]]. **Nothing about a member changes any price a waiter sees.**

A member is attached to the **[[Visit]]** from the cashier's bill overlay
(and, optionally, from the waiter's table sheet as a convenience) at any time
before [[Bill close (Tutup tagihan)|bill close]]. There is no ordering
deadline, because there is nothing an early attach would have changed.

Because these acts are all settlement acts, **none of them work offline.**
Lookup, attach, enroll and redeem all require the server. This is the one place
the app deliberately does *not* extend [ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md):
a queued redemption lets two disconnected clients spend the same balance, and
the ledger's non-negative invariant would break at replay, in the money path,
after the guest has already left.

## Consequences

The order-taking flow is untouched. Menu, cart, review, sent, KDS and the
Estimasi keep exactly one price per item, and the "waiter never sees a
discount" invariant survives intact.

A member who forgets to mention it until the till still gets everything, which
is the common case and the one the alternative handles worst.

The receipt does the marketing. It prints member name, poin didapat and sisa
poin (and punch progress when a program runs), which is the retention loop — a
balance nobody is shown is a database column, not a feature.

Membership is unavailable on a `terputus` client. Settlement already is, so
this adds no new failure mode to the floor; the copy says "sambungkan dulu"
and nothing is queued.
