# ADR-0061 — Overlays go through one entry point, on the root navigator

## Status

Accepted. Extends ADR-0055's ban discipline from widgets to routes, and closes
a defect ADR-0049 created without noticing.

Serves `lib/ui/core/widgets/sat_overlay.dart` and the Overlays section of
`lib/ui/core/widgets/CATALOG.md`.

## Context

The theme picker on a phone opened underneath the floating tab bar. Not
overlapped — underneath, with the bar's amber pill sitting on top of the
swatches and still taking taps.

The cause is structural, not a slip in that one sheet. `AppShell`'s phone
branch stacks two things:

```dart
Stack(children: [
  Positioned.fill(child: child),   // the ShellRoute navigator
  Positioned(bottom: 12, child: _FloatingTabBar(...)),
])
```

`child` is the shell's `Navigator`. Anything pushed onto it — a route, a modal
barrier, a bottom sheet — paints inside `Positioned.fill`, which is below the
tab bar in paint order and below it in hit-test order. And
`showModalBottomSheet`, `showDialog` and `showGeneralDialog` all default to
`useRootNavigator: false`.

So the correct call is one named argument, and the incorrect call is the one
you get by writing the obvious thing. Counted at the time of this decision:

- 34 `showModalBottomSheet` sites — 5 wrong.
- 26 `showDialog` sites — 22 wrong. A shell-navigator dialog is worse than a
  low sheet: it is centred, so it *looks* fine, while the tab bar stays live
  above its barrier and you can change tab with a "modal" open.
- 1 `showGeneralDialog` site — correct, by hand.

The same 34 sheet call sites also carried copies of decoration the theme
already owned: `backgroundColor: sc.bg1` and a `RoundedRectangleBorder`. The
copies had drifted from the theme — 14 of 15 said `SatR.c(24)` where
`bottomSheetTheme` said 28. The theme value was dead: only a sheet that forgot
to override ever rendered it.

## Decision

**One file owns every route pushed above the current one.**
`lib/ui/core/widgets/sat_overlay.dart` exports `showSatSheet`, `showSatDialog`
and `showSatDrawer`. All three force `useRootNavigator: true` and default
`barrierColor` to `satBarrier`. Raw `showModalBottomSheet`, `showDialog` and
`showGeneralDialog` anywhere under `lib/` fail
`test/design_tokens_test.dart`; `sat_overlay.dart` is the only exemption, and
there is no comment hatch. A case the helper cannot serve grows a parameter on
the helper — that is what "one place" buys.

`showDatePicker` and `showTimePicker` are not banned: Flutter already defaults
those to the root navigator.

**Decoration comes from the theme.** No call site passes `backgroundColor` or
`shape`. `bottomSheetTheme` adopts `SatR.c(24)`, the radius the app was
actually rendering, so the migration is a zero-pixel change for the 14 sheets
that had overridden it.

**Sheets scroll-control by default.** `isScrollControlled: true` unless a body
opts out. The 9/16-of-screen cap is almost never what a form or picker wants,
and it is the second thing every sheet had to remember.

**Safe area and keyboard insets stay with the body.** Twelve bodies already
pad by `viewInsets.bottom` and several nest their own `SafeArea`; hoisting
that into the helper would double-pad them for no defect anyone has hit. The
helper's remit is where a route goes and what it is made of, not how its
content lays out.

## Consequences

- The reported bug and 26 latent copies of it are gone, and the shape of the
  mistake is now unavailable.
- `bare: true` marks the four sheets that draw their own chrome
  (`modifier_sheet`, `line_item_action_sheet`, `printer_picker`,
  `table_detail_screen`). They were transparent-backed before and still are;
  the flag names the intent instead of leaving `Colors.transparent` to imply
  it.
- `showSatDrawer` has one consumer (the reservations filter rail). It exists
  because the alternative was an exemption, and an exemption is a hatch.
- Sheets that never set `isScrollControlled` grow taller when their content
  needs the room. Intended.
