# Per-item modifier groups, embedded as JSON

Modifier groups (add-ons like "Tingkat pedas", "Pilih protein") are **private to one item** and stored as a `modifierGroupsJson` blob on the menu item row — mirroring how variants are already stored. The shared `ModifierGroups` table and the `modifierGroupIdsJson` indirection are dropped (migration backfills existing per-item groups into the new column before dropping the table).

## Why

The original schema kept one global `ModifierGroups` table (reusable across items), but the admin editor created groups inline per-item with locally-minted, non-unique ids (`g0`, `g1`, options `o0`). `insertOnConflictUpdate` meant two items each creating `g0` overwrote each other's group globally, and editing a "shared" group from one item silently mutated every other item referencing the same id. We chose per-item ownership to kill that whole class of bug.

## Considered and rejected

A true shared modifier **library** (manage groups as first-class entities, attach by id, "used by N items" awareness). Rejected: the venue's modifiers are small and item-specific; the reuse payoff doesn't justify the attach/detach UI, orphan handling, and the footgun of one edit rippling across unrelated items. Re-entering "Tingkat pedas" on a few items is cheaper than that complexity.

## Consequences

- Editing a modifier on one item never affects another, even with identical names.
- No orphan groups, no id-collision class of bug.
- Tickets already snapshot their modifiers (`modifiersJson`), so existing orders are unaffected by the schema change.
- Reverting to a shared library later is a meaningful migration, not a config flip.
