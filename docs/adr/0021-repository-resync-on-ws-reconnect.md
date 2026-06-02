# LAN repositories full-resync on every WebSocket (re)connect

**Status:** accepted

## Context

Each list repository (`tables`, `zones`, `staff`, `menu`, …) bootstraps once
by `GET`-ing its collection from the [[Main Device]] over the LAN, then keeps
state live by applying **incremental** `*.created` / `*.updated` / `*.deleted`
WS events. The repository instance is keyed on `apiConfigProvider`, so it is
constructed the moment a loopback/LAN `ApiConfig` is published.

On the Server-mode **host**, that publish happens during server boot
(`mode_select_view_model`), and `AppShell` immediately watches
`totalReadyCountProvider` → `tablesProvider`, so the tables repo's bootstrap
`GET /tables` can fire **before the admin token is written** (401) or **before
first-run [[Generic seed (first-run sample data)|seeding]]** populated the DB
(`200 n=0`). Either way the initial list comes back empty.

With purely incremental WS handlers there is **no recovery**: the list can only
*accrete* rows one mutation at a time. The observed symptom — the host's floor
grid stays empty until a staff device touches a table, at which point that one
table pops in via `tableUpdated`, and a full app restart fixes it (the restart's
`GET` runs after auth/seed). Menu never showed the bug because it already
full-refetches on its coarse `menuUpdated` event; tables/zones/staff had no
equivalent. The same class of gap also drops any event a client misses while
its socket is down.

## Decision

**`WsClient` emits a client-internal `connected` event on its own event stream
every time the socket reaches `open` (first connect AND every reconnect), and
list repositories full-resync (re-`GET` the collection, replace state) on it.**

- New synthetic type `WsEventTypes.connected = 'local.connected'`. The server
  never sends it; `WsClient` pushes it onto `events` right after `channel.ready`
  flips `connState` to `open`. Repositories that own a list handle it like any
  other event — no separate `connState` listener / `ValueNotifier` lifecycle to
  manage.
- Each such repo extracts its bootstrap fetch into a `_refetch()` and a guarded
  `_resync()` (skips if one is already in flight; never throws — a transient
  failure simply waits for the next connect). The WS subscription is wired
  **unconditionally**, even when the bootstrap `GET` failed, because the
  `connected` resync is the recovery path.
- Because the WS only reaches `open` once authenticated
  (`wsConnStateProvider` gates the socket on a valid bearer), the first
  `connected` after an admin signs in re-pulls with the token present — so this
  also closes the login-time 401 race for free, without reordering boot.
- Applied to `tables` and `zones` now (the visibly-broken and same-shaped
  latent case); `staff` and the reservation list are candidates to follow.
  `menu` already had this behaviour via `menuUpdated` and is unchanged.

## Considered options

- **`connected` synthetic event + resync (chosen)** — reuses the one channel
  repos already consume, so the recovery hook is uniform and testable; no
  `ValueNotifier` add/removeListener ordering against `WsClient.dispose`. Cost:
  a small client-only event type that isn't a real server message.
- **Repos listen to `WsClient.connState` directly** (rejected) — same effect
  but every repo must add/remove a listener and reason about the notifier being
  disposed by the provider teardown; more lifecycle surface for no gain.
- **Refetch on auth-success only** (rejected) — invalidate the data providers
  when `authStateProvider` becomes authenticated. Fixes the login race but not
  the "missed events while the socket was down" class, and leaves each repo
  fragile to any other transient empty bootstrap.
- **Fix boot ordering** (publish `ApiConfig` only after the admin token lands)
  (rejected as the sole fix) — removes one trigger but leaves repos with no
  recovery path for future transients (reconnects, seed-before-fetch). Cheap to
  also do later, but not load-bearing once resync exists.
- **Make seeding broadcast + invalidate harder** (rejected) — the seed endpoint
  already broadcasts per-entity events and `genericSeedController.seed()`
  already invalidates the repos; the bug survives that because the *bootstrap*
  itself is the lossy moment. Resync addresses the general case.

## Consequences

- Every (re)connect costs one `GET` per resync-enabled repo. These lists are
  small and the resync is guarded against overlap, so the cost is negligible
  against the correctness win; reconnects are infrequent (backoff-driven).
- A resync **replaces** state wholesale with the server's authoritative list,
  so it also reconciles any drift from missed/duplicated incremental events —
  the server stays the single source of truth.
- Optimistic local mutations in flight at the instant of a resync could be
  briefly overwritten by the authoritative `GET`; in practice resync fires on
  connect transitions, not during steady-state editing, so the window is tiny.
- New list repositories should follow this pattern (handle `connected` →
  `_resync`) rather than relying on incremental events as a sole source.
