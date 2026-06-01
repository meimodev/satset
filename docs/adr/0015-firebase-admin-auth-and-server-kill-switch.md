# Firebase-gated admin auth + admin-bound server lifecycle

**Status:** accepted

SatSet is a LAN-first, offline-capable app whose admin previously signed in against the embedded local server. We are moving **admin** sign-in (only) to **Firebase Authentication** (email/password, project `satset-3a795`), with a Firestore `admins/{uid}` doc (`status: active|suspended|banned`, `name`, `avatarColorHex?`) acting as a **remote terms-of-service kill switch**. The embedded server stays the capability authority: once Firebase confirms identity + eligibility, the app mints the local admin JWT in-process and all admin screens keep talking to the local server as before. Staff PIN auth is untouched and stays fully local/offline.

The local server's running state is now **bound to a valid admin session** — it is killed on admin logout or loss of eligibility, and connected clients cannot reconnect until an admin re-signs-in. The admin session is the venue's on/off switch.

## Considered options

- **Verify Firebase ID token in the shelf server** (rejected) — proper, but the server runs in-process on the admin's own device, so we instead **mint the local JWT in-process** with no token round-trip. Same process, same device, loopback only.
- **Keep capabilities in Firestore / admin tiers from console** (rejected) — leaks capability authority to the cloud. All Firebase admins map to **one shared local admin role**; per-uid local user rows exist only for audit identity.
- **Keep the old local email/password admin login as offline fallback** (rejected) — one admin auth path is clearer; the local email/pw path, its HTTP route, and the seeded admin password are removed.
- **Login-time-only eligibility check** (rejected in favour of a **live Firestore listener**) — a kill switch you can't trigger mid-service isn't one.

## Consequences

- **First admin login requires internet.** The Firebase session then caches, so later restarts tolerate offline operation.
- **Offline dodge is bounded by a staleness guard:** if the listener hasn't confirmed `active` from the server in **7 days**, the server refuses to start until the admin gets online once.
- **Server start is gated on the first Firestore snapshot** (instant from cache offline) so a suspended admin's server is never briefly live.
- **Firestore scope is the admin registry only.** All operational data stays local Drift. Security rules: a signed-in admin may **read only their own doc and never write it** — `status` is changed only via console/Admin SDK, so the kill switch cannot be self-cleared.
- A misfired logout drops every connected waiter; logout warns while live tables exist but still proceeds — the kill is intentional.
