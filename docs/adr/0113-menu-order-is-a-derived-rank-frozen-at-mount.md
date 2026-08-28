# Menu order is a derived rank, frozen at mount

**Status:** Accepted — 2026-08-28.

## Context

`menu_items` has no `sort_order` column. Categories have one; items never did.
The order-flow grid therefore rendered items in raw SQLite insertion order —
whatever the seed or the owner happened to type first — for the whole life of
the app.

That is invisible on the seed's 42 items and useless on a real menu. A waiter
looking for the drink half the room orders scrolled, or typed. The search box
became the primary navigation for a screen that already had every item on it,
which is the tell: the grid populated fine, it just populated in an order that
carried no information.

The venue already knows the answer. Every line ever sent is a row in `tickets`
with an `item_id` and a `qty`. Reports already ranks items from exactly that
(`reports_routes.dart`), by **revenue**, for menu engineering.

## Decision

**The order-flow menu grid sorts by lines sold in the last 30 business days.**

Four parts, each of which had a plausible alternative:

**1. Qty, not revenue, and a window aligned to the rollover.**
`menuPopularity(db)` sums `tickets.qty` per `item_id` since
`businessDayStart(now, hour) - 30d`, excluding `voided` and counting every other
status — `draft` and `held` included. A waiter reaching for a tile wants the
thing ordered most, not the most expensive thing, so this is deliberately *not*
the Reports ranking and does not share its code. `held` counts because
popularity is what a guest asked for, not what the bill kept. The window edge is
the business day's rollover rather than `now - 30d` so the set of days counted
does not change between 03:00 and 05:00.

**2. Derived, never stored.** Same shape as `autoSoldOut` (ADR-0040): computed
on every `/menu` snapshot, riding the existing payload as `popQty`, no column,
no counter to increment on write, nothing to backfill or repair. A stored
`sales_count` would be a second source of truth about a fact `tickets` already
holds — and the first void would make it a lie.

**3. The client sorts, not the server.** The snapshot could have returned the
array pre-sorted, which needs no DTO field at all. It was rejected: `/menuadm`
reads the same `menuItemsProvider`, and an owner hunting an item to edit wants a
list that does not move between shifts. `popQty` on the item lets one surface
rank and the other ignore it. The guest page is unaffected either way — it
builds its own payload (`guestMenuJson`) and has `guestFeatured`, an
owner-authored pin that sales must not silently fight.

**4. The rank is frozen at mount.** `menuUpdated` fires on a stock flip, several
times an hour in a rush. Re-sorting live would move a tile between the look and
the tap — the one bug this feature can actually cause, and a waiter's muscle
memory is the thing being optimised. `_MenuScreenState` captures id → `popQty`
from the first non-empty menu it sees and sorts by that map for the life of the
order. An item that arrives after that lands at the bottom.

Unranked items — a new dish, a fresh venue, a venue whose `contoh` data was
cleared — sort last, **alphabetically**. A fresh venue therefore gets an
alphabetical grid, which is a better accident than insertion order. There is no
"Baru" pin: a new item nobody orders should sink, and pinning it would be a
second ranking rule to reason about.

Search results are **not** re-ranked. A live query already ignores the category;
having it also reshuffle as the venue trades costs a waiter more than the
ordering buys.

## Consequences

- `tickets(item_id, sent_at)` index added (v65). Without it the rank is a full
  scan of every line the venue ever sent, on a call a stock flip triggers.
- The aggregation is recomputed per snapshot, uncached. `deriveStockFlags`
  already walks every recipe on the same call; a cache would be a second thing
  to invalidate on an event that already means "re-read the menu". If a real
  venue's snapshot measurably slows, cache then.
- `popQty` is 0 on the single-item read (`GET /menu/items/<id>`) — that route
  feeds an editor, which does not rank — and 0 from an older server, which reads
  as unranked rather than as an error.
- Kedai home (ADR-0109) inherits this: it is the same `MenuScreen`.
