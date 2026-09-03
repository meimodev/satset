# 04 · Membership, petty cash & debt

This area covers the **Pelanggan (member)** directory and everything that hangs off a member — points, stempel, tier discount, split-bill attribution, the **Laporan pelanggan** report — plus two adjacent venue-local ledgers that share the same architectural shape: the **Kas kecil** petty-cash box and the **Piutang** (tab/debt) ledger. All three are append-only, single-writer ledgers whose balance is `SUM(delta)` and is never stored; all three are venue-local (no cloud sync); and all three are gated fail-closed by a 404 (not 403) when the owner has not opted in.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Member directory (Pelanggan) | `/members` | `manageMembers` | `lib/server/routes/members_routes.dart` |
| Member enrol / lookup (till) | (sheet, from `/kasir`) | `settleBill` (or `manageMembers`) | `POST /members` |
| Member edit / merge / delete | `/members` (sheets) | `manageMembers` | `PATCH/DELETE /members/<id>`, `POST /members/<id>/merge` |
| Points hand-adjust | `/members` (sheet) | `manageMembers` | `POST /members/<id>/points` |
| Member tier discount / redeem | till bill overlay (`MemberPanel`) | `settleBill` | `POST /settlement/visits/<id>/redeem` etc. |
| Stempel (punch card) | till bill overlay + guest plane | — (read), `settleBill` (settle) | `punchStatus`, `guestPunchStatus` |
| Laporan pelanggan (member report) | `/member-report` | `viewReports` or `manageMembers` | `GET /members/report`, `GET /members/<id>/report` |
| Kas kecil (petty cash) | `/kas` | `manageCash` or `editSettings` | `lib/server/routes/cash_routes.dart` |
| Piutang / tab (debt) — collect | till (`DebtCollectSheet`) + `/members` | `settleBill` (collect), `manageMembers`/`refund` | `lib/server/routes/members_routes.dart` (piutang endpoints), `lib/server/debts.dart` |
| Piutang charge (pay by tab) | till bill overlay | `settleBill` | `POST /settlement/receipts/<id>/payments` (`method: piutang`) |

## Member directory — Pelanggan (ID · EN: Pelanggan · Member)

**What** A durable person the venue recognises across visits: name, phone, join date, optional note/birthday, an optional four-field address, plus three derived figures (points balance, punch progress, debt balance) nothing stores. **The phone number is the identity** (ADR-0092) — unique venue-wide; enrolling on a number that already exists *attaches* to that member instead of creating a second one, and there is no anonymous member. A short display-only code (last 6 digits of the phone) prints on the receipt. Membership is venue-local — it lives in the venue's own Drift DB, never the cloud, so a lookup can never fail because the internet is down (ADR-0091).

**Who** Enrol/lookup: any cashier (`settleBill`) or a keeper (`manageMembers`) — it happens at the till mid-settlement. Edit, hand-adjust points, merge, delete, and reading one member's lifetime visit history: `manageMembers` only.

**Where** The directory lives at `/members` (tablet-only, reached from the Venue hub, same shape as `/audit` and `/kas` — `lib/ui/features/admin/members_screen.dart`). Lookup/enrol at the till happens inline in the bill overlay's `MemberPanel` (`lib/ui/features/cashier/member_panel.dart`), via `MemberLookupSheet`.

**How to use (directory)**
1. Open Venue hub → **Pelanggan** (`/members`). The screen title is "Pelanggan" (`memTitle`), with a live count ("N pelanggan" via `memCount`).
2. Search by name or phone prefix (`memSearchHint`: "Cari nama atau nomor").
3. Optional filters: **Ulang tahun bulan ini** (`memBirthdayFilter`, birthday this month) and **Berutang** (`memDebtFilter`, has an outstanding tab) chips; a **Belum kembali** (`memLapsedLabel`, "lapsed") days-picker chip.
4. Tap **Tambah** (`memActionAdd`) to open `MemberFormSheet` in add mode (`memSheetAddTitle`: "Pelanggan baru") — fields: Nama (`memFieldName`), Nomor HP (`memFieldPhone`, with helper text), optional birthday, note, credit limit, and the four address pickers (Kabupaten/Kecamatan/Kelurahan + street line).
5. Tap a row to open `_MemberDetailSheet`: shows Poin (`memColPoints`), Stempel (`memColPunch`, "Stempel N/target" or "Hadiah siap" when a reward is due), Kunjungan (`memColVisits`), Total belanja (`memColLifetime`), Bergabung (`memColJoined`), plus birthday/note/address when present.
6. From the detail sheet: **Ubah** (`memActionEdit`, edit), **Koreksi poin** (`memActionAdjust`), **Gabungkan** (`memActionMerge`), **Koreksi piutang** (`memActionDebtAdjust`), **Hapus buku** (`memActionWriteOff`), **Hapus** (`memActionDelete`).
7. The detail sheet also shows a **Riwayat poin** (`memLedgerTitle`) ledger tab, a **Piutang** (`memDebtTitle`) balance/ledger tab, and a **Kunjungan** (visits) tab of lifetime settled bills, paged by growing limit (`memVisitsMore` "muat lebih banyak").

**How to use (till lookup/enrol)** From the cashier bill overlay, tap the member chip when none is attached (`cshMemberNone`) → **Cari pelanggan** (`cshMemberFind`) opens `MemberLookupSheet`; search by phone/name, or tap **Daftar baru** (`cshMemberEnrol`) to enrol on the spot (name + phone only — two fields, done in seconds).

**Under the hood**
- Server: `lib/server/members.dart` — the single writer for `members` and `member_points`. Key functions: `createMember` (enrol, attaches on phone collision, throws `MemberException('phone_taken', memberId: existing.id)`), `updateMember`, `deleteMember` (anonymise), `mergeMembers`, `getMember`/`listMembers`/`findMemberByPhone`, `_decorate` (attaches derived points/debt/visits/punch in two grouped queries rather than N).
- Routes: `lib/server/routes/members_routes.dart` — `GET /members`, `GET /members/<id>`, `POST /members`, `PATCH /members/<id>`, `DELETE /members/<id>`, `POST /members/<id>/merge`, `POST /members/<id>/points`, `GET /members/<id>/visits`.
- Repository: `lib/data/repositories/members_repository.dart` (`MembersRepository`, provider `membersProvider`) — `enrol`, `edit`, `remove`, `merge`, `adjustPoints`, `detail`, `visits`, plus the piutang methods below. Applies the server's response directly rather than waiting for the WS echo, "so the acting device sees its own write immediately."
- Tables: `Members` (`lib/server/db/tables.dart:1387`) — `id, name, phone` (unique, digits-normalised), `code`, `note`, `birthday`, `joinedAt`, `debtLimit` (nullable — null means "inherit venue default"), `kabupaten/kecamatan/kelurahan/addressText`. `MemberPoints` (`:1449`) — append-only, `kind` (`earn|redeem|adjust|reversal`), `delta`, `visitId`, `baseAmount`, `note`.
- Wire: `MemberDto`/`MemberDetail`/`MemberLedgerEntry`/`MemberVisitDto` in `lib/data/models/member_dto.dart`; domain `Member` in `lib/domain/models/member.dart`.
- Gate: `MemberConfig.enabled = venueSettings.membersEnabled && venueHasModule(moduleMembers)` (`lib/server/members.dart:104`). Off ⇒ **every** `/members*` route answers `404 members_disabled`, never 403 — `enabledGuard()` in the routes file — so a client can't tell an unlicensed venue from an old server (ADR-0091).

**Offline behaviour** Membership acts (lookup, attach, enrol, redeem) are **online-only by design** (ADR-0093) — they are settlement acts, and a queued redemption could let two disconnected clients spend the same balance. Nothing here rides the `SendIntentKind` offline-intent queue (ADR-0090). A `terputus` (disconnected) client shows "sambungkan dulu" and nothing is queued.

**ADRs** ADR-0091 (venue-local, not cloud), ADR-0092 (phone is identity; delete anonymises), ADR-0093 (membership pays out at settlement — all four benefits resolve at the till, never on the menu/cart), ADR-0079 (ledger/visit pages by growing limit).

**Gotchas**
- Deleting a member **anonymises**: the `members` row and the points ledger are hard-deleted, but every closed bill keeps its `memberId` and renders as "Pelanggan dihapus" — trade stays counted (`memDeleteBody`: "{name} dan riwayat poinnya hilang permanen. Transaksi yang pernah dibuat tetap terhitung di laporan.").
- **A member who owes money cannot be deleted** — `deleteMember` throws `MemberException('has_outstanding_debt')` while the piutang balance is non-zero (checked inside `db.transaction`, ADR-0100). Collect or write off first.
- Merge folds `fromId` into `toId`: points and debt ledgers repoint (balances are `SUM(delta)`, so nothing needs reconciling), `tableSessions.memberId`, `visits.memberId` and `reservations.memberId` all repoint too, and `fromId`'s row is deleted — all six writes in one `db.transaction` (ADR-0100 amendment), because a fold that stops halfway leaves points naming one person and debt naming another.
- `MemberPointKind` and `MemberDebtKind` enum names are **persisted** (`member_points.kind`, `member_debts.kind`) — never rename one; it's the join to the ARB template.

## Points — Poin (ID · EN: Poin · Points)

**What** A loyalty-points ledger, live only when `memberPointsEnabled` is on. Append-only, `SUM(delta)`, never negative, never expires. Earned **once, at bill close** (ADR-0095) — not per payment — computed on the bill net of discount, excluding service and tax, at an owner-set rate (default 1 poin per Rp 1.000, floored). A reopen **reverses** the earn; the re-close earns afresh. A refund posts a negative earn. A walkout earns nothing.

**Who** Earning/redeeming ride `settleBill` at the till. Hand-adjustment (`adjustPoints`) needs `manageMembers`, a mandatory reason, and always writes `AuditKind.memberPointsAdjusted`.

**Where** Redeem happens from the till's `MemberPanel` → **Tukar poin** (`cshMemberRedeem`) opens `RedeemSheet` (`lib/ui/features/cashier/member_panel.dart`). Hand-adjustment is the "Koreksi poin" sheet on `/members`.

**How to use (redeem)**
1. With a member attached and a live bill open, tap **Tukar poin**.
2. Enter a points amount (minimum `redeemMin`, default 10); the sheet shows the max redeemable and the resulting rupiah value (`cshMemberRedeemWorth`).
3. Confirm — the discount lands in the bill's `redeem`-source slot and the points ledger row is written in the same settlement request (or not at all).
4. To undo before payment: **Batal tukar poin** (`cshMemberRedeemUndo`).

**Under the hood**
- Server functions (`lib/server/members.dart`): `spendPoints` (redeem — checks `points >= redeemMin`, `balance >= points`, all inside `db.transaction`), `earnPointsForVisit` (idempotent per-visit, or per-member under `memberSplit` — ADR-0118), `reverseEarnForVisit` (reverses **every** live earn row on a reopen, not just the last), `reverseRedeemForVisit`, `_post` (the one insertion point, floor-checked and transactional per ADR-0100).
- Routes: redeem/redeem-remove live in `lib/server/routes/settlement_routes.dart` at both bill grain (`POST /settlement/visits/<visitId>/redeem`, `/redeem/remove`) and receipt grain under `memberSplit` (`POST /settlement/receipts/<receiptId>/redeem`, `/redeem/remove`). Hand-adjust: `POST /members/<id>/points`.
- The discount source slot is `redeem` — one of three (`manual|member|redeem`) bill/receipt-scope authorities per ADR-0094/ADR-0118, enforced by a partial unique index `(receipt_id, source)`.
- `pointsBaseByMember` (`lib/server/members.dart:971`) — how a closing bill's points base divides between members under `memberSplit`: the Pemilik struk (receipt owner) takes their own receipts' base, the Pemilik tagihan (bill owner) takes everything left (a subtraction, not a sum, so the parts always reconcile to `billBase`).

**Offline behaviour** No offline path — lookup/attach/enrol/redeem all require the server (ADR-0093).

**ADRs** ADR-0095 (earn once at close, never expires; Poin beredar liability figure instead of expiry), ADR-0094 (discount source slot), ADR-0118 (attribution rides the receipt — split-bill points), ADR-0100 (guard only real inside a transaction — amendment names `members.dart`'s three unwrapped writers as the fix).

**Gotchas**
- `MemberPointKind` values: `earn`, `redeem`, `adjust`, `reversal` — persisted, never rename.
- Under `memberSplit`, a visit can hold **N earn rows** (one per member on it) — `reverseEarnForVisit` must reverse all of them on reopen, not just the newest; the code comment on `_liveEarnRows` calls out the exact bug this replaced.
- Earn/reversal and redeem/reversal tallies are struck **per member**, not per visit — striking across the whole visit would let one member's reversal silently cancel another member's earn.

## Stempel — Kartu stempel (ID · EN: Kartu stempel · Punch card)

**What** An owner-run "buy N, get one free" program on **one menu item at a time**, live only when `memberPunchEnabled` is on. Progress is **derived from settled history**, never a stored counter — paid, non-voided, non-comped units of the punch item. The reward is booked as a **Comp** at settlement (reports as a write-off, already audited), and the free unit does not count toward the next card.

**Who** Read-only figure everywhere; the reward is applied through the ordinary comp path at settlement (`settleBill`).

**Where** Shown on the member row/detail in `/members` (`memColPunch`: "Stempel N/target", or `memRewardDue`: "Hadiah siap" when a card is complete) and on the till's `MemberPanel`. Also the **only** member fact exposed on the cleartext guest plane (`:8080`, ADR-0110).

**How to use** Nothing to configure per-guest — it's automatic. A guest can check their own count on the guest web page (scan the venue QR) via `guestPunchStatus`, which returns two integers only (`progress`, `target`) — no name, phone, points, or debt crosses that boundary.

**Under the hood**
- `PunchStatus` class + `punchStatus()` (`lib/server/members.dart:141-254`): walks every closed session the member owned or (under `memberSplit`) was named on a receipt of, filters tickets to the configured `punchItemId`, and counts units via `memberUnitsOf` — bought (not voided) vs. given (void with `voidReasonCode == 'comp'`). `progress = bought % target`; `rewardDue = earned > given`.
- `memberUnitsOf` (`:274`) is **the** line-attribution rule shared with `memberHistory` — a line assigned to a receipt belongs to that receipt's Pemilik struk; a line on no receipt (every unit of an amount receipt) belongs to the Pemilik tagihan. Voids are left in; the caller decides what a void means (comp = reward here, non-purchase in the report).
- Guest-plane read: `guestPunchStatus()` (`:318`) — 404s identically to every authenticated member route when the program isn't running (ADR-0091's fail shape, reused here).

**Offline behaviour** Read-only derivation, but still requires the server (venue-local DB) — unreachable if the LAN server itself is down; no client-side computation.

**ADRs** ADR-0110 (the guest-plane exposure is capped at two integers, rate-limited, and answers identically for a known/unknown phone to avoid an enumeration oracle), ADR-0118 (split-bill unit attribution — a shared `qty:3` line divided 2+1 punches two cards, not one card three times).

**Gotchas** A program needs *both* the toggle and a configured `punchItemId` — `MemberConfig.punchRunning` ANDs them; a toggle alone runs nothing.

## Member attribution & split-bill (Pemilik tagihan / Pemilik struk)

**What** Every bill has exactly one **Pemilik tagihan** (bill owner, `visits.memberId`) — the party's identity on the floor, and the default/backstop for money no receipt claims. A venue holding the `memberSplit` mode key may *additionally* name a **Pemilik struk** (receipt owner, `receipts.memberId`) per receipt — "who is this share *for*", a different question from "who pays this share." The owner gets points/stempel/tier-discount/redeem/piutang against their own receipt; unclaimed money and units still fall to the bill owner.

**Who** Attaching/detaching a Pemilik struk is gated on `memberSplit`; reads (`punchStatus`, `memberUnitsOf`, `pointsBaseByMember`, the member report) are **unconditional** — the mode gates the write and the picker, never a read, so an already-attributed window keeps reporting as attributed after the mode is switched off.

**Where** The till's split-bill flow, once `memberSplit` is on for the venue.

**Under the hood**
- Routes: `POST /settlement/visits/<visitId>/member` (attach bill owner) / `.../member/detach`; `POST /settlement/receipts/<receiptId>/member` (attach Pemilik struk) / `.../member/detach` — all in `lib/server/routes/settlement_routes.dart`.
- `MemberConfig.splitEnabled` composes three facts: `membersEnabled && venueHasModule(moduleMembers) && venueHasMode(modeMemberSplit)` — fails **closed** (unlike the sellable-module fail-open), because a mis-offered picker writes a mis-attributed row into a ledger that never expires.
- An amount receipt (even split) *may* carry a declared member (money is attributable — the share's total is a number) but never a receipt letter and never contributes stempel units (there's nothing to say which lines its guest ate).
- `receipts.member_id` is a weak reference like `visits.member_id` — a deleted member leaves it dangling (ADR-0092); anonymising never rewrites who owed/bought what.
- Attribution freezes at the receipt's first payment (ADR-0068) — correcting it afterward goes through the audited reopen.

**ADRs** ADR-0118 (member attribution rides the receipt — the core decision), ADR-0119 (member report reads what they bought — extends the subtraction to line items), ADR-0120 (a tab follows the struk — extends attribution to piutang charges), ADR-0121 (a refund names its leg — piutang becomes reversible under split tender).

**Gotchas**
- One member field, not two: a tab reads `receipts.member_id ?? visit.member_id` — the same fallback subtraction as points/units, deliberately not a second "debt-only member" field.
- Reports keep counting **bills** by owner (so saved comparisons don't change meaning); the finer per-member rollup lives in the ranked list / member history only.

## Laporan pelanggan — member report (ID · EN: Laporan pelanggan · Member report)

**What** A dedicated report answering what the venue Reports' Keanggotaan block can't: who are the members (browsable, sortable, searchable directory of trade) and what do they actually buy (product rollup per member). Two panes: a ranked list on the left (sortable/filterable client-side over a server-capped 500 rows), one member's bills + product rollup on the right.

**Who** `viewReports` **or** `manageMembers` — the same "two authorities" shape as `/kas` and `/opname`, because the person enrolling guests and the person reading their spend back are rarely the same.

**Where** `/member-report`, tablet-only, reached from the Venue hub.

**How to use**
1. Open Venue hub → **Laporan pelanggan** (`mrpTitle`). Subtitle: "Riwayat belanja pelanggan terdaftar" (`mrpSub`) or, once loaded, "N aktif dari M pelanggan" (`mrpActiveOf`).
2. Pick a range chip: Hari ini / Kemarin / 7 hari / 30 hari / Bulan ini / **Semua** (`mrpRangeAll`, this report's only, since it's aggregated not per-bill) / custom.
3. The overview tiles show enrolled, active members, member vs. guest bill split, split-bill count (only non-zero under `memberSplit`), points earned/redeemed/outstanding, and the estimated points liability.
4. Scroll the ranked list (spend, visits, points, name, or "recent" sort — `MemberSort` enum) and tap a member to open the **Drill** sheet.
5. The drill has two tabs: **Produk** (`mrpTabProducts`) — every item they bought, qty + spend, newest name first — and **Kunjungan** (`mrpTabVisits`) — their bills in the window, each showing whether they were bill-owner or just a named receipt, and their share of the total.
6. A member whose spend includes an amount-receipt share with no lines shows an **Untracked spend** note (`untrackedSpend`) — money attributed with no product to show for it, named rather than silently disagreeing with the product rollup.

**Under the hood**
- Server: `memberTradeReport` (walks the window once via `memberWindowTrade` + `memberWindowPoints`, hands the scans to `memberReportSection` so the two never disagree about the same split bill), `memberHistory` (one member's lifetime-scoped-to-window bills + products, capped at 200 by default, up to 500), `memberUnitsOf` (shared line-attribution with `punchStatus`).
- Routes: `GET /members/report` (the ranked list + overview), `GET /members/<id>/report` (one member's drill — **does not** 404 for a deleted member, because their trade is the venue's own record; only `GET /members/<id>` 404s).
- Window resolution: `reportWindow` (shared with `/reports`, so business-day rollover agrees) except `range=all`, resolved **only** in `members_routes.dart`'s `windowOf` — deliberately not in the shared resolver, because an unbounded window is safe here (aggregated, capped) but would blow the accounting report's 92-day per-bill cap.
- Repository: `lib/data/repositories/member_report_repository.dart` — `MemberReportRepository`/`memberReportProvider`, `MemberRange` enum (`today, yesterday, d7, d30, month, custom, all`), `MemberSort` enum (`spend, visits, points, recent, name`).

**Offline behaviour** Read-only report over the venue-local DB; requires the server (same as every admin/report screen).

**ADRs** ADR-0119 (the whole feature — new screen not a bigger section, lines divide the way money does, two window resolvers on purpose, list capped server-side/sorted client-side, one walk feeds both halves).

**Gotchas**
- The venue Reports' Keanggotaan block is **left exactly as it was** — a closed month must keep printing what it printed, and this screen is the finer drill, not a replacement.
- A void is not a purchase — it's excluded from the product rollup and the per-bill item count (a bill a member did settle can legitimately show zero items), even though stempel *does* count a comped void as a reward.

## Kas kecil — petty cash (ID · EN: Kas kecil · Petty cash)

**What** The venue's standing float of physical cash for small outgoings (market shopping, ice, gas, an ojek run, a day labourer's wage). **Not the drawer** — the drawer holds sales cash from payments; the box only ever pays money out, and nothing links the two automatically. Append-only ledger, `SUM(delta)`, never stored, **cannot go negative** except a reversal or a count (ADR-0088). Fully isolated from every sales figure (`netTotal`, `settledTotal`, Bruto, payment mix — ADR-0089); reads through its own Kas section in Reports.

**Who** Posting an expense: `manageCash` (a supervisor spends). Funding (top-up) and counting (opname): `editSettings` (the owner's authority). A reversal is reachable by either authority. Reading the ledger: any of `manageCash`, `editSettings`, or `viewReports`.

**Where** `/kas`, tablet-phone-both? — screen is reachable via the Venue hub with a phone-specific "text only" notice (`_KasPhoneNotice`); full ledger UI lives in `lib/ui/features/admin/kas_screen.dart`.

**How to use**
1. Open Venue hub → **Kas kecil** (`kasTitle`). The hero shows **Saldo kas** (`kasBalance`) — the current balance.
2. Three actions at the top: **Isi kas** (`kasActionTopUp`), **Pengeluaran** (`kasActionExpense`), **Opname** (`kasActionCount`).
3. **Isi kas** (`kasSheetTopUpTitle`: "Isi kas kecil") — amount + optional note. `editSettings` only.
4. **Pengeluaran** (`kasSheetExpenseTitle`: "Pengeluaran kas") — amount, a required category (`kasFieldCategory`: Belanja bahan / Operasional / Transport / Upah harian / Lainnya), optional note, optional photo (camera or gallery — unlike a bill payment's proof, this one is optional: "the pasar has no receipt printer"). `manageCash`.
5. **Opname** (`kasSheetCountTitle`: "Opname kas") — enter the **absolute** cash counted; the sheet shows the resulting signed variance (`kasVariance`: "Selisih {amount}") against what the ledger says (`kasLedgerSays`). `editSettings`.
6. Tap any ledger row to open its detail sheet; **Batalkan mutasi kas** (`kasReverseTitle`) reverses it with a mandatory reason (`kasReverseBody`, `kasFieldReason`) — at most once per row, no time limit.
7. The ledger caps at `kCashMaxLoaded` loaded rows, with a `logCapNotice` when the cap is hit — page further with the growing-limit pattern.

**Under the hood**
- Server: `lib/server/cash.dart` — `topUpCash`, `spendCash` (the one path the negative-balance guard applies to, transactional per ADR-0100), `countCash` (writes a **zero-delta row** even on an exact match — "someone checked and it was right" is itself worth recording), `reverseCash` (exempt from the negative check in one direction: reversing a top-up may go negative if money was since spent).
- Routes: `lib/server/routes/cash_routes.dart` — `GET /cash` (ledger page + authoritative balance in one response), `POST /cash/topup`, `POST /cash/expense`, `POST /cash/count`, `POST /cash/<id>/reverse`, `GET /cash/<id>/photo`.
- Repository: `lib/data/repositories/cash_repository.dart` — `CashRepository`/`cashProvider`, `topUp`/`spend`/`count`/`reverse`/`loadMore`.
- Table: `CashEntries` (`lib/server/db/tables.dart:1332`) — `id, kind (topUp|expense|count|reversal), delta (plain rupiah, not micro-scaled), category, note, reversesId, reversedById, countedAmount, photo (blob, expense only), actorUserId/actorName, at`.
- Report section: `cashReportSection` (`lib/server/cash.dart:347`) — opening/inflow/outflow/variance/closing/byCategory, opening balance respects `businessDayStartHour` rollover.
- WS event: `WsEventTypes.cashEntryCreated` — payload `{entry, balance}`, unfiltered fan-out, because the balance is derived and a client holding one page can't recompute it.

**Offline behaviour** No offline queue for cash acts — they require the server directly (embedded LAN server, but not covered by the offline-settlement journal since it's not part of a bill's chain).

**ADRs** ADR-0088 (cannot go negative; reversal and count are the two exemptions), ADR-0089 (not revenue — fully isolated, one dedicated report section), ADR-0100 (guard only real inside a transaction — `spendCash`/`countCash`/`reverseCash` all wrap themselves), ADR-0079 (ledger pages by growing limit), ADR-0025 (non-cash payment proof — the *pattern* Kas expense photos loosely follow, but note the Kas photo is optional, unlike a bill payment's mandatory one).

**Gotchas**
- `CashEntryKind` (`topUp, expense, count, reversal`) and `CashCategory` (`ingredients, operations, transport, dailyWage, other`) names are **persisted** in `cash_entries.kind`/`.category` — never rename; both need ARB entries in both locales if a new one is added.
- The box's balance is completely separate from the cash drawer / payment mix — `openDrawer`/`closeShift` capabilities belong to the (not-yet-built) drawer reconciliation and must never be repurposed for the box.
- A negative balance here is always "somebody didn't write something down" — never treated as a signal the way `stockOnHand`'s negative is (ADR-0088 explicitly diverges from the stock precedent).

## Piutang — tab / debt (ID · EN: Piutang · Receivable)

**What** What a member owes the venue for food already eaten on credit. Mechanically it's a **sixth payment method**, `piutang` — a payment carrying it discharges the receipt's claim (`paid`) and, in the same transaction, writes a `charge` row to the member's Piutang ledger instead of moving cash (ADR-0098: "a Payment attests the claim was *discharged*", not necessarily that money changed hands). Append-only, `SUM(delta)`, never stored, never negative, and **a charge cannot exceed the member's credit limit** (per-member, falling back to a venue default, both shipping at `0` — nobody has a tab until an owner deliberately grants one).

**Who** Charging a tab (paying the bill *by* piutang) and collecting a payment against it: `settleBill` (till acts). Writing off a bad debt and hand-correcting the ledger: `refund` (the capability that already means "a manager accepts the money is gone"). Setting a member's own credit limit: `manageMembers`.

**Where** Charging happens in the ordinary settlement payment flow (pick "Piutang" as the tender). Collecting against an existing tab happens from the till's **Terima piutang** flow (`lib/ui/features/cashier/debt_collect_sheet.dart`) or from a member's detail sheet on `/members` (Koreksi piutang / Hapus buku).

**How to use (collect at the till)**
1. Open **Terima piutang** (`cshDebtCollect`) → `_DebtorPicker` — search by name/phone (`memSearchHint`); the empty state reads "tidak ada yang berutang" style copy (`cshDebtNobody`).
2. Pick a debtor — shows "Piutang {amount}" (`cshDebtOwes`).
3. Enter an amount (capped at the balance — over it shows `cshDebtOver`), pick a method (any of `tunai, kartu, qris, transfer, lainnya` — never `piutang` itself, which would be circular), attach a proof photo if the method needs one (`stlBlkAttachProof`), optional note.
4. Confirm — **Terima {amount}** (`cshDebtTake`).

**How to use (charge a tab)** At bill payment time, pick **Piutang** as the tender for part or all of a receipt — same split-tender flow as any other method, no separate screen.

**Under the hood**
- Server: `lib/server/debts.dart` — the single writer for `member_debts`. `chargeDebt` (credit-limit check inside `db.transaction`, ADR-0100), `payDebt` (non-cash requires a photo, same rule as ADR-0025; overpayment check inside the transaction), `writeOffDebt` (exempt from the non-negative check, mandatory note), `adjustDebt` (hand correction, exists specifically because a snapshotted visit has no receipt left to reopen so `writeOff` alone would blend real losses with typos), `reverseChargeForPayment` (idempotent by **subtraction** — `charge − Σreversals` — not by presence, so a part-refund followed by a reopen nets to exactly zero, per ADR-0121), `listDebtors`/`_walk` (FIFO ageing derived at read time, no due-date column).
- Routes: piutang directory/ledger routes in `lib/server/routes/members_routes.dart` — `GET /members/debt-total` (the one route with no enable-guard, so the fleet console can refuse to remove the members module while debt is outstanding), `GET /members/debtors`, `GET /members/<id>/debt`, `GET /members/debt/<entryId>/photo`, `POST /members/<id>/debt/payments`, `POST /members/<id>/debt/write-off`, `POST /members/<id>/debt/adjust`. Charging and refunding a piutang leg ride the ordinary settlement routes: `POST /settlement/receipts/<receiptId>/payments` (method `piutang`) and `POST /settlement/receipts/<receiptId>/refund` (targets a `paymentId`, not a method — a piutang leg refunds by ledger reversal, no rupiah moves, ADR-0121).
- Repository: `lib/data/repositories/members_repository.dart` — `debt`, `debtors`, `payDebt`, `writeOffDebt`, `adjustDebt`.
- Table: `MemberDebts` (`lib/server/db/tables.dart:1491`) — `id, memberId, kind (charge|payment|reversal|writeOff|adjust), delta, paymentId, visitId, billLabel, method, note, photo, actorUserId/actorName, at`.
- Domain: `MemberDebtKind` (`lib/domain/models/member.dart:45`), `MemberDebt`/`MemberDebtEntry` (headroom getter clamps to `[0, limit]`), `Debtor`.
- Report section: `debtReportSection` (`lib/server/debts.dart:689`) — opening/charged/collected-by-method/writtenOff/adjusted/closing, plus overdue total and a capped debtors table; venue-wide outstanding does not reset at midnight (unlike a window sum).
- Gate: `DebtConfig.enabled = venueSettings.membersEnabled && venueSettings.memberDebtEnabled` — nested under the membership master switch, so a venue that never opted into members can't have tabs against guests it doesn't keep. `debtGuard()` checks membership *and* debt, both 404 (`members_disabled` / `debt_disabled`).

**Offline behaviour** Piutang acts are settlement acts — no offline queue; require the server, same as every membership settlement act.

**ADRs** ADR-0098 (the whole feature — piutang widens the Payment definition rather than becoming a second bill-close mode; 5 ledger kinds not 3; a member with an outstanding balance can't be deleted), ADR-0120 (a tab follows the struk — the debtor is `receipt.memberId ?? visit.memberId`, same fallback as points/units, so a split-bill tab charges the right guest), ADR-0121 (a refund names its leg — a piutang leg is now reversible under split tender, reversal became partial), ADR-0025 (non-cash proof photo — piutang collections follow the same rule for any method but `tunai`), ADR-0100 (guard only real inside a transaction — `debts.dart` was retrofitted in the ADR-0100 amendment, being the newest of the ledger family and the one place the rule "did not travel").

**Gotchas**
- `debtPaymentMethods = {tunai, kartu, qris, transfer, lainnya}` — `piutang` is deliberately excluded from both collection methods and refund methods (paying/refunding a tab with the tab is circular).
- Refunding a bill no longer picks a method at all (ADR-0121) — it targets a specific `paymentId`/leg, and a piutang leg refunds via `MemberDebtKind.reversal` with **no rupiah movement**, while a money leg refunds as a negative `payments` row in its own method.
- `Member.debtLimit` is resolved via `creditLimitFor(ownLimit, cfg)` — `null` on the member means "inherit the venue default", **never** "unlimited"; there is no way to express an unbounded tab.
- Ageing (`listDebtors`/`_walk`) applies every negative movement to the **oldest open charge first** — charges and reductions are processed in two passes (all charges, then all reductions) because two rows can legitimately share a timestamp and reading raw row order could let a payment appear to predate the charge it pays.

## Domain vocabulary (CONTEXT.md)

| ID | EN |
|---|---|
| Pelanggan | Member |
| Keanggotaan | Membership |
| Alamat pelanggan | Member address |
| Pemilik tagihan | Bill owner |
| Pemilik struk | Receipt owner |
| Poin / Poin didapat / Sisa poin / Poin beredar | Points / Points earned / Points balance / Points outstanding |
| Tukar poin | Redeem |
| Kartu stempel / Hadiah | Punch card / Reward |
| Piutang / Batas kredit / Sisa kredit / Piutang tak tertagih | Receivable / Credit limit / Remaining credit / Bad debt |
| Kas kecil | Petty cash |
| Laporan pelanggan / Pelanggan aktif / Kembali lagi / Belanja pelanggan / Belanja tanpa rincian | Member report / Active members / Returning members / Member spend / Untracked spend |

**Avoid** (per CONTEXT.md): "Langganan" for a member (it means the venue's own SatSet subscription); "Customer" in English UI copy (no non-member customers exist to contrast against); "Kasbon" or "Bon" for Piutang (workplace salary advance / the paper bill, respectively); treating a piutang payment as money received; keeping a visit open as a tab (there is no such state — `snapshotVisitAndDelete` hard-deletes the visit at close); folding a Kas collection into Piutang or vice-versa; a stored "lapsed"/"churned" status (both are derived at read time).
