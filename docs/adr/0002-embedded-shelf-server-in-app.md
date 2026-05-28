# ADR-0002 — Single APK runs as embedded shelf server or thin client; Drift is source of truth

**Status:** Accepted — 2026-05-28

## Context

SatSet is a LAN-only restaurant ordering app for small Indonesian venues. Constraints:

- No cloud dependency during service. Internet may be flaky; ordering and KDS must keep working as long as the venue Wi-Fi is up.
- Hardware budget: a handful of Android tablets/phones, no dedicated server box, no managed Postgres, no ops engineer.
- One distributable APK to install on every device — the staff cannot juggle "server build" vs "client build".

We needed a topology that lets one device act as the authority and the rest fan out, with no install-time differentiation.

## Decision

**1. Single APK; the running role is a runtime preference.**

`AppMode` (`domain/models/app_mode.dart`) is `server` or `client`, chosen on the `ModeSelectScreen` and persisted by `PrefsService`. The router redirect logic dispatches the post-login home off this preference (`/venue` for server, `/tables` for client). Either role can be re-selected on a fresh install without rebuilding.

**2. Server mode embeds shelf in-process.**

`lib/server/server.dart::ServerRuntime.boot()` constructs the entire backend inside the Flutter process:

- `AppDatabase.open()` (Drift / SQLite) under app-support storage.
- `ServerTls.loadOrCreate()` for a self-signed leaf cert pinned by clients (see ADR-0003).
- `ServerAuth` (PIN + JWT, see ADR-0004).
- `WsHub` for authenticated WebSocket fanout.
- `SatSetAdvertiser` (bonsoir) broadcasting `_satset._tcp`.
- `shelf_io.serve(..., securityContext: tls.context)` mounts a single Router with twelve subroutes (`auth`, `menu`, `tables`, `tickets`, `reservations`, `printers`, `devices`, `kds`, `reports`, `health`, `server`, `venue_settings`), plus `/pair/claim`, `/pair/auto-claim`, and `/ws`.

Bind address is `InternetAddress.anyIPv4` on port `7443`. The server tablet is the host: it serves loopback to its own client UI and LAN traffic to peers simultaneously. There is no separate desktop runtime, no Docker image, no headless build.

**3. Drift / SQLite on the server device is the single source of truth.**

State that survives a restart — tables, tickets, menu, reservations, staff, audit, sessions, pair tokens, devices, printers — lives in the server's Drift database. Clients keep no persistent domain caches: their repositories bootstrap from HTTP and stay in sync via WebSocket events (`WsEventTypes.tableUpdated`, `.tableCreated`, `.ticketAdvanced`, etc). Restart a client → it re-bootstraps from `/tables`, `/menu`, `/tickets` and re-subscribes to `/ws`.

In-memory `DummyData` is gone. Seeding happens once at server first boot via `lib/server/db/seed.dart::seedIfEmpty(db)`.

**4. The server tablet runs the client UI against itself over loopback.**

`apiConfigProvider` on the server device points at `https://127.0.0.1:7443`. The same Riverpod repositories that clients use drive the server's own waiter/floor screens. `ApiClient.isLoopbackHost` relaxes TLS fingerprint pinning on loopback (the runtime trusts its own cert). There is no in-process shortcut — server-side UI calls go through the same HTTP/WS surface as remote clients, so the contract is exercised on every save.

## Consequences

**Positive:**
- Deploying the venue = install the APK on every device, pick Server on one, Client on the rest, scan the QR. No keys, no servers, no DNS.
- The HTTP/WS contract is exercised continuously on the server device itself; "works for me but not for clients" failure modes are nearly impossible.
- Drift on the server device means a SQLite file is the entire venue's persistent state — trivially backed up, restored, or copied to a new tablet.
- WS fanout from a single in-process hub keeps eventual consistency cheap: the writer broadcasts immediately after the DB write, every UI (including the writer's own) converges from the same event stream.
- Restart of the server (`ServerRuntime.restart`) rebinds the listener and re-advertises mDNS without dropping the DB or auth state; client `wsClient` backoff reconnects within ~1s.

**Negative:**
- If the server tablet dies mid-service, the venue is offline until another device is re-paired as server. There is no automatic failover. Mitigation: nightly DB export to durable storage is the user's responsibility; a "promote this client to server" workflow is not yet built.
- Single-writer SQLite caps throughput. Acceptable for ≤30-device venues; would need rework for chain deployments.
- Loopback-relaxed pinning means a misconfigured server pointing `apiConfigProvider` at a non-loopback host would silently bypass pinning. Guarded by `ApiClient._buildClient` which `throw`s `StateError` when `trustedFingerprint` is empty on a non-loopback host.
- Hot UI changes on the server APK require restarting the whole process, which also restarts the embedded server. `ServerRuntime.restart()` exists for in-app rebind without DB teardown; full process restart is a heavier event.
- The server device's UI competes with the server runtime for CPU. On the lowest-end target (mid-range Android tablet) shelf request latency stays under 30ms p95 during service, but heavy admin operations (reports, bulk menu edits) are noticeable.

## Alternatives considered

- **Two APKs (server build + client build).** Rejected: doubles release pipeline complexity, doubles staff confusion at install time, and prevents the loopback-self-test that catches contract drift.
- **Headless server on a dedicated mini-PC.** Rejected: adds a SKU to the BOM, an OS to maintain, and a power/Wi-Fi failure domain the staff cannot debug. Single-tablet ownership is simpler.
- **Cloud backend (Firebase / Supabase) with offline cache.** Rejected: violates the "service keeps working when internet is down" constraint, and adds a per-seat monthly cost the target venues will not pay.
- **CRDT / peer-to-peer state without a designated server.** Rejected: conflict resolution on table state (seat, lock, ticket fire) is hard to make intuitive for staff; "the device by the POS is the boss" mental model is easier than "any device is authoritative, sometimes."
- **In-process shortcut for server-side UI (skip HTTP for own calls).** Rejected: removes the continuous self-test; would have to maintain two code paths to the same data.
