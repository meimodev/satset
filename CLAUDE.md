# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Not auto-updated. Refresh by hand when layout / flow shifts.

## Project

SatSet — Flutter 3.41+ Android-only (minSdk 29) LAN restaurant ordering app. Single APK runs in **Server** or **Client** mode, paired over Wi-Fi via mDNS auto-claim.

Stack: `flutter_riverpod`, `go_router`, `intl`, `uuid`, `freezed`, `json_serializable`, `drift`, `shelf` (+ `shelf_router`, `shelf_web_socket`), `web_socket_channel`, `http`, `flutter_secure_storage`, `shared_preferences`, `bonsoir` (mDNS), `basic_utils` + `dart_jsonwebtoken` + `crypto` (TLS / JWT).

### Codegen scope

`build_runner` (`freezed`, `json_serializable`, `drift_dev`) only runs under:

- `lib/data/models/**` — wire DTOs
- `lib/domain/models/**` — domain models (selective; some are plain Dart)
- `lib/server/db/**` — Drift schema + DAOs

Generated `*.g.dart`, `*.freezed.dart`, Drift outputs excluded from analyzer. Run `tool/codegen.sh` (= `dart run build_runner build --delete-conflicting-outputs`) after editing those.

Localization is a **separate generator**, not part of `build_runner`: `lib/l10n/*.arb` → `flutter gen-l10n` → `lib/l10n/app_localizations*.dart`, configured by `l10n.yaml`. Output is committed and analyzer-excluded, so tests and CI need no generate step.

UI, repositories, services, server routes, use cases: hand-written.

## Commands

```bash
flutter pub get
flutter analyze                  # must pass clean
flutter run
flutter build apk --debug
flutter test
flutter test test/foo_test.dart
flutter test --tags golden --run-skipped            # pixel lock on core/widgets
flutter test --tags golden --run-skipped --update-goldens
tool/codegen.sh                  # rebuild generated files
flutter gen-l10n                 # rebuild AppL10n after editing lib/l10n/*.arb
```

Lints: `package:flutter_lints/flutter.yaml`. No custom rules.

## Architecture

Strict three-layer split: `ui/` ← `domain/` ← `data/`. Server lives separately under `server/`.

**Entry:** `lib/main.dart` → `ProviderScope` → `SatSetApp` (`lib/app.dart`) → `MaterialApp.router` wired to `routerProvider`.

### Layers

**`lib/ui/`** — Flutter only.
- `ui/core/design/` — tokens + theme: `colors.dart`, `typography.dart`, `spacing.dart`, `layout.dart`, `theme.dart`, plus `course_visuals.dart`, `role_visuals.dart`, `zone_visuals.dart`, `format.dart`, `motion.dart`. Amber-on-charcoal palette: accent `#FF9233`, dark `bg0 #0D0E10`, light `bg0 #F6F4EF`. Fonts are bundled in `assets/fonts/` and declared in `pubspec.yaml` — **nothing fetches at runtime and `google_fonts` is gone**. Archivo (one variable file, weight driven on the `wght` axis via `FontVariation`) serves the `glow` skin the default theme carries plus brutal's body copy; Archivo Black + DM Mono serve the rest of `brutal`; IBM Plex Sans + Mono serve the amber (`lembut`) themes. No italics are shipped — the two in-app italic spots synthesise. Guarded by `test/bundled_fonts_test.dart`, which fails if a role reaches for the network again. See §Design Context for the intent behind these.
- `ui/core/state/` — cross-feature view-models (`theme_view_model.dart`, `view_mode_view_model.dart`, `ready_alert_view_model.dart`).
- `ui/core/widgets/` — the shared vocabulary (ADR-0055): controls (`sat_button`, `sat_icon_button`, `sat_chip`, `sat_toggle`, `sat_stepper`, `sat_tabs`, `sat_field`, `sat_dropdown`, `sat_card`, `sat_empty`, `sat_sheet_header`, `pulse_dot`) plus chrome (`sat_app_bar`, `satset_top_bar`, `tablet_chrome`, `ready_banner`, `ready_toast`). **`CATALOG.md` in that folder lists every shared widget and token — read it before writing a new widget, and update it in the same commit when you add or remove one.** Enforced by `test/design_tokens_test.dart`, which is now all bans, no baselines: raw Material buttons, text inputs and dropdowns, literal type sizes, off-scale spacing, literal radii, hardcoded colours, roleless tap targets and duplicated widget class names all fail CI.
- `ui/features/<area>/` — screens grouped by flow. Each feature owns `view_models/` and `views/` (or top-level screens + `widgets/`).
  - Order-taking: `tables/` → `menu/` (+ `modifier_sheet.dart`) → `review/` → `sent/` → `orders/`.
  - Admin: `admin/` (`venue_hub_screen`, `alerts_screen`, `audit_screen`, `kas_screen`, `members_screen`, `opname_screen`, `floor_screen`, `menu_admin_screen` + `_item_screen` + `_item_editor`, `reports_screen`, `settings_screen`, `staff_screen`, `kitchen_screen`); `_common.dart` for shared widgets; `kitchen/view_models/`.
  - Onboarding: `onboarding/views/` (`mode_select_screen`, `forbidden_screen`). Pairing itself lives on `PinScreen` — mDNS discovery + auto-claim (ADR-0080).
  - Auth: `auth/views/pin_screen.dart`.
  - Other: `me/`, `void_flow/`, `shell/app_shell.dart`, `_stub/`.
  - Debug: `_book/` — widget book (`book_screen`, `book_entries`, `book_stubs`), debug builds only. ADR-0054.

**`lib/domain/`** — business logic, no Flutter imports.
- `models/` — `venue_table`, `zone`, `menu_item`, `menu_category`, `modifier_group`, `ticket` (freezed), `course` (freezed), `cart_item`, `role` (freezed), `user`, `capability`, `app_mode`, `audit_entry`, `member` (+ `MemberPointKind`).
- `use_cases/` — `submit_order_use_case`, `fire_course_use_case`, `advance_ticket_status_use_case`.

**`lib/data/`** — IO + caching, exposes Riverpod providers consumed by UI.
- `models/` — wire DTOs (freezed + json_serializable): `auth_dto`, `pair_dto`, `menu_dto`, `order_dto`, `ticket_dto`, `table_dto`, `ws_event_dto`.
- `repositories/` — `auth_repository`, `tables_repository`, `tickets_repository`, `menu_repository`, `zones_repository`, `staff_repository`, `roles_repository`, `audit_repository` (own shift), `venue_audit_repository` (venue-wide, paged), `cash_repository` (petty cash: WS-fed ledger + server-derived balance), `members_repository` (the Pelanggan (member) directory; `enabled: false` when the venue never opted in, because every member route answers 404 then). Each is a `StateNotifier` that hits the embedded server over HTTP/WS and re-emits domain models.
- `services/` — `api_client` (HTTP + `apiConfigProvider`), `ws_client` (WebSocket fan-out), `mdns_browser_service`, `prefs_service`, `secure_storage_service`, `error_bus_service`, `send_queue_service` + `send_queue_drain` (the offline **Antrean kirim**, ADR-0090).

**`lib/server/`** — embedded shelf server (runs in-process in Server mode).
- `server.dart` — bootstrap, mounts router, runs TLS listener.
- `routes/` — `auth_routes`, `tables_routes`, `tickets_routes`, `menu_routes`, `reference_routes`, `health_routes`, `cash_routes`, `members_routes`.
- `db/` — Drift: `database.dart`, `tables.dart` (schema), `seed.dart` + `seed_data.dart` (DB seeded on first boot — no more `DummyData`), `seed_history.dart` + `seed_history_mix.dart` (the fabricated month), `seed_inventory_data.dart` (bahan + resep).
- `seed_job.dart` — job marker + the venue-wide "prompt answered" flag (ADR-0073).
- `audit_log.dart` — **the** audit writer (`writeAudit`) + wire shape (`auditJson`). Every route that audits an act goes through it; hand-rolling the insert is how a new column reaches three call sites out of four. A row stores an `AuditKind` + params, never a sentence (ADR-0085) — the words are composed at read time by `auditText` in `lib/core/localization/audit_text.dart`.
- `cash.dart` — **the** petty cash writer (§Kas kecil). Every write to `cash_entries` goes through it, for the same reason `writeAudit` exists. Holds the two invariants: the balance is always `SUM(delta)` (nothing stores it) and the box cannot go negative (ADR-0088, with a reversal and a count exempt). `cashReportSection` is the Kas report block — a count's delta is booked as variance, never as cash moving (ADR-0089).
- `members.dart` — **the** membership writer (ADR-0091…0095), third of the same family. Holds the invariants: a points balance is `SUM(delta)` and never stored, never negative, never expires (ADR-0095); a member is identified by phone, so a merge folds one record into another and a delete anonymises rather than erases (ADR-0092). Points are earned once, at bill close, and reversed by a `MemberPointKind.reversal` row if the bill reopens — nothing is ever edited in place. `memberReportSection` is the Keanggotaan report block.
- `stock_counts.dart` — **the** stok opname writer (ADR-0096), fourth of the same family. An opname is a *session*: `stock_counts` header + `stock_count_lines`, opened, walked, then closed. Nothing moves until `closeCount`, which writes the `adjust` movements — each stamped with its `countId` — and exactly one `AuditKind.stockCountClosed` row. A line freezes its expectation at first entry, so a sale during the walk lands in the ledger and never in the variance; a zero-variance line is kept, because "counted and matched" is a finding. `recordCount` on `stock.dart` is gone — there is one path.
- `auth.dart` (PIN + JWT), `tls.dart` (self-signed cert), `mdns.dart` (advertise), `ws_hub.dart` (WebSocket broadcast). Pairing is a single unauthenticated `POST /pair/auto-claim` in `server.dart` that upserts the `Devices` row; there is no token table (ADR-0080).

**`lib/core/log/`** — `sat_log.dart` (logger), `sat_nav_observer.dart` (router observer).

### Routing (`lib/router/app_router.dart`)

GoRouter with refresh-listener pattern (auth / prefs / apiConfig changes trigger `redirect` re-eval without rebuilding the router itself).

- `/onboarding` — `ModeSelectScreen` (server / client).
- `/pin` — `PinScreen` (carries inline mode-select + mDNS discovery/auto-claim if unpaired). **The only pairing surface** — `/pair` is gone.
- `/forbidden` — capability-denied landing.
- `/book` — **debug builds only** (`if (kDebugMode)`). Widget book: every `core/widgets/` widget in all its states against stub data, with theme/skin, text-scale, reduced-motion and phone/tablet toggles. In the pair-gate bypass set, so it works unpaired. Two entries: a debug button on `PinScreen` (pre-pairing) and a "Book" item at the foot of `TabletSideRail` (pushed, not `go`ne — back returns to your tab). Lives in `lib/ui/features/_book/`. See ADR-0054 — add an entry there in the same commit as a new shared widget.
- `ShellRoute` → `AppShell` wraps tab routes: `/tables`, `/orders`, `/kitchen`, `/venue`, `/floor`, `/menuadm`, `/alerts`, `/reports`, `/settings`, `/staff`, `/me`.
  - `/alerts` = alert config (thresholds + sounds + this-device mute), reached from the Venue hub. Gated `editSettings`.
  - `/audit` = venue-wide integrity log (ADR-0072), reached from the Venue hub. Gated `viewReports`; admin rows need `manageStaff` on top, enforced server-side. **Tablet only** — the phone route renders an explanation. A row with a non-null `paymentId` shows a camera glyph and opens the proof photo on tap (ADR-0086) — this is the only place proofs are browsed across a range; Reports has no payments section.
  - `/members` = the Pelanggan (member) directory (ADR-0092), reached from the Venue hub. Gated `manageMembers`. **Tablet only**, like `/audit` and `/kas`. Reading a member is open to the till server-side, but the till reaches one through the bill overlay (`ui/features/cashier/member_panel.dart`) — this route is where records change. Enrol / edit / adjust points / merge / delete all live here; nothing on this screen touches a bill.
  - `/opname` = the stok opname archive (ADR-0096), reached from the Venue hub. Opened by `viewReports` **or** `manageIngredients` — the list shape `/kas` uses, because the person who counts and the person who reads the variance back are rarely the same. **Tablet only.** Read-only: counting happens on `/stock`, and this is where the closed sessions are filed. Export (PDF filing copy / CSV) is built client-side from the loaded document — a session has no paging, unlike the venue log.
  - `/kas` = the petty cash box (§Kas kecil), reached from the Venue hub. **Two capabilities open it** — `manageCash` (post an expense) or `editSettings` (fund it, count it) — which is why `_capabilityFor` returns a *list* and any one of them is enough; which of the three actions each may take is enforced per-route, server-side. **Tablet only**, like `/audit`. Nothing here is revenue (ADR-0089) — the box is not the cash drawer, and `openDrawer`/`closeShift` stay reserved for the drawer.
- **Outside the shell** (root-navigator pushes, full-page transitions):
  - `/table/:id` (+ `/menu`, `/review`, `/sent` subroutes) — order-taking flow.
  - `/menuadm/:id` — menu item editor.

**Redirect guard order:**
1. Hard pair gate: `apiConfigProvider == null` → `/pin` (no data screen renders against an empty repo cache).
2. Not authenticated → `/pin`.
3. Authenticated on `/pin` → `/venue` (server mode) or `/tables` (client mode), per `prefs.appMode()`.
4. Authenticated elsewhere → `_capabilityFor(loc)` returns the capabilities that open it; **any one** is enough (`needed.any(auth.has)`); fail-closed → `/forbidden`.

Capabilities (`domain/models/capability.dart`): `viewKds`, `takeOrder`, `manageStaff`, `manageCash`, … Route → capability mapping is in `_capabilityFor` at the top of `app_router.dart`.

### Shell

`AppShell` (`lib/ui/features/shell/app_shell.dart`) picks tablet (`TabletShell`) vs phone (custom `Scaffold` with `SatAppBar` + floating tab bar) based on `context.layout.useTabletShell` — hardware decides, there is no runtime override (ADR-0049 removed `forcePhoneViewProvider`). Table flow no longer lives under the shell, so AppShell no longer needs special-case bare-child branches.

`MainActivity.onCreate` keeps the screen awake (`FLAG_KEEP_SCREEN_ON`, unconditional) and pins orientation from `smallestScreenWidthDp >= 600` — tablet landscape, phone portrait. Orientation is not reachable from Dart; changing it means editing Kotlin. See ADR-0049.

## Gotchas

- Don't name a class `Table` — conflicts with `dart:ffi`. Use `VenueTable`.
- Portrait + tablet layouts both rendered — check `tablet_chrome.dart` when adding shell-level UI.
- `.codegraph/` and `graphify-out/` lag a beat behind file writes.
- DB is the source of truth in Server mode; seed via `lib/server/db/seed.dart`, not via in-memory `DummyData` (gone).
- **One seed, not two** (ADR-0073). `seedSampleVenue` = reference half (4 zones / 20 tables / ~42 items / 4 staff — 2 waiters + 2 kitchen / bahan+resep) **plus** a fabricated month of ~1500 bills and its audit trail, written through the production order path. It refuses on a venue that has traded; `clearSampleData` deletes the `contoh-` tagged transactional rows only, leaving the menu standing. The old demo seed and demo clock are gone — a seeded venue runs on real time, and backdating goes through the `at`/`idPrefix` overrides on `submitOrder`, `receiveStock` and `writeAudit`. A new seeded menu item needs a resep, bahan and a weight in `seed_history_mix.dart` or the seed will reject its lines for want of stock.
- The first-run seed prompt is a **blocking, non-dismissible dialog** on the Venue Hub, answered once and recorded server-side. Admin → Sistem → Operasional holds the permanent way back in.
- `apiConfigProvider == null` blocks every non-onboarding route — pair before exercising data screens.
- **Never rename an `AuditKind`** (`lib/domain/models/audit_kind.dart`). The name is persisted in `audit_entries.kind` and is the join to the ARB template; a rename silently drops every existing row back to its frozen Indonesian `title`. Adding one means an ARB entry in both locales — the `switch` in `auditText` is exhaustive, so the analyzer will say so.
- **`CashEntryKind` / `CashCategory` names are persisted** in `cash_entries.kind` and `.category`, and a category name also rides the Kas report's `byCategory` map. Renaming an enum value orphans every existing row — the resolvers fall through to the raw key, so it fails silently as a code where a word should be. Adding one needs an ARB entry in both locales.
- **`MemberPointKind` names are persisted** in `member_points.kind`, same rule as above.
- **`StockCountScope` names are persisted** in `stock_counts.scope`, same rule again. And `stock_movements.count_id` is nullable *by design* — an `adjust` written before v52 predates the session concept and is deliberately not backfilled (ADR-0096), so anything reading it must treat null as "pre-session", never as an error.
- **Membership is off until a venue switches it on** (ADR-0091). `venue_settings.membersEnabled` gates *every* member route with a 404 — not a 403 — so a client cannot tell an unlicensed venue from an old server, and `MembersRepository` reads that 404 as `enabled: false` rather than an error. The two programs underneath (`memberPointsEnabled`, `memberPunchEnabled`) toggle independently; the till panel and the printed slip both check them before drawing a thing.
- **A bill discount has a `source`** (ADR-0094): `manual` | `member` | `redeem`, one slot each, enforced by the `idx_discounts_bill_source_uniq` partial index. They stack by design — a cashier's promo, the member's standing discount and a points redemption are three different give-backs, and putting them in one slot is how one silently erases another. Everything is frozen at the first payment (ADR-0068), which is why `MemberPanel` gates on `billClosedAt == null && paidAmount == 0` instead of letting a button 409.
- **A new `Capability` reaches existing venues only because the admin role is reconciled on boot.** `_ensureAdminRole` (`lib/server/db/seed.dart`) rewrites `role-admin` to `Capability.values` every Server boot, because that role *is* all capabilities by definition and the Staf sheet shows it read-only — a stored snapshot is the one set nobody can repair. Every other role stores its own set, so a capability a non-admin role needs must be added to `seed_data.dart` **and** granted on already-seeded venues through the role sheet; there is no backfill but the one-off `_ensureWaiterCanVoid` pattern.
- **An offline write is an intent, not a row** (ADR-0090). `submitOrder` and `seat` fall back to `sendQueueProvider` when `wsConnStateProvider != open` (or when the request never lands), and the backlog replays through the *ordinary* routes on the next `connected` event. A new offline-capable action means a `SendIntentKind` + an arm in `apiIntentSender` — never a bulk endpoint, or the stock, visit and audit rules gain a second place to drift. `sendQueueDrainProvider` only subscribes because `AppShell` watches it.
- **Release builds run R8** (`isMinifyEnabled` + `isShrinkResources`). Dart is AOT and untouched, but a new plugin that resolves Java/Kotlin classes reflectively needs a keep rule in `android/app/proguard-rules.pro` or it fails only in release. `flutter build apk --release` is the check; debug will not catch it. Crashlytics' Gradle plugin uploads the mapping file, so minified traces stay symbolicated.

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

Four staff roles on shared Android hardware:

- **Waiter** — phone, one-handed, walking, tray in the other hand. Glances for half a second between tables. The busiest, least forgiving context.
- **Kitchen** — tablet KDS on a hot line, read from 1–2 m, often through steam, frequently never touched. Read-at-distance beats touch density.
- **Cashier** — settling, splitting, capturing payment proof. Accuracy over speed; money is on the line.
- **Owner / admin** — menu, staff, reports, inventory. Lower frequency, higher complexity tolerance. Seated, not rushed.

Job to be done: get an order from a guest's mouth into the kitchen, correctly, in seconds, without the internet. Everything else is bookkeeping around that.

The app ships **Indonesian and English** (ADR-0083). Indonesian is the hard default — the system locale is never consulted — and the picker is device-local, on `/me` beside the theme sheet.

Copy lives in `lib/l10n/app_id.arb` + `app_en.arb`, generated by `flutter gen-l10n` into `lib/l10n/app_localizations.dart` (class `AppL10n`, committed, analyzer-excluded). `AppStrings` is gone.

- **Widgets:** `context.l10n.foo` (extension in `lib/core/localization/locale_view_model.dart`).
- **No `BuildContext`** — exporters, `auth_error.dart`, pure view-model functions: `ref.read(l10nProvider)`, or take an `AppL10n` parameter.
- **A code crosses a layer, never a sentence** (ADR-0085). Enums carry their key and nothing else (`Capability`, `TicketStatus`, `ReservationStatus`, `StockReason`, `UserRole`, `AlertSoundPreset`); the server sends `kind` / `key` / `code` + params; `StaffException` and the report DTOs carry codes. The words are composed at read time by the resolvers in `lib/core/localization/` — `labels.dart` (enums, capabilities, staff errors, alert sounds), `report_copy.dart` (server-emitted report + void-reason codes), `audit_text.dart` (audit rows). Every resolver falls through to the raw code, so an older row or a newer server never renders blank.
- **Never hardcode user-facing text.** Three bans in `design_tokens_test.dart`, all at zero: copy in a `Text()`, copy in a named param (`label:`, `title:`, `hint:`…), and *any* Indonesian word in a Dart literal under `lib/ui` or `lib/domain` — the last one is what catches a switch arm, a preset list or a `return`. `arb_parity_test.dart` fails on a key, placeholder or plural present in one locale and not the other, because gen-l10n only *warns*.
- Indonesian remains the source language: `app_id.arb` is the template, and new copy is authored there first.

**Not localised, on purpose:** money (`formatIDR`, `groupRupiah` and the rupiah input mask stay `id_ID` in both languages — ADR-0084); the six theme names; venue-authored content (menu items, zones, notes, seed data). Dates *are* localised, so `format.dart` is deliberately half-pinned — see ADR-0084 before "fixing" it.

Domain vocabulary is canonical in `CONTEXT.md`: each term entry carries an `ID · EN` line, and no ARB value may render a domain term any other way (`opname` → Stocktake, not Inspection; `resep` → Recipe, not Prescription).

### Brand Personality

**Sharp, warm, dependable.** Tool-like precision, softened. Amber `#FF9233` on charcoal is the whole thesis: an instrument panel that doesn't feel cold, in a business that is fundamentally about hospitality.

Voice: direct, unfussy, Indonesian-plain. State what happened, not how the system feels about it. No exclamation marks, no apology copy, no personality in error states — a waiter mid-rush needs the fact and the next action.

Emotional goals, in order:

1. **Fast + in control** — every tap resolves visibly. Never ambiguous whether an order was sent.
2. **Calm under chaos** — the screen stays quiet while the room is loud. Nothing shouts unless it genuinely must (`urgent` is a scarce resource).
3. **Effortless / low-thought** — muscle memory. A new hire is productive on shift one, untrained.

### Aesthetic Direction

**The app boots on Neon Terang** — the light Glow palette, bone `#EEEFE0` ground (ADR-0057). Neither brightness is the exception: restaurants run dim and a dark theme is one tap away for the rooms that need it, while terrace and daylight service must survive glare. Both directions ship with genuine high contrast, never washed-out grays. Neon Terang is the roster's most accessible light palette — its semantic hues are authored as ink on white rather than reused from the charcoal ramp.

Color is signal, never decoration. The neutral ramp (`bg0`–`bg4`, `border0`–`border2`, `textHi`→`textDim`) carries structure; semantic tokens (`accent`, `success`, `warn`, `urgent`, `info`, `violet`) carry meaning only. Course colors (`cDrinks`/`cStarters`/`cMains`/`cDesserts`/`cFire`) alias the semantic set deliberately — one hue vocabulary, learned once.

Motion is welcome but purposeful: `satEaseOut`, transform + opacity only, always collapsing to a static final state under reduced motion (`motionEnabled(context)`). Motion clarifies what changed; it never entertains and never costs a waiter time.

**Anti-references — explicitly not this:**

- **Legacy Windows POS.** Gray gradients, beveled buttons, 6pt dense grids, 2005 enterprise chrome. This is the thing being replaced; resembling it is failure.
- **Generic Material 3 default.** No purple seed, no stock M3 look. `useMaterial3: true` is a substrate, overridden by `SatColors` + `SatType`. If a screen could be any Flutter demo, it's wrong.
- **Consumer food-delivery app.** No hero photography, gradients, promo banners, or gamification. Staff tools, not a storefront.

### Design Principles

1. **Glanceable beats dense.** Optimize for the half-second look from arm's length. Tap targets sized for a moving thumb; KDS text sized for 2 m. When density and legibility conflict, legibility wins.
2. **Color is signal, not decoration.** Reach for the neutral ramp first. `urgent` earns its red by being rare — if everything is urgent, nothing is.
3. **State must be unambiguous.** Sent vs. unsent, locked vs. free, ready vs. pending, settled vs. open — never inferable only from subtle color. Pair every state with text, shape, or position.
4. **Both themes, both real.** Every surface ships dark and light with genuine contrast. Never hardcode a `Color` — go through `context.sat`.
5. **Quiet motion, honest feedback.** Every action produces immediate visible acknowledgement; no animation delays a confirmation. Reduced motion always yields the final state instantly.
6. **Degrade loudly, fail safely.** Offline, mid-reconnect, and stale-cache states are first-class UI — this app's whole promise is working when the network doesn't.
