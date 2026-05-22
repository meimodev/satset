# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SatSet — Flutter 3.41+ Android-only (minSdk 29) LAN-based restaurant ordering app. Single APK runs in Server or Client mode. UI-first phase: dummy data only, no real WebSocket/DB yet.

Stack: `flutter_riverpod`, `go_router`, `google_fonts`, `intl`, `uuid`. No codegen (no freezed, no drift, no build_runner).

## Commands

```bash
flutter pub get             # install deps
flutter analyze             # static analysis — must pass clean
flutter run                 # run on connected device/emulator
flutter build apk --debug   # first build slow (Gradle download)
flutter test                # run all tests
flutter test test/foo_test.dart  # single test file
```

Lints from `package:flutter_lints/flutter.yaml`. No custom rules.

## Architecture

**Entry:** `lib/main.dart` → `ProviderScope` → `SatSetApp` (`lib/app.dart`) → `MaterialApp.router` wired to `routerProvider`.

**Routing (`lib/router/app_router.dart`):** GoRouter with:
- `/pin` — `PinScreen` login (any PIN signs in as `DummyData.maya`).
- `ShellRoute` wrapping `AppShell` (`lib/features/shell/app_shell.dart`) for tab nav. Routes: `/tables`, `/orders`, `/kds`, `/floor`, `/menuadm`, `/reports`, `/settings`, `/staff`, `/me`.
- `/table/:id` (and `/menu`, `/review`, `/sent` subroutes) — full-screen order-taking flow outside the shell.
- Redirect guard: not authenticated → `/pin`; authenticated on `/pin` → `/tables`.

**State (`lib/state/`):** Riverpod providers, one per concern.
- `auth/auth_state.dart` — `AuthNotifier` (StateNotifier). Dummy: any PIN authenticates.
- `cart_provider.dart` — current table's draft order.
- `tables_provider.dart`, `tickets_provider.dart` — venue state.
- `audit_provider.dart`, `ready_alert_provider.dart`, `view_mode_provider.dart`, `theme_provider.dart`.

**Models (`lib/models/`):** Plain Dart classes. All seed/demo data lives in `dummy_data.dart` (users, zones, tables, categories, menu items, modifier groups, orders, inventory). Edit there to change demo state.

**Features (`lib/features/<area>/`):** Screens grouped by flow.
- Order-taking flow: `tables` → `menu` (+ `modifier_sheet`) → `review` → `sent` → `orders`.
- Admin: `admin/` (kds, floor, menu_admin, reports, settings, staff). `_common.dart` holds shared admin widgets.
- Other: `me/`, `void_flow/`, `shell/`.

**Design (`lib/design/`):** Heritage Hospitality tokens — Soft Cream `#FBF9F4`, Rich Brown `#4A3728`. `theme.dart` defines `satLightTheme()`/`satDarkTheme()` used by `app.dart`. `colors.dart`, `spacing.dart` (4/8/12/16/24/40), `layout.dart`, plus `components/` (sat_button, sat_card, sat_input, sat_chip, sat_divider). Fonts (Noto Serif, Be Vietnam Pro) fetched at runtime via `google_fonts` — needs network on first launch.

**Widgets (`lib/widgets/`):** Cross-feature chrome — `satset_top_bar.dart`, `tablet_chrome.dart`, `ready_banner.dart`, `ready_toast.dart`.

## Gotchas

- Don't name a class `Table` — conflicts with `dart:ffi`. Use `VenueTable`.
- Portrait + tablet layouts both rendered; check `tablet_chrome.dart` when adding shell-level UI.
- Index in `.codegraph/` and `graphify-out/` lag a beat behind file writes.

## graphify

This project has a graphify knowledge graph at `graphify-out/`.

- Before answering architecture or codebase questions, read `graphify-out/GRAPH_REPORT.md` for god nodes and community structure.
- If `graphify-out/wiki/index.md` exists, navigate it instead of reading raw files.
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse EXTRACTED + INFERRED edges.
- After modifying code files, run `graphify update .` to keep the graph current (AST-only, no API cost).
