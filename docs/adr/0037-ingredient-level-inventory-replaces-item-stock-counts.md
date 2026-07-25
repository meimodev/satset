# Ingredient-level inventory replaces item stock counts

Status: accepted

SatSet tracked availability with one nullable `MenuItems.stockCount` plus an `autoSoldOutAtZero` flag — a per-dish counter someone decremented by hand. This ADR replaces it with **[[Bahan (Ingredient)|bahan]] + [[Resep (Recipe)|resep]]**: stock is held against raw ingredients, and selling a dish deducts what its recipe says it consumes. `stockCount` and `autoSoldOutAtZero` are **dropped** in migration v35, with existing counts converted into self-named `pcs` bahan.

The item counter could only answer "how many portions of this dish are left", which nobody maintains once the same beras backs six dishes. Recipes make the deduction automatic and make one bahan's depletion mark every dish that needs it.

## Decision

1. **Bahan is the only stock entity.** A bottled drink is a bahan whose recipe is one of itself — there is no second "countable SKU" concept alongside ingredients. Rejecting a parallel item-level counter is the point of the ADR (see Considered options).

2. **Quantities are integers at 1/1000 of a dimension's canonical base** (mg, µl, milli-pcs) — the same exact-integer discipline the codebase already uses for money. Unit **presets** are grouped by dimension: mass (`mg`/`g`/`kg`), volume (`ml`/`L`), count (`pcs`, `butir`, `siung`, `lembar`). Units convert freely *within* a dimension, never across; count presets are display labels only and never inter-convertible. The bahan's chosen preset is entry/display, not storage.

3. **Recipes resolve against the exact configuration ordered**, in three layers: the item's **base** list; a **per-variant** list that *replaces* the base entirely; and **per-modifier-option** lists that *add* on top of whichever won. Recipes are private to their item, like [[Modifier group (add-on)|modifier groups]] and [[Variant (variation)|varian]] — there is no shared recipe library.

4. **An item with no recipe consumes nothing** and never goes auto-habis. This is the correct default, not an error state: it lets a live venue migrate one dish at a time.

5. **Bahan may themselves carry a recipe**, with an explicit **yield** (`this batch makes 2 kg sambal`), consumed by a `produce` movement that deducts inputs and credits output in one transaction. **One level only** — a produced bahan's recipe may contain only non-produced bahan. Habis does **not** cascade: sambal at zero makes the dish habis even when chilli is plentiful, because unmade sambal cannot be served.

6. **Habis is derived at three granularities** — item, variant, and modifier option — so "Besar" can be unavailable while "Reguler" sells. Derived flags ride the `/menu` snapshot and are broadcast **only when a flag flips**; beras dropping 8.0 → 7.8 kg is silent. Manual habis stays sticky and independent; receiving stock un-habises automatically because the flag is computed, never stored.

7. **`MenuItems.cost` stays authoritative.** Recipes can derive cost (Σ qty × bahan moving-average cost) but that figure is shown only as a **hint** beside the manual field. Margin and [[Menu classification]] reporting is untouched by this feature.

8. **Migration v35** drops `stockCount` and `autoSoldOutAtZero`. Every item with a non-null `stockCount` gains a self-named bahan (unit `pcs`, stock = the old count) and a 1-pcs recipe, preserving its behaviour on the new spine. One-way, against shipped production data (v1.0.1).

9. **New capabilities** `manageIngredients` and `overrideStock`, group `inventory`. Both are **backfilled** at migration — any role holding `adjustStock` gets `manageIngredients`, any role holding `markSoldOut` gets `overrideStock` — following the existing `voidItem` backfill precedent.

## Considered options

- **Keep `stockCount` alongside bahan, layered** — bahan for cooked dishes, the item counter for bottled SKUs where a recipe feels like overhead. Rejected: two fields answering "how many left" will disagree by the end of the first service, and staff will believe whichever is more convenient. Modelling a bottle as a bahan costs one row and removes the ambiguity entirely.
- **Keep the columns but stop reading them** — no migration risk. Rejected: dead columns that the next reader will assume are live.
- **Derived cost replaces `MenuItems.cost`** — a single source of truth, and self-updating as prices move. Rejected because on day 1 almost nothing has a recipe, so every un-migrated item's margin would drop to zero and the classification report would be wrong for the whole menu. A *partial* recipe is worse still: it understates cost, overstates margin, and looks authoritative. The manual field degrades honestly; derived-as-hint lets the gap be seen at authoring time.
- **Per-variant multiplier instead of a full override** (`Besar = 1.5×`) — one field per variant, far less authoring. Rejected: a size step is not always proportional, and a "Besar" that swaps in a second protein is mismodelled by any scalar. The override costs more editing and is right in every case.
- **`double` quantities with free-text units** — natural to author. Rejected: float drift accumulates over thousands of deductions and makes `<= 0` comparisons fuzzy, and free text blocks the unit conversion this design relies on.
- **Full multi-level BOM** for produced bahan — arbitrary nesting. Rejected: nesting buys nothing a single level doesn't for a warung, and makes cost resolution recursive.

## Consequences

- `Capability.adjustStock` loses its current job (it gates the item-level stock-delta route at `lib/server/routes/menu_routes.dart`); that endpoint and `menuRepository.adjustStock` are rewritten against bahan rather than deleted.
- The `/menu` snapshot grows three derived flag sets (item, variant, option). The [[Guest plane]] self-order SPA renders from that same snapshot, so guests get habis behaviour with no extra work — a guest cannot order a dish the kitchen cannot make.
- Bahan data is **not** mirrored into a client repository. Only derived flags are cached and broadcast; the bahan list, movements, and opname screens fetch on demand over HTTP, gated by `manageIngredients` rather than by app mode — so an [[Admin-client]] manages stock without being sent to find the host tablet.
- Recipes are authored in the existing menu **item editor** (beside variants and modifiers, which a per-variant recipe is meaningless without). Bahan, movements, receiving, and opname live in a new `/stock` section off the Venue Hub.
- Migration v35 is one-way against production data. A venue that had `stockCount = 24` on Coca-Cola wakes up with a Coca-Cola bahan at 24 pcs and a 1-pcs recipe — same behaviour, new spine.
- Batch-prep venues must record `produce` events or their raw inputs drift; the drift surfaces at opname as variance rather than silently.
