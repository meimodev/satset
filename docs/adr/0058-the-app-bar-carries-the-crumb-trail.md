# ADR-0058 — The app bar carries the crumb trail

## Status

Accepted. Reconciles `SatAppBar` against the design source's top bar, in the
manner of ADR-0051. Serves `lib/ui/core/widgets/CATALOG.md` and ADR-0054's
widget book.

Amended by ADR-0062, which gives the phone bar a height and a width budget.
Two decisions below no longer hold: phone no longer keeps `LoginClock` (it
adopts `_ShiftCluster`, and `LoginClock` is deleted), and the phone clock is
now conditional on there being no back button.

Amended again (see "Unlisted shell routes belong to the Venue hub" below) after
`/stock` and `/alerts` shipped with the rail lighting up Meja: the trail and the
rail item now come from one mapping, and the shell's default destination
inverted from `tables` to `venue`.

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

## Amendment — unlisted shell routes belong to the Venue hub

### Context

`app_shell.dart` computed the trail and the rail's active item in two parallel
hand-written switches over the same paths — `_activeFor` and `_crumbsFor`. Both
were allowlists that ended in a fallthrough, and the fallthroughs disagreed:
`_activeFor` defaulted to `'tables'`, `_crumbsFor`'s `venue` case defaulted to
`Konfigurasi`.

`/stock` and `/alerts` were added to the Venue hub and to neither switch. The
result: opening Stok or Peringatan lit up **Meja** in the side rail and captioned
the screen `Venue › Konfigurasi`. Two further liars came from the same shape —
`/venue`, the hub root, claimed its own settings child's label, and `/kasir` had
no case at all, so it fell to the `[venue › zone]` trail meant for `/tables`.

Three bugs, one cause: two allowlists that have to be edited in lockstep, and a
default in each that asserts something specific and false.

### Decision

**One mapping, both answers.** `venueHubCrumbs` maps a hub path to its trail's
tail segment. The rail reads it (anything absent is `venue`), the crumb reads it,
and the two can no longer drift. `activeTabFor` and `crumbsFor` are top-level, so
they are checkable without pumping a shell.

**The default inverted to `venue`, not `tables`.** `_railRoutes` now lists the
six destinations that own a route outright, and *everything else* is a hub child.
The alternative — keep the allowlist and add the two missing entries — fixes this
instance and leaves the trap armed for the next hub screen. The inversion picks
which mistake is possible: the hub grows children often, and those now self-heal;
the app grows top-level destinations rarely, and forgetting one is the loud
failure. That is the trade, and it is deliberate.

Route metadata (a `tab` on each `GoRoute`) was rejected as the fix. It removes
the mapping entirely, but rewrites every route for a mapping that is still one
small function.

**Missing entries fail short, never confident.** A hub path with no entry renders
`[Venue]` — one truthful segment — rather than borrowing a sibling's label. Same
for the hub root. `Konfigurasi` is now attached to `/venue-settings` explicitly,
which is the only path it was ever true for. Deriving the tail from the path was
rejected: it emits English into a Bahasa Indonesia UI, against `AppStrings`.

**Matching is on the first path segment, not `startsWith`.** The old chain had a
latent ordering trap — `/menuadm` starts with `/me`, and only survived because
`/menuadm` happened to be tested first. Segment matching removes the whole class.

### Consequences

- `/kasir` gets a single-segment `[Kasir]` trail. It reads flatter than its
  two-segment siblings (`Stasiun › Antrian Persiapan`); the alternative needed
  new copy for a second segment that the screen's own Aktif/Riwayat tabs would
  immediately make stale.
- `crumbsFor`'s `default:` is now reachable only by `'tables'` — the one case the
  `[venue › zone]` trail was written for.
- **A new top-level destination that is not added to `_railRoutes` will show
  Venue as active.** This is the accepted cost of the inversion.
- `test/shell_active_tab_test.dart` pins path → (rail item, trail) for every
  shell route, plus the `/menuadm`-vs-`/me` collision and an unmapped hub path
  asserting the short trail. Pure functions, no pump.
