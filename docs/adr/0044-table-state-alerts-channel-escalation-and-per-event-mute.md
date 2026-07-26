# Table-state alerts: channel split, escalation, and per-event mute

Extends [ADR-0007](0007-audio-alert-routing.md) (who hears what) and [ADR-0035](0035-selectable-per-event-alert-sounds.md) (which clip plays). Adds four service timings that previously did not exist in any form, and one that existed only as a hardcoded colour ramp.

## Not every state earns a sound

The four new states are **not** all cues. A sound is a claim on attention that cannot be declined; it is only honest when there is something to do *right now* and a cost to not doing it.

| state | threshold | channel |
|---|---|---|
| **Belum dilayani** — seated, nothing sent | `ungreetedMins` (+`ungreetedEscalateMins`) | **audible** |
| **Menunggu diantar** — `readyAt → servedAt` | `pickupTargetMins` | **audible** |
| **Meja lama** — long occupancy | `longStayMins` | visual only |
| **Meja selesai makan** — all served, idle | `idleTableMins` | visual only |
| **Terlambat** — reservation past grace | `reservationGraceMins` | visual only |

*Belum dilayani* has a victim, a deadline, and a discharge (go to the table); it self-clears on the first line sent. *Menunggu diantar* is the quality killer ADR-0013 already measured but never alerted on. *Meja lama* has **no action** — a waiter cannot make a party leave — so a sound for it would be pure noise that devalues every cue they *can* act on. `_kElapsedAlarm` (hardcoded 1h) becomes `longStayMins` and stays a colour ramp.

Going from 4 audible events to 6 is the real cost here, and it is why the two states with no action stayed silent.

## Escalation, because targeted delivery fails silently

*Belum dilayani* is routed to the seating waiter (`lastActorId`) at `ungreetedMins`, then **floor-wide** a further `ungreetedEscalateMins` later. Targeting only the seating waiter looks considerate and fails silently: that waiter may be mid-walk-in, in the back, or signed out, and the guest the cue exists to protect stays neglected while the alert reports itself delivered. `lastActorId` is explicitly "approximate, not a strong owner claim" — the escalation is what makes it safe to route on.

Cues stay **one-shot**. The glossary invariant ("never loop or demand acknowledgement") came under real pressure here, because unlike overdue food an unserved table is a harm that is *ongoing* while the condition persists. It held because the two escalating fires already solve the "one person missed it" failure, and a cue staff cannot discharge — a party waiting for a friend, on the phone — becomes a metronome they mute. Re-nagging is a one-line change later if one-shot measurably loses tables.

## Reservations: a clock must not decide a no-show

"Terlambat" is a **derived display state**, never a stored status. Auto-flipping to `noShow` was rejected on two grounds: it is a judgement with customer-relationship consequences, and it introduces a race (a party arriving at +40m, seated at +46m, already flipped) that would force `seated` to be reachable *from* `noShow` to fix a problem auto-flip created. `Reservations.seatedAt` is added — set-once on the first flip into `seated` — because `updatedAt` moves on any later edit and so cannot measure lateness.

## Three orthogonal mute axes

- **Which clip** — venue-wide preset per event (ADR-0035), now including `soundUngreeted` / `soundPickup`.
- **Venue policy** — `ungreetedAlertEnabled` / `pickupAlertEnabled`, explicit booleans. "Off" is never a degenerate threshold: overloading `0` to mean disabled gives one number two meanings, and a mistyped `0` would silently kill a cue.
- **Device** — the all-or-nothing "Alert audio" toggle becomes a per-event set in prefs, listing only cues that device's role receives. Without it, one annoying cue costs the operator *pesanan siap* as collateral. It is unenforceable anyway (the handset has a volume rocker), so an in-app valve is strictly better than pushing an annoyed waiter to OS-level mute, which is invisible and total.

## Consequences

- **On upgrade every venue gets these live at their defaults, audible cues included.** The alternative — audible cues opt-in, visual states on — was recommended and not taken. The accepted risk is concrete: a venue that never asked for them hears new sounds mid-service, and the first instinct is to mute. The per-event mute and the venue-wide enable flags exist to make that recoverable rather than terminal.
- Reporting gains **time to first order** (median + % breaching `ungreetedMins`), **pickup SLA**, and reservation **late % / no-show %** — all derived from timestamps already stored.
- **No alert-event log.** Escalation rate is the best staffing signal available and is deliberately not built: alerts are computed client-side and ephemeral, so recording them needs a new table, a new write path, and de-duplication across devices. The derived metrics measure *the service*; the log would measure *the alerting*. Consequence: if the floor complains about noise, there is no interruption count to tune against, only the derived breach rate as a proxy.
- **Known gap in the escalation.** "The seating waiter is signed out, so skip straight to floor-wide" is not implemented — a client device cannot tell whether another operator's session is live. That case degrades to waiting for the normal escalation (`ungreetedEscalateMins` later) rather than firing floor-wide immediately. Graceful, but slower than designed; closing it needs the server to publish live-session state on the table.
- All thresholds are **venue-wide**. Per-zone overrides are plausible (a terrace is further from the pass) but every threshold is 5-minute granular, so an override would almost always equal the default — config surface with no signal, and a second place to look when asking why a table did not alarm.
