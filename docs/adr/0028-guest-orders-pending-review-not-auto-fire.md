# Guest orders land in pending-review, not straight to the kitchen

**Status:** Superseded by [0080](0080-self-order-and-token-pairing-removed.md) — guest QR self-ordering removed. Kept for the reasoning; the feature no longer exists.

Originally: accepted — depends on [0027](0027-cleartext-guest-plane-for-self-order.md) (guest plane)

## Context

A waiter-taken order goes straight to the kitchen: `POST /orders` writes tickets at `status = 'sent'`, which fires them onto the KDS immediately. That is safe because a **trusted, authenticated staff member** (`takeOrder` capability) built and reviewed it.

Guest self-ordering (CONTEXT.md: *Self-order*) removes the staff member from order **entry**. The submitter is an unauthenticated party on the guest plane (ADR-0027). If guest submits fired directly to the kitchen, the failure modes are real and costly:

- **Mis-taps / menu confusion** — a guest unsure of the UI fires food they didn't mean to.
- **Trolling / abuse** — anyone on the venue LAN with a table URL fires arbitrary food.
- **Pacing loss** — kitchen pacing/coursing decisions move out of staff hands.

The product goal is "order **without waiting for a waiter to transcribe**" — *not* "order with **no staff involvement at all**." Those are different: the win is eliminating the transcription wait, which a one-tap confirm preserves.

## Decision

**A guest submit creates tickets in a new `pendingReview` lifecycle state that does not fire to the kitchen. A waiter approves (→ `sent`) or rejects from a dedicated review queue.**

- New ticket status **`pendingReview`**, ordered **before `sent`** in the lifecycle. KDS and the Pesanan board **exclude** `pendingReview` tickets — they are invisible to the kitchen until approved.
- `POST /guest/orders` writes `pendingReview` tickets (server re-validates required modifiers, re-prices authoritatively), then broadcasts a `guestOrderSubmitted` WS event.
- A **Guest Orders review queue** (gated by `takeOrder`, announced by the existing ready-alert audio infra) lets a waiter **Approve** — transition `pendingReview → sent` (fires to KDS, staff assigns/fires course) — or **Reject** (discard with reason).
- The guest sees status on their phone: received → confirmed / "please ask your server" (poll-backed).
- All guest lines default to **one course**; coursing/firing stays a staff decision at approval.

## Considered options

- **Pending-review with one-tap staff approve (chosen)** — keeps the no-transcription speed win while preserving the mis-tap / abuse / pacing safeguards that authenticated entry gave for free. Cost: one staff tap per guest batch, a new lifecycle state, a review surface.
- **Direct-to-kitchen, no approval** (rejected) — truest to "no waiter," but any LAN device fires food unsupervised; unacceptable on a busy floor.
- **Auto-approve after a timeout** (rejected) — reintroduces exactly the mis-tap/troll risk the review step exists to remove; a distracted floor becomes a fire-anything floor.
- **Inline pending badge on the table card, no dedicated queue** (rejected as the primary surface) — guest orders arrive unpredictably and a passive badge gets missed during a rush; a queue + audio alert is the active surface.

## Consequences

- A new ticket state ripples through the lifecycle: every KDS / board / reporting query must treat `pendingReview` as **not-yet-fired** (excluded from prep-time, service-target, and kitchen views).
- Guest orders are **never** edited/cancelled by the guest after submit — staff own them from the queue (Approve/Reject), avoiding kitchen race conditions.
- Approval reuses the existing `sent` transition + course-fire path, so KDS, timestamps (ADR-0008/0013), and printing are unchanged downstream of approval.
- If a venue ever wants true direct-fire, it becomes a `venue_settings` flag layered on top — the safe default is review.
