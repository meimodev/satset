# Customizable menu tags (allergen / diet) as data, not enums

Allergen and dietary labels move from fixed Dart enums (`Allergen`, `DietaryTag` + const `name`/`code` maps) to admin-managed rows in a single `menu_tags` table (`id, kind, name, code, sortOrder`, where `kind` ∈ `allergen | diet`). Menu items keep referencing tags by **id** in their existing `allergensJson` / `dietaryJson` arrays. Tags ride the `/menu` snapshot and broadcast `menuUpdated`. Managed from a third **Tag** tab in the menu admin, gated by `Capability.editMenu`.

## Why

The venue's allergen and diet vocabulary is not universal — a halal-first warung and a vegan café want different labels, and the hardcoded eight-allergen / seven-diet enums forced a code change (and rebuild) to add "Sulfites" or "Keto". Making them data lets an admin curate the list at runtime, same as categories.

We seed the new table with ids equal to the legacy enum names (`gluten`, `vegan`, …). Because items already store those names as strings in `allergensJson` / `dietaryJson`, **no per-item migration is needed** — the strings are already valid tag ids the day the table appears.

## Considered and rejected

- **Two tables (`allergens` + `diet_tags`).** Cleaner separation, but doubles routes, repo, and UI for two structurally identical entities. One table with a `kind` discriminator reproduces the existing two-map split with half the plumbing.
- **Per-tag custom colour.** Rejected: colour stays kind-derived (allergen → warn, diet → info), matching today's render. Free colour invites unreadable badges and adds a picker for little value.
- **Free-form string tags (level C).** Items already carry `List<String>`, so bare tags were tempting. Rejected because the UI renders **code badges** ("GL", "VG") and kind-based colour — that metadata needs a stable entity, not an ad-hoc string.
- **A separate `tagsProvider` + `tagsUpdated` WS event.** Rejected in favour of folding tags into the `/menu` snapshot: the menu repo already refetches the whole (small) snapshot on any `menuUpdated`, and tags are tiny.

## Consequences

- Adding/renaming/reordering an allergen or diet is a runtime admin action, no rebuild.
- Renaming a tag never breaks item references (items hold ids, not labels).
- Deleting a tag **cascade-strips** its id from every item's JSON, so no dangling refs accumulate.
- The `Allergen` / `DietaryTag` enums and their const maps are deleted; every consumer (menu admin, menu screen, review, modifier sheet, table detail) resolves a tag id against the snapshot instead.
- Reverting to enums later is a meaningful migration, not a config flip.
