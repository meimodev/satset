# Owner: cloud read-only report snapshot, host-published

**Status:** accepted

**Amends [0016](0016-fleet-superadmin-cloud-control-plane.md):** adds a third cloud role (`owner`) beside `admin`/`super` on the same `admins` collection and login-divert machinery, and adds two report collections the fleet model did not have.

## Context

SatSet is LAN-first: every operational screen — including Admin → Reports — is hard-gated on `apiConfigProvider != null` (paired to the local server), and reports are computed on demand by the embedded shelf server from the host's Drift DB (`/reports/snapshot`). A venue stakeholder who wants to **watch activity from outside the venue** can satisfy none of that: no LAN, no pairing, no server to query.

The existing local `Role`/`Capability` system (`Capability.viewReports`) is the wrong tool — it is venue-internal and only meaningful behind the pair gate, which an off-site viewer can never pass. But the project already has a cloud control plane (ADR-0016): Firebase Auth, a role-tagged `admins/{uid}` collection, a login-time role divert (`super` → `/fleet` bypassing the pair gate), and a host that is already Firebase-authenticated and already writes a `lastSeenAt` heartbeat to its own `venues/{vid}` through a field-scoped rule. The off-site report viewer is a natural fit for that plane, not the local one.

The data does not need to be real-time — a periodic snapshot is enough — and the viewer must gain **no** floor power.

## Decision

**Add an `owner` cloud role that reads a host-published report snapshot from Firestore; it never pairs, never runs a server, never touches Drift, and gains no floor capability.**

- **Identity.** `admins/{uid}.role == 'owner'`, bound to one `venueId`, with the same `{role, venueId}` custom claim admins carry. Owners live in the **same `admins` collection** (role-tagged principals — not a new collection). `createAdmin` is extended to accept `role ∈ {admin, owner}`; the super admin creates/manages owners in the Fleet console venue editor. At Firebase login an `owner` **diverts to `/owner`** (a read-only view) *before* the hard pair gate, mirroring the `super` → `/fleet` bypass.
- **Publish path (host → cloud).** The host computes the aggregate report it already serves (`/reports/snapshot`, KB-scale pre-formatted JSON) for a **fixed range set `{today, 7d}`** and writes it to a **separate** doc `reports/{vid}` with a `generatedAt` stamp, on a **fixed ~30-min interval** plus on server start/stop. The write is a **direct client write** gated by a field-scoped rule mirroring the heartbeat: a normal admin (the host) may write `reports/{vid}` **only** on its own `venueId`. Kept off `venues/{vid}` so the Fleet console's venue reads don't drag the payload.
- **Manual refresh (cloud-mediated command).** The owner cannot reach the host, so refresh is a command, not a pull: the owner writes `report_requests/{vid}.requestedAt = serverTimestamp()` (a tiny **command** doc, owner-write that field only); the host holds a live listener on it and, on a `requestedAt` newer than its last publish, recomputes and rewrites `reports/{vid}` (the **state** doc). Command and state are **separate docs** so rules stay clean and the host's own republish never re-triggers its listener. If the host is offline the request waits and the view shows stale `generatedAt` + a "refresh requested, venue may be offline" state (derived from `generatedAt` not advancing — **no hanging spinner**). The button is debounced ~30s; the host ignores an already-satisfied `requestedAt`.
- **Exclusions (floor-powerless).** The [admin-client](0017-main-device-host-and-admin-clients.md) ID-token gate stays `role ∈ {admin, super}` so an owner can't join a host as a client; server-mode boot rejects owner; `isSuper()` is unchanged so owner can't read the fleet; the owner's **entire** Firestore footprint is read-`reports/{vid}` + write-`report_requests/{vid}.requestedAt`. Freshness/offline is derived from `generatedAt` alone, so the owner needs no `venues/{vid}` read.

## Considered options

- **Cloud role reading a pushed snapshot (chosen)** — reuses the ADR-0016 login-divert, the role-tagged `admins` collection, the host's existing authenticated heartbeat write path, and the report JSON the screen already produces. Costs: report data is now duplicated into Firestore and is stale between publishes; refresh is an indirect command round-trip.
- **Local Drift `owner` role with `viewReports`** (rejected) — would never satisfy the hard pair gate; an off-site device has no server to authenticate against or query.
- **Web page reading Firestore** (rejected) — no install for the owner, but a second artifact with duplicated Firebase-web auth wiring and new hosting; ADR-0016 already rejected a separate build target for the same reason, and the guest SPA (ADR-0029) is unauthenticated and LAN-only, not reusable.
- **Owner connects live to the host (VPN / port-forward / relay)** (rejected) — real-time and no duplication, but demands network plumbing every restaurant would have to configure, and exposes the LAN server to the internet. The requirement explicitly does not need real-time.
- **Cloud Function computes the report** (rejected) — the function has no access to the host's Drift DB (the host is the only holder of venue data), so it cannot compute anything; it could only relay, which the direct write already does without a function.
- **Snapshot on `venues/{vid}`, refresh as one shared doc** (rejected) — bloats every Fleet console venue read with the report payload, and a single read/refresh doc forces per-field role discrimination in rules and makes the host's republish re-trigger its own listener.
- **Manual refresh as a plain cloud re-fetch (no host recompute)** (rejected) — trivial, but "refresh" would never produce data newer than the last 30-min publish, defeating the point of the button.
- **Rename `admins` → `principals`/`accounts`** (rejected) — accurate, but churns rules, functions, claims, and ADR-0016 language for cosmetics; the role tag already disambiguates.

## Consequences

- **A LAN-first app now mirrors a derived report copy into the cloud.** New collections `reports/{vid}` (host-written state) and `report_requests/{vid}` (owner-written command), new security rules, and a host publish loop + refresh listener riding the Firebase lifecycle alongside the heartbeat.
- **Owner data is stale by design** — accurate only as of `generatedAt` (≤ ~30 min old, or older if the host is offline). The view always shows freshness; it never implies live numbers.
- **No filters off-site.** The on-site report's server/zone/category filters need a live server; the owner sees the host's unfiltered `{today, 7d}` publish only — no arbitrary date-picking.
- **No proof photos off-site (deliberate).** Non-cash [[proof photo]] bytes are LAN-only pinned blobs (ADR-0025) and never ride the snapshot; the owner sees every payment's method/amount/cashier/time and a `hasPhoto` flag, with a placeholder noting "bukti foto tersedia di perangkat venue". The fraud-audit (verifying a tender's image) stays where the auditor is — on-site. Hauling audit-grade JPEGs over the cloud (Firebase Storage upload loop, lifecycle, rules) was rejected as a heavy subsystem for a numbers-monitoring role; if the owner spots a suspicious non-cash figure, the row data names which payment for the on-site admin to pull up.
- **The `admins` collection holds non-admins.** An `owner` doc lives there role-tagged and **counts toward the venue-delete guard** (a venue with an owner attached can't be deleted); the venue editor filters owners into their own sub-list.
- **Owner is online-only and floor-powerless** — like the super admin it has no offline tolerance, no server, no Drift; unlike the super admin it sees exactly one venue's one report doc and can perform no mutation but a refresh request.
- **Heartbeat rule precedent widens by one doc.** A normal admin can now write `reports/{vid}` (own venue) in addition to `lastSeenAt`; both stay pinned to `request.auth`'s own `venueId`, so neither can reopen a suspended venue or write another venue.
- **No owner audit trail** for refresh requests beyond the `requestedAt` stamp; acceptable for a read-only viewer.
