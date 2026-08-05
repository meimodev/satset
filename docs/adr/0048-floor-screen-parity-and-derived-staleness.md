# ADR-0048 — The floor screen goes to parity, and staleness becomes a first-class signal

## Status

Accepted. Amends ADR-0047 (which declared layout untouched) and extends
ADR-0044 (silent floor states).

> **Amended 2026-08-05 by [ADR-0080](0080-self-order-and-token-pairing-removed.md).**
> The fourth `crit` rule below — "guest order still unreviewed", on
> `pendingReviewMins` — is gone with self-ordering. Threshold, setting and
> branch all removed; the other five rules stand as written.

## Context

ADR-0047 shipped the neo-brutalist skin as paint only: `SatR`/`SatB`/`SatBox`
reached ~800 decoration literals, and its closing consequence was explicit —
"Layout is untouched. Every token here is paint-level: no size, spacing,
breakpoint, or composition changed."

The SatSet v2 design project then reworked the floor screen itself, not its
colours. The tables screen there grew an owner chip, money and service pills, a
booking model, and a concept the app had no name for: a card that has been
**stuck** in one condition too long, banded across the foot of the card with a
severity. None of that is expressible as a token swap.

Meanwhile the screen it had to land on carried two always-on horizontal strips
(reservations, takeaway) above the zone tabs. Together they cost ~140px before a
waiter had looked at a single table, to show queues that are usually empty.

## Decision

### Composition changes for every theme; paint changes only under `brutal`

Shipping two information architectures for one screen — one per skin — would be
absurd, so the head restructure, the surfaces, the card anatomy and the grid are
unconditional across all six palettes. Paint is gated on `SatShape.brutal`:

| | `lembut` (4 palettes) | `brutal` (2 palettes) |
| -------------- | ------------------------- | ---------------------------- |
| occupied fill | `bg3` | `infoSoft` |
| pending fill | `bg3` + `warnSoft` rule | `warnSoft` |
| ready fill | `successSoft` | `successSoft`, ink numerals |
| status label | semantic colour, sentence | ink, uppercase, w700 |
| table numeral | `SatType.mono` | `SatType.display` (Archivo Black) |
| pills | 15% tint, tone text | full fill, ink rule, ink text |
| press | `scale(0.97)` | `translate(3,3)`, shadow off |

The neo palettes' `*Soft` tokens are near-saturation blocks; the lembut ones are
14% tints designed to sit *behind* a border. Painting a lembut card with them
would read washed out, so the four existing themes keep the look they shipped.

### Staleness: one banner, worst condition wins, thresholds from settings

`staleFor` returns at most one [[TableStale]] per card, ordered by severity and
then by how actionable it is:

| sev | condition | threshold |
| ------ | ----------------------------- | ------------------------------------------- |
| `crit` | ready, nobody collected it | `pickupTargetMins × 2` |
| `crit` | held table, guest not arrived | `reservationGraceMins` |
| `crit` | seated, still ungreeted | `ungreetedMins + ungreetedEscalateMins` |
| `crit` | guest order still unreviewed | **`pendingReviewMins`** (new, default 6) |
| `warn` | everything served, idle | `idleTableMins` |
| `warn` | long occupancy | `longStayMins` |

Not one of these is a constant. The source design hardcoded 4/6/8/20/100
minutes, four of which are near-misses of settings this app already ships — a
venue that sets `idleTableMins` to 40 would have got a banner at 20 anyway. The
two `crit` rules that read a *second* window past an already-cued threshold are
deliberate: this banner is for cues that went **unanswered**, so firing it at the
same moment as the sound would say nothing new.

`pendingReviewMins` is the one genuinely new threshold — nothing aged an
unreviewed guest order (ADR-0028). Schema v38, clamped 1–120, edited in
`/alerts` beside its siblings.

### The elapsed heat ramp is retired

ADR-0044 ramped the elapsed clock `textLo → warn → urgent` against
`longStayMins`. The banner now names that same overrun in words, with the action
attached ("Duduk 2:14 — cek penutupan"). Two encodings of one fact is the thing
Design Principle 3 warns about; the words survive, the tint does not.

The ready **pulse glow** goes the same way under `brutal` — it is a blurred
animated halo, and the skin has no blur anywhere (ADR-0047 §9). The `successSoft`
slab already shouts.

### Reservations are derived, never persisted

The design models a real hold: `TableStatus.reserved`, a no-show that *frees* the
table. That needs table-side state, a migration, routes, and WS events.

Everything the card and the book actually show is a function of the clock over
reservations the repo already holds — so it is computed, not stored:

- **hold** — a free table named by a pending booking between the start of the
  current business day (`businessDayStartHour`) and `kReservationHoldWindow`
  (60 min) from now. The **lower bound is load-bearing**: `pending` is only ever
  cleared by hand, so without it a single forgotten no-show would hold a table
  "Dipesan" indefinitely, and the floor would contradict a book that scopes
  itself to today. Found on device, not in review.
- **next** — the soonest pending booking beyond that window; a footnote on the
  card, shown on occupied tables too ("turn this by 20:30").
- **late** — pending past `reservationGraceMins`. Already how ADR-0044 does it:
  a clock must not decide a no-show, and auto-flipping would force `seated` to be
  reachable from `noShow` for the party that turns up at +46m.

**Accepted gap:** releasing a no-show frees nothing, because nothing was locked.
Two waiters can still seat walk-ins on the same booked table. Making the hold
real is a separate, larger change.

The source design's "Telat" button has no counterpart for the same reason —
there is no status to set.

### Triggers replace strips; the book gets a drawer

The head is now the zone title, its counts, and three counted triggers:
`Reservasi` (waiting count, plus an urgent `N telat` badge), `Bawa pulang`
(active count), and `Pesanan baru`.

`ReservationsBook` is built once and mounted two ways: a 480px right-side drawer
on tablet — the source's idiom for a surface read *against* the floor grid — and
a 92%-height bottom sheet on a phone, where a side panel is the whole screen.
Takeaway is a sheet on both: there is nothing in it to compare against the grid.

The phone gets the same card anatomy and the same triggers (icon + count, label
dropped for width). The source's phone card was never updated, but the
phone-carrying waiter is the busiest context this app has — withholding "ready 9
minutes, nobody collected it" from exactly that person is backwards.

### The grid equalises per row

CSS grid rows stretch to their tallest cell. `GridView.count` cannot: one
`childAspectRatio` sizes every cell on screen, and card height is now genuinely
variable — pills and the banner both come and go. Chunked `Row`s of 4 (tablet) or
`gridCount(minTileWidth: 180)` (phone) under `IntrinsicHeight` reproduce it with
no new dependency.

The cost is the grid's laziness, which is affordable: one zone is a dozen or two
cards, and `_CardFadeIn` was building all of them anyway.

### `forcePhoneView` leaves this screen only

The tables screen no longer reads `forcePhoneViewProvider`; layout comes from
`context.layout.useTabletShell`. The provider, its `me_screen` toggle and the
`app_shell` branch stay, so flipping it now wraps phone chrome around a
tablet-layout floor. Mismatched, not broken — a deliberate half-measure, since
removing the toggle is not this change's job.

> **Superseded by ADR-0049.** The provider, the toggle and the `app_shell`
> branch are now gone; layout class comes from hardware alone.

## Consequences

- `tables_screen.dart` drops from 968 to ~610 lines; the card, the two surfaces
  and the derivations live in `widgets/` and `view_models/floor_signals.dart`.
- New UI on this screen must branch on `SatShape.brutal` for *fills and type*,
  not just radii — the helpers cannot catch a colour choice.
- `onFill()` picks black or white by luminance rather than adding four `*Ink`
  tokens per palette, and **both** skins use it. The first cut hardcoded white
  on the lembut banner, which is ~2:1 on `warn` amber — the same class of defect
  ADR-0047 found in `successInk`, on the one element of the card a waiter has to
  read at a glance. If a fill ever reads wrong, that is the moment to make it a
  token.
- Adding a stale rule means one clause in `staleFor` and one string. Adding one
  without a `venue_settings` threshold behind it is the mistake to watch for.
- `floor_staleness_test` pins the precedence and that thresholds move with
  settings.
