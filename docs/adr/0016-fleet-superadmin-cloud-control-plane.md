# Fleet super-admin cloud control plane

**Status:** accepted

**Amends [0015](0015-firebase-admin-auth-and-server-kill-switch.md):** relocates the terms-of-service kill switch from the admin doc to a new venue doc, and adds a fleet operator above the venue admin.

SatSet is a LAN-first, Android-only restaurant app: one APK runs in **Server** or **Client** mode, and every operational screen is hard-gated on being paired to a local server (`apiConfigProvider != null`). We are adding a **super admin** — a fleet operator who manages *many* venues and their admins across the whole customer base — without giving up the LAN-first nature of the venue app.

A super admin has **no venue, no local server, no pairing, no Drift**. It is a pure cloud control surface that talks only to Firebase Auth, Firestore, and Cloud Functions. It is **not** a new mode-select tile: it shares the ordinary admin Firebase login, and is recognised purely by `admins/{uid}.role == 'super'`. On login the app reads the signed-in admin doc; a `super` role **diverts to the Fleet console** (`/fleet`), bypassing the pair gate that traps every other route at `/pin`.

To support this, **venue becomes a first-class cloud entity** `venues/{vid}` (distinct from the per-device local `VenueSettings` in Drift), carrying only fleet-level fields: `name`, `status` (the kill switch), `plan`, `billingStatus`, `paidUntil`, `lastSeenAt`. The relationship is **one venue → many admins** (several managers share a restaurant); each admin carries `venueId`. Because the venue is now the shared unit, the **kill switch moves from `admins/{uid}.status` to `venues/{vid}.status`**. The admin doc keeps its own `status` as a per-operator ban. A Server-mode boot now requires **both** `venue.status == active` AND `admin.status == active`, and the live kill-switch listener watches `venues/{vid}` (resolved via the admin's `venueId`).

The fleet console **reads** Firestore directly (gated by an `isSuper()` rule that `get()`s the requester's own admin doc) and performs **all mutations through Cloud Functions callables** (Admin SDK, server-enforced authz): create/disable/delete admin accounts, create/edit venues, flip a venue's kill switch, set billing flags. The Server device writes a `lastSeenAt` **heartbeat** every ~60s via a **field-scoped** rule (a normal admin may write *only* `lastSeenAt` on its own venue), driving the offline-duration monitor.

## Considered options

- **Separate Flutter app / build target for the console** (rejected) — cleaner isolation, but two artifacts and duplicated Firebase wiring; the single-APK + role-divert keeps one codebase and one login surface.
- **Console-only fleet management** (rejected — i.e. keep provisioning/kill in the Firebase console as ADR-0015 had it) — no new backend, but the operator wanted in-app self-serve CRUD, billing, and monitoring; a console is not a product surface for them.
- **Super-admin as a local Drift capability** (rejected) — fleet authority is inherently cloud and cross-venue; it has no local server to host a capability. Local `Roles`/capabilities stay venue-internal and untouched.
- **Secondary-FirebaseApp trick for account creation, no backend** (rejected) — creates Auth users from the pure client without disturbing the SA session, but cannot delete/disable other users or reset their passwords, and puts privileged logic on the client. Cloud Functions give the full credential lifecycle and server-side authz.
- **Direct client Firestore writes for mutations** (rejected) — would force broad write rules on the admins/venues collections; routing mutations through callables keeps client write rules locked to the heartbeat field only.
- **Per-venue kill stays at admin level (1:1)** (rejected) — would mean one admin per venue; the real model is many managers per venue, so the kill, billing, and offline must be per-venue.
- **Payment-gateway billing** (deferred) — billing is manual SA-set flags for now; a real gateway + webhooks is a separate, larger effort.

## Consequences

- **A LAN-first app gains a cloud control plane.** New backend surface: `functions/` (Admin SDK), requiring the Firebase **Blaze** plan and a deploy pipeline the project did not previously have.
- **The kill switch relocates** (amends ADR-0015): listeners, boot gates, and `FirebaseAdminService.evaluateForBoot`/`watch` now resolve `admin.venueId → venues/{vid}` and gate on venue **and** admin status. The 7-day staleness guard now keys off the venue confirmation.
- **Greenfield cutover.** No live customers yet, so existing `admins` docs are wiped and reseeded into the new shape (`role`, `venueId` + a `venues` collection); no backfill/migration path is built. A Server login whose admin lacks a `venueId` is defensively blocked.
- **Super admin is online-only** — no offline tolerance, no local server, no Drift; if it cannot reach Firebase it cannot operate.
- **Billing is decoupled from the kill switch** — an `overdue` venue keeps running until the SA manually suspends it; nothing auto-kills on non-payment.
- **No fleet audit trail** for SA actions yet (greenfield); Firestore console history is the only record. Revisit if the fleet grows beyond a single trusted operator.
- **Security-rule cost:** `isSuper()` performs a `get()` on the requester's admin doc per evaluation — an extra read per fleet query, accepted for a low-traffic console.
