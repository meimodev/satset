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
- **Waiters** hear **ready** for any table (shared "someone grab it" awareness), but a **void/comp** cue reaches only the **responsible waiter** (the table's current waiter — see [[Waiter]]).

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

### Local server lifecycle (tied to admin session)
The embedded LAN server's running state is bound to a valid admin session. It starts when an [[Admin session (Firebase-gated)|admin]] signs in, and is **killed on admin logout or loss of [[Admin eligibility (T&C kill switch)|eligibility]]** — connected staff/client devices are disconnected and **cannot reconnect until an admin successfully re-signs-in**. The admin session is thus the venue's on/off switch. A logout while live tables exist warns first ("X meja aktif, staff akan terputus") but still proceeds — the kill is intentional. _Avoid_: leaving the server running after the admin signs out.

### Super admin
A fleet operator who manages **many [[Venue (cloud)|venues]] and their [[Admin session (Firebase-gated)|admins]]** across the whole SatSet customer base — distinct from a venue **admin** (who runs one restaurant). Flagged by **`admins/{uid}.role == 'super'`** (normal admins are `role == 'admin'`). Detected **at Firebase login**: the app reads the signed-in admin doc and, if `super`, **diverts to the [[Fleet console]]** instead of the normal Server-mode flow — a super admin **never pairs, never runs a local server, never touches Drift**; it talks only to Firebase/Firestore + Cloud Functions. There is no separate mode-select tile; the super-admin account is created manually and recognised purely by its role.

A super admin can: CRUD venues and admin accounts, flip the per-venue [[Admin eligibility (T&C kill switch)|kill switch]], monitor [[Venue billing]], and monitor [[Venue offline duration]]. _Avoid_: granting a super admin a local server or venue of its own; routing its mutations through direct client Firestore writes (they go through Cloud Functions — see [[Fleet console]]).

### Fleet console
The single role-gated screen a [[Super admin]] lands on — the cloud control surface for the whole fleet. Read side (live Firestore, gated by an `isSuper()` rule): list venues + their admins, [[Venue billing]] state, [[Venue offline duration]]. Write side (**all** mutations via **Cloud Functions** callables, server-enforced authz, audited): create/disable/delete admin accounts, create/edit venues, flip a venue's kill switch. _Avoid_: doing mutations with direct client writes — the client only reads; credentials (Firebase Auth users) can only be managed by the Admin SDK behind a callable.

### Venue (cloud)
A restaurant as a **first-class cloud entity** `venues/{vid}` — the unit the [[Fleet console]] manages and monitors. Distinct from the **local** `VenueSettings` (display name, receipt header, etc.) that lives in each Server device's Drift DB: the cloud venue carries only fleet-level fields (`name`, `status` kill switch, billing plan/state, `lastSeenAt`). **One venue → many [[Admin session (Firebase-gated)|admins]]**; each admin carries `venueId`, and every admin on a venue runs *that* venue's local server when in Server mode. _Avoid_: conflating the cloud venue record with local `VenueSettings`, or assuming one admin per venue (the old implicit 1:1 is gone).

### Venue offline duration
How long a [[Venue (cloud)|venue]] has been dark — derived from `venues/{vid}.lastSeenAt`, a **heartbeat** the Server device writes (**direct client write, ~60s** while the local server is live, plus on start/stop). A **field-scoped** security rule lets a normal admin write **only** `lastSeenAt` on **their own** venue (`venueId`) and nothing else — so the heartbeat doesn't reopen the kill switch. The [[Fleet console]] surfaces `now − lastSeenAt`. _Avoid_: treating a stale heartbeat as a kill — offline ≠ suspended (a venue can be legitimately closed); and letting the heartbeat rule widen into a general venue-write.

### Venue billing
The billing state of a [[Venue (cloud)|venue]], held on `venues/{vid}` as **manual flags** — `plan` (tier, e.g. free/pro), `billingStatus` (`paid` | `overdue` | `trial`), `paidUntil` (date). **No payment gateway**: a [[Super admin]] sets these by hand via a Cloud Function. Surfaced read-only to the SA in the [[Fleet console]]. Billing is **independent of the [[Admin eligibility (T&C kill switch)|kill switch]]** — an `overdue` venue keeps running until the SA *manually* flips `status` to `suspended`; nothing auto-suspends on non-payment. _Avoid_: coupling `billingStatus` to `status` automatically.

### Shift
One staff member's working session, bounded by login and logout — **not** a fixed roster block. Begins at PIN sign-in (`shiftStartedAt` = the login timestamp) and ends at **"Akhiri shift & keluar"** (sign-out). Elapsed time is `now − shiftStartedAt`. The **Ringkasan shift** ("Saya" tab) summarises the current session for its owner: their identity, sales, [[Cover|covers]], and recent [[Void (item)|void]]/comp/modify [[Audit|audit]] activity. _Avoid_: treating a shift as a scheduled shift-pattern, or as venue-wide (it is per-account, this-session only).

