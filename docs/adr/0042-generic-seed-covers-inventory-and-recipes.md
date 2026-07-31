# Generic seed covers inventory and recipes

Status: accepted

The prompted [[Generic seed (sample data)|generic restaurant seed]] (ADR-0017) predates ingredient-level inventory (ADR-0040/0041), so a freshly seeded venue had a full menu and an empty inventory: no [[Bahan (Ingredient)|bahan]], no [[Resep (Recipe)|resep]], every stock screen blank and no dish able to go auto-habis. Extending the dataset is mostly authoring, but two of its decisions are baked into shipped venues' history and are the reason this ADR exists: **how opening stock arrives** and **what a re-seed is allowed to overwrite**.

## Decision

1. **Opening stock arrives as a `receive` movement, not a bare balance.** Each seeded bahan is inserted at zero and then received through `receiveStock` — the same path a real delivery takes — which writes the [[Mutasi stok (Stock movement)|movement]] row, prices the moving average, and moves `stockOnHand` in one transaction. `Σ movements == stockOnHand` therefore holds from the first row, and the stock report opens with a first entry rather than a balance nobody can account for. This does not breach the seed's "no fake report history" rule (ADR-0017): there are no seeded sales, wastage or tickets — one arrival per bahan is the honest origin of the stock it creates.

2. **Bahan are insert-if-absent; resep are replaced.** `POST /seed/generic` is callable at any time by a `manageStaff` holder, not only on an empty DB. `stockOnHand` and `costMicro` are the only numbers in the whole dataset that become **real** the moment the venue trades, so a re-run skips any bahan whose id already exists — it never rewrites a count, never re-receives, and never resets a moving average. Resep, names and thresholds are reference data like the menu itself and are rewritten wholesale, so a re-seed still repairs them.

3. **Not every item gets a resep.** The three cocktails (`margarita`, `negroni`, `rose`) are seeded deliberately recipe-less. An item with no recipe consumes nothing and is never auto-habis (ADR-0040 §4) — that is the correct default, and the seed shows it rather than hiding it behind 100% coverage, because a live venue migrates one dish at a time. `bintang` instead carries the canonical self-recipe: one bottled bahan, 1 pcs per pour.

4. **One item carries all three recipe layers.** `nasi-goreng` has a base list, a full `lg` (Besar) override, and per-option adds on protein and extras; every other item is base-only. The sharp edge in the model is that a variant list *replaces* the base rather than scaling it, and one worked example demonstrates it — repeating the shape on six more items is authoring cost without new information.

5. **Two produced bahan.** `sambal` and `saus-kacang` carry their own recipes and an explicit `batchYield`, consuming only non-produced bahan (the one-level rule, ADR-0040 §5). They also make the non-cascading habis rule visible: sambal at zero makes the dish habis even while cabai is plentiful.

6. **Bahan prices are tuned, not market rates.** Prices sit at roughly 1.0–1.5× Indonesian market rates so the derived recipe cost lands near the seeded `MenuItems.cost` (35% of menu price) rather than far below it. The fit is loose by design — the seed menu is priced at resort level, so an honest drink lands near 11% and a rendang near 36%, and forcing every item to 35% would need prices like Rp654,000/kg for tea. `MenuItems.cost` stays authoritative (ADR-0040 §7); the derived figure remains a hint beside it.

7. **The seeded Kitchen role gains `adjustStock` + `manageIngredients`.** The people who physically receive and count stock are the ones who record it. `overrideStock` is deliberately *not* seeded onto any role: selling past zero stays an explicit grant, so the default venue cannot quietly drift its balances negative.

8. **`needsGenericSeed` is unchanged.** It still looks at zones, menu items and non-admin users. Adding bahan to the check would guard against a state that cannot realistically occur, and decision 2 already removes the damage it would prevent.

## Considered options

- **Set `stockOnHand` directly and skip the movements** — fewer writes, no ledger noise. Rejected: the ledger and the balance disagree from day one, which is exactly the invariant ADR-0041 exists to protect, and every stock report opens empty against non-zero balances.
- **Seed opening stock as an `adjust` (opname) movement** — also consistent. Rejected: `adjust` deltas *are* the variance figure the report shows (ADR-0041 §7), so seeding them fabricates a variance against a count nobody performed.
- **Upsert bahan like every other seeded row** — uniform with the rest of `seedGenericRestaurant`. Rejected: one re-post of `/seed/generic` would silently restore every count to its opening value while the ledger still showed the venue's sales.
- **Skip the whole inventory block when any bahan exists** — simpler guard. Rejected: too coarse. A venue that deleted one seeded bahan would never get it back, and recipe corrections would stop landing.
- **Recipes for all 16 items** — complete coverage. Rejected: the recipe-less default is a state staff will meet during their own migration, and a seed that never shows it teaches the wrong model.
- **Derive `MenuItems.cost` from the seeded recipes instead of tuning prices** — a single source of truth, self-updating. Rejected here for the same reason ADR-0040 §7 rejected it globally: the manual field stays authoritative, and the seed should look like a correctly-authored venue, not a special case.

## Consequences

- A freshly seeded venue can exercise the whole inventory spine on day one: stock list with one low badge (udang), recipe editor with a worked three-layer example, production batches, opname, and stock-driven habis after a few sends.
- Seeded costs are demo figures. An owner who trusts the stock *value* on the report without re-pricing their own deliveries will see a number tuned to the sample menu, not to their purchasing.
- The seed now depends on `lib/server/stock.dart` (`receiveStock`, `writeRecipes`), so seeding runs the production write paths rather than raw inserts — a change to the ledger's shape breaks the seed loudly, which is the intended coupling.
- `test/seed_inventory_test.dart` pins the dataset: recipe lines must reference real bahan and real variant/option ids, quantities must be authored in a compatible unit, produced bahan must not nest, the ledger must sum to every balance, and a re-seed must leave moved stock alone.
