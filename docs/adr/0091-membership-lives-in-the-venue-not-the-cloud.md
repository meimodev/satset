# ADR-0091 — Membership lives in the venue, not the cloud

Status: accepted
Date: 2026-08-09

## Context

SatSet has a cloud. [ADR-0074](0074-venue-subscription-notice-without-enforcement.md)
and [ADR-0076](0076-two-plans-and-a-subscription-that-cuts-off.md) put venue
billing there, the [[Fleet console]] runs there, the release gate reads from
there. So the obvious home for a **[[Pelanggan (member)]]** looks like the
cloud too: one guest could then be recognised at every venue in the fleet, and
an owner with two outlets would not keep two directories.

That is a genuinely attractive feature and it is the wrong trade for this app.

The thing SatSet promises is that a restaurant keeps trading when the internet
does not — the LAN server, the mDNS pairing, the offline
[[Antrean kirim (send queue)|send queue]] ([ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md))
all exist to buy that. A cloud-resident member directory spends it back. The
lookup sits in the **cashier's settlement path**, which is the least
interruptible moment in the venue: a guest is standing at the till holding a
card, and the answer to "am I a member" cannot be "the ISP is down."

The half-measures are worse than either end. A cloud directory with a local
read-through cache has to decide what a stale points balance is allowed to do —
and the only safe answer is "refuse to redeem", which is the same outage,
arriving later and less honestly. A local directory that syncs upward has to
resolve two venues spending the same points, which is a distributed-ledger
problem this app has carefully never had.

## Decision

A member, their [[Poin]] ledger and their [[Kartu stempel (punch card)]]
progress live **in the venue's own Drift database**, alongside visits and
receipts. There is no cloud member record, no sync, no cross-venue identity.
A guest who is a member at two outlets of the same brand is two members.

The cloud keeps doing exactly what it does today: venue billing, super admin,
release gate. It learns nothing about guests.

## Consequences

Membership works at 100% of the moments settlement works, which is the point.
No feature in the flow can ever be blocked on connectivity, so there is no
degraded mode to design, no cache staleness rule, and no "member data may be
out of date" copy anywhere in the UI.

An owner with multiple outlets gets multiple directories. That is the accepted
cost, and it is paid by the small number of multi-outlet venues rather than by
every venue's till.

Cross-venue membership stays available as a later decision. It would be an
additive cloud projection *on top of* venue-local records — an export upward,
not a relocation — and it needs its own ADR because the points-spending
conflict is the entire problem and none of it is solved here.

Personal data (guest names, phone numbers) never leaves the venue's own
hardware, which is a smaller compliance surface than the alternative and worth
naming as a benefit rather than an accident.
