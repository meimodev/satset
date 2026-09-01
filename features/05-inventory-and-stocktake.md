# 05 · Inventory & stocktake

SatSet tracks inventory at ingredient grain: a **bahan** (ingredient) is the only stock entity — even a bottled drink is a bahan whose recipe is itself. A **resep** (recipe) says how much of each bahan one sellable configuration of a menu item consumes; selling a dish deducts stock automatically when the line is *sent*, never at cook or bill close. Availability (`Tidak tersedia`) is derived from the ledger at read time, never stored. A **stok opname** (stocktake) is a first-class counting session — opened, walked, closed — that writes correction movements only at close. This document covers ingredients/recipes, receive/waste/produce movements, the derived balance and low-stock/par (Belanja) surfacing, item availability (auto vs. manual, guest override), and the opname archive.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Ingredient (bahan) list, add/edit/archive | `/stock` | `manageIngredients` (list also readable with `editMenu`) | `GET/POST /stock/ingredients`, `DELETE /stock/ingredients/<id>` |
| Movement ledger (per bahan) | `/stock` (bahan detail) | `manageIngredients` | `GET /stock/ingredients/<id>/movements` |
| Receive stock (Terima barang) | `/stock` | `manageIngredients` | `POST /stock/receive` |
| Waste / Buang (bahan or menu item) | `/stock` (row menu), menu item editor | `manageIngredients` | `POST /stock/waste` |
| Produce a batch (Produksi) | `/stock` (row menu) | `manageIngredients` | `POST /stock/produce` |
| Recipes (resep) editor | menu item editor / stock screen | `editMenu` (item-owned) or `manageIngredients` (ingredient-owned) | `GET/PUT /stock/recipes/<ownerId>` |
| Stok opname — open / walk / close / discard | `/stock` (opname mode) | `manageIngredients` | `POST/DELETE /stock/counts`, `PUT/DELETE /stock/counts/<id>/lines`, `POST /stock/counts/<id>/close` |
| Opname archive (read-only document viewer) | `/opname` (tablet only) | `viewReports` **or** `manageIngredients` | `GET /stock/counts`, `GET /stock/counts/<id>` |
| Stock report (usage/waste/variance/valuation) | Reports screen (`ReportStockSection`) | `viewReports` **or** `manageIngredients` | `GET /stock/report` |
| Item availability (auto habis / manual unavailable) | Menu admin item editor | `editMenu` | derived read-side; `unavailable` written via menu item PATCH |
| Guest stock override (Menu tamu tab) | `/selforder-admin` | `editSettings` | `PATCH /selforder/items/<id>` |
| Deduct-at-send (submit order) | — (n/a, server-internal) | — | `POST /orders`, `acceptGuestOrder` → `consumeForTicket` |

## Ingredients (Bahan) & recipes (Resep) (ID · EN)

**What** A bahan is a raw stock item the venue holds and counts — beras, ayam, keju, or a countable SKU like a bottle of Coca-Cola. It carries a unit **preset** grouped by dimension (mass `mg`/`g`/`kg`, volume `ml`/`L`, count `pcs`/`butir`/`siung`/`lembar`); units convert within a dimension, never across (`lib/domain/models/ingredient.dart`, `lib/domain/models/stock_unit.dart`). Quantities are stored as integers at 1/1000 of the dimension's canonical base (mg / µl / milli-pcs) — `0.2 kg` is `200000` — the same exact-integer discipline the codebase uses for money (docs/adr/0040). A resep is the bill of materials for one sellable configuration of a menu item: a **base** list, a per-**variant** list that *replaces* the base, and per-**modifier-option** lists that *add* on top (`ResolvedRecipes.resolve`, `lib/server/stock.dart:28-54`). Recipes are private to their item, like modifier groups — there is no shared recipe library. A bahan itself may carry a recipe with an explicit `batchYield`, consumed by a `produce` movement — **one level only**, a produced bahan's recipe may reference only non-produced bahan (ADR-0040 §5).

**Who** Admin / inventory manager (`manageIngredients`); menu editors (`editMenu`) can read the ingredient list to author recipes on the item side.

**Where** `/stock` (`lib/ui/features/admin/stock_screen.dart`), reached from the Venue hub.

**How to use**
1. Open the Venue hub → **Stok**. The header reads "Bahan, penerimaan & mutasi" (`stkSub`).
2. Tap the `+` icon (`stkAddIngredient`, "Tambah bahan") to add a bahan: name, unit preset, optional reorder threshold, optional par level, optional opening stock.
3. Tap a bahan row's overflow menu for **Terima barang** (Receive), **Produksi batch** (Produce, only if `batchYield` is set), **Riwayat mutasi** (Ledger), **Ubah bahan** (Edit), **Arsipkan** (Archive) — keys `stkMenuReceive`/`stkMenuProduce`/`stkMenuLedger`/`stkMenuEdit`/`stkMenuArchive` (`lib/ui/features/admin/stock_screen.dart:3001-3005`).
4. Recipes are authored from the **menu item editor** for an item-owned resep (`kind=item`), or from the stock screen for an ingredient-owned resep on a produced bahan (`kind=ingredient`).

**Under the hood**
- Domain: `lib/domain/models/ingredient.dart` (`Ingredient`, `StockReason` enum), `lib/domain/models/stock_unit.dart`.
- Repository: `StockApi` (`lib/data/repositories/stock_repository.dart:15-210`) — `ingredients()`, `save()`, `archive()`, `movements()`, `recipes()`, `saveRecipes()`. Deliberately **fetch-on-demand**, not live-synced — only derived habis flags ride the broadcast `/menu` snapshot.
- Server: `lib/server/stock.dart` — `loadRecipes` (l.58), `ResolvedRecipes.resolve` (l.43), `writeMovement` (l.293), `deriveStockFlags` (l.210).
- Routes: `lib/server/routes/stock_routes.dart` — `GET/POST /stock/ingredients`, `DELETE /stock/ingredients/<id>` (archives, does not delete — movement history and recipe lines must keep resolving a name), `GET /stock/ingredients/<id>/movements`, `GET/PUT /stock/recipes/<ownerId>?kind=item|ingredient`.
- Tables: `Ingredients` (id, name, unit, `stockOnHand`, `lowStockAt`, `parLevel`, `costMicro`, `batchYield`, `archivedAt`) and `RecipeLines` (ownerKind, ownerId, variantId, optionId, ingredientId, qty) — `lib/server/db/tables.dart:1151-1216`.
- Adding a bahan with an opening stock books it as a `receive` movement inside the same transaction (`stock_routes.dart` POST `/stock/ingredients`), never as a bare balance — `Σ movements == stockOnHand` holds from row one.

**Offline behaviour** Bahan data is not mirrored client-side and has no offline path — `/stock` requires a live connection to the paired host; `_paired` short-circuits every `StockApi` call to empty/no-op when `apiConfigProvider == null`.

**ADRs** docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md, docs/adr/0042-generic-seed-covers-inventory-and-recipes.md (seed dataset shape).

**Gotchas**
- `StockReason` enum values (`sale`, `voidReturn`, `waste`, `receive`, `adjust`, `produce`) are persisted in `stock_movements.reason` — never rename one.
- `Ingredients.stockOnHand` **may go negative** — an `overrideStock` send on a shortfall is a deliberate "your counts are wrong" signal and must never be clamped.
- An item with **no recipe at all** consumes nothing and is never auto-habis — this is the correct default for a menu migrated one dish at a time, not an error state.

## Receiving stock (Terima barang) (ID · EN)

**What** Records a delivery: increases `stockOnHand` and, optionally, re-prices the moving-average `costMicro`.

**Who** `manageIngredients`.

**Where** `/stock` → bahan row → **Terima barang** (`stkMenuReceive`, `stkReceiveTitle` = "Terima {name}").

**How to use**
1. From a bahan's overflow menu, choose **Terima barang**.
2. Enter the quantity received (in the bahan's display unit).
3. Optionally enter **Harga per {unit}** (`stkPricePer`, "Harga per {unit} (opsional)") — leave blank to receive without re-pricing the moving average (`stkPriceHelper`).
4. Optionally enter **Pemasok** (Supplier, `stkSupplier`) and a note.
5. Confirm — toast **"Stok berhasil ditambahkan"** (`stkReceiveOk`).

**Under the hood**
- Repository: `StockApi.receive()` (`lib/data/repositories/stock_repository.dart:58-73`) → `POST /stock/receive` with `{ingredientId, qty, unitPrice?, supplier?, note?}`.
- Server: `stock_routes.dart` `/stock/receive` handler converts `unitPrice` (money per display unit) to `unitCostMicro` via `costMicroFromUnitPrice`, then calls `receiveStock` (`lib/server/stock.dart:344`) inside `db.transaction`, which calls `writeMovement` with `reason: StockReason.receive` and re-broadcasts the menu if a derived habis flag flipped (`broadcastIfFlipped`).
- Table write: one `StockMovements` row (`reason='receive'`, positive `delta`) plus the `Ingredients.stockOnHand`/`costMicro` update, same transaction.

**Offline behaviour** No offline path — this route requires a live host connection like every other `/stock` write.

**ADRs** docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md.

**Gotchas** `unitPrice` is money per *display* unit (rupiah per kg), not per milli-base unit — the conversion happens server-side via `costMicroFromUnitPrice`.

## Waste / Buang (ID · EN)

**What** Records stock thrown away — spoiled milk, unsold pastries, a dropped jug. Two entry points, one writer: bin a bahan directly, or bin one portion of a menu item (explodes its resep into the same `waste` movements). Returns the money value destroyed so the caller can show it back.

**Who** `manageIngredients`.

**Where** `/stock` → bahan row → **Buang** (`stkMenuWaste`), or the menu item editor's waste action, dialog titled **"Buang {name}"** (`stkWasteTitle`).

**How to use**
1. Choose **Buang** on a bahan row, or waste a menu item from its editor.
2. Enter the quantity.
3. Enter **Alasan** (Reason, `stkWasteNote`) — **required**: "Wajib diisi — tanpa alasan, angka buang tidak bisa ditindaklanjuti" (`stkWasteNoteHelper`). Empty reason surfaces `stkWasteNoteRequired`; empty qty surfaces `stkWasteQtyRequired`.
4. Confirm — toast **"Tercatat dibuang, nilai {value}"** (`stkWasteOk`).

**Under the hood**
- Repository: `StockApi.waste()` (`lib/data/repositories/stock_repository.dart:77-93`) → `POST /stock/waste` with `{ingredientId? | itemId? + variantId?, qty, note}`.
- Server: `stock_routes.dart` `/stock/waste` — if `ingredientId` given, wastes that bahan directly; if `itemId` given, resolves the item's recipe via `loadRecipes(...).resolve(variantId: ...)` and multiplies by `qty`; **an item with no recipe is refused** with `400 no_recipe` (points at [[Jual satuan]] as the fix). Calls `wasteStock` (`lib/server/stock.dart:616-657`) inside `db.transaction`, which writes one `StockMovements` row per ingredient (`reason: waste`, negative delta) and **one audit row per act** (`AuditKind.stockWasted`), never per bahan.
- Reason is audited — this is the one stock write with no counterpart anywhere else in the books, per CONTEXT.md.

**Offline behaviour** No offline path.

**ADRs** docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md.

**Gotchas** A menu item with **no recipe cannot be wasted** — the act refuses rather than silently binning nothing, per CONTEXT.md §Buang (waste).

## Producing a batch (Produksi) (ID · EN)

**What** Turns a produced bahan's raw inputs into finished output in one transaction — e.g. "1 batch of sambal = 2 kg". Deducts the recipe inputs and credits the `batchYield` output.

**Who** `manageIngredients`.

**Where** `/stock` → bahan row → **Produksi batch** (`stkMenuProduce`, dialog titled `stkProduceTitle` "Produksi {name}"). Only offered on a bahan with a non-null `batchYield` (`isProduced`).

**How to use**
1. Choose **Produksi batch** on a produced bahan's row. Sub-text reads "1 batch = {qty}. Bahan baku penyusun akan berkurang otomatis." (`stkProduceSub`).
2. Enter **Jumlah batch** (`stkBatchCount`).
3. Confirm — toast **"Produksi berhasil dicatat"** (`stkProduceOk`).

**Under the hood**
- Repository: `StockApi.produce()` (`lib/data/repositories/stock_repository.dart:175-182`) → `POST /stock/produce` with `{ingredientId, batches, note?}`.
- Server: `stock_routes.dart` `/stock/produce` calls `produceBatch` (`lib/server/stock.dart`) inside `db.transaction`; if the target ingredient has no `batchYield`, returns `400 not_produced`. Input movements and the output movement share a `batchId` (`StockMovements.batchId`), grouping the batch.

**Offline behaviour** No offline path.

**ADRs** docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md §5 (one-level-only rule — a produced bahan's recipe may reference only non-produced bahan).

**Gotchas** Habis does **not** cascade through a production chain: sambal at zero makes a dish habis even when the chilli behind it is plentiful, because unmade sambal cannot be served.

## Deduct at send (Pengurangan stok saat kirim) (ID · EN)

**What** Stock deducts **when a ticket line is sent to the kitchen**, not when cooked, served, or at bill close. Deduction rides the existing idempotency-keyed submit transaction, so a retried submit cannot double-deduct.

**Who** N/A — automatic, server-internal, triggered by any waiter/guest submitting an order.

**Where** No dedicated screen; a rejected line surfaces as a snackbar ("out of stock") back on the order screen.

**How to use** N/A (system behaviour). A waiter who submits a line the pantry can't cover for sees only that line rejected — the rest of the batch still sends — with the missing bahan named (e.g. `tktOutOfStockNamed`).

**Under the hood**
- Flow: `submitOrder` (`lib/server/routes/tickets_routes.dart:187`) → `needForLine` computes what one line's exact configuration (variant + options) consumes via `ResolvedRecipes.resolve` → `consumeForTicket` (`lib/server/stock.dart:515-541`) → `writeMovement` per ingredient (`reason: StockReason.sale`, negative delta, `ticketId` set).
- **Partial rejection with an override valve**: only the offending lines are rejected at send; the rest of the batch still goes through. A holder of `overrideStock` may force-send anyway — the movement is still written and the balance goes negative deliberately, surfacing as "your counts are wrong, go do an opname."
- Voiding a line restocks **only if it was still `sent`** (`reverseTicketStock`, `lib/server/stock.dart:549`) — a `voidReturn` movement. Voided from `prep`/`cooked`/`ready` it is booked as `waste` instead (net zero on the balance, but the loss becomes visible and countable). The test is the line's **lifecycle status**, never its void reason code.
- Habis flags (`ItemStockFlags`, `lib/server/stock.dart:174-255`) are recomputed via `deriveStockFlags` and re-broadcast on the `/menu` snapshot **only when a flag flips** (`refreshAndDetectFlip` / `broadcastIfFlipped`) — stock ticking from 8.0 kg to 7.8 kg is silent; crossing zero is not.

**Offline behaviour** This is a server-side write inside the ordinary order-submit path. A client-mode device queues the *order itself* offline via the send queue (ADR-0090) if disconnected; the deduction happens when that order lands on the host, same as any online submit — there is no separate offline stock path.

**ADRs** docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md.

**Gotchas** By `cooked` the ingredients are physically gone, so an "insufficient stock" answer past that point has nothing left to prevent — this is why send, not cook/serve/close, is the deduction point.

## Derived balance & the movement ledger (Mutasi stok) (ID · EN)

**What** `Ingredients.stockOnHand` is a **denormalised balance**, always written in the same transaction as its `StockMovements` row — never a bare mutable number with no history. Every movement is self-contained: bahan, signed `delta` (milli-base units), `reason`, acting user, timestamp, a nullable `ticketId`, and a frozen `sourceLabel` (item + variant as ordered) — reads never join back to tickets, since live ticket rows are deleted at bill close.

**Who** `manageIngredients` reads the per-bahan ledger; `viewReports`/`manageIngredients` read the aggregated stock report.

**Where** `/stock` → bahan row → **Riwayat mutasi** (`stkMenuLedger`); aggregated view on the Reports screen (`ReportStockSection`, `lib/ui/features/admin/report_stock_section.dart`).

**How to use**
1. Per-bahan history: open a bahan's overflow menu → **Riwayat mutasi**. Shows the newest movements first, each carrying its `sourceLabel` and reason.
2. Aggregated report: open Reports, scroll to the stock section — KPI tiles for **Nilai stok** (stock value), **Terbuang** (waste value), **Selisih** (variance value), plus tables for waste / variance / usage / current valuation.

**Under the hood**
- Repository: `StockApi.movements(id, {limit})` → `GET /stock/ingredients/<id>/movements?limit=N`.
- Report: `StockApi.report({from, to})` → `GET /stock/report`; server function `stockReport` (`lib/server/routes/stock_routes.dart`) ranks usage (net `sale`+`voidReturn`), waste, and variance (`adjust`), and lists current valuation per bahan flagging `low` (`stockOnHand <= lowStockAt`) and `negative` (`stockOnHand < 0`).
- Provider: `stockMovementsProvider` (family by ingredient id), `stockReportProvider` (family by ISO range) — both `FutureProvider.autoDispose`.
- Table: `StockMovements` (`lib/server/db/tables.dart:1223-1257`) — `id, ingredientId, delta, reason, ticketId?, sourceLabel, userId?, note?, costMicro, batchId?, countId?, at`.

**Offline behaviour** No offline path — read-only screens against the live host.

**ADRs** docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md.

**Gotchas**
- **No pruning** — the ledger keeps every row forever; ~300 lines/day is under half a million rows a year, and stock history is the thing an owner looks backwards at.
- The stock report's **variance** figures are anchored to opname events (every `adjust` movement *is* one variance observation), not to the caller's date range — a variance figure over a window that starts and ends mid-count is meaningless.
- `costMicro` on each movement is frozen at the moment it was written, so waste/usage values are historical, never re-priced.

## Low stock, par level & Belanja (shopping list) (ID · EN)

**What** Two independent numbers per bahan: `lowStockAt` (reorder **threshold** — "warn me") and `parLevel` (**par** — "how much to buy to be fully stocked"). Neither is written by receiving or opname; both are entered on the ingredient editor. `Ingredient.isLow` = `lowStockAt != null && stockOnHand <= lowStockAt`. `Ingredient.shortfall` = `max(0, parLevel - stockOnHand)` when `parLevel` is set. **Belanja** (shopping list) is fully derived — every bahan with a positive shortfall, with the shortfall as the buy quantity — there is no list entity, nothing is ticked off; buying is recorded the ordinary way, by receiving stock.

**Who** `manageIngredients` (viewer); low-stock count is also surfaced to anyone who can see the Venue hub.

**Where** `/stock` (KPI tile + Belanja card); Venue hub tile badge.

**How to use**
1. On `/stock`, the **MENIPIS** (Low) KPI tile shows the count of low-stock bahan and toggles a filter chip when tapped (`stkKpiLow`, `stkFilterLow`).
2. A **STOK MINUS** (Negative) tile appears only when at least one bahan is negative, with sub-text "Perlu opname segera" (Needs an opname urgently, `stkNeedOpname`) — because a negative balance signals bad counts, not real shortage.
3. Below the KPI row, a **Belanja** card lists every bahan under its par with the quantity to buy and an estimated total cost (`stkBelanja`, `stkBelanjaEstimate`) — hidden entirely when nothing is short.
4. The Venue hub shows a low-stock badge: "{count} bahan ({low} low)" (`venueHubStockLow`), colored `warn` when `lowStock > 0`, `success` otherwise.

**Under the hood**
- Model: `Ingredient.isLow`, `Ingredient.shortfall` (`lib/domain/models/ingredient.dart:60-68`).
- UI: `_summaryGrid` and `_belanjaCard` in `lib/ui/features/admin/stock_screen.dart:237-370`.
- Venue hub: `lib/ui/features/admin/venue_hub_screen.dart:100-109, 334-481` reads `ingredientsProvider` and computes `lowStock` client-side.
- No server endpoint for Belanja specifically — it is computed client-side from the same `ingredients()` fetch used everywhere else on `/stock`.

**Offline behaviour** No offline path — the ingredient list this is derived from is fetch-on-demand against the live host.

**ADRs** docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md (`lowStockAt`/`parLevel` fields), docs/adr/0041 (variance/valuation).

**Gotchas** Par is optional — without it a bahan still warns via `lowStockAt`, it just never reaches the Belanja list (there is no quantity to name).

## Item availability — auto habis vs. manual unavailable (ID · EN)

**What** A menu item can stop being sellable for two unrelated reasons, both surfaced under one word, **`Tidak tersedia`** (not "habis" — ADR-0046), with the cause named parenthetically: `Tidak tersedia (stok 0)` when a recipe ingredient hit zero (auto, **derived**, never stored — `MenuItem.isAutoSoldOut`), or `Tidak tersedia (manual)` when an admin manually flipped `MenuItems.unavailable`. Receiving stock clears an auto flag automatically; nobody has to remember to un-flag it.

**Who** `editMenu` (manual toggle); auto-derivation is system behaviour requiring no capability.

**Where** Menu admin item editor (`lib/ui/features/admin/menu_admin_item_editor.dart`).

**How to use**
1. Open a menu item in the admin menu editor.
2. Toggle **availability manually** if the kitchen isn't serving it today regardless of stock — this sets `unavailable`.
3. Auto-habis needs no action — it is computed live from `deriveStockFlags` against the item's resep and the current ingredient balances, at item, variant, and modifier-option granularity, so "Besar" can be unavailable while "Reguler" still sells.

**Under the hood**
- Server derivation: `deriveStockFlags` (`lib/server/stock.dart:210-255`) builds `ItemStockFlags` (`autoSoldOut`, `soldOutVariantIds`, `soldOutOptionIds`) per item by checking `ResolvedRecipes.resolve(...)` coverage against on-hand balances (`_covers`). Flags carry a compact `signature` used purely to detect a **flip** for the broadcast (stock ticking down inside a bucket does not re-broadcast; only crossing a threshold does).
- Table: `MenuItems.unavailable` (manual, `lib/server/db/tables.dart:267`) — the only stored availability bit; auto is never stored.
- Code identifiers use `soldOut` throughout (`MenuItem.isSoldOut`, `autoSoldOut`, `soldOutVariantIds`, `soldOutOptionIds`) though the user-facing word is `Tidak tersedia`.

**Offline behaviour** No offline path for the manual toggle; auto-derivation happens on every server-side menu snapshot build regardless of connectivity.

**ADRs** docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md, docs/adr/0046-unavailable-replaces-sold-out-in-item-availability.md.

**Gotchas** `MenuItems.stockCount` / `autoSoldOutAtZero` were **dropped in migration v36** — do not reintroduce a per-item stock number alongside bahan.

## Guest stock override (Override stok tamu) (ID · EN)

**What** A manual, **shift-long** call on whether the guest self-order page may sell one item, overriding the live inventory derivation. Three values, persisted verbatim in `menu_items.guest_stock_override`: `auto` (Ikut inventaris — reads the live recipe/stock derivation), `forceIn` (Paksa ada — force available), `forceOut` (Paksa habis — force sold out). A force **expires at the next business-day rollover** — `guestOverrideAt` is checked against `businessDayStart`; a force whose timestamp predates the current business day is served back to the client as `auto`, already expired.

**Who** `editSettings` — set from the **Menu tamu** tab, the one screen that shows and writes `alcohol`/`guestVisible`/`guestStockOverride` together.

**Where** `/selforder-admin` → Menu tamu tab (`lib/ui/features/admin/self_order_admin_screen.dart`).

**How to use**
1. Open **Pesan mandiri** admin → **Menu tamu** tab.
2. On an item, tap **Otomatis** (`soStockAuto`), **Paksa ada** (`soStockIn`), or **Paksa habis** (`soStockOut`) — tapping the already-selected force clears it back to `auto`.
3. The choice holds for the rest of the current business day; there is no explicit "clear" needed — it self-expires at rollover.

**Under the hood**
- Repository/route: `PATCH /selforder/items/<id>` writes `guestStockOverride` + stamps `guestOverrideAt = SatClock.now()`.
- Read path: `guestMenuJson` (`lib/server/self_order.dart:314-413`) computes the **effective** value per item — `override = (guestOverrideAt != null && !guestOverrideAt.isBefore(today)) ? guestStockOverride : 'auto'` — then resolves `soldOut` as `forceIn → false`, `forceOut → true`, else the auto derivation (`unavailable` flag OR outside the category's guest serving window OR `deriveStockFlags` auto-sold-out). The wire payload's `stockOverride` field carries this **effective**, already-expired-if-applicable value, never the raw stored one — so the Menu tamu tab's three-way control never renders a stale force as still held down.
- Table: `MenuItems.guestStockOverride` (text, default `'auto'`), `MenuItems.guestOverrideAt` (nullable datetime) — `lib/server/db/tables.dart:291-297`.

**Offline behaviour** No offline path — this is an admin-configuration write against the live host.

**ADRs** referenced under ADR-0105/0106 ([[Pesan mandiri]]) in CLAUDE.md; behaviour itself is not covered by a numbered stock ADR but documented in CONTEXT.md §Override stok tamu.

**Gotchas**
- `guestMenuJson` emits the **effective**, not the stored, value — nothing client-side recomputes the expiry, and no button can render held-down after the server has let go. Waiting for midnight (business-day rollover) is the only way back to `auto` short of tapping it again.
- A same-day `forceIn` beats **both** the stock ledger and the category's serving-window clock — a human saying "we have it" outranks both.

## Stok opname — open, walk, close (ID · EN)

**What** A counting session, not a burst of adjustments: `StockCounts` (header: actor, `startedAt`, `closedAt`, `closedBy`, `scope`, `blind`, note) plus `StockCountLines` (one line per counted bahan, `expectedQty` + `costMicro` **frozen at the moment the line is entered**, `countedQty` absolute). **Every counted bahan gets a line, including one found correct** — a zero-variance line is a fact somebody established, not an absence; only a non-zero-variance line also writes a movement. **Nothing moves until `closeCount`** — a forty-minute walk of the pantry survives the tablet sleeping, because the session is a server-backed row, not an in-memory screen mode.

**Who** `manageIngredients` opens/walks/closes/discards a session.

**Where** `/stock`, opname mode (tap **Opname**, `stkOpname`).

**How to use**
1. On `/stock`, tap **Opname** (top-right). A start sheet appears: **Mulai stok opname** (`stkOpnameStartTitle`), sub-copy "Sesi ini akan tersimpan, jadi hitungan Anda tidak hilang kalau layar mati." (`stkOpnameStartSub`).
2. Choose **Cakupan** (Scope, `stkOpnameScope`): **Menyeluruh** (Full, `stkOpnameScopeFull`) asserts every active bahan was seen; **Sebagian** (Partial, `stkOpnameScopePartial`) claims nothing.
3. Toggle **Hitung buta** (Blind count, `stkOpnameBlind`, default on) — "Sembunyikan stok tercatat selama menghitung. Selisih muncul setelah opname ditutup." (`stkOpnameBlindHint`). Blind is a stronger form of evidence than a sighted spot-check.
4. Tap **Mulai** (`stkOpnameStart`) — opens the session (`409 countAlreadyOpen` if one is already running; two overlapping walks would each freeze expectations the other is moving).
5. Walk the pantry: for each bahan, type the physical count found (`stkOpnameHint`, "Ketik jumlah fisik di gudang saat ini. Selisih akan otomatis dihitung sebagai penyesuaian mutasi."). Each entry calls `PUT /stock/counts/<id>/lines` and freezes `expectedQty`/`costMicro` at that instant — a sale mid-walk lands in the ledger, never in this line's variance.
6. The header shows **"{n} diisi"** (`stkFilled`) as lines accumulate; tap **Simpan ({n})** (`stkSaveCount`) to close.
7. Closing on a **Menyeluruh** scope with bahan still uncounted prompts **"Belum semua bahan dihitung"** (`stkOpnameIncompleteTitle`) — "Tutup tetap sebagai menyeluruh?" (`stkOpnameCloseAnyway`) lets the user close anyway.
8. On close, a summary toasts either **"Opname selesai — tidak ada selisih"** (`stkOpnameDoneNoVariance`) or **"Opname selesai — {n} bahan disesuaikan"** (`stkOpnameDone`).
9. To abandon mid-walk: tap **Batal** (Cancel) → confirm **"Buang opname ini?"** (`stkOpnameDiscardTitle`) — "{n} bahan yang sudah dihitung akan ikut terbuang. Opname yang belum ditutup tidak mengubah stok." (`stkOpnameDiscardBody`). Discarding leaves **no document** — an unfinished count is not evidence of anything.

**Under the hood**
- Domain: `StockCount`, `StockCountLine`, `StockCountScopeKind` (`lib/domain/models/stock_count.dart`); server-side mirror `StockCountScope` enum (`lib/server/stock_counts.dart:292`, values `full`/`partial`).
- UI state: `_StockScreenState` in `stock_screen.dart` — `_session` (the open `StockCount`), `_counts`/`_expected` maps keyed by ingredient id, `_adoptSession` (l.94, resumes a walk left open by re-reading `/stock/counts` on `initState`), `_startOpname`/`_commitLine`/`_closeOpname`/`_clearCountCtrls`.
- Repository: `StockApi.counts()`, `.count(id)`, `.openCount()`, `.countLine()`, `.removeCountLine()`, `.discardCount()`, `.closeCount()` (`lib/data/repositories/stock_repository.dart:102-173`).
- Routes (`lib/server/routes/stock_routes.dart`): `GET /stock/counts` (archive + open session), `GET /stock/counts/<id>` (one session as a document — header + every line), `POST /stock/counts` (open, 409 if one is already open), `PUT /stock/counts/<id>/lines` (enter one counted bahan, absolute quantity), `DELETE /stock/counts/<id>/lines/<ingredientId>`, `DELETE /stock/counts/<id>` (discard — leaves no document), `POST /stock/counts/<id>/close`. A legacy one-shot `POST /stock/count` (open+line+close in one call) is kept for pre-v52 clients, routed through the same writers.
- **`closeCount`** (`lib/server/stock_counts.dart:170-247`) is the single writer: re-reads the session inside `db.transaction` (already-closed guard must read inside the transaction it protects, same rule as every ledger writer); for each line, `delta = countedQty - expectedQty`; **skips writing a movement when `delta == 0`** (the line itself is still kept in `StockCountLines`) but always accumulates `varianceValue = valueOf(delta, line.costMicro)`; non-zero lines write one `StockMovements` row each (`reason: StockReason.adjust`, `countId` set); stamps `closedAt`/`closedBy`; writes **exactly one** audit row (`AuditKind.stockCountClosed`) carrying line count + total variance — the session, not its lines.
- Tables: `StockCounts` (`lib/server/db/tables.dart:1265-1289`), `StockCountLines` (`:1302-1320`).

**Offline behaviour** No offline path — opening/walking/closing a session all require a live host connection. The resilience this feature provides is against the **tablet sleeping**, not against the network dropping: the session lives server-side from the moment it opens, so a killed app or a dimmed screen loses nothing, but the walk itself cannot start or continue while disconnected from the paired host.

**ADRs** docs/adr/0096-an-opname-is-a-document-not-a-burst-of-adjustments.md, docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md §7 (variance anchoring).

**Gotchas**
- **A zero-variance line is kept** — dropping it (as the pre-ADR-0096 `recordCount` did) makes any document assembled from `adjust` rows silently a document of failures only.
- **Nothing moves until `closeCount`** — an open session with lines entered has written zero `StockMovements` rows; the balance is untouched until close.
- `recordCount` **no longer exists** on `stock.dart` — the one path is `recordCountLine` → `closeCount`, both in `lib/server/stock_counts.dart`.
- A closed session is **never reopened** — the ledger already holds its movements, and closing twice would double them (`closeCount` returns `null`/`409 countClosed` on an already-closed id).
- Historic sessions are valued at the **cost frozen on each line**, not today's moving average — a session read a year from now reports the same rupiah it reported at close.

## Opname archive (ID · EN)

**What** A read-only, tablet-only archive of every closed opname session plus whatever is currently open — the document an inventory manager files, argues with, and is held to.

**Who** `viewReports` **or** `manageIngredients` — two authorities, like `/kas`: the person who counts is rarely the person who reads the variance back.

**Where** `/opname` (tablet only — phone shows an explanatory notice), reached from the Venue hub.

**How to use**
1. Open the Venue hub → **Opname**.
2. Pick a range chip — **30**, **90**, or **365** hari (days) (`opnRangeDays`); default is 90.
3. The left pane lists sessions (open session pinned at top via `_OpenBanner`, showing "{n} bahan sudah dihitung. Belum ada stok yang bergerak sampai ditutup." — `opnOpenBody`); tap one to view its document on the right.
4. The document shows scope + blind/sighted tag (`opnTagBlind`/`opnTagSighted`), KPI row (**Baris** lines, **Cocok** exact-match count, **Selisih** variance), and a table with columns **Bahan / Tercatat (Expected) / Dihitung (Counted) / Selisih (Variance) / Nilai (Value)**.
5. **Ekspor** (`opnExport`) produces a CSV or PDF filing copy client-side from the already-loaded document — no server round trip, no paging (unlike the venue-wide audit log).

**Under the hood**
- Screen: `lib/ui/features/admin/opname_screen.dart` — `OpnameScreen`/`_OpnameScreenState` (l.56-171), `opnameRange(days, {now})` (l.48, pure helper pinned by `test/opname_range_test.dart`).
- Provider: `stockCountsProvider` (family by `(String, String)` ISO range) → `StockApi.counts(from, to)`.
- Export: `lib/core/export/opname_exporter.dart` — `buildOpnameCsv`, `buildOpnamePdf`, `opnameFilename`.
- Route capability: `app_router.dart` — `if (loc.startsWith('/opname')) return const [Capability.viewReports, Capability.manageIngredients];` (`lib/router/app_router.dart:121-125`).

**Offline behaviour** No offline path — read-only fetch against the live host, same as the rest of `/stock`.

**ADRs** docs/adr/0096-an-opname-is-a-document-not-a-burst-of-adjustments.md.

**Gotchas**
- **Tablet only** — the phone route renders `_OpnamePhoneNotice` instead of the two-pane layout; a document is read by comparing its rows side-by-side, which does not fit a phone width.
- `stock_movements.count_id` is **nullable by design**: an `adjust` row written before schema v52 predates the session concept and is deliberately **not backfilled** — any reader must treat null as "pre-session", never as an error.

## Seed data (Contoh data) (ID · EN)

**What** The prompted sample-venue seed (`seedSampleVenue`) includes a full inventory: bahan with opening stock and resep for most of the ~42-item generic menu.

**Who** N/A — system seed, triggered by an admin answering the first-run prompt or re-running it from Admin → Settings → Operasional.

**Where** Venue Hub first-run dialog; `POST /seed/generic`.

**Under the hood**
- `lib/server/db/seed_inventory_data.dart` supplies the bahan/resep dataset consumed by `lib/server/db/seed_history.dart` / `seed.dart`.
- Opening stock arrives as a `receive` movement per bahan through the real `receiveStock` path — never a bare balance — so `Σ movements == stockOnHand` holds from the first row.
- **Bahan are insert-if-absent; resep are replaced wholesale** on every re-run — `stockOnHand` and `costMicro` are the only numbers that become "real" once the venue trades, so a re-seed never rewrites a count or re-receives, but always repairs recipe data.
- Three cocktails (`margarita`, `negroni`, `rose`) are seeded **deliberately recipe-less**, demonstrating the "no recipe = never auto-habis" default. `nasi-goreng` carries all three recipe layers (base + full variant override + per-option adds) as the one worked example. Two produced bahan (`sambal`, `saus-kacang`) demonstrate `batchYield` + non-cascading habis.
- `test/seed_inventory_test.dart` pins the dataset shape: recipe lines must reference real bahan/variant/option ids, the ledger must sum to every balance, and a re-seed must leave moved stock alone.

**ADRs** docs/adr/0042-generic-seed-covers-inventory-and-recipes.md.

**Gotchas** Seeded bahan costs are demo figures tuned to land the derived recipe cost near the seeded `MenuItems.cost` (35% of price) — an owner who trusts the stock *value* on the report without re-pricing their own deliveries sees a number tuned to the sample menu, not their real purchasing.
