# 02 · Kitchen (KDS) & the ticket lifecycle

Covers the Main Device's prep queue — called **Antrian Persiapan** ("Dapur"/"Kitchen" is a banned screen name, CONTEXT.md — Dapur is one *station*, not the screen) — the canonical `TicketStatus` transition graph shared by server and client, courses and course-fire pacing, per-item and per-venue ready targets and lateness, the kitchen-ownership freeze on a sent line, the ready alert (banner/toast) and the venue-wide alert-sound system, and the two mode keys that reshape or remove the prep queue (**simple KDS**, one queue with no station split, and **Tanpa antrian persiapan** / "no prep queue", which removes it entirely). There is no in-app screen literally named "Kitchen" or "Dapur" — the settings that shape the queue live on `/alerts` (thresholds + sounds) and on the menu item editor (per-item ready target); the two mode keys are cloud-set on the fleet console, not in venue Pengaturan.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| KDS board (Antrian Persiapan) | `/kitchen` | `viewKds` | `GET /tickets`, `POST /tickets/<id>/transition` |
| Ticket transition graph | *(embedded — no own route)* | varies per move, see table below | `POST /tickets/<id>/transition` |
| Courses & fire-course | `/table/:id` | `takeOrder` | `POST /tables/<tableId>/course/<course>/fire` |
| Kitchen ownership freeze (edit a held line) | `/table/:id` (line item sheet) | `modifyOrder` | `PATCH /tickets/<id>` |
| Prep targets & lateness (thresholds) | `/alerts` | `editSettings` | `PATCH` via `venueSettingsProvider` (`VenueSettings.prepTargetMins` etc.) |
| Per-item ready target ("Waktu siap") | `/menuadm/:id` | `editMenu` | menu item route (`MenuItems.prepTime`) |
| Ready alert (banner + toast) | *(global overlay, `AlertHost` in `app.dart`)* | — (read-only) | WS `ticket.updated`/`ticket.created` |
| Alert sounds + device mute | `/alerts` | `editSettings` (device mute needs none — device-local) | `PATCH` venue settings; device mute is `prefs`-only |
| Simple KDS / Tanpa antrian persiapan (mode keys) | *(fleet console only — `venue_edit_screen.dart`)* | fleet operator, not a venue `Capability` | mirrored to `venue_settings.modules`/`counter_config` |
| KDS station pairing status | `/system` (Sistem → Operasional) | `editSettings`/admin | `GET` via `kdsStationsProvider` (Devices table) |

## KDS board (Antrian Persiapan)

**What** The Main Device's live prep queue: every sent (or fired) kitchen-station ticket, grouped into **batches** and shown oldest-first, with a tap-to-advance flow (`sent → prep → cooked → ready`) per item.

**Who** Kitchen staff (`viewKds` capability) — normally the Server-mode device on the pass.

**Where** `/kitchen`, inside `ShellRoute` (`AppShell`). Gated `viewKds` (`lib/router/app_router.dart:58`).

**How to use**
1. Open **Antrian Persiapan** (`context.l10n.kitchenQueueTitle`). Each card is one **batch** — the tickets one table sent together in one go, identified by `(table, sentAt)`.
2. Tap an item row to advance it. `KitchenViewModel.toggleCooked` (`lib/ui/features/admin/kitchen/view_models/kitchen_view_model.dart:55`) walks a single line `sent → prep → cooked → ready` in one tap — a cook does not tap three times per dish.
3. Toggle **"Tampilkan order selesai"** (`kitShowDone`, the `_CompletedFilter` chip) to reveal completed batches (`ready`/`served`) alongside active ones.
4. A late tally in the header (`_LateTally`) counts how many visible batches are past their target — a card scrolled off-screen still counts.
5. Empty queue shows `kitEmptyBody` ("Semua pesanan dapur sudah selesai dimasak.").

**Under the hood**
- `lib/ui/features/admin/kitchen_screen.dart` — `KitchenScreen` widget; phone gets a flat `ListView`, tablet an `AdminPage` `Wrap` of 360px cards (`context.layout.useTabletShell`).
- `lib/ui/features/admin/kitchen/view_models/kitchen_orders.dart` — `kitchenOrdersProvider` builds the actual list via `buildKitchenOrders` (pure function, tested in `test/kitchen_orders_build_test.dart`). Recomputes on ticket changes, the venue target, per-item prep overrides, the completed-filter, and once a minute (`minuteTickerProvider`, ADR-0081) — not on a 1s screen timer.
- `lib/ui/features/admin/kitchen/kitchen_order.dart` — `KitchenOrder` (one card's data) and `kitchenLineDone` (`cooked`/`ready`/`served`).
- Visibility sets: `_kitchenInProgress = {sent, prep, cooked, ready}` (ready stays visible so a just-finished item still shows struck-through, not vanished one at a time) and `_kitchenCompleted = {ready, served}` (shown only under the completed filter).
- `KitchenViewModel` (`lib/ui/features/admin/kitchen/view_models/kitchen_view_model.dart`) is the older card grouping used by `kitchenNewOrderCountProvider` (Antrian nav badge — count of batches still holding an untouched `sent` line) and `kitchenQueueLiveProvider` (any line still `sent`/`prep`/`cooked` — read by the shell so turning **Tanpa antrian persiapan** on mid-shift doesn't strand lines already cooking, ADR-0115).
- `KitchenViewModel.toggleCooked` and `_OrderCard`'s tap handler both route every status change through `AdvanceTicketStatusUseCase`, never a direct repository call — so server, repository and KDS converge (docstring at `kitchen_view_model.dart:49`).
- Card colour tiers: `late` (age ≥ `targetMins`) tints the whole card `urgentSoft`/`urgent` border; `warn` (age ≥ `0.7 × targetMins`, `kKitchenWarnFraction`) tints `warn`. A `complete` batch is **never** late and renders its frozen time in `success`.
- Under **simple KDS** (`counterOn(counterSimpleKds)`), `_OrderCard` passes an empty `courses` list to `_CardHead` — the course chip row disappears because with one pace it is the same word on every card (`kitchen_screen.dart:344`).

**Offline behaviour** The KDS is server-local — the queue lives on the Main Device's own DB and needs no network round trip. No offline path of its own: transitions always go through the ordinary `POST /tickets/<id>/transition`, and only a **void** (of the six moves) is ever offline-capturable (see below), because the KDS is the authority a queued `prep`/`cooked`/`ready` would be lying to.

**ADRs** 0008 (dual `sentAt`/`sentAtTime`), 0013 (lifecycle timestamps + service target), 0043 (per-item target + course-as-unit-of-late), 0081 (two tickers: readout vs threshold — the board recomputes on a minute ticker, not per-second), 0115 (Tanpa antrian persiapan hides the KDS slot but the queue survives draining).

**Gotchas**
- `KitchenScreen`'s batch freeze logic is load-bearing: a batch's counter freezes once *every* line is `cooked`/`ready`/`served`, at the *last* line's `readyAtTime`. If a done line is missing that stamp (only reachable from seeded/demo data — `toggleCooked` always passes through `ready`), the board remembers a **fallback freeze** the first time it sees the batch complete (`kitchenFallbackFreezeProvider`, deliberately not `autoDispose` — see the doc comment at `kitchen_orders.dart:32` for why a re-mount must not re-freeze at a new time).
- `KitchenCard.done` (the older view model) counts `TicketStatus.cooked` only; `KitchenOrder.done` (the one the screen actually renders) counts `kitchenLineDone` — cooked, ready **or** served. Do not mix the two when reading "done" off a card.

## The `TicketStatus` transition graph

`TicketStatus` (`lib/domain/models/ticket.dart:16`): `draft, acknowledged, sent, prep, cooked, ready, served, held, voided`. `draft` and `acknowledged` exist for a future queued-dispatch backend and are never written by anything today (`draft → sent` and `acknowledged → prep` have no writer). The live lifecycle is `sent → prep → cooked → ready → served`, with `held` for course pacing and `voided` as the terminal failure state.

`ticketTransitions` (`lib/domain/models/ticket_transitions.dart:23`) is the **one** table naming both what moves are legal *and* what capability each costs (ADR-0101). A key's presence makes the move legal; there is no separate switch to forget an arm in.

| From | To | Capability |
|---|---|---|
| `draft` | `voided` | `voidItem` *(no writer today — see above)* |
| `acknowledged` | `voided` | `voidItem` *(no writer today)* |
| `sent` | `prep` | `viewKds` |
| `sent` | `cooked` | `viewKds` *(a line may skip `prep` when a dish needs no staging)* |
| `sent` | `voided` | `voidItem` |
| `held` | `sent` | `takeOrder` *(the course-fire move)* |
| `held` | `voided` | `voidItem` |
| `prep` | `cooked` | `viewKds` |
| `prep` | `voided` | `voidItem` |
| `cooked` | `ready` | `viewKds` |
| `cooked` | `voided` | `voidItem` |
| `ready` | `served` | `takeOrder` |
| `ready` | `voided` | `voidItem` |
| `served` | `ready` | `takeOrder` *(the canonical undo of a premature serve — "Batalkan sajian")* |
| `served` | `voided` | `compItem` *(voiding an already-served line is a comp, a manager power, ADR-0006)* |
| `voided` | — | *(terminal — empty map)* |

`canTransition(from, to)` and `capabilityForTransition(from, to)` (both in `ticket_transitions.dart`) are the two pure functions every caller reads. Both the client `AdvanceTicketStatusUseCase` and the server route `POST /tickets/<id>/transition` (`lib/server/routes/tickets_routes.dart:766`) re-check the same table — the client refuses before dialing, the server refuses (`409 illegal_transition`) if it disagrees.

**Under the hood**
- `AdvanceTicketStatusUseCase` (`lib/domain/use_cases/advance_ticket_status_use_case.dart:21`) — throws `IllegalTicketTransition` locally if `canTransition` says no, otherwise delegates to `TicketsRepository.transition`. **Every** UI ticket mutation (KDS, table detail "mark served"/"unserve", the line item action sheet's fire/serve/void) goes through this use case.
- `TicketsRepository.transition` (`lib/data/repositories/tickets_repository.dart:488`) posts `{status, voidReason?, voidReasonCode?, voidApprovedBy?}` to `POST /tickets/<id>/transition`, then applies the same change optimistically to local state. Returns `true` only when the move was captured on the send queue instead of delivered.
- Server-side, `POST /tickets/<id>/transition` (`tickets_routes.dart:766`) re-derives `needed = capabilityForTransition(from, to)`, 409s if null, `_requireCap`s the caller, stamps `firedAt`/`readyAt`/`servedAt` as appropriate (see next section), maintains `VenueTable.readyCount`/`status` atomically in the same transaction, broadcasts `ticketUpdated` (+ `tableUpdated` if the table row changed), and calls `syncVisitMoney` (void/serve change the bill subtotal).
- A void additionally requires `voidReasonCode` non-empty, and `voidReason` free text **only** when the code is `other` (ADR-0114, amending ADR-0006 — demanding text for every code used to 400 four of the five reasons the picker offers).

**Offline behaviour** Only `voided` is queueable. `TicketsRepository.transition` checks `to == TicketStatus.voided` and, while `wsConnStateProvider != open`, parks the void on the send queue (`SendIntentKind.voidTicket`, keyed `void-<ticketId>` so repeated taps dedupe) instead of attempting the request — the same pre-check `submitOrder` makes, so a waiter mid-rush doesn't pay an 8s `requestTimeout` on a dead socket. Every other move (`prep`, `cooked`, `ready`, `served`, fire) has **no** offline path: a queued `prep` would replay a kitchen fact minutes after it stopped being true. If the socket claimed `open` but the request still failed to land, a void additionally falls back to the queue from the `catch` branch; any other move's exception simply rethrows.

**ADRs** 0006 (self-served void, per-waiter accountability; comp needs `compItem`), 0090 (Antrean kirim — the offline write queue a void rides), 0101 (transition+capability as one table), 0114 (void reason is a code; free text only for `other`; void is the one offline-capable transition).

**Gotchas**
- `KitchenViewModel.toggleCooked` walks `sent → prep → cooked → ready` in three sequential `useCase.call`s — if the caller does not await correctly, a rapid double-tap could race two in-flight transitions on the same line. The use case itself is stateless per call, so the repository's local `state = next` write is what actually serializes.
- `capabilityForTransition` returns `null` for an illegal move — always check for null before dereferencing the capability (the client gate reads it exactly this way in `line_item_action_sheet.dart:453` to decide whether to render the void row enabled).

## Kitchen ownership freezes a line (ADR-0071)

**What** Once a line is fired (any status past `held`), the cook's copy **is** the order — the sole remedy is a void with a reason. `held` (unfired, course-pending) is the only status a line's qty/note/modifiers/price may still change on.

**Who** Waiter (`modifyOrder` capability) editing a course before firing it.

**Where** The line item action sheet on `/table/:id`, "Ubah item" (`liaEditItem`) row — offered only when `ticket.status == TicketStatus.held`.

**How to use**
1. Open a table with an unfired course (`held` items).
2. Tap the line → the action sheet offers **Bakar sekarang** ("fire now") and **Ubah item** ("edit item" — "Jumlah, catatan, dan pilihan · sebelum masuk dapur").
3. Editing re-books stock from scratch (`untouched: true` — safe because nothing was cooked yet) and writes an audit row (`AuditKind.modify`/`modifyQty`) with the before/after value.
4. Once fired, only **Batalkan** (void) remains for that line; the server enforces this with a `409 line_frozen` even if the UI is bypassed.

**Under the hood**
- `PATCH /tickets/<id>` (`tickets_routes.dart:635`) rejects with `409 {code: 'line_frozen'}` unless `ticketStatusFromKey(current.status) == TicketStatus.held`. Variant is deliberately **not** editable (a different variant is a different dish, often a different station) — only qty, note, modifiers, and the resolved unit price.
- Requires `Capability.modifyOrder`.

**ADRs** 0071 (defines the editable window and retires "refire" as a concept — accept/reject proposal UI was prototyped and rejected as a two-party negotiation nobody asked for).

**Gotchas** A held line the client renders as editable can still 409 if another device fired it between render and tap — the sheet does not lock the line.

## Courses & course-fire pacing

**What** A course (`CourseId`: `drinksNow, starters, mains, sides, desserts, fireNow`) is a pacing group. `drinksNow` and `fireNow` lines are sent straight to `sent` at order time; every other course is born `held` and stays there until the waiter fires it, so mains don't hit the pass before starters are cleared.

**Who** Waiter (`takeOrder`).

**Where** `/table/:id` — per-course "Bakar {course}" button (`_FireButton`, shown when every item in that course block is `held`) and, when reviewing a single line, the action sheet's "Bakar sekarang".

**How to use**
1. Send an order containing a `mains` or `sides` line — it lands `held`, badged `{n} item · ditahan` (`tblItemCountHeld`) instead of the ordinary `{n} item`.
2. Tap **BAKAR {COURSE}** on that course's block (`_FireButton`, `table_detail_screen.dart:1129`) to fire every held line in that course at once, or fire a single held line from its own action sheet.
3. Firing flips every `held` line of that `(tableId, course)` pair to `sent` in one server write, sharing one identical `firedAt` timestamp — which is what groups them as one course for lateness purposes.

**Under the hood**
- Client: `TicketsRepository.fireCourse` (`lib/data/repositories/tickets_repository.dart:718`) — online, `POST /tables/<tableId>/course/<key>/fire`; offline (`apiConfigProvider == null`, i.e. unpaired), `_fireCourseLocal` flips matching `held` rows to `sent` in local state directly (this is a different offline path than the send-queue one — it only fires when the device has never paired, not when a paired device loses the socket).
- Server: `POST /tables/<tableId>/course/<course>/fire` (`tickets_routes.dart:940`) — `Capability.takeOrder`. One `UPDATE … WHERE tableId = ? AND course = ? AND status = 'held'` sets `status: 'sent', firedAt: now` for every matching row, so every line of the course shares one `firedAt`. Broadcasts `ticketUpdated` per fired row and calls `syncVisitMoney` (firing grows the bill).
- `sendOrder` (`tickets_repository.dart:676`) is where the birth status is decided client-side (mirrored server-side in `submitOrder`): `fireNow`/`drinksNow` → `sent`; everything else → `held` — **unless** the venue is running **Tanpa antrian persiapan** (`bypassKds`), in which case every line is born `ready` with `readyAtTime` stamped at send, regardless of course (see the mode-keys section below).

**Offline behaviour** Fire-course has **no** send-queue path — it announces a kitchen fact the queue cannot safely replay (same reasoning as `prep`/`cooked`/`ready`). The line item sheet hides both "Bakar sekarang" and "Ubah item" while `wsConnStateProvider != open` (`line_item_action_sheet.dart:400`); the table screen's per-course fire button has no equivalent explicit offline guard beyond `readOnly`/`canQueueWrite` gating on the surrounding screen.

**ADRs** 0043 (per-item ready target and course-as-unit-of-late; `firedAt` is the supporting fix so a course held 40 minutes is not born overdue).

**Gotchas** `_fireCourseLocal`'s local-fallback path only runs when `apiConfigProvider == null` (device never paired) — it is not the terputus (lost-socket) offline path; a paired-but-disconnected device's fire call will simply fail/rethrow rather than queue, per the "no offline path" rule above.

## Prep targets, ready targets, and lateness

**What** Two-level ready-target resolution (ADR-0043 amending ADR-0013): a menu item's own `prepTime` (nullable — "Waktu siap", null = inherit live) falls back to the venue-wide `VenueSettings.prepTargetMins` ("Target siap (default semua menu)", default 15 min). `resolvePrepMins(itemPrepTime, venueDefaultMins)` (`lib/domain/service_timing.dart:17`) is the one function every surface (KDS card, waiter's elapsed pill, the overdue cue, the report SLA) calls — none may carry its own definition of "late".

**Who** Owner/admin sets the venue default and the per-item override (`editSettings` / `editMenu`); kitchen and waiters only read the resolved number.

**Where**
- Venue default: `/alerts` → **Ambang waktu** card → "Target siap (default semua menu)" stepper (5–60 min, step 5). Hidden entirely when the venue runs **Tanpa antrian persiapan** — the row it summarises isn't on the screen either (`alerts_screen.dart:200`).
- Per-item override: `/menuadm/:id` item editor, "Waktu siap" field (`lib/ui/features/admin/menu_admin_item_editor.dart:157`) — empty reads back as what it would inherit.

**How it composes into "late"**
- **The course, not the line, is the unit of "late".** A course's target is the `max` of its lines' resolved targets, and the course is ready only when its *last* line is ready — so a `sides` line correctly waiting on a 25-minute `mains` course is never flagged for doing exactly the right thing.
- `KitchenOrder.resolve` (`kitchen_order.dart:68`) applies the same `max`-of-lines rule to a **batch** (a send group), which is a different aggregate from a course (a batch may span several courses fired together).
- `rollUpCourses` (`lib/domain/service_timing.dart:148`) is the shared pure grouping function the server's overdue scan and the report both call — groups by `(visitKey, course, start)`, `start` being `firedAt ?? sentAt` (`kitchenClockStart`).

**Under the hood**
- `lib/domain/service_timing.dart` — pure, no Flutter, imported by both the client alert path and `lib/server/routes/reports_routes.dart`, so the floor and the report SLA can never disagree about "late". Also defines `ungreetedCueFor` (table-greet escalation — a related but table-scoped cue, not kitchen-scoped).
- `CourseTiming.isOverdueAt(now)` — still cooking and already past target — is the live-cue predicate; `CourseTiming.onTime`/`missedTarget` are the report's completed-course predicates.
- Server writes `Tickets.firedAt` on the `held → sent` transition (the fire), never re-stamps `sentAt` (which stays "when the guest ordered" — it is the KDS card-grouping key, ADR-0008, and the line time printed on the struk).

**Offline behaviour** Purely derived/display state — no writes of its own beyond the ordinary settings PATCH and the ordinary transitions already covered.

**ADRs** 0013 (introduces `readyAt`/`servedAt`, one configurable threshold), 0043 (per-item resolution + course-as-unit-of-late; amendment section extends the resolved target to the KDS card and the waiter's `ElapsedPill`, replacing a stale hardcoded `kKitchenLateMins = 10` constant that ignored `prepTargetMins` entirely).

**Gotchas**
- `slowItems`/per-item report diagnostics **lose pass/fail colouring** once an item can share a course with something slower — coloring it against its own target would permanently red a `sides` item for correctly waiting. It is a neutral ranked list, not a red/green one.
- A `MenuItems.prepTime` sitting at exactly the old default `5` from a pre-v37 migration is nulled (treated as "never overridden") rather than preserved — a genuine 5-minute item from that era cannot be distinguished and will inherit the venue default instead (documented cost, ADR-0043 Consequences).

## Ready alert (banner + toast) and alert sounds

**What** Two layers: (1) a persistent in-screen **banner** on the table detail screen while any of that table's items are `ready` (`ReadyBanner`); (2) a global, app-wide **toast** (`ReadyToast`, hosted by `AlertHost`) that pops in from the top whenever *any* line anywhere reaches `ready`, with a one-tap "Ambil" that jumps straight to that table/takeaway. Both ride the same underlying `AlertEvent` sound system that also drives new-order, void, overdue, ungreeted-table and pickup-lag cues.

**Who** Waiters see and hear the ready cue; kitchen hears new-order/overdue/void-recall; an owner (`editSettings`) configures thresholds and sounds on `/alerts`.

**Where**
- Banner: inline on `/table/:id` (`table_detail_screen.dart:671`, `if (readyAny) const ReadyBanner()`).
- Toast: global overlay, mounted once by `AlertHost` wrapping the router's child in `lib/app.dart:51` — visible on every screen, not just the table detail.
- Config: `/alerts` (`AlertsScreen`), three scope cards — **Ambang waktu** (venue-wide thresholds), **Suara** (venue-wide sound picker), **Senyapkan di alat ini** (this-device mute).

**How to use**
1. A cook marks the last line of a batch `ready` (client mode ≠ server, i.e. a waiter device, and the venue is not running Tanpa antrian persiapan) → `AlertSoundService._onEvent` plays `AlertEvent.orderReady` and raises `readyAlertProvider`.
2. `AlertHost` shows the toast ("Siap di pass · {what}" / "MEJA {table} · {zone} · SEKARANG"), holds it 3 seconds (`_dwell` timer), then auto-dismisses; tapping **Ambil** navigates to `/table/:id` (or `/takeaway/:id` for a table-less order) and dismisses immediately.
3. On the table screen itself, `ReadyBanner` ("Item siap diambil di pass — tandai disajikan di bawah") stays up as long as *any* ticket on that table is `ready`, independent of the toast's 3s window.
4. On `/alerts`, tap a sound row to open the preset picker sheet (21 bundled clips + "none"); tap the play icon to preview.
5. Toggle a row on `_DeviceMuteCard` to silence one cue **on this device only** — the venue-wide sound choice is untouched.

**Under the hood**
- `lib/ui/core/state/ready_alert_view_model.dart` — `ReadyAlert` (tableId, tableLabel, zone, what, isTakeaway) + `readyAlertProvider` (`StateProvider<ReadyAlert?>`).
- `lib/data/services/alert_sound_service.dart` — `AlertSoundService`, a WS-event listener kept alive by `alertSoundServiceProvider` once paired + authenticated. `_onEvent` switches on the new `TicketStatus`: `sent` → `newOrder` (server mode only — including a fired-`held` course); `ready` → `orderReady` + `_raiseReadyAlert` (client mode only, and **not** while `bypassKds`, since a bypass line is born `ready` and would otherwise ring on the same device that just sent it); `voided` → `voided` (server mode = kitchen recall; client mode = only if `_isMyTable`, the responsible waiter).
- Two periodic scans, mode-gated: server mode runs `_scanCourseOverdue` (every 20s, via `rollUpCourses`) for `AlertEvent.overdue`; client mode runs `_scanPickup` + `_scanUngreeted` + `_refreshOnline` (every 20s) for `pickup`/`ungreeted`.
- `_play(event)`: checks device-local mute (`prefs.mutedAlerts()`), resolves the venue's chosen preset (`resolveSoundId`, degrading an unknown/removed id to the event default), leading-edge-debounces bursts (500ms — a fired course of 8 lines is one cue, not eight), haptics on client mode, then `_emit` seeks/resumes a preloaded `AudioPlayer` per preset (or one-shot-falls-back if preload isn't finished).
- `lib/domain/models/alert_sound.dart` — `AlertEvent` enum (`newOrder, orderReady, voided, overdue, ungreeted, pickup, guestPending`), `AlertSoundPreset` (`id`, nullable `asset`), the 21-entry `alertSoundPresets` registry (`kNoneSoundId = 'none'` is the silent sentinel), `alertEventDefaults` (reproduces ADR-0007's original fixed cues: `newOrder→alert`, `orderReady→chime`, `voided→alert`, `overdue→alert`, `ungreeted→chime`, `pickup→chime`, `guestPending→chime`).
- `lib/ui/features/admin/alerts_screen.dart` — `AlertsScreen` composes `_ThresholdCard`, `_SoundCard`, `_DeviceMuteCard`. `_kdsCues = {newOrder, overdue, orderReady}` is the set both the sound card and the device-mute card hide when `venueSettingsProvider.bypassKds` is true — cues a prep-less venue's queue can never raise (`newOrder` needs a `sent` line; `overdue` needs a line that could be late; `orderReady` would ring on the device that just sent the order).
- `lib/ui/core/widgets/ready_banner.dart` / `ready_toast.dart` / `alert_host.dart` — presentational widgets. `AlertHost._raiseReadyAlert`'s reverse-resolve for a table-less (takeaway) line reads the visit off `takeawayVisitsProvider`.

**Offline behaviour** The alert service is a pure WS-event consumer with no writes and no queue of its own — it goes silent whenever the socket is down (nothing to listen to) and resumes on reconnect. Thresholds/sounds are ordinary `VenueSettingsDto` fields, PATCHed like any other setting (no special offline handling documented here; see the settlement/venue-settings sync path elsewhere).

**ADRs** 0007 (routing by device role, not active screen; overdue/void asymmetry), 0035 (decouples clip from meaning; per-event venue-wide preset + preview), 0044 (adds ungreeted/pickup with escalation + venue-policy enable flags + per-device mute as the **only** device axis — the old blanket "Alert audio" toggle is gone), 0064 *(a-guest-order-gets-its-own-cue — superseded/re-decided history for `AlertEvent.guestPending`, which now fires on both client and server mode for a submitted guest order)*, 0081 (the two scans run on 20s `Timer.periodic`, not per-frame — orthogonal to the two-ticker readout/threshold split which governs *display*, not these scans), 0115 (bypassKds silences `newOrder`/`overdue`/`orderReady` but deliberately **not** `pickup` — food sitting ready is still the counter's own failure to hand it over).

**Gotchas**
- Three orthogonal silencing axes exist and must not be conflated: venue-wide **sound choice** (which clip), venue-wide **enable flag** (`ungreetedAlertEnabled`/`pickupAlertEnabled` — silences the cue, never the underlying threshold, which keeps driving the floor card's standing state and the report SLA), and device-local **mute** (this handset only). There is deliberately no second device-wide switch anywhere outside `/alerts`.
- `_onlineUserIds` (used by the ungreeted escalation, not the ready alert) is `null` until the first successful `/auth/online` fetch — an **unknown** set must read as "cannot tell" and fall back to the normal escalation, never as "everyone signed out" (would floor-wide-cue on a network hiccup).
- The ready toast and `ReadyBanner` are independent: dismissing/timing out the toast does **not** clear the banner, and a table can show the banner with no toast currently visible (toast already dismissed, order still ready).

## Simple KDS & Tanpa antrian persiapan (mode keys, cloud-set only)

**What** Two independent, fail-**closed** [[Kedai]]-family mode keys (unlike sellable `Modul`s, which fail open) that reshape the prep queue rather than gating a feature:
- **`simpleKds`** (`counterSimpleKds`) — one of the six switches inside the `counterService` preset (ADR-0109 §3). "Dapur satu antrean, tanpa stasiun" — collapses the KDS card's course-chip row so every card reads as one undivided queue instead of split by station/course. Read via `VenueSettingsDto.counterOn(counterSimpleKds)` (which itself ANDs `counterMode` — i.e. `simpleKds` is meaningless outside a Kedai/counter-mode venue).
- **`bypassKds`** (`modeBypassKds`) — "Tanpa antrian persiapan" ("no prep queue"). The venue has nobody downstream of the order-taker to hand a line to. **Never** call this "bypass KDS" in user-facing copy (CONTEXT.md is explicit) — KDS is always "Antrian Persiapan" and "bypass" only describes the code path.

**Who** Set by the fleet **operator**, not the venue owner — "the shape of their shop, settled at onboarding" (CONTEXT.md), not a Pengaturan toggle.

**Where** `lib/ui/features/fleet/venue_edit_screen.dart` (fleet console, outside the SatSet app proper) — `fltModeBypassKds` toggle with a confirmation dialog (`fltModeBypassKdsOnTitle`/`OnBody`/`OnYes`) and `fltCounterSimpleKds` inside the counter-mode switch list.

**Effect when `bypassKds` is on**
1. `sendOrder` (client, `tickets_repository.dart:687`) and `submitOrder` (server) both mint every new line as `TicketStatus.ready` with `readyAtTime` stamped at send — **not** `sent`, and **not** `served`. The line lands directly in the waiter's "Siap diambil" bucket on `/orders`. `ready → served` is the ordinary handover tap, so a mis-key is still the waiter's own `voidItem`, never a manager's `compItem` comp — which is exactly why the born status is `ready`, not `served`.
2. The KDS nav slot **hides** — but the route stays legal and the slot **returns** while `kitchenQueueLiveProvider` is true (any line still `sent`/`prep`/`cooked` — so flipping the mode on mid-shift never strands food already cooking) or for a `viewKds`-only signed-in user (who would otherwise have no destination at all).
3. `newOrder`, `overdue` and `orderReady` cues silence themselves (nothing can raise them); `pickup` keeps running.
4. `_ThresholdCard` drops the "Target siap" row entirely (the value stays stored, unedited, ready to reappear if the mode is turned back off); `alertsSummary` badges `alertsThresholdLineNoPrep` instead of `alertsThresholdLine`.
5. Nothing is **revoked** — the `viewKds` capability row stays stored on whatever role held it; it is hidden, not removed, so unticking the mode later restores the venue exactly as it was.

**Under the hood**
- `lib/domain/models/venue_module.dart` — `modeBypassKds = 'bypassKds'`, `counterSimpleKds = 'simpleKds'`, `venueModeKeys`. Fails **closed**: `modules?.contains(...) ?? false` — unlike the sellable `hasModule`, which defaults `true` when `modules == null` (never mirrored). A mode absent or unmirrored reads as "restaurant"/"has a queue", which is the safe default for every venue that predates this feature.
- `lib/data/models/venue_settings_dto.dart:163` — `VenueSettingsModules.bypassKds` getter (client read); `counterOn(key)` for the six counter switches including `simpleKds`.
- `lib/server/db/tables.dart` — `VenueSettings.modules`/`counterConfig` TEXT columns, comma-joined, mirrored down from `venues/{vid}.addOns`/`counterConfig` by the cloud listener — no in-app writer.

**Offline behaviour** A device caches the venue "shape" (`PrefsService.venueShape()` — modules + counterConfig) at `VenueSettingsRepository` construction, because a mode fails closed and a cold-boot-offline handset would otherwise render a KDS tab and a floor the venue does not actually have.

**ADRs** 0107 (Modul entitlement vs mode keys, fail-open vs fail-closed), 0109 (Kedai/counter mode is a *preset of switches*, not a read; `simpleKds` is one of six), 0115 (bypassKds — the one mode key that branches a writer, `submitOrder`; hides-never-revokes; the `ready`-not-`served` reasoning; the KDS-slot self-drain).

**Gotchas**
- There is no in-app screen where an owner can flip `bypassKds` or `simpleKds` — do not point a user at Pengaturan/Sistem looking for it. It genuinely is fleet-console-only.
- `bypassKds` and `counterService` (Kedai/counter mode) are **independent** — a counter shop may still run a cook line, and a small restaurant may have no queue at all. Neither implies the other; do not assume one from the other's state.

## KDS station pairing status (visibility, not configuration)

**What** `/system` (Sistem → Operasional) shows a live count of paired KDS station displays (`sysKdsOnline`, `kdsStationsProvider`) alongside paired tablets and printers, plus a **Printer & KDS** section listing each device with an online/offline indicator (`lastSeenAt` within 5 minutes).

**Who** Admin (viewing `/system`).

**Where** `/system`, top KPI row + "Printer & KDS" section (`lib/ui/features/admin/system_screen.dart:84` / `:290`).

**Under the hood** Backed by the `Devices` (printers + KDS station screens advertised on the LAN) table (`lib/server/db/tables.dart:630` area) via `kdsStationsProvider`/`PrinterDto`. This is device/LAN discovery visibility, not a kitchen-queue configuration surface — there is no per-station routing today (item→station routing data was dropped in migration v19; CONTEXT.md §Station).

**Gotchas** Do not confuse this with the KDS *board* (`/kitchen`) — this only shows whether a physical KDS display is online, not the ticket queue itself. Per-station metrics are deferred pending routing data returning.

## Terminology (CONTEXT.md canonical, ID · EN)

- **Antrian Persiapan · Prep Queue** — the screen at `/kitchen`. Never "Dapur"/"Kitchen" as the screen name.
- **Stasiun · Station** — Dapur (kitchen) / Bar. A prep destination, not a separate screen; routing data currently absent.
- **Batch (kitchen order)** — the set of tickets one table sends together, keyed `(table, sentAt)`. Nav badge "Antrian"; late chip/tally "Telat".
- **Kitchen clock start** — `firedAt ?? sentAt`; every prep measurement runs from this, never `sentAt` alone.
- **Waktu siap · Ready target** — per-item `MenuItem.prepTime`, nullable-inherit. "Ikut venue (15m)" when inheriting.
- **Target siap (default semua menu) · Ready target (venue default)** — `VenueSettings.prepTargetMins`.
- **Course (English only in code; ID copy is per-course name)** — `drinksNow, starters, mains, sides, desserts, fireNow`; the unit of "late".
- **Peringatan · Alerts** — the `/alerts` screen. Events: Pesanan baru (new order), Pesanan siap (order ready), Void, Lewat waktu (overdue), Belum dilayani (not greeted), Menunggu diantar (waiting to run/pickup lag).
- **Tanpa antrian persiapan · No prep queue** — never "bypass KDS" in user-facing copy.
