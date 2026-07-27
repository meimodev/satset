# ADR-0049 — The widget book is a debug-only route, not a second app

## Status

Accepted. Serves `lib/ui/core/widgets/CATALOG.md`, which remains the contract
this gallery renders.

## Context

`CATALOG.md` tells you a shared widget exists and what it is for. It cannot show
you the widget. The consequences of that gap are all in the catalog's own
"Known duplicates" table: three `_StatusChip`s, two `_EntranceFade`s, two
parallel motion systems — each written by someone who could not see what was
already there.

The states that break widgets are also the states hardest to reach in the
running app. A `voided` line with an approver, a 42-minute-overdue `ElapsedPill`,
an account with no avatar colour, a 68-character Indonesian dish name at 1.3×
text scale under reduced motion on a tablet breakpoint — reproducing any of
those means seeding a database and walking a service through it.

The obvious tool is `widgetbook`. Its actual value — knobs, device frames, cloud
review — arrives with `widgetbook_annotation` + `widgetbook_generator`, which
would pull `lib/ui/**` into `build_runner` scope. Codegen scope is currently
three directories (`data/models`, `domain/models`, `server/db`) and that
boundary is load-bearing: it is why `tool/codegen.sh` is fast and why UI edits
never wait on a build. Used without codegen, `widgetbook` is a manual
`WidgetbookComponent` tree — about as much code as writing the gallery, plus a
dependency and usually a second entrypoint.

## Decision

### A route, gated on `kDebugMode`, inside the one app

`/book` is registered under `if (kDebugMode)` in `app_router.dart`.
`kDebugMode` is a `const`, so in a release build the route, both entry points
below, and everything they reference are tree-shaken out — the gallery cannot
ship by accident, and no second `main` has to be kept alive.

Two doors, because one was not enough in practice:

- **`PinScreen`** — the only surface reachable before pairing, which is where
  browsing widgets on a fresh device has to work. `/book` therefore joins the
  redirect's `onboardingRoutes` bypass set, so the hard pair gate does not
  bounce it to `/pin`.
- **`TabletSideRail`** — a dev device stays paired and auto-signs-in, so it
  never lands on `PinScreen` again and the first door is effectively closed.
  The rail item **pushes** rather than `go`es: the book is a detour, and back
  should land on the tab you left. `_RailBtn` gained a `push` flag for that.

`_capabilityFor('/book')` returns null, so an authenticated session reaches it
without a capability check — the gate it needs is the build mode, not a role.

The phone tab bar is deliberately left alone. The rail is on the tablet, which
is the device that runs as server and stays signed in; adding a sixth phone tab
to reach a debug tool would cost a waiter's thumb more than it buys.

### Scope is `core/widgets/`, and the coverage rule is mechanical

The book renders the ~31 entries `CATALOG.md` lists as cross-feature. Per entry:
one state for every enum value the widget accepts, one for every meaningful
boolean, plus one stress state carrying the longest realistic Indonesian copy —
`BookStubs.longName`, ×99, six modifiers, a two-line note. The stress state is
not decoration; it is the only place overflow shows up on demand.

Feature-local widgets (`TableCard`, `AdminPage`, `ReceiptPreview`) are out until
they are promoted to `core/widgets/`, which keeps one boundary rather than two.

### State comes from per-state `ProviderScope` overrides

Seven catalog widgets read Riverpod. Each state that needs a provider is wrapped
in its own scope, so `SatAppBar / connected` and `SatAppBar / disconnected`
render on the same page — a single book-wide scope could only ever show one
value per provider, which is exactly the wrong half of every pair.

`authStateProvider` is a `StateNotifierProvider<AuthRepository, AuthState>`, so
its override subclasses `AuthRepository`. That is safe because the real
constructor is inert: it stores `ref` and `storage` and starts nothing.

`venueSettingsProvider` is deliberately **not** overridden. `ElapsedPill`'s
overdue escalation is reachable by ageing the ticket instead, and the real
default (`prepTargetMins: 15`) is the number worth checking against.

`AlertHost` is not mounted. It is a mount point rather than a visual — it keeps
the alert sound service alive and holds a router — so the book renders its
visible half, `ReadyToast` and `ReadyBanner`, directly.

### Five global axes, one strip

Theme/skin, text scale (1.0 / 1.3, the app-wide ceiling), reduced motion, and
forced width (device / 390 / 1100, straddling `SatLayout`'s 1024 tablet break).
Scale and motion are one `MediaQuery` wrap; width overrides `MediaQuery.size` so
`context.layout` genuinely reports tablet rather than merely being narrowed.

Theme selection goes through the real `satThemeProvider` and therefore persists
to prefs. A book-local theme would have to mutate `SatShape`'s statics behind
the app's back and restore them on pop; borrowing the real picker is one line
and cannot desynchronise.

### The book obeys the design-token guard

No exemption in `test/design_tokens_test.dart`. The book uses `context.sat`,
`Sp`, `SatR` and `satMotion` like any other screen, and its private widgets are
`_Book`-prefixed so the duplicate-name baseline of 12 does not move. A gallery
that documents the token system while ignoring it would not be worth trusting.

Book captions stay hardcoded English. They are dev-facing; routing them through
`AppStrings` would put developer tooling in the same namespace as guest copy.

## Consequences

- Widget states that previously required a seeded database and a walked service
  are now one tap apart, including the ones nobody had ever looked at.
- Reduced motion and 1.3× text scale become checkable without changing Android
  settings — the two accessibility axes that used to fail silently in review.
- Drift is held by discipline, not by a test: `CATALOG.md` now says to add a
  book entry in the same commit as a new shared widget. A coverage test was
  considered and declined — the catalog rule has held so far, and a ratcheting
  baseline on entry count would fire on every widget rename.
- `showExportSheet` runs against canned empty-but-valid report payloads, so
  exporting from the book produces a real PDF/CSV and opens the Android share
  sheet. Intended, not a leak — but it is real IO from a gallery.
- Three files gained a `kDebugMode` branch (`app_router.dart`, `pin_screen.dart`,
  `tablet_chrome.dart`). All const-folded in release.
- `test/widget_book_test.dart` pumps every state and asserts no exception, so a
  stub that drifts from a constructor fails in CI rather than on a device. It
  found two real constraints on first run: `TagBadgeRow` returns a bare
  `Flexible` and throws outside a `Row`/`Column`, and `SkeletonCard` overflows
  below ~86px. Both are now documented in the entry notes.
