# ADR-0065 — A shift outlives the staff session

## Status

**Superseded on the shift boundary and the two exits by
[ADR-0096](0096-a-shift-is-a-session-and-it-is-recorded.md)** — a shift no
longer outlives the session, "Keluar" no longer preserves it, and
`Users.shiftStartedAt` is gone. The rest of this ADR stands: ownership by
`lastActorId`, the live-snapshot Saya tab, server-side-only attribution, and
`GET /audit` scoped from the bearer with no query parameter and no row limit
(ADR-0096 widens its *window* to the business day).

Accepted. Redefines the [[Shift]] boundary previously implied by
ADR-0004 (PIN + JWT sessions), and carves one exception out of ADR-0015
(the local server is bound to a valid admin session).

## Context

The "Saya" tab presented itself as a shift summary but was wired to almost
nothing that survived a round trip. Auditing it end-to-end surfaced five
separate breaks, and fixing them forced one genuine domain question.

The mechanical breaks:

- **Table ownership was a phantom.** `VenueTable.mine` was set optimistically
  on `seat` / `markPending` and never restored by `_toDomain`, so any WS
  update, resync or relaunch silently reset it to `false` and emptied every
  metric on the screen.
- **Audit was venue-wide.** `actorUserId` existed on the DB column, was
  stamped server-side, and was serialised into every payload — and then
  dropped by the client DTO. A waiter who had voided nothing read the whole
  venue's voids under their own face, in urgent red.
- **`GET /audit` was unbounded**, shipping the venue's entire integrity log to
  every handset at boot to render five rows.
- **One KPI could only ever be zero.** "Comp / modif" counted
  `AuditType.comp` + `AuditType.modify`, neither of which is emitted anywhere
  in the server — a comp is a void carrying reason `comp` (see the [[Comp]]
  glossary entry), so it was already inside the void count.
- **The pacing card was inverted.** `openTickets / shiftMinutes × 60` divides a
  live stock by a shift-long flow: it read highest when a waiter was furthest
  behind and reached `0.0 tiket / jam` at the end of a well-run shift.

The domain question underneath: **`Users.shiftStartedAt` was a dead column.**
No route read or wrote it; the shift clock lived entirely in device-local
secure storage under a single `loginAt` slot. That works until you notice the
handsets are shared. A waiter who hands their phone to a colleague and picks
up another one starts a brand-new shift on the second device, and the first
device's slot has already been overwritten by whoever signed in after them.

## Considered options

**Keep the clock device-local** (rejected). Zero server work, and it matches
the old glossary wording exactly — "bounded by login and logout", so a fresh
sign-in legitimately *is* a fresh shift. Rejected because it makes a shift a
property of a *device* while every other thing about a shift is a property of
a *person*. The behaviour is only defensible by reading the definition
narrowly, and the definition was written to describe the implementation rather
than the intent.

**Server-authoritative, cleared on sign-out** (rejected). Puts the value on
the existing column and makes concurrent sessions agree, but is otherwise
observationally identical to the device-local version: signing in on a second
handset still restarts the clock, because that is still a new login. It pays
for a server round trip and buys nothing a waiter can perceive.

**Server-authoritative, business-day boundary only** (rejected). Delivers
cross-handset continuity, but "Akhiri shift & keluar" becomes a lie — it would
end the session and leave the shift running. Losing the ability to deliberately
close a shift is worse than the problem being solved.

**Server-authoritative, spans logins, ended explicitly *or* by the business-day
boundary** (chosen). Both concepts stay honest: sign-out-and-return resumes
your shift, and the button that says it ends your shift ends it.

We also considered, and declined, making the summary **cumulative** — closed
`TableSessions` filtered by actor and shift window, which would have added a
sales figure and an honest tickets-per-hour rate via a self-scoped
`GET /me/shift`. Declined as scope: the live-snapshot reading answers "what is
on my plate", the question a waiter mid-rush actually has. The cost is that the
screen carries no money at all, and that closing a table makes its numbers go
*down*.

## Decision

A **shift** is server-side state on `Users.shiftStartedAt`, opened at PIN
sign-in and **resumed** by any later sign-in within the same business day.

**Two exits, and the hierarchy follows frequency rather than severity of name.**
"Keluar" — prominent, no confirmation — drops the session and leaves the shift
running; handing over a handset happens many times a service. "Akhiri shift &
keluar" — quieter, confirmed, and it spells out the consequence — closes the
shift; that happens once. `POST /auth/logout {endShift}` carries the
distinction, one route and one field, so the two effects stay atomic.

**A Server-mode admin gets only the shift-ending exit.** Their sign-out kills
the venue's server regardless (ADR-0015), so a shift-preserving exit would be,
for that one user, the most destructive action in the app wearing the
lightest-weight label. Admin-clients host nothing and get both.

**The business-day boundary retires a forgotten shift.** `openShiftOf` reports a
stamp older than today's rollover as absent without erasing it, so
`GET /auth/me` cannot hand an overnight token yesterday's clock, while only a
login re-anchors it. Working past midnight stays one shift.

Consequently:

- **Ownership is `lastActorId == meId`** — the same server-authoritative key
  ADR-0056 gave the Pesanan board. `VenueTable.mine` is deleted.
- **`GET /audit` is scoped from the bearer and bounded by the shift window**,
  never by a query parameter and never by a row limit. A limit would make
  "3 pembatalan" mean "3 among the rows that fit". It **fails closed**: no
  session or no open shift yields an empty list.
- **Attribution is stamped only server-side, from the JWT.** `POST /audit` is
  deleted rather than hardened — its sole client caller was dead code, and void
  attribution is evidence (ADR-0006), never a client-supplied field.
- **The summary is a live snapshot**, labelled in the present tense, with no
  sales figure and no rate.

## Consequences

A waiter can hand over or swap handsets without losing their shift, and the
"Saya" tab shows their own numbers rather than the venue's — which it never did
before, on any device, after the first WS update.

The costs we accept:

- **The counts go down as the night goes well.** Closing tables correctly
  empties the screen. Anyone reading it as a scoreboard will misread it; the
  glossary and the labels say "terbuka"/"aktif" to fight that.
- **No money on the screen, ever**, until someone wants `GET /me/shift` badly
  enough to build it. The old glossary promised "sales" here; that promise is
  now explicitly withdrawn rather than left dangling.
- **A shift is only as accurate as `lastActorId`**, which ADR-0056 already
  documents as approximate and which no UI can currently hand over
  deliberately. A table that changed hands attributes its covers to whoever
  holds it now.
- **One more piece of cross-device state to reason about.** A shift is no
  longer inferable from what a device knows, which is the point, but it means
  an offline handset falls back to its local `loginAt` and can disagree with the
  host until it reconnects.
- **`Users.shiftStartedAt` stops being droppable.** It was dead schema we could
  have removed; it is now load-bearing.
