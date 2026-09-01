# 01 · Order taking & the floor

This covers the waiter's operational surface: the floor (zones, tables, locking, seating, moving), the menu-browse-and-cart flow into review and send, the "sent" confirmation, the Pesanan (orders) board, table-less/takeaway orders, counter mode's menu-home layout, reservations, and the void flow. It is the "get an order from a guest's mouth into the kitchen, correctly, in seconds, without the internet" job described in CLAUDE.md's Design Context — everything else in the app is bookkeeping around it.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Floor (zones + table grid) | `/tables` | `takeOrder` (implicit — reads tables/zones) | `GET /tables` |
| Table hold / Dipesan derived state | `/tables` (card badge) | — (read-only) | — |
| Seat a table (walk-in) | `/table/:id` | `takeOrder` | `POST /tables/:id/seat` |
| Reservations (Buku reservasi) | drawer/sheet over `/tables` | `takeOrder` | `GET/POST/PATCH/DELETE /reservations` |
| Seat from a reservation | drawer over `/tables` | `takeOrder` | `POST /tables/:id/seat` (`acquireLock:true`) |
| Table lock (advisory lease) | `/table/:id` | `takeOrder` | `POST/DELETE /tables/:id/lock`, `POST /tables/:id/lock/heartbeat` |
| Move table (Pindah meja) | sheet over `/table/:id` | `takeOrder` | `POST /tables/:id/move` |
| Table close / release | `/table/:id` | `takeOrder` | `POST /tables/:id/close`, `POST /tables/:id/release` |
| Menu browse + cart | `/table/:id/menu`, `/order/new`, `/takeaway/:id/menu`, `/counter` | `takeOrder` | `GET /tables` (menu via `menuRepository`) |
| Modifiers (item configure sheet) | sheet over the menu screen | `takeOrder` | — (client-only until send) |
| Review & send | `/table/:id/review`, `/order/new/review`, `/takeaway/:id/review` | `takeOrder` | `POST /orders` |
| Table-less draft → commit (Pesanan baru) | `/order/new` → assign-table sheet | `takeOrder` | `POST /tables/:id/seat` + `POST /orders` |
| Takeaway (Bawa pulang) | `/takeaway/:visitId` | `takeOrder` | `POST /orders` (takeaway path), `POST /visits/:id/handover` |
| Sent confirmation | `/table/:id/sent` | `takeOrder` | — (display only) |
| Pesanan board (orders) | `/orders` | `takeOrder` | live from `ticketsProvider`/WS |
| Fire a held course | table detail | `takeOrder` | `POST /tables/:tableId/course/:course/fire` |
| Ticket transitions (advance/serve) | table detail, KDS | per-move, see [ticket_transitions.dart](lib/domain/models/ticket_transitions.dart) | `POST /tickets/:id/transition` |
| Void an item | line-item action sheet | `voidItem` (pre-serve) / `compItem` (post-serve) | `POST /tickets/:id/transition` (`status: voided`) |
| Edit a sent (held) line | line-item action sheet | `modifyOrder` | `PATCH /tickets/:id` |
| Counter mode menu-home (Kedai) | `/counter` | `takeOrder` | — (config-driven route swap) |

## Floor (Meja / Zone grid)

**What** — The waiter's live operational screen: zone tabs over a grid of table cards, headed by the zone's occupied/ready/open-tab counts and three counted triggers — Reservasi, Bawa pulang, Pesanan baru. This is the primary jumping-off point for waiters during service; distinct from `/floor` (admin floor configuration — create/rename/reorder zones and tables), which is a different screen despite the name.

**Who** — Waiter and anyone with `takeOrder`; reading the grid itself is not capability-gated beyond the route requiring `takeOrder` in `_capabilityFor` (`lib/router/app_router.dart:60-68`).

**Where** — Route `/tables` (`lib/router/app_router.dart:303`). Screen: `lib/ui/features/tables/tables_screen.dart` (`TablesScreen`, line 40). Card widget: `lib/ui/features/tables/widgets/table_card.dart`. Derived signals: `lib/ui/features/tables/view_models/floor_signals.dart`.

**How to use**
1. Land on `/tables` after sign-in (server mode goes to `/venue`; client mode goes to `/tables`, or `/counter` if [[Kedai]] menu-home is on — see below).
2. Switch zones via the zone tab row; each tab shows a total or, when any table in that zone is ready, `N·sp` (ready count) instead.
3. Read a table card's status pill: **Kosong** (`tcStatusAvailable`), **Terisi** (`tcStatusOccupied`), **Pesanan masuk** (`tcStatusPending`), **Siap ×N** (`tcStatusReady`), or **Dipesan** (`tcStatusReserved`) when a `pending` reservation names it inside the hold window.
4. A card also carries a money badge when the visit has a payment state: **Lunas** (`tablePaidFull`) or **Sebagian** (`tablePaidPartial`) — from `t.billClosed || t.moneyState == 'paid'` / `t.moneyState == 'partial'` (`lib/ui/features/tables/widgets/table_card.dart:471-473`).
5. Tap a kosong card to open `/table/:id` and seat it, or tap an occupied one to manage it.
6. Use the head triggers: **Reservasi** opens the booking book, **Bawa pulang** opens the takeaway strip, **Pesanan baru** opens the table-less draft flow.

**Under the hood** — `TablesScreen.build` (`lib/ui/features/tables/tables_screen.dart:47-115`) reads `tablesProvider` and `zonesProvider`, filters to `t.active`, computes the subtitle line from `tblOccupiedOf`, `tblReadyToCollect`, `tblOpenTab` (lines 78-83), and renders `_FloorHead` + `_TablesZoneRow` + a `_FloorGrid` of `table_card.dart` widgets. `VenueTable.status` is `TableStatus` — `available | occupied | pending | ready` (`lib/domain/models/venue_table.dart:3`). Backed by `GET /tables` in `lib/server/routes/tables_routes.dart:568`.

**Offline behaviour** — The grid renders from local `tablesProvider` state, which is kept current by WebSocket `tableUpdated` broadcasts while connected, and simply goes stale (no spinner, no error) while `terputus` — degrade loudly is the design principle, but the floor itself has no offline-specific banner beyond individual table locks/queues (see below).

**ADRs** — [ADR-0048](docs/adr/0048-floor-screen-parity-and-derived-staleness.md) (screen composition, Basi/stale banding), [ADR-0001](docs/adr/0001-table-locking-and-seat-semantics.md) (lock scope).

**Gotchas** — `FloorScreen` at `/floor` is the *admin* configuration screen; never call it "the Floor" — that term is reserved for `TablesScreen`. A table's **Dipesan** badge and the "Basi" (stale) banner are both derived, never persisted (see CONTEXT.md "Dipesan (table hold)" and "Basi (stale)") — no lock is taken for a hold, so two waiters can still walk-in seat a "Dipesan" table.

## Reservations (Buku reservasi)

**What** — A planned future visit: name, phone, party size, expected time, optional zone/table hint, notes, optional linked [[Pelanggan (member)]]. Lifecycle `pending → (seated | noShow | cancelled)`.

**Who** — `takeOrder` (`_requireCap(req, db, auth, Capability.takeOrder)` on all three reservation routes, `lib/server/routes/reservations_routes.dart:89,142,206`).

**Where** — `openReservationsSurface` (`lib/ui/features/tables/widgets/reservations_surface.dart:35`) — a side drawer on tablet, a 92%-height bottom sheet on phone, both hosting `ReservationsBook` (line 89). Reached from the Floor head's **Reservasi** trigger.

**How to use**
1. From `/tables`, tap **Reservasi**. The book opens showing today's bookings, filtered by chips: **Menunggu** (waiting), **Terlambat** (late), **Duduk** (seated), **No-show**, **Semua** (all) — `_RvFilter` enum, `reservations_surface.dart:82`.
2. Tap **Reservasi baru** (`resNewBooking`) to create one: guest name, phone (optional), party size, expected time, optional zone/table, notes; a matching phone can attach or enrol a [[Pelanggan (member)]].
3. A `pending` booking overdue by more than `reservationGraceMins` shows **Terlambat** instead of its normal status — this is derived at render time, never stored (`_isLate`, line 99).
4. On a pending row, use the **SeatPicker** (`reservations_surface.dart:497`) to pick a free table and seat the party, or tap **No-show** (danger button) / **Batal** (cancel outline button) to close it out without seating.
5. A `noShow`/`cancelled` row can be restored via **Pulihkan** back to `pending`.

**Under the hood** — Domain model `Reservation` / `ReservationStatus` (`lib/domain/models/reservation.dart`); DTOs in `lib/data/models/reservation_dto.dart` with `ReservationStatusKey` = `pending|seated|noShow|cancelled`. Server: `GET/POST /reservations`, `PATCH /reservations/:id`, `DELETE /reservations/:id` (`lib/server/routes/reservations_routes.dart:70,88,141,205`), all gated `takeOrder`. Seating a reservation calls `POST /tables/:id/seat` with `acquireLock: true` so the waiter's later navigation to the table detail doesn't lose a lock race (see ADR-0001).

**Offline behaviour** — Not covered by the [[Antrean kirim]]; reservation CRUD requires a live connection.

**ADRs** — [ADR-0048](docs/adr/0048-floor-screen-parity-and-derived-staleness.md) (drawer/sheet surface, "Basi" derivation pattern shared with lateness), [ADR-0001](docs/adr/0001-table-locking-and-seat-semantics.md) (reservation-seat pre-acquires the lock, unlike walk-in seat).

**Gotchas** — Lateness has no `late` status and no button that sets one — "a clock must not decide a no-show" (CONTEXT.md). A booking is *not* a Visit; only a closed session counts toward a member's visit/spend/stempel stats.

## Seat a table (walk-in)

**What** — Transition a table from **kosong** (`available`) to **terisi** (`occupied`). Two entry points hit the same endpoint: walk-in (from the table detail's CTA) and reservation-seat (from the booking book, pre-acquiring the lock).

**Who** — `takeOrder`.

**Where** — Table detail screen `lib/ui/features/tables/table_detail_screen.dart` — `onSeat()` (line ~347). Button label: **"Mulai layani meja"** (`tblStartService`).

**How to use**
1. Tap a kosong table card, land on `/table/:id`.
2. Read-only summary + **"Mulai layani meja"** CTA is shown (no lock is held on a kosong table, per ADR-0001).
3. Tap it — pax defaults to 1; adjust afterward with the `+`/`−` stepper (`onMinus`/`onPlus`, clamped `[1, capacity]`).
4. On success, the status flip to `occupied` triggers an auto-acquire of the table lock via a `tablesProvider` listener — no explicit lock call is needed client-side.
5. On `409 already_seated`, a snackbar reads `tblAlreadySeated` ("Meja sudah diisi oleh {holder}") and the optimistic UI rolls back.

**Under the hood** — `TablesRepository.seat()` (`lib/data/repositories/tables_repository.dart:246-340`) optimistically flips local state, then either enqueues (see Offline below) or `POST`s `/tables/:id/seat` with `{pax, actorId, actorName, guestName, guestNotes, reservationId, acquireLock}`. Server route `lib/server/routes/tables_routes.dart:713`, gated `takeOrder` (line 714), rejects a non-`available` target with `409 already_seated` carrying the current table row so the client can merge it.

**Offline behaviour** — If `wsConnStateProvider != open` when `seat()` is called, the seat is parked on the [[Antrean kirim]] (`_enqueueSeat`, ADR-0090) rather than attempted — checked *before* the POST so a waiter doesn't pay an 8s timeout on every tap in a dead-signal corner. Even when the socket claims open but the POST never lands (transport gap), the same enqueue path runs. On successful queued send, `sendQueueDrainProvider` replays it through the ordinary route once reconnected.

**ADRs** — [ADR-0001](docs/adr/0001-table-locking-and-seat-semantics.md), [ADR-0090](docs/adr/0090-an-offline-order-is-an-intent-not-a-row.md).

**Gotchas** — Seat is capacity-clamped (`pax.clamp(0, prev.capacity < 1 ? 1 : prev.capacity)`). A table may only be seated by one party at a time — the 409 is the sole contention point; every other surface converges via the WS `tableUpdated` broadcast.

## Table lock (advisory lease)

**What** — A per-user 7s-TTL advisory lease (3s heartbeat) on a table's detail screen, preventing two waiters editing the same table at once. Only active when `status != available` — kosong tables are lock-free.

**Who** — `takeOrder` implicitly (the lock endpoints sit under the same route prefix, all gated `takeOrder`).

**Where** — `lib/data/repositories/tables_repository.dart`: `acquireLock()` (line 569), `heartbeatLock()` (line 613), `releaseLock()` (line 644). Server: `POST /tables/:id/lock` (line 841), `POST /tables/:id/lock/heartbeat` (line 890), `DELETE /tables/:id/lock` (line 930) in `lib/server/routes/tables_routes.dart`.

**How to use** — Automatic: opening `/table/:id` on a non-kosong table triggers auto-acquire; the screen heartbeats every 3s while mounted; leaving releases it. Another device opening the same table sees a read-only banner: **"Meja diambil oleh {holder}{since}"** (`tblLockedBy`).

**Under the hood** — `acquireLock()` returns `TableLockResult.acquired` or, on `409 table_locked`, `.conflict` carrying the current holder's row so the UI can show who holds it (`lib/data/repositories/tables_repository.dart:587-608`). `VenueTable.isLockedByOther(userId, {now})` (`lib/domain/models/venue_table.dart:68-74`) is the client-side gating helper — the server is authoritative.

**Offline behaviour** — A lease **cannot be requested** while `terputus` — the request needs the host. `table_detail_screen.dart` computes `tableAccess(lockedByOther, hasLease, offline)` (around line 288) to distinguish "someone else holds this table" (fully blocked) from "nobody could be asked" (a third state — only the two queue-backed writes, **submit order** and **void**, stay open; firing, serving, closing and pax edits wait). This is the ADR-0116 split described in CLAUDE.md's "A lease you cannot renew still lets you queue" rule; the padlock must never be read as "the network is down".

**ADRs** — [ADR-0001](docs/adr/0001-table-locking-and-seat-semantics.md). (ADR-0116, referenced throughout, was not in the assigned reading set but is load-bearing here — see CLAUDE.md.)

**Gotchas** — The lease is never faked, claimed, or heartbeaten while offline; the host still arbitrates on drain. Kosong tables are deliberately lock-free — locking a resource with nothing to protect just wastes heartbeat round-trips.

## Move table (Pindah meja)

**What** — Transfer a whole live session from a seated table onto an empty target table, atomically, attributed as one session to the **target** (final) table at close.

**Who** — `takeOrder`.

**Where** — Sheet `showMoveTableSheet` (`lib/ui/features/tables/widgets/move_table_sheet.dart:22`), triggered from the table detail's **"Pindahkan meja"** quick action (`tblMoveTable`).

**How to use**
1. From an occupied table's detail, choose **Pindahkan meja**.
2. Pick an empty (`available` + `active`) target table, grouped by zone (`_zoneSection`, line 121).
3. If the target's capacity is below the source's pax, a warning icon shows but the move is still allowed (`overCapacity`, line 142) — the waiter decides.
4. Confirm in the dialog (`_confirmAndMove`, line 190) — title `mvtConfirmTitle`, body `mvtConfirmBody` (or `mvtConfirmOver` if over capacity).
5. On success the waiter lands on the target table's detail, already holding its lock.

**Under the hood** — `TablesRepository.moveTable()` (`lib/data/repositories/tables_repository.dart:726-778`) posts `POST /tables/:id/move` `{targetId, actorId, actorName}`. Server does it in one DB transaction: re-points every ticket's `tableId`, copies session fields (pax, openedAt, guestName/guestNotes, reservationId, readyCount, openAmount, lastActorId), wipes the source to `available` with locks cleared, broadcasts `tableUpdated` for both tables, and writes a `tableMoved` audit row.

**Offline behaviour** — Not queued; requires a live connection (no dev-mode fallback beyond the in-memory local emulation used when unpaired, lines 738-770).

**ADRs** — [ADR-0019](docs/adr/0019-move-table-session-transfer.md).

**Gotchas** — Target must be genuinely empty — a move is never a merge. Failure modes surface as specific toasts: `target_unavailable` → `mvtTargetOccupied`, `table_locked` → `mvtTableLocked`, `source_not_occupied` → `mvtSourceEmpty`. Because a `TableSession` snapshots only at close, per-table reports attribute the whole visit to the target; recovering "where did this party actually sit" needs the audit log.

## Table close (Selesaikan Layanan / Lepaskan Meja)

**What** — The waiter's floor act: detach the live Visit from its table and free it to `available`. Two labels for the same act depending on whether anything was ever ordered: **"Lepaskan Meja"** (release, no tickets) vs **"Selesaikan Layanan"** (finish service, tickets exist and are all terminal). Never confused with **Tutup tagihan** (bill close, the cashier's money act) — see CONTEXT.md.

**Who** — `takeOrder`.

**Where** — `table_detail_screen.dart`, `onClose()` (around line 509); labels computed as `closeLabel` (line 403-405).

**How to use**
1. From the table detail, the close button is enabled only when `!hasLive` — every ticket is terminal (served or voided) or none exist (`canClose`, line 401).
2. Confirm in a dialog; if tickets exist, an optional **"Cetak struk"** (print receipt) step is offered first, which prints without closing.
3. Confirm **Lepaskan Meja** / **Selesaikan Layanan** — calls `releaseTable()` (no tickets) or `closeTable()` (tickets, all terminal).
4. On success the waiter is popped back to the floor.

**Under the hood** — `TablesRepository.closeTable()` / `.releaseTable()` (`lib/data/repositories/tables_repository.dart:662-718`) call `POST /tables/:id/close` / `POST /tables/:id/release`. Server-enforced gate: every ticket terminal (`409 tickets_not_terminal` otherwise) and the table lock held.

**Offline behaviour** — Not queued — this is one of the writes that stays disabled under `readOnly` + no lease (`canClose = !readOnly && !hasLive`).

**ADRs** — [ADR-0024](docs/adr/0024-visit-decoupled-from-table-and-bill-close.md) (table close is one of the visit's two independent end-axes; the money side, bill close, is a cashier concern this document does not own).

**Gotchas** — Closing does **not** touch money and has no effect on the cashier — a closed-but-unpaid table's bill lives on, detached, flagged as a walkout on the cashier list until bill close. Never call this "Tutup meja" in copy — that phrase is reserved/ambiguous against bill close.

## Menu browse + cart

**What** — Browse the venue's menu by category, tap an item to configure it (variant/modifiers/course/note) via a bottom sheet, and build a cart. Serves four entry contexts: dine-in (`/table/:id/menu`), table-less draft (`/order/new`), takeaway (`/takeaway/:visitId/menu`), and counter mode's home tab (`/counter`).

**Who** — `takeOrder`.

**Where** — `lib/ui/features/menu/menu_screen.dart` (`MenuScreen`, line 48); view model `lib/ui/features/menu/view_models/menu_view_model.dart` (`MenuScreenState`, line 59); cart state `lib/ui/features/menu/view_models/cart_view_model.dart` (`CartViewModel`, `add()` line 16).

**How to use**
1. Open the menu from a table (`onAdd` → `context.push('/table/$id/menu')`), from **Pesanan baru** (`/order/new`), from a takeaway visit's **Tambah item**, or land on it directly as the `/counter` home tab.
2. Items are grouped by menu category; tap a card to open the modifier sheet (see below), or long-press to add with defaults straight to cart (`mnuAddItemHint`: "KETUK UNTUK ATUR · TEKAN LAMA UNTUK TAMBAH DEFAULT").
3. A card badges how many of that item are already in cart (qty overlay), and greys out with a killswitch mark when `Habis` (sold out).
4. Item order in the grid is a **derived rank** — items ranked by qty sold in the last 30 business days (excluding voided lines), frozen at screen mount; unranked items fall to the bottom alphabetically (ADR-0113).
5. Tap **Review** in the cart footer once items are added, to proceed to the review screen.

**Under the hood** — `CartViewModel.add()` **stacks identical lines** rather than appending duplicates: two lines are the same when `itemId`, `variantId`, `course`, trimmed `note`, and the *set* of `(groupId, optionId)` modifier keys all match (`CartItem.sameLineAs`, `lib/domain/models/cart_item.dart:79-85`) — tapping "nasi goreng pedas" three times yields one `×3` line, not three `×1` rows. `cartProvider` is a Riverpod `family` keyed by table id / draft uuid / takeaway visit id.

**Offline behaviour** — The cart itself is client-local and needs no connection to build; only *sending* it (via Review) touches the network/queue.

**ADRs** — [ADR-0060](docs/adr/0060-the-cart-stacks-identical-lines-and-lets-you-edit-them.md) (stacking + edit rule), [ADR-0061](docs/adr/0061-leaving-the-menu-discards-the-cart.md) (leaving discards, confirmed only if non-empty), [ADR-0113](docs/adr/0113-menu-order-is-a-derived-rank-frozen-at-mount.md) (grid order), [ADR-0026](docs/adr/0026-table-less-orders-menu-first-and-takeaway.md) (table-less/takeaway entry points).

**Gotchas** — Leaving the menu (back navigation) is a **discard**, not a stash — a non-empty cart raises a confirm sheet first, but there is no state where a cart usefully survives the screen that owns it (ADR-0061). The grid's rank is frozen at mount — a live stock flip (`menuUpdated`) does not re-sort a grid already on screen. Two surfaces deliberately ignore the popularity rank: the menu admin list and Menu tamu (guest page), which is out of this document's scope.

## Modifiers (item configure sheet)

**What** — A bottom sheet that configures one menu item before it joins the cart: variant (size), modifier groups (required/optional, single/multi-select), course (delivery timing), qty, and a free-text note.

**Who** — `takeOrder` (same gate as the menu screen it's opened from).

**Where** — `lib/ui/features/menu/modifier_sheet.dart` — top-level function around line 40; state class fields `_variantId`, `_selections`, `_course`, `_noteCtl` (lines 121-151).

**How to use**
1. Tap an item card on the menu grid.
2. Pick a variant if the item has more than one (required — this is the "Ukuran" group).
3. Answer each modifier group; a `required` group blocks Add until satisfied.
4. Optionally change the **Course** chip — which prep-timing bucket the line belongs to (drinks-now / starters / mains / sides / desserts / fire-now).
5. Optionally type a note (max length enforced; shown in red on the KDS per CONTEXT.md's Guest note rule).
6. Adjust qty with the stepper, tap **Tambah ke pesanan** (or **Pilih yang wajib** while invalid).

**Under the hood** — On confirm, builds a `CartItem` with `selectedModifiers: List<TicketModifier>` — a structured snapshot (`groupId`, `optionId`, `label`, `priceDelta`) frozen at add time so the KDS and reports never depend on the live menu later (ADR-0011, referenced by `TicketModifier`'s own doc comment, `lib/domain/models/ticket_modifier.dart:1-6`). Re-opening an already-cart item (edit) restores prior selections; an edited line keeps whatever course it already carries rather than recomputing a default.

**Offline behaviour** — Entirely client-local; nothing here touches the network.

**ADRs** — ADR-0011 (modifier snapshot — cited by code comment, not in the assigned ADR list; see `lib/domain/models/ticket_modifier.dart`), [ADR-0060](docs/adr/0060-the-cart-stacks-identical-lines-and-lets-you-edit-them.md).

**Gotchas** — A variant can be retired from the menu while a line sits in the cart — the sheet falls back to the item's first variant if the cart's chosen `variantId` no longer exists (`lib/ui/features/menu/modifier_sheet.dart:133-138`).

## Review & send

**What** — The pre-send confirmation screen: cart grouped by course, subtotal/estimate, a **Kirim pesanan** (or **Tambah ke pesanan**, for an already-sent table) action.

**Who** — `takeOrder`.

**Where** — `lib/ui/features/review/review_screen.dart` (`ReviewScreen`); routes `/table/:id/review`, `/order/new/review`, `/takeaway/:visitId/review`.

**How to use**
1. Arrive from the menu screen's **Review** button.
2. Read the grouped cart, with pills for kitchen/bar counts and any allergen flags; each course block notes whether it sends automatically (drinks-now/fire-now) or is held until fired.
3. Edit (**Ubah**) or remove (**Hapus**) a line inline, or go back to the menu to add more.
4. Tap **Kirim pesanan** (`revSendOrder`, or `revSendTo` "Kirim ke {target}" naming kitchen/bar/both) — becomes **Mengirim…** (`revSending`) while in flight.
5. **Table-less (Pesanan baru) only:** tapping send first opens a commit chooser sheet — **"Kirim pesanan ke"** (`revCommitTitle`): **Meja (dine-in)** or **Bawa pulang** (`_chooseCommit`, `review_screen.dart:460-502`).
   - Choosing **dine-in** opens `showAssignTableSheet` to pick an empty table + confirm pax/guest name, then seats it (`acquireLock: true`) and submits the draft cart against the newly seated table.
   - Choosing **Bawa pulang** opens `askTakeawayDetails` (guest name optional when the venue's `counterAnonTakeaway` switch is on) and mints a takeaway visit via `vm.submitTakeaway`.
6. On success, the app navigates to the **sent** screen (or, for table-less dine-in, `context.go('/table/$id/sent?...')` — a `go`, not `push`, dropping the draft menu/review stack).

**Under the hood** — `vm.submit()` / `vm.submitTakeaway()` call `SubmitOrderUseCase` (`lib/domain/use_cases/submit_order_use_case.dart:17-84`), which validates the cart is non-empty, mints a fresh idempotency key (`Uuid().v4()`), maps `CartItem → CartLineDto`, and calls `TicketsRepository.submitOrder()` / `.submitTakeawayOrder()`. That repository method (`lib/data/repositories/tickets_repository.dart:249-338`) posts `POST /orders` (server route `lib/server/routes/tickets_routes.dart:475`, gated `Capability.takeOrder`, line 476) with `{tableId, idempotencyKey, lines, actorId}`. On response, `ref.read(tablesProvider.notifier).seedCurrentVisit(tableId, res.visitId)` pre-seeds the table's visit id ahead of the WS echo, and `_reportRejected()` surfaces any per-line ingredient rejections as warnings (never silently dropped). If not `bypassKds`, the caller also marks the table `pending` client-side after a successful send.

**Offline behaviour** — `submitOrder()` checks `wsConnStateProvider != open` **before** attempting the POST (to avoid an 8s timeout tax) and enqueues via `_enqueueOrder()` onto the [[Antrean kirim]] (`SendIntentKind.submitOrder`) if so, or if the socket claimed open but the request never landed. A queued order returns `const []` for ticket ids (no navigation to a real ticket state until drain). A full send queue surfaces `sendQueueFull` as an error and rethrows rather than swallowing.

**ADRs** — [ADR-0026](docs/adr/0026-table-less-orders-menu-first-and-takeaway.md) (table-less commit flow), [ADR-0090](docs/adr/0090-an-offline-order-is-an-intent-not-a-row.md) (offline capture), [ADR-0060](docs/adr/0060-the-cart-stacks-identical-lines-and-lets-you-edit-them.md).

**Gotchas** — With `bypassKds` (no prep queue) on, `submitOrder` writes lines straight to `ready` server-side and stamps `readyAt` at send — the client must **not** overwrite that by posting `pending` afterward, or it hides already-finished food behind "Pesanan masuk" (see comment at `review_screen.dart:395-398`). A rejected line (out of stock) is reported per-line — the rest of the order still goes through.

## Sent confirmation

**What** — A brief post-send screen confirming the order reached the kitchen/bar, station-by-station.

**Who** — `takeOrder` (same gate as the flow it completes).

**Where** — Route `/table/:id/sent?stations=...`; screen `lib/ui/features/sent/sent_screen.dart` (`SentScreen`, line 18).

**How to use** — Automatic: lands here after a successful send. Title **"Terkirim"** (`sntTitle`); body reads `sntBody` ("Pesanan Meja {table} sudah live di display dapur dan bar") normally, or `sntBodyNoPrep` ("...sudah siap diambil") when `bypassKds` skips the kitchen queue entirely.

**Under the hood** — Purely presentational; the `stations` list rides as a query param (comma-separated, defaulting to `Dapur`) from the review screen's send call.

**ADRs** — none specific; downstream of [ADR-0115]/[[Tanpa antrian persiapan]] for the no-prep-queue variant (not in the assigned ADR set — see CONTEXT.md).

## Pesanan board (orders)

**What** — The waiter's live line-level view of what the kitchen is doing: three buckets — **Siap diambil** (ready to run), **Disiapkan** (in progress), **Selesai** (done) — each split into dine-in and Bawa pulang sections. Distinct from the Floor (tables, not lines) and the KDS (the kitchen's own queue, out of this document's scope).

**Who** — `takeOrder`.

**Where** — Route `/orders` (`lib/router/app_router.dart:319`); screen `lib/ui/features/orders/orders_screen.dart` (`OrdersScreen`, line 31).

**How to use**
1. From the shell's bottom tab (phone) or side rail (tablet), open **Pesanan**.
2. Toggle scope: **Milik saya** / **Semua** — session-scoped, not device-local (snaps back to "Milik saya" on every PIN sign-in).
3. Read the three segmented buckets; tap a row to jump to its table (or takeaway visit).

**Under the hood** — Scoped to the signed-in user per ADR-0056: a row is "yours" when you handle its table (`lastActorId`), or you authored the line (`createdBy`), or nobody owns it (shown to everyone rather than no one). **Siap diambil is always venue-wide** regardless of the scope switch — the ready alert already sounds for everyone, so hiding a ready plate from other waiters would hide a shared problem. `lastActorId` is written by exactly five ops: seat, mark pending, move, explicit handover, and submitting tickets — deliberately *not* by viewing, lock acquire, a pax correction, or clearing a ready plate (running a colleague's food to the pass is help, not a takeover).

**ADRs** — [ADR-0056](docs/adr/0056-pesanan-board-scoped-to-the-table-you-handle.md).

**Gotchas** — An empty board under "Milik saya" does not mean the kitchen is quiet — check "Semua" before concluding that. There is currently no UI that calls the explicit handover endpoint (`PATCH /tables/<id>/handler`) — a wrongly-attributed handler is only correctable by re-seating.

## Fire a held course

**What** — Send a `held` course (one deliberately delayed at order time, e.g. desserts) to the kitchen now, on demand.

**Who** — `takeOrder` for the fire action itself (advancing `held → sent` costs `Capability.takeOrder` per the transition graph below); the KDS side (`sent → prep/cooked`) costs `viewKds` and is out of scope here.

**Where** — Table detail screen, course header action **"Bakar {course}"** (`tblFireCourse`); `fireCourse()` at `table_detail_screen.dart` (~line 489).

**How to use** — On a table with a held course, tap the course's fire action; it advances every `held` line in that course to `sent` at once.

**Under the hood** — `TicketsRepository.fireCourse()` (`lib/data/repositories/tickets_repository.dart:718-761`) posts `POST /tables/:tableId/course/:course/fire` (server: `lib/server/routes/tickets_routes.dart:940`, gated `takeOrder`, line 945), which the server does authoritatively and returns the updated ticket rows to merge locally.

**ADRs** — [ADR-0071](docs/adr/0071-kitchen-ownership-freezes-a-line.md) (firing hands kitchen ownership; the prep clock starts at fire, not at original send — this is the boundary that makes post-fire edits illegal, see below).

**Gotchas** — Once fired, a line is frozen from the kitchen's point of view (ADR-0071) — the only remedies past that point are advance or void, never edit.

## Ticket transitions (advance / serve / unserve)

**What** — The canonical ticket status graph, shared verbatim between client and server, with the capability each move costs baked into the same table (ADR-0101).

**Who** — Per-move, per `ticketTransitions`:

| from → to | capability |
|---|---|
| `draft`/`acknowledged` → `voided` | `voidItem` |
| `sent` → `prep` / `cooked` | `viewKds` |
| `sent` → `voided` | `voidItem` |
| `held` → `sent` | `takeOrder` |
| `held` → `voided` | `voidItem` |
| `prep` → `cooked` | `viewKds` |
| `prep` → `voided` | `voidItem` |
| `cooked` → `ready` | `viewKds` |
| `cooked` → `voided` | `voidItem` |
| `ready` → `served` | `takeOrder` |
| `ready` → `voided` | `voidItem` |
| `served` → `ready` (undo) | `takeOrder` |
| `served` → `voided` (i.e. a comp) | `compItem` |

**Where** — `lib/domain/models/ticket_transitions.dart:23-57` (the one table — `canTransition()` line 60, `capabilityForTransition()` line 65). Client entry point: `AdvanceTicketStatusUseCase.call()` (`lib/domain/use_cases/advance_ticket_status_use_case.dart:21-53`), which re-checks legality client-side before calling `TicketsRepository.transition()` (`POST /tickets/:id/transition`).

**How to use** — Mark served (`markServed`), unserve (`unserve` — walks `served` back to `ready`), or toggle a KDS line cooked (`toggleCooked`, batches every line sharing a `sentAt` to `ready` once all are `cooked`) — all from the table detail's line-item actions or the KDS screen.

**Under the hood** — Server route `POST /tickets/<id>/transition` (`lib/server/routes/tickets_routes.dart:766`) re-derives `capabilityForTransition(from, to)`, answers `409 illegal_transition` if the move has no row in the table, then `_requireCap` (line 786). Speed-of-service stamps are set here too: `readyAt` set-once on first entry to `ready`, `servedAt` last-write, `firedAt` stamped exactly on `held → sent`.

**ADRs** — [ADR-0101](docs/adr/0101-a-transition-and-its-capability-are-one-table.md) — a legal move with no row nobody exercises (`draft → sent`, `acknowledged → prep`, `sent → held`) is intentionally absent, not a bug; a writer that appears for one of those needs its row (with capability) added.

**Gotchas** — `voided` is terminal — `ticketTransitions[TicketStatus.voided]` is an empty map; there is no un-void.

## Void an item (Batalkan item)

**What** — Removing a sent ticket line from an order, pre-serve, on the waiter's own authority — no manager PIN. Voiding an already-**served** line is a comp, gated by `compItem` instead, because that is a different power (giving something away vs correcting a mistake).

**Who** — `voidItem` (pre-serve: `sent | held | prep | cooked | ready`); `compItem` (post-serve, i.e. `served → voided`).

**Where** — `lib/ui/features/void_flow/line_item_action_sheet.dart` — `showLineItemActionSheet()` (line 53), reason picker `_VoidReasonList` (line 610).

**How to use**
1. From a line in the table detail (or takeaway detail), open its action sheet — offers Bakar sekarang / Ubah item / Batalkan sajian / **Batalkan item** depending on state.
2. Tap **Batalkan item** (`liaVoidItem`). A reason list appears: **Terkirim salah** (wrong order), **Tamu berubah pikiran** (customer change), **Stok habis** (out of stock), **Komplain / kualitas** (kitchen error), and — only on an already-served line — **Kompensasi manajer** (comp), plus **Lainnya** (other) always last.
3. `other` requires typed free text (min 3 chars); every other code needs none.
4. Tap the primary button (still labelled **Batalkan item**) to commit.
5. On success: **"Item dibatalkan"** with either `liaVoidedNote` (delivered) or `liaVoidedQueued` (captured on this device only, dapur belum tahu — see Offline below).
6. On failure: an inline **"Item tidak dibatalkan"** view names the reason (`voidFailureText`) with a **Back** button to the reason list — never a silently-stuck sheet.

**Under the hood** — `TicketsRepository.voidTicket()` calls `transition(..., TicketStatus.voided, voidReason:, voidReasonCode:)`, which posts `POST /tickets/:id/transition {status: 'voided', voidReason, voidReasonCode, actorId}`. Server (`lib/server/routes/tickets_routes.dart:786-816`) requires a non-empty `voidReasonCode` always, and non-empty `voidReason` text **only** when the code is `other` (`needsText = voidReasonCode == 'other'`) — demanding text for every code was the bug ADR-0114 fixed (it had silently 400'd four of five reasons for months). The server stamps `voidedByUserId` from the bearer (or a replay's carried `actorId`) for per-waiter void-rate reporting.

**Offline behaviour** — Void is one of exactly two ticket moves with an offline path (the other being submit order). A `terputus` handset parks it as `SendIntentKind.voidTicket` on the [[Antrean kirim]] — real on that device, invisible to the kitchen until drain. Its refusal (e.g. `403` — role lacks `voidItem`, or line needs `compItem`) is a **business refusal that must not stall the drain**, unlike other queued intents — see ADR-0114.

**ADRs** — [ADR-0006](docs/adr/0006-self-served-void-with-per-waiter-accountability.md) (self-served + per-waiter accountability, replacing manager-PIN theatre), [ADR-0114](docs/adr/0114-a-void-is-a-code-and-can-be-captured-offline.md) (the code/text contract fix + offline capture).

**Gotchas** — A comp is **not** a separate entity — it *is* a void with reason code `comp`, gated by `compItem`. `AuditType.comp` exists in the enum but is emitted by nothing; any "comps" figure in reports is derived from the void reason, never counted separately. Reason codes are persisted strings under the never-rename rule — `wrongOrder`, `customerChange`, `outOfStock`, `kitchenError`, `comp`, `other`. There is no undo — `voided` is terminal; the reason picker is the only safety net.

## Edit a sent (held) line

**What** — `PATCH /tickets/<id>` lets qty, note, unit price, and modifiers change on a line that hasn't been fired to the kitchen yet.

**Who** — `modifyOrder` (`lib/server/routes/tickets_routes.dart:636`).

**Where** — `TicketsRepository.modifyLine()` (`lib/data/repositories/tickets_repository.dart:622-669`), reached from the void-flow sheet's **Ubah item** (`liaEditItem`) action.

**How to use** — From a `held` line's action sheet, tap **Ubah item**, adjust qty/note/modifiers in the (re-opened) modifier sheet, confirm.

**Under the hood** — The client optimistically updates local state after a successful `PATCH`; this is a **request, not a local mutation with sync-after** — the server can reject anything past `held` with `409` (kitchen ownership freeze).

**ADRs** — [ADR-0071](docs/adr/0071-kitchen-ownership-freezes-a-line.md).

**Gotchas** — Only a `held` line is editable — once fired the cook's copy *is* the order (ADR-0071); the only remedies after that are advance or void, never edit, deliberately (no "propose a change" negotiation protocol was built — considered and rejected as a worse failure mode than a re-key).

## Takeaway (Bawa pulang)

**What** — A table-less order that never occupies a floor table: a `Visit` with `kind == takeaway`, keyed by a daily running number (`"Bawa pulang #N"`), guest-name-identified, `pax = 0`, with an explicit **handover** act replacing table-close in its end-of-visit lifecycle.

**Who** — `takeOrder`.

**Where** — Route `/takeaway/:visitId` (`lib/router/app_router.dart:419`); screen `lib/ui/features/takeaway/takeaway_detail_screen.dart` (`TakeawayDetailScreen`, line 28). Created via the Floor's **Bawa pulang** trigger (`lib/ui/features/tables/widgets/takeaway_surface.dart`) or via the table-less review screen's commit chooser (see Review & send above).

**How to use**
1. From the Floor, tap **Bawa pulang**, or reach it via a table-less draft's commit sheet.
2. Fill guest name (required unless the venue's `anonTakeaway` counter switch is on), channel (`bungkus` walk-in-pickup / `telepon` / `gofood` / `grab`), and whether it's prepaid.
3. Add items via **Tambah item** (opens the menu at `/takeaway/:visitId/menu`).
4. Track items on the detail screen — `tkwItemCount` badge, `tkwEmpty` when nothing's added yet.
5. Once every item is `served` (or `voided`), tap **Serahkan** (`tkwHandover`) — blocked with `tkwHandoverBlocked` until then.
6. After handover, the card shows `tkwHandedOverTag` ("SUDAH DISERAHKAN") and `tkwHandedOver` ("Sudah diserahkan ke tamu.").

**Under the hood** — Server `createTakeawayVisit()` (`lib/server/routes/tables_routes.dart:137-202`) mints a `Visits` row with `tableId: ''`, `kind: 'takeaway'`, a `tableLabel` of `"Bawa pulang #N"` from a per-business-day `DailyCounters.takeawayNext` counter (anchored to `businessDayStartHour`, not raw midnight), `channel` validated against `_takeawayChannels`, and `prepaid`. Order submission reuses the same `POST /orders` path with a takeaway visit id instead of a table id (`SubmitOrderUseCase.takeaway()`, `lib/domain/use_cases/submit_order_use_case.dart:40-60`). Handover: `POST /visits/:id/handover` (`lib/server/routes/tables_routes.dart:1463`, gated `takeOrder`), reusing the same "all tickets terminal" gate as dine-in table-close.

**Offline behaviour** — Same order-submit queueing as dine-in (ADR-0090); a takeaway visit holds **no table lock** at all (ADR-0026), so there is no lock-related offline distinction to make here.

**ADRs** — [ADR-0026](docs/adr/0026-table-less-orders-menu-first-and-takeaway.md) (the whole feature), [ADR-0024](docs/adr/0024-visit-decoupled-from-table-and-bill-close.md) (the two-axis end-of-visit model this reuses, handover standing in for table-close).

**Gotchas** — Takeaway is deliberately **not** a pseudo-table (a table holds exactly one attached visit — concurrent takeaways would collide) and **not** a separate entity duplicating the bill/receipt stack — it's a `Visit.kind` flag reusing everything ADR-0024 already built. Reports exclude takeaway from per-cover/turn-time/occupancy metrics but count it in total sales, menu classification, and void/comp.

## Table-less draft orders (Pesanan baru)

**What** — Build a cart with no table bound yet (menu-first), then bind it at commit time to either a dine-in table or a takeaway visit. The cart stays client-local and invisible to any other device until that commit.

**Who** — `takeOrder`.

**Where** — Route `/order/new` (`lib/router/app_router.dart:395-414`), triggered from the Floor's **Pesanan baru** button (`_NewOrderButton`, `lib/ui/features/tables/tables_screen.dart:449`). Cart key: the transient `draftOrderIdProvider` uuid.

**How to use**
1. From `/tables`, tap **Pesanan baru** — opens the menu with no table context.
2. Build the cart exactly as in the dine-in flow.
3. Tap **Review** → **Kirim pesanan**, which opens the commit chooser sheet described in "Review & send" above: **Meja (dine-in)** (via `showAssignTableSheet`) or **Bawa pulang** (via `askTakeawayDetails`).

**Under the hood** — Same `MenuScreen`/`ReviewScreen` widgets as the table-bound flow, parameterized `tableless: true`. Dine-in commit calls `POST /tables/:id/seat` then `POST /orders` in sequence — no dedicated server entity for the table-less draft itself; it's a client-side-only concept until bound.

**ADRs** — [ADR-0026](docs/adr/0026-table-less-orders-menu-first-and-takeaway.md).

**Gotchas** — `AssignTableSheet` only lists `available` + `active` tables (`lib/ui/features/tables/widgets/assign_table_sheet.dart:66-75`) — same target rule as move-table's picker, with the same soft over-capacity warning rather than a hard block.

## Counter mode menu-home (Kedai)

**What** — For a venue configured as a **Kedai** (one person takes, makes, and takes payment for the order — a counter shop rather than a four-role floor), the app's home tab becomes the menu itself instead of the table grid.

**Who** — `takeOrder`, gated the same way as any menu access; the mode switch itself is set by the fleet operator, not the venue owner, at onboarding (not a settings toggle in `Pengaturan`).

**Where** — Route `/counter` (`lib/router/app_router.dart:309-318`), mounted **inside** the `ShellRoute` (unlike the table-bound and table-less menu routes, which are root-navigator pushes) — so the shell's rail/tab bar survives it. `counterHome(ref, auth)` (`lib/router/app_router.dart:167-170`) decides: `venueSettingsProvider.counterOn(counterMenuHome)` AND `auth.has(Capability.takeOrder)`.

**How to use** — Nothing to configure client-side; when the venue's `menuHome` switch (`counterMenuHome = 'menuHome'`, `lib/domain/models/venue_module.dart:85`) is on, signing in lands directly on `/counter` instead of `/tables`, and any stale redirect toward `/tables` bounces back to `/counter` (`app_router.dart:265-267`).

**Under the hood** — `/counter`'s builder is literally `MenuScreen(tableId: draftOrderIdProvider, tableless: true, inShell: true)` — the **same** cart key and screen as `/order/new`, deliberately: "a counter has one order pad, and a second draft flow with its own cart is how an order gets typed twice" (comment at `app_router.dart:304-308`). The venue-wide preset is a set of independent switches (`menuHome`, `anonTakeaway`, `settleAfterSend`, `simpleKds`, `counterQr`, `ringkasReport`) stored in `counterConfig`; ticking the `counterService` module writes all six on, and the operator unticks what a given shop doesn't need.

**ADRs** — Not in the assigned reading list, but load-bearing per CLAUDE.md's "Counter mode is a preset of switches, and its key fails closed" (ADR-0109) and "A venue may have no prep queue" (ADR-0115, the related `bypassKds` mode key that changes `submitOrder`'s born status to `ready`).

**Gotchas** — `counterService` **fails closed** — absent, null, or never-mirrored all read as "restaurant" (unlike the sellable `hasModule` resolver, which fails *open*). `menuHome` is a **switch** (default/layout only — it may never branch a writer); `bypassKds` is a separate **mode key** that *can* branch a writer (`submitOrder`'s born status) and is independent of Kedai — a counter shop may still run a cook line, and a small restaurant may have none. `/tables` and everything the floor writes stay legal and written even when hidden — unticking `menuHome` finds a venue's tables exactly as left.

## Zones (context for the Floor)

**What** — The organizing dimension for the table grid: each `VenueTable` belongs to one `Zone` (e.g. Teras, Dalam, VIP). Zone *administration* (create/rename/reorder/delete) is the admin `/floor` (Floor configuration) screen, out of this document's scope — this section covers only what the ordering flow reads.

**Who** — Read access only needs `takeOrder`; zone editing needs `editSettings` (admin scope).

**Where** — `lib/data/repositories/zones_repository.dart`; domain model `lib/domain/models/zone.dart`.

**Under the hood** — `TablesScreen` groups the active-table set by `zoneId` and sorts zone tabs in `zonesProvider` order; every table/reservation/move-target picker in this document sorts its list by zone index first, then table display name (see `assign_table_sheet.dart:70-75`, `move_table_sheet.dart:62-67`).

**Gotchas** — None specific to the ordering flow beyond: a zone with zero active tables (`_EmptyZone`) is a normal, handled state, not an error.
