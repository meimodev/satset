# ADR-0081 — Two tickers: readout and threshold

Status: accepted
Date: 2026-08-05

## Context

Live time displays had grown five independent heartbeats:

| where | mechanism | cadence |
| --- | --- | --- |
| `elapsed_pill.dart` | `StreamProvider` | 30s |
| `table_card.dart` | `StreamProvider` | 1s |
| `kitchen_screen.dart` | `Timer` + `setState` | 1s |
| `me_screen.dart` | `Timer` + `setState` | 1s |
| `sat_app_bar.dart` | `Timer` + `setState` | 1s |

Three cadences, and two of the timers called `setState` on a whole screen. The
KDS re-grouped every live ticket and rebuilt a menu-wide prep-time map sixty
times a minute so that one station timer could advance a digit. Every table card
on the floor re-scanned the reservation list twice a second for the same reason.

Underneath the mess were two genuinely different things, never named:

- Numbers that **move** every second and that nothing branches on — the station
  timer, the seated counter, the shift counter.
- State that **changes** when the clock crosses a boundary — a table going
  *basi*, a batch turning late, an overdue tint, a progress ring.

Everything in the second group compares `.inMinutes` against a venue setting
(`ungreetedMins`, `idleTableMins`, `longStayMins`, `reservationGraceMins`,
`prepTargetMins`). Such a comparison can only change its answer when the wall
clock flips a minute. Recomputing it at 1s costs 59 wasted passes a minute;
recomputing it at 30s means it can be reported up to 30s late, on a different
offset per device, for a threshold the venue configured in whole minutes.

## Decision

Two shared providers in `lib/ui/core/state/tickers.dart`, and nothing else may
own a clock heartbeat:

- `secondTickerProvider` — each wall-clock second. **Readouts only**, watched
  from the smallest widget that renders the digits.
- `minuteTickerProvider` — `:00` of each wall-clock minute. Everything that
  branches on time.

The rule, stated once: **if you branch on it, watch the minute ticker.**

The minute ticker is *aligned to the boundary*, not periodic. A
`Stream.periodic(60s)` begins its period when the first widget subscribes, so a
crossing at 12:05:00 surfaces at an arbitrary offset into the minute. Aligning
means a `.inMinutes` comparison is re-evaluated exactly when its answer can
change — never late, never redundant. Both tickers re-derive their delay from
`SatClock` on every iteration rather than trusting a fixed period, so a sleeping
device or a jumped clock resynchronises on the next tick instead of drifting for
the rest of a shift.

Both are `autoDispose`: no timer runs when nothing is watching.

## Consequences

- `elapsedTickerProvider` and `tableElapsedTickerProvider` are deleted; the
  three raw `Timer`s go with them.
- A card body and its seconds label now watch *different* tickers. That split is
  the mechanism, so it is guarded by a rebuild-count test rather than left to
  reviewers to notice.
- A time-derived state that forgets to watch `minuteTickerProvider` will not
  repaint until some unrelated event rebuilds it — a table that never turns
  *basi*. `floor_staleness_test.dart` asserts the transition happens with zero
  provider events, which is the shape that regression takes.
- The alignment is invisible from a call site and reads like an over-complicated
  `Stream.periodic`. It is not: reverting it reintroduces per-device lateness on
  every threshold in the app. This ADR exists mostly to say so.
