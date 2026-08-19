# A guest order arriving gets its own cue

**Status:** Superseded by [0080](0080-self-order-and-token-pairing-removed.md) — guest QR self-ordering removed, and with it `AlertEvent.guestPending`. Kept for the reasoning. Re-decided by [0105](0105-guest-self-order-returns-as-an-intent-not-a-ticket.md) — the cue returns.

Extends [ADR-0028](0028-guest-orders-pending-review-not-auto-fire.md) (guest orders rest in review) and [ADR-0044](0044-table-state-alerts-channel-escalation-and-per-event-mute.md) (what earns a sound). `AlertEvent` grows a seventh member, `guestPending`, with its own venue-wide preset (`soundGuestPending`, schema v40) and its own row in the device mute list.

The glossary already claimed the review queue was "announced by an Audio alert (reuses the ready-alert plumbing)". It was not. `guestOrder.submitted` reached `GuestOrdersRepository`, which silently refetched, and `AlertSoundService` dropped the event on the floor — its `_onEvent` switch only handled `sent` / `ready` / `voided`, and `pendingReview` is none of those. So a guest order landed as a passive badge, which is the one outcome the glossary's own `_Avoid_` clause names.

It earns a sound on ADR-0044's own test: there is a victim (a guest watching "received" on their phone), a deadline, and a discharge a waiter can perform right now (approve or reject). Unlike *Meja lama*, doing nothing is not an acceptable response.

## Why not reuse `newOrder`

Reusing an existing event was the cheaper option and was rejected. `newOrder` is a **kitchen** cue: it means "work has arrived at the pass", it is routed to Server-mode devices, and its clip is chosen by an owner thinking about the line. A guest order means the opposite — *nothing* has reached the kitchen, and a waiter must decide whether it ever will. Routing `newOrder` to waiters would have needed the mute-set change anyway, so the reuse saved a Drift column and cost the venue the ability to distinguish the two by ear.

The default preset is deliberately **not** `chime`, the ready cue. A waiter answers *pesanan siap* by walking to the pass and collecting a plate; they answer this one by opening the review queue. Two cues that demand different journeys must not sound alike.

## Fires at submit, not at `pendingReviewMins`

The cue is the **announcement**; `pendingReviewMins` (ADR-0048) stays what it was — the standing crit state for an order that went unanswered. Firing only at the threshold would have made the guest wait out the timer before anyone was told, which inverts the point of skipping the transcription wait.

## Consequences

- **Every venue on v40 hears a new sound**, since the column defaults to `doorbell` rather than `none`. Shipping it silent-by-default would have left the bug in place for exactly the venues that never read release notes. The per-event mute is the recovery path, as in ADR-0044.
- Venues with self-order **off** are unaffected: no submit, no event, no cue.
- The cue is client-mode only, matching the routing rule in ADR-0007 — the host tablet is the kitchen, and the kitchen cannot approve a guest order.
- Still **no alert-event log** (ADR-0044). A missed guest order is not counted, only visible as the standing `pendingReviewMins` banner.
