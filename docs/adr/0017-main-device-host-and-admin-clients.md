# Main Device as the single venue server host; admins are interchangeable operators

**Status:** accepted

**Amends [0016](0016-fleet-superadmin-cloud-control-plane.md):** ADR-0016 made the relationship *one venue → many admins* but left the local server per-device and uncoordinated. This ADR defines how many admins share **one** running venue without splitting the data.

## Context

The embedded shelf server (ADR-0002) runs in-process on a device in **Server mode** and owns a **per-device** Drift DB. There is no `venueId` in the server and no coordination between devices. ADR-0016 then declared *one venue → many admins*. Those two facts collide:

- Each admin device in Server mode boots **its own** server + **its own** DB.
- mDNS advertises **both** → two QR codes, two pair targets; clients pair to whichever they scan.
- Orders/tables/menu on host A are invisible to clients on host B; each host seeds its own generic data → divergent menus/staff.
- If the host device dies and a different admin starts Server mode, it comes up on a **different, possibly empty** DB → the venue's live data is gone.

Root cause: **per-device DB + interchangeable admins = no stable home for venue data.** The KDS already assumes a singular **"Main Device"**; restaurants run one till/host with interchangeable operators.

## Decision

**Exactly one device per venue hosts the server (the Main Device); all other admins join it as authenticated admin-clients.** The host's Drift DB is the single authoritative venue DB.

- **`venueId` on the server.** The host's `venueId` (from the signed-in admin's Firebase record) is passed into `ServerRuntime.boot` and advertised in the mDNS TXT record.
- **Single-host guard.** Before starting a server, a device browses mDNS for an existing SatSet service whose TXT `venueId` matches its own (short discovery window, ~2–3 s). If one is found it does **not** start a second server; it offers to **join that host as an admin-client** instead. Only when none is found does it boot as host.
- **Admin-client trust (offline-capable).** A joining admin is already Firebase-signed-in and knows its own `uid`, `role`, `venueId`. SA-created admin accounts carry Firebase **custom claims** `{role, venueId}` (set by the Fleet-console Cloud Function on create/edit; one-time backfill for existing accounts). The joining client presents its Firebase **ID token**; the host verifies the RS256 signature against **cached Google public certs** (`dart_jsonwebtoken`/`basic_utils`), checks `aud == project` + `venueId == host.venueId` + `role ∈ {admin, super}`, then issues an **admin local JWT**. Capability authority stays local (ADR-0004): the host owns the admin role row; the token only proves *eligibility to be an admin of this venue*.
- **Seeding only on the host.** The first-run generic-seed prompt (zones/tables/menu/2 staff) fires only on the Main Device against its own empty DB. Admin-clients never seed.

## Considered options

- **Designated Main Device + admin-clients (chosen)** — one authoritative DB; other admins operate concurrently as clients. Solves divergence at the cost of building admin-over-client auth and a Firebase-token verifier.
- **One-at-a-time, no admin-clients** (rejected) — guard blocks a second server; the second admin simply cannot do admin work while the host is up, and a dead host still yields a fresh empty DB. Weaker product.
- **Cloud-synced venue data** (rejected) — every device syncs through Firestore; removes the single-host need but breaks the LAN-first offline design (ADR-0002/0003) and is a major re-architecture.
- **Pairing-trust for admin-clients** (rejected) — whoever completes the admin QR pair is granted admin; no cryptographic proof, trivially escalatable. Unacceptable for admin privilege.
- **Host fetches admin roster from Firestore** (rejected as primary) — needs the host online to refresh and still needs the client to prove its `uid`; the ID-token + claims path is self-contained and offline-capable after first cert fetch.

## Consequences

- **New trust surface on the host:** an offline RS256 verifier over Firebase ID tokens with cached Google certs, plus `venueId`/`role`/`aud` checks. Cert staleness while long-offline is a known edge — reuse the existing 7-day staleness posture (ADR-0015/0016) for admin-client admission if certs cannot be refreshed.
- **Cloud Function change:** admin create/edit must set custom claims `{role, venueId}`; existing accounts need a one-time claim backfill. Claims and the Firestore admin doc must stay in sync.
- **mDNS TXT carries `venueId`** (ADR-0003); the browser path gains a same-venue collision check and a "join as client" branch.
- **Admin screens must work in client mode** for admin-clients — previously admin UI implied Server mode (ADR-0015: "Firebase only on Server-mode device"). Admin-clients are Firebase-signed-in *and* paired clients; the kill-switch/eligibility listener still runs on the host, clients ride its JWT.
- **Single point of data:** if the Main Device is lost, the venue DB is lost (no cross-device replication). Backup/restore of the host DB is now the meaningful continuity story — out of scope here, flagged.
- **Greenfield:** no live venues, so no migration of existing multi-server installs is needed.
