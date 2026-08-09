# ADR-0095 — Points earn at bill close and never expire

Status: accepted
Date: 2026-08-09

## Context

The [[Poin]] ledger is the one part of membership that holds a number a guest
believes in. Two questions decide whether that number is trustworthy.

**When does it earn?** A [[Bill (tab)]] mints a receipt per payment
([ADR-0067](0067-billing-mode-is-per-payment.md)), so "earn on payment" fires
several times per party and fires again for every receipt of a reopened bill.
[[Bill close (Tutup tagihan)|Bill close]] fires exactly once per visit and is
already the moment the bill's arithmetic is final.

**What is the base?** `settledTotal` includes service and tax
([ADR-0039](0039-settled-total-over-redefining-net-total.md)) — rewarding a
guest for the tax the venue collects on the state's behalf is money the venue
gives away for nothing.

**Does it expire?** Every loyalty scheme in the world expires points, because
the outstanding balance is a liability that only grows. The problem is that
this venue's server is a phone or tablet in a restaurant. It has no scheduler,
no cron, no reliable wake. Expiry could only be evaluated lazily — when
somebody opens a screen — which produces a balance that changes *by being
looked at*, and a guest who is told 400 poin on Tuesday and 0 on Wednesday
because nobody opened the app in between.

## Decision

**Earn once, at bill close.** The base is the bill **net of
[[Diskon (discount)|discount]], excluding service and tax**, at an owner-set
rate defaulting to 1 poin per Rp 1.000, floored. A **reopen reverses** the earn
row; the subsequent re-close earns afresh. A [[Settlement (recording payment)|refund]]
posts a negative earn. A [[Walkout (tak tertagih)|walkout]] earns nothing —
money that was never collected buys no loyalty.

**The ledger is append-only and its balance is `SUM(delta)`, derived and never
stored** — the same shape as [[Kas kecil (petty cash)]]
([ADR-0088](0088-the-petty-cash-box-cannot-go-negative.md)), and non-negative
for the same reason: a balance that can go below zero is a balance somebody
spent twice.

**Points never expire.** In place of expiry, the members Reports section
carries **Poin beredar** — the outstanding balance, presented as a liability
figure over the range. The owner watches the number instead of the system
quietly deleting it.

A hand-adjustment exists under `manageMembers`, requires a reason, and writes
`memberPointsAdjusted` to the [[Audit]] trail. It is the only way points move
without a bill.

## Consequences

The balance is arithmetic over immutable rows. It cannot drift, it cannot be
corrected by editing history, and it reconciles against closed bills the same
way the cash box reconciles against its movements.

The liability grows without bound. That is visible rather than hidden, and a
venue that finds it uncomfortable can lower the earn rate — which affects only
future earning and never retroactively deletes what a guest was promised.

Expiry stays available as a later decision. It needs a scheduler the venue
server does not have, and adding one is the actual cost, not the rule.

Earning at close means a guest who pays and lingers does not see their points
until the cashier closes the bill. The receipt prints the earned figure at that
moment, which is when they are handed it anyway.
