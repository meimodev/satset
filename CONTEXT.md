# Domain Context

Living glossary of domain terms used in SatSet. Capture meaningful concepts for waitstaff, kitchen, and admin flows. Implementation details belong in code, not here.

## Terms

### Table
A physical seating unit in the venue (e.g. table 7, table A2). Domain model: `VenueTable`. Class renamed from `Table` to avoid `dart:ffi` conflict.

A table has a **status** that drives both the floor view and what actions are available:

- **kosong** (`available`) — no party seated. Open to any waiter. No lock held. Multiple waiters may view simultaneously.
- **terisi** (`occupied`) — party seated, possibly with open tickets. Per-user lock active on the detail screen.
- **pending** — open tab held (e.g. waiting on kitchen). Per-user lock active.
- **ready** — at least one ticket marked ready by kitchen, awaiting handoff. Per-user lock active.

### Seat (verb)
Transition a table from **kosong** to **terisi**. Two entry points, both hit the same `POST /tables/:id/seat` endpoint:

- **Walk-in seat** — waiter opens a kosong table from the floor, taps the "Mulai layani meja" CTA. Pax defaults to 1; adjust afterward via stepper.
- **Reservation seat** — waiter taps a reservation chip, picks a free table inside the action sheet. Carries the reservation's `partySize`, `name`, `notes`, and `reservationId` onto the table; flips the reservation to `seated` status.

Seat is rejected with `409 already_seated` if the target table is not `available`. A table may only be seated by one party at a time.

### Waiter
Per `lastActorId` on the table row — the user who most recently performed an operative action on the table (seat, pax change, ticket advance, explicit handover). Refreshed on every real op, not by viewing or by lock acquire alone. The field is approximate, not a strong "owner" claim — see [docs/adr/0001-table-locking-and-seat-semantics.md](docs/adr/0001-table-locking-and-seat-semantics.md).

### Table lock
Per-user advisory lease on a table's detail screen. Prevents two waiters editing the same table simultaneously. Held by the user actively viewing the detail; 7s TTL with a 3s client heartbeat. Anyone else opening the detail sees a read-only banner ("Meja diambil oleh X").

**Scope:** the lock is only active when the table's status is **not** `available`. Kosong tables are lock-free; their detail screen is read/seat-only. See ADR-0001.

### Reservation
A planned future visit: name, phone, party size, expected time, optional zone hint, optional pre-assigned table, optional notes. Status lifecycle: `pending` → (`seated` | `noShow` | `cancelled`). Reservations are created via the floor's "Reservasi" strip and seated through the same strip's action sheet.

### Party / partySize
The number of guests of a single reservation or walk-in. Distinct from a table's **capacity** (max seats); pax stepper on the table detail is clamped to `[1, capacity]`.

### Habis (menu item out of stock)
A menu item that is not available to order right now. Surfaced in the menu admin as plain Indonesian — **"Ditandai habis manual"** (waiter or admin flipped the toggle) or **"Otomatis ditandai habis (stok 0)"** (auto-flag tied to stock count). Avoid the English slang "86'd" in user-facing copy; it is opaque to non-restaurant staff. Internal code identifiers (`isEightySixed`, `autoEightySixAtZero`) keep the term for brevity — refactor only with a coordinated rename.

### Floor
The screen that lists all tables with status chips and the reservations strip across the top. The primary jumping-off point for waiters during service.

### Void (item)
Removing a sent ticket line from an order. User-facing copy: **"Batalkan item"**. Internal term stays **void** (`Capability.voidItem`, `AuditType.voidItem`, `TicketStatus.voided`) to keep it distinct from reservation **cancel** (`pending → cancelled`).

Self-served by any waiter holding `voidItem`, allowed only pre-serve (`sent | held | prep | cooked | ready`). Voiding a `served` item is a **comp/refund**, not a void — those go through `compItem` / `refund` capabilities with manager approval. See [docs/adr/0006-self-served-void-with-per-waiter-accountability.md](docs/adr/0006-self-served-void-with-per-waiter-accountability.md).

Every void carries a canonical **reason code** — `wrongOrder` (terkirim salah), `customerChange` (tamu berubah pikiran), `outOfStock` (stok habis), `kitchenError` (kualitas dapur), `other` (free text wajib). Server stamps `actorUserId` from the JWT; reports surface per-waiter void rate and lost rupiah by reason.
