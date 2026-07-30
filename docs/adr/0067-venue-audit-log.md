# ADR-0067 — The venue audit log

## Status

Accepted. Adds a second, venue-scoped audit surface alongside the personal
feed defined in ADR-0065, and makes real two audit types that ADR-0065
observed could only ever read zero.

## Context

`GET /audit` is deliberately narrow. ADR-0065 rewrote it to return **the
caller's own rows for the current shift**, scoped from the bearer and never
from a query parameter, because the previous venue-wide behaviour leaked every
colleague's voids onto a personal screen.

The Venue Hub needs the opposite screen: who did what, across the venue, back
through history. Widening `/audit` would break the one property that makes it
safe. So this is a second endpoint behind a second permission, not a flag.

Three things the screen needs did not exist:

- **No amount.** Rupiah was formatted into the row's `title` text. A tile
  summing voids would have to parse a display string — a money figure derived
  from a label, wrong the first time the copy or the locale changes.
- **No durable attribution.** Rows carry `actorUserId`. `staffDeleted` is
  itself an audit type, so a read-time join blanks the actor on every row an
  ex-employee ever wrote.
- **Two dead types.** `AuditType.comp` and `.modify` were emitted nowhere. A
  comp is a void carrying reason code `comp` (ADR-0006) — but the void sheet
  offered no comp reason, so a comp was only *recorded* as one if someone
  happened to type the word into free text. Meanwhile the manual sold-out
  toggle, a genuine integrity event, wrote no row at all.

## Decision

`GET /audit/venue`, behind `viewReports` — the same permission as reports,
because both answer "what really happened in my venue".

**Admin rows need more.** Staff and role edits (`isAdminAuditType`) are
filtered out unless the caller also holds `manageStaff`, and they are filtered
out of the summary too. A count is a disclosure: "1 PIN reset" tells an
unauthorised reader the fact the row was hidden to protect.

**Keyset paging on `(at, id)`, never offset.** Rows arrive at the head while a
manager reads; an offset window silently re-shows or skips rows. The `id`
tiebreak is not decoration — a burst of voids lands in the same millisecond,
and `at` alone drops every row after the first at that instant. Both failures
are invisible on screen, which is why the test suite starts there.

**The summary is computed server-side over the whole filtered window**, and
rides page one only. Counting loaded rows would print "3 pembatalan" on a
venue with forty. Page, summary and CSV share one filter builder for the same
reason: three hand-rolled copies is how a tile ends up counting rows the table
below it does not show.

**`amountCents` is a magnitude, never signed.** Direction is carried by the
type, so a void, a comp, a discount and a refund all store a positive number
and every tile sums within one type. Nothing downstream has to decide what a
negative means; sign bugs on this screen are the expensive kind. Null where
money is not the point.

**Actor name and role are snapshotted at write time**, with a live join as
fallback for pre-v42 rows. An audit trail that a later rename or deletion can
rewrite is not one.

**Export is server-rendered and unpaged.** The client holds only the pages it
has scrolled; exporting local state would produce a file that stops wherever
the reader stopped — a truncated record carrying the word "lengkap". There is
no format picker: the log has one useful shape, and a 500-row PDF serves
nobody.

Two concepts are made real to feed it:

- Voiding with reason code `comp` now writes `AuditType.comp`, and the void
  sheet offers that reason on served lines — exactly the case that already
  required `compItem` rather than `voidItem`.
- The manual availability toggle writes `menuKilled` / `menuRestored` with an
  optional reason. **Only the manual path.** Auto-habis at zero stock is the
  stock trail's story; echoing it here would bury the human decisions this log
  exists to record under bookkeeping.

**Tablet only.** Six columns side by side is what lets a manager scan forty
rows for the one that looks wrong. The phone route renders an explanation and
the hub card carries a "Tablet saja" badge, so the limit is visible before the
tap — but the card still navigates, because an owner holding a handset should
learn the feature exists.

## Consequences

Rows written before schema v42 have no amount and no actor snapshot, and
comps among them remain typed as voids. The screen renders `—` rather than
guessing.

The tile set diverges from the design prototype. "Refire" is gone (ADR-0066),
and "Total events" is demoted to the sub-header in favour of a second money
tile — every tile now answers "did money move oddly?", which is what the
screen is for.

New audit types must be added to `auditTypeLabel` and `auditTone`; both are
exhaustive switches, so the compiler asks.
