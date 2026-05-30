# Ticket lifecycle timestamps & a unified service target

To report **speed of service** for the owner, a sent line now stamps two
lifecycle timestamps — `readyAt` (set once, on first entry into `ready`) and
`servedAt` (last-write, most recent serve) — alongside the existing `sentAt`.
From these the report derives **prep time** (`sentAt→readyAt`, kitchen
throughput) and **pickup lag** (`readyAt→servedAt`, food waiting at the pass).
A single configurable threshold, `VenueSettings.prepTargetMins` (default 15),
drives both the floor/audio **overdue** alert and the report **SLA hit-rate**.

## Why

The report claimed a "Time to ready" KPI computed as `closedAt − earliest
sentAt` — that is whole-visit length (kitchen + waiter + guest dwell), not
kitchen speed. It was mislabeled, not measurable: live tickets carried only
`sentAt`, with no ready/served event captured anywhere. The
`TableSessionCourses.firedAt/servedAt` columns are both *derived from* `sentAt`
(earliest sent / latest served-status sent), so they are a proxy, not real
timing. Honest speed-of-service requires capturing the events first.

We add the timestamps to the one generic `/tickets/:id/transition` write,
keyed off the `to` status, so no new endpoints or client gestures are needed —
cooks already tap `ready`, waiters already tap `serve`.

## Considered and rejected

- **Four timestamps (`prepStartedAt`, `cookedAt`, `readyAt`, `servedAt`).**
  Enables per-stage station breakdown, but cooks rarely tap every intermediate
  stage promptly, so `prep`/`cooked` times are noisy. More columns, more
  migration, softer data. Rejected for two clean signals.
- **`servedAt` only.** Cheapest, but collapses kitchen prep and waiter pickup
  lag into one number — loses the diagnostic split that tells the owner
  *whose* problem a slow plate is.
- **A `sentAt`-derived proxy, labeled "estimate".** Cheap but soft; would
  enshrine the same conflation the old KPI suffered from.
- **Two separate thresholds** (a report SLA distinct from the floor's 10-min
  overdue line). Rejected: two numbers drift apart and each needs explaining.
  One setting is the source of truth for both.

## Consequences

- DB migration **v22 → v23**: nullable `ready_at` / `served_at` added to
  `tickets` and `table_session_tickets`; `prep_target_mins` (default 15) added
  to `venue_settings`. Pre-existing rows keep `NULL` timestamps and are simply
  excluded from speed metrics (no backfill — the events never happened).
- `readyAt` is **set-once** so a waiter's `served→ready` undo does not inflate
  prep time; `servedAt` is **last-write**. A voided line carries neither.
- The two timestamps are mirrored into `table_session_tickets` at close, so the
  metric survives the live-ticket hard-delete.
- The hardcoded `_overdueMinutes = 10` in `elapsed_pill.dart` and
  `alert_sound_service.dart` now reads `prepTargetMins`. **On upgrade the
  overdue alert relaxes from 10→15 min** unless the owner tunes it down — an
  intentional behavior change, recorded here so it is not mistaken for a
  regression.
- **Per-station** speed is deferred: item→station routing was removed in
  migration v19 (`station` column dropped). The metric returns per-station only
  when routing does.
- Report tiles: the mislabeled "Time to ready" KPI is replaced by **median**
  prep time and **median** pickup lag (service times are right-skewed; mean
  misleads), plus a slowest-items table and an SLA hit-rate vs `prepTargetMins`.
