# 03 · Cashier & settlement

The Kasir (Cashier) surface is where a table's food becomes money: assigning sent lines to receipts, splitting a bill any number of ways, taking payment by cash/card/QRIS/transfer/tab, discounting, refunding, and closing the bill — live when the embedded server is reachable, and captured to a client-side journal when it is not. This document covers `/kasir` end to end: the venue-wide bill list, the per-visit bill overlay, [[Split bill]] modes, [[Amount receipt|amount receipts]] and [[Receipt letter|receipt letters]], [[Payment (manual confirmation)|payments]] (including [[Piutang|tabs]]), [[Payment proof photo (Bukti pembayaran non-tunai)|proof photos]], [[Diskon (discount)|discounts]] and tax stacking, refunds, bill close/reopen, cashier history, the offline [[Antrean setelmen]] + client Drift database (ADR-0123/0124), and the one money function (`recomputeBill`) both the server and the offline projection are required to call.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Cashier bill list (`/kasir`) | `/kasir` | `settleBill` | `GET /settlement/payable` |
| Bill detail (Visit's bill) | root-navigator page from `/kasir`, post-send, or the active table header | `settleBill` | `GET /settlement/visits/<visitId>/bill` |
| Visits vs tables (two-phase settlement) | architectural — `/kasir` list + bill overlay | — | `Visits.tableFreedAt` / `Visits.billClosedAt` |
| Split bill mode (Penuh / Per item / Bagi rata) | bill overlay → `SettlePane` | `settleBill` | `POST /settlement/visits/<id>/receipts`, `POST /settlement/visits/<id>/split-even` |
| Per-item line assignment | bill overlay → `Atur` sheet | `settleBill` | `POST /settlement/receipts/<id>/lines` |
| Amount receipt (Bagi rata share) | bill overlay → `_EvenSplitCard` | `settleBill` | part of `POST /settlement/visits/<id>/split-even` |
| Receipt letters | bill overlay, printed slip | — (client-only render) | `Receipt.label`, server-assigned lowest-unused letter |
| Payment (incl. tab) | bill overlay → pay sheet / `SettlePane` foot | `settleBill` | `POST /settlement/receipts/<id>/payments` |
| Non-cash proof photo | payment sheet | `settleBill` | inline `photoBase64` on the payment request |
| Discounts (manual/member/redeem) | discount sheet, member panel, Siapa sheet | `applyDiscount` (or manager step-up) | `POST /settlement/receipts/<id>/discounts`, `POST /settlement/visits/<id>/discounts` |
| Refund | receipt card → `_refundSheet` | `refund` | `POST /settlement/receipts/<id>/refund` |
| Bill close / reopen | bill overlay top / done pane | `settleBill` (write-off also needs `refund`) | `POST /settlement/visits/<id>/bill-close`, `POST /settlement/visits/<id>/reopen` |
| Member panel (Pemilik tagihan) | bill overlay | `settleBill` | `POST /settlement/visits/<id>/member`, `/member/detach`, `/redeem`, `/redeem/remove` |
| Pemilik struk (Siapa) | Who sheet, per-receipt | `settleBill` (needs `memberSplit` mode) | `POST /settlement/receipts/<id>/member`, `/member/detach`, `/redeem`, `/redeem/remove` |
| Piutang collection | `/kasir` → "Terima piutang" | `settleBill` | `POST /members/<id>/debt/payments` |
| Cashier history (Lunas / Semua) | `/kasir` segments | `settleBill` | `GET /settlement/history`, `GET /settlement/sessions/<id>/bill` |
| Printing (Tagihan / Struk pembayaran / Rincian pilihan) | print buttons throughout | `settleBill` | `POST /settlement/visits/<id>/bill/print`, `POST /settlement/receipts/<id>/print` |
| Offline settlement journal | any of the above, offline | `settleBill` | replayed 1:1 through the same routes, `x-idempotency-key` |
| Settlement money function | server + offline projection | — | `recomputeBill` (`lib/domain/use_cases/bill_recompute.dart`) |

## Cashier bill list (Kasir · Cashier)

**What** The venue-wide money screen: every open [[Visit]] with an unsettled or unclosed [[Bill (tab)]], plus closed bills, in one scrollable grid of `BillCard`s under three segments.

**Who** Any staff holding `Capability.settleBill` (`lib/domain/models/capability.dart:19`). The seeded **Kasir** role grants `settleBill` + `openDrawer`, deliberately without `applyDiscount`.

**Where** `lib/ui/features/cashier/cashier_screen.dart` (`CashierScreen`). Shell route `/kasir`.

**How to use**
1. Open **Kasir** from the app shell. The header shows "Kasir" and a running summary ("Terima {amount}" total outstanding).
2. Three segments filter the grid: **Perlu ditagih** (open + part-paid), **Lunas** (closed, defaulting to today and extendable to 7 days), **Semua** (both). `cashier_screen.dart:38-42`.
3. A "Meja ditutup" stat tile, tapped, filters to detached-unpaid visits only (`_detachedOnly`, `cashier_screen.dart:57-59,522-546`).
4. A **Piutang** filter chip (only shown when the venue runs tabs) narrows the Lunas/Semua segments to bills settled on account (`cashier_screen.dart:612-618`).
5. Tap any card to open that visit's bill overlay (`openCashierBill`).
6. Below the stats, a **"Terima piutang"** button opens the debt-collection sheet directly — reachable with nothing seated, because a member may walk in only to pay off a tab (ADR-0098).

**Under the hood**
- `SettlementRepository` (`lib/data/repositories/settlement_repository.dart`) is a `StateNotifier<List<BillSummary>>`; `_bootstrap` fetches `/settlement/payable` and re-subscribes on `WsEventTypes.billUpdated`/`tableUpdated`/`tableCreated`/`tableDeleted`/`ticketUpdated`/`ticketCreated`/`tableSessionClosed`.
- `venueHistoryProvider` (closed bills) and `historyLimitProvider` (a growing page limit) back the Lunas/Semua segments; scrolling within two viewports of the end grows the limit (ADR-0079).
- Server: `GET /settlement/payable` lists every visit with `billClosedAt == null` that has at least one sent line, sorted detached-first then by outstanding descending (`settlement_routes.dart:329-348`).
- `GET /settlement/history?days=&limit=&tableId=&onAccount=` returns closed `TableSession` rows within a bounded window, plus `total` (the whole window's count, not the page's) and `piutangTotal` (net tab total for the window) (`settlement_routes.dart:2086-2181`).
- `BillCard` (`lib/ui/features/cashier/widgets/bill_card.dart`) is built either `.fromSummary` (live) or `.fromPastBill` (closed) — one card vocabulary for both, per ADR-0066/0063.

**Offline behaviour** The bootstrap fetch falls back to a cached payable list (`SettlementJournal.cachedPayable()`) when the host is unreachable and no bills are yet in state, so a cold boot with no host still shows a way into cached bills (ADR-0123 §Q19). `SettlementSyncStrip` renders on this screen whenever the journal holds pending or draining events.

**ADRs** ADR-0023, ADR-0024, ADR-0066, ADR-0069, ADR-0079, ADR-0098, ADR-0123.

**Gotchas** Counts shown on segment chips read `page.total`, never `closed.length` — the loaded rows are one page of the window (ADR-0079). The Piutang filter is client-visible narrowing of a server-filtered list, never a client-side re-filter of the loaded page.

### Bill card states and pills

`BillCard` (`lib/ui/features/cashier/widgets/bill_card.dart`) is the one card vocabulary for both a live and a closed bill (`_Masonry`, a round-robin column layout because a bill card's height is its content, not a fixed grid extent). Its `BillCardState` enum (`open | partial | settled | writeOff`, `bill_card.dart:22`) drives the outline colour — an open bill takes the neutral `border0` on purpose, since on **Perlu ditagih** (where most cards are open) a coloured outline on every card would mean nothing. The card's headline number and caption flip meaning by state: `amount`/`amountCaption` read `outstanding`/`blcCaptionOutstanding` while open, `total`/`blcCaptionPaid` once settled (`bill_card.dart:142-143`). A pill row (`_pills`) stacks whatever facts are earned: item count, elapsed time since seated/arrived, `Tertunda` (this device's own offline-captured settlement, ADR-0123 — **never** a generic network badge, because it names *this bill*, not the link), `Meja ditutup` (detached), a named bill-discount label, an even-split tally (`N dari M lunas`), `Dibayar di muka` (prepaid aggregator), a `Piutang {amount}` chip (settled but partly on account — orthogonal to `BillCardState`, since a tab-settled bill is still Lunas), and one `ReceiptBadge` per itemized letter still owing.

## Capabilities reference

| Capability | Gates | Notes |
|---|---|---|
| `settleBill` | Every read/write on `/kasir` and the bill overlay: list, bill detail, mint/delete receipt, assign, split-even, payment, reopen, bill-close (Lunas path), member attach/detach, redeem, Piutang collection | The seeded **Kasir** role holds this + `openDrawer`, deliberately without `applyDiscount` |
| `applyDiscount` | Apply/remove a discount at any scope without a manager step-up | A cashier lacking it can still apply one via a verified manager PIN |
| `refund` | Refund a payment leg; write-off (`tak tertagih`) bill close; `POST /members/<id>/debt/write-off`, `/debt/adjust` | "The capability that already means a manager is accepting that money is gone" |
| `manageCash` / `manageMembers` | Out of scope here — `manageMembers` gates the `/members` directory, credit-limit edits, and reading a member's lifetime visit history; unrelated to the till's own read of a member mid-bill | — |
| `viewReports` | `GET /audit/payments/<id>/photo` (proof lookup from the venue log) | Not a settlement-writing capability |

No new capability was minted for the offline path — a captured event replays under the same gate the online route already checks, at drain time, against whatever role the acting user currently holds.

## Bill overlay (the Visit's Bill)

**What** The per-visit settlement surface: line assignment, split mode, discounts, member panel, payments, receipts, refunds, close/reopen — everything that moves one bill's money.

**Who** `settleBill`.

**Where** `lib/ui/features/cashier/cashier_bill_screen.dart`. `openCashierBill(context, visitId: ...)` — tablet: full-screen `MaterialPageRoute` (`CashierBillPage`) on the root navigator; phone: a `FractionallySizedBox` sheet at 92% height (`cashier_bill_screen.dart:58-74`). Both are root-navigator by construction so the floating phone tab bar cannot cover the confirm button.

**How to use**
1. Tablet: two independently-scrolling panes — items + member + totals on the left (`flex: 3`), the settle pane on the right (`flex: 2`) — so the running cash tally never scrolls away mid-count. Phone: one column, items on top, a 420dp settle pane pinned below (or the "done" pane once the bill is settled/closed).
2. The lines list groups sent tickets by send batch (`HH:mm`), oldest first, matching the KDS grouping key.
3. `MemberPanel`, `_TotalsCard`, `_TopActions` (print whole bill / bill-scope discount / write-off icon), a detached-visit banner, then the lines, then (if split) the **Siapa** card and either the even-split card or per-receipt list, then **"Tambah struk"**.

**Under the hood** `CashierBillView` watches `billDetailProvider(visitId)` (a `FutureProvider.family.autoDispose<Bill,String>` that re-fetches on `bill.updated`/`tableSession.closed` for that visit). Every mutating call goes through `_run` (`cashier_bill_screen.dart:144-168`), which surfaces `ApiException` on an inline error line (never a `SnackBar` — the bill overlay is a modal, and a snackbar would render underneath the barrier) and re-invalidates the provider on success. A transport failure (no response at all) shows an "unconfirmed, not unpaid" message rather than "failed" — the write may have landed and a retry without an idempotency key would double-charge, which is exactly what the offline journal path (below) exists to prevent for every route this screen calls.

**Offline behaviour** See "Offline settlement journal" below — every mutation this screen makes is wrapped by `SettlementRepository._act`/`_actOnReceipt`, which captures to the journal instead of calling the API when the visit is [[Kunjungan otoritatif-lokal|local-authoritative]] or the socket is down.

**ADRs** ADR-0023, ADR-0024, ADR-0064, ADR-0066, ADR-0067, ADR-0123.

**Gotchas** `_whoOffered` offers the Siapa sheet exactly once per screen instance, the first time a split appears with an unnamed share — closing it (even by tapping away) does not re-offer it on the next rebuild (`cashier_bill_screen.dart:443-473`).

## Visits vs tables — two-phase settlement

**What** The bill belongs to the **[[Visit]]**, never to the table row — which is what lets settlement keep running after a waiter has already freed the table for the next party, and what keeps an old unpaid party and a new one seated at the same physical table from ever mixing money.

**Who** N/A (architectural invariant read by every settlement route and by `/kasir`'s list).

**Where** `Visits` table (`lib/server/db/tables.dart:140-181`); the pairing logic lives in `snapshotVisitAndDelete` (`lib/server/routes/tables_routes.dart`) and `performBillClose` (`settlement_routes.dart:89-219`).

**How it works**
1. A visit ends along **two independent axes**, in either order: **table close (detach)** — the waiter frees the table back to `kosong`, touching only table status — and **bill close (Tutup tagihan)** — the cashier locks the money. `Visits.tableFreedAt` and `Visits.billClosedAt` are two separate nullable timestamps; whichever act lands first just stamps its own column and the visit stays live.
2. Only when **both** are set does the visit disappear: the `TableSession` snapshot is written **exactly once**, at whichever act completes the pair. Usually that is bill close (the cashier acts after the table is freed) — `performBillClose` checks `fresh.tableFreedAt != null` and calls `snapshotVisitAndDelete` right there (`settlement_routes.dart:180-196`) — but if the cashier locks the bill first while guests linger, the waiter's later detach is what completes it instead.
3. Until both are done, the visit stays on the `/kasir` list. A visit whose table is freed but bill still open surfaces there flagged **detached** ("meja sudah ditutup, tagihan belum lunas") — `bill['detached']`/`bill['tableFreedAt']` in `_buildBill` (`settlement_routes.dart:2708,2728`), rendered by `BillSummary.detached` and the **Meja ditutup** stat tile on `/kasir`.
4. Settlement is **lock-free and orthogonal to kitchen-driven table status**: taking money never requires or respects the `Table lock` a waiter holds while editing lines — a table can be fully paid yet still occupied, or freed while still unpaid. `VenueTable.status` flips to `available` at table close **regardless of payment state**; no `settling`/`paid` table status exists (that would be two axes crammed into one field).
5. `GET /settlement/payable` therefore spans **both** attached (table occupied, ≥1 sent line) and detached visits in one list (`settlement_routes.dart:329-348`) — a table close never removes a visit from the cashier's job list, only a bill close does.

**ADRs** ADR-0023, ADR-0024 (visit decoupled from table and bill close — the ADR that introduced this pair, superseding a single "Tutup meja" act).

**Gotchas** "Close table" in English copy is banned — it reads as settling money, which is `Bill close (Tutup tagihan)`. A moved visit (`Pindah meja`) is recorded as one `TableSession` attributed to the **final** table only; the source table shows no session for that party.

## Split bill mode (Penuh · Per item · Bagi rata)

**What** How the next payment carves up what is owed — chosen **per payment**, not per bill: a table where two friends split evenly and a third pays his own steak is one bill holding both kinds of receipt.

**Who** `settleBill`.

**Where** `lib/ui/features/cashier/widgets/settle_pane.dart` (`SettlePane`, `SettleMode` enum: `penuh`, `perItem`, `bagiRata`).

**How to use**
1. Three chips at the top of the settle pane: **Penuh** (`stlModePenuh`), **Per item** (`stlModePerItem`), **Bagi rata** (`stlModeBagiRata`).
2. **Penuh** — one receipt for the whole remainder (or the single already-open receipt, if exactly one exists and nothing is left to mint).
3. **Per item** — tap lines in the left pane; the settle pane prices the selection (subtotal + proportional service/tax), lets the cashier print a provisional **Rincian pilihan** slip before minting anything, and offers a **Siapa** ("who is this for") row when `memberSplit` is on.
4. **Bagi rata** — a stepper picks N (2–12); the pane shows the per-head figure and confirms the next open share.
5. Confirming mints the implied receipt (transactionally, with lines attached) and takes the payment in the same call.

**Under the hood** Nothing is minted until confirm — a mode the cashier tries and abandons leaves nothing on the bill (ADR-0067). `SettlePane._confirm` (`settle_pane.dart:250-295`) calls `SettlementRepository.mintReceipt` (Per item / Penuh-with-nothing-open) or `splitEven` (Bagi rata, first share only) then `recordPayment` on the returned receipt id. Server: `POST /settlement/visits/<id>/receipts` mints (and optionally assigns lines in the same transaction — `settlement_routes.dart:370-448`); `POST /settlement/visits/<id>/split-even` mints N `even` receipts sized from `distributeEvenRounded` off the untracked remainder (`settlement_routes.dart:547-604`).

**Offline behaviour** Both mint routes accept a client-minted `id` (`_mintId`, `settlement_routes.dart:2210-2216`) so the offline journal's captured `mintReceipt`/`splitEven` events can replay idempotently and so a captured payment can name a struk that has not reached the host yet.

**ADRs** ADR-0023, ADR-0067, ADR-0068, ADR-0122.

**Gotchas** `_penuhTarget` only returns a target when exactly one receipt is still open and nothing is left to mint — with two or more open receipts, Penuh has nothing sensible to charge and the per-struk `Bayar` button is the only way through (`settle_pane.dart:150-157`).

## Per-item line assignment

**What** Assigning qty-level units of a sent ticket line to a specific itemized receipt, either via the fast tap-to-select-and-pay path (Per item mode) or the deliberate `Atur`/`Assign` sheet.

**Who** `settleBill`.

**Where** `_LinesSection._assignSheet` + `_AssignRow` in `cashier_bill_screen.dart:1006-1104`; the tap picker lives in `_BillBodyState._toggle`/`_setUnits` (`cashier_bill_screen.dart:422-441`).

**How to use**
1. In assignable (non-picking) mode, each line shows an **Atur**/**Ubah** button opening a sheet with a stepper per existing itemized receipt.
2. In Per item picking mode, tapping a line takes the whole unassigned remainder in one tap (the 95% case); when more than one unit is free, a stepper appears to split it (the rare per-unit case).
3. Owner chips under each line show which receipt(s) own how many units, plus an amber `?×N` chip for anything still unclaimed.

**Under the hood** `POST /settlement/receipts/<id>/lines` (`settlement_routes.dart:483-544`) replaces this receipt's claim on the ticket wholesale (delete-then-insert), clamped to what is actually free elsewhere (`_assignedUnits` excluding this receipt). Assignment is qty-level, never fractional — a `qty: 3` line can send 2 units to one receipt and 1 to another.

**ADRs** ADR-0023, ADR-0037 (line discounts only attach to non-voided owned units), ADR-0063.

**Gotchas** A voided or draft ticket line has no free units and cannot be assigned (`t.status == 'voided' || t.status == 'draft'` refusals live on the discount route, not here — assignment itself just finds `0` free).

## Amount receipt (Bagi rata share)

**What** A receipt that owns no lines and instead holds a **frozen** money claim — "one third of whatever is left" — fixed at mint time so later bill edits cannot silently move a quote a guest was given.

**Who** `settleBill`.

**Where** Rendered by `_EvenSplitCard`/`_EvenShareRow` (`cashier_bill_screen.dart:1732-2051`); minted server-side by `POST /settlement/visits/<id>/split-even`.

**How to use** See Split bill mode above. Every share collapses into one card of thin rows (per-head amount, `2 dari 3 lunas`, one row per share) rather than N near-identical cards — a row opens that share's own receipt sheet, so pay/reopen/refund/discount/print all run through the one `_ReceiptCard` implementation (ADR-0063).

**Under the hood** The remainder an amount receipt draws from is `bill.total − Σ(every existing receipt's total)` (`settlement_routes.dart:564-572`), never the whole bill — which is what lets an amount receipt sit beside an itemized one on the same bill. Shares are rounded so each head is a note-friendly figure (`distributeEvenRounded`) and the surplus rides the later heads. An amount receipt's `total` is never recomputed by `recomputeBill` after minting (`bill_recompute.dart:166-169`, `RcReceipt.isAmount`); only its `paid`/`unpaid` status moves.

**ADRs** ADR-0068, ADR-0067, ADR-0063.

**Gotchas** No line discount can ever attach to an amount receipt (it owns no lines to attach one to); the discount sheet's scope filter enforces this by only offering `order`/`bill` presets against a receipt whose `mode == 'even'` refused server-side (`even_mode` error code, `settlement_routes.dart:686-694`).

## Receipt letters

**What** A persisted capital letter (`Receipt.label`) that identifies an itemized guest at the till — "Tamu A" — rather than a positional slot number.

**Who** N/A (assigned automatically; read-only identity).

**Where** `lib/domain/models/receipt_label.dart` (`isReceiptLetter`, `nextReceiptLetter`, `receiptTitle`); rendered by `lib/ui/features/cashier/receipt_badge.dart` (`ReceiptBadge`); coloured by `lib/ui/core/design/receipt_visuals.dart` (`receiptHue`).

**How to use** The letter appears on four surfaces: the receipt card header, each owned item's origin chip on the lines list (`A×2 B×1`, plus an amber `?×1` for unassigned), the assign sheet's rows, and the `/kasir` tile's progress strip.

**Under the hood** `_AddReceiptButton` mints a new receipt with `label: nextReceiptLetter([...existing labels])` — the **lowest unused** letter, so deleting `B` and adding again refills `B` rather than minting `D` (`cashier_bill_screen.dart:2170-2200`). An even split's shares carry `Bagian N/M` instead — they own no lines, so there is genuinely nothing to tell one apart from another, and they wear no letter. A whole-bill undivided receipt is `Tagihan`. The hue ramp is six curated colours minus green/red (already spoken for by paid/unpaid); the letter, not the colour, is the identity, so a monochrome printed slip and a colour-blind cashier both still work.

**ADRs** ADR-0063.

**Gotchas** Bills already open before ADR-0063 shipped keep legacy `Tamu 1`-style labels and simply wear no badge — `receiptTitle()` passes any non-single-letter label through untouched.

## Payment (incl. tab / Piutang)

**What** A cashier-recorded attestation that a receipt's claim was **discharged** — by money changing hands, or (under `piutang`) by moving onto a member's [[Piutang]] ledger.

**Who** `settleBill`; a `piutang` payment additionally needs the debtor to have `debtHeadroom > 0` (client-side pre-gate, server-enforced).

**Where** `SettlePane._confirm` (settle-pane driven payment) and `_ReceiptCard._paySheet` (`cashier_bill_screen.dart:1401-1620`, per-struk pay sheet). Method chips are shared by both via `PayMethodPicker` (`lib/ui/features/cashier/widgets/pay_method_picker.dart`).

**How to use**
1. Pick a method: **Tunai**, **QRIS**, **Kartu**, **Transfer**, **Lainnya**, and — only where the venue runs tabs — **Piutang** (`payMethodOnAccount`).
2. Tunai shows a `CashPad` (Indonesian denomination buttons Rp 100–Rp 100.000, quick-tender chips, a running received/change summary with a denomination breakdown for the change).
3. Any other money method (not Tunai, not Piutang) requires a live camera shot before the confirm button unlocks.
4. Piutang shows the debtor's remaining credit (`stlPiutangLeft`) instead of a pad or camera — no money moves, so nothing is tendered and nothing is shot.
5. The amount field defaults to the receipt's outstanding but is the cashier's to type down (part-payment), capped at that figure.

**Under the hood** `POST /settlement/receipts/<id>/payments` (`settlement_routes.dart:1516-1675`):
- Validates `method ∈ {tunai, kartu, qris, transfer, lainnya, piutang}` and `amount ≤ receipt.total − paidNet`.
- Non-cash, non-`piutang` methods require a `photoBase64` body field or `400 photo_required`.
- A `piutang` payment resolves the debtor as `receipt.memberId ?? visit.memberId` — the [[Pemilik struk]], falling back to the [[Pemilik tagihan]] (ADR-0120) — checks `debtConfig(db).enabled`, and requires a member. In the **same transaction** as the payment insert, `chargeDebt` writes a `MemberDebtKind.charge` row against that member, re-checking the credit limit inside `db.transaction` (ADR-0100 — the balance is `SUM(delta)`, so the guard only holds if the read and the write are one step).
- A tab is stored **unphotographed** and **untendered** (`storedPhoto = null`, `tenderedAmount = null` when `onAccount`).
- A payment captured offline and drained past its own business day writes an extra `AuditKind.settlementArrivedLate` audit row (`settlement_routes.dart:1645-1673`).

**Money order-of-operations** A struk holds **multiple** payments now that the bill-wide tender lock is gone (ADR-0121) — part Tunai + part Kartu, or part cash + part on account, each with its own proof (where required). "Every method is available on every payment" — nothing about the receipt's history restricts the next payment's method.

**Offline behaviour** `recordPayment` captures a `SettlementEventKind.recordPayment` event carrying the photo bytes as base64 on the event payload — the photo never enters the offline money projection (`_apply` sets `hasPhoto: false` on a captured payment; `settlement_projection.dart:180-196`), it only has to arrive on drain.

**ADRs** ADR-0025 (proof photo), ADR-0098 (tab as payment method), ADR-0100 (transactional ledger guard), ADR-0120 (tab follows the struk), ADR-0121 (split tender, no lock).

**Gotchas** `Piutang` cannot be selected to refund; a `piutang` leg refunds by ledger reversal, never by picking `piutang` as a refund method (that chip is deliberately absent from the refund sheet — see Refunds below).

## Non-cash proof photo

**What** A mandatory, camera-shot photograph attesting a non-cash payment (or a Piutang collection). Exactly one photo per payment; cash and Piutang carry none.

**Who** `settleBill` (payment recorder).

**Where** `image_picker`'s `ImagePicker().pickImage(source: ImageSource.camera, ...)`, called from `SettlePane._shootProof`, `_ReceiptCard._paySheet.shootPhoto`, and `_DebtCollectSheet._CollectForm._shoot`. Displayed via `PaymentProofThumb` (`lib/ui/core/widgets/payment_proof_thumb.dart`) and the paper preview.

**How to use** Tap **Ambil foto**; the shot becomes a 56dp square thumbnail, tappable to a full-screen zoomable viewer at every surface it appears (capture preview, live bill, past-bill detail, non-cash report) — the same size everywhere (ADR-0082). Tap the thumbnail again pre-submit to retake.

**Under the hood** Camera-only, never gallery — the proof is a live capture, not a saved screenshot. Server enforcement is fail-closed: a non-cash `POST /settlement/receipts/<id>/payments` with no `photoBase64` returns `400 photo_required`. Photo + payment land in one atomic request (no orphaned payment). At bill close the photo is copied into the immutable `TableSessionPayments` snapshot, so it survives on the Struk pembayaran detail and the non-cash-payments report. Proof bytes are never selected into the bill JSON or list payload — fetched on demand via `GET /settlement/payments/<id>/photo` (live), `GET /settlement/history/payments/<id>/photo` (closed), or `GET /audit/payments/<id>/photo` (venue log, looks in both tables).

**ADRs** ADR-0025, ADR-0082, ADR-0086.

**Gotchas** A `piutang` payment is exempt — "there is no slip for a promise" — which is also why `piutang` is refused as a *refund* method (no photo, no proof of a reversal that never moved money).

## Discounts (manual / member / redeem) + tax stacking

**What** A cashier-authorised reduction of what a guest owes, applied only at settlement, from a fixed catalogue of owner-defined [[Preset diskon|presets]] — never a free-typed percentage.

**Who** `applyDiscount`, or `settleBill` plus a manager step-up PIN verified server-side.

**Where** `lib/ui/features/cashier/discount_sheet.dart` (`showDiscountSheet`, `DiscountTarget`), invoked from `_TopActions` (bill-scope), `_ReceiptCard` (order-scope), `_ReceiptItemRow` (line-scope), and from `MemberPanel`/`_WhoRow` for the member/redeem slots.

**How to use**
1. Tap **Diskon** at bill level, receipt level, or on an owned line.
2. The sheet lists only presets whose `scope` matches what was tapped (`bill`, `order`, or `line`) — a fixed whole-bill amount can never land on one cheap line.
3. If the signed-in user lacks `applyDiscount`, a manager PIN prompt appears before the pick is submitted; the PIN is passed through untouched and verified server-side.
4. Removing a discount is a guarded confirm (`_confirm`), same step-up rule.

**Under the hood — three scopes, one mechanism**
- **Line** (`ticketId` set): base is the value of the units *this receipt* owns of that line.
- **Order** (`ticketId` null, `receiptId` set): base is the receipt's subtotal net of its own line discounts.
- **Bill** (`receiptId` null, `visitId` set, ADR-0070): attaches to the **visit**, not a receipt — the only scope reachable before any receipt has been minted. Resolves against `billSub − Σ(line discounts)`, then fans out proportionally across every itemized receipt via `distributeFixed`.

`POST /settlement/receipts/<id>/discounts` and `POST /settlement/visits/<id>/discounts` both: reject a second discount in the same `(target, source)` slot with `discount_exists` (ADR-0094 — `manual`/`member`/`redeem` each get their own slot and stack), snapshot the preset's `name`/`kind`/`value` at apply time (a later preset edit never rewrites settled history), and re-run `_recompute` to resolve the rupiah amount against the *current* base. A discount is frozen the moment its receipt takes its first payment (`receipt_paid`), corrected only by reopening.

**Manager step-up** `resolveStepUp` (`settlement_routes.dart:606-627`) verifies the PIN against a salted hash server-side and checks the resulting user holds `applyDiscount`; it is fail-closed on any absent/wrong/ambiguous PIN. This is one of the two acts with **no offline path** (see Offline settlement journal below) — a cashier without `applyDiscount` who is offline is refused client-side before an event is even captured.

**Money order-of-operations — `recomputeBill` (`lib/domain/use_cases/bill_recompute.dart:145`)**
1. Per **itemized receipt**: gross = Σ(unit price × assigned qty); line discounts resolve against the value of the units they target and subtract from gross to get `net`; order discounts resolve against `net`.
2. **Bill-scope** discounts resolve against `billSub − Σ(all line discounts)` (the same base every source shares, so stacked sources never compound on each other — ADR-0094), clamp to that base, then fan out proportionally across itemized receipts via `distributeFixed`.
3. Each itemized receipt's `service`/`tax`/`total` come from `computeBreakdown(subtotal, cfg, discount: orderDiscount)` (`bill_math.dart:79-124`) — **discount → service+tax**, per the venue's `taxAfterDiscount` flag: `true` (default) reduces the base both add-ons compute from (`base = subtotal − discount`, service-then-tax on that base); `false` computes service+tax on the gross subtotal and subtracts the discount from the grand total last. Stacking order is always **service-then-tax** regardless of the flag: `service = f(base)`, `tax = g(base + service)`.
4. The bill-level total (`billBreak`) aggregates the *resolved* discount amounts — a second resolution here would let a discounted bill never show fully settled, since the bill total would stay undiscounted while receipts shrink.
5. When every unit is assigned, `splitItemized` targets the bill's own total exactly, pushing any integer rounding remainder onto the receipt with the largest subtotal so parts always sum to the whole.

**Both sides call the same function.** `_recompute` in `settlement_routes.dart` is the persistence half (writes resolved amounts back to `discounts`/`receipts` rows); `settlement_projection.dart`'s `_recompute` calls the identical `recomputeBill` over the cached-bill-plus-journal JSON. `test/settlement_offline_parity_test.dart` runs one event sequence through both and asserts byte-identical bills.

**ADRs** ADR-0037 (catalogue-only, cashier stage), ADR-0038 (stacking order), ADR-0070 (bill-scope), ADR-0094 (source slots), ADR-0118 (member tier discount lands in the `member` slot).

**Gotchas** A member's standing discount and a points redemption are `source: 'member'`/`source: 'redeem'` bill (or receipt) discounts, not a separate mechanism — see Member panel below. A `100%` line discount is not a comp: the priced line stays visible with the reduction beside it; a comp *removes* the item entirely and is a `Void (item)` with reason `comp`, reported as a write-off, never folded into Diskon.

## Refund

**What** A negative payment that unwinds part or all of one payment **leg** — named by `paymentId`, never by method, because a struk can hold two `tunai` legs a method cannot tell apart, and a `piutang` leg has no money method at all (ADR-0121).

**Who** `Capability.refund`.

**Where** `_ReceiptCard._refundSheet` (`cashier_bill_screen.dart:1622-1729`).

**How to use** Open the receipt, tap **Refund** (shown only when `r.refundable > 0`). Pick which leg (chips list every non-refund payment with its remaining refundable amount and method), type the amount (capped at that leg's remainder), confirm.

**Under the hood** `POST /settlement/receipts/<id>/refund` (`settlement_routes.dart:1729-1825`) requires the target `paymentId`, resolves `refundable = leg.amount + Σ(prior refunds against it)`, rejects `over_refund` past that. It inherits the leg's `method` onto a new row with `amount: -amount, isRefund: true, refundsPaymentId: paymentId`. A `piutang` leg refunds by calling `reverseChargeForPayment(paymentId, amount: ...)` — a `MemberDebtKind.reversal` ledger row against the same member, **no rupiah moves**, drawer untouched. Reversal is idempotent by **subtraction**, not presence (`charge − Σreversals`, clamped at zero), so a partial refund followed later by a full reopen nets to exactly the original charge.

**ADRs** ADR-0098 (piutang never a refund method — the leg-based design is *how* that rule now holds, structurally, rather than by banning a chip), ADR-0120, ADR-0121.

**Gotchas** A refund raises the receipt's outstanding again, meeting the guard payments already carry (`amount ≤ outstanding`) — nothing capped the amount before ADR-0121 because the old bill-wide tender lock computed the method and the split-per-payment mode computed the amount for you.

## Bill close / reopen

**What** The cashier's act that ends a [[Bill (tab)]] — locks it against further payment/receipt edits, and (if the table is already freed) snapshots the visit into history in the same transaction.

**Who** `settleBill`; the write-off flavour additionally needs `refund`.

**Where** `_CashierBillViewState._closeBill`/`_reopenBill` (`cashier_bill_screen.dart:240-292`); the "done" pane is `_DonePane` (`cashier_bill_screen.dart:2208-2296`).

**How to use**
1. **Lunas** closes itself automatically the instant every line is assigned to a receipt **and** every receipt is paid (`outstanding == 0`) — there is no confirm button for this path. `_closeBill` reaching the confirm dialog on a settled bill is only the client racing the server's own auto-close.
2. **Tak tertagih** (write-off) is the one manual close: the cashier types a mandatory reason; needs `refund` capability. Books the outstanding as `lossAmount`, a recorded loss distinct from a comp.
3. **Reopen** (undo) is always reachable from the settled/closed pane with no confirm dialog — it is the recovery from a mis-tap, and a second decision in front of the recovery is how a cashier gets stuck.

**Under the hood** `performBillClose` (`settlement_routes.dart:89-219`) is one transaction: stamp `visits.billClosedAt/billClosedBy/lossAmount`, write the audit row (`AuditKind.billClosed` or `billWrittenOff`), and — only when `loss <= 0` (a normal Lunas close, never a write-off) — earn [[Poin]] once per member (`pointsBaseByMember`, splitting per [[Pemilik struk]] under `memberSplit`). If the table is already freed (`tableFreedAt != null`), it also calls `snapshotVisitAndDelete`; otherwise it mirrors a Lunas pill onto the still-occupied table and the snapshot defers until the waiter frees it (ADR-0024's pair). `autoCloseIfSettled` is called after every mutation that can move a bill *toward* settled (`settleOrBroadcast`) — payment, assignment, split, discount — never after one that can only move it away (refund, reopen, delete), so a reopen is never undone a millisecond later. `POST /settlement/visits/<id>/reopen` clears the close stamp, reverses the earn (`reverseEarnForVisit`), and writes `AuditKind.billReopened`; corrections are allowed only while the bill is open — after snapshot, the past bill is immutable.

**ADRs** ADR-0023, ADR-0024, ADR-0069 (auto-close), ADR-0095 (points earn/reversal), ADR-0100.

**Gotchas** `lockGuard` returns `409 bill_locked` on almost every other settlement route once `billClosedAt != null` — a bill locked but not yet snapshotted (table still occupied) must be reopened before any further edit, including a discount or an assignment.

## Member panel (Pemilik tagihan)

**What** The [[Pelanggan (member)|member]] row on a live bill — attach/detach a member, redeem points, see their tab balance and punch-card reward. The only surface where a guest's points turn into money off, because it is the only surface that knows what they owe.

**Who** `settleBill`.

**Where** `lib/ui/features/cashier/member_panel.dart` (`MemberPanel`, `MemberLookupSheet`, `RedeemSheet`).

**How to use**
1. If no member is attached and `membersOn`, a **Cari pelanggan** button opens `MemberLookupSheet` — a debounced search plus a **Daftar baru** enrol shortcut, since at the till "who are you" and "let's sign you up" are the same thirty seconds.
2. Once attached, the panel shows name, phone, a points chip, a debt chip (if `> 0`), a credit-remaining line, and a punch-reward chip if due.
3. **Tukar poin** opens `RedeemSheet` — points capped at `min(member.points, bill.room ÷ pointValue)`.
4. **Lepas** detaches; any live redemption is handed back first (the guest spent nothing, keeps their points).

**Under the hood** Everything here is frozen at the first payment (`live = bill.billClosedAt == null && bill.paidAmount == 0`). Attach is `POST /settlement/visits/<id>/member` — swapping members reverses any live redemption and clears both member-authored discount slots before the new member's standing discount (if configured, and only when `memberSplit` is **off** — under `memberSplit` the tier discount lands per-receipt instead, ADR-0118) lands. Redeem is `POST /settlement/visits/<id>/redeem` — the ledger row (`spendPoints`) and the `redeem`-slot bill discount land in one transaction (ADR-0100); the redemption is a **fixed** discount priced at today's `memberPointValue`, never re-priced later.

**ADRs** ADR-0091 (membership on by default), ADR-0092 (phone is identity, weak reference), ADR-0093, ADR-0094, ADR-0098, ADR-0100, ADR-0118.

**Gotchas** The punch-card reward chip is a reminder, not a button — the cashier comps the free item through the ordinary void-with-comp flow on the line itself; this panel never writes a comp.

## Pemilik struk (Siapa)

**What** Naming **who each split-bill receipt is for** — a second question from "who pays" — live only at a venue holding the `memberSplit` mode (ADR-0118, ADR-0120).

**Who** `settleBill` + the venue's `memberSplit` mode + the `members` module + `membersEnabled`.

**Where** `lib/ui/features/cashier/who_sheet.dart` (`showWhoSheet`, `_WhoSheet`, `_WhoRow`); the mint-time picker lives in `SettlePane._whoRow` (Per item mode only).

**How to use**
1. **Siapa** is offered automatically the first time a split appears with an unnamed share, and reachable any time after via the **Siapa** card in the lines pane.
2. Each share row shows its letter, its money, and either a name or **Cari pelanggan**.
3. Naming someone moves their tier discount, redemption ceiling, points earn base, and — since ADR-0120 — their `piutang` charge, all onto that receipt.
4. A struk is **born named**: in Per item mode, the "who" pick happens before confirm, because the pane mints at commit and there is otherwise a window where a named struk is half-made.

**Under the hood** `POST /settlement/receipts/<id>/member` (`writeReceiptMember`, `settlement_routes.dart:284-324`) writes `receipts.member_id` and — if the venue's nominated preset has `scope: bill|order` — lands the standing discount in the `member` order-scope slot. `memberUnitsOf` (server, `members.dart`) is the one function both stempel and the member report read to split units: on-receipt units belong to that receipt's named member, everything else falls to the [[Pemilik tagihan]].

**ADRs** ADR-0118, ADR-0119 (member report reads the same subtraction), ADR-0120.

**Gotchas** Switching `memberSplit` off **freezes, never deletes** — stored `receipts.member_id` values stay, the picker disappears, and earn/attribution fall back to the bill owner from that point on.

## Piutang collection (Terima piutang)

**What** Taking money against a member's tab, from nobody's bill — a member may walk in only to settle up, with nothing seated and nothing open.

**Who** `settleBill`.

**Where** `lib/ui/features/cashier/debt_collect_sheet.dart` (`showDebtCollectSheet`, `_DebtorPicker`, `_CollectForm`).

**How to use**
1. Opens on the **debtor list** — everyone who owes, largest first, with a prefix search — rather than a search box, because "who owes" is the question and the venue already knows.
2. Pick a debtor; type an amount (defaults to their full balance), pick a method (every method except `piutang` — a tab cannot pay a tab), attach proof if non-cash, optional note.
3. Submitting books the collection and offers a printed **TERIMA PIUTANG** slip naming the balance after.

**Under the hood** `POST /members/<id>/debt/payments` → `payDebt` (`lib/server/debts.dart:255-314`), gated `settleBill` (`members_routes.dart:182-184`). Re-checks the balance inside `db.transaction` (`amount > balance` refuses `overpayment`) — the same transactional-guard rule ADR-0100 states once. A cash collection lands in the drawer but reads only through the **Piutang** report section, never the day's payment mix, because it discharges a claim booked as revenue at a *previous* bill close.

**ADRs** ADR-0098, ADR-0100.

**Gotchas** This is the one settlement-adjacent surface reached from `/members` too (the directory), but only `/kasir`'s entry can collect mid-transaction against a live bill's own tab payment — collection from the directory and collection from `/kasir` are the same route.

## Cashier history (Lunas / Semua, past bills)

**What** The read-only view of recently closed bills, bounded on two axes — the last N days and the newest M rows within them — with per-table filtering as a client-side chip over the server-scoped list.

**Who** `settleBill`.

**Where** Rendered inside `CashierScreen`'s Lunas/Semua segments via `BillCard.fromPastBill`; detail view is `PastBillDetailScreen` (`cashier_bill_screen.dart:2571-2679`).

**How to use** Tap a settled card in Lunas/Semua to open its immutable **Struk pembayaran** detail — totals, line-by-line batch grouping, and every payment/refund row with proof thumbnails (`ProofScope.history`).

**Under the hood** `GET /settlement/history` (see Cashier bill list above) and `GET /settlement/sessions/<id>/bill` (`_buildSessionBill`, `settlement_routes.dart:2817-2924`) reconstruct a bill-shaped JSON from the `TableSession`/`TableSessionTickets`/`TableSessionReceipts`/`TableSessionPayments` snapshot tables — the frozen record written once, at whichever of table-close/bill-close completed the visit's pair.

**ADRs** ADR-0079 (growing-limit paging), ADR-0024.

**Gotchas** Any filter over this list belongs server-side (`?tableId=`, `?onAccount=1`) — filtering the loaded page client-side reports "none" for a bill that merely sits below the current page boundary, which is exactly the trap ADR-0079 documents and the code (`_filter` nowhere in this list) deliberately avoids.

## Printing (Tagihan / Struk pembayaran / Rincian pilihan)

**What** The guest-facing money document, at three granularities: whole-bill, per-receipt, and an ephemeral pre-mint selection slip.

**Who** `settleBill`.

**Where** `lib/ui/features/cashier/widgets/paper_preview.dart` (`PaperPreview`, screen renderer) mirrors `BillStrukData`, the same data the ESC/POS renderer (`core/printing/bill_struk_renderer.dart`) consumes — one source, two renderers, so the cashier never commits a document sight-unseen.

**How to use** Print buttons appear at bill level (`_TopActions`), per-receipt (`_ReceiptCard` action row), and — only in Per item mode with a non-empty tap selection — **Cetak pilihan** in the settle pane's summary box, which prints the tapped-but-unconfirmed selection.

**Under the hood** The document's state is **read off itself**, never chosen: no payment recorded ⇒ **Tagihan**; any payment ⇒ **Struk pembayaran** (ADR-0023). A **Rincian pilihan** (selection slip, ADR-0122) persists nothing — its total is `Bill.prorate(subtotal)`, the same figure the confirm button beneath it will charge, and reuses `BillDocKind.itemizedReceipt` with a `docLabel` reading "Tagihan sementara" instead of a minted share's "Bagian N/M" so nobody mistakes the slip for evidence a receipt exists. Server-side rendering (`printDoc`, `settlement_routes.dart:1827-1917`) sends to a **venue** printer; a client-rendered path (device printers, and always the Rincian pilihan, which has no receipt for the server to re-render) sends bytes this device rendered.

**ADRs** ADR-0023, ADR-0066, ADR-0067, ADR-0122.

**Gotchas** Two Rincian pilihan slips need not sum to the bill total to the rupiah — each rounds on its own; they are quotes, and the minted receipts are what the arithmetic closes on.

## Offline settlement journal + client Drift database

**What** A device-local, append-only, per-visit **ordered chain** of settlement acts a [[Terputus (client disconnected)|terputus]] till has captured but not yet delivered — the [[Antrean setelmen]]. Distinct from the [[Antrean kirim]] (order queue) in three load-bearing ways: it is a **chain**, not a FIFO of independents (each event reads what the last one wrote); it is **read as well as drained** (the cashier needs a live outstanding and change while offline); and it **never expires** (a business-day rollover retires an order, but cash is already in the drawer).

**Who** `settleBill` (identical capability gate to every online settlement route — the offline path grants no new authority).

**Where** `lib/domain/models/settlement_event.dart` (`SettlementEvent`, `SettlementEventKind`), `lib/data/services/settlement_journal.dart` (`SettlementJournal`, a `StateNotifier<JournalState>`), `lib/data/services/settlement_sync.dart` (`_sendEvent`, the replay function), `lib/domain/use_cases/settlement_projection.dart` (`projectBill`), `lib/data/db/client_db.dart` (`ClientDb`, Drift, ADR-0124).

**How it works**
1. **Every mutating call** in `SettlementRepository` goes through `_act`/`_actOnReceipt`, which decides online-vs-captured per call: if the visit is [[Kunjungan otoritatif-lokal|local-authoritative]] (`journal.isLocal(visitId) || wsConnState != open`), it appends a `SettlementEvent` to the journal and re-projects; otherwise it calls the API, and on any **non-`ApiException`** failure (transport, not a business refusal) it *also* captures — "the cashier is standing in front of a guest and refusing the act is worse than replaying it" (`settlement_repository.dart:267-287`).
2. **Client-minted ids, online too.** Receipt, payment, discount and refund ids are minted client-side (`_mintId`/`Uuid().v4()`) and sent even on an online call — not just offline — so one row has one provenance regardless of path, and a queued refund can name a payment leg that has not reached the host yet.
3. **Idempotency key.** Every settlement POST/PATCH/DELETE carries `x-idempotency-key: <event.id>`. `idempotent()` (`lib/server/idempotency.dart`) wraps the whole settlement router: on a repeat key it replays the first 2xx response verbatim with **no second write and no second broadcast**; a refusal (non-2xx) is never stored, because a chain halts on a refusal rather than retrying it.
4. **The read path projects.** `SettlementRepository.fetchBill`/`_project` reconstitutes a bill by taking the last-cached server bill JSON (`CachedBills`, prefetched for **every** open visit while online, throttled per-visit at a 2-minute TTL) and running its visit's undrained journal events through `projectBill` (`settlement_projection.dart:31-42`). `projectBill` **only moves data around** — receipts, discount rows, payment rows — and delegates every rupiah figure to the identical `recomputeBill` the server calls; a second money rule in the projection is exactly the drift ADR-0123 forbids, and `test/settlement_offline_parity_test.dart` pins it by running one event sequence through both routes and the projection and diffing the result.
5. **Drain.** `SettlementJournal.drain()` (`settlement_journal.dart:327-387`) replays every visit's chain in capture order, **halting that visit on its first refusal** ("a refund whose payment was refused must never land") while other visits keep draining. `send_queue_drain.dart` wires this to the `connected` WS event and runs it **after** the order queue drains (`_drainOrders` then `_drainSettlement`) — money after food, always, so a replayed payment never lands against a bill that does not yet hold the lines it paid for.
6. **Refusal vs staleness.** A 4xx from a captured event's replay throws `SettlementRefused`, which parks the rest of that visit's chain (`status: 'parked'`, `failCode` stamped on the first parked event) and surfaces a **blocking** sheet (`SettlementRefusalListener`/`_RefusalSheet`) naming the stranded amount — heavier than the ordinary offline-order toast, because the cash is already collected. A bill that merely *grew* while the till was dark (e.g. someone else added a payment) settles **short**, which is a correct, non-refusing outcome — only a genuine contradiction (the bill already closed by someone else, the receipt gone, the line voided, a redeem over balance) refuses.
7. **Late-drain backdating.** Every captured event carries `capturedAt`; the server honours it for the payment's `at`, the audit row, and which business day the money lands in, rather than stamping drain time. A payment that drains after its own business day closed writes `AuditKind.settlementArrivedLate` in addition to the ordinary payment audit row.
8. **Client Drift database (ADR-0124).** `ClientDb` (`lib/data/db/client_db.dart`) holds three tables: `SettlementEvents` (the journal — `id, visitId, seq, kind, payloadJson, capturedAt, actorId, status, failCode`), `CachedBills` (`visitId, billJson, fetchedAt` — one row per open visit, the projection's base), and `CachedPayable` (one row, the last `/settlement/payable` array, so a cold boot with no host still has a way *into* the cached bills). It is opened `ClientDb.lazy()` so the provider is synchronous from the first frame — a captured payment in the frames before the SQLite file resolves must not be lost. **A cache and a journal, never a source of truth**: nothing here survives its chain draining.

**Two acts stay online-only.** A manager step-up PIN (a credential; ADR-0099) and member **lookup** (ADR-0092 makes the phone the identity, so no mirrored directory exists client-side) have no offline path — `SettlementRepository.applyDiscount`/`removeDiscount`/`applyBillDiscount`/`removeBillDiscount` refuse client-side (`_refuse`, error code `approval_offline`) before capturing an event, if `approverPin != null && isLocal`. Redeeming an **already-attached** member's points offline is fine — the member is already on the bill, no lookup is needed.

**Two islanded tills, not prevented.** Two devices can both fully collect the same bill while both are offline (ADR-0116's reasoning, applied here) — a designated-cashier flag would itself be a lease the vanished host granted, so there is nothing to hold. This is made **loud at drain**, not prevented at capture: whichever chain drains second either lands cleanly (the bill still has room) or refuses on contradiction and parks, surfacing on the blocking sheet.

**ADRs** ADR-0090 (the sibling order queue, for contrast), ADR-0098, ADR-0100, ADR-0116 (two-islanded-tills reasoning, table-lock origin), ADR-0120, ADR-0121, ADR-0123 (the whole design), ADR-0124 (the client database).

**Gotchas**
- `SettlementJournal` caps at 100 events per visit and 1000 total on the device (`maxPerVisit`, `maxTotal`, `settlement_journal.dart:122-127`) — tripping either throws `SettlementJournalFull`, surfaced through the same error-bus refusal path as a server-side no.
- `visitOfReceipt` asks the **journal first**, not the cache — a receipt minted this instant by a `mintReceipt`/`splitEven` event exists nowhere in a cached bill yet, so falling through to the cache-only lookup would strand a same-gesture payment behind a receipt that is right there.
- `SettlementJournal.forget(visitId)` drops both the journal and the cache for a visit — called when a bill closes clean, because nothing offline-cached is authoritative once the host has taken it. Acknowledging a **parked** (refused) chain also calls `forget` — the events go, and the rupiah delta becomes a human problem the audit row already records.

## Settlement money function (`recomputeBill`)

**What** The one pure function that computes every rupiah figure on a bill — discount → service → tax → total, per receipt and for the whole bill — called by both the server route and the offline projection, and by nothing else.

**Who** N/A (internal).

**Where** `lib/domain/use_cases/bill_recompute.dart` (`recomputeBill`, `RcLine`, `RcReceipt`, `RcAssign`, `RcDiscount`, `RcResult`); the shared primitives (`computeBreakdown`, `resolveDiscountAmount`, `distributeFixed`, `splitItemized`, `isFullyAssigned`) live in `lib/domain/use_cases/bill_math.dart`.

**Callers**
- **Server**: `_recompute(db, visitId)` in `lib/server/routes/settlement_routes.dart:2425-2462` — gathers plain records from Drift (`_rcInputs`), calls `recomputeBill`, writes the resolved discount `amount`s and receipt money fields back to the DB.
- **Offline projection**: `_recompute(bill, cfg)` in `lib/domain/use_cases/settlement_projection.dart:332-446` — gathers the identical shape from the cached-bill-plus-journal JSON, calls `recomputeBill`, and mutates the JSON in place.

**Money order-of-operations** (see "Discounts + tax stacking" above for the full walkthrough): per-receipt line discounts fold into subtotal → order discounts resolve against that net → bill-scope discounts resolve against the bill's line-discounted subtotal and fan out across itemized receipts via `distributeFixed` → each receipt's service and tax come from `computeBreakdown` (service-then-tax always; discount-before-or-after governed by the venue's `taxAfterDiscount` flag) → when every unit is assigned, `splitItemized` targets the bill's exact total and absorbs the rounding remainder on the largest receipt.

**Testing** `test/settlement_offline_parity_test.dart` runs one event sequence through the live routes and through `projectBill` and asserts the two bills are byte-identical — the mechanical guarantee behind "a second money rule is exactly the drift ADR-0123 exists to prevent."

**ADRs** ADR-0037, ADR-0038, ADR-0068, ADR-0070, ADR-0094, ADR-0123.

**Gotchas** `recomputeBill` has **no covering unit test of its own** per `codegraph`'s blast-radius report (as of this writing) — the parity test exercises it only indirectly, through the server route and the projection. `RcReceiptMoney.discountAmount` on an itemized receipt is a *reporting* figure — line discounts (already folded into `subtotal`) plus the applied order discount — not a second source of truth; the printed slip and the totals card both read it as such.
