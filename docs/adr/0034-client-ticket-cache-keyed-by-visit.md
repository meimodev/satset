# Client live-ticket cache keyed by Visit, not Table

Status: accepted

The client holds live tickets in one in-memory map (`tickets_repository`). Historically dine-in groups were keyed by `tableId` and takeaway groups by `visitId`. This ADR makes the key **`visitId` for every group**, and resolves a dine-in screen's lines through the table's **current** visit (`tableId → currentVisitId → map[visitId]`).

A [[Reseat]] recycles a `tableId` across unrelated [[Visit]]s. The [[Visit]] — not the table — is the stable key a [[Bill (tab)|bill]] and its lines hang off (ADR-0024). The client cache now mirrors that truth.

## Context — the bug this fixes

Reseat showed ghost lines from the **previous** party: a closed-and-settled table, freshly seated for a new party, intermittently displayed the old visit's orders. Server DB was clean (ghosts died on app restart) — purely a client-cache fault.

Mechanism: with dine-in keyed by `tableId`, the WS handler had **no visit-generation guard**. Close broadcast `tableUpdated status=available`, which purged the table's group by `tableId`. But a *trailing* `ticket.*` event for the just-closed visit (a final serve, snapshot churn, or plain WS reordering) arrived **after** the purge and re-inserted the old line under the reused `tableId`. "There is a chance" = the race between the purge and the last in-flight ticket event. Keying by `visitId` removes the collision at the root: an old visit's lines live in their own group and are simply never resolved as the table's *current* visit.

## Decision

1. **Server** exposes `currentVisitId` on the table payload (`_toJson(VenueTable)`). The client cannot resolve table→visit without it. Mandatory for this approach.
2. **Models** — `TableDto` + domain `VenueTable` gain `currentVisitId`; domain `Ticket` gets `tableId` back (already on the wire DTO) so flatteners stop leaning on the map key for a table identity.
3. **Repo** — `_groupKey` is always `visitId` (legacy null-`visitId` rows keep the `tableId` fallback, defensively). The blunt `tableUpdated`-kosong purge is dropped; the `tableSessionClosed`-by-`visitId` purge stays to free memory on snapshot.
4. **Provider** — `ticketsForTableProvider(tableId)` watches `tablesProvider` + `ticketsProvider`, returns `map[currentVisitId] ?? []`, and `[]` when the table has no live visit. The four dine-in `[tableId]` call sites switch to it; map-flattening consumers (orders/kitchen/me/alert_sound) read `t.tableId` and treat the key as opaque.
5. **Optimistic seed** — dine-in `submitOrder` threads the `/orders` response `visitId` (server already returns it) into `tables_repository`'s `currentVisitId` for that table, so the sending device resolves its lines immediately instead of flashing empty until the `tableUpdated` echo lands.

## Considered options

- **Visit-generation guard, keep tableId keying (Option A)** — add `currentVisitId` to the table, then on `ticket.*` ignore events whose `visitId ≠` the table's current visit, and evict on visit change. Smaller surface, keeps the existing grouping and UI untouched, fixes the same race. Rejected as the *primary* shape because it patches the symptom (filter bad events) rather than the cause (the cache key lies about identity); the `tableId`/`visitId` split between dine-in and takeaway persists, and every future ticket-event path must remember the guard. C unifies the model so the guard is unnecessary.
- **Client-only, no server field** — track "latest visit seen per table," reject older-visit events. No round-trip, but visit ids are UUIDs with no chronological order, so it needs a `sentAt`/generation heuristic and is brittle across reconnects. Rejected.
- **Stop the trailing events server-side** — they are legitimate at emit time; reordering is the network's doing, not the server's. Not addressable there.

## Consequences

- One new field flows server→client (`currentVisitId`). `TableDto` change requires `tool/codegen.sh` (freezed/json). No DB migration — the column already exists.
- Domain `Ticket` gains `tableId`; consumers that read the old map key as a table id (`orders`, `kitchen`, `me`, `alert_sound`) switch to `t.tableId`. Takeaway lines (empty `tableId`) keep labelling via the visit, unchanged.
- Dine-in line lookups go through one indirection (`ticketsForTableProvider`). A reseated table whose `tableUpdated` echo has not yet landed shows no lines for a beat on **non-ordering** devices; the optimistic seed covers the ordering device on the happy path. Self-heals within a beat.
- Stale visit groups (a detached-but-bill-still-open visit) linger in the client map under their `visitId` until `tableSessionClosed` purges them on snapshot. Harmless — never resolved as a table's current visit.
- The fix is client-architectural; server behaviour is unchanged beyond the added field. If a future need wants per-table line history on the client, it reads through visits, not by recycling `tableId`.
