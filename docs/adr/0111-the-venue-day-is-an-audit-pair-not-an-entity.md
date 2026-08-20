# The venue day is an audit pair, not an entity

**Status:** Accepted — 2026-08-20.

## Context

A small shop opens and closes as a ritual: put the float in the box, trade, count
the box, read the day's numbers, go home. In a venue with one or two staff that
ritual is the only control there is — nobody supervises the person on the till, so
the discipline of counting at a fixed moment is what makes a discrepancy visible
at all.

Every part of it already exists and every part lives somewhere else. [[Shift]]
opens at PIN sign-in. The float and the count go through `cash.dart`. The numbers
come from Reports. What does not exist is the **sequence**, and — more
interestingly — nothing in the schema knows whether the venue is open. There is no
venue-wide open state anywhere; `guestHoursStartMin` / `guestHoursEndMin` gate the
guest plane's ordering window and nothing else.

The obvious move is a `venue_days` table: opened, closed, by whom, with the float
and the count hanging off it. It is also the move that quietly adds a second
day-boundary concept beside `businessDayStartHour`, and a piece of state that can
get stuck.

The pull the other way is ADR-0097, which is emphatic that a [[Shift]] is **one
staff member's session** — per-account, opened by sign-in, closed by sign-out or
by the business-day rollover. Opening the shop is venue-wide and happens once. A
shift cannot carry it, and stretching it to would undo the boundary ADR-0097 chose
precisely so a three-hour disappearance stays visible.

## Decision

**1. No entity.** "Buka kedai" and "Tutup kedai" are a **screen** that sequences
writers that already exist. Nothing new is persisted about the day itself.

**2. The record is two audit rows** — `AuditKind.venueOpened` and
`AuditKind.venueClosed`. "This happened, by whom, at this time" is exactly what an
[[Audit]] row is, it costs no table, it is already paged and exportable and
locale-composed at read time (ADR-0085), and it inherits `writeAudit`'s single
door. A venue day is a *thing that happened*, not a thing with a lifecycle.

**3. The two reserved capabilities get wired.** `Capability.openDrawer` and
`Capability.closeShift` have been granted in `seed_data.dart` and checked by
nothing since they were added. They name this act; they gate it now.

**4. Closing records; it does not enforce.** Open bills, unfired courses and live
tickets do **not** block a close. The screen may say what is still open — that is
useful — but a cafe with one unpaid tab still has to go home, and a close that
refuses would be routed around by simply not using the screen, which loses the
record that was the whole point.

**5. Two things are deliberately outside the sequence.** [[Opname]] — it is a
session document with its own archive and its own cadence (ADR-0096), and stapling
a stocktake to every closing is how a stocktake becomes a rubber stamp. And staff
**sign-out** — that is each person's own shift, per-account, and the last person
out closing the shop is not the same act as three people clocking off.

## Consequences

- There is no state to get stuck in. A venue that is never "closed" has a gap in
  its audit log, which is honest, visible and reportable — as against a boolean
  stuck `true` that nothing repairs.
- Nothing derives "is the venue open right now" from these rows, and nothing
  should. The guest plane keeps deciding on `guestHours`; the floor keeps deciding
  on nothing at all.
- Two new `AuditKind` values means an ARB entry in both locales, and the exhaustive
  `switch` in `auditText` will say so. Neither name may ever be renamed.
- Because the pair is only a record, the same day can carry two opens or none.
  Reports reading them must treat the sequence as evidence, not as a state machine.

## Alternatives

**A `venue_days` table** (rejected). The obvious model, and it would let the close
screen show "you opened at 07:12" without a log query. Rejected for adding a
second day boundary next to `businessDayStartHour` — two answers to "what is
today" is exactly the drift this codebase keeps eliminating — and for introducing
a row that can be left open forever with no rollover to retire it.

**A venue-scoped row in `Shifts`** (rejected). Reuses a table shaped almost right,
and inherits the rollover that retires forgotten rows. Rejected because ADR-0097
defines a shift as a person's session and reports hours off it; a row with no real
`userId` would either corrupt the hours report or need excluding from it
everywhere, which is a special case in every reader.

**A boolean on `venue_settings`** (rejected). One column, trivially cheap.
Rejected because it is state that can be wrong with nothing to repair it, and it
records only the current value — losing "who opened, and when", which is the fact
the owner actually wants.
