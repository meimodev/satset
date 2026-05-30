# Audio alert routing

Audio (and on waiter devices, haptic) cues for important events are routed by **device role**, not by which screen is foreground. The kitchen — i.e. the Main Device, running in **server** mode — hears all kitchen cues (new order, recall, overdue). Waiter — **client** mode — devices hear all of them too, with one deliberate asymmetry: the **food-ready** cue is broadcast to *every* waiter device, while the **void/comp** cue reaches *only* the table's responsible waiter (`table.lastActorId == current user`).

The WS hub already broadcasts every ticket event to every connected client, so routing is a client-side decision. We gate on `prefs.appMode()` (server vs client) rather than on the active route, so a waiter still hears "ready" while deep in the menu flow and the kitchen still hears "new order" while an admin is on reports. "Ready" is intentionally a shared, un-targeted signal — a "someone go grab it" prompt that any free waiter can answer — whereas a "void" is an accountability event scoped to the waiter who owns the line (consistent with [ADR-0006](0006-self-served-void-with-per-waiter-accountability.md)).

## Consequences

- Every waiter device beeps on every "ready". In a large room this is louder than per-waiter targeting; accepted as the cost of shared pickup awareness. Revisit if venues report alert fatigue.
- Void/comp targeting needs the current user id (`authStateProvider.user.id`) compared against the event's `table.lastActorId` — already available client-side.
- Overdue is **not** a server event: the Main Device scans the live queue on a timer and fires the alert once per ticket when it first crosses the existing 10-minute floor threshold (`kitchen_screen.dart`), tracking already-alerted ids so it never re-nags.
- Bursts (a fired course = many `ticket.created` at once) are debounced (500ms) into a single cue per type.
- All cues are one-shot — no loop-until-acknowledged — and every device can mute its own via the existing "Alert audio" toggle (`audioAlertEnabled`, default on).
