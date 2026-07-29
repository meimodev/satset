# ADR-0062 — The phone bar is budgeted for a 360dp handset

## Status

Accepted. Amends ADR-0058, which gave the phone bar its contents; this one
gives it a height and a width budget. Serves `lib/ui/core/widgets/CATALOG.md`.

## Context

Three complaints about phone chrome, which turned out to be one measurement
problem and one unfinished half of ADR-0058.

**The bar was ~30dp taller than it reads.** `_phone` padded its top with
`l.topInset`, which `layout.dart` defines as `padding.top + 24`. That `+24` is
breathing room for screens that render *bare* — `me_screen`, `venue_hub_screen`,
`stub_screen` are all shell children with no chrome of their own. The app bar is
the chrome those screens lack, so paying the constant there stacked a bare
screen's allowance on top of a status bar the bar had already cleared.

The same token was doing the same thing one layer down. All four `topInset`
consumers are shell routes, none builds its own `Scaffold` or app bar, and every
one of them therefore rendered *under* `SatAppBar` while adding `statusBar + 24`
a second time. Every phone screen paid the status bar twice.

**ADR-0058 left the phone on `LoginClock` and the tablet on `_ShiftCluster`.**
Its reasoning was width: the phone row already carried two bordered clock badges,
so the sync indicator shed *its* border rather than the clock shedding its own.
That preserved two enclosures nobody had asked for, and left one concept — "what
time is it, how long have I been on" — with two implementations, two 1s timers
and two formats (`18:14:07` against `18:14 · Sab`).

**The bottom tab bar and the tablet rail disagreed on what "active" means.**
`_RailBtn` fills the active tab with `sc.accent` under both brutal and glow — on
Neon Terang, the shipped default (ADR-0057), a solid lime pill. `_Tab` filled it
with `sc.bg4`, a neutral. Same nav, same skin, two answers.

## Decision

**The phone bar is `padding.top + 56`.** The status bar inset and a fixed row,
nothing else. 56 rather than the tablet's 64: the tablet is read across a pass,
the phone at arm's length, and 56 still clears the 38dp back button with room.

**`topInset` keeps its meaning; its wrong callers are corrected.** The token is
right for what it was written for. The four shell screens move to a plain `Sp.s6`
— the breathing-room half of the token, with the duplicated status bar dropped.
Rejected: redefining `topInset` to shed the `+24`. That would have fixed the
chromed callers by breaking the bare ones the constant exists for.

**The phone adopts `_ShiftCluster` verbatim.** One clock widget, one timer, one
format, both layouts. The phone loses seconds off the wall clock and gains the
weekday. The elapsed counter beside it already proves the clock is live, so a
seconds digit ticking in permanent chrome is motion nobody acts on; the weekday
is worth more to someone reading a shift. `LoginClock` is deleted — after this it
had no production caller, only a widget-book entry that `SatAppBar`'s own entry
already covers.

**The shift cluster is shell chrome, so it yields to the back button.** They
occupy the same slot and never appear together. A screen you can back out of is a
task — menu, review, table detail, takeaway — and mid-order is not when you check
your shift clock. This is also the only way the row fits; see the budget below.

**The sync label is spent on the states that hurt.** On phone, `open` is the dot
alone. `connecting` and `offline` keep their words. "LIVE · LAN" costs ~72dp to
narrate the case that changes nothing, and design principle 6 wants the words on
the degraded states, not the healthy one. The dot still carries `open` — principle
3's "never inferable only from subtle colour" is satisfied by the two states that
alter what a waiter does next being labelled. The tablet is wide enough to say
all three out loud and is unchanged.

**`_Tab` mirrors `_RailBtn`'s active treatment.** Glow and brutal fill with
`sc.accent` over `sc.accentInk`; lembut keeps its deliberately quiet `sc.bg3`;
brutal keeps its ink rule. One hue vocabulary, learned once.

Rejected: extracting a shared `SatShape.navActive*` helper. The rail's
brutal-*paper* case cannot come across — there the rail **is** the accent slab,
so both states sit on a bright ground and take ink, while the phone bar is a
scrim over the page and behaves like every other skin. A two-call-site
abstraction that needs an `onAccentGround` escape hatch, and still leaves the
rail's border and hard shadow behind, is not paying for itself at n=2.

## The budget

Widths at `caption` 10px and `monoM` 13px in IBM Plex Mono (~0.6em advance),
admin account, worst case per column:

| Element | dp |
|---|---|
| `_ShiftCluster` (`SHIFT` + elapsed + `18:14 · Sab`) | ~208 |
| `_SyncStatus` bare, connected | 7 |
| `_SyncStatus` bare, `MENGHUBUNGKAN…` | ~105 |
| `SatBackButton` + gap | 48 |
| avatar + gap | 44 |
| horizontal padding (`Sp.s4` ×2) | 32 |

| Row | Needed | 360dp headroom |
|---|---|---|
| Shell — cluster, dot, avatar | 291 | 69 |
| Task — back, sync label, avatar | 184 | 176 |
| **Cluster + back together** | **~419** | **overruns 411dp too** |

**360dp is the floor, not the 411dp handset this gets eyeballed on.** The last
row is why the cluster and the back button are exclusive.

## Consequences

- Menu, review, table detail and takeaway show no clock on phone. Accepted:
  they are task screens, and the shell is two taps away.
- `trailingPills` has no production caller today. Adding one on phone spends
  from a budget with 69dp of headroom — check the table first. `CATALOG.md`
  carries the warning.
- `test/phone_app_bar_fit_test.dart` pins the two conditionals, because both
  look like cosmetic `if`s to anyone who has not done this arithmetic.
- That test asserts **structure, not pixels**, wherever the cluster is on
  screen. `flutter_test` has no real font — `SatType.useSystemFonts` falls back
  to no family and the test font draws every glyph as a square of the font size,
  so `18:14 · Sab` measures 143dp there against ~86dp on a device. The cluster
  overflows 360dp in the harness by 53px while fitting with 69dp to spare in
  production. The test drains that overflow deliberately. The back-button
  variant carries no mono text, fits under the fat font, and keeps a real
  overflow assertion.
- Consequence of the above: a genuine horizontal regression is invisible to the
  test suite. This budget and hardware are what cover it. Loading real IBM Plex
  metrics into the harness would fix that; `google_fonts` fetches over the
  network, so it is not free.
- Goldens untouched — the golden set covers the Controls group only, and this is
  all chrome (same reasoning as ADR-0058).
