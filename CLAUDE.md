# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Not auto-updated. Refresh by hand when layout / flow shifts.

## Project

SatSet — Flutter 3.41+ Android-only (minSdk 29) LAN restaurant ordering app. Single APK runs in **Server** or **Client** mode, paired over Wi-Fi via mDNS + QR.

Stack: `flutter_riverpod`, `go_router`, `google_fonts`, `intl`, `uuid`, `freezed`, `json_serializable`, `drift`, `shelf` (+ `shelf_router`, `shelf_web_socket`), `web_socket_channel`, `http`, `flutter_secure_storage`, `shared_preferences`, `bonsoir` (mDNS), `mobile_scanner` (QR), `basic_utils` + `dart_jsonwebtoken` + `crypto` (TLS / JWT).

### Codegen scope

`build_runner` (`freezed`, `json_serializable`, `drift_dev`) only runs under:

- `lib/data/models/**` — wire DTOs
- `lib/domain/models/**` — domain models (selective; some are plain Dart)
- `lib/server/db/**` — Drift schema + DAOs

Generated `*.g.dart`, `*.freezed.dart`, Drift outputs excluded from analyzer. Run `tool/codegen.sh` (= `dart run build_runner build --delete-conflicting-outputs`) after editing those.

UI, repositories, services, server routes, use cases: hand-written.

## Commands

```bash
flutter pub get
flutter analyze                  # must pass clean
flutter run
flutter build apk --debug
flutter test
flutter test test/foo_test.dart
tool/codegen.sh                  # rebuild generated files
```

Lints: `package:flutter_lints/flutter.yaml`. No custom rules.

## Architecture

Strict three-layer split: `ui/` ← `domain/` ← `data/`. Server lives separately under `server/`.

**Entry:** `lib/main.dart` → `ProviderScope` → `SatSetApp` (`lib/app.dart`) → `MaterialApp.router` wired to `routerProvider`.

### Layers

**`lib/ui/`** — Flutter only.
- `ui/core/design/` — tokens + theme: `colors.dart`, `typography.dart`, `spacing.dart`, `layout.dart`, `theme.dart`, plus `course_visuals.dart`, `role_visuals.dart`, `zone_visuals.dart`, `format.dart`. Heritage Hospitality palette: Soft Cream `#FBF9F4`, Rich Brown `#4A3728`. Fonts (Noto Serif, Be Vietnam Pro) via `google_fonts` — needs network on first launch.
- `ui/core/state/` — cross-feature view-models (`theme_view_model.dart`, `view_mode_view_model.dart`, `ready_alert_view_model.dart`).
- `ui/core/widgets/` — cross-feature chrome: `sat_app_bar.dart`, `satset_top_bar.dart`, `tablet_chrome.dart`, `ready_banner.dart`, `ready_toast.dart`.
- `ui/features/<area>/` — screens grouped by flow. Each feature owns `view_models/` and `views/` (or top-level screens + `widgets/`).
  - Order-taking: `tables/` → `menu/` (+ `modifier_sheet.dart`) → `review/` → `sent/` → `orders/`.
  - Admin: `admin/` (`venue_hub_screen`, `floor_screen`, `menu_admin_screen` + `_item_screen` + `_item_editor`, `reports_screen`, `settings_screen`, `staff_screen`, `kitchen_screen`); `_common.dart` for shared widgets; `kitchen/view_models/`.
  - Onboarding: `onboarding/views/` (`mode_select_screen`, `pair_screen`, `forbidden_screen`).
  - Auth: `auth/views/pin_screen.dart`.
  - Other: `me/`, `void_flow/`, `shell/app_shell.dart`, `_stub/`.

**`lib/domain/`** — business logic, no Flutter imports.
- `models/` — `venue_table`, `zone`, `menu_item`, `menu_category`, `modifier_group`, `ticket` (freezed), `course` (freezed), `cart_item`, `role` (freezed), `user`, `capability`, `app_mode`, `audit_entry`.
- `use_cases/` — `submit_order_use_case`, `fire_course_use_case`, `advance_ticket_status_use_case`.

**`lib/data/`** — IO + caching, exposes Riverpod providers consumed by UI.
- `models/` — wire DTOs (freezed + json_serializable): `auth_dto`, `pair_dto`, `menu_dto`, `order_dto`, `ticket_dto`, `table_dto`, `ws_event_dto`.
- `repositories/` — `auth_repository`, `tables_repository`, `tickets_repository`, `menu_repository`, `zones_repository`, `staff_repository`, `roles_repository`, `audit_repository`. Each is a `StateNotifier` that hits the embedded server over HTTP/WS and re-emits domain models.
- `services/` — `api_client` (HTTP + `apiConfigProvider`), `ws_client` (WebSocket fan-out), `mdns_browser_service`, `prefs_service`, `secure_storage_service`, `error_bus_service`.

**`lib/server/`** — embedded shelf server (runs in-process in Server mode).
- `server.dart` — bootstrap, mounts router, runs TLS listener.
- `routes/` — `auth_routes`, `tables_routes`, `tickets_routes`, `menu_routes`, `reference_routes`, `health_routes`.
- `db/` — Drift: `database.dart`, `tables.dart` (schema), `seed.dart` + `seed_data.dart` (DB seeded on first boot — no more `DummyData`).
- `auth.dart` (PIN + JWT), `pairing.dart` (QR pair flow), `tls.dart` (self-signed cert), `mdns.dart` (advertise), `ws_hub.dart` (WebSocket broadcast).

**`lib/core/log/`** — `sat_log.dart` (logger), `sat_nav_observer.dart` (router observer).

### Routing (`lib/router/app_router.dart`)

GoRouter with refresh-listener pattern (auth / prefs / apiConfig changes trigger `redirect` re-eval without rebuilding the router itself).

- `/onboarding` — `ModeSelectScreen` (server / client).
- `/pair` — `PairScreen` (mDNS browse + QR scan).
- `/pin` — `PinScreen` (carries inline mode-select + pair flow if unpaired).
- `/forbidden` — capability-denied landing.
- `ShellRoute` → `AppShell` wraps tab routes: `/tables`, `/orders`, `/kitchen`, `/venue`, `/floor`, `/menuadm`, `/reports`, `/settings`, `/staff`, `/me`.
- **Outside the shell** (root-navigator pushes, full-page transitions):
  - `/table/:id` (+ `/menu`, `/review`, `/sent` subroutes) — order-taking flow.
  - `/menuadm/:id` — menu item editor.

**Redirect guard order:**
1. Hard pair gate: `apiConfigProvider == null` → `/pin` (no data screen renders against an empty repo cache).
2. Not authenticated → `/pin`.
3. Authenticated on `/pin` → `/venue` (server mode) or `/tables` (client mode), per `prefs.appMode()`.
4. Authenticated elsewhere → check `_capabilityFor(loc)` against `auth.has(cap)`; fail-closed → `/forbidden`.

Capabilities (`domain/models/capability.dart`): `viewKds`, `takeOrder`, `manageStaff`. Route → capability mapping is in `_capabilityFor` at the top of `app_router.dart`.

### Shell

`AppShell` (`lib/ui/features/shell/app_shell.dart`) picks tablet (`TabletShell`) vs phone (custom `Scaffold` with `SatAppBar` + floating tab bar) based on `context.layout.useTabletShell` and the `forcePhoneViewProvider`. Table flow no longer lives under the shell, so AppShell no longer needs special-case bare-child branches.

## Gotchas

- Don't name a class `Table` — conflicts with `dart:ffi`. Use `VenueTable`.
- Portrait + tablet layouts both rendered — check `tablet_chrome.dart` when adding shell-level UI.
- `.codegraph/` and `graphify-out/` lag a beat behind file writes.
- DB is the source of truth in Server mode; seed via `lib/server/db/seed.dart`, not via in-memory `DummyData` (gone).
- `apiConfigProvider == null` blocks every non-onboarding route — pair before exercising data screens.

## graphify

Knowledge graph at `graphify-out/`.

- Read `graphify-out/GRAPH_REPORT.md` for god nodes + community structure before answering architecture questions.
- If `graphify-out/wiki/index.md` exists, navigate that over raw files.
- Cross-module "how does X relate to Y" → `graphify query`, `graphify path`, `graphify explain` (traverse EXTRACTED + INFERRED edges).
- After code changes, run `graphify update .` (AST-only, no API cost).

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Standard triage label mapping is used. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout is used (CONTEXT.md + docs/adr/ at the root). See `docs/agents/domain.md`.

