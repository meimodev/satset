# ADR-0058 — The app bar carries the crumb trail

## Status

Accepted. Reconciles `SatAppBar` against the design source's top bar, in the
manner of ADR-0051. Serves `lib/ui/core/widgets/CATALOG.md` and ADR-0054's
widget book.

Amended by ADR-0062, which gives the phone bar a height and a width budget.
Two decisions below no longer hold: phone no longer keeps `LoginClock` (it
adopts `_ShiftCluster`, and `LoginClock` is deleted), and the phone clock is
now conditional on there being no back button.

## Context

`SatAppBar` declared four public parameters — `title`, `crumbs`,
`trailingPills`, `showAvatar` — and read none of them. Both `build` branches
rendered the same fixed row: back button, `LoginClock`, network pill.

Nine call sites passed `crumbs`. `tablet_chrome.dart` and `app_shell.dart` both
computed a trail per route and handed it over; `table_detail`, `menu`, `review`
and `takeaway_detail` each built one from live table state. Five passed
`title`, two of them alongside `crumbs` for the same screen. Two book entries
passed `trailingPills`. All of it was dropped on the floor, silently, in every
palette. Nobody noticed because the bar looked deliberate: it just never said
where you were.

The design source (`tablet-app.jsx` `Shell`, `screens.jsx` `TopBar`) had
answered the layout question already, and differently per form factor:

- **Tablet** `.tab-topbar` — 64h, crumbs left, then a right cluster of sync
  pill, shift elapsed, wall clock. The crumb trail *is* the left half of the
  bar. No avatar; the rail's foot carries it.
- **Phone** `.topbar` — three slots: leading (zone switch or back), a bare
  dot-and-label sync line, and a 32px avatar. No crumbs, no clock at all.

## Decision

**Crumbs are the bar's label. `title` is deleted.** One way to say where you
are, not two that disagree. The eight surviving call sites all already passed
an equivalent trail, so the migration was arg removal, not rewriting.

**The structure lands in every palette; only the look stays skinned.** The
temptation was to gate this on Neon Terang, since that is the palette the
design source is drawn in. Rejected: the params being dropped is a bug, and a
bug is not a palette choice. Shape continues to come from `SatShape.skin`
through the existing `_resolveBg` / `_rule` switches, and colour continues to
come from `context.sat`. There is no `SatTheme`-named branch in the widget —
adding one would have doubled the layout permanently and left crumbs broken in
five palettes.

**Tablet drops the badge chrome; phone keeps it.** The tablet bar now carries
crumbs, a sync pill, elapsed and a wall clock in one row. `LoginClock`'s two
bordered, icon-led badges made that four enclosures across a 64h slab. The
tablet gets bare label/value pairs instead (`SHIFT` in `caption` over `textLo`,
values in `monoM`), matching the source. Phone keeps `LoginClock` unchanged and
instead sheds the *sync* pill's border, for the same reason in reverse: its row
already holds two badges.

**Phone keeps the clock the design source doesn't have.** The mock has no shift
state to show, so it spends that space on a zone switcher. A waiter on shift
does have shift state, and the elapsed timer is the number they check. The
avatar is adopted, the zone switcher is not, the clock stays.

**Phone ignores crumbs.** At 402px, minus a back button, two clock badges, the
sync line and an avatar, the trail's slot is around 120px — it would truncate
to its last segment on nearly every screen. The parent is one back-tap away.
`showAvatar` inverts along the same seam: on by default, off on tablet, where
`TabletSideRail` owns the avatar.

**`neo-skin-btn` is not ported.** It is a mock-side dev affordance, sibling to
`TweaksPanel`. The theme picker lives in `/me`.

## Consequences

- `SatAppBar.title` is gone. Eight call sites migrated; `menu`, `review`,
  `table_detail` and `takeaway_detail` simply lost a redundant argument.
- `formatBarClockId` is hand-rolled rather than `DateFormat(..., 'id_ID')`. The
  bar builds on first frame and a widget test mounting it directly threw
  `LocaleDataException`; seven weekday strings are not worth an init
  dependency. The trade is that this one string does not follow the locale — it
  is Indonesian-only, like the rest of `app_strings.dart`.
- The tablet bar now shows a second-ticking elapsed and a minute-precision wall
  clock. Two second-ticking numbers side by side read as a race, so only the
  one a waiter actually times against gets seconds.
- `_ShiftCluster` runs a 1s timer whenever a tablet bar is mounted, as
  `LoginClock` already did on phone. One timer per bar, disposed with the state.
- Goldens were untouched: the golden set covers the Controls group only, and
  `SatAppBar` is chrome.
