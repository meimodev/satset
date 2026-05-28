# ADR-0001 — Table locking is scoped to non-available status; reservation seat pre-acquires the lock

**Status:** Accepted — 2026-05-27

## Context

A table's detail screen lets a waiter manage one party: bump pax, add tickets, advance ticket status, close the tab. To prevent two waiters editing the same table at once, the detail screen acquires a per-user advisory lock (7s TTL, 3s heartbeat). Anyone else opening the same detail sees a read-only banner.

Until this decision, the lock was acquired unconditionally on every detail-screen open, regardless of the table's status. That meant:

- Empty (`available`, "kosong") tables — which carry no editable state — still locked out other waiters who tried to view them.
- Both **walk-in seat** and **reservation seat** flows flipped a table to `occupied` server-side, but neither path explicitly assigned the lock to the seater. Whichever device's detail screen acquired first held the lock — possibly not the waiter who seated the party.

We needed a coherent answer to: when is the lock active, and who holds it after a seat?

## Decision

**1. Lock is only active when `status != available`.**

The `available` status carries no editable per-party state (no tickets, no pax beyond zero, no guest info). Locking it produces contention without protecting anything. Kosong tables are freely browsable by any waiter; the detail screen renders a read-only summary + a "Mulai layani meja" CTA.

`table_detail_screen.initState` skips lock acquire when the row is `available`. A status listener triggers auto-acquire when the row transitions to a non-`available` state while the screen is open.

**2. The `seat` endpoint rejects non-`available` tables.**

`POST /tables/:id/seat` returns `409 {code: 'already_seated', table: …}` when the target table is not `available`. Both the walk-in CTA and the reservation action sheet handle this with a toast ("Sudah diisi oleh {lastActorName}") plus a state refresh. This is the only contention point that matters: once one waiter wins the seat, every other surface flips coherently via the WebSocket broadcast.

**3. Reservation seat pre-acquires the lock; walk-in seat does not.**

The seat endpoint accepts an optional `acquireLock: bool` flag. When `true`, the same UPDATE that flips status to `occupied` also writes `lockedBy / lockedByName / lockedAt / lockExpiresAt` for the acting user.

- **Reservation flow** passes `acquireLock=true`. The waiter taps a table from the action sheet, then is expected to navigate to the table's detail — a non-trivial delay during which another device opening the same table would otherwise win the lock race.
- **Walk-in flow** is already on the detail screen when the seat button is tapped. The status flips, the screen's existing auto-acquire timer claims the lock within ~1.5s. No pre-acquire needed; the window is small enough that a race here is acceptable.

**4. `lastActorId` semantics: last-write-wins.**

`lastActorId` reflects whoever most recently performed an operative action on the table (seat, pax change, ticket advance, handover). It is *not* a stable "owner of record." We accept that a manager bumping pax mid-service silently becomes the `lastActorId` until the next action — the field is approximate, used for display and audit hints, not authorization.

## Consequences

**Positive:**
- Kosong tables stop generating spurious "locked by" banners and stop burning heartbeat round-trips.
- Reservation flow no longer has a lock-race window between seat and detail navigation.
- The `seat` endpoint becomes the single source of truth for status transition and lock assignment, eliminating client-side multi-call orchestration for that transition.
- `409 already_seated` gives both flows a clean failure mode with a localized error.

**Negative:**
- Asymmetry between walk-in and reservation flows is surprising on first read. Mitigated by this ADR and by the fact that the asymmetry is real (different starting states warrant different solutions).
- `lastActorId` continues to be a weak signal. If a future feature needs a strong "primary waiter" identity (e.g. shift reports, tip allocation), it will need a dedicated `waiterId` field with first-write-wins semantics. We deferred that work — current displays of `lastActorId` are tolerant of noise.
- `table_detail_screen` gains a status-watching listener and a small amount of state-machine complexity for "kosong → seat-CTA → flip detected → auto-acquire."

## Alternatives considered

- **Always lock** (status quo before this decision): keeps the code uniform but wastes a lock on a resource with nothing to protect.
- **First-write-wins `lastActorId` / dedicated `waiterId`** field: cleaner semantics but a bigger refactor (every PATCH route would need to stop spraying actor IDs). Postponed — no concrete feature requires it yet.
- **Pre-acquire lock for both flows**: would have been free and symmetric, but the walk-in case is already covered by the existing auto-acquire path. The unnecessary write was not worth the symmetry.
