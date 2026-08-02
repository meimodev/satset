# ADR-0077 — One admin, one device

**Status:** Accepted
**Date:** 2026-08-01
**Supersedes:** [ADR-0017](0017-main-device-host-and-admin-clients.md) (its multi-admin premise and the admin-client half)
**Amends:** [ADR-0016](0016-fleet-superadmin-cloud-control-plane.md) (venue account management)

## Context

ADR-0017 answered a real question — a venue's data lives in one device's Drift DB,
so two Server-mode devices for one venue is split-brain — and answered it in two
parts. The first part is the **Main Device guard**: a device about to boot a server
browses mDNS for an existing host advertising the same `venueId` and refuses to
start a rival. That part was correct and stays.

The second part was the escape hatch. Having refused, the device offered to join
the existing host as an **admin-client**: it presented its Firebase ID token, the
host verified the RS256 signature offline against cached Google certs, checked
`aud`, `venueId` and `role ∈ {admin, super}` from custom claims, and issued a local
admin JWT. That machinery existed because ADR-0016 had just made a venue hold
**many** admins, and the alternative — several admins each hosting their own
server — was the split-brain we had set out to prevent.

The many-admins premise is what has changed. In practice a venue has one operator.
The plural was never a requirement anyone asked for; it fell out of the fleet
console's data model (`admins/{uid}` carries a `venueId`, so nothing stopped two
documents carrying the same one) and the admin-client design was built to survive
it. Meanwhile the plural cost real surface: an offline RS256 verifier, a
Firebase-token door into the local server sitting outside the bearer-auth
middleware, a custom-claims scheme, and a one-time backfill callable to stamp
claims onto accounts that predated them.

Three separate facts made the plural cheaper to remove than to keep.

**Nothing else reads the claims.** `firestore.rules` resolves every decision by
reading the `admins/{uid}` *document* — `me().role`, `me().venueId`,
`get(...).data.role == 'super'`. Not one rule reads `request.auth.token`. The
custom claims had exactly one consumer in the entire system: the host admitting an
admin-client.

**The super arm of the gate was already dead.** `/auth/admin` accepted
`role ∈ {admin, super}`, but a super admin never pairs, never runs a local server
and never touches Drift — it diverts to the fleet console at login. The `super`
branch could not be reached by any flow that exists.

**The unauthenticated door is a standing cost.** `/auth/admin` sits in the auth
middleware's skip set by necessity — a joining device has no local bearer yet — so
it is the one route on the LAN server that answers before authentication. A route
in that position earns its keep by being used.

## Decision

**A venue has exactly one active admin, on exactly one device.** Admin-client is
retired.

**The cap counts `active`, not documents.** `createAdmin` refuses when the venue
already holds an `admins/{uid}` doc with `role == 'admin'` and `status == 'active'`;
`setAdminStatus` enforces the same rule on the other door into `active`, so
reactivating a suspended admin cannot walk a venue back to two. Handing a venue to
a new operator is therefore **suspend the old, create the new** — no window where
the venue has nobody, and the outgoing account's document survives for the audit
trail rather than being deleted to make room.

**Owners stay uncapped.** An owner is a read-only cloud report viewer held
powerless on the floor by four separate exclusions (ADR-0036). Plurality costs
nothing, and two investors watching one restaurant's numbers is ordinary.

**A second device is refused, not admitted.** The mDNS guard survives and now
terminates rather than diverting: finding a host for this `venueId` raises
`AuthState.hostOccupied` carrying that host's mDNS label. The Firebase session is
deliberately **left signed in** — the condition is transient and self-clearing, and
charging a full password re-entry for a state that resolves when someone switches
off a tablet is a tax on the person standing between both devices. The block screen
names the host, offers **Coba lagi**, and carries the second cause too, because the
device cannot distinguish them: an account that is not this venue's admin at all
will sit there forever, and its copy must point at the operator.

**Existing multi-admin venues are corrected by hand.** Nothing is auto-suspended.
The venue editor warns when it renders two or more active admins and the operator
picks which survives — only they know which device holds the venue's database, and
a rule like "oldest `createdAt` wins" would pick by a fact with no product meaning.

**The admin role is immutable from the venue's staff screen.** ADR-0017 blocked
*granting* `manageStaff` and said nothing about editing a role that already had
it, which left the worse edit open: stripping `editSettings` or `viewReports` off
the admin role locks the venue's only admin out of the screens that could put them
back, and since admin is Firebase-only there is no second admin role to repair it
from. `PATCH /roles/<id>` and `DELETE /roles/<id>` now refuse outright on any role
carrying `manageStaff` — capabilities, name and colour alike. The staff screen
matches: the role row keeps its badge and its counts but loses colour, rename and
delete, its permission-matrix cells are rendered as non-controls rather than
disabled ones, and both carry `Dikelola pengelola`. The old
"don't revoke the last `manageStaff` holder" count guard is gone from the role
path — unreachable once the role cannot be edited, and a count was always a weaker
promise than immutability. The equivalent guard on *users* is untouched.

**What is deleted:** the `/auth/admin` route and its skip-set entry,
`firebase_token_verifier.dart` in full, `_establishAdminClientSession`, and the
`backfillAdminClaims` callable with its fleet-console entry.

**What is kept, deliberately consumerless:** `setCustomUserClaims` in
`createAdmin`. Claims are the one thing that cannot be reconstructed cheaply after
the fact — `backfillAdminClaims` had to exist for precisely the gap that dropping
the line would reopen. One call, no maintenance, and a reversal of this ADR finds
nothing to backfill.

## Consequences

**A single-person venue loses reach, and this is the real cost.** The previous
answer to "I want to check today's takings from my phone" was to sign in there and
join as an admin-client. That answer is gone. The remaining one is an **owner**
account — but Firebase Auth is one account per email, so the same human needs a
second email address to watch their own numbers. Owner and admin are frequently the
same person in a small restaurant, and the fleet operator will absorb that
explanation over the phone. Accepted with open eyes; it is the price of the
guarantee that a venue's data has exactly one home.

**The local server's attack surface shrinks by one pre-auth route.** `/auth/login`
and the pairing endpoints remain the only doors answering before a bearer token.

**Firestore serves the cap query by index merging.** Three equality filters
(`venueId`, `role`, `status`) need no composite index.

**A venue can now be momentarily admin-less on purpose.** Suspending the outgoing
admin before creating the incoming one leaves a real gap in which the server will
not boot. That is the intended shape — the alternative was a `replaceAdmin`
callable maintained year-round for a transition that happens about once a venue's
lifetime.

## Alternatives considered

**Cap the fleet UI only, keep admin-client.** One admin *identity* signed in on
several devices; all the machinery survives. Rejected: it keeps every line of the
cost above to serve a case the product does not have, and it leaves a pre-auth
route alive for a flow nobody exercises.

**Takeover — the second device boots and the first dies.** Rejected on sight: that
is split-brain with extra steps, and it strands a Drift DB on the losing device.

**Auto-suspend surplus admins by `createdAt`.** Rejected: the oldest account is not
necessarily the one on the device holding the data, and the failure is silent and
irreversible-feeling to whoever gets suspended.

**Sign the refused device out (the existing rejection pattern).** Rejected: the
suspended-venue and no-venue rejections sign out because those states are durable.
"Another device is hosting" clears itself, and re-entry should not cost a password.
