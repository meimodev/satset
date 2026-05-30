# Allergen / diet tags live-resolve on sent lines — not snapshotted

Per-line-item allergen and diet badges (on the review/order-confirmation and table-detail line items) resolve the item's tag ids **live** against the current menu snapshot by `itemId`. They are **not** frozen onto the sent line. This deliberately differs from modifiers, which **are** snapshotted onto the line (ADR-0011).

## Why

A reader who knows ADR-0011 will ask: modifiers freeze onto the line so the KDS and reports are self-sufficient and immune to later menu edits — why not allergens too? The answer is that the two carry different obligations:

- A **modifier** is the guest's *choice*, captured at order time. It must survive the menu being re-priced or re-worded, and the KDS has **no menu** to resolve ids against — so it has to ride the line.
- An **allergen/diet tag** is a *property of the dish*, not a choice. The only readers that show it (review screen, table detail) **already hold the live menu snapshot** and resolve `itemId` for name, price, and the existing aggregate today. There is nothing to freeze that the screen can't re-derive for free.

So snapshotting buys no new reader independence here — it only adds a wire field, a DB column, and a migration. We resolve live and keep the line lean.

The existing table-detail **aggregate** (`ctxAllergens`) and review **top pill** already live-resolve. Per-line-item resolution extends the same path rather than introducing a second, snapshot-based one — one mental model for tags.

## Considered and rejected

- **Snapshot allergen/diet ids onto the ticket (mirror ADR-0011).** Rejected: the only readers hold the menu already; freezing adds `TicketDto`/`Ticket` fields, a DB column on `tickets` + `table_session_tickets`, a seed change, and a migration — for no reader that lacks the menu. ADR-0011 paid that cost because the KDS genuinely has no menu; no allergen reader is in that position.
- **Snapshot just the resolved code/colour strings.** Same migration cost, plus it bakes presentation into storage (the thing ADR-0011 explicitly avoided for modifier sign/amount).

## Consequences

- A tag renamed, recoloured-by-kind, or deleted after a line is sent **retroactively** changes (or drops) that line's badges on the table-detail screen. Accepted: tags rarely change mid-service, deletion already cascade-strips the id from items, and a stale-but-live badge is no worse than the aggregate, which behaves identically today.
- A line whose `itemId` no longer resolves (item deleted post-send) shows **no** badges — fail-open to silence, consistent with the aggregate.
- **Safety caveat:** because badges are not frozen, they are a *display aid*, not a legal allergen record. If a frozen-at-order-time allergen audit trail is ever required (regulatory), that is a snapshot feature and supersedes this ADR — reverting to snapshot is then a migration, not a config flip.
- No wire, DB, or seed change ships with this feature — it is pure UI over existing providers.
