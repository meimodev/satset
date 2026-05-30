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
Per `lastActorId` on the table row — the user who most recently performed an operative action on the table (seat, pax change, ticket advance, explicit handover). Refreshed on every real op, not by viewing or by lock acquire alone. Cleared when the table is **closed** back to kosong — a fresh table carries no waiter. The field is approximate, not a strong "owner" claim — see [docs/adr/0001-table-locking-and-seat-semantics.md](docs/adr/0001-table-locking-and-seat-semantics.md).

### Orderer (line author)
The single staff member who submitted one specific order line. Stored per-ticket as `createdBy` (a userId, stamped server-side from the JWT at submit). Distinct from [[Waiter]]: the **Waiter** is the table's *current* actor (`lastActorId`, overwritten on every table op), while the **Orderer** is frozen to whoever sent that line — so two waiters serving one table show as different orderers across its tickets. Surfaced on order cards (Pesanan board) and table-detail line items as the orderer's **avatar** (initials in their account color; nothing shown when `createdBy` is absent on legacy/offline lines). _Avoid_: showing the table Waiter as if they authored a line.

### Order elapsed time
How long a line has been live, measured from its `sentAtTime` (when sent to the kitchen). Ticks live while the line is active; **freezes** once the line is `served` or `voided` (the frozen value is its total time-to-serve). Shares the venue's **overdue** threshold — calm under 10 minutes, urgent at/after — so the Pesanan board, the floor highlight, and the overdue [[Audio alert]] all agree on "late". Replaces the older display of the raw clock time the line was sent.

### Orderer (line author)
The single staff member who submitted one specific order line. Stored per-ticket as `createdBy` (a userId, stamped server-side from the JWT at submit). Distinct from [[Waiter]]: the **Waiter** is the table's *current* actor (`lastActorId`, overwritten on every table op), while the **Orderer** is frozen to whoever sent that line — so two waiters serving one table show as different orderers across its tickets. Surfaced on order cards (Pesanan board) and table-detail line items as the orderer's **avatar** (initials in their account color; nothing shown when `createdBy` is absent on legacy/offline lines). _Avoid_: showing the table Waiter as if they authored a line.

### Order elapsed time
How long a line has been live, measured from its `sentAtTime` (when sent to the kitchen). Ticks live while the line is active; **freezes** once the line is `served` or `voided` (shown as the static sent clock, since the Ticket carries no terminal timestamp). Shares the venue's **overdue** threshold — calm under 10 minutes, urgent at/after — so the Pesanan board, the floor highlight, and the overdue [[Audio alert]] all agree on "late". Replaces the older display of the raw clock time the line was sent.

### Table lock
Per-user advisory lease on a table's detail screen. Prevents two waiters editing the same table simultaneously. Held by the user actively viewing the detail; 7s TTL with a 3s client heartbeat. Anyone else opening the detail sees a read-only banner ("Meja diambil oleh X").

**Scope:** the lock is only active when the table's status is **not** `available`. Kosong tables are lock-free; their detail screen is read/seat-only. See ADR-0001.

### Reservation
A planned future visit: name, phone, party size, expected time, optional zone hint, optional pre-assigned table, optional notes. Status lifecycle: `pending` → (`seated` | `noShow` | `cancelled`). Reservations are created via the floor's "Reservasi" strip and seated through the same strip's action sheet.

### Party / partySize
The number of guests of a single reservation or walk-in. Distinct from a table's **capacity** (max seats); pax stepper on the table detail is clamped to `[1, capacity]`.

### Habis / Sold out (menu item out of stock)
A menu item that is not available to order right now. Surfaced in the menu admin as plain Indonesian — **"Ditandai habis manual"** (waiter or admin flipped the toggle) or **"Otomatis ditandai habis (stok 0)"** (auto-flag tied to stock count). Avoid the English slang "86'd" in user-facing copy; it is opaque to non-restaurant staff.

Code identifiers use **`soldOut`** throughout (English, matching the codebase convention of `unavailable`/`stockCount`): `MenuItem.isSoldOut`, `isAutoSoldOut`, `autoSoldOutAtZero` (DB column `auto_sold_out_at_zero`), `MenuAdminCounts.soldOut`. The staff availability toggle is gated by **`Capability.markSoldOut`**. The earlier "86" naming (`isEightySixed`, `Capability.toggle86`) was fully renamed — no `86`/`eightySix` identifier remains. Migration v21 renames the DB column and rewrites the stored `"toggle86"` capability string in the `roles` table.

### Menu category
A named, ordered grouping of menu items — e.g. "Starters", "Mains", "Drinks". Managed (create/rename/reorder/delete) from the menu admin's **Kategori** panel. Ordering is by **sortOrder**. Every item always references a valid category: a category with items in it **cannot** be deleted (`409 category_not_empty`) — the admin must move or remove those items first. User-facing copy: **"Kategori"**.

### Modifier group (add-on)
A named set of choices attached to a menu item — e.g. "Tingkat pedas", "Pilih protein". Has flags **wajib** (required) and **pilih banyak** (multi-select), and a list of **options**, each with an optional price delta. Modifier groups are **private to one item** — not a shared library. Editing a group on one item never affects another, even if both happen to have a "Tingkat pedas". User-facing copy: **"Grup modifier"**. _Avoid_: treating modifiers as reusable/global.

### Variant (variation)
A size/format choice for an item that sets an absolute price — e.g. "Reguler", "Besar". Distinct from a **modifier option**, which adjusts price by a delta. Variants are private to one item. User-facing copy: **"Varian"**.

### Menu tag (allergen / diet)
An admin-managed label attached to menu items, of one **kind**: **allergen** (a warning — e.g. Gluten, Kacang) or **diet** (a property — e.g. Vegan, Halal). Each tag has a stable `id`, a `name` (display), a `code` (2-char badge, e.g. "GL"), a `kind`, and a `sortOrder`. Colour is **kind-derived** (allergen → warn, diet → info), not per-tag.

Tags are **customizable**: created/renamed/recoloured-by-kind/reordered/deleted from the menu admin's **Tag** panel (third tab beside Items / Kategori), gated by `Capability.editMenu`. Stored in one `menu_tags` table (single table, `kind` discriminator). Items reference tags by **id** (in `allergensJson` / `dietaryJson`), so a rename never breaks an item's refs. Seed tag ids equal the legacy enum names (`gluten`, `vegan`, …) so existing items need no migration. Deleting a tag **cascade-strips** its id from every item. Tags ride the `/menu` snapshot and broadcast `menuUpdated`, so every device live-refreshes. _Avoid_: a fixed `Allergen`/`DietaryTag` enum (removed) or per-tag custom colour.

### Floor
The screen that lists all tables with status chips and the reservations strip across the top. The primary jumping-off point for waiters during service.

### Close (table) / Table session
Settle a **terisi** table back to **kosong**: snapshot the visit into a **TableSession** (+ per-ticket, per-course children) for reports, hard-delete the live tickets, reset the table to `available`. User-facing copy: **"Tutup meja"**. Endpoint `POST /tables/:id/close`.

Allowed only when the bill is **fully terminal** — at least one ticket and every ticket is **served** or **voided** (or a mix). A table with a **live** ticket (anything pre-serve: `sent | held | prep | cooked | ready` etc.) or with zero tickets cannot be closed. The server enforces this (`409 tickets_not_terminal` / `409 no_tickets`), not just the UI.

_Avoid_: "settle"/"checkout" in user-facing copy — stick with "Tutup meja". Distinct from **Void** (removes one line) and reservation **cancel**.

### Void (item)
Removing a sent ticket line from an order. User-facing copy: **"Batalkan item"**. Internal term stays **void** (`Capability.voidItem`, `AuditType.voidItem`, `TicketStatus.voided`) to keep it distinct from reservation **cancel** (`pending → cancelled`).

Self-served by any waiter holding `voidItem`, allowed only pre-serve (`sent | held | prep | cooked | ready`). Voiding a `served` item is a **comp/refund**, not a void — those go through `compItem` / `refund` capabilities with manager approval. See [docs/adr/0006-self-served-void-with-per-waiter-accountability.md](docs/adr/0006-self-served-void-with-per-waiter-accountability.md).

Every void carries a canonical **reason code** — `wrongOrder` (terkirim salah), `customerChange` (tamu berubah pikiran), `outOfStock` (stok habis), `kitchenError` (kualitas dapur), `other` (free text wajib). Server stamps `actorUserId` from the JWT; reports surface per-waiter void rate and lost rupiah by reason.

### KDS / Antrian Persiapan
The unified digital preparation queue displayed on the Main Device showing all sent items chronologically, oldest-first, across every prep **station**. Staff mark items cooked/ready here; handoff (serve) happens elsewhere.
_Avoid_: "Dapur" as the screen name (Dapur is one station, not the screen), Bar screen, multi-station KDS (separate per-station screens).

### Station (Stasiun)
A prep destination an item routes to — currently **Dapur** (kitchen) and **Bar**. Stations feed the single Antrian Persiapan queue; they are not separate screens.

### Audio alert
An audible (and on waiter devices, haptic) cue that draws a staff member's attention to an event without them watching the screen. Three semantic cues:

- **Ding** — a new order reached the kitchen (a ticket was sent / a course fired). Heard by the kitchen.
- **Chime** — food is **ready** for handoff. Heard by waiters.
- **Alert** — something needs attention: an item **voided**/comped, a kitchen recall, or a ticket gone **overdue**.

**Who hears what** is by device role, not by which screen is open:

- The **kitchen** (the Main Device) hears all kitchen cues: new order, recall, and overdue.
- **Waiters** hear **ready** for any table (shared "someone grab it" awareness), but a **void/comp** cue reaches only the **responsible waiter** (the table's current waiter — see [[Waiter]]).

**Overdue** reuses the floor's existing 10-minute line: a ticket sounds the alert once when it first crosses 10 minutes unhandled, never again for that ticket. Bursts (a fired course landing as many tickets at once) collapse to a single cue. Cues are one-shot — they never loop or demand acknowledgement. Each device may silence its own cues (the venue's "Alert audio" toggle).

