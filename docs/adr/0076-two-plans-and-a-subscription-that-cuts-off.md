# ADR-0076 — Two plans, and a subscription that cuts off

**Status:** Accepted
**Date:** 2026-08-01
**Supersedes:** [ADR-0074](0074-venue-subscription-notice-without-enforcement.md) (its core invariant)
**Amends:** [ADR-0016](0016-fleet-superadmin-cloud-control-plane.md) (venue status, fleet audit)

## Context

ADR-0074 closed half of the money loop. It mirrored `plan` / `billingStatus` /
`paidUntil` down to the venue so the people paying the bill could finally see it,
and it deliberately stopped there: *"`status` remains the only thing that stops a
venue trading, flipped only by an explicit `setVenueStatus`."* The venue was told;
nothing happened if it ignored being told.

Three things have changed since.

**The plans were never real.** `{free, basic, pro, enterprise}` were four strings
that gated nothing, carried no price, and meant nothing to anyone but the operator
who typed them. ADR-0074 recorded this honestly — *"`plan` still means nothing"* —
and pushed entitlements out of scope. The actual commercial arrangement is simpler
than an entitlement model and was never representable: venues are on a **trial**
with an end date, or they are a **partner** paying an agreed monthly rate.

**`billingStatus` and the dates disagreed by design.** ADR-0074 named the failure
itself: `paid` with a `paidUntil` three weeks gone, healthy on every surface,
billing nobody. The mitigation was to make extending the term and marking it paid
one act (`_extend`). That works only for as long as nobody sets the two fields
independently — and `setVenueBilling` accepts them independently, because it
always has.

**One of ADR-0074's rejection reasons expired.** It rejected auto-suspension partly
because it *"requires new scheduled infrastructure."* [ADR-0075](0075-dictated-temporary-password.md)
shipped `sweepExpiredTempPasswords` as an hourly `onSchedule` two days later. The
infrastructure exists and is in production.

What remains of ADR-0074's argument is the part that was always the strongest: a
mis-typed date should not take a restaurant offline mid-service, on a system with
no payment gateway to correct it. That concern survives this ADR intact — it is
why the cutoff is not the date.

## Decision

**Two plans, dates as the only billing truth, and a cutoff that actually fires.**

### 1. `plan` becomes a closed two-value set that carries data

| | `trial` | `partner` |
|---|---|---|
| Term | `paidUntil` | `paidUntil` |
| Start | `trialStartAt` — recorded and displayed, enforces nothing | — |
| Price | none | `priceMonthly`, integer rupiah |
| Cycle | — | `billingCycle: 'monthly' \| 'yearly'` |

`fleetPlanKeys()` already widens the dropdown by whatever the venue currently
holds, so a venue sitting on `free` renders as `free` until someone changes it.
No backfill, no migration, no silent re-plan as a side effect of opening an editor.

**Yearly is two months off, and it moves the term with the price.** Checked, the
card shows `priceMonthly × 10` as the annual total and the quick-term control
collapses to a single `+1 tahun`. Unchecked, monthly rate and `+1 bulan`. The
checkbox describes how a venue pays; a control that let you renew a yearly venue
one month at a time would make the flag decorative.

### 2. `billingStatus` is deleted

Lapsed is `paidUntil < now`. Ending is `paidUntil - now <= fleetRenewWarn`. Both
predicates already existed in `data/services/venue_billing.dart`; they lose their
`billingStatus` limb and keep their shared-code property, which is the whole point
of that file.

The state ADR-0074 called the worst — paid, with a date already gone — becomes
unrepresentable rather than merely discouraged. The cost is real and accepted: a
partner whose transfer you have personally seen clear cannot be held as "paid"
past their date. Extending the date is the way to say that, which is the same act
you would have taken anyway.

### 3. Both plans cut off. Trial on the date, partner seven days after

```
trial:    paidUntil < now                        → suspend
partner:  paidUntil + 7d < now                   → suspend
either:   paidUntil == null                      → never
```

A trial ending is the trial working. Going dark is what a trial is *for*, and a
trial that quietly runs forever is a free venue nobody decided to give away.

A partner is a paying restaurant, so it gets `fleetGraceAfterLapse` — seven days,
half the fourteen-day warning window, deliberately asymmetric. Fourteen days of
banner before the date and seven after is twenty-one days of visible notice, and
a bank transfer that clears late in the week still lands in time. This is where
ADR-0074's real objection is answered: a data-entry slip now costs a week of
warning before it costs a service.

`paidUntil: null` never lapses, so a newly created venue with no term set sits
idle rather than being cut off at creation.

### 4. The sweep cannot fight the operator

**`Aktifkan` is disabled while a venue is lapsed past its grace.** The only route
back is a future date. This replaces the obvious alternative — stamp
`autoSuspendedAt` so the sweep knows not to re-fire — with a rule that needs no
field: if the venue cannot be activated while lapsed, there is nothing for the
sweep to undo.

**Extending re-enables the button. It does not press it.** Without a stored reason
for the suspension, nothing can distinguish a lapse from a suspension you set by
hand over a dispute, so recording a payment must never silently revive a venue you
took offline on purpose. Turning it back on stays one explicit tap.

### 5. Automatic cutoffs are audited like everything else

The sweep writes `fleet_audit` through `writeFleetAudit()` with the reserved
`actorUid: 'system'` and `action: 'autoSuspendVenue'`, rendered "Sistem" in the
reader. `actorUid` is a free string with no reference, so the sentinel costs
nothing structurally.

Every other status change on a venue has a row. The one class of change nobody
remembers making is exactly the one whose record you will want at 09:00 when a
venue calls to ask why it is dark.

### 6. The banner may now say what happens

ADR-0074 held that *"copy implying imminent shutdown would be a lie the code does
not tell."* The code tells it now, so the banner names the actual cutoff date —
the end date for a trial, end + 7 for a partner. It stays `editSettings`-gated and
still taps through to WhatsApp.

A venue cut off without being told the date would be the exact failure ADR-0074
was written to prevent, reintroduced from the other side.

## Consequences

**The loop closes, and it closes at different speeds on purpose.** A trial expires
by itself; a partner is warned for three weeks and then expires by itself. Neither
needs a human to remember, and only one of them can plausibly be a mistake.

**One number defines "ending", still.** `fleetRenewWarn` stays 14 days and stays
shared. `fleetGraceAfterLapse` is a second, separate number answering a different
question — when it *stops*, not when we *warn* — and belongs beside it in
`venue_billing.dart` for the same reason.

**`plan` finally means something, without becoming entitlements.** It selects which
fields are meaningful and which cutoff rule applies. It still gates no feature
inside the venue; the embedded server still knows nothing about the cloud plan.
The entitlement model ADR-0074 pushed out of scope stays out of scope.

**The console can no longer express "overdue but fine".** Deleting `billingStatus`
removes a manual judgement the dates cannot carry. Accepted: it was the field that
made the dangerous state possible, and it was set by hand by the same person who
sets the date.

**A venue in `unknown` status now includes ex-`banned` venues** — see the companion
decision below. They stay blocked, because every gate tests `isActive`.

## Companion decision: `banned` is removed

`AdminStatus` becomes `{active, suspended, unknown}`, and `STATUSES` in
`functions/index.js` becomes `["active", "suspended"]`.

`Tangguhkan` was always sufficient. Both states stop the venue's server and lock
its staff out; the only difference was the word, the tint, and an operator's
memory of which one they had used. Two controls that do the same thing to the
venue, distinguished by severity of tone rather than of effect, is a choice
presented at the worst moment — mid-service, on the most destructive control in
the console.

Because venue status and admin-account status share one enum and one server-side
whitelist, **admin accounts lose `Blokir` too**. This is not collateral damage
worth avoiding: the same argument applies to an account, and `Hapus` remains for
an account that should never return.

**Existing `status: 'banned'` documents need no migration.** `_parseStatus` maps
any unrecognised value to `AdminStatus.unknown`, every gate tests `isActive`
(`status == active`), so they stay blocked — failing closed. The only degradation
is the message, from "Venue diblokir." to "Venue tidak aktif."

## Alternatives rejected

**Keep `billingStatus`, shrink it to `{paid, overdue}`.** Smallest possible diff
and it preserves the manual "overdue" judgement. Rejected: with `plan: 'trial'`
alongside `billingStatus: 'trial'`, the word meant two things at once, and the
combinations (`plan:partner` + `billingStatus:trial`) were nonsense the wire would
happily accept.

**Auto-suspend trials only, notice-only for partners.** Closest to ADR-0074 and to
the initial framing of the request. Rejected: it leaves the partner half of the
loop exactly where ADR-0074 left it — a lapsed venue trading forever until a human
notices — which is the thing this ADR exists to fix. The grace window addresses
the underlying risk more precisely than an exemption does.

**Stamp `autoSuspendedAt` so a manual override survives the sweep.** Genuinely
correct, and it distinguishes lapse-suspension from dispute-suspension for free.
Rejected as the primary mechanism: disabling `Aktifkan` while lapsed achieves the
same non-interference with no new field, and makes the invariant ("an unpaid venue
cannot be turned on") stronger rather than merely enforced by bookkeeping.

**A grace window on trials too.** Symmetric and one fewer branch. Rejected: it
makes the trial end date not the trial end date, and a trial's whole value as a
commercial instrument is that the stated date is the date.

**Store the computed annual total instead of a monthly rate plus a cycle flag.**
One field, no derived value that can disagree with a stored one. Rejected: nothing
could then show "hemat 2 bulan", because nothing would know the monthly rate — and
the discount is the reason the yearly option exists.

**A full subscription block in the create dialog.** One pass, nothing left
half-configured. Rejected: it makes the create dialog a second Langganan editor
with its own copy of the yearly maths, and two places that can set a term are two
places that will drift.
