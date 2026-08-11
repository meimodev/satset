# ADR-0099 — An admin sign-in has no offline path, though a boot does

Status: accepted
Date: 2026-08-11

## Context

This app's whole promise is that it works when the network does not. A waiter
signs in with a PIN against a server on the same Wi-Fi; an order written with
no WAN is an intent that replays later
([ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md)); a session
survives a restart from the cached `/auth/me` when the host is unreachable.

An admin sign-in is the one door that does not work that way. It goes to
Firebase for the credential, to Firestore for the profile, to eligibility and to
the venue's status — four WAN round trips, before any of the local machinery
runs. Bounding them ([ADR-0098](0098-an-admission-is-one-staged-gauntlet-with-one-outcome.md))
made the failure quick and legible. It did not make it optional.

Writing that down matters because the *rest* of the admin story is already
offline-tolerant, and the resemblance is misleading. A venue that has already
booted keeps trading through a WAN outage: the eligibility watch tolerates a
dropped listener, the cached profile answers a cache-first read, and every
capability check is local. Only the door is online.

## Decision

**An admin sign-in requires the WAN, and says so.** No cached-credential path,
no "trust the last verdict" grace, no local admin password. A WAN failure ends
as `AdmissionUnreachable`, which names the situation rather than implying the
password was wrong.

**A boot is not a sign-in.** A device that has already been admitted restores
from its stored token and, when the host cannot be reached, from the cached
`/auth/me` — that path is deliberately generous, because the alternative is
deleting a valid JWT over a network blip and stranding someone on the sign-in
screen they cannot reach. The distinction is *has this device been admitted
before*, and it is the whole reason the two behave differently.

**The eligibility kill switch stays two-sided and stays online-authoritative.**
See [ADR-0015](0015-firebase-admin-auth-and-server-kill-switch.md). A venue
that loses its licence must lose the server, and a verdict that can be outrun by
pulling a network cable is not a kill switch.

## Considered options

**Cache the last admission verdict with a grace window.** The obvious ask, and
the one a venue will make the first time it happens at 18:00 on a Friday.
Rejected for now: a grace window is exactly the hole the kill switch exists to
close, and the two cannot both be honoured without deciding whose loss is
cheaper. That decision needs a real incident behind it, not a guess.

**A local break-glass admin password.** Rejected: a second credential that
Firebase has never seen is a second thing to leak, rotate and audit, and the
device it protects is the one holding the venue's takings.

**Let the staff PIN reach admin surfaces when the WAN is down.** Rejected: it
collapses the staff/admin separation the sign-in screen is built around, in the
exact circumstance where nobody can check the result.

## Consequences

A venue with a dead internet connection and a device that has never been
admitted cannot open. The mitigation is operational, not technical: admit each
device once while the connection is up. The seeded and paired devices in a
running venue are unaffected.

The failure is now fast (25s worst case, 8s per stage) and it is named. Before
this, the same situation produced an indefinite spinner, which taught operators
that the app was broken rather than that the internet was.

If the grace-window question returns with an incident attached, this is the ADR
to supersede, and the decision it needs is about the kill switch — not about
caching.
