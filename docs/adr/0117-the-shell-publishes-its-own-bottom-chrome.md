# The shell publishes its own bottom chrome

**Status:** Accepted — 2026-08-29.

## Context

The phone shell floats its tab bar **over** the page: a `Stack` with
`Positioned(bottom: 12)` holding a 64-high translucent slab, not a
`Scaffold.bottomNavigationBar`. That is a deliberate look, and it means the
page's own bottom 76 logical pixels are unusable — a scroll view that ends at
the screen edge ends underneath the bar.

`SatLayout.bottomInset` existed to pay for that: `padding.bottom + (useSideRail
? 16 : 92)`. Eleven call sites used it out of 118 vertical scroll views in 53
files. The other screens either hardcoded a bottom of `120` — the same remedy,
spelled as a literal, in `kitchen_screen`, `reports_screen`, `staff_screen`,
`system_screen` and `venue_settings_screen` — or paid nothing at all.

Three things were wrong with the token, and they were all the same thing.

**It answered a question nobody asked.** `SatLayout` is built from
`MediaQuery`, so `bottomInset` could only say *is this a phone*. The question a
scroll view has is *is there a bar below me*, and the two differ. `MenuScreen`
and `ReviewScreen` are mounted **both** inside the shell (`/counter`, ADR-0109)
and pushed outside it on the root navigator (`/table/:id/menu`, `/order/new`,
`/takeaway/:visitId/menu`). Same widget, same width, one bar between them. On
the pushed mounts those screens padded 92px for chrome that was not there, and
floated their own action footers 92px up the screen for the same reason.

**It keyed off the wrong predicate.** `useSideRail` is true on a compact
landscape device and on the 600–1023dp band, but the floating bar renders
whenever `useTabletShell` is false. A 7" tablet in that band therefore drew the
bar and got 16px of clearance.

**It was optional.** A rule that lives in a getter is a rule every new screen
has to remember, and 42 of the 53 files did not.

## Decision

**`AppShell` publishes its bottom chrome downward, and `SatLayout.bottomInset`
is deleted.**

`ShellInset` (`lib/ui/core/design/shell_inset.dart`) is an `InheritedWidget`
carrying one double. The phone branch of `AppShell` wraps its child in it with
`_tabBarGap + _tabBarHeight`, the same two constants the `Positioned` and the
bar `Container` now read. `context.shellInset` returns **0** where there is no
`ShellInset` above — the tablet shell, which rails instead of floating, and
every root-navigator push.

Consequences that fall out of that, rather than being decided separately:

- The dual-mounted screens are correct on both mounts without knowing which
  they are on, and their floating footers become
  `Sp.s4 + context.shellInset + l.padding.bottom` — unchanged geometry inside
  the shell, 76px tighter outside it.
- The `useSideRail` band bug disappears, because the number now comes from the
  widget that draws the bar rather than from a guess about the device.
- `AdminPage` (`admin/_common.dart`) adds it once inside its own
  `SingleChildScrollView`, paying for nine admin screens in one place.
- A screen's own footer clearance stops hiding inside the same number. Where a
  screen floats a bar over its content it names its own constant
  (`_cartFooterClearance`, `_sendBarClearance`, `_actionStackClearance`) and
  stacks it: `shellInset` clears the tab bar, the constant clears the footer.

**And a test, because 53 files is not a rule anyone remembers.**
`test/shell_inset_test.dart` holds the list of files mounted inside
`ShellRoute` and asserts two things: that the list still matches what
`app_router.dart` mounts, and that every listed file building a vertical scroll
view mentions `shellInset`.

## Alternatives

**Sprinkle the existing token into all 53 files.** Rejected: it preserves the
bug — the token cannot tell the two mounts of `MenuScreen` apart, so the sweep
would have written the wrong answer into three more places.

**Inject the padding through `MediaQuery` at the shell.** Rejected as a
half-measure. `ListView` does not consume `MediaQuery.padding`, so it would
have silently helped only the screens already reading it, which are the
screens that were already correct.

**Stop overlaying: `Scaffold(bottomNavigationBar:)`.** This makes the problem
not exist — layout reserves the space and no screen changes. Rejected because
it is a visual redesign, not a padding fix: the floating bar's 8px side inset,
22px radius and skin-dependent shadow are the phone chrome's whole character.
Worth revisiting as a design decision on its own; it should not arrive
smuggled inside a bug fix.

**A site-granular test with per-site exemption markers.** Rejected: a regex
cannot see nesting, and these files hold sheets, dialogs and horizontal chip
rows alongside their page scroll. Every one would need a marker, and markers
that appear 60 times stop being read. The file-granular ban is the weaker
guarantee that catches what actually happens — a whole screen shipping with
none — at no false-positive cost. A screen whose only scroll views are in
sheets opts out once, with a reason, via `// no-shell-inset:`.

## Consequences

Adding a top-level shell destination, or a new route inside `ShellRoute`, now
fails `shell_inset_test` until the screen's file is listed. That is the point:
the list is what makes the second assertion able to see the screen at all.

Screens that were padding `120` now pad `Sp.s6 + shellInset` — 100 on a phone
under the bar, 24 on a tablet, where the old literal wasted 96px on every
admin screen.

The floating bar still ignores the system gesture inset (it sits 12px from the
physical bottom edge, not from the safe area). `shellInset` describes the bar,
so it does not add `padding.bottom` either. Content that clears the bar
therefore clears the gesture area too. If the bar is ever moved to respect the
safe area, the constant moves with it and nothing downstream changes — which
is the property this ADR is buying.
