# Domain Context

Living glossary of domain terms used in SatSet. Capture meaningful concepts for waitstaff, kitchen, and admin flows. Implementation details belong in code, not here.

## Terms

The app ships in Indonesian and English (ADR-0083). Where a term reaches the
screen, its entry opens with an **`ID · EN`** line — that pair is **canonical**,
and no ARB value may render a domain term any other way. This is what stops
`struk` being "receipt" on one screen and "bill" on the next, and it is why
machine translation cannot be trusted here: `opname` is not "inspection",
`bahan` is not "material", `resep` is not "prescription".

Entries with no pair line are internal concepts that never reach a user. Ordinary
UI words — Save, Cancel, Close — need no entry at all.

### Table
**ID · EN** — Meja · Table. Statuses: kosong · Free; terisi · Seated; pending · Open tab; ready · Ready. _Not_ "Empty/Filled" — a table is free to seat, not an empty container.

A physical seating unit in the venue (e.g. table 7, table A2). Domain model: `VenueTable`. Class renamed from `Table` to avoid `dart:ffi` conflict.

A table has a **status** that drives both the floor view and what actions are available:

- **kosong** (`available`) — no party seated. Open to any waiter. No lock held. Multiple waiters may view simultaneously.
- **terisi** (`occupied`) — party seated, possibly with open tickets. Per-user lock active on the detail screen.
- **pending** — open tab held (e.g. waiting on kitchen). Per-user lock active.
- **ready** — at least one ticket marked ready by kitchen, awaiting handoff. Per-user lock active.

### Seat (verb)
**ID · EN** — Mulai layani meja · Seat table. Walk-in seat · Walk-in; reservation seat · Seat from booking.

Transition a table from **kosong** to **terisi**. Two entry points, both hit the same `POST /tables/:id/seat` endpoint:

- **Walk-in seat** — waiter opens a kosong table from the floor, taps the "Mulai layani meja" CTA. Pax defaults to 1; adjust afterward via stepper.
- **Reservation seat** — waiter taps a reservation chip, picks a free table inside the action sheet. Carries the reservation's `partySize`, `name`, `notes`, and `reservationId` onto the table; flips the reservation to `seated` status.

Seat is rejected with `409 already_seated` if the target table is not `available`. A table may only be seated by one party at a time.

### Reseat
Seating a **new party** on a [[Table]] whose previous [[Visit]] has ended (table back to **kosong**). Not a distinct action — it is an ordinary [[Seat (verb)|seat]] on a recycled table. The point of the term: a Table's identity is **reused across Visits**, so the same `tableId` carries successive, unrelated parties over a service. The [[Visit]] — not the table — is the stable key a [[Bill (tab)|bill]] and its lines hang off. _Avoid_: treating a reseat as "reopening the old table"; the prior visit is over and its lines belong to that visit alone, never to the reseat.

### Waiter
**ID · EN** — Pelayan · Waiter. "Meja diambil oleh X" · "Table taken by X".

Per `lastActorId` on the table row — the user currently **handling** the table. Written by the five ops that constitute taking a table on: **seat**, **mark pending**, **move**, **explicit handover** (`PATCH /tables/<id>/handler`), and **submitting tickets**. Deliberately *not* written by viewing, by lock acquire, by a **pax correction**, or by **clearing a ready plate** — running someone else's food to the pass is a favour, not a takeover (ADR-0056). Cleared when the table is **closed** or **released** back to kosong — a fresh table carries no waiter. Now load-bearing: it is the **scope key for the [[Pesanan board]]**, so a spurious write silently moves a colleague's section onto your screen and yours off it. Still approximate rather than a strong "owner" claim, and there is currently **no UI** that calls the handover endpoint — a wrong handler is correctable only by re-seating. See [docs/adr/0001-table-locking-and-seat-semantics.md](docs/adr/0001-table-locking-and-seat-semantics.md) and [docs/adr/0056-pesanan-board-scoped-to-the-table-you-handle.md](docs/adr/0056-pesanan-board-scoped-to-the-table-you-handle.md).

### Orderer (line author)
**ID · EN** — Pemesan · Orderer.

The single staff member who submitted one specific order line. Stored per-ticket as `createdBy` (a userId, stamped server-side from the JWT at submit). Distinct from [[Waiter]]: the **Waiter** is the table's *current* handler (`lastActorId`), while the **Orderer** is frozen at submit to whoever sent that line — so two waiters serving one table show as different orderers across its tickets. Surfaced on order cards ([[Pesanan board]]) and table-detail line items as the orderer's **avatar** (initials in their account color; nothing shown when `createdBy` is absent on legacy/offline lines). It is the board's **fallback** ownership rule, not its primary one: the board scopes by handler, and falls back to authorship for table-less ([[Bawa pulang (Takeaway)|takeaway]]) lines and for food you sent on a table that has since moved on (ADR-0056). Never backfilled — firing a [[Course fire|held]] course does not transfer authorship to whoever fired it. _Avoid_: showing the table Waiter as if they authored a line; reading `createdBy` as "who put this in the queue".

### Pesanan board
**ID · EN** — Pesanan · Orders. Buckets: Siap diambil · Ready to run; Disiapkan · In progress; Selesai · Done. Scope switch: Milik saya · Mine; Semua · All.

The waiter's live line-level view of what the kitchen is doing, at route **`/orders`** — three buckets, **Siap diambil** / **Disiapkan** / **Selesai**, each split into [[Bawa pulang (Takeaway)|Bawa pulang]] and Makan di tempat sections. Distinct from the [[Floor]] (tables, not lines) and from the [[KDS / Antrian Persiapan|KDS]] (the kitchen's own queue).

**Scoped to you, not to the venue** (ADR-0056). A row is yours when you handle its table (`lastActorId`), *or* you authored the line (`createdBy`), *or* nobody owns it — an unowned live line shows to everyone rather than to no one. The scope governs **Disiapkan** and **Selesai** only: **Siap diambil is always venue-wide**, because the [[Alert (cue)|Pesanan siap]] cue already sounds on every waiter's handset and a plate under the lamp is everyone's problem. A **Milik saya / Semua** switch sits over the two scoped buckets; it is **session-scoped**, not device-local — the handsets are shared, so it follows the signed-in user and snaps back to Milik saya on every [[PIN]] sign-in. _Avoid_: reading an empty board as "the kitchen is quiet" (check Semua); scoping the Siap bucket; persisting the switch in device prefs, where the next person to sign in inherits it.

### Order elapsed time
**ID · EN** — Waktu berjalan · Elapsed. The pill renders a **duration**, not a clock time — `18m`, not a localised timestamp.

How long a line has been live, measured from its **[[Kitchen clock start]]** (`firedAtTime ?? sentAtTime`) — so a [[Course fire|held]] course counts from the fire, not from when the guest ordered it. Ticks live while the line is active; **freezes** once the line is `served` or `voided` (the frozen value is its total time-to-serve, off the line's own `readyAt`/`servedAt` stamps). The pill tints urgent at **that line's** resolved target (`Waktu siap`, else the venue default) — a reading aid on one row. The **cue** and the **report**, by contrast, judge lateness on the whole **[[Course]]** — see [[Waktu siap (per-item ready target)]]. Replaces the older display of the raw clock time the line was sent. The **[[Batch (kitchen order)|batch]] counter on the KDS card is a different aggregate with a different trigger** — it freezes at *all lines done*, earlier than `served` — see there.

### Table lock
**ID · EN** — "Meja diambil oleh X" · "Table taken by X" — an ICU-placeholder ARB entry, not interpolation.

Per-user advisory lease on a table's detail screen. Prevents two waiters editing the same table simultaneously. Held by the user actively viewing the detail; 7s TTL with a 3s client heartbeat. Anyone else opening the detail sees a read-only banner ("Meja diambil oleh X").

**Scope:** the lock is only active when the table's status is **not** `available`. Kosong tables are lock-free; their detail screen is read/seat-only. See ADR-0001.

### Reservation
**ID · EN** — Reservasi · Booking. Buku reservasi · Booking book. Statuses: pending · Pending; seated · Seated; noShow · No-show; cancelled · Cancelled.

A planned future visit: name, phone, party size, expected time, optional zone hint, optional pre-assigned table, optional notes. Status lifecycle: `pending` → (`seated` | `noShow` | `cancelled`). Created and seated from the **buku reservasi** — the floor head's "Reservasi" trigger, a right-side drawer on tablet and a bottom sheet on a phone (ADR-0048).

A booking may be **made against a [[Pelanggan (member)]]**. Finding the guest in the directory is the primary path and typing them in is the fallback — a regular booked by hand for the fourth time is a fourth record, and the directory is keyed on a phone number nobody re-reads carefully at 19:00. The fallback doubles as **enrolment**: name + phone with the tick on creates the member alongside the booking, so the meals that follow accrue to somebody. Enrolment is **best effort** — a booking always saves, with or without the member, because the booking is what the guest is waiting on. `name` and `phone` stay a **snapshot of what was booked**; a later rename in the directory never rewrites a past booking, the same rule [[Diskon (discount)]] keeps against its preset. Seating a linked booking hands the member to the [[Visit]] it opens, so the till starts with the standing discount live and the points earned at close without anyone looking the guest up twice. A booking is **not** a [[Visit]]: only a closed session counts toward the member's visits, spend and stempel card.

### Terlambat (reservation late)
**ID · EN** — Terlambat · Late. `N telat` · `N late`. _Not_ "Overdue" — that word belongs to [[Audio alert|Lewat waktu]], a kitchen state.

A `pending` reservation whose `expectedAt` is more than `reservationGraceMins` in the past. **Derived, never stored** — there is no `late` status and no button that sets one. A clock must not decide a no-show, and auto-flipping would make `seated` unreachable for the party that turns up at +46m. See ADR-0044 / ADR-0048.

### Dipesan (table hold)
**ID · EN** — Dipesan · Reserved. _Not_ "Booked" — that reads as the [[Reservation]] itself rather than the table standing by for it.

A **kosong** table that a `pending` reservation names, whose time falls between the start of the current business day (`businessDayStartHour`) and 60 minutes from now. The card reads "Dipesan" and prints the guest's name under the table number.

The lower bound is not cosmetic: `pending` is only ever cleared by hand, so a forgotten no-show would otherwise hold its table "Dipesan" forever.

**Derived, not persisted (ADR-0048):** no lock is taken, so releasing a no-show frees nothing and two waiters can still seat walk-ins on the same booked table. Distinct from [[Table lock]], which *is* a real lease.

### Reservasi berikutnya (next booking)
**ID · EN** — Reservasi berikutnya · Next booking.

The soonest `pending` reservation on a table beyond the hold window — a footnote on the card, not a state. Shown on occupied tables too: "this one has to be turned by 20:30".

### Basi (stale)
**ID · EN** — Basi · Stale. The banner names the overrun in words; both languages describe the condition, never the guest.

A table stuck in one condition longer than the venue allows. At most **one** per card, banded full-bleed across the card's foot, worst-condition-wins. Two severities: `crit` (urgent fill, plus a doubled hard shadow under the brutal skin) and `warn`.

| sev | condition | threshold |
| ------ | ----------------------------- | ----------------------------------------- |
| `crit` | ready, nobody collected it | `pickupTargetMins × 2` |
| `crit` | held table, guest not arrived | `reservationGraceMins` |
| `crit` | seated, still ungreeted | `ungreetedMins + ungreetedEscalateMins` |
| `warn` | everything served, idle | `idleTableMins` |
| `warn` | long occupancy | `longStayMins` |

Every threshold comes from `venue_settings`; none are hardcoded. Always **visual, never audible** — the two conditions that do have a sound cued once already, and this banner is for the cue that went unanswered, which is why those two read a second window past the audible threshold. Replaces the elapsed-clock heat ramp from ADR-0044: the banner names the same overrun in words, with the action attached. See ADR-0048.

### Party / partySize
**ID · EN** — Pax · Pax; kapasitas · Capacity.

The number of guests of a single reservation or walk-in. Distinct from a table's **capacity** (max seats); pax stepper on the table detail is clamped to `[1, capacity]`.

### Habis / Sold out (menu item out of stock)
**ID · EN** — Habis · Sold out. Ditandai habis manual · Marked sold out; Otomatis (bahan habis) · Auto (out of ingredients). The English slang "86'd" is banned in copy in both languages — opaque to non-restaurant staff.

A menu item that is not available to order right now, along **two independent axes**:

- **Ditandai habis manual** — a waiter or admin flipped the toggle (`MenuItem.unavailable`). Sticky: it stays until someone flips it back.
- **Otomatis (bahan habis)** — **derived** from [[Bahan (Ingredient)|ingredient]] stock: the item's [[Resep (Recipe)|resep]] cannot be covered. Never stored, so [[Mutasi stok (Stock movement)|receiving stock]] clears it by itself and no one has a flag to remember. An item with **no recipe** is never auto-habis.

Avoid the English slang "86'd" in user-facing copy; it is opaque to non-restaurant staff.

Derived habis is computed at **three granularities** — item, [[Variant (variation)|varian]], and [[Modifier group (add-on)|modifier option]] — so "Besar" can grey out while "Reguler" still sells, and the item itself only goes habis when *no* configuration is makeable. The flags ride the `/menu` snapshot and re-broadcast **only when one flips**; stock merely ticking down inside a bucket is silent, or the LAN would flood mid-service. See [docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md](docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md).

Code identifiers use **`soldOut`** throughout: `MenuItem.isSoldOut`, `autoSoldOut`, `soldOutVariantIds`, `soldOutOptionIds`, `MenuAdminCounts.soldOut`. The staff availability toggle is gated by **`Capability.markSoldOut`**. The earlier "86" naming (`isEightySixed`, `Capability.toggle86`) was fully renamed — no `86`/`eightySix` identifier remains (migration v21). **Migration v36 dropped `stockCount` / `autoSoldOutAtZero`** — the per-item counter that used to drive the auto-flag — converting existing counts into `pcs` bahan with 1-pcs recipes. _Avoid_: reintroducing a per-item stock number alongside bahan (two answers to "how many left" will disagree by the end of the first service).

### Menu category
**ID · EN** — Kategori · Category.

A named, ordered grouping of menu items — e.g. "Starters", "Mains", "Drinks". Managed (create/rename/reorder/delete) from the menu admin's **Kategori** panel. Ordering is by **sortOrder**. Every item always references a valid category: a category with items in it **cannot** be deleted (`409 category_not_empty`) — the admin must move or remove those items first. User-facing copy: **"Kategori"**.

### Modifier group (add-on)
**ID · EN** — Grup modifier · Modifier group. Flags: wajib · Required; pilih banyak · Multi-select. Options · Options.

A named set of choices attached to a menu item — e.g. "Tingkat pedas", "Pilih protein". Has flags **wajib** (required) and **pilih banyak** (multi-select), and a list of **options**, each with an optional price delta. Modifier groups are **private to one item** — not a shared library. Editing a group on one item never affects another, even if both happen to have a "Tingkat pedas". User-facing copy: **"Grup modifier"**. _Avoid_: treating modifiers as reusable/global.

### Modifier snapshot (on a sent line)
The frozen record of the add-ons a guest actually chose, captured onto a [[Order elapsed time|line]] at the moment it is sent to the kitchen. Each chosen [[Modifier group (add-on)|option]] is snapshotted with its **group**, the **option** picked, the **label** as it read at order time, and its **price delta**. The snapshot is **self-contained**: renaming, re-pricing, or deleting that modifier on the menu afterward never alters an already-sent line. The KDS reads the **label** off the snapshot (it has no menu to resolve against); reports group by the snapshotted **group**. _Avoid_: storing only the option id on the line (a reference, not a snapshot — leaves the kitchen with an unresolvable id and breaks when the menu is edited).

### Variant (variation)
**ID · EN** — Varian · Variant.

A size/format choice for an item that sets an absolute price — e.g. "Reguler", "Besar". Distinct from a **modifier option**, which adjusts price by a delta. Variants are private to one item. User-facing copy: **"Varian"**.

### Menu tag (allergen / diet)
**ID · EN** — Tag · Tag. Kinds: alergen · Allergen; diet · Dietary. Sample tags keep their own names (Gluten, Kacang · Nuts, Vegan, Halal) — these are venue content, not chrome.

An admin-managed label attached to menu items, of one **kind**: **allergen** (a warning, rendered red/`urgent` — e.g. Gluten, Kacang) or **diet** (a property, rendered blue/`info` — e.g. Vegan, Halal). Each tag has a stable `id`, a `name` (display), a `code` (2-char badge, e.g. "GL"), a `kind`, and a `sortOrder`. Colour is **kind-derived** (allergen → `urgent`/red, diet → `info`/blue), not per-tag — matching the allergen banner in the modifier sheet and the allergen chip on the review screen.

Tags surface in three forms: the **menu card** badge rows, the **per-line-item** badge rows (under each dish name on the review/order-confirmation and table-detail line items — both rows, allergen then diet), and the **aggregate** (review's top pill, table-detail's context sheet). Per-line-item and aggregate both **live-resolve** the item's tag ids against the current menu snapshot by `itemId` — they are *not* frozen onto the sent line the way modifiers are (see [[Modifier snapshot (on a sent line)]]). A voided line shows no tag badges.

Tags are **customizable**: created/renamed/recoloured-by-kind/reordered/deleted from the menu admin's **Tag** panel (third tab beside Items / Kategori), gated by `Capability.editMenu`. Stored in one `menu_tags` table (single table, `kind` discriminator). Items reference tags by **id** (in `allergensJson` / `dietaryJson`), so a rename never breaks an item's refs. Seed tag ids equal the legacy enum names (`gluten`, `vegan`, …) so existing items need no migration. Deleting a tag **cascade-strips** its id from every item. Tags ride the `/menu` snapshot and broadcast `menuUpdated`, so every device live-refreshes. _Avoid_: a fixed `Allergen`/`DietaryTag` enum (removed) or per-tag custom colour.

### Menu photo
**ID · EN** — Foto menu · Menu photo; Galeri · Gallery; Kamera · Camera.

An optional photograph of a [[Menu category|menu item]] — a single image the admin attaches in the menu editor, sourced from the device **gallery** or shot live with the **camera**. Surfaced on the customer-facing menu card (banner) and the admin item editor (square slot). An item has **at most one** photo.

When an item has no photo, every surface falls back to the same **initials avatar** (the item name's initials on a neutral tile) — never a broken-image or empty box. Removing a photo returns the item to that fallback. The photo is **per item**: deleting the item removes its photo; it is never shared between items. _Avoid_: treating the photo as required, or showing a different placeholder per surface.

Photo edits have **commit semantics distinct from the rest of the editor**. On an **existing** item, picking or removing the photo **applies immediately** — the change is saved and broadcast to every device the moment the action completes, independent of the editor's Save button (which still governs name, price, tags, etc.). On a **brand-new** item (no row yet) the photo stays staged in the draft and lands on the first explicit Save, since the photo can only attach to a persisted item. _Avoid_: assuming the photo follows the form's staged-until-Save behaviour on an existing item.

### Guest note / Item note
**ID · EN** — Catatan · Note (guest); Instruksi khusus · Special instructions (item). The note *content* is venue-authored and never translated.

Free-text remarks staff attach to a visit or a dish. Two distinct concepts, **same plain visual treatment** — a note is reference text, not an alert; it never uses the allergen `urgent`/red or any attention colour (see [[Menu tag (allergen / diet)]] for what *does* warrant attention).

- **Guest note** — table/visit level. Carried onto a table at seat time (a [[Reservation]]'s `notes`), held as `VenueTable.guestNotes`. Shown on the table detail (header, context sheet) alongside the guest name.
- **Item note** — per-line, the guest's special instruction for one dish. Captured in the modifier sheet ("Instruksi khusus"), frozen onto the sent line, shown under that line on review, the Pesanan board, and the KDS.

User-facing copy: **"Catatan"** (guest note), **"Instruksi khusus"** (item note). _Avoid_: rendering either in an allergen/warning colour, or with loud iconography — they are notes, not warnings.

### Menu classification (Klasifikasi menu)
**ID · EN** — Klasifikasi menu · Menu classification. Buckets: Laku & untung · Popular & profitable; Laku tapi tipis · Popular, thin margin; Untung tapi sepi · Profitable but slow; Sepi & tipis · Slow & thin. The English **must not** revert to Star/Plowhorse/Puzzle/Dog — those stay code identifiers in both languages, for the same plain-meaning reason the Indonesian abandoned them.

The report's verdict on each menu item, crossing two traits: **popularitas** (how much it sells, `qty` relative to the range's top seller) and **margin** (`(basePrice − cost) / basePrice`). Each item lands in one of four buckets, split at the **median** of each trait across the range:

- **Laku & untung** (star) → jaga & sorot.
- **Laku tapi tipis** (plowhorse) → reprice / kurangi porsi.
- **Untung tapi sepi** (puzzle) → promosikan.
- **Sepi & tipis** (dog) → kandidat dipangkas.

User-facing copy is **"Klasifikasi menu"** with the plain-meaning bucket labels above (describe the trait, no metaphor); the English menu-engineering terms (Star/Plowhorse/Puzzle/Dog) stay as code/internal identifiers only. Presented as four labeled, colour-coded sections (Andalan→success, Kuda Beban→warn, Teka-teki→info, Buntung→textLo) each listing its **top items** with pop/margin, action-priority order, empty buckets shown as "tidak ada item". _Avoid_: the prior two-axis scatter "Menu engineering matrix" plot (replaced — too hard to decode) and the English jargon title in user-facing copy.

### Floor
**ID · EN** — Meja · Floor (the waiter grid); Zona · Zone. Triggers: Reservasi · Bookings; Bawa pulang · Takeaway; Pesanan baru · New order. The admin `/floor` screen is **Konfigurasi lantai · Floor configuration**, never "Floor".

The waiter's live operational screen: zone tabs over a grid of table cards, headed by the zone's counts and three counted triggers — **Reservasi** (with a `N telat` badge), **Bawa pulang**, **Pesanan baru**. The primary jumping-off point for waiters during service. Implemented as `TablesScreen` at route **`/tables`** (`lib/ui/features/tables/`); the card is `widgets/table_card.dart` and everything it derives lives in `view_models/floor_signals.dart`. See [[Basi (stale)]] and ADR-0048.

_Not_ the same as `FloorScreen` at route **`/floor`** (`lib/ui/features/admin/floor_screen.dart`) — that is the **admin floor configuration** screen (create/rename/reorder/delete zones and tables, capacity/active edits). The glossary term **"Floor"** always means the waiter grid; the admin screen is called **floor configuration** to keep them distinct. _Avoid_: calling the admin `/floor` screen "the Floor".

### Visit
**ID · EN** — Kunjungan · Visit.

A single seating occurrence at a [[Table]] — one party from [[Seat (verb)|seat]] to [[Bill close (Tutup tagihan)|bill close]]. The live unit that owns the visit's tickets, its [[Bill (tab)|Bill]], receipts and payments. **Independent of the physical table it occupies**: a visit can be *detached* from its table (the table freed for a new party) while its bill is still open on the [[Cashier]]. A table holds at most **one attached** (live) visit; **detached** visits live on until bill close. The visit is the key the tickets/receipts hang off — not the table — so an old unpaid visit and a new party at the same table never mix. _Avoid_: equating a visit with a table row (a table is reused across many visits; a detached visit outlives its table attachment).

### Visit end (two independent axes)
A visit ends along **two independent acts**, in **either order**:

- **[[Table close (detach)]]** (waiter / floor) — frees the table back to **kosong** for a new party. Touches table status only.
- **[[Bill close (Tutup tagihan)]]** (cashier / money) — locks the money and snapshots the visit into history.

The visit only fully disappears once **both** have happened; the snapshot (`TableSession`) is written when the **second** act completes the pair — usually [[Bill close (Tutup tagihan)|bill close]] (the cashier acts after the table is freed), but **table close** if the cashier locked the bill first while guests lingered. Whichever act lands first just records its timestamp and keeps the visit live. Until both are done the visit stays on the [[Cashier]] list — a **detached-but-unpaid** visit is flagged there ("meja sudah ditutup, tagihan belum lunas"). This **supersedes the former single "Tutup meja"** act (see [docs/adr/0024-visit-decoupled-from-table-and-bill-close.md](docs/adr/0024-visit-decoupled-from-table-and-bill-close.md), which amends ADR-0023). _Avoid_: assuming freeing the table settles the money, or that settling the bill frees the table.

### Table close (detach)
**ID · EN** — Selesaikan Layanan · Finish service; Lepaskan Meja · Release table (seated, never ordered). The banned Indonesian "Tutup meja" has a banned English twin: **never "Close table"** — it reads as settling the money, which is [[Bill close (Tutup tagihan)]].

The waiter's floor act: detach the live [[Visit]] from its [[Table]] and reset the table to **kosong**, making it immediately reusable. Gated (server-enforced) on every ticket being **terminal** — served or voided; you cannot free a table with food in flight (`409 tickets_not_terminal`) — and on the [[Table lock]]. User-facing copy: **"Selesaikan Layanan"** (or **"Lepaskan Meja"** for a table seated but never ordered). It does **not** touch money and has **no effect on the [[Cashier]]**: the visit's [[Bill (tab)|bill]] lives on, now detached, until [[Bill close (Tutup tagihan)|bill close]]. It does **not** snapshot — **unless the cashier had already locked the bill** (lingering guests), in which case detach is the second axis and completes the visit (snapshot + delete). A detached visit keeps its **frozen table label + free time** so the cashier can still identify it ("Meja 7 · ditutup 19:40"). _Avoid_: the copy **"Tutup meja"** (reserved/ambiguous against [[Bill close (Tutup tagihan)]]); treating detach as settling the bill; snapshotting here.

### Bill close (Tutup tagihan)
**ID · EN** — Tutup tagihan · Close bill. Flavours: Lunas · Settled; Tak tertagih · Written off. "Tak tertagih" is **never** "Cancel"/"Batalkan" in either language — the books record a loss, and copy promising the bill never happened would lie about it.

The cashier's money act that **ends a [[Bill (tab)]]**: it **locks** the bill against further payment/receipt edits and removes the visit from the active cashier list. If the table is **already freed** it also **snapshots the [[Visit]] into history** (a `TableSession` + per-ticket / per-receipt / per-payment / per-course children) and deletes the live visit; if the table is **still occupied** the snapshot **defers** until the waiter frees it ([[Table close (detach)]]). A `TableSession` is written **exactly once per visit**, at whichever act completes the pair. Gated by **`settleBill`**. Two flavors:

- **Lunas** (normal) — **automatic**. The moment a bill becomes fully settled (every line assigned to a receipt **and** every receipt paid; outstanding == 0) it closes itself; there is no separate confirming act. The cashier's undo is **reopen**, which stays reachable from the settled bill. See [docs/adr/0069-a-bill-closes-itself-when-it-settles.md](docs/adr/0069-a-bill-closes-itself-when-it-settles.md).
- **Tak tertagih** (write-off) — the only **manual** close, and the only one that can end an unpaid / under-paid bill (e.g. a [[Walkout (tak tertagih)|walkout]]) as a **recorded loss**: the outstanding is stamped as a loss amount on the snapshot. Needs a reason + **manager approval** (the existing comp / [[Payment (manual confirmation)|refund]] authority), and is reported **distinctly from comps**. Because outstanding > 0 is its precondition, the automatic Lunas close never fires on this path.

Naming: the cashier's word for the write-off is **"Tak tertagih"**, never "Batalkan". A bill is never *cancelled* — a mistaken one is unwound line by line through [[Void (item)]]. _Avoid_: copy that promises the bill never happened while the books record a loss.

Corrections (un-pay / **reopen**, post-payment void/comp/refund per ADR-0006) are allowed **only while the bill is still open** — after bill close the [[Past bills|snapshot]] is **immutable**. _Avoid_: the copy "Tutup meja" for this act; snapshotting at [[Table close (detach)]]; folding bill close into the waiter's table close; recording a walkout as a comp.

### Walkout (tak tertagih)
**ID · EN** — Tak tertagih · Uncollected. "meja sudah ditutup, tagihan belum lunas" · "table freed, bill unpaid".

A [[Visit]] whose guests left without fully paying. After the waiter [[Table close (detach)|frees the table]], the unpaid [[Bill (tab)|bill]] stays on the [[Cashier]] (flagged). It leaves the active list only via **[[Bill close (Tutup tagihan)|bill close]] → tak tertagih (write-off)**, which records the outstanding as a **loss** (`lossAmount`), distinct from a comp. _Avoid_: leaving an unpaid bill floating forever; zeroing it out as comps (hides the loss in comp metrics).

### Past bills (cashier history)
**ID · EN** — Riwayat · History.

The cashier's read-only view of recently **[[Bill close (Tutup tagihan)|closed]] bills**. Its window is bounded on **two** axes — the **last 7 days**, and the **newest N rows** within those days, N growing as the cashier scrolls. Sourced from the snapshotted `TableSession` rows (which persist beyond both bounds for **reports** — neither is a retention limit). The row bound means the view is a **page of the window, not the window**: any count shown beside it (how many bills are lunas) is the count of the *whole* window and is never derived from the rows on screen, and any **filter over this list belongs server-side** — a filter applied to the loaded page reports "none" for a table whose bills merely sit below the page boundary. Tap any past bill to read its [[Tagihan / Struk pembayaran (the money document)|Struk pembayaran]]. See [docs/adr/0079-cashier-history-pages-by-growing-limit.md](docs/adr/0079-cashier-history-pages-by-growing-limit.md).

**Primary surface is venue-wide**, not per-table: the [[Cashier]]'s **Lunas** segment lists *every* closed bill across all tables, newest-first, grouped by day. A closed bill renders in the **same card** as a live one, so a cashier scanning **Semua** is not reading two vocabularies; only the amount's caption changes (`total dibayar` rather than `sisa tagihan`). A **[[Bawa pulang (Takeaway)|takeaway]]** card carries its [[Kanal (channel)]] pill in place of the zone. The history payload carries the visit's frozen `kind` for this split. **Per-table is a filter, not a separate view** — a table-filter chip narrows the venue-wide list (client-side, scoped to a frozen `tableId`/`tableLabel` so even a since-deleted table's history is reachable), and that chip is now the **only** way in: the [[Bill (tab)|bill]] surface no longer carries a per-table Riwayat shortcut of its own. One server source feeds it (`/settlement/history?days=7&limit=<page>&tableId=<optional>`), which answers with the page **and** the window's true total. Available even when no table is currently occupied (history outlives the visit). _Avoid_: treating it as live/editable (it is immutable history); conflating either view bound with data retention; framing per-table as the primary access path (it is a filter of the venue-wide list); counting the loaded rows to label anything; filtering the loaded page client-side.

### Pindah meja (Move table)
**ID · EN** — Pindahkan meja · Move table. The [[Audit]] row "Pindah meja {src} → {tgt}" · "Moved table {src} → {tgt}" — an ARB template under ADR-0085, no longer a stored sentence.

Transfer one live visit from its current table (**source**, any non-`available` status) onto a chosen empty table (**target**, `available` + `active`). The whole session moves in one atomic server op: every [[Order elapsed time|ticket]] re-points its `tableId` from source → target, and the session fields (pax, `openedAt`, [[Guest note / Item note|guestName/guestNotes]], `reservationId`, `readyCount`, `openAmount`, [[Waiter|lastActorId]]) copy across; the source is wiped back to **kosong** (locks cleared). Endpoint `POST /tables/:srcId/move` (`{targetId, actorId}`), gated by `Capability.takeOrder`. User-facing copy: **"Pindahkan meja"**.

Cross-zone moves are allowed. A target whose **capacity** is below the moved **pax** is permitted with a soft warning (the waiter decides), but a target that is no longer `available` is hard-rejected (`409`), as is a source actively **[[Table lock|locked]]** by a different waiter (`409 table_locked`). The move set the target's lock to the mover, so the waiter lands on the target detail already holding it. Every move writes a `tableMoved` [[Audit]] entry ("Pindah meja {src} → {tgt}").

Because a [[Close (table) / Table session|TableSession]] is only snapshotted at **close**, a moved visit is recorded as **one** session attributed to the **final** (target) table — its `openedAt` (and thus duration) spans the whole visit across both tables; the source table shows no session for that party. The move itself survives only in the audit log. See [docs/adr/0019-move-table-session-transfer.md](docs/adr/0019-move-table-session-transfer.md). _Avoid_: splitting a moved visit into two sessions; treating the move as a merge (target must be empty).

### Void (item)
**ID · EN** — Batalkan item · Void item. Reason codes: terkirim salah · Wrong order; tamu berubah pikiran · Guest changed mind; stok habis · Out of stock; kualitas dapur · Kitchen error; lainnya · Other. English **must** say "Void", not "Cancel" — reservation cancel is a different act, which is exactly why the Indonesian keeps `void` internally.

Removing a sent ticket line from an order. User-facing copy: **"Batalkan item"**. Internal term stays **void** (`Capability.voidItem`, `AuditType.voidItem`, `TicketStatus.voided`) to keep it distinct from reservation **cancel** (`pending → cancelled`).

Self-served by any waiter holding `voidItem`, allowed only pre-serve (`sent | held | prep | cooked | ready`). Voiding a `served` item is a **comp/refund**, not a void — those go through `compItem` / `refund` capabilities with manager approval. See [docs/adr/0006-self-served-void-with-per-waiter-accountability.md](docs/adr/0006-self-served-void-with-per-waiter-accountability.md).

Every void carries a canonical **reason code** — `wrongOrder` (terkirim salah), `customerChange` (tamu berubah pikiran), `outOfStock` (stok habis), `kitchenError` (kualitas dapur), `other` (free text wajib). Server stamps `actorUserId` from the JWT; reports surface per-waiter void rate and lost rupiah by reason.

### Comp
**ID · EN** — Kompensasi manajer · Comp (manager). _Not_ "Free"/"Gratis" as a label — a comp is a write-off with an approver, not a giveaway.

A dish given away — written off rather than charged. **Not its own entity: a comp *is* a [[Void (item)|void]] carrying reason code `comp`** ("Kompensasi manajer"), gated by `compItem` instead of `voidItem` because it applies to an already-**served** line and needs manager approval (ADR-0006).

The consequence that trips people up: comps are **inside** every void count, never beside them. `AuditType.comp` and `AuditType.modify` exist in the enum but are **emitted nowhere** — vestigial values, kept only so historical rows still decode. Any "comps" figure has to be derived from the void reason (reports do exactly that); a counter that reads `AuditType.comp` can only ever return zero, which is why the [[Shift|Ringkasan shift]] no longer has one.

_Avoid_: modelling comp as a parallel concept to void; counting comps and voids as disjoint sets; reading `AuditType.comp` as a live signal. Distinct from a [[Diskon (discount)]] (a priced reduction at settlement) and from a [[Settlement (recording payment)|Refund]] (money returned after payment).

### KDS / Antrian Persiapan
**ID · EN** — Antrian Persiapan · Prep Queue. "Dapur"/"Kitchen" is banned as the screen name in both languages — Dapur is one [[Station (Stasiun)|station]], not the screen.

The unified digital preparation queue displayed on the Main Device showing all sent items chronologically, oldest-first, across every prep **station**. Staff mark items cooked/ready here; handoff (serve) happens elsewhere.
_Avoid_: "Dapur" as the screen name (Dapur is one station, not the screen), Bar screen, multi-station KDS (separate per-station screens).

### Station (Stasiun)
**ID · EN** — Stasiun · Station. Dapur · Kitchen; Bar · Bar.

A prep destination an item routes to — currently **Dapur** (kitchen) and **Bar**. Stations feed the single Antrian Persiapan queue; they are not separate screens. _Note_: per-item station **routing data was removed** (migration v19 dropped the `station` column from items/tickets); the concept survives but reports cannot split metrics per station until routing returns. Per-station [[Speed of service]] is deferred for this reason.

### Speed of service (prep time / pickup lag)
**ID · EN** — Kecepatan layanan · Speed of service; Waktu masak · Prep time; Jeda antar · Pickup lag; Median · Median.

How fast food moves from order to guest, measured on a [[Order elapsed time|sent line]] from its lifecycle timestamps. Two distinct durations:

- **Prep time** — [[Kitchen clock start]] `→ readyAt`. The kitchen producing the dish. The headline kitchen-throughput number.
- **Pickup lag** — `readyAt → servedAt`. Food sitting at the pass waiting for a waiter — the quality killer (cold plates, complaints). Now has its own threshold and cue — see [[Menunggu diantar (pickup lag alert)]].

`readyAt` is stamped **once** (first entry into `ready`, so a waiter's unserve→reserve never inflates prep time); `servedAt` is **last-write** (most recent serve). A voided line carries neither. Reports surface **median** (not mean — service times are right-skewed), a per-item slowest list, an SLA hit-rate, and a per-hour degradation curve. The SLA is measured on **[[Course]]s**, not lines (see [[Waktu siap (per-item ready target)]]); the per-item slowest list is a **neutral ranked diagnostic with no pass/fail verdict**, because an item sharing a course with something slower was never judged on its own target. _Avoid_: a single mean; treating the whole-visit length (`closedAt − first sentAt`) as kitchen speed (that conflates kitchen, waiter, and guest dwell); re-adding a red/green verdict to the slowest-items list.

### Kitchen clock start
When the kitchen starts owning a line: **`firedAt ?? sentAt`**. `sentAt` means *the guest ordered it*; `firedAt` (nullable, stamped on the `held → sent` fire) means *the kitchen was handed it*. They differ only for a [[Course]] that was held and fired later — and before this existed such a course was **born overdue**, arriving at the pass already older than any target. Every prep measurement (live cue and report alike) runs from this, never from `sentAt` alone. `sentAt` is deliberately **not** re-stamped on fire: it is the KDS card-grouping key (ADR-0008) and the line time printed on the [[Struk (cetak struk meja)|struk]]. _Avoid_: measuring prep from `sentAt`; re-stamping `sentAt` at fire time.

### Waktu siap (per-item ready target)
**ID · EN** — Waktu siap · Ready target. "Ikut venue (15m)" · "Follow venue (15m)".

How long one dish should take, in minutes — `MenuItem.prepTime`, **nullable**. Null means **inherit** the venue default ([[Service target|Target siap]]) *live*, so moving the venue number moves every non-overridden item; a value is a deliberate per-item override. Set in the menu item editor, where an empty field reads back as what it would inherit ("Ikut venue (15m)"). **Item granularity only** — not per [[Variant (variation)|varian]] or [[Modifier group (add-on)|modifier option]].

**"Late" is judged on the [[Course]], not the line.** A course's target is the **`max`** of its lines' resolved targets, and the course is ready when its *last* line is ready. This is what stops a `sides` line — the course literally named "Bersama Utama" — from being flagged late at 6 minutes for correctly waiting on the 25-minute mains it plates with. The report **SLA hit-rate is therefore % of *courses* on time**, not % of lines. See [docs/adr/0043-per-item-ready-target-and-course-lateness.md](docs/adr/0043-per-item-ready-target-and-course-lateness.md). _Avoid_: reading `prepTime` raw (resolve it); judging a line against its own target; adding a second "how long does this take" number alongside it.

### Service target (prepTargetMins)
**ID · EN** — Target siap (default semua menu) · Ready target (all menu default).

The venue-wide **default** ready target (`VenueSettings.prepTargetMins`, default **15 min**) — user-facing **"Target siap (default semua menu)"**. Every menu item with a null [[Waktu siap (per-item ready target)|Waktu siap]] inherits it, so it remains the one lever that moves the whole floor (the "everything ran slow on Saturday" knob). It feeds the report SLA, the overdue cue, the [[KDS / Antrian Persiapan|KDS]] card's Telat tier and the waiter board's [[Order elapsed time|elapsed pill]] — every one of them **as the fallback in a resolved per-line target**, not as the only threshold — ADR-0013's "one source of truth" invariant now holds *per line* rather than per venue. Lives in the [[Waktu & Peringatan]] settings section, not under Laporan. _Avoid_: describing it as the single threshold; separate, drifting thresholds for the alert, the board and the report — a surface with its own hardcoded "late" is the bug ADR-0043's amendment removed.

### Batch (kitchen order)
**ID · EN** — Antrian · Queue (nav badge); Telat · Late (chip and header tally).

The set of tickets a table sends together in one go — the unit a cook reads as a single "order" on the [[KDS / Antrian Persiapan]]. Identified by `(table, sentAt)`: same table, same send. One table may have several open batches across a visit (each fire/send is its own batch). A batch is **new** while it holds at least one untouched (`sent`) item, and stops being new once every item has been started (`prep`/`cooked`) or finished. The **Antrian nav badge** counts new batches across all tables — the cook's "unstarted orders" inbox.

A batch is **complete** once *every* line is `cooked`/`ready`/`served`. Its card counter then **freezes** at the batch's real time-to-pass — from the earliest **[[Kitchen clock start]]** across its lines to the **last** line's `readyAt`, the same "ready when its last line is ready" rule a [[Course]] uses (ADR-0043). A batch is **late** past its own target — the `max` of its lines' resolved [[Waktu siap (per-item ready target)|Waktu siap]] (else the venue [[Service target]]), so the slowest dish paces the card and a drink riding along with a grill order does not drag it red; the warn tier is `0.7 ×` that. A complete batch is **never late**: no Telat chip, no red card, and no slot in the header's TELAT tally — that tally exists to say how much work is behind, and a finished batch is not work, however long it took. The frozen number therefore renders in `success`, not in the tier colour it stopped on. Distinct from **[[Order elapsed time]]**, which is per *line* and freezes later, at `served`. _Avoid_: equating one batch with one table (a table can hold many) or with one item (a batch is usually several items); measuring the card's clock from `sentAt` (a held course would be born overdue); leaving a completed batch in the TELAT tally; a board-local "late" constant that ignores the venue's target.

### Audio alert
**ID · EN** — Peringatan · Alerts. Events: Pesanan baru · New order; Pesanan siap · Order ready; Void · Void; Lewat waktu · Overdue; Belum dilayani · Not greeted; Menunggu diantar · Waiting to run. The ready toast's "Ambil" · "Collect".

An audible (and on waiter devices, haptic) cue that draws a staff member's attention to an event without them watching the screen. Each cue marks a distinct **alert event** — the *meaning*, independent of which sound plays it (see [[Alert sound (Suara)]]). **Seven** alert events:

- **Pesanan baru** (new order) — a new order reached the kitchen (a ticket was sent / a course fired). Heard by the kitchen.
- **Pesanan siap** (order ready) — food is **ready** for handoff. Heard by waiters.
- **Void** — an item was **voided**/comped (or a kitchen recall). Heard by the responsible waiter.
- **Lewat waktu** (overdue) — a **[[Course]]** crossed its resolved target unhandled. Heard by the kitchen.
- **Belum dilayani** — see [[Belum dilayani (greet alert)]]. Heard by waiters, escalating.
- **Menunggu diantar** — see [[Menunggu diantar (pickup lag alert)]]. Heard by waiters.

**Not every service state is a cue.** [[Meja lama]], [[Meja selesai makan]] and [[Terlambat (reservation)]] are deliberately **visual only** — a waiter cannot make a party leave, so a sound there is noise they cannot discharge, which devalues the cues they *can* act on.

**Who hears what** is by device role, not by which screen is open:

- The **kitchen** (the Main Device) hears all kitchen cues: new order, recall, and overdue.
- **Waiters** hear **ready** for any order — a dine-in [[Table]] *or* a [[Bawa pulang (Takeaway)|takeaway]] visit (shared "someone grab it" awareness); the ready toast's "Ambil" opens the matching detail (table detail vs the Bawa pulang detail). A **void/comp** cue reaches only the **responsible waiter** (the table's current waiter — see [[Waiter]]). Waiters also own the two table cues above.

**Overdue** reuses the configurable [[Service target]] (default **15 min**, the venue default that each line's [[Waktu siap (per-item ready target)|Waktu siap]] may override): a **course** sounds the alert once when it first crosses its target unhandled, never again. Bursts (a fired course landing as many tickets at once) collapse to a single cue. Cues are **one-shot** — they never loop or demand acknowledgement; where a missed cue would matter, the answer is [[Belum dilayani (greet alert)|escalation]], not repetition.

**Three orthogonal silencing axes**, deliberately not merged: the venue-wide **[[Alert sound (Suara)|sound choice]]** (*which clip*), the venue-wide **enable flags** on the two table cues (*venue policy*, an explicit boolean — never a `0` threshold), and the **device-local per-event mute** (*this handset*), the only device-level axis — it replaced the old all-or-nothing "Alert audio" toggle outright, so one annoying cue no longer costs the operator **Pesanan siap** as collateral. The mute list shows only cues that device's role receives. An enable flag silences the **cue**, never the signal: the threshold behind it keeps driving the [[Floor]] card's standing state and the report SLA, and stays editable while the cue is off. _Avoid_: a second device-wide audio switch anywhere outside `/alerts`; reading a disabled cue as a disabled threshold. See [docs/adr/0044-table-state-alerts-channel-escalation-and-per-event-mute.md](docs/adr/0044-table-state-alerts-channel-escalation-and-per-event-mute.md).

### Belum dilayani (greet alert)
**ID · EN** — Belum dilayani · Not greeted. _Not_ "Unserved" — the guest is waiting to be *acknowledged*, not waiting on food.

A seated [[Table]] with **no line sent yet** past `ungreetedMins` (default 7). The one new cue with a victim, a deadline, and a discharge — a guest sitting unnoticed — and it **self-clears** the moment the first line is sent. Audible, and **escalating**: the first cue reaches only the [[Waiter|seating waiter]] (`lastActorId`); `ungreetedEscalateMins` (default 5) later it goes **floor-wide**. Targeting one waiter alone would fail *silently* whenever that person is busy, in the back, or signed out — and `lastActorId` is explicitly approximate, so the escalation is what makes routing on it safe. A seater with **no live [[Pairing vs staff session|staff session]]** skips stage one altogether and the cue goes floor-wide immediately (waiter devices read `GET /auth/online` on their scan tick; sign-out deletes the session row, so the set is exact). Uncertainty biases toward silence — an unknown set is read as "cannot tell" and falls back to the normal escalation, never as "everyone is signed out". Each stage fires **once**; the escalation *is* the second chance, not a re-nag. Also shown as a standing pill on the floor card, so a missed one-shot cue is still visible. _Avoid_: routing it to one waiter only; re-nagging on an interval.

### Menunggu diantar (pickup lag alert)
**ID · EN** — Menunggu diantar · Waiting to run. _Not_ "Ready" — that is [[Audio alert|Pesanan siap]], which fires when food *becomes* ready; this fires when it has been sitting.

Food **ready but not yet delivered** for longer than `pickupTargetMins` (default 4) — the [[Speed of service|pickup lag]] the glossary already called "the quality killer", now with a threshold and a cue instead of hindsight-only reporting. Audible to waiters, one-shot per line. Reported as a **pickup SLA %** against the same number. _Avoid_: conflating it with **Pesanan siap** (that fires once when food *becomes* ready; this fires when it has been sitting).

### Meja lama
**ID · EN** — Meja lama · Long stay.

A [[Visit]] occupying its table longer than `longStayMins` (default 90). **Visual only** — it drives the floor card's elapsed-time colour ramp (which previously ran against a hardcoded 1 hour) and never sounds. A waiter cannot make a party leave, so there is nothing to discharge. _Avoid_: giving it a cue.

### Meja selesai makan
**ID · EN** — Meja selesai makan · Finished eating. The Indonesian bans "mandek"; English bans its equivalents — **no "Stalled", "Idle" or "Dead table"**. The party has done nothing wrong.

Everything ordered is **served** and nothing has moved for `idleTableMins` (default 20) — the party has probably finished and wants dessert or the bill. **Visual only**, a pill on the floor card. Requires *every* live line terminal and datable (a line still in the kitchen, or one with no `servedAt`, means the state stays off rather than guessing). _Avoid_: the word "mandek" in user-facing copy (harsh about guests who have done nothing wrong); treating it as a cue.

### Terlambat (reservation)
**ID · EN** — Terlambat · Late; noShow · No-show. Reports: % terlambat · Late %; % tidak datang · No-show %.

A **pending** [[Reservation]] past `expectedAt + reservationGraceMins` (default 15). A **derived display state** — computed at render, **never a stored status**. The reservation lifecycle is untouched: nothing auto-flips to `noShow`, because that is a judgement with customer-relationship consequences, and auto-flipping introduces a race (a party arriving at +40m and seated at +46m would already be a no-show, forcing `seated` to become reachable *from* `noShow`). `Reservations.seatedAt` is stamped **set-once** on the first flip to `seated` so lateness stays measurable — `updatedAt` moves on any later edit and cannot serve. Reports surface **late %** and **no-show %**. _Avoid_: an auto-`noShow` timer; measuring lateness off `updatedAt`.

### Waktu & Peringatan
**ID · EN** — Waktu & Peringatan · Timing & Alerts.

The venue settings section owning **every** service threshold: [[Service target|Target siap]], [[Menunggu diantar (pickup lag alert)|Menunggu diantar]], [[Belum dilayani (greet alert)|Belum dilayani]] (+ its escalation), [[Meja lama]], [[Meja selesai makan]], and the reservation grace — plus the venue enable flags and the device mute list. All thresholds are **venue-wide** (no per-[[Zone]] override: every one is 5-minute granular, so an override would almost always equal the default). `prepTargetMins` **moved here out of the Laporan section**, where it had been filed as a reporting knob despite driving live alerting — an owner chasing a noise complaint looks for alerts, not for reports. A cue's on/off switch turns off its **sound only**: the threshold beside it keeps feeding the floor card and the report, so it stays editable while the switch is off. _Avoid_: scattering thresholds next to the features they affect; putting new ones under Laporan; reading a silenced cue as a switched-off threshold.

### Alert sound (Suara)
**ID · EN** — Suara · Sound. None · None (silent).

The actual **audio file** that plays for an [[Audio alert]] event — chosen by the admin, **per event**, on the venue settings screen ("Suara" section). A small fixed library of named **presets** (each a bundled clip), plus **None** (silent for that event). The choice is a **venue-wide setting**: one admin picks it and every paired device obeys, because the same sound should mean the same thing across the floor. This is **orthogonal to routing** — *who* hears an event stays a per-device-role decision (see [[Audio alert]]), while *which clip* plays is the same everywhere — and **orthogonal to muting** — the per-device "Alert audio" toggle silences a device entirely regardless of the chosen sounds. _Avoid_: conflating the venue sound choice with the device mute toggle; making the sound choice per-device (it is shared); custom-uploaded audio (presets only for now).

### Cover
**ID · EN** — Cover · Cover (unchanged — a restaurant term in both). "Cover dilayani" · "Covers served". _Not_ "Guests" — that reads as a headcount rather than the per-cover divisor.

A single seated guest — one diner, not one table. A table's cover count is its **pax**. The unit behind per-cover averages (e.g. sales ÷ covers). User-facing copy: **"Cover"**.

"Cover dilayani" on the [[Shift|Ringkasan shift]] is a **live** count — the sum of pax on the non-empty tables that waiter currently **handles** (`lastActorId`, the same key the [[Pesanan board]] scopes on). It is not a shift total: closing a table removes its covers from the number. Reports have the cumulative figure, drawn from closed [[Close (table) / Table session|TableSessions]].

_Avoid_: conflating cover with table (one table seats many covers) or with [[Batch (kitchen order)|order]]; reading "cover dilayani" as covers served across the whole shift.

### Capability
**ID · EN** — Izin · Permission. The group headings: Pesanan · Orders; Uang · Money; Menu & stok · Menu & stock; Admin · Admin; Dapur · Kitchen.

One named thing a person is allowed to do — `takeOrder`, `refund`, `overrideStock`. Nineteen of them, fixed in code, each belonging to exactly one of five **groups** that exist only to organise the reading. A capability is never held by a person: it is held by a [[Role]], and a person inherits it by wearing that role. Three of them decide route access (`viewKds`, `takeOrder`, `manageStaff` — see the router's capability gate); the rest gate actions inside a screen. The **local server is the authority** on every one of them — Firebase carries identity, never capabilities.

The enum name is **persisted** (a role stores capability keys) and is the join to its ARB label and description. Renaming one silently drops it off every role that held it. _Avoid_: granting a capability to a user directly (there is no such column); reading the five groups as anything but headings — nothing checks a group.

### Role
**ID · EN** — Peran · Role.

A named bundle of [[Capability|capabilities]], plus a colour, that a person wears. Venue-authored: an admin creates, renames, recolours and deletes roles freely, and a role carrying no members can be deleted. A person wears **one** role or none. The role's colour is the person's fallback avatar colour and the [[Pesanan board]] filter chip.

Permissions are edited **one role at a time**, in that role's sheet, grouped by capability group — there is no cross-role comparison anywhere in the app, deliberately ([ADR-0087](docs/adr/0087-permissions-are-edited-one-role-at-a-time.md)). The **admin role is the one exception to all of it**: see [[One admin, one device]]. _Avoid_: treating a role as a job title (a venue may run two roles that both "waiter" describes); reading `UserRole` (`waiter`/`kitchen`/`admin` — a seed-and-reporting classification) as this.

### Admin session (Firebase-gated)
An **admin** signs in with **email + password against Firebase Authentication** (project `satset-3a795`), not the local server. Firebase is the *identity and eligibility gate*; the embedded [[Local server lifecycle|local server]] remains the *capability authority* — once Firebase confirms the admin, the app still obtains a local admin JWT and every admin screen keeps talking to the local server as before. Staff [[PIN]] sign-in is unaffected and stays fully local/offline. Firebase is only exercised on a device running in **Server mode** (the admin's device); Client devices never touch it.

First sign-in needs internet; the Firebase session is then cached, so later app restarts tolerate offline operation. _Avoid_: routing staff PIN auth through Firebase, or treating the local server as merely a dumb relay — it still owns capabilities.

### Admin eligibility (T&C kill switch)
Whether a **venue** is currently allowed to operate. **As of the [[Super admin]] work the kill switch moved from the admin doc to the [[Venue (cloud)]] doc** — held in Firestore at `venues/{vid}.status` (`active` | `suspended`), since the kill is per-venue rather than per-operator (it must also cut off the venue's [[Owner|owners]] and staff, not just its one admin). Only `active` permits operation; `suspended` **blocks the venue** (its admin and everyone on its floor), whether it was flipped by a [[Super admin]] over a terms-of-service violation or by the [[Subscription cutoff]] sweep. **There is no `banned`** — it was removed in [ADR-0076](docs/adr/0076-two-plans-and-a-subscription-that-cuts-off.md): it did exactly what `suspended` does, so it offered a severity-of-tone choice at the worst possible moment. Any doc still carrying `status: 'banned'` parses to `unknown`, which fails `isActive` and therefore stays blocked — no migration, fails closed. The app holds a **live snapshot listener** on `venues/{vid}` (resolved via the signed-in admin's `venueId`): the instant `status` leaves `active`, the app triggers the same teardown as an explicit admin logout — see [[Local server lifecycle]]. This is a *remote* kill switch, flippable mid-service.

The admin doc `admins/{uid}` keeps its own `status` as a **per-operator** suspension (disable one rogue manager without killing the venue), drawn from the **same two-value set** — venue status and account status share one enum and one server-side whitelist, which is why removing `banned` removed it from accounts too. An account that should never return is **deleted**, not blocked. The Server boot gate requires **both** `venue.status==active` AND `admin.status==active`. The kill switch is flipped by a [[Super admin]] from inside the app (via a Cloud Function), no longer only from the Firebase console. Security rules still forbid a normal admin from writing either doc, so it can't be self-cleared. On first sign-in a uid is **auto-provisioned a local user row** (for [[Audit]] identity) pointing at one shared local admin role — capabilities stay local, Firestore never carries them.

**Staleness guard:** the app records the last time the listener confirmed `active` *from the server* (not cache). If that is older than **7 days** while offline, the server **refuses to start** ("Perlu koneksi internet untuk verifikasi admin") until the admin gets online once — closing the dodge where a suspended admin stays offline to keep running.

### Offline grace period (masa tenggang offline)
**ID · EN** — Masa tenggang offline · Offline grace period. "Perlu koneksi internet untuk verifikasi admin" · "Internet needed to verify admin". The Indonesian bans "cooldown"; English bans it too, for the same reason — this is a window closing, not a wait being served.

The shrinking window the [[Admin eligibility (T&C kill switch)|staleness guard]] allows a Server-mode device to keep operating without the live Firestore listener confirming `active` *from the server*. Measured as `7 days − (now − adminConfirmedAt)`, where `adminConfirmedAt` is stamped on every non-cache confirmation (boot and live listener). It **resets to the full 7 days** the instant the device reconnects and the listener confirms; it only counts down while offline. When it reaches zero the venue is **locked**: the embedded server **refuses to start at the next cold boot** ("Perlu koneksi internet untuk verifikasi admin"). _Avoid_: the word "cooldown" (implies a forced wait after an action — this is the opposite); and assuming the lock kills a **live** session — a server already running stays up indefinitely while offline, the lock only bites at the next restart. The proactive warning exists so the admin reconnects *before* a restart traps them out.

### Local server lifecycle (tied to admin session)
**ID · EN** — "X meja aktif, staff akan terputus" · "X tables live, staff will be disconnected".

The embedded LAN server's running state is bound to a valid admin session. It starts when an [[Admin session (Firebase-gated)|admin]] signs in, and is **killed on admin logout or loss of [[Admin eligibility (T&C kill switch)|eligibility]]** — connected staff/client devices are disconnected and **cannot reconnect until an admin successfully re-signs-in**. The admin session is thus the venue's on/off switch. A logout while live tables exist warns first ("X meja aktif, staff akan terputus") but still proceeds — the kill is intentional.

Because of this, a Server-mode admin is the one user offered **no shift-preserving exit**: the two-exit model other roles get ("Keluar" vs "Akhiri shift & keluar", see [[Shift]]) would promise to keep their shift running while taking the venue offline, so their device shows only the shift-ending exit. Staff and [[Owner|owners]], who host nothing, are unaffected.

_Avoid_: leaving the server running after the admin signs out; offering a host admin a "lightweight" sign-out.

### Main Device
The single device per [[Venue (cloud)|venue]] that runs the embedded [[Local server lifecycle|local server]] — the venue's one authoritative Drift DB. Because the DB is per-device, a venue must have exactly one host or its data splits (divergent menus/staff, orders invisible across hosts, a lost DB when a different device boots empty). A device about to enter Server mode browses mDNS for an existing server advertising the **same `venueId`** (in the mDNS TXT record) and, if found, **refuses** — it does not start a second server, and since [ADR-0077](docs/adr/0077-one-admin-one-device.md) it no longer offers to join as an [[Admin-client (retired)|admin-client]] either. The refused device parks on a block screen naming the host it found. The KDS / [[Audio alert|kitchen cues]] run on the Main Device, which under [[One admin, one device]] is simply *the* admin's device. See [ADR-0017](docs/adr/0017-main-device-host-and-admin-clients.md) (guard) and [ADR-0077](docs/adr/0077-one-admin-one-device.md) (refusal). _Avoid_: two Server-mode devices for one venue (split-brain); treating any admin's device as a fresh data home.

### Admin-client (retired)
**Retired by [ADR-0077](docs/adr/0077-one-admin-one-device.md).** A second [[Admin session (Firebase-gated)|admin]] device used to join the venue's [[Main Device]] as a client instead of hosting its own server: it presented its Firebase **ID token** to `/auth/admin`, the host verified the RS256 signature offline against cached Google certs (checking `aud`, `venueId` and `role ∈ {admin, super}` from Firebase **custom claims**) and issued a local admin JWT. It existed because a venue then held **many** admins.

A venue now has [[One admin, one device|one admin on one device]], so there is no second admin device to admit. The route, the offline verifier, the client-side join and the `backfillAdminClaims` migration are all gone. **The custom claims are still written** by `createAdmin` and read by nothing — kept because claims cannot be reconstructed cheaply after the fact, which is the exact gap `backfillAdminClaims` existed to close. Don't delete that line as dead code. Security rules resolve everything from the `admins/{uid}` **document**, never from the token.

The term survives here because `auth.adminClient` appears in the git history and the retired flow is the first thing anyone will reinvent. _Avoid_: pairing-trust (QR alone) for admin privilege — the reason the ID-token door existed at all, and still the reason not to build a cheaper one.

### One admin, one device
**ID · EN** — Dikelola pengelola · Managed by operator (the locked admin role row).

A [[Venue (cloud)|venue]] has **exactly one active admin account, running on exactly one device**. Two rules, enforced in two places.

**One active admin.** `createAdmin` refuses when the venue already holds an admin-role doc with `status == active`; `setAdminStatus` enforces the same on reactivation, so a suspended admin coming back cannot make two. The cap counts **active**, not documents — which makes handing a venue to a new operator a **suspend-then-create** with no window where the venue has nobody, and leaves the outgoing account's doc standing for the [[Fleet audit]] rather than being deleted to make room. [[Owner]] accounts are **not** capped. Venues predating the cap keep their extra admins until an operator suspends them by hand; the venue editor warns, nothing is auto-suspended.

**The admin role is locked.** The venue's local **admin-level [[Role]]** (the one carrying `manageStaff`, held by that Firebase admin's auto-provisioned user row) is **immutable and undeletable from the staff screen** — capabilities, name and colour. Blocking only the *grant* left the worse edit open: stripping `editSettings` off it locks the venue's only admin out of the screen that could restore it, and admin being Firebase-only means no second admin role exists to repair it from. The role row shows and opens, but its [[Role]] sheet is read-only throughout — no rename, no colour, no delete, and every [[Capability]] renders as state rather than as a control — and the server refuses the PATCH and the DELETE. _Avoid_: hiding the row instead of locking it — a person in the Orang tab holds that role, and a list that omitted it would leave their row pointing at a role defined nowhere.

**One device.** The mDNS [[Main Device]] guard now terminates instead of diverting: a device finding an existing host for its `venueId` is **refused**, and lands on a block screen naming that host. The Firebase session stays signed in — the condition clears the moment the other device stops hosting, so re-entry costs a tap, not a password. The same screen carries the second cause, since the device can't tell them apart: an account that isn't this venue's admin will wait there forever and needs the operator. See [ADR-0077](docs/adr/0077-one-admin-one-device.md). _Avoid_: reading the cap as "one admin document" (suspended ones don't count); capping owners; auto-picking which surplus admin survives — only the operator knows which device holds the DB.

### Super admin
A fleet operator who manages **many [[Venue (cloud)|venues]] and the accounts attached to them** across the whole SatSet customer base — distinct from a venue **admin** (who runs one restaurant). Flagged by **`admins/{uid}.role == 'super'`** (normal admins are `role == 'admin'`). Detected **at Firebase login**: the app reads the signed-in admin doc and, if `super`, **diverts to the [[Fleet console]]** instead of the normal Server-mode flow — a super admin **never pairs, never runs a local server, never touches Drift**; it talks only to Firebase/Firestore + Cloud Functions. There is no separate mode-select tile; the super-admin account is created manually and recognised purely by its role.

A super admin can: CRUD venues and admin accounts, flip the per-venue [[Admin eligibility (T&C kill switch)|kill switch]], monitor [[Venue billing]], and monitor [[Venue offline duration]]. _Avoid_: granting a super admin a local server or venue of its own; routing its mutations through direct client Firestore writes (they go through Cloud Functions — see [[Fleet console]]).

### Fleet console
**ID · EN** — Konsol armada · Fleet console; Blokir · Block; Aktifkan · Activate; aktif · Active; ditangguhkan · Suspended.

The single role-gated screen a [[Super admin]] lands on — the cloud control surface for the whole fleet. Read side (live Firestore, gated by an `isSuper()` rule): an **urgency-sorted list of venue tiles** ([[Venue billing]] state, [[Venue offline duration]], lockout-risk), grouped under headings by *kind* of trouble and narrowable by search and by lens once the fleet is large enough to hide something; venue `status` is carried by the tile's leading icon **tint plus glyph** (active→success, suspended→warn) rather than a separate roster. Write side (**all** mutations via **Cloud Functions** callables, server-enforced authz, audited — see [[Fleet audit]]): create/edit venues, flip a venue's kill switch, set billing, create/disable/delete admin accounts.

**Two surfaces, by altitude:** the console list is fleet-wide and read-at-a-glance; per-venue management lives one level down in the **venue editor** (opened by tapping a tile), which owns that venue's identity, [[Venue billing]], its **accounts** (the per-venue admin + owner lists, with add/status/[[Sandi sementara (temporary password)|reset]]/delete — there is no fleet-wide admin roster), and venue delete (guarded: only when the venue has zero admins, and the editor stays open if the delete is refused). Identity and billing **stage and commit on Save**, which diffs against the venue's *live* document rather than the snapshot the tile was tapped on — diffing the frozen copy meant a change made from another device while the editor sat open was silently written back. The only mutation kept **on the tile itself** is the [[Admin eligibility (T&C kill switch)|kill switch]] (a guarded `⋮` quick-action), so its destructive mid-service friction is preserved. **Venue creation is name + address + plan only** (defaulting to trial, `paidUntil` unset) — term and price belong to the editor, because two places that can set a term are two places that will drift. **Adding an admin is capped at one active per venue** ([[One admin, one device]]): the add button dies once the seat is taken and says the handover sequence instead, and a venue predating the cap gets a warning naming how many it holds. [[Owner|Owners]] are uncapped. _Avoid_: doing mutations with direct client writes — the client only reads; credentials (Firebase Auth users) can only be managed by the Admin SDK behind a callable. _Avoid_: a separate global admin list (admins are seen only inside their venue).

### Owner
**ID · EN** — Pemilik · Owner. Distinct from **Pengelola · Operator** (the [[Super admin]]) and **Admin · Admin** (runs the floor) — three cloud identities, three words, both languages.

A venue stakeholder who watches **one venue's [[Venue report snapshot|reports]] from outside the venue** — distinct from a venue **admin** (who runs the floor on-site, paired to the [[Local server lifecycle|local server]]) and from a [[Super admin]] (fleet-wide). A third cloud identity flagged by **`admins/{uid}.role == 'owner'`**, bound to one `venueId`. Detected **at Firebase login** like the super admin: an `owner` role **diverts to a read-only [[Owner report view]]** instead of the pair gate — an owner **never pairs, never runs a local server, never touches Drift**, and cannot reach the floor at all (the [[Admin-client (retired)|admin-client]] door it was deliberately excluded from no longer exists for anyone). It is **not** a local [[Role]]/[[Capability]] — those stay venue-internal and LAN-gated; the owner sees only what the host **publishes** to the cloud, never live operational screens. Created by a [[Super admin]] in the [[Fleet console]] venue editor like any admin account — same `admins` collection (role-tagged principals, not a new collection), same `{role, venueId}` custom claim, the `createAdmin` callable extended to accept `role ∈ {admin, owner}`. The owner is held **powerless on the floor** by three exclusions: server-mode boot rejects owner, `isSuper()` excludes it (no fleet read), and its Firestore footprint is exactly read-`reports/{vid}` + write-`report_requests/{vid}`. An owner doc **counts toward the venue-delete guard** (a venue with an owner attached can't be deleted). _Avoid_: modelling owner as a local Drift role (it can never satisfy the pair gate); letting owner pair, boot a server, or act on the floor.

### Venue report snapshot
A **pre-aggregated, periodically-published copy of one venue's [reports](#)** living in the cloud at `reports/{vid}`, so an [[Owner]] can read venue activity **without reaching the [[Local server lifecycle|local server]]**. The [[Main Device|host]] already computes the full report JSON on demand (`/reports/snapshot` — sales/staff/menu/ops/payments, KPIs as formatted strings, KB-scale); on a fixed **interval** it writes that blob to `reports/{vid}` as the signed-in admin, gated by a **field-scoped** rule that mirrors the [[Venue offline duration|heartbeat]] (a normal admin writes the report doc **only** on its own `venueId`). It is **not real-time** — it reflects the venue as of the last publish (a `generatedAt` stamp travels with it), republished on a **fixed ~30-min interval** plus on server start/stop, covering a **fixed range set ({today, 7d})** — the owner gets the host's cadence and ranges, **never arbitrary date-picking** (that needs a live server). Kept in a **separate doc** from `venues/{vid}` so the [[Fleet console]]'s venue reads don't drag the report payload. _Avoid_: pushing raw order rows (publish the aggregate only); putting it on `venues/{vid}`; routing the write through a Cloud Function (the host already heartbeats its own venue directly — same trust level).

### Report refresh request
The owner's **manual-refresh command** across the venue air gap. An [[Owner]] is outside the venue and cannot reach the [[Main Device|host]], so refresh is **cloud-mediated**, not a direct pull: the owner writes `report_requests/{vid}.requestedAt = serverTimestamp()` (a tiny **command** doc the owner may write **only** that field on), the host holds a live listener on it, and on a `requestedAt` newer than its last publish it recomputes and rewrites the [[Venue report snapshot]] (`reports/{vid}`). **Command and state are separate docs on purpose** — owner writes the command, host writes the state — so rules stay clean and the host's own republish never re-triggers its own listener. If the host is **offline** the request just waits: the [[Owner report view]] shows the stale `generatedAt` plus a "refresh requested, venue may be offline" state derived from `generatedAt` not advancing — **never a hanging spinner**. UI disables the button ~30s per tap; the host ignores a `requestedAt` it already satisfied. _Avoid_: modelling refresh as a live pull from the host; a refresh that spins forever when the host is dark.

### Owner report view
**ID · EN** — Laporan · Reports; Diperbarui · Updated; "refresh diminta, venue mungkin offline" · "refresh requested, venue may be offline".

The single read-only screen an [[Owner]] diverts to at Firebase login (`role == 'owner'` → `/owner`), the cloud counterpart to the on-site Admin → Reports screen. Renders the latest [[Venue report snapshot]] from `reports/{vid}` with its `generatedAt` freshness and a manual [[Report refresh request|refresh]], and **nothing else** — no floor, no live data, no filters, no mutations. An owner's **entire** cloud footprint is: **read** `reports/{vid}`, **write** `report_requests/{vid}.requestedAt` — no access to `venues/{vid}`, other admins, or any other venue (freshness/offline is derived from `generatedAt` alone, so no `venues` read is needed). _Avoid_: wiring it to the local report endpoints (an owner has no paired server); granting it any read beyond its one report doc; offering the on-site report **filters** (server/zone/category — those need a live server).

### Venue (cloud)
A restaurant as a **first-class cloud entity** `venues/{vid}` — the unit the [[Fleet console]] manages and monitors. Distinct from the **local** `VenueSettings` (display name, receipt header, etc.) that lives in each Server device's Drift DB: the cloud venue carries only fleet-level fields (`name`, `status` kill switch, [[Venue billing|subscription]] plan/term/price, `lastSeenAt`). **One venue → one active [[Admin session (Firebase-gated)|admin]]** ([[One admin, one device]]), plus any number of [[Owner|owners]]; each carries `venueId`. That admin's device is the [[Main Device]] — the authoritative server + DB — and it is the only device that can host. The cloud venue's **`name` and `address` are the source of truth for the venue's identity**: the live `venues/{vid}` listener mirrors them **read-only** into the host's local `VenueSettings.displayName`/`address` (those two fields are no longer locally editable; all other `VenueSettings` fields stay local-editable). See [docs/adr/0018-cloud-owned-venue-identity-mirror.md](docs/adr/0018-cloud-owned-venue-identity-mirror.md). _Avoid_: editing the venue name locally (it comes from the [[Fleet console]]); reading the one-admin rule as one admin *document* (suspended docs survive and don't count); counting [[Owner|owners]] against it.

### Venue offline duration
How long a [[Venue (cloud)|venue]] has been dark — derived from `venues/{vid}.lastSeenAt`, a **heartbeat** the Server device writes (**direct client write, ~60s** while the local server is live, plus on start/stop). A **field-scoped** security rule lets a normal admin write **only** `lastSeenAt` on **their own** venue (`venueId`) and nothing else — so the heartbeat doesn't reopen the kill switch. The [[Fleet console]] surfaces `now − lastSeenAt`. _Avoid_: treating a stale heartbeat as a kill — offline ≠ suspended (a venue can be legitimately closed); and letting the heartbeat rule widen into a general venue-write.

Because the venue device stamps `lastSeenAt` on the **same heartbeat** that refreshes its local `adminConfirmedAt`, the two freeze together when the venue goes dark — so `lastSeenAt` is a faithful cloud proxy for the venue's [[Offline grace period]]. The [[Fleet console]] uses it to show a **lockout-risk** view of each venue **without any new field**: derived as `staleAfter − (now − lastSeenAt)` from the same `staleAfter` constant the venue boot gate uses. To avoid alarming on routine nightly closure, the risk badge appears **only in the final stretch** (approaching the limit), separate from the always-shown raw offline pill, and is framed as **risk, never an asserted "locked"** — from the cloud the [[Super admin]] cannot distinguish a venue that shut its app (will block on restart) from one whose server stayed up but lost internet (still serving, locks only if it later restarts). It is a support-outreach signal, **decoupled from the [[Admin eligibility (T&C kill switch)|kill switch]]** — nothing auto-suspends.

### Sandi sementara (temporary password)
**ID · EN** — Sandi sementara · Temporary password; Reset password · Reset password; "Lupa password?" · "Forgot password?".

How an [[Admin]] who has lost their password gets back in. A [[Super admin]] taps **Reset password** in the [[Fleet console]] venue editor; the `resetAdminPassword` callable sets a random **8-digit** password on the Firebase Auth user and flags `admins/{uid}.mustChangePassword` with a `passwordResetAt` stamp. The code is shown to the operator **once**, who **reads it out** to the venue over a phone call or WhatsApp — there is no mail sender in this project, and recovery here has always been a phone call (the venue's own "Lupa password?" opens WhatsApp too). Eight digits because it is dictated in a loud room and typed on a tablet: no case to ask about, no letter that sounds like another.

**Forced replacement, checked first.** `signInAsAdmin` tests the flag **before every divert and before `bootServer`** — ahead of the super/owner branches, the eligibility read, the [[Admin eligibility (T&C kill switch)|kill switch]] and the mDNS host lookup. The admin lands on a blocking change-password screen; `changeOwnPassword` (guarded on *owning the account*, not on being super) sets the new password and clears the flag in one call, and the app then re-runs sign-in so the whole gauntlet fires normally. `evaluateForBoot` refuses the same state at cold start. So a code that travelled by voice never boots a server or mints a local session.

**Dies at 24 hours, twice.** An hourly scheduled function re-randomizes any outstanding code past its term, making it dead at Firebase for every client; the app compares the same `passwordResetAt` during sign-in, closing the gap between expiry and the sweep next waking. `FirebaseAdminService.otpTtl` and `OTP_TTL_MS` must stay equal. A super admin cannot be reset this way — the callable refuses `role == 'super'`, because one fleet operator resetting another locks out whoever is not holding the phone. See [ADR-0075](docs/adr/0075-dictated-temporary-password.md). _Avoid_: `generatePasswordResetLink` (mints a URL and sends nothing); logging or storing the code anywhere; identifying the account to reset by email rather than uid; letting the change screen be dismissed without signing out.

### Fleet audit
The record of **who did what** on the cloud control plane, at `fleet_audit/{id}` — actor uid, action, target (venue or admin, with its name captured *before* a delete removes it), and the `before`/`after` of the fields that changed. The actor is a [[Super admin]]'s uid, or the reserved sentinel **`'system'`** (rendered "Sistem") for a [[Subscription cutoff]] — `actorUid` is a free string with no reference, so the sentinel costs nothing, and the one class of change nobody remembers making is exactly the one whose record gets wanted at 09:00. Written **only** by the Cloud Functions through a single `writeFleetAudit()` helper, for the same reason the venue server routes every act through `writeAudit` (`lib/server/audit_log.dart`): hand-roll the insert and a new field reaches three call sites out of four. Read is **super-only**; client writes are denied outright, because a log its own subject can edit is not a log.

**Best-effort, never blocking** — a failed audit write must not roll back the mutation it describes, so it degrades to a Cloud Logging error. An operator whose "Blokir" fails because the *log* failed will simply tap it again; a venue left running because its audit row did not commit is the worse outcome. **Never carries a credential**: `resetAdminPassword` records the email it was asked about and never the [[Sandi sementara (temporary password)|code]] it minted, and `changeOwnPassword` records that a password changed and nothing about what it changed to. The expiry sweep writes its rows with the actor `system`, because no operator tapped anything and a blank actor would read as an unattributed credential change. Distinct from the venue-internal [[Audit]] trail, which is Drift-local and per-venue. _Avoid_: writing audit rows outside the helper; a client-writable audit path; storing the code.

### Venue billing
**ID · EN** — Langganan · Subscription. Plans: Trial · Trial; Partner · Partner. Cycles: bulanan · Monthly; tahunan · Yearly. `+1 tahun` · `+1 year`. The **price** is rupiah and never localises (ADR-0084); `paidUntil` is a date and does.

The commercial arrangement between a [[Venue (cloud)|venue]] and the operator, held on `venues/{vid}`. **No payment gateway**: a [[Super admin]] sets it by hand via the `setVenueBilling` callable, from the [[Fleet console]] venue editor.

**Exactly two plans**, and a plan now carries data rather than being a recorded string:

- **Trial** — `trialStartAt` (recorded and displayed, enforces nothing) and `paidUntil` as the end date, both SA-set. No price.
- **Partner** — `priceMonthly` (integer rupiah) and `billingCycle` (`monthly` | `yearly`). **Yearly is two months off**: the total is `priceMonthly × 10` for twelve months, and choosing it collapses the renewal control to a single `+1 tahun`, because a control that renews a yearly venue one month at a time makes the cycle decorative.

**Dates are the only billing truth.** `billingStatus` was deleted in [ADR-0076](docs/adr/0076-two-plans-and-a-subscription-that-cuts-off.md) — it could disagree with `paidUntil`, and the disagreement it produced (`paid` with a date three weeks gone: healthy on every surface, billing nobody) was the worst state the console could hold. **lapsed** is `paidUntil < now`; **ending** is inside `fleetRenewWarn` (14 days) and still ahead. Both are shared code (`data/services/venue_billing.dart`) rather than duplicated per surface, so the operator's warning and the venue's warning can never be about different things, and they are mutually exclusive — a lapsed date is never also reported as ending.

**`plan` selects the rules, not the features.** It decides which fields are meaningful and which [[Subscription cutoff]] applies. It still gates no feature inside the venue and the embedded server still knows nothing about it; there is no entitlement model.

_Avoid_: a `billingStatus` flag in any form (the dates say it); a plan that carries neither a price nor a term; reading `plan` as an entitlement; setting a price on a trial.

### Subscription cutoff
When an unpaid [[Venue billing|subscription]] actually stops a venue trading. An hourly scheduled function (`onSchedule`, riding the pattern `sweepExpiredTempPasswords` proved) flips `status` to `suspended` on any `active` venue past its cutoff:

- **Trial: on the date.** No grace. Going dark is what a trial is *for*, and a trial that quietly runs forever is a free venue nobody decided to give away.
- **Partner: `fleetGraceAfterLapse` (7 days) after it.** Half the 14-day warning window, deliberately asymmetric — 14 days of banner before the date and 7 after is three weeks of visible notice, and a late bank transfer still lands in time.
- **`paidUntil == null` never lapses**, so a newly created venue with no term set sits idle rather than being cut off at creation.

This **overturns ADR-0074's central invariant** (*"nothing auto-suspends on non-payment"*) on purpose; ADR-0074's real objection — a mis-typed date taking a restaurant offline mid-service — is answered by the partner grace window rather than by an exemption.

**The sweep cannot fight the operator.** `Aktifkan` is **disabled while a venue is lapsed past its grace**, so the only route back is a future date and there is nothing for the sweep to undo — an invariant instead of a bookkeeping field. **Extending re-enables the button; it does not press it**, because nothing distinguishes a lapse-suspension from one an SA set by hand over a dispute, and recording a payment must never silently revive a venue taken offline on purpose.

Every cutoff writes [[Fleet audit]] with the reserved `actorUid: 'system'` and `action: 'autoSuspendVenue'`. _Avoid_: an `autoSuspendedAt` field (the disabled button removes the need); a grace window on trials (it makes the stated end date not the end date); a cutoff that fires without an audit row.

### Subscription notice
**ID · EN** — Langganan · Subscription; berakhir · ending; kedaluwarsa · lapsed. The banner **names a date**, so it localises under ADR-0084's date rule; the price beside it does not.

The venue-side counterpart to [[Venue billing]] — a shell banner on the [[Main Device|host]] telling the venue's own admin that its subscription is **ending** or **lapsed**, in the same slot and with the same warn→urgent escalation as the [[Offline grace period]] countdown beside it. Derived from the live `venues/{vid}` snapshot the eligibility listener **already receives and used to discard**, so it costs no extra read and Firestore's cache serves it offline.

**It names the date the venue stops** — the end date for a trial, end + 7 for a partner. ADR-0074 forbade this on the grounds that *"copy implying imminent shutdown would be a lie the code does not tell"*; since [[Subscription cutoff]] the code tells it, so the banner states it as fact. A venue cut off without ever being told the date would be ADR-0074's own failure case, reintroduced from the other side.

**Gated on `editSettings`**, which the grace banner deliberately is not: reconnecting the wifi is operational and any staff member can act on it, while "the restaurant has not paid" read by a waiter mid-shift is a different message with no action attached. Tapping opens WhatsApp to the developer with the venue's **name and id** prefilled — names repeat across the fleet, the id is what makes the venue findable in one tap on the other end. There is no in-app payment; this is the whole of the renewal path. _Avoid_: showing it to the floor; wording it as a shutdown warning; a second definition of "ending" that disagrees with the console's.

### Release gate (Gerbang versi)
**ID · EN** — Pembaruan · Update; Perbarui · Update (the button); Versi · Version; Pembaruan wajib · Mandatory update.

Three semver strings — `min`, `recommended`, `latest` — in **one global Firestore doc**, `config/release_gate`, describing what the fleet is allowed to be running. Not per-venue: the gate says which builds of SatSet are acceptable anywhere, and a venue-by-venue floor would be a rollout schedule, which is a different thing nobody asked for.

Written by **Codemagic, from the release tag** — `/push-deploy`'s `-breaking` / `-recommended` suffix, which CI already parses off `CM_TAG` and used to discard. The write cascades so `min ≤ recommended ≤ latest` can never be violated, and it happens **after the GitHub Release publishes**, never before: a floor that rises while the APK is still building points every device at a download that does not exist. The [[Fleet console]] can edit the same doc, and that override is the only correction that reaches a venue nobody can drive to.

**Only the [[Main Device|host]] reads the cloud.** It caches the gate off the `config/release_gate` listener, folds it into the unauthenticated `/healthz` payload, and pushes a `releaseGate` WS event when it changes; clients never touch Firebase (see [[Admin session (Firebase-gated)]]). A paired client persists the last gate it saw, so it stays gated with the host down. An unpaired client has no gate and is never blocked.

**An unknown gate never blocks.** No doc, no network, an unparseable version — every one of them fails open. Comparison is on `versionName` alone; the build number is invisible to the gate, because CI is free to move it and the tag is not.

_Avoid_: a per-venue gate; a gate written before the artefact exists; blocking on a version the device could not read; reading the build number.

### Pembaruan wajib (Mandatory update)
**ID · EN** — Pembaruan wajib · Mandatory update; "Versi ini tidak didukung lagi" · "This version is no longer supported"; "Minta admin memperbarui perangkat ini" · "Ask an admin to update this device".

A **policy floor, not a wire-compatibility floor**. `min` is a decree — a bad build, wrong tax arithmetic, a corruption — and it is enforced in-app on each device against that device's own installed version. It is not a statement about whether an old client can still talk to a new host; the LAN protocol is unaffected and the host never rejects a client for its version.

Below `min` the device shows a **non-dismissible block, immediately, wherever the user is** — not at the next cold launch. This is deliberately harsher than the [[Offline grace period]] lock, which "only bites on restart": that guard protects against a network the venue can fix, this one against a build the venue must stop running. The cost is real and accepted — a wrong `-breaking` tag darkens the fleet mid-service, and the console override is the mitigation, not a cure. **The block never stops the embedded server**, or a client would report the host offline instead of telling its holder to fetch an admin.

Between `recommended` and `latest` the [[Main Device]] alone carries a **persistent shell banner** — no sheet, no snooze, no release notes, just the two version numbers. Nothing else is nagged: a waiter cannot install and telling them is noise on the one screen that must stay quiet under chaos.

**Only the [[Main Device]] ever installs.** It downloads the signed APK from the GitHub Release the website already links to and hands it to Android's package installer. Every other device — staff client and admin-client alike — is told to fetch an admin, because SatSet is distributed by hand and updating a device means someone holding it. _Avoid_: a staff-installable update; a block that also tears down the server; a nag on a device that cannot act on it; release notes written for developers on a screen read by a restaurant owner.

### Shift
**ID · EN** — Shift · Shift; Ringkasan shift · Shift summary; Saya · Me. Exits: "Keluar" · "Sign out"; "Akhiri shift & keluar" · "End shift & sign out". The two exits must stay as visibly different in English as in Indonesian — one keeps the clock running, the other stops it.

One staff member's stretch of work — **not** a fixed roster block, and **not** the same thing as a login. It **outlives the [[Pairing vs staff session|staff session]] that opened it**: signing out with **"Keluar"** leaves the shift running, so the next PIN sign-in *resumes* it, on that handset or a different one. Handsets are shared, so this is what lets a waiter hand a device over or swap to another without losing their clock.

Exactly two things end a shift: the explicit **"Akhiri shift & keluar"**, and the **business-day boundary** (`businessDayStartHour`, default 04:00 — the same rollover reports bucket "today" on). The boundary is not a nicety: without it one forgotten sign-out leaks the shift forever and tomorrow's first login inherits a 14-hour clock. Working past midnight therefore stays *one* shift, because 23:00 and 02:00 sit in the same business day.

**Server-authoritative** — `Users.shiftStartedAt`, stamped by the host, because surviving a device change is the whole point and device-local storage cannot. Elapsed time is `now − shiftStartedAt`. A client keeps its own `loginAt` only as an offline fallback for a host that has no opinion.

The **Ringkasan shift** ("Saya" tab) is a **live snapshot** of what its owner is holding *right now* — outstanding tickets, seated [[Cover|covers]], tables in hand — plus their own [[Void (item)|void]] [[Audit]] rows for the shift. Closing a table correctly makes those numbers go **down**; that is intended, the screen answers "what is on my plate", not "what did I do tonight". It deliberately carries **no sales figure and no per-hour rate**: both need closed [[Close (table) / Table session|TableSessions]], which clients never receive. See [ADR-0065](docs/adr/0065-a-shift-outlives-the-staff-session.md).

_Avoid_: treating a shift as a scheduled shift-pattern, or as venue-wide (it is per-account); equating sign-out with shift end (only one of the two exits ends it); reading the Saya tab's counts as a shift total.

### Pairing vs staff session
**Three** independent lifetimes, not two. **Pairing** is the LAN connection to a [[Main Device]] (host URL + pinned TLS fingerprint, the `ApiConfig`), established once by picking the server off mDNS discovery — the client pins the fingerprint advertised in the TXT record and auto-claims over it — and held in secure storage. A **staff session** is one operator's authenticated bearer (the local JWT). A **[[Shift]]** is that operator's stretch of work, and it is **server-side state that outlives the session** — the newest of the three distinctions and the easiest to get wrong.

**Staff sign-out drops only the session** (revokes the token, clears `AuthState`) and **keeps the pairing** — "the connection to the server is still alive" — so the next operator can PIN in without re-pairing. Whether it also ends the shift depends on *which* exit was used: **"Keluar"** keeps the shift open for the next sign-in to resume, **"Akhiri shift & keluar"** closes it. Contrast the [[Local server lifecycle|admin/Server side]], where admin logout *kills the server* — which is why a Server-mode admin is offered only the shift-ending exit.

_Avoid_: conflating sign-out with un-pairing; assuming a live pairing implies a live session (the data screens still need a session to load); assuming sign-out ends the shift.

### Terputus (client disconnected)
**ID · EN** — Terputus · Disconnected. The same word [[Local server lifecycle]] already uses ("staff akan terputus"), deliberately reused rather than minting "Offline".

A client device that cannot currently reach its [[Main Device]] — the LAN dropped, the waiter walked into a dead zone, the host restarted. Distinct from the [[Offline grace period (masa tenggang offline)|masa tenggang offline]], which is the *host's* loss of **Firebase**; these are two different axes and a device can be in either without the other. _Avoid_: "Offline mode" as a mode the user enters — there is no switch, only a condition; treating a closed WebSocket as proof the host is gone (it is the badge signal, not the authority).

### Antrean kirim (send queue)
**ID · EN** — Antrean kirim · Send queue.

The device-local, first-in-first-out list of **intents** a [[Terputus (client disconnected)|terputus]] handset has captured but not yet delivered — "seat this table", "send these lines" — each carrying the idempotency key it will be replayed under. Belongs to the **device**, not the session, so it survives a handset handover; each entry keeps the [[Orderer (line author)|author]] who captured it. _Avoid_: "outbox", "sinkron", "rekonsiliasi" — Latinate words a waiter mid-rush does not parse; calling the queue's contents "orders" (the venue has no order until the host accepts one).

### Pesanan tertunda (pending order)
**ID · EN** — Pesanan tertunda · Pending order.

A line captured into the [[Antrean kirim]] and not yet accepted by the host. It is **provisional in every respect** — no [[KDS / Antrian Persiapan|KDS]] has seen it, no stock has moved, no [[Visit]] owns it, and it may still be refused. The waiter may edit or void their own tertunda line; once delivered it is an ordinary sent line and [[Void (item)|the freeze rule]] applies. _Avoid_: rendering it as "Terkirim"; counting it in a [[Bill (tab)|bill]] the [[Cashier|kasir]] can settle.

### Hasil pengiriman (send result)
**ID · EN** — Hasil pengiriman · Send result. The failure list within it: Gagal terkirim · Failed to send.

What the host answered when the [[Antrean kirim]] drained: accepted, refused (out of stock, the [[Visit]] closed, the table changed guests), or expired past the business-day boundary. A clean drain passes silently; anything refused is shown and **acknowledged**, then survives on the [[Shift|Saya]] tab until resolved. _Avoid_: silently dropping a refusal, or retrying one automatically — a line the host refused is a fact the waiter must act on, not a transport error.

### Diambil vs terkirim (capture time vs send time)
**ID · EN** — Diambil · Captured; Terkirim · Sent.

Two moments a [[Pesanan tertunda]] carries. **Terkirim** is when the host accepted the line — what the [[KDS / Antrian Persiapan|KDS]], the [[Order elapsed time|waktu berjalan]] and every [[Audio alert]] threshold measure from, because the kitchen cannot be late for food it had not received. **Diambil** is when the waiter keyed it at the table, kept for the [[Audit]] trail and for telling a guest why their food is behind. _Avoid_: aging a replayed line from diambil (it lands on the board already screaming); presenting diambil as the ordering time in [[Reports|laporan]], which bucket on terkirim.

### Generic seed (sample data)
**ID · EN** — Contoh data · Sample data. The seeded **content itself** — zone names (Dalam / Luar / Teras / VIP), the ~42 menu items, bahan, staff names — is venue content and ships Indonesian in both locales (ADR-0083). Only the prompt and progress copy around it translate.

The optional starter dataset a fresh [[Main Device]] offers to load, so a new venue is not bootstrapped against an empty DB — and so its [[Reports|laporan]], [[Venue audit log|catatan audit]] and stock history are readable on day one rather than blank. **One dataset, one action**: the reference half plus a fabricated month, never separately (ADR-0073 merged the demo seed into it).

The reference half is a generic restaurant: **4 zones** (Dalam / Luar / Teras / VIP) with **20 tables** between them, the generic menu (categories + ~42 items + [[Menu tag (allergen / diet)|tags]]), the **inventory** — [[Bahan (Ingredient)|bahan]] with opening stock and [[Resep (Recipe)|resep]] for most of the menu — and **2 staff**, one [[Waiter]] and one Kitchen, with their roles + capabilities. It does **not** seed a PIN admin (admin comes only from Firebase — see below).

The fabricated half is **a month of settled service**: roughly 1500 bills across 30 days, written through the production order path rather than inserted directly, so recipe resolution, stock deduction and per-ticket consumption are exercised for real. Its contents are **organic, not uniform** — a hand-authored table of item popularity, category attach rates, an hourly curve with lunch and dinner humps, and party sizes that drive line count. It writes **both halves of the audit trail**: the service rows a manager looks for (fire, void, discount, payment, bill close) and the `manageStaff`-gated admin rows (staff and role changes, manual habis toggles), because neither comes free — the seed bypasses every route handler, and every audit writer lives in one. It seeds **no live snapshot**: every table lands kosong and the venue runs on real time.

Its safety is two rules. It **hard-refuses when the venue has traded** — any live [[Ticket]] row, or any archived [[Table close (detach)|sesi meja]]. Both halves matter: closing a bill hard-deletes its tickets into history, so a venue with a real trading month and no open orders holds no tickets at all. And every fabricated row is **tagged** with an id prefix, so [[Seed clear (Hapus contoh data)]] deletes by tag and never by table — a real order taken on a seeded venue survives.

Two rules govern the inventory half (see [docs/adr/0042-generic-seed-covers-inventory-and-recipes.md](docs/adr/0042-generic-seed-covers-inventory-and-recipes.md)). Opening stock arrives as one **`receive` [[Mutasi stok (Stock movement)|mutasi]] per bahan**, never as a bare balance, so the ledger sums to the balance from the first row. And bahan are **insert-if-absent**: `stockOnHand` is the one seeded number that becomes real the moment the venue trades, so a re-seed replaces resep but never rewrites a count. The cocktails and wines are seeded **without a resep** on purpose — an item with no recipe consumes nothing and is never auto-[[Habis / Sold out (menu item out of stock)|habis]].

Distinct from **infra seed** — the shared admin **role** row and the `voidItem` backfill, which always seed silently and unconditionally so a Firebase-provisioned admin uid can resolve its role and operate. See [docs/adr/0073-the-generic-seed-fabricates-a-month.md](docs/adr/0073-the-generic-seed-fabricates-a-month.md). _Avoid_: auto-loading it without asking; calling it "the demo" (there is no separate demo dataset); treating its month of history as report data anyone should trust; re-seeding over a venue's real stock counts.

### Seed prompt (mandatory first run)
**ID · EN** — Muat contoh data · Load sample data; Lewati · Skip; Hapus & muat ulang · Clear & reload. Progress "hari 12/30" · "day 12/30" — an ICU-placeholder ARB entry, not interpolation.

The **blocking dialog** an empty venue meets on the Venue Hub: *Muat contoh data* or *Lewati*, and nothing else — no close button, no tap-outside, no back button. The admin answers once. The answer is stored **server-side and venue-wide**, so skipping on the tablet also skips on the phone; "never ask again" is a property of the venue, not of the device that answered.

It is answered on **completion or on skip, never on tap**. A job takes minutes and cannot be resumed, so a host that is backgrounded or reclaimed mid-run leaves the question genuinely unanswered: the dialog returns on the next boot, sees the incomplete marker, and offers **Hapus & muat ulang**. Progress lives inside the same dialog — a bar, `hari 12/30`, and the instruction to keep the app open — because leaving is what kills the job.

Because skipping is permanent, **Admin → Sistem carries the same dialog as a permanent action**. Without it one tap would put the sample data out of reach forever. _Avoid_: an escapable prompt; writing the answer when the job starts; a Venue Hub banner carrying progress in parallel; expecting a client-mode device to see it (the hub is server mode — seeding is a host act).

### Seed clear (Hapus contoh data)
**ID · EN** — Hapus contoh data · Clear sample data. _Not_ "Reset" or "Wipe" in either language — it deletes the fabricated month only, and the menu stays standing.

Deleting the fabricated month and **nothing else**: the invented bills, tickets, sesi meja, receipts, payments, stock movements and audit rows go; zones, tables, menu, staff and bahan stay standing. What an owner actually wants — keep the menu, lose the fake sales — and a zone or an item they do not want, they delete by hand.

Deletes strictly **by tag**, never by truncating a table, so an order the venue took for real after seeding survives it. Stock balances are recomputed from the surviving ledger rather than patched, because a balance that no longer equals the sum of its movements is the exact breakage ADR-0041 exists to prevent. A cleared venue passes the guard again and can be re-seeded. _Avoid_: using "clear" to mean wiping the DB; expecting it to remove the zones and menu too.

### Struk (cetak struk meja)
**ID · EN** — Cetak struk meja · Print order slip. The document is an **order slip**, never a "receipt" — it carries no money. "verifikasi pesanan" · "check your order".

A printed **guest order-confirmation slip** for a live [[Table]] — lists that table's sent, non-[[Void (item)|voided]] lines (item, qty, [[Modifier group (add-on)|modifiers]], [[Guest note / Item note|item notes]]) under the venue header/footer, headed by the table label, [[Pax]], time, and — when set — the **guest name** and the table-level [[Guest note / Item note|guest note]] ("Catatan"), with **no prices, tax, service, or total**. Money is settled elsewhere; the struk only lets the guest verify what was ordered ("verifikasi pesanan"). It is a confirmation, not a fulfillment tracker — it carries no per-line sent/ready/served state, no course grouping, and no internal table fields (waiter, lock, status). Printed on demand from the table-detail **"Cetak struk meja"** action, the [[Close (table) / Table session|Tutup meja]] flow, and the order-sent screen — all through one shared print path. _Avoid_: treating the struk as the guest's **bill** (it carries no money — that is a separate, not-yet-built document); printing a table with no sent lines (nothing to confirm).

### Tagihan / Struk pembayaran (the money document)
**ID · EN** — Tagihan · Bill (pre-payment); Struk pembayaran · Receipt (post-payment). The pair must stay as distinct in English as in Indonesian, and neither may collide with the [[Struk (cetak struk meja)|order slip]] — three documents, three words, both languages.

The guest's **money** document, deliberately **named apart from the [[Struk (cetak struk meja)|Struk]]** (which is a no-money order-confirmation slip — do not overload it). This is the "separate, not-yet-built document" the Struk glossary referred to. One renderer template, two **states** — and the state is **not chosen by the cashier** but read off the document: no [[Payment (manual confirmation)|payment]] recorded yet ⇒ **Tagihan**, any payment recorded ⇒ **Struk pembayaran**.

- **Tagihan** (pre-payment bill) — venue header, table + receipt/guest label, **itemized lines with prices**, subtotal, **service** and **tax** (see [[Tax & service charge]]), and **total**. No payment block. Lets the guest verify the total before paying.
- **Struk pembayaran** (post-payment receipt) — the Tagihan **plus** the payment method(s), amount tendered, and change (and any remaining **sisa** if part-paid). Printed after settling.

Every printed line — on whole-bill, itemized, and the even-split reference list — also carries the line's chosen [[Modifier group (add-on)|modifiers]] and its [[Guest note / Item note|item note]] ("Instruksi khusus"), so the money doc lets the guest verify *exactly what was ordered* (not just totals), matching the [[Struk (cetak struk meja)|Struk]]. Especially load-bearing for [[Bawa pulang (Takeaway)|takeaway]], whose only printout is this money doc.

Prints at **two granularities**: the **whole-bill** document (the table's entire undivided tab) and a **per-receipt** document (one [[Split bill]] receipt). An **itemized** receipt lists only *its own* assigned lines with prices; an **even** receipt shows its flat **share** amount plus a compact, price-less **reference list** of the whole table's items (it owns no specific items). Reuses the existing two-scope [[Printer (scope × transport)|printer]] picker, shared print path, and transport rules (ADR-0020/0022) — only the renderer template is new. _Avoid_: overloading the word "Struk" for the money document; handing one combined whole-bill slip to guests who asked for **separate** receipts instead of printing one per receipt.

### Venue branding (receipt branding block)
**ID · EN** — Branding struk · Receipt branding; Dikelola pengelola · Managed by operator. The venue's own header, tagline, footer and thank-you text are **venue-authored content** and never translated — only the editor's labels are.

The single, **venue-wide** identity block stamped on every document — the [[Struk (cetak struk meja)|Struk]], the [[Tagihan / Struk pembayaran|money docs]], and (a trimmed form) the [[Export (report / order history / staff / accounting)|PDF exports]]. There is **one** block, not a per-document one; "edit the receipt" means edit this shared block once and it shows everywhere. Composed of:

- **Logo** — an optional image. Stored as a JPEG blob on the venue-settings row and carried by a monotonic `logoRev`, **never** inlined in the settings JSON snapshot; fetched/cache-busted by `logoRev` exactly like a [[Menu photo]] (ADR-0014). Printed on thermal as a centred, monochrome-dithered raster fit to the 384-dot (58mm) width; embedded full-colour on PDFs. Gallery-picked (free aspect, auto-downscaled); clearable.
- **Venue name + address** — **read-only**, mirrored from the cloud [[Venue (cloud)|venue]] (ADR-0018). Editing "the receipt" does **not** re-open these; the branding editor shows them locked ("Dikelola pengelola").
- **Contact** — the locally-editable `phone`.
- **Header text, tagline, social line** — free-text branding lines under the name.
- **Footer text + thank-you** — closing lines; the thank-you (was a hardcoded "Terima kasih") is now its own editable field.
- **Footer QR** — one free-form URL + caption (e.g. Google review / IG). Printed on the **money docs only** — not the order-confirmation Struk, not PDFs.

Edited on the [[Venue (cloud)|venue]] identity screen ("Branding struk" card) with a **live full-sample-receipt preview** — a Flutter widget mimicking the 58mm thermal slip (it is a mock; ESC/POS bytes are not renderable). PDF exports get only the **letterhead subset** (logo + name + address + contact next to the report title) — never the customer-facing footer/tagline/thank-you/QR. _Avoid_: making this a per-document override (it is one shared block); putting logo bytes in the settings JSON; treating the QR/thank-you as appropriate for an accounting PDF.

### Printer (scope × transport)
**ID · EN** — Printer · Printer; Printer venue · Venue printer; Printer perangkat · Device printer; Offline · Offline.

A receipt printer the app can send a [[Struk (cetak struk meja)|struk]] to. Described by two independent traits — **scope** (who transmits) and **[[Printer transport|transport]]** (the physical link) — but only three combinations are valid:

| | wifi (network ESC/POS) | bluetooth (Classic SPP) |
|---|---|---|
| **venue** | ✅ shared, Main Device sends | ❌ impossible — server can't reach a phone's paired radio |
| **device** | ✅ this phone sends | ✅ this phone sends |

- **Venue printer** — always **wifi**. Registered to the [[Venue (cloud)|venue]], stored once in the [[Main Device]]'s DB, **shared by every device**. The [[Main Device]] **renders and sends** the bytes; a client only *triggers* the print and never talks to the printer directly. Any staff member may **add or test** one; only an **admin may delete** one (shared config).
- **Device printer** — **private to one device**, stored locally on it; that device renders and sends directly. May be **wifi** (host:port) or **bluetooth** (a paired MAC). No server involvement, no shared-config authz. **Bluetooth is device-scope only** (a BT printer is bonded to one phone's radio).

The print picker **merges both scopes** and runs the **same shared struk renderer**, so output is identical regardless of who transmits. _Avoid_: a device printer leaking into the shared venue list; a **venue+bluetooth** printer (impossible — reject in the add flow).

### Printer transport
**ID · EN** — wifi · Wi-Fi; bluetooth · Bluetooth. Both are proper nouns and stay as-is; only the surrounding copy translates.

The physical link to a [[Printer (scope × transport)|printer]], shown on each picker row by icon + address so staff can tell them apart at a glance:

- **wifi** — network ESC/POS, raw-9100 on the LAN. Address = `host:port`. Discovered by **mDNS**. Reachable by the [[Main Device]] (venue) or any phone on the LAN (device).
- **bluetooth** — Bluetooth **Classic (RFCOMM/SPP)**, the radio cheap thermal pocket printers speak. Address = a **MAC**. **Must be paired in Android settings first**; the app only enumerates *bonded* devices (no air-scan), so an unpaired printer never appears until the user pairs it in system settings.

### Printer online (reachability heartbeat)
Whether a [[Printer (scope × transport)|printer]] is reachable **right now**. The print picker lists **only online printers** as tappable; offline ones drop to a greyed "Offline" section, and a **disabled** venue printer is hidden entirely (offline ≠ disabled). Reachability is proven by a **heartbeat**, not assumed from registration:

- **Venue (wifi)** — the [[Main Device]] probes each enabled venue printer (TCP connect, no bytes sent) on a periodic tick and broadcasts the result; clients read it. A printer counts online if it answered within the freshness window.
- **Device (wifi/bluetooth)** — the owning phone probes its own printers (TCP connect for wifi, the BT plugin's connection check for bluetooth); this never crosses devices.

A probe is **connect-only** — it never spews a struk. _Avoid_: inferring "online" from a manual test print alone (the prior behaviour — `lastSeenAt` only ever moved on test, so the dot lied); air-scanning for unpaired BT printers.

### Bill (tab)
**ID · EN** — Tagihan · Bill. Money badges: Lunas · Settled; Sebagian · Part-paid; sisa tagihan · outstanding; total dibayar · total paid.

The settleable money document for **one [[Visit]]** — the whole open tab of a party, across everyone seated together. It belongs to the **visit, not the table row**, so it **outlives the table attachment**: a [[Table close (detach)|detached]] visit's bill stays open and settleable on the [[Cashier]] until [[Bill close (Tutup tagihan)|bill close]]. The unit the [[Cashier]] collects on. Distinct from a [[Order elapsed time|Ticket]] (one line), a [[Batch (kitchen order)|Batch]] (one send), and a [[Struk (cetak struk meja)|Struk]] (a no-money order-confirmation slip). A Bill's total is computed from the table's sent, non-[[Void (item)|voided]] lines (line prices → subtotal) plus venue [[Tax & service charge|tax and service charge]]. One table visit has exactly one Bill; splitting produces multiple **receipts** off that one Bill (see [[Split bill]]), not multiple Bills. This is the document CONTEXT formerly called "a separate, not-yet-built document". _Avoid_: treating a Bill as per-ticket or per-batch; conflating it with the Struk (which carries no money).

### Estimasi (cart estimate)
**ID · EN** — Estimasi · Estimate. _Not_ "Total" — the word has to keep promising less than a [[Bill (tab)|bill]] does, in both languages.

The provisional total shown to the [[Waiter]] **during order-taking** — on the menu cart pane and the review screen — computed over the **cart** (not-yet-sent lines) rather than a [[Bill (tab)]]'s sent lines. Uses the **same** [[Tax & service charge]] math as settlement (service-then-tax, the shared `computeBreakdown`), so the **rate math** the waiter quotes agrees to the rupiah with what the [[Cashier]] later applies — no duplicated or drifting rates. It does **not** promise the same *total*: a [[Diskon (discount)]] is a settlement-stage reduction the waiter cannot see, so a discounted bill settles **lower** than the Estimasi quoted. That direction of surprise is intended. It is **informational only** — no money binds until [[Settlement (two-phase, precedes Close)|settlement]], and the cart can still change before sending. _Avoid_: calling the cart estimate a Bill; computing it with ad-hoc rates that drift from the venue [[Tax & service charge]] settings; re-deriving or previewing a discount in the cart.

### Settlement (recording payment)
**ID · EN** — Penyelesaian · Settlement; Metode · Method; Bagi untuk · Split between. _Not_ "Checkout" — that is a consumer-storefront word and this is a till.

The [[Cashier]] recording [[Payment (manual confirmation)|payments]] against a [[Bill (tab)]]. One of the threads of the [[Visit end (two independent axes)]]: settlement (money in) builds toward **[[Bill close (Tutup tagihan)|bill close]]** (the cashier locks + snapshots), which is **independent** of the waiter's **[[Table close (detach)]]** (freeing the floor table). Settlement can run while the table is **still occupied** (a guest pays, then lingers) **and after the table is detached** (a [[Walkout (tak tertagih)|walkout]] paid later). A [[Split bill]] settles each guest's receipt independently. Settlement does **not** require tickets terminal (a guest may pay while the last drink is still coming). Settlement is also the **only** stage where a [[Diskon (discount)]] may be applied. _Avoid_: merging pay-and-free into one act; requiring all food served before money can be taken.

Settlement is **orthogonal to the kitchen-driven table status** — a table can be fully paid yet still **occupied**, or freed while still unpaid. No payment-bearing table status is added; the table carries a **money badge** (Lunas / Sebagian / outstanding) while attached, and a freed-but-unpaid visit surfaces on the cashier list flagged. `VenueTable` status flips to `available` at [[Table close (detach)]], **regardless** of payment. Settlement is **lock-free** — taking money never requires or respects the [[Table lock]] (a [[Waiter]] editing lines and a [[Cashier]] taking money co-occur); only [[Table close (detach)]] respects the lock. _Avoid_: a `settling`/`paid` table status (two axes in one field); making the cashier wait on a waiter's table lock.

### Cashier
**ID · EN** — Kasir · Cashier. Segments: Perlu ditagih · To collect; Lunas · Settled; Semua · All. "minta bill" · "bill requested".

The staff role that operates the **venue-wide** money screen — listing every **open [[Visit]]** with an unsettled or unclosed [[Bill (tab)]], so money is collected from one place. The list spans both **attached** visits (table still occupied, ≥1 sent line) **and detached** visits ([[Table close (detach)|table already freed]] by a waiter but bill not yet closed) — the detached-unpaid ones carry a **visual flag** ("meja sudah ditutup, tagihan belum lunas") and keep their frozen table label + free time. A **minta bill** ("guest requested the bill") highlight **sorts/raises** a visit but **does not gate** — every open visit is listed. The screen is one list under three segments — **Perlu ditagih** (open and part-paid), **Lunas** (already closed; this is where [[Past bills]] is read, defaulting to today and extendable to the 7-day window), and **Semua** — so "already paid" and "history" are one place rather than two. _Avoid_: gating the list on all-food-terminal; treating the screen as per-ticket; dropping a detached visit off the list before its bill is closed; a separate Riwayat tab (folded into **Lunas**).

Gated by the **`settleBill`** capability (record payments, create/split receipts, **reopen**, and **[[Bill close (Tutup tagihan)|bill close]]** — both Lunas and tak tertagih); a seeded **Kasir** role grants `settleBill` + `openDrawer`, deliberately **without** `applyDiscount` (a cashier reaches a [[Diskon (discount)]] through manager step-up unless the owner grants the capability outright), plus `refund` if trusted — [[Payment (manual confirmation)|refunds]] and the **tak tertagih** write-off keep the manager-approved `refund`/comp authority, not auto-granted). The screen runs in **client mode** like other staff screens and is **not** Firebase-gated. Lives at shell route **`/kasir`** ("Kasir"). The cashier's end act is **[[Bill close (Tutup tagihan)]]** — *not* "Tutup meja"; freeing the floor table stays the waiter-side **[[Table close (detach)]]**. _Avoid_: giving the cashier a "Tutup meja" (table-freeing) button; merging bill close and table close into one capability; auto-granting refund/write-off to every cashier.

### Split bill
**ID · EN** — Bagi tagihan · Split bill. Modes: Penuh (Bayar penuh) · Pay in full; Per item · By item; Bagi rata · Split evenly.

Dividing one [[Bill (tab)]] into multiple **receipts**, each settled independently, so guests at one table can pay separately. The [[Cashier]] picks a **mode per payment**, not per bill — a table where two friends go halves and a third pays for his own steak is one bill holding both kinds of receipt. The three modes:

- **Penuh** — one receipt for the whole remainder. The degenerate, undivided case.
- **Per item** — each [[Order elapsed time|line]] is assigned to a **receipt**; that receipt totals its own lines plus a proportional share of [[Tax & service charge]]. "Pay for what you ordered."
- **Bagi rata** — the remainder is divided into N shares, each an [[Amount receipt]]; no line assignment.

Mode is therefore a **receipt-creation strategy**, not a property the bill remembers. See [docs/adr/0067-billing-mode-is-per-payment.md](docs/adr/0067-billing-mode-is-per-payment.md). One `Receipt` entity covers all three: it either **owns a set of line items** or is an [[Amount receipt]] carrying only a money claim. Because an amount receipt owns no lines, a **line [[Diskon (discount)]] is itemized-only**. _Avoid_: modelling a split as multiple [[Bill (tab)|Bills]] (it is one Bill, many receipts); per-mode receipt entities; per-item pricing inside an even share (which has already abandoned tracking who ordered what); speaking of "the bill's mode".

**Assignment is qty-level** — a `qty: 3` line can send 2 units to one receipt and 1 to another (integer per-unit math; no fractional ownership). A genuinely shared single (qty-1) dish lands whole on one receipt or goes to an even split. At the till the common gesture takes the **whole line**; the per-unit split is a second, deliberate act, because a line divided between two guests is the rare case and should not tax the frequent one. **Settlement is incremental** — a receipt may be paid as soon as *its* lines are assigned, even while sibling lines are still unassigned (covers "one guest pays and leaves early"). A Bill is **fully settled** only when **every line is assigned to some receipt AND every receipt is paid**; only then may the table [[Close (table) / Table session|Close]]. _Avoid_: fractional line ownership; blocking a receipt's payment on unrelated unassigned lines.

### Amount receipt
**ID · EN** — Bagian · Part (`Bagian 1/3` · `Part 1/3`). Under ADR-0085 this is composed from ARB at read time, not stored as a sentence.

A **receipt that owns no lines** and instead holds a frozen **money claim** on the part of a [[Bill (tab)]] no itemized receipt has claimed. It is what an even share *is*: "one third of whatever is left", fixed at the moment it is minted so later edits to the bill cannot silently move what a guest was quoted. The remainder it draws from is the bill total less every itemized receipt's total and every other amount receipt's claim, which is what lets a single bill carry both kinds at once (see [[Split bill]]). A bill is **fully assigned** when every unit is owned by an itemized receipt **or** covered by an amount receipt — the predicate that in turn decides whether the bill [[Bill close (Tutup tagihan)|closes itself]]. See [docs/adr/0068-an-even-receipt-is-an-amount-receipt.md](docs/adr/0068-an-even-receipt-is-an-amount-receipt.md).

Shares are rounded so a guest is handed a **note-friendly figure**: each head rounds up to the nearest Rp 100 and the resulting surplus is spread back across the later heads, so nobody is asked for coins and nobody ends up owing nothing. _Avoid_: giving an amount receipt a [[Receipt letter]] or any per-guest identity (it has none — see there); attaching a line [[Diskon (discount)]] to one; recomputing its claim after it is minted.

### Receipt letter
**ID · EN** — Tamu A · Guest A. The even share's `Bagian 1/3` · `Part 1/3` — an ARB template under ADR-0085, not a stored string.

The name an **itemized** [[Split bill]] receipt is known by at the till — a capital letter, spoken as **"Tamu A"**. It is a **property of the receipt, not of its position in a list**: it is assigned once (the lowest letter not already in use) and never changes, so deleting a receipt leaves a **gap** (A, C) rather than renaming the guest who comes after. This matters because the letter is **printed on the guest's slip** — a scheme that renumbers would put one name on the screen and another in the guest's hand. A letter also carries a **colour**, but the letter is the identity and the colour only the scan aid: monochrome paper and a colour-blind [[Cashier]] must both still work. _Avoid_: deriving the letter from list order; closing the gap after a delete; treating the colour as the identity.

The letter is what a receipt is *called*; what a receipt **is** to a cashier is **the items on it** — "the guest who had the nasi goreng". Only an **even** share has neither, and honestly so: it owns no lines, so `Bagian 1/3` and `Bagian 2/3` are genuinely interchangeable and carry **no letter**. The undivided whole-bill case ("Bayar penuh") likewise has no sibling to be told apart from, and carries none either. _Avoid_: implying a per-guest identity for an even share (the mode has already abandoned tracking who ordered what — the only real question left is *how many shares are still owing*).

### Tax & service charge
**ID · EN** — Pajak · Tax; Service · Service charge; Subtotal · Subtotal; Total · Total. Amounts stay `Rp 14.500` in both languages (ADR-0084).

The two venue-level add-ons stacked onto a [[Bill (tab)]] at [[Settlement (two-phase, precedes Close)|settlement]], each gated by its own toggle in `VenueSettings` (`taxEnabled`/`taxRateBps`, `serviceEnabled`/`serviceMode`+`serviceRateBps`/`serviceFixedAmount`). **Stacking order is service-then-tax** (ID PB1 convention): service charge applies to the line **subtotal**, then tax applies to **(subtotal + service)**. e.g. 100k → +5% service = 105k → +11% tax = 116.55k.

A [[Diskon (discount)]] slots into that stack under a **single** venue flag, `taxAfterDiscount` (default **true**). When true the discount reduces the base *both* add-ons compute from (`base = subtotal − discount`, the DPP-correct reading); when false both are computed on the gross subtotal and the discount comes off the grand total last. "Before tax" therefore necessarily means "before service" — service is upstream of tax, so a mode with the discount wedged *between* them is not offered. A **line** discount is always pre-tax regardless of the flag, because it *is* a price change and so is part of how the subtotal is derived; the flag governs whole-order discounts only. See [ADR-0038](docs/adr/0038-discount-tax-stacking-order.md).

Before this feature these toggles existed but were **never applied** — [[Close (table) / Table session|close]] stored `netTotal = subtotal`. Settlement is where they finally bind. In a [[Split bill]] each **receipt** computes service+tax on its **own** assigned-line subtotal, and the small integer **rounding remainder is pushed onto the largest receipt** so receipts always sum to the bill total exactly (no money invented or lost). The settled `TableSession` now persists `serviceAmount` and `taxAmount`, and **`netTotal` is redefined** to the *actually settled* total (`subtotal − void + service + tax`) rather than the old `netTotal == subtotal`. _Avoid_: tax-then-service order; applying tax/service per-line instead of per-receipt-subtotal; reading historical `netTotal` as if it still equals subtotal.

`netTotal` is now **frozen** at that formula permanently and never learns about discounts — the money actually collected is the separate **`settledTotal`** (`netTotal − discount`), which every report and export reads. `netTotal` answers "what did we ring up net of voids"; `settledTotal` answers "what did we collect". See [ADR-0039](docs/adr/0039-settled-total-over-redefining-net-total.md). _Avoid_: reading `netTotal` as revenue on a discounted bill; redefining `netTotal` a third time.

### Diskon (discount)
**ID · EN** — Diskon · Discount. Scopes: bill · Bill; order · Receipt; line · Line. The printed row keeps the **preset's own name** (`Diskon Member 10%`) — a snapshotted venue string, never translated.

A deliberate, authorized reduction of what a guest owes, applied by the [[Cashier]] at [[Settlement (recording payment)|settlement]] and **never** during order-taking. Three targets, one mechanism: a **bill** discount against the whole [[Bill (tab)]], a **whole-order** discount against one receipt, or a **line** discount against one bill line. The bill scope is what a table-wide promo actually is — it reduces the bill subtotal before any receipt claims anything, then distributes across receipts the way an order discount already does, so "20% off the table, split three ways" is one act rather than one per payer. See [docs/adr/0070-discounts-have-a-bill-level-scope.md](docs/adr/0070-discounts-have-a-bill-level-scope.md). A bill discount additionally carries a **[[Sumber diskon (discount source)|source]]** (`manual` | `member` | `redeem`), and the "one per visit" rule is **one per source** (ADR-0094) — a cashier's promo, a [[Pelanggan (member)|member]] discount and a [[Tukar poin (redeem)|redemption]] each hold their own slot and stack by design. Always drawn from a [[Preset diskon]] — cashiers pick, they do not type a percentage — and the applied row **snapshots** the preset's name, kind, and value, so editing or deleting a preset never rewrites settled history. **At most one order discount per receipt and one per line**; there is no stacking, and a venue wanting two promos combines them into one preset where the arithmetic can be checked once. Free to add, swap, and remove while a receipt is unpaid; **frozen once paid**, corrected only by the audited [[Settlement (recording payment)|reopen]]. Gated by the `applyDiscount` capability, or by **manager step-up** for a cashier without it — the row records both who applied it and who approved it. A discount can never push a total below zero. Prints as a **named** row (`Diskon Member 10%`), positioned per the `taxAfterDiscount` flag so the slip's arithmetic visibly works; reports as its own **Diskon** figure, never folded into Bruto. See [ADR-0037](docs/adr/0037-cashier-stage-catalog-discounts.md).

**Distinct from a comp.** A [[Void (item)|comp]] is order-stage and **removes** the item — it leaves the bill entirely and reports as a write-off. A 100% line Diskon is settlement-stage and **keeps the priced line visible** with the reduction beside it, so the guest sees they were given something. Same money, opposite messages, both needed. A line discount may target only a **non-voided** line, and no line is ever counted in both figures. _Avoid_: letting a waiter apply or preview a discount; stacking two discounts on one target; typing an ad-hoc percentage; treating a 100% discount and a comp as interchangeable; double-counting a give-away in both Bruto write-offs and Diskon.

### Preset diskon
**ID · EN** — Preset diskon · Discount preset. kind: persen · Percent; tetap · Fixed.

An owner-defined discount the [[Cashier]] may choose from — `{name, scope, kind, value, active}`, where **scope** is `bill`, `order` or `line` and **kind** is `percent` or `fixed`. Scope is what stops "Potongan 50rb" being applied to a 25k line; the cashier's picker only offers presets valid for what they tapped. Edited in a **Diskon** section of Venue Settings under `editSettings`, and **hard-deleted** rather than archived — safe because every applied [[Diskon (discount)]] snapshots its values, so history stands alone. The `active` flag hides a seasonal promo without deleting it. Deliberately carries **no** validity dates, usage caps, or per-item targeting — those are promo-engine features, and the cashier already knows which line to tap. _Avoid_: reading a preset live through `presetId` when rendering or reporting a settled bill (`presetId` is a weak reference kept only for the per-preset rollup); adding targeting rules without an ADR.

### Payment (manual confirmation)
**ID · EN** — Pembayaran · Payment. Methods: tunai · Cash; kartu · Card; qris · QRIS; transfer · Transfer; lainnya · Other. Kembalian · Change; Refund · Refund.

A cashier-recorded **attestation** that money changed hands — there is no payment gateway, so recording the payment *is* the confirmation (no verification, no external call). A Payment attaches to a **receipt** (not the whole [[Bill (tab)]]) and carries a **method** (`tunai` | `kartu` | `qris` | `transfer` | `lainnya`, the last with a free-text note), an **amount**, the recording **cashier's userId**, and a timestamp. A receipt may hold **multiple payments** (split tender, e.g. part Tunai + part Kartu); it flips to **paid** once `sum(payments) ≥ receipt total`. A receipt is **binary paid/unpaid** — no partial-paid limbo even mid-tender. For **Tunai**, the cashier may enter **amount tendered** and the app shows **change** (`tendered − total`); tendered/change are informational (printed, not stored as revenue — the recorded amount is the receipt total). _Avoid_: treating a Payment as gateway-verified; attaching payments to the whole bill instead of a receipt; storing tendered cash as revenue; confusing the sales cash a Tunai payment brings in with the [[Kas kecil (petty cash)]] box, which only ever pays money out.

**Post-payment correction.** [[Void (item)|Voiding]]/comping a line *after* its receipt is paid is **allowed** (with the existing manager approval, ADR-0006); the credit owed back is recorded as a **Refund** — a **negative payment** against the receipt, carrying the method it was returned by. A receipt's net = `payments − refunds`. The cashier may also **reopen** (un-pay) a receipt before [[Close (table) / Table session|Close]] to fix a mistaken settlement; reopen is itself audited. _Avoid_: freezing paid lines so corrections are impossible; letting a paid receipt's total drift with no Refund record (a lying money trail); inventing a parallel refund concept instead of reusing the `refund` capability.

### Payment proof photo (Bukti pembayaran non-tunai)
**ID · EN** — Bukti pembayaran non-tunai · Non-cash payment proof. "Ambil ulang" · "Retake".

A **mandatory** photograph attesting a non-cash [[Payment (manual confirmation)]]. Shot **live by the cashier's camera** at the moment the payment is recorded. Every method **except `tunai`** (kartu, qris, transfer, lainnya) requires **exactly one photo per [[Payment (manual confirmation)|Payment]]**; cash carries none. **Camera-only — no gallery** — so the proof is a live capture, not a saved screenshot. Enforcement is **server-side and fail-closed**: a non-cash payment arriving without a photo is rejected, and the photo + payment land in **one atomic request** (no orphan). Being **per Payment**, a split tender (e.g. part QRIS + part transfer on one receipt) carries **one photo each**.

The photo is **frozen into history** alongside its payment at [[Bill close (Tutup tagihan)|bill close]] (copied into the immutable snapshot), so it remains viewable on the [[Past bills]] **Struk pembayaran** detail and in a dedicated **non-cash payments report**. A [[Payment (manual confirmation)|refund]] (negative payment) carries **no** photo. _Avoid_: a gallery-sourced image; one photo for a whole receipt or bill; gating cash on a photo; letting a photo-less non-cash payment persist.

**One size, everywhere it is shown.** Wherever a proof appears — capture preview, live bill, [[Past bills]] detail, non-cash report — it is the **same 56dp square**, cropped, tappable, opening a zoomable full-screen viewer (ADR-0082). The thumbnail exists to answer *"was a real slip attached"*, **not** *"what does it say"*: a square crop crops a portrait slip's nominal and sender away, and reading it is the viewer's job. A proof is **always tappable**, capture preview included — the moment before submitting is the only one where a blurry shot is still retakeable. Three display states, never collapsed into two: **the slip**; **taken but unreachable** (bytes live only on the venue's LAN server, so an off-site [[Owner]] reading a [[Venue report snapshot|snapshot]] sees that a proof exists without being able to open it, ADR-0036); and **no proof** (cash, or a row predating the requirement). _Avoid_: a per-screen thumbnail size; showing "unreachable" and "no proof" as the same thing; sizing the thumbnail as if the slip were meant to be read in it.

### Kas kecil (petty cash)
**ID · EN** — Kas kecil · Petty cash. Movements: isi kas · Top-up; pengeluaran · Expense; opname kas · Cash count; pembatalan · Reversal. Categories: belanja bahan · Ingredients; operasional · Operations; transport · Transport; upah harian · Daily wages; lainnya · Other. Balances stay `Rp 250.000` in both languages (ADR-0084).

The venue's standing fund of physical cash for small outgoings — market shopping, ice, LPG, an ojek run, a day labourer's wage. **Not the drawer.** The drawer holds sales cash arriving through [[Payment (manual confirmation)|payments]]; the box holds a float that only ever leaves the venue. Nothing links the two: cash taken at the till never flows into the box automatically, and a top-up is an explicit act naming where the money came from in its note. The `openDrawer` and `closeShift` [[Capability|capabilities]] belong to the drawer and to per-cashier float reconciliation — neither of which exists yet — and must not be repurposed for the box.

The box is an **append-only ledger**, and its balance is `SUM(delta)` — **derived, never stored**. A movement is one of four: **isi kas** (positive), **pengeluaran** (negative, carrying a category and an optional photo of whatever receipt existed), **opname kas** (the counter enters the **absolute** cash found and the system writes the difference — the variance *is* the finding, exactly as [[Mutasi stok (Stock movement)|stok opname]] works), and **pembatalan** (a counter-entry against one earlier movement, carrying a **mandatory** note). Rows are never edited and never deleted; a mistake is corrected by reversing it, at most once per row, with no time limit — the same posture a [[Payment (manual confirmation)|refund]] takes toward a payment it cannot un-write.

**The box cannot go negative.** An expense exceeding the balance is rejected server-side (ADR-0088) — a divergence from `stockOnHand`, which is deliberately allowed to go negative because physical counts drift silently and the negative *is* the signal. Cash drifts for a different reason: somebody spent from the box and did not write it down. Refusing the entry is what makes them write the missing top-up.

**Petty cash is not revenue** (ADR-0089). It never enters `netTotal`, `settledTotal`, Bruto, or the payment mix, and reads only through its own **Kas** section in [[Report freshness (Live vs Snapshot)|Reports]] — opening balance, in, out, by category, closing balance — where the opening balance respects `businessDayStartHour` so a 02:00 expense buckets with the sales it sat beside. An expense is not negative revenue and a top-up is not income.

Every movement writes an [[Audit]] row under the single `cashMovement` type, visible to any `viewReports` reader rather than admin-gated, because it belongs with the other money acts. Movements broadcast over WebSocket to every paired client carrying the new authoritative balance — unfiltered, the way `auditCreated` already carries void and payment amounts, a fan-out that was seen and chosen rather than overlooked. Reachable at **`/kas`** under a **`manageCash`** capability for posting expenses, with top-up and opname held behind `editSettings`: a supervisor spends from the box, the owner funds and counts it.

_Avoid_: calling it the drawer, or reviving `openDrawer` for it; storing the balance; editing or deleting a movement; letting a would-be negative balance persist as a signal; folding a top-up into revenue or an expense into a write-off; linking an expense to a [[Mutasi stok (Stock movement)|stock receipt]] (correct end state, deliberately not yet — a wrong link corrupts two ledgers instead of one); giving the box an open/closed lifecycle.

### Pelanggan (member)
**ID · EN** — Pelanggan · Member; Keanggotaan · Membership; Daftar pelanggan · Member directory. _Avoid_: **Langganan** — that word already means the venue's own SatSet [[Venue billing|subscription]], and the two must never share a term. _Avoid_ "Customer" in user-facing English (the app has no non-member customers to contrast against).

A **durable person** the venue recognises across [[Visit|visits]] — name, phone, join date, optional note and birthday. **The phone number is the identity** (ADR-0092): it is unique venue-wide, enrolling on an existing number attaches to that member rather than minting a second, and there is **no anonymous member** — a guest who will not give a number simply is not one. Duplicates still arrive by typo, so **merge** exists as an admin act (points sum, punch progress takes the max, both audited). A member is **venue-local** (ADR-0091) — it lives in the venue's own database, never in the cloud, so a lookup cannot fail because the internet did.

**Distinct from `guestName`.** The waiter's party label on a [[Visit]] ("Pak Budi, 4 orang") is a *per-visit* string; the Pelanggan is the person behind it. Attaching a member **fills an empty `guestName` and never overwrites** one a waiter typed — the floor recognises the waiter's label, not the CRM's. A member attaches to the **Visit**, not to a receipt: one party has one member, and a [[Split bill]] across three payers must not earn three times.

The whole feature is off until **`membersEnabled`**; enroll, attach and [[Tukar poin|redeem]] ride the **`settleBill`** [[Capability]] (they happen at the till), while edit, hand-adjustment, merge and delete need **`manageMembers`**. Reachable at **`/members`**, tablet-only from the Venue hub, like [[Audit]] and [[Kas kecil (petty cash)]]. **Deleting a member anonymises, it never erases money** (ADR-0092): the person's row goes, the closed [[Bill (tab)|bills]] keep their `memberId` and render as "Pelanggan dihapus". _Avoid_: an anonymous or walk-in member; attaching to a receipt; overwriting `guestName`; deleting a member by deleting their settled history; storing a member in the cloud.

### Poin
**ID · EN** — Poin · Points; Poin didapat · Points earned; Sisa poin · Points balance; Poin beredar · Points outstanding.

A ledger of loyalty points against a [[Pelanggan (member)]], live only when **`memberPointsEnabled`** is on. Modelled on [[Kas kecil (petty cash)]]: **append-only, balance is `SUM(delta)`, never stored, never negative.** Points **earn once, at [[Bill close (Tutup tagihan)|bill close]]** (ADR-0095) — not per payment, because one bill mints several receipts and a reopen would earn twice — computed on the bill **net of discount, excluding service and tax** at an owner-set rate (default 1 poin per Rp 1.000, floored). A **reopen reverses** the earn and a re-close re-earns; a [[Settlement (recording payment)|refund]] posts a negative earn; a [[Walkout (tak tertagih)|walkout]] earns nothing.

**Points never expire** (ADR-0095) — the venue server has no scheduler, and a balance that changes by being looked at is worse than a growing one. The honest substitute is **Poin beredar** in the members Reports section: the outstanding balance read as a **liability**. _Avoid_: storing a balance; earning per payment or per receipt; earning on service and tax; expiring points on read; a negative balance.

### Tukar poin (redeem)
**ID · EN** — Tukar poin · Redeem.

Spending a [[Poin]] balance as money off a live [[Bill (tab)]], at the till, under `settleBill`. Lands as a **bill-scope [[Diskon (discount)]] in the `redeem` slot** (see [[Sumber diskon (discount source)]]) at an owner-set value (default 1 poin = Rp 1.000), minimum 10 poin, and the redeemed rupiah **earns nothing back**. A redemption is **never auto-reversed** by a reopen — the guest already spent the points and took the money off; an audited hand-adjustment unwinds the rare mistake. _Avoid_: redeeming offline; auto-reversing on reopen; letting a redemption push a total below zero.

### Kartu stempel (punch card)
**ID · EN** — Kartu stempel · Punch card; Hadiah · Reward. _Avoid_: "loyalty card" / "kartu loyalitas" — nothing is issued and nothing is carried.

An owner-run "buy N, get one free" program on **one menu item at a time**, live only when **`memberPunchEnabled`** is on. Progress is **derived from settled history** — paid, non-voided, non-[[Comp|comped]] units of that item on closed bills — never a stored counter, for the same reason the cash balance is not stored. The **reward is a [[Comp]]**, offered at settlement and booked through the existing comp path, so it reports as a write-off rather than as revenue and is already audited; **the free unit does not count** toward the next card. Takeaway counts — same guest, same item. _Avoid_: many concurrent programs (that is a promo engine); a stored punch counter; booking the reward as a discount; counting comped or voided units.

### Sumber diskon (discount source)
**ID · EN** — internal; not shown. Slots: `manual` · `member` · `redeem`.

Which authority put a bill-scope [[Diskon (discount)]] on a [[Visit]]. Three things now want that one slot — a cashier's promo, the [[Pelanggan (member)]] tier discount, and a [[Tukar poin (redeem)|redemption]] — so the "one bill discount per visit" rule becomes **one per source** (ADR-0094): the unique index moves from `visitId` to `(visitId, source)`. Every slot still snapshots its preset and still distributes across receipts through the ADR-0070 machinery. _Avoid_: relaxing the index to "any number of bill discounts" (that is how a promo gets applied twice); making the three mutually exclusive (a member's card must not cancel the Tuesday promo); giving order- or line-scope discounts a source.

### Admin is Firebase-only (no PIN admin)
Admin privilege is granted **only** through a Firebase admin account created by the [[Super admin]] in the [[Fleet console]] — never minted locally as a PIN user. The admin-mode **staff screen** therefore cannot assign any role that carries **`manageStaff`** (the seeded admin role *or* any custom role granting it), and the roles editor cannot grant `manageStaff` to a role; both are enforced server-side, not just in the UI. This closes the loophole where a local admin mints another admin (directly or via a custom elevated role). The old seeded PIN admin (full admin behind a 6-digit PIN) is removed; on upgrade, existing demo seed data is wiped. _Avoid_: a local break-glass PIN admin; gating the restriction in the UI only.

### Pesanan baru (table-less draft order)
**ID · EN** — Pesanan baru · New order.

A new order started **without first picking a [[Table]]** — the waiter opens the menu, builds the [[Estimasi (cart estimate)|cart]], then binds it at the review/commit step. Two terminal bindings: **assign to a table** (becomes a normal dine-in [[Visit]] via [[Seat (verb)|seat]] + submit) or **[[Bawa pulang (Takeaway)|Bawa pulang]]** (a takeaway visit with no table). The cart stays **client-local** until commit — nothing exists server-side before binding (no [[Visit]], no [[KDS / Antrian Persiapan|KDS]] line, invisible to other devices). **Complements, does not replace** the table-first flow (tap a kosong table → menu). Entry point: a **"Pesanan baru"** action on the [[Floor]]. _Avoid_: persisting a draft server-side before a table/takeaway binding (there is no server entity until commit).

### Kanal (channel)
**ID · EN** — Kanal · Channel; Bungkus · Walk-in wrapped; Telepon · Phone. **GoFood and GrabFood keep their brand names** in both languages.

How a [[Bawa pulang (Takeaway)]] order reached the venue — **Bungkus** (walked in and asked for it wrapped), **Telepon** (phoned through), **GoFood**, **GrabFood**. Recorded at creation, alongside the guest name, and carried for the life of the visit. It exists because these are not the same job at the till: a GoFood order is [[Prabayar (prepaid)|already paid]] and waiting on a courier, a phone order is owed and waiting on a person who may not arrive, and telling them apart at a glance is the whole reason a takeaway needs more than a "bawa pulang" flag. Each channel carries a hue, and that hue is the takeaway's stand-in for a dine-in's zone. _Avoid_: inferring the channel from the guest name; treating channel as a payment method (it is provenance — a GoFood order can still be unpaid); adding a channel without deciding what it means for money.

### Prabayar (prepaid)
**ID · EN** — Prabayar · Prepaid.

A [[Bawa pulang (Takeaway)]] [[Bill (tab)]] whose money **arrived before the food did** — the aggregator settled it, so there is nothing for the [[Cashier]] to collect. Normal for a GoFood / GrabFood [[Kanal (channel)]], impossible for a walk-in Bungkus. A prepaid bill still appears on the cashier list, because the cashier's question about it is "is this ready to hand over" rather than "who owes me" — but it carries no outstanding and offers no settle pane. _Avoid_: hiding prepaid bills from the cashier (the handover still has to happen); deriving prepaid from the channel alone (an aggregator order can be cash-on-delivery); recording a zero payment to fake it settled.

### Bawa pulang (Takeaway)
**ID · EN** — Bawa pulang · Takeaway; Makan di tempat · Dine-in; Serahkan · Hand over. _Not_ "Takeout" or "To go" — pick one and hold it across the board, the KDS and the cashier.

A [[Visit]] that **never occupies a [[Table]]** — a takeaway order. Modeled as a Visit with `kind == takeaway`: no `tableId`/table row, `tableLabel` = the guest name (+ running takeaway number), **guestName required** (its only handle). It rides ADR-0024's two-axis end, with **handover replacing [[Table close (detach)]]**:

- **Handover ("Serahkan")** — marks the food handed to the guest. Same **all-tickets-terminal gate** as table-close (can't hand over food still cooking); stamps the visit's `tableFreedAt` (reinterpreted as handover time). Gated by `takeOrder` — **waiter or cashier** may tap it.
- **[[Bill close (Tutup tagihan)]]** — unchanged money axis.

The `TableSession` **snapshot fires at the second axis**, exactly like dine-in: pay-upfront → later handover snapshots; food-first → handover, bill stays on the [[Cashier]] flagged, later pay snapshots. `tableFreedAt` is `null` at creation (not snapshotted on bill-close while food still cooks — that would delete live [[KDS / Antrian Persiapan|KDS]] tickets). Distinguished from a detached **[[Walkout (tak tertagih)|walkout]]** by `kind` (different cashier copy: "Bawa pulang" vs "meja ditutup, belum lunas") and **reported distinctly** (takeaway vs dine-in revenue). The KDS and [[Order elapsed time|Pesanan board]] label its lines by the visit's frozen label, **not** a `tableId → table` lookup (which drops the line / shows a raw id). _Avoid_: snapshotting at bill-close while food still cooks; a pseudo "Bawa pulang" table (a table holds one visit — concurrent takeaways collide); a separate takeaway entity duplicating the bill/receipt/payment stack.

### Report freshness (Live vs Snapshot)
**ID · EN** — Langsung · Live; Cuplikan · Snapshot.

Whether the [[Reports]] screen's numbers are still moving. A report over a range that **includes the current business day** (`today`) is **Live** — new sales land in it as service runs, so it reflects "now". A report over any range that **ended in the past** (`yesterday` / `7 hari` / `30 hari` / `bulan ini` / a past [[Custom range]]) is a **Snapshot** — a frozen window that no longer changes. The distinction is **informational only**: it tells staff whether to expect the figures to tick, and never gates any action. Surfaced as a **plain status line** on the report header (a freshness word beside the active range), deliberately **not** styled as a chip/button so no one mistakes it for a control. _Avoid_: rendering freshness as a tappable-looking chip; treating "Live" as a refresh mode (resync is a separate manual/auto act).

### Custom range
**ID · EN** — Rentang khusus · Custom range. Presets: today · Hari ini · Today; yesterday · Kemarin · Yesterday; 7 hari · 7 days; 30 hari · 30 days; bulan ini · This month. The chip's own span label ("12 Jun – 15 Jun") is a **date**, so it localises (ADR-0084).

A sixth **timeline chip** on the [[Reports]] screen, beside the fixed presets (`today` / `yesterday` / `7 hari` / `30 hari` / `bulan ini`). Tapping it opens a sheet to pick a **start** and **end calendar date**; the window is **date-only**, snapped to the venue's **business-day boundary** like every other chip (start = business-day-of-start, end = next business-day after the end date, exclusive), never a clock-time range. The span is **capped at 92 days**. The picked range drives **both** the on-screen report **and** the [[Export (report / order history)|export]] (report + order history) — it is the single range control; there is no per-export picker. Committing requires both dates valid (start ≤ end, no future); until committed the chip stays inert and the previously active chip holds. Once committed the chip shows the picked span (e.g. "12 Jun – 15 Jun"). Custom counts as a **Snapshot** (not Live) range. _Avoid_: a clock-time range; an independent range living inside the export sheet; refetching mid-pick.

### Export (report / order history / staff / accounting)
**ID · EN** — Ekspor · Export; Jenis · Kind. Kinds: Laporan · Report; Pesanan · Orders; Staf · Staff; Akuntansi · Accounting. CSV headers and PDF section titles follow the exporting device's locale (ADR-0083); the amounts inside them do not (ADR-0084).

A **range-scoped** download of venue data as **CSV or PDF**, generated on-device and handed off through the Android **share sheet** (`share_plus`). One entry point on the [[Reports]] screen — a single **Ekspor** action opens one sheet where the user first picks a **Jenis** (kind): **Laporan**, **Pesanan**, **Staf**, or **Akuntansi**. All four read the **same active timeline chip** (including [[Custom range]]); there is no per-export range picker. The four kinds:

- **Laporan (report export)** — Covers the active **timeline chip** (`today` / `yesterday` / `7 hari` / `30 hari` / `bulan ini` / `custom`) already selected on screen — export reads that chip, no separate picker. PDF carries the **full** report (every section, laid out to mirror the screen); CSV carries the **KPI block + key tables** (staff rows, menu top/slow, category mix, hourly) — visual-only bits (matrix, basket pairs, sparklines) are dropped.
- **Pesanan (order history export)** — The order board stays **live** (open tickets now); the export reads the **same active timeline chip** as the report (including [[Custom range]]) — it has **no separate range picker** and does **not** change the board. Rows are [[Orderer (line author)|line items]] for closed [[Table session (visit snapshot)|visits]] in the window, **grouped by visit** (table + party header, visit total), [[Void (item)|voided]] lines **included and flagged**.
- **Staf (staff-focus export)** — One **combined per-staff row** carrying productivity + sales + integrity together: sessions, [[Party / partySize|covers]], items, net sales, average ticket, upsell rate, void count, void %, lost rupiah, top void reason. Sorted by net descending. CSV is the wide table verbatim; PDF renders it as a **single landscape table** (the 10 columns do not fit portrait). For comparing and coaching waitstaff in one sheet. _Avoid_: splitting productivity and integrity into separate Jenis — they live on one row.
- **Akuntansi (accounting export)** — A bookkeeping view of the same window: **revenue summary** (gross subtotal → discounts → net → tax → total collected), **payment-method breakdown** (cash / QRIS / card / transfer, amount + count, refunds on their own line, for drawer-and-bank reconciliation), **voids & refunds** as write-offs, and a **per-calendar-day breakdown** for ledger posting. Tax and service are the **real settled figures** (sum of session `taxAmount` / `serviceAmount`), **not** the on-screen "Pajak + Service" 18% estimate, and the window uses the **same range rule as the on-screen report** rather than settlement-date accrual — see [[../docs/adr/0032-accounting-export-real-settled-figures-on-screen-range|ADR-0032]].

Generated via **dedicated read-only server endpoints** scoped to the range: **Laporan** reuses the [[Reports]] snapshot already in memory; **Pesanan**, **Staf**, and **Akuntansi** each hit a purpose-built window query (`/reports/staff`, `/reports/accounting`) that reuses the snapshot's `_resolveRange`. All gated behind `viewReports` — even the order list (otherwise open to `takeOrder`) — because export exposes historical financial data. _Avoid_: turning the live order board into a historical browser; trusting a client to widen its own range past the gate; splitting kinds into separate header buttons (one **Ekspor** entry, Jenis chosen inside the sheet); basing accounting tax on the cosmetic 18% KPI.

### Bahan (Ingredient)
**ID · EN** — Bahan · Ingredient; Stok · Stock. Count presets keep their Indonesian names — **butir**, **siung**, **lembar** — in both languages: they are units on a label, and "grain"/"clove"/"sheet" would imply they inter-convert, which they never do. `pcs`, `g`, `kg`, `ml`, `L` are already language-neutral. _Not_ "Material".

A **raw stock item the venue holds and counts** — beras, ayam, keju, or a countable SKU like a bottle of Coca-Cola. The unit inventory is tracked in; a [[Menu category|menu item]] is *not* an ingredient, it is assembled from ingredients via a [[Resep (Recipe)|resep]]. A bottled drink is modelled as an ingredient whose recipe is one of itself — the SKU and the ingredient are the same thing, so there is no second "countable item" concept.

Each bahan carries a **unit preset** from a fixed list, grouped by **dimension**: mass (`mg`/`g`/`kg`), volume (`ml`/`L`), and count (`pcs`, `butir`, `siung`, `lembar`). Units convert freely **within** a dimension and never **across** one — and count presets are display labels only, never inter-convertible (a butir of telur and a siung of bawang are different bahan, not different units of one). Entering a `kg` figure against a volume bahan is rejected.

Quantities — both stock on hand and [[Resep (Recipe)|resep]] amounts — are stored as **integers at 1/1000 of the dimension's canonical base** (milligram, microlitre, milli-pcs), the same exact-integer discipline the codebase uses for money. `0.2 kg` is `200000`; `0.5 butir` is `500`. The chosen preset is an entry/display convenience, not the storage unit. _Avoid_: `double` quantities (drift accumulates over thousands of deductions and makes `<= 0` fuzzy); free-text units (blocks conversion); treating a menu item as a stock item.

### Resep (Recipe)
**ID · EN** — Resep · Recipe. _Not_ "Prescription" — the machine-translation trap this glossary exists to catch.

The **bill of materials** for one sellable configuration of a [[Menu category|menu item]] — which [[Bahan (Ingredient)|bahan]], and how much of each, one portion consumes. Recipes are what make inventory move: they are the only link between "a guest ordered this" and "this much stock left the building".

A recipe resolves against the **exact configuration ordered**, in three layers:

- **Base recipe** — the item's own list. Used when the item has no [[Variant (variation)|varian]], or when the ordered varian carries none of its own.
- **Per-variant recipe** — a full list that **replaces** the base entirely, not merges with it. "Besar" is authored as its own complete recipe, not as a multiplier over "Reguler", because a size step is not always proportional.
- **Per-modifier-option recipe** — a small list that **adds** on top of whichever of the above won. "Extra keju" contributes `+30 g keju`; it never replaces anything.

Recipes are **private to their item**, like [[Modifier group (add-on)|modifier groups]] and [[Variant (variation)|varian]] — there is no shared recipe library. An item with **no recipe at all consumes nothing**, which is the correct default for a menu being migrated onto inventory one dish at a time. _Avoid_: a per-variant multiplier over the base (rejected — it mismodels variants that swap ingredients rather than scale them); merging a variant recipe into the base (it replaces); assuming a recipe-less item is an error state.

### Mutasi stok (Stock movement)
**ID · EN** — Mutasi stok · Stock movement; Stok opname · Stocktake; Terima barang · Receive stock; Produksi · Production. Reasons: sale · Sale; voidReturn · Void return; waste · Waste; receive · Received; adjust · Adjustment. **"Opname" is "Stocktake", never "Inspection"**.

The **append-only record of one change to one [[Bahan (Ingredient)|bahan]]'s stock** — the audit trail behind every number inventory shows. Carries the bahan, a signed `delta` (in the bahan's milli-base unit), a **reason**, the acting user, the timestamp, and — where one exists — the [[Order elapsed time|ticket]] that caused it.

Every movement writes its row **and** updates the bahan's denormalised `stockOnHand` in the same transaction, so history is complete while sold-out checks stay O(1). Five reasons, one uniform shape:

- **`sale`** (negative, ticket-linked) — a line was [[Batch (kitchen order)|sent]] to the kitchen. See [[Pengurangan stok saat kirim (Deduct at send)]].
- **`voidReturn`** (positive, ticket-linked) — a [[Void (item)|void]] the kitchen had not started; the stock is genuinely still there.
- **`waste`** (negative) — a void the kitchen *had* started (the ingredients are gone), or standalone spoilage.
- **`receive`** (positive) — goods arrived.
- **`adjust`** (either sign) — a stok opname correction. Requires a reason text.

_Avoid_: a bare mutable balance with no history (an unauditable number is worse than none — staff stop trusting the sold-out flags and route around them); recomputing balances by aggregating the ledger on every menu render.

### Pengurangan stok saat kirim (Deduct at send)
Stock moves **when a line is sent to the kitchen**, not when it is cooked, served, or paid for. Send is the one point that is already atomic and server-side, and the last point at which refusing a line is still cheap — by `cooked` the ingredients are gone and an "insufficient stock" answer is useless. It is also the only point at which two waiters racing for the last portion can be resolved consistently.

A [[Void (item)|void]] returns stock **only if the line was still `sent`** (the kitchen never touched it); a void from `prep`, `cooked`, or `ready` is recorded as [[Mutasi stok (Stock movement)|waste]] instead. The test is the line's **lifecycle status**, not its void reason code — status is a kitchen fact already on the ticket, whereas a stated reason asks the waiter to predict one (a `customerChange` on a plated dish would wrongly restock). Known ceiling: a kitchen that leaves everything at `sent` until pickup makes every void look untouched. _Avoid_: deducting at serve or at [[Bill close (Tutup tagihan)|bill close]] (sold-out would never fire during service); restocking every void unconditionally.


### Audit (venue audit log)
**ID · EN** — Catatan audit · Audit log. Columns: Waktu · Time; Jenis · Type; Pengguna · User; Alasan · Reason; Disetujui oleh · Approved by. Event kinds: void · Void; comp · Comp; diskon · Discount; refund · Refund; ubah pesanan · Order edit; pindah meja · Table move; tutup tagihan · Bill close.

The venue's own integrity record (ADR-0072) — every act that moves money without selling something: [[Void (item)|voids]], [[Comp|comps]], [[Diskon (discount)|discounts]], refunds, order edits, [[Pindah meja (Move table)|moves]]. Written **only** through `writeAudit`, for the reason `CLAUDE.md` gives: hand-roll the insert and a new column reaches three call sites out of four. Distinct from the cloud-side [[Fleet audit]], which records what a [[Super admin]] did to the fleet.

An audit row records **what happened, not a sentence about it** (ADR-0085): a `kind` plus its params, composed into prose at read time in the reader's language. Rows written before that change carry a frozen Indonesian `title` and keep rendering from it, because that is genuinely what was recorded. _Avoid_: composing the sentence at write time; a "comps" figure read off `AuditType.comp` (vestigial — see [[Comp]]); treating the log as editable by its own subject.

### Tema (Theme)
**ID · EN** — Tema · Theme. The six theme **names** — Amber Gelap, Amber Terang, Neon Gelap, Neon Terang, Neo Kertas, Neo Tengah Malam — stay Indonesian in both locales: they are product names for a palette, and a translated name would make a waiter's muscle memory for "the dark one" break at a language switch. The **language** setting sits beside this one, on the same `/me` sheet pattern and with the same device-local scope (ADR-0083).

The whole look of the staff app — background ramp, accent, and semantic hues together — picked as one named unit, not assembled from a palette plus a light/dark switch. Six ship today: **Amber Gelap**, **Amber Terang**, **Neon Gelap**, **Neon Terang** (default), **Neo Kertas**, **Neo Tengah Malam**. Each declares its own brightness, so there is no separate dark-mode toggle and no OS-follow, and each carries a shape language alongside its colours — a theme is one choice, not a palette plus a style.

A theme is **device-local**: it lives in `SharedPreferences` on one handset, next to the audio-alert flag and that device's printers. It is deliberately neither per-user (shared hardware would re-theme on every shift change, destroying the muscle memory the app is built for) nor per-venue (the hot line tablet and the terrace phone want different palettes at the same moment). Staff pick by the light in the room they are standing in.

The six semantic hues ([[Habis / Sold out (menu item out of stock)|habis]], ready, urgent, and friends) are byte-identical across themes so the colour vocabulary is learned once — except where a theme's accent would collide with one of them, in which case only that one token is retuned. See [docs/adr/0045-device-local-theme-selection.md](docs/adr/0045-device-local-theme-selection.md).

_Avoid_: treating theme as a user profile setting or a venue policy; putting the picker behind an admin capability (every waiter sets their own); adding a theme whose accent duplicates a semantic hue.
