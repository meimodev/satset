# ADR-0074 — Venue subscription notice, without enforcement

**Status:** Accepted
**Date:** 2026-07-31
**Amends:** [ADR-0016](0016-fleet-superadmin-cloud-control-plane.md) (fleet audit)

## Context

`venues/{vid}` has carried three billing fields since ADR-0016 — `plan`,
`billingStatus`, `paidUntil` — set by hand by a super admin through
`setVenueBilling`. Until now they were read by exactly one thing: the fleet
console's own tiles.

Nothing else in the system consulted them. Not the boot gate, not the live
eligibility watch, not the venue's own screens. A venue could sit on
`billingStatus: overdue` with `paidUntil` two years behind it and trade exactly
like a venue paid through next December. The console's billing lens, its urgency
ranks and its renewal quick-terms were a private notepad for the operator.

That left a hole neither party could see out of. The super admin knew a
subscription had lapsed; **the venue paying for it did not**, and had no way to
find out. Asking someone to pay while never telling them they owe anything is not
a billing system, it is a to-do list.

The obvious fix — lapse the date, suspend the venue — was already ruled out.
`CONTEXT.md` "Venue billing" states it explicitly: *"an `overdue` venue keeps
running until the SA manually flips `status` to `suspended`; nothing
auto-suspends on non-payment. Avoid: coupling `billingStatus` to `status`
automatically."*

## Decision

**Mirror the billing state down to the venue. Do not enforce it.**

1. The live `venues/{vid}` listener the auth repository already holds publishes
   its whole snapshot to `venueCloudDocProvider`. The billing fields were always
   arriving at the device and being discarded; nothing new is fetched.
2. `venueBillingNoticeProvider` derives a two-tier verdict from that snapshot
   using **the same predicates the fleet console ranks on**
   (`fleetBillingTrouble`, `fleetSubscriptionEnding`, `fleetRenewWarn`), moved to
   `data/services/venue_billing.dart` so both layers can reach them.
3. `VenueBillingBanner` renders it in the shell, gated on
   `Capability.editSettings`, tapping through to WhatsApp with the venue's name
   and id prefilled.
4. `status` remains the only thing that stops a venue trading, flipped only by an
   explicit `setVenueStatus`.

The same commit makes ADR-0016's audit claim true: every mutating callable now
writes a `fleet_audit` record through a single `writeFleetAudit()` helper.

## Consequences

**The money loop closes without coupling.** Super admin sets `paidUntil` → the
venue is warned fourteen days out → the venue messages the super admin → the
super admin extends it in the console. Four steps, each one visible to whoever
has to take it, and not one of them touches the kill switch.

**One definition of "ending".** The predicates are shared rather than copied, for
the same reason the offline-grace countdown reuses a single `staleAfter`: a
console that warns at fourteen days over a venue banner that starts at seven
makes one subscription into two different facts.

**The banner cannot threaten.** Because nothing auto-suspends, copy implying
imminent shutdown would be a lie the code does not tell. It states the term and
offers the way to renew.

**Capability-gated, unlike its neighbour.** `AdminGraceBanner` sits in the same
slot ungated, because "reconnect the wifi" is operational and any staff member
can act on it. A billing notice is commercial and lands badly in front of the
floor, so only `editSettings` sees it.

**`plan` still means nothing.** It is recorded, shown to the operator, and gates
no feature. Entitlements were considered and rejected as a separate, much larger
piece of work; this ADR does not open it.

**A lapsed venue keeps trading, forever, until a human intervenes.** That is the
accepted cost, and it is deliberate. Automatic suspension would put a restaurant's
service at the mercy of a mis-set date, on a system with no payment gateway to
correct it.

## Alternatives rejected

**Auto-suspend after a grace period.** Genuinely end-to-end and needs no human.
Contradicts ADR-0016 and the standing glossary invariant, requires new scheduled
infrastructure, and makes a data-entry slip take a restaurant offline mid-service.

**`plan` as entitlements** (gate table count, zones, KDS by tier). Would make the
field mean something, but needs a limits model and enforcement inside the embedded
server, which today knows nothing about the cloud plan.

**Settings-screen readout, no banner.** Quieter, but nobody visits settings
unprompted, so the fourteen days of notice would be discovered after they expired.

**Mirroring billing into Drift `VenueSettings`** the way ADR-0018 mirrors name
and address. Rejected: billing is cloud state that changes without the venue
acting, not local venue identity, and Firestore's own cache already serves the
snapshot offline.
