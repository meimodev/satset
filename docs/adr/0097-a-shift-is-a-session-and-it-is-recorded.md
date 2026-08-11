# ADR-0097 — A shift is a session, and it is recorded

## Status

Accepted. **Supersedes [ADR-0065](0065-a-shift-outlives-the-staff-session.md)**
on the shift boundary and on the two exits; leaves the rest of that ADR
standing (ownership by `lastActorId`, the live-snapshot Saya tab, attribution
stamped server-side). Rescopes the `GET /audit` window ADR-0065 set.

## Context

An owner asked which staff turn up diligently and which do not. The app could
not answer, and the reason was structural rather than a missing screen:
**nothing recorded attendance at all.**

- `Users.shiftStartedAt` was one nullable stamp, overwritten by every sign-in
  and cleared by "Akhiri shift & keluar". It answered "is a shift running, and
  since when" and nothing else. There was no history to report on.
- Session rows are deleted on logout, so the token table recovers nothing
  either.
- The audit log records *acts*, not presence. A waiter who worked a full
  service and voided nothing leaves no trace in it.

So the report had to be built on data that did not exist yet, which made the
storage question the first one rather than a detail: derive attendance from
sales activity, or record it.

Deriving it is tempting — every seeded venue already has orders stamped with an
actor — but it measures the wrong thing twice over. A kitchen account takes no
orders and would read as permanently absent. A waiter who arrives on time to a
dead Monday and takes their first order at 13:00 reads as three hours late. And
prep, setup, cash-up and standing about are exactly the diligence being asked
about, none of which produce a row.

Recording it needs somewhere to put it, and the shift boundary ADR-0065 chose
then became load-bearing in a way it had not been. Under that boundary a shift
spans logins: hand the handset over, sign back in, same shift. One row per
shift is then one row per *business day*, and a person who signed in at 11:00,
vanished for three hours and came back at 17:00 is indistinguishable from one
who worked straight through. The gap is the answer to the owner's question, and
that boundary erases it.

The user resolved the tension directly by removing the other side of it: they
asked for the shift-preserving "Keluar" to go. With one exit, a session and a
shift have the same edges, and a handover is what it looks like — a clock-out
and a clock-in.

## Considered options

**Derive attendance from order timestamps** (rejected). No schema, no new
writes, and it works retroactively on the fabricated month. Rejected for
measuring output and calling it presence: silent on kitchen accounts, wrong on
quiet days, and it cannot see the half of a shift that produces no orders. An
owner disciplining someone on this number would be disciplining them for a slow
Monday.

**Keep ADR-0065's boundary and record one row per shift** (rejected). Cheapest
change on top of what existed. Rejected because a shift that spans logins is a
day-long row: the three-hour disappearance is inside it, and the report reads
100% present for someone who was not.

**Keep both exits and record one row per *session*** (rejected). Full
resolution, no behaviour change. Rejected because two exits with different
recording consequences is a trap: the frequent, prominent, unconfirmed one is
the one that hides the gap, so the report is accurate exactly when nobody uses
the button. A measurement anyone can quietly opt out of by tapping the obvious
control is not a measurement.

**One exit; a shift *is* a signed-in session; one row per session** (chosen).
The boundary and the recording agree, the gaps are visible, and there is no
control whose purpose is to make them invisible.

## Decision

**A shift is a signed-in staff session.** It opens at PIN sign-in and closes at
sign-out. Signing in never resumes anything — every sign-in opens a new row.

**One exit, and it is named plainly: "Keluar".** It is the only way out. The
shift-preserving exit, its confirmation copy and the `endShift` field on
`POST /auth/logout` are all deleted. The shorter label survives the merge: the
longer "Akhiri shift & keluar" existed to distinguish two exits, and with one
left the distinction it draws is against nothing. Ending the shift is no longer
an option the label must warn about — it is what signing out *is*, and the
elapsed shift clock sits directly above the button. A **Server-mode admin still
confirms**, unchanged and for the unchanged reason: their sign-out kills the
venue's server (ADR-0015), which is not a thing to do by mis-tap.

**Shifts are recorded in their own table, never derived.** `Shifts`
(`id`, `userId`, `startedAt`, `endedAt`, `endedBy`, `lastActivityAt`), written
through `lib/server/shift.dart` and nothing else — the same one-writer rule
`writeAudit`, `cash.dart` and `members.dart` hold, for the same reason.
`Users.shiftStartedAt` is dropped, its open rows migrated forward.

**A forgotten sign-out is closed by the business-day rollover, and flagged.**
An open row still open past its own rollover (`businessDayStartHour`, default
04:00) is retired with `endedBy: rollover`. `endedAt` records the boundary that
closed it and `lastActivityAt` records the person's **last audited act** inside
the window — two columns, because they are two different facts and collapsing
them loses whichever one the next question needs. Neither is a measurement:
rollover-closed shifts **contribute nothing to the hours total**, and are
counted separately and shown as a flag. A row that ran to 04:00 would otherwise
put a fabricated eleven hours on a report read as attendance, and an estimated
duration that looks like a measured one is worse than an absent one. A shift
whose whole span produced no auditable act leaves `lastActivityAt` null; it
still contributes zero minutes and still carries the flag.

**`endedBy` is `manual` or `rollover`, and those names are persisted** in
`shifts.ended_by`. Renaming either orphans every existing row, the same rule
that already binds `AuditKind`, `CashEntryKind` and `MemberPointKind`.

**`GET /audit` is rescoped from the shift window to the business day.** Under
ADR-0065 the shift window and the day were near enough the same span; under one
row per session they are not, and a waiter who signed out for a break would
have watched their own void list empty. The Saya tab answers "today", which is
what it always meant.

**Jam kerja is a section inside `/reports`**, gated `viewReports` like every
other section, fed by `shiftReportSection`. It reports hours, days, shift
count, median first sign-in and unclosed count per person. It is **read-only**:
there is no editing `endedAt`. An owner who can adjust the hours their staff
are judged on is not reading a record.

**The seed writes shifts through the live path.** The fabricated month gives
each seeded staff member a deliberately uneven attendance shape — an absent
rate, a punctuality range, a forget-to-sign-out rate, a split-day rate — with
each day's times bracketed from that person's own seeded orders. A forgotten
sign-out is seeded by *omitting* `endShift` and letting the next day's sign-in
retire the row, not by fabricating a `rollover` row. A flag nobody has seen is
a flag nobody understands the first time it appears for real.

## Consequences

An owner can compare hours, days and punctuality across staff, and a forgotten
sign-out shows as a flag rather than as an eleven-hour day.

The costs we accept:

- **The report starts empty on every existing venue.** No history is
  recoverable — there was never any to recover — so the block is only as old as
  this release. Migration carries forward open shifts and nothing else.
- **Hours under-report time worked.** Handing your handset to a colleague now
  costs you a clock-out, and the minutes until you sign in elsewhere are yours
  and go uncounted. ADR-0065 bought that continuity and this ADR sells it back;
  what it buys is that the same mechanism can no longer hide an absence.
- **Handover costs two taps.** The exact friction ADR-0065 removed, restored
  deliberately.
- **`lastActivityAt` is only as good as the audit log.** A person whose whole
  shift produced no auditable act and who forgot to sign out closes at their
  own `startedAt` — zero minutes, flagged. Under-reads, never over-reads, which
  is the direction to fail in.
- **Nothing enforces one open shift per person across devices.** Signing in on
  a second handset while the first is still signed in opens a second row, and
  both count. Two concurrent sessions is already an unusual state; making it
  impossible would mean revoking a live session from under someone mid-service.
