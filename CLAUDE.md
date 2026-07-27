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
- `ui/core/design/` — tokens + theme: `colors.dart`, `typography.dart`, `spacing.dart`, `layout.dart`, `theme.dart`, plus `course_visuals.dart`, `role_visuals.dart`, `zone_visuals.dart`, `format.dart`, `motion.dart`. Amber-on-charcoal palette: accent `#FF9233`, dark `bg0 #0D0E10`, light `bg0 #F6F4EF`. Fonts (IBM Plex Sans + IBM Plex Mono) via `google_fonts` — needs network on first launch. See §Design Context for the intent behind these.
- `ui/core/state/` — cross-feature view-models (`theme_view_model.dart`, `view_mode_view_model.dart`, `ready_alert_view_model.dart`).
- `ui/core/widgets/` — cross-feature chrome: `sat_app_bar.dart`, `satset_top_bar.dart`, `tablet_chrome.dart`, `ready_banner.dart`, `ready_toast.dart`. **`CATALOG.md` in that folder lists every shared widget and token — read it before writing a new widget, and update it in the same commit when you add or remove one.** Enforced by `test/design_tokens_test.dart` (ratcheting guard against hardcoded colors, off-scale spacing, and literal radii).
- `ui/features/<area>/` — screens grouped by flow. Each feature owns `view_models/` and `views/` (or top-level screens + `widgets/`).
  - Order-taking: `tables/` → `menu/` (+ `modifier_sheet.dart`) → `review/` → `sent/` → `orders/`.
  - Admin: `admin/` (`venue_hub_screen`, `alerts_screen`, `floor_screen`, `menu_admin_screen` + `_item_screen` + `_item_editor`, `reports_screen`, `settings_screen`, `staff_screen`, `kitchen_screen`); `_common.dart` for shared widgets; `kitchen/view_models/`.
  - Onboarding: `onboarding/views/` (`mode_select_screen`, `pair_screen`, `forbidden_screen`).
  - Auth: `auth/views/pin_screen.dart`.
  - Other: `me/`, `void_flow/`, `shell/app_shell.dart`, `_stub/`.
  - Debug: `_book/` — widget book (`book_screen`, `book_entries`, `book_stubs`), debug builds only. ADR-0054.

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
- `/book` — **debug builds only** (`if (kDebugMode)`). Widget book: every `core/widgets/` widget in all its states against stub data, with theme/skin, text-scale, reduced-motion and phone/tablet toggles. In the pair-gate bypass set, so it works unpaired. Two entries: a debug button on `PinScreen` (pre-pairing) and a "Book" item at the foot of `TabletSideRail` (pushed, not `go`ne — back returns to your tab). Lives in `lib/ui/features/_book/`. See ADR-0054 — add an entry there in the same commit as a new shared widget.
- `ShellRoute` → `AppShell` wraps tab routes: `/tables`, `/orders`, `/kitchen`, `/venue`, `/floor`, `/menuadm`, `/alerts`, `/reports`, `/settings`, `/staff`, `/me`.
  - `/alerts` = alert config (thresholds + sounds + this-device mute), reached from the Venue hub. Gated `editSettings`.
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

`AppShell` (`lib/ui/features/shell/app_shell.dart`) picks tablet (`TabletShell`) vs phone (custom `Scaffold` with `SatAppBar` + floating tab bar) based on `context.layout.useTabletShell` — hardware decides, there is no runtime override (ADR-0049 removed `forcePhoneViewProvider`). Table flow no longer lives under the shell, so AppShell no longer needs special-case bare-child branches.

`MainActivity.onCreate` keeps the screen awake (`FLAG_KEEP_SCREEN_ON`, unconditional) and pins orientation from `smallestScreenWidthDp >= 600` — tablet landscape, phone portrait. Orientation is not reachable from Dart; changing it means editing Kotlin. See ADR-0049.

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


## Design Context

> Guides every UI decision. Tokens live in `lib/ui/core/design/`; this section is the *why*.

### Users

Four staff roles on shared Android hardware, one guest role on the web:

- **Waiter** — phone, one-handed, walking, tray in the other hand. Glances for half a second between tables. The busiest, least forgiving context.
- **Kitchen** — tablet KDS on a hot line, read from 1–2 m, often through steam, frequently never touched. Read-at-distance beats touch density.
- **Cashier** — settling, splitting, capturing payment proof. Accuracy over speed; money is on the line.
- **Owner / admin** — menu, staff, reports, inventory. Lower frequency, higher complexity tolerance. Seated, not rushed.
- **Guest** — hand-rolled web SPA (ADR-0029), own phone, zero training, one-shot use.

Job to be done: get an order from a guest's mouth into the kitchen, correctly, in seconds, without the internet. Everything else is bookkeeping around that.

UI language is **Bahasa Indonesia** (`kosong`, `terisi`, `habis`, `Dikelola pengelola`). Copy goes through `lib/core/localization/app_strings.dart` — never hardcode user-facing text.

### Brand Personality

**Sharp, warm, dependable.** Tool-like precision, softened. Amber `#FF9233` on charcoal is the whole thesis: an instrument panel that doesn't feel cold, in a business that is fundamentally about hospitality.

Voice: direct, unfussy, Indonesian-plain. State what happened, not how the system feels about it. No exclamation marks, no apology copy, no personality in error states — a waiter mid-rush needs the fact and the next action.

Emotional goals, in order:

1. **Fast + in control** — every tap resolves visibly. Never ambiguous whether an order was sent.
2. **Calm under chaos** — the screen stays quiet while the room is loud. Nothing shouts unless it genuinely must (`urgent` is a scarce resource).
3. **Effortless / low-thought** — muscle memory. A new hire is productive on shift one, untrained.

### Aesthetic Direction

Dark-first. Restaurants run dim, so **dark is the real default and light is the exception** — but light mode is a first-class citizen, not a fallback: terrace and daylight service must survive glare, so light mode needs genuine high contrast, not washed-out grays.

Color is signal, never decoration. The neutral ramp (`bg0`–`bg4`, `border0`–`border2`, `textHi`→`textDim`) carries structure; semantic tokens (`accent`, `success`, `warn`, `urgent`, `info`, `violet`) carry meaning only. Course colors (`cDrinks`/`cStarters`/`cMains`/`cDesserts`/`cFire`) alias the semantic set deliberately — one hue vocabulary, learned once.

Motion is welcome but purposeful: `satEaseOut`, transform + opacity only, always collapsing to a static final state under reduced motion (`motionEnabled(context)`). Motion clarifies what changed; it never entertains and never costs a waiter time.

**Anti-references — explicitly not this:**

- **Legacy Windows POS.** Gray gradients, beveled buttons, 6pt dense grids, 2005 enterprise chrome. This is the thing being replaced; resembling it is failure.
- **Generic Material 3 default.** No purple seed, no stock M3 look. `useMaterial3: true` is a substrate, overridden by `SatColors` + `SatType`. If a screen could be any Flutter demo, it's wrong.
- **Consumer food-delivery app.** No hero photography, gradients, promo banners, or gamification. Staff tools, not a storefront. (Guest SPA may lean slightly warmer — different audience, still not this.)

### Design Principles

1. **Glanceable beats dense.** Optimize for the half-second look from arm's length. Tap targets sized for a moving thumb; KDS text sized for 2 m. When density and legibility conflict, legibility wins.
2. **Color is signal, not decoration.** Reach for the neutral ramp first. `urgent` earns its red by being rare — if everything is urgent, nothing is.
3. **State must be unambiguous.** Sent vs. unsent, locked vs. free, ready vs. pending, settled vs. open — never inferable only from subtle color. Pair every state with text, shape, or position.
4. **Both themes, both real.** Every surface ships dark and light with genuine contrast. Never hardcode a `Color` — go through `context.sat`.
5. **Quiet motion, honest feedback.** Every action produces immediate visible acknowledgement; no animation delays a confirmation. Reduced motion always yields the final state instantly.
6. **Degrade loudly, fail safely.** Offline, mid-reconnect, and stale-cache states are first-class UI — this app's whole promise is working when the network doesn't.
