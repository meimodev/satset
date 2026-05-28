# ADR-0005 — Strict three-layer architecture (ui/domain/data) on Riverpod; repositories are StateNotifiers hydrated from HTTP and WS; codegen scoped to DTOs and Drift

**Status:** Accepted — 2026-05-28

## Context

SatSet has to keep many UIs (waiter floor, table detail, menu screen, kitchen display, admin) coherent against a single embedded server while a) the device may be the server itself (loopback) or a remote client, and b) every state-changing operation produces fanout via WebSocket. We needed an app-side architecture that:

- Survives the same code rendering against `https://127.0.0.1:7443` (server-mode self-call) and `https://192.168.x.y:7443` (client-mode LAN call) with no branching.
- Lets `tableUpdated` / `ticketAdvanced` events update every open screen automatically without manual refresh wiring.
- Keeps the domain model Flutter-free so domain types are usable from `server/` route handlers (e.g. `domain/models/venue_table.dart` is shared with the seed file's DTO conversion logic).
- Doesn't pay the codegen tax everywhere — `build_runner` is slow, and most UI code does not benefit from `freezed`.

## Decision

**1. Three layers, dependencies flow inward: `ui/` → `domain/` → `data/`. No reverse imports.**

- **`lib/domain/`** — pure Dart, no Flutter imports, no IO. Models (`VenueTable`, `MenuItem`, `Ticket`, `Reservation`, `Role`, `Capability`, `User`, `AppMode`, …) and use cases (`SubmitOrderUseCase`, `FireCourseUseCase`, `AdvanceTicketStatusUseCase`). Free-standing; can be imported by anything.
- **`lib/data/`** — IO + caching. Owns repositories (`TablesRepository`, `MenuRepository`, `TicketsRepository`, etc), services (`ApiClient`, `WsClient`, `MdnsBrowserService`, `PrefsService`, `SecureStorageService`, `ErrorBusService`), and wire DTOs (`*_dto.dart`).
- **`lib/ui/`** — Flutter only. Watches Riverpod providers exposed by `data/`; constructs/uses `domain/` types. Never touches HTTP / Drift / WebSocket directly.

**2. Repositories are `StateNotifier<List<DomainModel>>` (or `StateNotifier<Map<…>>`), bootstrap from HTTP, then live-update from WS.**

Canonical shape (e.g. `lib/data/repositories/tables_repository.dart`):

```dart
class TablesRepository extends StateNotifier<List<VenueTable>> {
  TablesRepository({required this.ref}) : super(const []) {
    Future.microtask(_bootstrap);              // deferred to escape ctor
  }

  Future<void> _bootstrap() async {
    if (ref.read(apiConfigProvider) == null) { /* mark ready, return */ }
    state = const [];                          // clear stale state
    final raw = await api.getJson('/tables');  // hydrate
    state = [for (final d in dtos) _toDomain(d)];

    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.tableUpdated) { /* upsert into state */ }
      // tableCreated, tableDeleted, …
    });
  }
}
```

Conventions baked in:

- **Microtask-deferred bootstrap.** Riverpod forbids mutating other providers during a notifier's own initialization; the microtask escape is the recognized pattern.
- **Hard pair-gate.** `apiConfigProvider == null` → return without hitting the network. The router pair-gate already prevents data screens rendering before pair, but repos defend in depth.
- **Status provider sibling.** Each repo exposes a `<thing>StatusProvider: StateProvider<AsyncValue<void>>` so UIs can show a spinner during bootstrap or an inline error banner if hydration fails. State + status are split because the data layer keeps the last good state visible while a refresh is in flight.
- **No fallback to in-memory dummy data on failure.** When LAN is supposed to be authoritative, an error surfaces as `AsyncValue.error`. Silent fallback was actively harmful — it hid pair/server outages behind plausible-looking data.
- **DTOs at the wire boundary only.** `TableDto.fromJson` → `_toDomain(d)` happens inside the repo. Domain types never know about JSON; UI never sees DTOs.

**3. `WsClient` is the single source of WebSocket events; repositories subscribe.**

`WsClient` (`lib/data/services/ws_client.dart`) holds one socket and reconnects with backoff. Repos `ref.read(wsClientProvider).events.listen(...)`. Cross-repo fanout (a `tableUpdated` that also implies a tickets refresh) is handled in the relevant repos' own listeners — no central event dispatcher.

This means: a state-changing route on the server broadcasts one WS event, every relevant client repo updates its state, every watching UI rebuilds. No manual `invalidate` from the UI layer in the happy path.

**4. `ApiClient` carries TLS pinning + bearer auth; repos never see HTTP details.**

`apiConfigProvider: StateProvider<ApiConfig?>` is the seam. Set by onboarding (pair flow on a client, loopback init on a server). Replaced when mode or pairing changes. `apiClientProvider` rebuilds whenever the config changes. Repos `ref.read(apiClientProvider)` and call typed JSON helpers (`getJson`, `postJson`, `patchJson`, `delete`). Pinning, headers, error envelopes are invisible to repos.

`pairedProvider: Provider<bool>((ref) => ref.watch(apiConfigProvider) != null)` is the single readable signal — used by the router redirect and by some repo guards.

**5. Codegen is scoped to three directories; everything else is hand-written.**

`build_runner` (`freezed`, `json_serializable`, `drift_dev`) runs only against:

- `lib/data/models/**` — wire DTOs (`auth_dto`, `pair_dto`, `menu_dto`, `order_dto`, `ticket_dto`, `table_dto`, `ws_event_dto`, …). Freezed + JSON.
- `lib/domain/models/**` — **selectively**. Domain models that benefit from freezed (`Ticket`, `Course`, `Role`, `Zone`) use it; simpler value types (`VenueTable`, `MenuItem`, `User`, `Capability`, `AppMode`) are plain Dart classes / enums. The choice is per-model — no rule that every domain model must be freezed.
- `lib/server/db/**` — Drift schema + DAOs.

Generated `*.g.dart`, `*.freezed.dart`, and Drift outputs are excluded from the analyzer (`analysis_options.yaml`).

**UI, repositories, services, server routes, use cases are all hand-written.** No `riverpod_generator`, no `freezed` for ephemeral UI state, no `retrofit` for the API client. The hand-written code is small and easy to read; the cost of a `build_runner` run is real (multi-second) and we don't want to pay it for every UI tweak.

Regen happens via `tool/codegen.sh` after editing files under those three directories.

## Consequences

**Positive:**
- The same `TablesRepository` runs on a server tablet hitting `https://127.0.0.1:7443` and on a remote client hitting `https://192.168.x.y:7443`. No "is this server?" branching anywhere in the data or UI layers.
- WS-driven state means cross-device coherence (a waiter on tablet A seats a table → tablet B's floor view updates within ~50ms) without any UI-level orchestration.
- The hard layer boundary catches accidental coupling at code review (a `Flutter` import inside `domain/` jumps out immediately).
- The narrow codegen scope keeps `flutter analyze` and IDE responsiveness fast on a mixed Dart/Flutter codebase. A typical UI iteration never needs to run `build_runner`.
- Repos as `StateNotifier<List<…>>` give UIs a `select`-able value that diffs cheaply; pairs naturally with Riverpod's read/watch story.
- The pattern is repetitive enough across repos (`tables`, `menu`, `tickets`, `reservations`, `staff`, …) that adding a new entity is mechanical — copy the canonical shape.

**Negative:**
- **Repo boilerplate.** Every entity duplicates bootstrap + WS listener + status provider. Roughly ~50 LOC per repo. Tolerated; an abstract base class would couple the entities and obscure per-repo nuances (e.g. tables' lock semantics).
- **No centralized event router.** Cross-cutting events (a ticket fired → tables get a status nudge → reservations may flip seated) require each affected repo to listen for the relevant event types. Forgotten listeners silently desync — not blocked at compile time.
- **WS reconnect drops events in the window before reconnect.** Repos do not currently rebootstrap on `wsClient` reconnect, so a long disconnect can leave state stale. Mitigation: pull-to-refresh on relevant screens; planned: a `wsReconnect` signal that triggers selective re-bootstrap.
- **Hand-written API client.** Adding an endpoint = edit `ApiClient` *and* repo *and* potentially a DTO. Less ergonomic than a generated typed client, but the call surface is small (~30 endpoints) and the hand-written version stays debuggable.
- **Selective freezed in `domain/` is a recurring "should I?" choice.** No hard rule; we lean on freezed when copyWith/equality are nontrivial and skip it when they are not. Acceptable but documented here to head off churn.
- **`Future.microtask` bootstrap is invisible startup ordering.** Repos look "ready" the instant they construct but state populates a tick later. UIs must watch the matching `<thing>StatusProvider` rather than treat empty state as "loaded with zero rows". Not always intuitive.

## Alternatives considered

- **Riverpod's `AsyncNotifier` / generator-based providers.** Considered. The codegen tax (`riverpod_generator`) for every provider plus the still-evolving API didn't feel worth it; `StateNotifier` is well-understood and the boilerplate it adds is small.
- **GetIt + Provider, or BLoC.** Rejected: Riverpod's `ref.watch` and provider invalidation map cleanly onto the WS-driven update model. BLoC's event/state ceremony would compound the boilerplate already present in repos.
- **Two-layer (no `domain/`).** Rejected: would have meant either (a) Flutter imports in models (blocks reuse from `server/`) or (b) DTOs leaking into UI. The `domain/` boundary pays its keep.
- **In-memory cache layer between repo and `ApiClient` (e.g. normalized store).** Rejected for current scale. Repos hold whole entity lists in `state`; the venues this targets have hundreds of menu items, not millions. A normalized store can come later if scale demands it; the repo seam already encapsulates state shape.
- **Generated typed API client (chopper / retrofit / OpenAPI codegen).** Rejected: the schema isn't published and changes often during early development; hand-written `getJson`/`postJson` calls cost less than maintaining an OpenAPI spec for an internal LAN API.
- **Full `freezed` on every `domain/` model.** Considered. Pays off for unions and deep `copyWith`; over-engineered for plain enums and trivial value classes. Per-model choice is the pragmatic answer.
