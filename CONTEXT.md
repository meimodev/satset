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

### Reseat
Seating a **new party** on a [[Table]] whose previous [[Visit]] has ended (table back to **kosong**). Not a distinct action — it is an ordinary [[Seat (verb)|seat]] on a recycled table. The point of the term: a Table's identity is **reused across Visits**, so the same `tableId` carries successive, unrelated parties over a service. The [[Visit]] — not the table — is the stable key a [[Bill (tab)|bill]] and its lines hang off. _Avoid_: treating a reseat as "reopening the old table"; the prior visit is over and its lines belong to that visit alone, never to the reseat.

### Waiter
Per `lastActorId` on the table row — the user who most recently performed an operative action on the table (seat, pax change, ticket advance, explicit handover). Refreshed on every real op, not by viewing or by lock acquire alone. Cleared when the table is **closed** back to kosong — a fresh table carries no waiter. The field is approximate, not a strong "owner" claim — see [docs/adr/0001-table-locking-and-seat-semantics.md](docs/adr/0001-table-locking-and-seat-semantics.md).

### Orderer (line author)
The single staff member who submitted one specific order line. Stored per-ticket as `createdBy` (a userId, stamped server-side from the JWT at submit). Distinct from [[Waiter]]: the **Waiter** is the table's *current* actor (`lastActorId`, overwritten on every table op), while the **Orderer** is frozen to whoever sent that line — so two waiters serving one table show as different orderers across its tickets. Surfaced on order cards (Pesanan board) and table-detail line items as the orderer's **avatar** (initials in their account color; nothing shown when `createdBy` is absent on legacy/offline lines). _Avoid_: showing the table Waiter as if they authored a line.

### Order elapsed time
How long a line has been live, measured from its `sentAtTime` (when sent to the kitchen). Ticks live while the line is active; **freezes** once the line is `served` or `voided` (the frozen value is its total time-to-serve). Shares the venue's **overdue** threshold (the configurable [[Service target]], default 15 min) — so the Pesanan board, the floor highlight, and the overdue [[Audio alert]] all agree on "late". Replaces the older display of the raw clock time the line was sent.

### Orderer (line author)
The single staff member who submitted one specific order line. Stored per-ticket as `createdBy` (a userId, stamped server-side from the JWT at submit). Distinct from [[Waiter]]: the **Waiter** is the table's *current* actor (`lastActorId`, overwritten on every table op), while the **Orderer** is frozen to whoever sent that line — so two waiters serving one table show as different orderers across its tickets. Surfaced on order cards (Pesanan board) and table-detail line items as the orderer's **avatar** (initials in their account color; nothing shown when `createdBy` is absent on legacy/offline lines). _Avoid_: showing the table Waiter as if they authored a line.

### Order elapsed time
How long a line has been live, measured from its `sentAtTime` (when sent to the kitchen). Ticks live while the line is active; **freezes** once the line is `served` or `voided` (shown as the static sent clock, since the Ticket carries no terminal timestamp). Shares the venue's **overdue** threshold (the configurable [[Service target]], default 15 min) — so the Pesanan board, the floor highlight, and the overdue [[Audio alert]] all agree on "late". Replaces the older display of the raw clock time the line was sent.

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

### Modifier snapshot (on a sent line)
The frozen record of the add-ons a guest actually chose, captured onto a [[Order elapsed time|line]] at the moment it is sent to the kitchen. Each chosen [[Modifier group (add-on)|option]] is snapshotted with its **group**, the **option** picked, the **label** as it read at order time, and its **price delta**. The snapshot is **self-contained**: renaming, re-pricing, or deleting that modifier on the menu afterward never alters an already-sent line. The KDS reads the **label** off the snapshot (it has no menu to resolve against); reports group by the snapshotted **group**. _Avoid_: storing only the option id on the line (a reference, not a snapshot — leaves the kitchen with an unresolvable id and breaks when the menu is edited).

### Variant (variation)
A size/format choice for an item that sets an absolute price — e.g. "Reguler", "Besar". Distinct from a **modifier option**, which adjusts price by a delta. Variants are private to one item. User-facing copy: **"Varian"**.

### Menu tag (allergen / diet)
An admin-managed label attached to menu items, of one **kind**: **allergen** (a warning, rendered red/`urgent` — e.g. Gluten, Kacang) or **diet** (a property, rendered blue/`info` — e.g. Vegan, Halal). Each tag has a stable `id`, a `name` (display), a `code` (2-char badge, e.g. "GL"), a `kind`, and a `sortOrder`. Colour is **kind-derived** (allergen → `urgent`/red, diet → `info`/blue), not per-tag — matching the allergen banner in the modifier sheet and the allergen chip on the review screen.

Tags surface in three forms: the **menu card** badge rows, the **per-line-item** badge rows (under each dish name on the review/order-confirmation and table-detail line items — both rows, allergen then diet), and the **aggregate** (review's top pill, table-detail's context sheet). Per-line-item and aggregate both **live-resolve** the item's tag ids against the current menu snapshot by `itemId` — they are *not* frozen onto the sent line the way modifiers are (see [[Modifier snapshot (on a sent line)]]). A voided line shows no tag badges.

Tags are **customizable**: created/renamed/recoloured-by-kind/reordered/deleted from the menu admin's **Tag** panel (third tab beside Items / Kategori), gated by `Capability.editMenu`. Stored in one `menu_tags` table (single table, `kind` discriminator). Items reference tags by **id** (in `allergensJson` / `dietaryJson`), so a rename never breaks an item's refs. Seed tag ids equal the legacy enum names (`gluten`, `vegan`, …) so existing items need no migration. Deleting a tag **cascade-strips** its id from every item. Tags ride the `/menu` snapshot and broadcast `menuUpdated`, so every device live-refreshes. _Avoid_: a fixed `Allergen`/`DietaryTag` enum (removed) or per-tag custom colour.

### Menu photo
An optional photograph of a [[Menu category|menu item]] — a single image the admin attaches in the menu editor, sourced from the device **gallery** or shot live with the **camera**. Surfaced on the customer-facing menu card (banner) and the admin item editor (square slot). An item has **at most one** photo.

When an item has no photo, every surface falls back to the same **initials avatar** (the item name's initials on a neutral tile) — never a broken-image or empty box. Removing a photo returns the item to that fallback. The photo is **per item**: deleting the item removes its photo; it is never shared between items. _Avoid_: treating the photo as required, or showing a different placeholder per surface.

Photo edits have **commit semantics distinct from the rest of the editor**. On an **existing** item, picking or removing the photo **applies immediately** — the change is saved and broadcast to every device the moment the action completes, independent of the editor's Save button (which still governs name, price, tags, etc.). On a **brand-new** item (no row yet) the photo stays staged in the draft and lands on the first explicit Save, since the photo can only attach to a persisted item. _Avoid_: assuming the photo follows the form's staged-until-Save behaviour on an existing item.

### Guest note / Item note
Free-text remarks staff attach to a visit or a dish. Two distinct concepts, **same plain visual treatment** — a note is reference text, not an alert; it never uses the allergen `urgent`/red or any attention colour (see [[Menu tag (allergen / diet)]] for what *does* warrant attention).

- **Guest note** — table/visit level. Carried onto a table at seat time (a [[Reservation]]'s `notes`), held as `VenueTable.guestNotes`. Shown on the table detail (header, context sheet) alongside the guest name.
- **Item note** — per-line, the guest's special instruction for one dish. Captured in the modifier sheet ("Instruksi khusus"), frozen onto the sent line, shown under that line on review, the Pesanan board, and the KDS.

User-facing copy: **"Catatan"** (guest note), **"Instruksi khusus"** (item note). _Avoid_: rendering either in an allergen/warning colour, or with loud iconography — they are notes, not warnings.

### Menu classification (Klasifikasi menu)
The report's verdict on each menu item, crossing two traits: **popularitas** (how much it sells, `qty` relative to the range's top seller) and **margin** (`(basePrice − cost) / basePrice`). Each item lands in one of four buckets, split at the **median** of each trait across the range:

- **Laku & untung** (star) → jaga & sorot.
- **Laku tapi tipis** (plowhorse) → reprice / kurangi porsi.
- **Untung tapi sepi** (puzzle) → promosikan.
- **Sepi & tipis** (dog) → kandidat dipangkas.

User-facing copy is **"Klasifikasi menu"** with the plain-meaning bucket labels above (describe the trait, no metaphor); the English menu-engineering terms (Star/Plowhorse/Puzzle/Dog) stay as code/internal identifiers only. Presented as four labeled, colour-coded sections (Andalan→success, Kuda Beban→warn, Teka-teki→info, Buntung→textLo) each listing its **top items** with pop/margin, action-priority order, empty buckets shown as "tidak ada item". _Avoid_: the prior two-axis scatter "Menu engineering matrix" plot (replaced — too hard to decode) and the English jargon title in user-facing copy.

### Floor
The waiter's live operational screen that lists all tables with status chips and the **Reservasi** strip across the top. The primary jumping-off point for waiters during service. Implemented as `TablesScreen` at route **`/tables`** (`lib/ui/features/tables/`).

_Not_ the same as `FloorScreen` at route **`/floor`** (`lib/ui/features/admin/floor_screen.dart`) — that is the **admin floor configuration** screen (create/rename/reorder/delete zones and tables, capacity/active edits). The glossary term **"Floor"** always means the waiter grid; the admin screen is called **floor configuration** to keep them distinct. _Avoid_: calling the admin `/floor` screen "the Floor".

### Visit
A single seating occurrence at a [[Table]] — one party from [[Seat (verb)|seat]] to [[Bill close (Tutup tagihan)|bill close]]. The live unit that owns the visit's tickets, its [[Bill (tab)|Bill]], receipts and payments. **Independent of the physical table it occupies**: a visit can be *detached* from its table (the table freed for a new party) while its bill is still open on the [[Cashier]]. A table holds at most **one attached** (live) visit; **detached** visits live on until bill close. The visit is the key the tickets/receipts hang off — not the table — so an old unpaid visit and a new party at the same table never mix. _Avoid_: equating a visit with a table row (a table is reused across many visits; a detached visit outlives its table attachment).

### Visit end (two independent axes)
A visit ends along **two independent acts**, in **either order**:

- **[[Table close (detach)]]** (waiter / floor) — frees the table back to **kosong** for a new party. Touches table status only.
- **[[Bill close (Tutup tagihan)]]** (cashier / money) — locks the money and snapshots the visit into history.

The visit only fully disappears once **both** have happened; the snapshot (`TableSession`) is written when the **second** act completes the pair — usually [[Bill close (Tutup tagihan)|bill close]] (the cashier acts after the table is freed), but **table close** if the cashier locked the bill first while guests lingered. Whichever act lands first just records its timestamp and keeps the visit live. Until both are done the visit stays on the [[Cashier]] list — a **detached-but-unpaid** visit is flagged there ("meja sudah ditutup, tagihan belum lunas"). This **supersedes the former single "Tutup meja"** act (see [docs/adr/0024-visit-decoupled-from-table-and-bill-close.md](docs/adr/0024-visit-decoupled-from-table-and-bill-close.md), which amends ADR-0023). _Avoid_: assuming freeing the table settles the money, or that settling the bill frees the table.

### Table close (detach)
The waiter's floor act: detach the live [[Visit]] from its [[Table]] and reset the table to **kosong**, making it immediately reusable. Gated (server-enforced) on every ticket being **terminal** — served or voided; you cannot free a table with food in flight (`409 tickets_not_terminal`) — and on the [[Table lock]]. User-facing copy: **"Selesaikan Layanan"** (or **"Lepaskan Meja"** for a table seated but never ordered). It does **not** touch money and has **no effect on the [[Cashier]]**: the visit's [[Bill (tab)|bill]] lives on, now detached, until [[Bill close (Tutup tagihan)|bill close]]. It does **not** snapshot — **unless the cashier had already locked the bill** (lingering guests), in which case detach is the second axis and completes the visit (snapshot + delete). A detached visit keeps its **frozen table label + free time** so the cashier can still identify it ("Meja 7 · ditutup 19:40"). _Avoid_: the copy **"Tutup meja"** (reserved/ambiguous against [[Bill close (Tutup tagihan)]]); treating detach as settling the bill; snapshotting here.

### Bill close (Tutup tagihan)
The cashier's money act that **ends a [[Bill (tab)]]**: it **locks** the bill against further payment/receipt edits and removes the visit from the active cashier list. If the table is **already freed** it also **snapshots the [[Visit]] into history** (a `TableSession` + per-ticket / per-receipt / per-payment / per-course children) and deletes the live visit; if the table is **still occupied** the snapshot **defers** until the waiter frees it ([[Table close (detach)]]). A `TableSession` is written **exactly once per visit**, at whichever act completes the pair. Gated by **`settleBill`**. Two flavors:

- **Lunas** (normal) — allowed only when the bill is **fully settled** (every line assigned to a receipt **and** every receipt paid; outstanding == 0).
- **Tak tertagih** (write-off) — closes an unpaid / under-paid bill (e.g. a [[Walkout (tak tertagih)|walkout]]) as a **recorded loss**: the outstanding is stamped as a loss amount on the snapshot. Needs a reason + **manager approval** (the existing comp / [[Payment (manual confirmation)|refund]] authority), and is reported **distinctly from comps**.

Corrections (un-pay / **reopen**, post-payment void/comp/refund per ADR-0006) are allowed **only while the bill is still open** — after bill close the [[Past bills|snapshot]] is **immutable**. _Avoid_: the copy "Tutup meja" for this act; snapshotting at [[Table close (detach)]]; folding bill close into the waiter's table close; recording a walkout as a comp.

### Walkout (tak tertagih)
A [[Visit]] whose guests left without fully paying. After the waiter [[Table close (detach)|frees the table]], the unpaid [[Bill (tab)|bill]] stays on the [[Cashier]] (flagged). It leaves the active list only via **[[Bill close (Tutup tagihan)|bill close]] → tak tertagih (write-off)**, which records the outstanding as a **loss** (`lossAmount`), distinct from a comp. _Avoid_: leaving an unpaid bill floating forever; zeroing it out as comps (hides the loss in comp metrics).

### Past bills (cashier history)
The cashier's read-only view of recently **[[Bill close (Tutup tagihan)|closed]] bills**, capped to the **last 7 days**. Sourced from the snapshotted `TableSession` rows (which persist beyond 7 days for **reports** — the 7-day cap is only this cashier view's window, **not** a retention limit). Tap any past bill to read its [[Tagihan / Struk pembayaran (the money document)|Struk pembayaran]].

**Primary surface is venue-wide**, not per-table: a **Riwayat** tab on the [[Cashier]] screen (toggled against the live **Aktif** payable list) lists *every* closed bill across all tables, newest-first, grouped by day. A **dine-in** row leads with its **table-label** chip and reads `{time} · {N} item`; a **[[Bawa pulang (Takeaway)|takeaway]]** row instead leads with the **Bawa pulang glyph** (the long takeaway label — guest name + running number — overflows the square label chip) and surfaces that label as its title, mirroring the **Aktif** tab's takeaway treatment. The history payload carries the visit's frozen `kind` for this split. **Per-table is a filter, not a separate view** — a table-filter chip narrows the venue-wide list (client-side, scoped to a frozen `tableId`/`tableLabel` so even a since-deleted table's history is reachable), and the [[Bill (tab)|bill]] screen's **Riwayat** shortcut opens the same data pre-scoped to that one table. One server source feeds both (`/settlement/history?days=7&tableId=<optional>`). Available even when no table is currently occupied (history outlives the visit). _Avoid_: treating it as live/editable (it is immutable history); conflating the 7-day view window with data retention; framing per-table as the primary access path (it is a filter of the venue-wide list).

### Pindah meja (Move table)
Transfer one live visit from its current table (**source**, any non-`available` status) onto a chosen empty table (**target**, `available` + `active`). The whole session moves in one atomic server op: every [[Order elapsed time|ticket]] re-points its `tableId` from source → target, and the session fields (pax, `openedAt`, [[Guest note / Item note|guestName/guestNotes]], `reservationId`, `readyCount`, `openAmount`, [[Waiter|lastActorId]]) copy across; the source is wiped back to **kosong** (locks cleared). Endpoint `POST /tables/:srcId/move` (`{targetId, actorId}`), gated by `Capability.takeOrder`. User-facing copy: **"Pindahkan meja"**.

Cross-zone moves are allowed. A target whose **capacity** is below the moved **pax** is permitted with a soft warning (the waiter decides), but a target that is no longer `available` is hard-rejected (`409`), as is a source actively **[[Table lock|locked]]** by a different waiter (`409 table_locked`). The move set the target's lock to the mover, so the waiter lands on the target detail already holding it. Every move writes a `tableMoved` [[Audit]] entry ("Pindah meja {src} → {tgt}").

Because a [[Close (table) / Table session|TableSession]] is only snapshotted at **close**, a moved visit is recorded as **one** session attributed to the **final** (target) table — its `openedAt` (and thus duration) spans the whole visit across both tables; the source table shows no session for that party. The move itself survives only in the audit log. See [docs/adr/0019-move-table-session-transfer.md](docs/adr/0019-move-table-session-transfer.md). _Avoid_: splitting a moved visit into two sessions; treating the move as a merge (target must be empty).

### Void (item)
Removing a sent ticket line from an order. User-facing copy: **"Batalkan item"**. Internal term stays **void** (`Capability.voidItem`, `AuditType.voidItem`, `TicketStatus.voided`) to keep it distinct from reservation **cancel** (`pending → cancelled`).

Self-served by any waiter holding `voidItem`, allowed only pre-serve (`sent | held | prep | cooked | ready`). Voiding a `served` item is a **comp/refund**, not a void — those go through `compItem` / `refund` capabilities with manager approval. See [docs/adr/0006-self-served-void-with-per-waiter-accountability.md](docs/adr/0006-self-served-void-with-per-waiter-accountability.md).

Every void carries a canonical **reason code** — `wrongOrder` (terkirim salah), `customerChange` (tamu berubah pikiran), `outOfStock` (stok habis), `kitchenError` (kualitas dapur), `other` (free text wajib). Server stamps `actorUserId` from the JWT; reports surface per-waiter void rate and lost rupiah by reason.

### KDS / Antrian Persiapan
The unified digital preparation queue displayed on the Main Device showing all sent items chronologically, oldest-first, across every prep **station**. Staff mark items cooked/ready here; handoff (serve) happens elsewhere.
_Avoid_: "Dapur" as the screen name (Dapur is one station, not the screen), Bar screen, multi-station KDS (separate per-station screens).

### Station (Stasiun)
A prep destination an item routes to — currently **Dapur** (kitchen) and **Bar**. Stations feed the single Antrian Persiapan queue; they are not separate screens. _Note_: per-item station **routing data was removed** (migration v19 dropped the `station` column from items/tickets); the concept survives but reports cannot split metrics per station until routing returns. Per-station [[Speed of service]] is deferred for this reason.

### Speed of service (prep time / pickup lag)
How fast food moves from order to guest, measured on a [[Order elapsed time|sent line]] from its lifecycle timestamps. Two distinct durations:

- **Prep time** — `sentAt → readyAt`. The kitchen producing the dish. The headline kitchen-throughput number.
- **Pickup lag** — `readyAt → servedAt`. Food sitting at the pass waiting for a waiter — the quality killer (cold plates, complaints).

`readyAt` is stamped **once** (first entry into `ready`, so a waiter's unserve→reserve never inflates prep time); `servedAt` is **last-write** (most recent serve). A voided line carries neither. Reports surface **median** (not mean — service times are right-skewed), a per-item slowest table, an SLA hit-rate against the [[Service target]], and a per-hour degradation curve. _Avoid_: a single mean, or treating the whole-visit length (`closedAt − first sentAt`) as kitchen speed — that conflates kitchen, waiter, and guest dwell.

### Service target (prepTargetMins)
The single configurable threshold (`VenueSettings.prepTargetMins`, default **15 min**) defining "the kitchen should have this ready by now". One source of truth for two surfaces: the floor/audio **overdue** alert (a [[Order elapsed time|line]] still not ready N minutes after send) and the report **SLA hit-rate** (% of lines whose [[Speed of service|prep time]] stayed under N). Replaces the formerly hardcoded 10-minute overdue line — **on upgrade this relaxes the alert from 10→15 min** unless the owner tunes it down. _Avoid_: separate, drifting thresholds for the alert and the report.

### Batch (kitchen order)
The set of tickets a table sends together in one go — the unit a cook reads as a single "order" on the [[KDS / Antrian Persiapan]]. Identified by `(table, sentAt)`: same table, same send. One table may have several open batches across a visit (each fire/send is its own batch). A batch is **new** while it holds at least one untouched (`sent`) item, and stops being new once every item has been started (`prep`/`cooked`) or finished. The **Antrian nav badge** counts new batches across all tables — the cook's "unstarted orders" inbox. _Avoid_: equating one batch with one table (a table can hold many) or with one item (a batch is usually several items).

### Audio alert
An audible (and on waiter devices, haptic) cue that draws a staff member's attention to an event without them watching the screen. Three semantic cues:

- **Ding** — a new order reached the kitchen (a ticket was sent / a course fired). Heard by the kitchen.
- **Chime** — food is **ready** for handoff. Heard by waiters.
- **Alert** — something needs attention: an item **voided**/comped, a kitchen recall, or a ticket gone **overdue**.

**Who hears what** is by device role, not by which screen is open:

- The **kitchen** (the Main Device) hears all kitchen cues: new order, recall, and overdue.
- **Waiters** hear **ready** for any order — a dine-in [[Table]] *or* a [[Bawa pulang (Takeaway)|takeaway]] visit (shared "someone grab it" awareness); the ready toast's "Ambil" opens the matching detail (table detail vs the Bawa pulang detail). A **void/comp** cue reaches only the **responsible waiter** (the table's current waiter — see [[Waiter]]).

**Overdue** reuses the configurable [[Service target]] (default 10 min): a ticket sounds the alert once when it first crosses the target unhandled, never again for that ticket. Bursts (a fired course landing as many tickets at once) collapse to a single cue. Cues are one-shot — they never loop or demand acknowledgement. Each device may silence its own cues (the venue's "Alert audio" toggle).

### Cover
A single seated guest — one diner, not one table. A table's cover count is its **pax**; "covers served" across a [[Shift]] is the sum of pax on that waiter's non-empty tables. The unit behind per-cover averages (e.g. sales ÷ covers). User-facing copy: **"Cover"**. _Avoid_: conflating cover with table (one table seats many covers) or with [[Batch (kitchen order)|order]].

### Admin session (Firebase-gated)
An **admin** signs in with **email + password against Firebase Authentication** (project `satset-3a795`), not the local server. Firebase is the *identity and eligibility gate*; the embedded [[Local server lifecycle|local server]] remains the *capability authority* — once Firebase confirms the admin, the app still obtains a local admin JWT and every admin screen keeps talking to the local server as before. Staff [[PIN]] sign-in is unaffected and stays fully local/offline. Firebase is only exercised on a device running in **Server mode** (the admin's device); Client devices never touch it.

First sign-in needs internet; the Firebase session is then cached, so later app restarts tolerate offline operation. _Avoid_: routing staff PIN auth through Firebase, or treating the local server as merely a dumb relay — it still owns capabilities.

### Admin eligibility (T&C kill switch)
Whether a **venue** is currently allowed to operate. **As of the [[Super admin]] work the kill switch moved from the admin doc to the [[Venue (cloud)]] doc** — held in Firestore at `venues/{vid}.status` (`active` | `suspended` | `banned`), since one venue now holds **many** admins and the kill is per-venue. Only `active` permits operation; `suspended`/`banned` represent a terms-of-service violation and **block the venue** (all its admins). The app holds a **live snapshot listener** on `venues/{vid}` (resolved via the signed-in admin's `venueId`): the instant `status` leaves `active`, the app triggers the same teardown as an explicit admin logout — see [[Local server lifecycle]]. This is a *remote* kill switch, flippable mid-service.

The admin doc `admins/{uid}` keeps its own `status` as a **per-operator** ban (disable one rogue manager without killing the venue); the Server boot gate requires **both** `venue.status==active` AND `admin.status==active`. The kill switch is flipped by a [[Super admin]] from inside the app (via a Cloud Function), no longer only from the Firebase console. Security rules still forbid a normal admin from writing either doc, so it can't be self-cleared. On first sign-in a uid is **auto-provisioned a local user row** (for [[Audit]] identity) pointing at one shared local admin role — capabilities stay local, Firestore never carries them.

**Staleness guard:** the app records the last time the listener confirmed `active` *from the server* (not cache). If that is older than **7 days** while offline, the server **refuses to start** ("Perlu koneksi internet untuk verifikasi admin") until the admin gets online once — closing the dodge where a suspended admin stays offline to keep running.

### Offline grace period (masa tenggang offline)
The shrinking window the [[Admin eligibility (T&C kill switch)|staleness guard]] allows a Server-mode device to keep operating without the live Firestore listener confirming `active` *from the server*. Measured as `7 days − (now − adminConfirmedAt)`, where `adminConfirmedAt` is stamped on every non-cache confirmation (boot and live listener). It **resets to the full 7 days** the instant the device reconnects and the listener confirms; it only counts down while offline. When it reaches zero the venue is **locked**: the embedded server **refuses to start at the next cold boot** ("Perlu koneksi internet untuk verifikasi admin"). _Avoid_: the word "cooldown" (implies a forced wait after an action — this is the opposite); and assuming the lock kills a **live** session — a server already running stays up indefinitely while offline, the lock only bites at the next restart. The proactive warning exists so the admin reconnects *before* a restart traps them out.

### Local server lifecycle (tied to admin session)
The embedded LAN server's running state is bound to a valid admin session. It starts when an [[Admin session (Firebase-gated)|admin]] signs in, and is **killed on admin logout or loss of [[Admin eligibility (T&C kill switch)|eligibility]]** — connected staff/client devices are disconnected and **cannot reconnect until an admin successfully re-signs-in**. The admin session is thus the venue's on/off switch. A logout while live tables exist warns first ("X meja aktif, staff akan terputus") but still proceeds — the kill is intentional. _Avoid_: leaving the server running after the admin signs out.

### Main Device
The single device per [[Venue (cloud)|venue]] that runs the embedded [[Local server lifecycle|local server]] — the venue's one authoritative Drift DB. All other [[Admin session (Firebase-gated)|admins]] of that venue join it as **[[Admin-client|admin-clients]]** rather than hosting a second server. Because the DB is per-device and admins are interchangeable operators, a venue must have exactly one host or its data splits (divergent menus/staff, orders invisible across hosts, a lost DB when a different device boots empty). A device about to enter Server mode browses mDNS for an existing server advertising the **same `venueId`** (now in the mDNS TXT record) and, if found, refuses to start a second server and offers to join as an admin-client instead. The KDS / [[Audio alert|kitchen cues]] run on the Main Device. See [docs/adr/0017-main-device-host-and-admin-clients.md](docs/adr/0017-main-device-host-and-admin-clients.md). _Avoid_: two Server-mode devices for one venue (split-brain); treating any admin's device as a fresh data home.

### Admin-client
An [[Admin session (Firebase-gated)|admin]] who is Firebase-signed-in **and** paired into the venue's [[Main Device]] as a client, rather than hosting their own server. They get **admin capabilities from the host**, not from running a local server — admin screens therefore work in **client** mode for them (a narrowing of the old "Firebase only on the Server-mode device" stance). The host trusts them **offline**: the joining device presents its Firebase **ID token**, the host verifies the RS256 signature against cached Google public certs and checks `aud == project` + `venueId == host.venueId` + `role ∈ {admin, super}` (carried as Firebase **custom claims** set by the [[Fleet console]] Cloud Function), then issues an **admin local JWT**. The token proves *eligibility to be this venue's admin*; the [[Local server lifecycle|local server]] still owns capabilities. See ADR-0017. _Avoid_: pairing-trust (QR alone) for admin privilege — it is trivially escalatable.

### Super admin
A fleet operator who manages **many [[Venue (cloud)|venues]] and their [[Admin session (Firebase-gated)|admins]]** across the whole SatSet customer base — distinct from a venue **admin** (who runs one restaurant). Flagged by **`admins/{uid}.role == 'super'`** (normal admins are `role == 'admin'`). Detected **at Firebase login**: the app reads the signed-in admin doc and, if `super`, **diverts to the [[Fleet console]]** instead of the normal Server-mode flow — a super admin **never pairs, never runs a local server, never touches Drift**; it talks only to Firebase/Firestore + Cloud Functions. There is no separate mode-select tile; the super-admin account is created manually and recognised purely by its role.

A super admin can: CRUD venues and admin accounts, flip the per-venue [[Admin eligibility (T&C kill switch)|kill switch]], monitor [[Venue billing]], and monitor [[Venue offline duration]]. _Avoid_: granting a super admin a local server or venue of its own; routing its mutations through direct client Firestore writes (they go through Cloud Functions — see [[Fleet console]]).

### Fleet console
The single role-gated screen a [[Super admin]] lands on — the cloud control surface for the whole fleet. Read side (live Firestore, gated by an `isSuper()` rule): a **flat, urgency-sorted list of venue tiles** ([[Venue billing]] state, [[Venue offline duration]], lockout-risk); venue `status` is carried by the tile's leading icon **tint** (active→success, suspended→warn, banned→urgent) rather than a separate roster. Write side (**all** mutations via **Cloud Functions** callables, server-enforced authz, audited): create/edit venues, flip a venue's kill switch, create/disable/delete admin accounts.

**Two surfaces, by altitude:** the console list is fleet-wide and read-at-a-glance; per-venue management lives one level down in the **venue editor** (opened by tapping a tile), which owns that venue's identity, [[Venue billing]], its **admins** (the per-venue admin list + add/status/reset/delete — there is no fleet-wide admin roster), and venue delete (guarded: only when the venue has zero admins). The only mutation kept **on the tile itself** is the [[Admin eligibility (T&C kill switch)|kill switch]] (a guarded `⋮` quick-action), so its destructive mid-service friction is preserved. _Avoid_: doing mutations with direct client writes — the client only reads; credentials (Firebase Auth users) can only be managed by the Admin SDK behind a callable. _Avoid_: a separate global admin list (admins are seen only inside their venue).

### Venue (cloud)
A restaurant as a **first-class cloud entity** `venues/{vid}` — the unit the [[Fleet console]] manages and monitors. Distinct from the **local** `VenueSettings` (display name, receipt header, etc.) that lives in each Server device's Drift DB: the cloud venue carries only fleet-level fields (`name`, `status` kill switch, billing plan/state, `lastSeenAt`). **One venue → many [[Admin session (Firebase-gated)|admins]]**; each admin carries `venueId`. The admins of a venue do **not** each run a server — exactly one device is the [[Main Device]] (the authoritative server + DB) and the rest join as [[Admin-client|admin-clients]]. The cloud venue's **`name` and `address` are the source of truth for the venue's identity**: the live `venues/{vid}` listener mirrors them **read-only** into the host's local `VenueSettings.displayName`/`address` (those two fields are no longer locally editable; all other `VenueSettings` fields stay local-editable). See [docs/adr/0018-cloud-owned-venue-identity-mirror.md](docs/adr/0018-cloud-owned-venue-identity-mirror.md). _Avoid_: editing the venue name locally (it comes from the [[Fleet console]]); assuming one admin per venue (the old implicit 1:1 is gone); or assuming every admin hosts a server (only the Main Device does).

### Venue offline duration
How long a [[Venue (cloud)|venue]] has been dark — derived from `venues/{vid}.lastSeenAt`, a **heartbeat** the Server device writes (**direct client write, ~60s** while the local server is live, plus on start/stop). A **field-scoped** security rule lets a normal admin write **only** `lastSeenAt` on **their own** venue (`venueId`) and nothing else — so the heartbeat doesn't reopen the kill switch. The [[Fleet console]] surfaces `now − lastSeenAt`. _Avoid_: treating a stale heartbeat as a kill — offline ≠ suspended (a venue can be legitimately closed); and letting the heartbeat rule widen into a general venue-write.

Because the venue device stamps `lastSeenAt` on the **same heartbeat** that refreshes its local `adminConfirmedAt`, the two freeze together when the venue goes dark — so `lastSeenAt` is a faithful cloud proxy for the venue's [[Offline grace period]]. The [[Fleet console]] uses it to show a **lockout-risk** view of each venue **without any new field**: derived as `staleAfter − (now − lastSeenAt)` from the same `staleAfter` constant the venue boot gate uses. To avoid alarming on routine nightly closure, the risk badge appears **only in the final stretch** (approaching the limit), separate from the always-shown raw offline pill, and is framed as **risk, never an asserted "locked"** — from the cloud the [[Super admin]] cannot distinguish a venue that shut its app (will block on restart) from one whose server stayed up but lost internet (still serving, locks only if it later restarts). It is a support-outreach signal, **decoupled from the [[Admin eligibility (T&C kill switch)|kill switch]]** — nothing auto-suspends.

### Venue billing
The billing state of a [[Venue (cloud)|venue]], held on `venues/{vid}` as **manual flags** — `plan` (tier, e.g. free/pro), `billingStatus` (`paid` | `overdue` | `trial`), `paidUntil` (date). **No payment gateway**: a [[Super admin]] sets these by hand via a Cloud Function. Surfaced read-only to the SA in the [[Fleet console]]. Billing is **independent of the [[Admin eligibility (T&C kill switch)|kill switch]]** — an `overdue` venue keeps running until the SA *manually* flips `status` to `suspended`; nothing auto-suspends on non-payment. _Avoid_: coupling `billingStatus` to `status` automatically.

### Shift
One staff member's working session, bounded by login and logout — **not** a fixed roster block. Begins at PIN sign-in (`shiftStartedAt` = the login timestamp) and ends at **"Akhiri shift & keluar"** (sign-out). Elapsed time is `now − shiftStartedAt`. The **Ringkasan shift** ("Saya" tab) summarises the current session for its owner: their identity, sales, [[Cover|covers]], and recent [[Void (item)|void]]/comp/modify [[Audit|audit]] activity. _Avoid_: treating a shift as a scheduled shift-pattern, or as venue-wide (it is per-account, this-session only).

### Pairing vs staff session
Two independent client-side lifetimes. **Pairing** is the LAN connection to a [[Main Device]] (host URL + pinned TLS fingerprint, the `ApiConfig`), established once by QR/mDNS and held in secure storage. A **staff session** is one operator's authenticated [[Shift|shift]] (the local JWT bearer). They are orthogonal: **staff sign-out drops only the session** (revokes the token, clears `AuthState`) and **keeps the pairing** — "the connection to the server is still alive" — so the next operator can PIN in without re-scanning. Contrast the [[Local server lifecycle|admin/Server side]], where admin logout *kills the server*. _Avoid_: conflating sign-out with un-pairing; assuming a live pairing implies a live session (the data screens still need a session to load).

### Generic seed (first-run sample data)
The optional starter dataset a fresh [[Main Device]] offers to load on first admin sign-in, so a new venue is not bootstrapped against an empty DB. It is **prompted, not automatic**: the host detects an empty DB and asks the admin once (on the Venue Hub) whether to load it; declining hides the prompt for that session but leaves a **"Seed contoh data"** action in Admin → Settings and re-prompts on the next cold boot while the DB is still empty. The set is a generic restaurant: **2 zones** (Dalam / Luar) with **2 tables each**, the generic menu (categories + items + [[Menu tag (allergen / diet)|tags]]), and **2 staff** — one [[Waiter]], one Kitchen — with their roles + capabilities. It does **not** seed a PIN admin (admin comes only from Firebase — see below) and does **not** seed fake report history.

Distinct from **infra seed** — the shared admin **role** row and the `voidItem` backfill, which always seed silently and unconditionally so a Firebase-provisioned admin uid can resolve its role and operate. _Avoid_: auto-loading sample data without asking; seeding demo report history into a real venue; seeding a PIN-based admin account.

### Struk (cetak struk meja)
A printed **guest order-confirmation slip** for a live [[Table]] — lists that table's sent, non-[[Void (item)|voided]] lines (item, qty, [[Modifier group (add-on)|modifiers]], [[Guest note / Item note|item notes]]) under the venue header/footer, headed by the table label, [[Pax]], time, and — when set — the **guest name** and the table-level [[Guest note / Item note|guest note]] ("Catatan"), with **no prices, tax, service, or total**. Money is settled elsewhere; the struk only lets the guest verify what was ordered ("verifikasi pesanan"). It is a confirmation, not a fulfillment tracker — it carries no per-line sent/ready/served state, no course grouping, and no internal table fields (waiter, lock, status). Printed on demand from the table-detail **"Cetak struk meja"** action, the [[Close (table) / Table session|Tutup meja]] flow, and the order-sent screen — all through one shared print path. _Avoid_: treating the struk as the guest's **bill** (it carries no money — that is a separate, not-yet-built document); printing a table with no sent lines (nothing to confirm).

### Tagihan / Struk pembayaran (the money document)
The guest's **money** document, deliberately **named apart from the [[Struk (cetak struk meja)|Struk]]** (which is a no-money order-confirmation slip — do not overload it). This is the "separate, not-yet-built document" the Struk glossary referred to. One renderer template, two **states** — and the state is **not chosen by the cashier** but read off the document: no [[Payment (manual confirmation)|payment]] recorded yet ⇒ **Tagihan**, any payment recorded ⇒ **Struk pembayaran**.

- **Tagihan** (pre-payment bill) — venue header, table + receipt/guest label, **itemized lines with prices**, subtotal, **service** and **tax** (see [[Tax & service charge]]), and **total**. No payment block. Lets the guest verify the total before paying.
- **Struk pembayaran** (post-payment receipt) — the Tagihan **plus** the payment method(s), amount tendered, and change (and any remaining **sisa** if part-paid). Printed after settling.

Every printed line — on whole-bill, itemized, and the even-split reference list — also carries the line's chosen [[Modifier group (add-on)|modifiers]] and its [[Guest note / Item note|item note]] ("Instruksi khusus"), so the money doc lets the guest verify *exactly what was ordered* (not just totals), matching the [[Struk (cetak struk meja)|Struk]]. Especially load-bearing for [[Bawa pulang (Takeaway)|takeaway]], whose only printout is this money doc.

Prints at **two granularities**: the **whole-bill** document (the table's entire undivided tab) and a **per-receipt** document (one [[Split bill]] receipt). An **itemized** receipt lists only *its own* assigned lines with prices; an **even** receipt shows its flat **share** amount plus a compact, price-less **reference list** of the whole table's items (it owns no specific items). Reuses the existing two-scope [[Printer (scope × transport)|printer]] picker, shared print path, and transport rules (ADR-0020/0022) — only the renderer template is new. _Avoid_: overloading the word "Struk" for the money document; handing one combined whole-bill slip to guests who asked for **separate** receipts instead of printing one per receipt.

### Venue branding (receipt branding block)
The single, **venue-wide** identity block stamped on every document — the [[Struk (cetak struk meja)|Struk]], the [[Tagihan / Struk pembayaran|money docs]], and (a trimmed form) the [[Export (report / order history / staff / accounting)|PDF exports]]. There is **one** block, not a per-document one; "edit the receipt" means edit this shared block once and it shows everywhere. Composed of:

- **Logo** — an optional image. Stored as a JPEG blob on the venue-settings row and carried by a monotonic `logoRev`, **never** inlined in the settings JSON snapshot; fetched/cache-busted by `logoRev` exactly like a [[Menu photo]] (ADR-0014). Printed on thermal as a centred, monochrome-dithered raster fit to the 384-dot (58mm) width; embedded full-colour on PDFs. Gallery-picked (free aspect, auto-downscaled); clearable.
- **Venue name + address** — **read-only**, mirrored from the cloud [[Venue (cloud)|venue]] (ADR-0018). Editing "the receipt" does **not** re-open these; the branding editor shows them locked ("Dikelola pengelola").
- **Contact** — the locally-editable `phone`.
- **Header text, tagline, social line** — free-text branding lines under the name.
- **Footer text + thank-you** — closing lines; the thank-you (was a hardcoded "Terima kasih") is now its own editable field.
- **Footer QR** — one free-form URL + caption (e.g. Google review / IG). Printed on the **money docs only** — not the order-confirmation Struk, not PDFs.

Edited on the [[Venue (cloud)|venue]] identity screen ("Branding struk" card) with a **live full-sample-receipt preview** — a Flutter widget mimicking the 58mm thermal slip (it is a mock; ESC/POS bytes are not renderable). PDF exports get only the **letterhead subset** (logo + name + address + contact next to the report title) — never the customer-facing footer/tagline/thank-you/QR. _Avoid_: making this a per-document override (it is one shared block); putting logo bytes in the settings JSON; treating the QR/thank-you as appropriate for an accounting PDF.

### Printer (scope × transport)
A receipt printer the app can send a [[Struk (cetak struk meja)|struk]] to. Described by two independent traits — **scope** (who transmits) and **[[Printer transport|transport]]** (the physical link) — but only three combinations are valid:

| | wifi (network ESC/POS) | bluetooth (Classic SPP) |
|---|---|---|
| **venue** | ✅ shared, Main Device sends | ❌ impossible — server can't reach a phone's paired radio |
| **device** | ✅ this phone sends | ✅ this phone sends |

- **Venue printer** — always **wifi**. Registered to the [[Venue (cloud)|venue]], stored once in the [[Main Device]]'s DB, **shared by every device**. The [[Main Device]] **renders and sends** the bytes; a client only *triggers* the print and never talks to the printer directly. Any staff member may **add or test** one; only an **admin may delete** one (shared config).
- **Device printer** — **private to one device**, stored locally on it; that device renders and sends directly. May be **wifi** (host:port) or **bluetooth** (a paired MAC). No server involvement, no shared-config authz. **Bluetooth is device-scope only** (a BT printer is bonded to one phone's radio).

The print picker **merges both scopes** and runs the **same shared struk renderer**, so output is identical regardless of who transmits. _Avoid_: a device printer leaking into the shared venue list; a **venue+bluetooth** printer (impossible — reject in the add flow).

### Printer transport
The physical link to a [[Printer (scope × transport)|printer]], shown on each picker row by icon + address so staff can tell them apart at a glance:

- **wifi** — network ESC/POS, raw-9100 on the LAN. Address = `host:port`. Discovered by **mDNS**. Reachable by the [[Main Device]] (venue) or any phone on the LAN (device).
- **bluetooth** — Bluetooth **Classic (RFCOMM/SPP)**, the radio cheap thermal pocket printers speak. Address = a **MAC**. **Must be paired in Android settings first**; the app only enumerates *bonded* devices (no air-scan), so an unpaired printer never appears until the user pairs it in system settings.

### Printer online (reachability heartbeat)
Whether a [[Printer (scope × transport)|printer]] is reachable **right now**. The print picker lists **only online printers** as tappable; offline ones drop to a greyed "Offline" section, and a **disabled** venue printer is hidden entirely (offline ≠ disabled). Reachability is proven by a **heartbeat**, not assumed from registration:

- **Venue (wifi)** — the [[Main Device]] probes each enabled venue printer (TCP connect, no bytes sent) on a periodic tick and broadcasts the result; clients read it. A printer counts online if it answered within the freshness window.
- **Device (wifi/bluetooth)** — the owning phone probes its own printers (TCP connect for wifi, the BT plugin's connection check for bluetooth); this never crosses devices.

A probe is **connect-only** — it never spews a struk. _Avoid_: inferring "online" from a manual test print alone (the prior behaviour — `lastSeenAt` only ever moved on test, so the dot lied); air-scanning for unpaired BT printers.

### Bill (tab)
The settleable money document for **one [[Visit]]** — the whole open tab of a party, across everyone seated together. It belongs to the **visit, not the table row**, so it **outlives the table attachment**: a [[Table close (detach)|detached]] visit's bill stays open and settleable on the [[Cashier]] until [[Bill close (Tutup tagihan)|bill close]]. The unit the [[Cashier]] collects on. Distinct from a [[Order elapsed time|Ticket]] (one line), a [[Batch (kitchen order)|Batch]] (one send), and a [[Struk (cetak struk meja)|Struk]] (a no-money order-confirmation slip). A Bill's total is computed from the table's sent, non-[[Void (item)|voided]] lines (line prices → subtotal) plus venue [[Tax & service charge|tax and service charge]]. One table visit has exactly one Bill; splitting produces multiple **receipts** off that one Bill (see [[Split bill]]), not multiple Bills. This is the document CONTEXT formerly called "a separate, not-yet-built document". _Avoid_: treating a Bill as per-ticket or per-batch; conflating it with the Struk (which carries no money).

### Estimasi (cart estimate)
The provisional total shown to the [[Waiter]] **during order-taking** — on the menu cart pane and the review screen — computed over the **cart** (not-yet-sent lines) rather than a [[Bill (tab)]]'s sent lines. Uses the **same** [[Tax & service charge]] math as settlement (service-then-tax, the shared `computeBreakdown`), so the figure the waiter quotes agrees to the rupiah with what the [[Cashier]] later settles. It is **informational only** — no money binds until [[Settlement (two-phase, precedes Close)|settlement]], and the cart can still change before sending. _Avoid_: calling the cart estimate a Bill; computing it with ad-hoc rates that drift from the venue [[Tax & service charge]] settings.

### Settlement (recording payment)
The [[Cashier]] recording [[Payment (manual confirmation)|payments]] against a [[Bill (tab)]]. One of the threads of the [[Visit end (two independent axes)]]: settlement (money in) builds toward **[[Bill close (Tutup tagihan)|bill close]]** (the cashier locks + snapshots), which is **independent** of the waiter's **[[Table close (detach)]]** (freeing the floor table). Settlement can run while the table is **still occupied** (a guest pays, then lingers) **and after the table is detached** (a [[Walkout (tak tertagih)|walkout]] paid later). A [[Split bill]] settles each guest's receipt independently. Settlement does **not** require tickets terminal (a guest may pay while the last drink is still coming). _Avoid_: merging pay-and-free into one act; requiring all food served before money can be taken.

Settlement is **orthogonal to the kitchen-driven table status** — a table can be fully paid yet still **occupied**, or freed while still unpaid. No payment-bearing table status is added; the table carries a **money badge** (Lunas / Sebagian / outstanding) while attached, and a freed-but-unpaid visit surfaces on the cashier list flagged. `VenueTable` status flips to `available` at [[Table close (detach)]], **regardless** of payment. Settlement is **lock-free** — taking money never requires or respects the [[Table lock]] (a [[Waiter]] editing lines and a [[Cashier]] taking money co-occur); only [[Table close (detach)]] respects the lock. _Avoid_: a `settling`/`paid` table status (two axes in one field); making the cashier wait on a waiter's table lock.

### Cashier
The staff role that operates the **venue-wide** money screen — listing every **open [[Visit]]** with an unsettled or unclosed [[Bill (tab)]], so money is collected from one place. The list spans both **attached** visits (table still occupied, ≥1 sent line) **and detached** visits ([[Table close (detach)|table already freed]] by a waiter but bill not yet closed) — the detached-unpaid ones carry a **visual flag** ("meja sudah ditutup, tagihan belum lunas") and keep their frozen table label + free time. A **minta bill** ("guest requested the bill") highlight **sorts/raises** a visit but **does not gate** — every open visit is listed. The cashier can also browse [[Past bills]] venue-wide via a **Riwayat** tab on this screen (last 7 days, filterable by table). _Avoid_: gating the list on all-food-terminal; treating the screen as per-ticket; dropping a detached visit off the list before its bill is closed.

Gated by the **`settleBill`** capability (record payments, create/split receipts, **reopen**, and **[[Bill close (Tutup tagihan)|bill close]]** — both Lunas and tak tertagih); a **Kasir** role grants `settleBill` (plus `refund` if trusted — [[Payment (manual confirmation)|refunds]] and the **tak tertagih** write-off keep the manager-approved `refund`/comp authority, not auto-granted). The screen runs in **client mode** like other staff screens and is **not** Firebase-gated. Lives at shell route **`/kasir`** ("Kasir"). The cashier's end act is **[[Bill close (Tutup tagihan)]]** — *not* "Tutup meja"; freeing the floor table stays the waiter-side **[[Table close (detach)]]**. _Avoid_: giving the cashier a "Tutup meja" (table-freeing) button; merging bill close and table close into one capability; auto-granting refund/write-off to every cashier.

### Split bill
Dividing one [[Bill (tab)]] into multiple **receipts**, each settled independently, so guests at one table can pay separately. The [[Cashier]] picks a **mode** per bill:

- **Itemized** — each [[Order elapsed time|line]] is assigned to a **receipt**; that receipt totals its own lines plus a proportional share of [[Tax & service charge]]. "Pay for what you ordered."
- **Even** — the bill total is divided into N equal receipts; no line assignment.

One `Receipt` entity covers both: in itemized mode it **owns a set of line items**, in even mode it carries **only a share amount**. A Bill with no split is the degenerate case — one receipt owning every line. _Avoid_: modelling a split as multiple [[Bill (tab)|Bills]] (it is one Bill, many receipts); per-mode receipt entities.

**Assignment is qty-level** — a `qty: 3` line can send 2 units to one receipt and 1 to another (integer per-unit math; no fractional ownership). A genuinely shared single (qty-1) dish lands whole on one receipt or goes to an even split. **Settlement is incremental** — a receipt may be paid as soon as *its* lines are assigned, even while sibling lines are still unassigned (covers "one guest pays and leaves early"). A Bill is **fully settled** only when **every line is assigned to some receipt AND every receipt is paid**; only then may the table [[Close (table) / Table session|Close]]. _Avoid_: fractional line ownership; blocking a receipt's payment on unrelated unassigned lines.

### Tax & service charge
The two venue-level add-ons stacked onto a [[Bill (tab)]] at [[Settlement (two-phase, precedes Close)|settlement]], each gated by its own toggle in `VenueSettings` (`taxEnabled`/`taxRateBps`, `serviceEnabled`/`serviceMode`+`serviceRateBps`/`serviceFixedAmount`). **Stacking order is service-then-tax** (ID PB1 convention): service charge applies to the line **subtotal**, then tax applies to **(subtotal + service)**. e.g. 100k → +5% service = 105k → +11% tax = 116.55k.

Before this feature these toggles existed but were **never applied** — [[Close (table) / Table session|close]] stored `netTotal = subtotal`. Settlement is where they finally bind. In a [[Split bill]] each **receipt** computes service+tax on its **own** assigned-line subtotal, and the small integer **rounding remainder is pushed onto the largest receipt** so receipts always sum to the bill total exactly (no money invented or lost). The settled `TableSession` now persists `serviceAmount` and `taxAmount`, and **`netTotal` is redefined** to the *actually settled* total (`subtotal − void + service + tax`) rather than the old `netTotal == subtotal`. _Avoid_: tax-then-service order; applying tax/service per-line instead of per-receipt-subtotal; reading historical `netTotal` as if it still equals subtotal.

### Payment (manual confirmation)
A cashier-recorded **attestation** that money changed hands — there is no payment gateway, so recording the payment *is* the confirmation (no verification, no external call). A Payment attaches to a **receipt** (not the whole [[Bill (tab)]]) and carries a **method** (`tunai` | `kartu` | `qris` | `transfer` | `lainnya`, the last with a free-text note), an **amount**, the recording **cashier's userId**, and a timestamp. A receipt may hold **multiple payments** (split tender, e.g. part Tunai + part Kartu); it flips to **paid** once `sum(payments) ≥ receipt total`. A receipt is **binary paid/unpaid** — no partial-paid limbo even mid-tender. For **Tunai**, the cashier may enter **amount tendered** and the app shows **change** (`tendered − total`); tendered/change are informational (printed, not stored as revenue — the recorded amount is the receipt total). _Avoid_: treating a Payment as gateway-verified; attaching payments to the whole bill instead of a receipt; storing tendered cash as revenue.

**Post-payment correction.** [[Void (item)|Voiding]]/comping a line *after* its receipt is paid is **allowed** (with the existing manager approval, ADR-0006); the credit owed back is recorded as a **Refund** — a **negative payment** against the receipt, carrying the method it was returned by. A receipt's net = `payments − refunds`. The cashier may also **reopen** (un-pay) a receipt before [[Close (table) / Table session|Close]] to fix a mistaken settlement; reopen is itself audited. _Avoid_: freezing paid lines so corrections are impossible; letting a paid receipt's total drift with no Refund record (a lying money trail); inventing a parallel refund concept instead of reusing the `refund` capability.

### Payment proof photo (Bukti pembayaran non-tunai)
A **mandatory** photograph attesting a non-cash [[Payment (manual confirmation)]]. Shot **live by the cashier's camera** at the moment the payment is recorded. Every method **except `tunai`** (kartu, qris, transfer, lainnya) requires **exactly one photo per [[Payment (manual confirmation)|Payment]]**; cash carries none. **Camera-only — no gallery** — so the proof is a live capture, not a saved screenshot. Enforcement is **server-side and fail-closed**: a non-cash payment arriving without a photo is rejected, and the photo + payment land in **one atomic request** (no orphan). Being **per Payment**, a split tender (e.g. part QRIS + part transfer on one receipt) carries **one photo each**.

The photo is **frozen into history** alongside its payment at [[Bill close (Tutup tagihan)|bill close]] (copied into the immutable snapshot), so it remains viewable on the [[Past bills]] **Struk pembayaran** detail and in a dedicated **non-cash payments report**. A [[Payment (manual confirmation)|refund]] (negative payment) carries **no** photo. _Avoid_: a gallery-sourced image; one photo for a whole receipt or bill; gating cash on a photo; letting a photo-less non-cash payment persist.

### Admin is Firebase-only (no PIN admin)
Admin privilege is granted **only** through a Firebase admin account created by the [[Super admin]] in the [[Fleet console]] — never minted locally as a PIN user. The admin-mode **staff screen** therefore cannot assign any role that carries **`manageStaff`** (the seeded admin role *or* any custom role granting it), and the roles editor cannot grant `manageStaff` to a role; both are enforced server-side, not just in the UI. This closes the loophole where a local admin mints another admin (directly or via a custom elevated role). The old seeded PIN admin (full admin behind a 6-digit PIN) is removed; on upgrade, existing demo seed data is wiped. _Avoid_: a local break-glass PIN admin; gating the restriction in the UI only.

### Pesanan baru (table-less draft order)
A new order started **without first picking a [[Table]]** — the waiter opens the menu, builds the [[Estimasi (cart estimate)|cart]], then binds it at the review/commit step. Two terminal bindings: **assign to a table** (becomes a normal dine-in [[Visit]] via [[Seat (verb)|seat]] + submit) or **[[Bawa pulang (Takeaway)|Bawa pulang]]** (a takeaway visit with no table). The cart stays **client-local** until commit — nothing exists server-side before binding (no [[Visit]], no [[KDS / Antrian Persiapan|KDS]] line, invisible to other devices). **Complements, does not replace** the table-first flow (tap a kosong table → menu). Entry point: a **"Pesanan baru"** action on the [[Floor]]. _Avoid_: persisting a draft server-side before a table/takeaway binding (there is no server entity until commit).

### Bawa pulang (Takeaway)
A [[Visit]] that **never occupies a [[Table]]** — a takeaway order. Modeled as a Visit with `kind == takeaway`: no `tableId`/table row, `tableLabel` = the guest name (+ running takeaway number), **guestName required** (its only handle). It rides ADR-0024's two-axis end, with **handover replacing [[Table close (detach)]]**:

- **Handover ("Serahkan")** — marks the food handed to the guest. Same **all-tickets-terminal gate** as table-close (can't hand over food still cooking); stamps the visit's `tableFreedAt` (reinterpreted as handover time). Gated by `takeOrder` — **waiter or cashier** may tap it.
- **[[Bill close (Tutup tagihan)]]** — unchanged money axis.

The `TableSession` **snapshot fires at the second axis**, exactly like dine-in: pay-upfront → later handover snapshots; food-first → handover, bill stays on the [[Cashier]] flagged, later pay snapshots. `tableFreedAt` is `null` at creation (not snapshotted on bill-close while food still cooks — that would delete live [[KDS / Antrian Persiapan|KDS]] tickets). Distinguished from a detached **[[Walkout (tak tertagih)|walkout]]** by `kind` (different cashier copy: "Bawa pulang" vs "meja ditutup, belum lunas") and **reported distinctly** (takeaway vs dine-in revenue). The KDS and [[Order elapsed time|Pesanan board]] label its lines by the visit's frozen label, **not** a `tableId → table` lookup (which drops the line / shows a raw id). _Avoid_: snapshotting at bill-close while food still cooks; a pseudo "Bawa pulang" table (a table holds one visit — concurrent takeaways collide); a separate takeaway entity duplicating the bill/receipt/payment stack.

### Self-order (guest QR ordering)
The dining party ordering directly from **their own phone** by scanning a per-[[Table]] QR, with no [[Waiter]] transcribing. The guest reaches a small web app the [[Main Device]] hosts on the [[Guest plane]], browses the [[Self-order menu]], builds a cart, and submits — landing as a [[Guest order]] for staff to approve. The "guest" here is the same dining party as elsewhere in this glossary, now acting **as an actor through their own device** rather than being served by staff. Complements, never replaces, waiter order-taking ([[Pesanan baru]]); **dine-in only** ([[Bawa pulang (Takeaway)|takeaway]] excluded). Enabled by a venue master toggle (default off) plus per-table opt-in. _Avoid_: treating self-order as bypassing staff (every order is staff-confirmed); enabling it on takeaway.

### Guest plane
The **cleartext, browser-reachable** surface the [[Main Device]] exposes for guest [[Self-order (guest QR ordering)|self-ordering]] — separate listener/port from the TLS-pinned staff/admin connection ([[Pairing vs staff session]]). Carries only the guest web app, the [[Self-order menu]], menu photos, and guest order submit/status — **never** staff/admin operations. Guests reach it with a plain browser (no TLS-fingerprint pinning — a public CA can't sign a LAN IP, and a self-signed cert would scare guests off), and **must be on the same LAN segment** as the server (no cross-VLAN routing for v1). _Avoid_: exposing staff/admin endpoints on it; assuming guests pin the server's TLS fingerprint.

### Guest session
A [[Self-order (guest QR ordering)|self-ordering]] party's short-lived identity, minted when they scan a [[Table]]'s QR and **scoped to that one table's live [[Visit]]**. Expires after **2 hours**. Authorizes only guest reads + order submit against that visit — nothing on the staff plane — and goes invalid once the visit's [[Bill (tab)|bill]] closes. Scanning an unseated table **auto-opens a visit** (true self-seat); the [[Guest order]] review step is the safety net. _Avoid_: reusing a [[Pairing vs staff session|staff session]]/pairing for guests; a long-lived or global guest identity (a saved QR photo must not order indefinitely or from off-site).

### Guest order
An order a party submits themselves via [[Self-order (guest QR ordering)|self-order]], which **does not fire to the [[KDS / Antrian Persiapan|kitchen]] on submit**. It rests in a **pending-review** state until a [[Waiter]] approves it (then it becomes a normal sent [[Batch (kitchen order)|batch]]) or rejects it. The guest watches its status on their phone (received → confirmed / "please ask your server"). All lines default to one course; staff set/fire course at approval. Distinct from a waiter-sent line, which fires immediately. _Avoid_: firing a guest order straight to the kitchen; letting the guest edit/cancel after submit (staff owns it from the [[Guest order review queue]]).

### Guest order review queue
The staff surface listing pending [[Guest order]]s awaiting approval, announced by an [[Audio alert]] (reuses the ready-alert plumbing). A waiter holding `takeOrder` reads the table + items and **Approves** (fires to the [[KDS / Antrian Persiapan|kitchen]] via the normal sent transition) or **Rejects**. The deliberate confirmation step that keeps pacing + control with staff while the guest skips the transcription wait. _Avoid_: auto-approving on a timer (reintroduces the mis-tap/troll risk this step exists to stop); burying pending orders as a passive inline badge that gets missed in a rush.

### Self-order menu
The [[Menu category|menu]] as a guest sees it on the [[Guest plane]] — the same item/category/[[Modifier group (add-on)|modifier]]/[[Variant (variation)|variant]]/[[Menu tag (allergen / diet)|tag]] data as the staff menu, but **filtered to guest-visible items**: [[Habis / Sold out (menu item out of stock)|sold-out]] items, hidden categories, and any staff-only rows are dropped, live (re-fetched on load, so a mid-service 86 vanishes for guests). Prices and required-modifier rules are **server-authoritative** — the guest's phone never sets a price or skips a required choice; the server re-validates and re-prices every submit. _Avoid_: serving the raw staff menu to guests (leaks unavailable/internal rows); trusting client-sent prices.

### Report freshness (Live vs Snapshot)
Whether the [[Reports]] screen's numbers are still moving. A report over a range that **includes the current business day** (`today`) is **Live** — new sales land in it as service runs, so it reflects "now". A report over any range that **ended in the past** (`yesterday` / `7 hari` / `30 hari` / `bulan ini` / a past [[Custom range]]) is a **Snapshot** — a frozen window that no longer changes. The distinction is **informational only**: it tells staff whether to expect the figures to tick, and never gates any action. Surfaced as a **plain status line** on the report header (a freshness word beside the active range), deliberately **not** styled as a chip/button so no one mistakes it for a control. _Avoid_: rendering freshness as a tappable-looking chip; treating "Live" as a refresh mode (resync is a separate manual/auto act).

### Custom range
A sixth **timeline chip** on the [[Reports]] screen, beside the fixed presets (`today` / `yesterday` / `7 hari` / `30 hari` / `bulan ini`). Tapping it opens a sheet to pick a **start** and **end calendar date**; the window is **date-only**, snapped to the venue's **business-day boundary** like every other chip (start = business-day-of-start, end = next business-day after the end date, exclusive), never a clock-time range. The span is **capped at 92 days**. The picked range drives **both** the on-screen report **and** the [[Export (report / order history)|export]] (report + order history) — it is the single range control; there is no per-export picker. Committing requires both dates valid (start ≤ end, no future); until committed the chip stays inert and the previously active chip holds. Once committed the chip shows the picked span (e.g. "12 Jun – 15 Jun"). Custom counts as a **Snapshot** (not Live) range. _Avoid_: a clock-time range; an independent range living inside the export sheet; refetching mid-pick.

### Export (report / order history / staff / accounting)
A **range-scoped** download of venue data as **CSV or PDF**, generated on-device and handed off through the Android **share sheet** (`share_plus`). One entry point on the [[Reports]] screen — a single **Ekspor** action opens one sheet where the user first picks a **Jenis** (kind): **Laporan**, **Pesanan**, **Staf**, or **Akuntansi**. All four read the **same active timeline chip** (including [[Custom range]]); there is no per-export range picker. The four kinds:

- **Laporan (report export)** — Covers the active **timeline chip** (`today` / `yesterday` / `7 hari` / `30 hari` / `bulan ini` / `custom`) already selected on screen — export reads that chip, no separate picker. PDF carries the **full** report (every section, laid out to mirror the screen); CSV carries the **KPI block + key tables** (staff rows, menu top/slow, category mix, hourly) — visual-only bits (matrix, basket pairs, sparklines) are dropped.
- **Pesanan (order history export)** — The order board stays **live** (open tickets now); the export reads the **same active timeline chip** as the report (including [[Custom range]]) — it has **no separate range picker** and does **not** change the board. Rows are [[Orderer (line author)|line items]] for closed [[Table session (visit snapshot)|visits]] in the window, **grouped by visit** (table + party header, visit total), [[Void (item)|voided]] lines **included and flagged**.
- **Staf (staff-focus export)** — One **combined per-staff row** carrying productivity + sales + integrity together: sessions, [[Party / partySize|covers]], items, net sales, average ticket, upsell rate, void count, void %, lost rupiah, top void reason. Sorted by net descending. CSV is the wide table verbatim; PDF renders it as a **single landscape table** (the 10 columns do not fit portrait). For comparing and coaching waitstaff in one sheet. _Avoid_: splitting productivity and integrity into separate Jenis — they live on one row.
- **Akuntansi (accounting export)** — A bookkeeping view of the same window: **revenue summary** (gross subtotal → discounts → net → tax → total collected), **payment-method breakdown** (cash / QRIS / card / transfer, amount + count, refunds on their own line, for drawer-and-bank reconciliation), **voids & refunds** as write-offs, and a **per-calendar-day breakdown** for ledger posting. Tax and service are the **real settled figures** (sum of session `taxAmount` / `serviceAmount`), **not** the on-screen "Pajak + Service" 18% estimate, and the window uses the **same range rule as the on-screen report** rather than settlement-date accrual — see [[../docs/adr/0032-accounting-export-real-settled-figures-on-screen-range|ADR-0032]].

Generated via **dedicated read-only server endpoints** scoped to the range: **Laporan** reuses the [[Reports]] snapshot already in memory; **Pesanan**, **Staf**, and **Akuntansi** each hit a purpose-built window query (`/reports/staff`, `/reports/accounting`) that reuses the snapshot's `_resolveRange`. All gated behind `viewReports` — even the order list (otherwise open to `takeOrder`) — because export exposes historical financial data. _Avoid_: turning the live order board into a historical browser; trusting a client to widen its own range past the gate; splitting kinds into separate header buttons (one **Ekspor** entry, Jenis chosen inside the sheet); basing accounting tax on the cosmetic 18% KPI.

