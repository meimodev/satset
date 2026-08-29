# A venue may have no prep queue, and that is a mode, not a switch

**Status:** Accepted — 2026-08-28 — **amends** [0109](0109-counter-mode-is-a-preset-of-switches.md).

ADR-0109's decision stands: `counterService` is a mode key, it fails closed, and
the six `counterConfig` switches under it are configuration rather than
entitlement. What this ADR adds is a **second mode key** and one exception to
0109's §3, drawn narrowly: a *mode* may branch a writer, a *switch* still may
not.

## Context

The [[KDS / Antrian Persiapan|KDS]] is the second person in a two-person
handoff. A waiter sends, a cook picks it up, marks `prep`, marks `cooked`, marks
`ready`, and a waiter runs it. Every one of those moves costs `viewKds` in
`ticketTransitions` (ADR-0101), because every one of them is the kitchen's.

A warung, a coffee counter, a juice stall and a home kitchen doing deliveries all
have **one** person. They take the order and they make it. There is no second
party to hand the line to, so a queue is not a simplification of their work — it
is a screen nobody looks at holding rows nobody moves. Left running, the lines
pile up in `sent` forever: `sent → served` is not in the transition graph, and the
only paths out cost a capability the venue has nobody to give it to.

Counter mode (ADR-0109) was the near miss. It has `simpleKds` — one queue, no
station split — which flattens the KDS but still assumes one exists. And it is a
**preset for a counter shop**, which is a different question: a cafe with a real
cook line wants Kedai mode *and* a queue; a twelve-seat restaurant with a floor,
tables and one owner cooking wants no queue and no counter preset. Folding the
second question into the first makes both unanswerable.

Three things in 0109 are actively in the way:

- **§3: "a switch that changed what `submitOrder` writes is a review finding."**
  Removing the queue is exactly that — the line has to be born somewhere other
  than `sent`, or there is no queue-less shape, only a hidden screen and a
  growing backlog.
- **§6: "counter mode hides, never refuses."** Hiding the KDS alone is the
  broken option: it is not a refusal, it is an orphaning.
- **The switches are `counterConfig`**, ANDed with `counterService`. A seventh
  one would make "no prep queue" reachable only by a venue that had also agreed
  to be a counter shop.

## Decision

**`bypassKds` is a mode key in `addOns`, beside `counterService` and
independent of it.** Fail-closed, through `venueHasMode`; outside the trial's
implicit grant, like every `MODE_MODULES` entry; written from the fleet console's
own **Mode** card rather than under Modul, because an operator ticking "no prep
queue" in a list titled *Modul* is being told they are selling something.

**`submitOrder` writes `ready`, with `readyAt` stamped at send.** One branch, in
one writer, read from the venue's own settings row rather than taken off the
wire — so `acceptGuestOrder` and an [[Antrean kirim]] replay inherit the shape
with no second arm, and no caller on the cleartext guest plane can name a status.

**`ready`, not `served`**, and the transition graph is the reason. `ready →
voided` costs `voidItem`; `served → voided` costs `compItem`, because voiding
something already served is a comp (ADR-0006). Born-`served` would mean every
mis-key in a one-person shop needs a manager the shop does not have. Born-`ready`
puts the line in the [[Pesanan board]]'s *Siap diambil* bucket, where
`ready → served` is already the handover tap and already costs `takeOrder` — no
new UI, no new transition, no new capability.

**Everything else hides and nothing is revoked.** The KDS rail slot, the prep
metrics in Operasional, the prep target, the prep-queue cues and the `viewKds`
row in the [[Role]] sheet all go. The stored values stay: the capability is still
on the role, `prepTargetMins` is still on the settings row, `simpleKds` is still
in `counterConfig` (greyed on the console, not cleared). Unticking the mode finds
the venue as it left it.

**Two survivals keep the hiding honest.** The KDS slot returns while any line is
still `sent`/`prep`/`cooked`, so flipping the mode on mid-shift drains rather than
strands; and it returns for a signed-in user holding `viewKds` and not
`takeOrder`, whose device would otherwise have no destination. The route itself
is never gated — 0109 §6 holds for the *route*, and what this ADR amends is only
what gets **written**.

**The venue shape is cached.** `modules` + `counterConfig` are written to
`PrefsService` on every settings load and re-read at repository construction. A
mode fails closed, so without this a handset that cold-boots away from its host
renders a KDS tab and a [[Floor]] the venue does not have, then flickers them
away on reconnect. This was already true of `menuHome`; the cache fixes both.

## Consequences

- ADR-0109 §3 now reads: **a `counterConfig` switch may not branch a writer; a
  mode key may.** The distinction is load-bearing — a switch is a default an
  operator tunes, a mode is a shape the venue has, and only the second is worth
  a fork in the ledger.
- Reports for a bypass venue lose their prep median, SLA hit-rate and `prep` KPI.
  They would read a structural "100% on target, 0 minutes" — a statement about
  the schema, not the shift. Pickup metrics stay: food that sits after it is
  ready is a real failure at a counter too.
- A venue that flips the mode **off** mid-shift has history in two shapes:
  earlier lines born `ready` with a zero prep clock, later ones walked through
  the queue. This is accepted and not repaired — the alternative is rewriting
  rows for events that did not happen.
- `held` and course fire are unreachable in a bypass venue: nothing writes
  `held`, so the fire affordances (which gate on it) never render. The optimistic
  offline row in `TicketsRepository.sendOrder` mints `ready` for the same reason
  — a `held` stand-in would offer a fire button for a course nothing will fire,
  then swap under the waiter on reconnect.
- `bypassKds` is a **persisted string** in `venues/{vid}.addOns` and in the
  mirrored `venue_settings.modules` CSV, under the same never-rename rule as an
  `AuditKind`.

## Alternatives considered

**A seventh `counterConfig` switch.** Rejected: it ANDs with `counterService`,
so a restaurant could never have it and a counter shop with a cook line could
never be without it. Two independent questions, two keys.

**Hide the KDS and change nothing else.** Rejected: lines stay `sent` with no
legal move out. Not a smaller version of this decision — a broken one.

**Add `sent → served: takeOrder` to the graph and keep writing `sent`.** The
lazy version, and genuinely tempting: no writer branch, no ADR. Rejected because
it makes the move legal in **every** venue, including the restaurant where
letting a waiter mark food served without the kitchen ever seeing it is the exact
failure the graph exists to prevent.

**A `venueKind` enum.** Rejected for the same reason ADR-0109 rejected it: the
half-ticked case is the common one.
