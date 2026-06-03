# A Visit is decoupled from its Table, and the snapshot moves from table-close to bill-close

**Status:** accepted — amends [0023](0023-two-phase-settlement-and-split-bills.md)

## Context

ADR-0023 split end-of-visit into **Settlement** (record payment) then **Close** (free table + snapshot `TableSession`), but kept Close as a single act that did three things at once — free the table, hard-delete the live tickets, and snapshot history — and asserted "**the table *is* the bill**" (tickets/receipts key off `tableId`; no visit identity). The cashier screen surfaced a convenience "Tutup meja" that called that same Close.

Two confusions surfaced in use:

1. **One name, two concerns.** "Tutup meja" on the cashier screen (money done) and the floor act of freeing a table (so another waiter can reuse it) read as the same thing, but the cashier should never be the one freeing the floor table, and a waiter freeing a table should not depend on money being collected.
2. **Walkouts have nowhere to live.** Because money and table were the same act, a party that leaves without paying forced a choice between *not* freeing the table (blocking the floor) or freeing it and losing the bill. Real venues need to free the table immediately **and** keep chasing the money.

The requirement that crystallised: the **table** (a floor/occupancy concern, the waiter's) and the **bill** (money, the cashier's) must end on **independent axes**, in either order, and the unpaid bill must survive the table being freed and reused.

## Decision

**Introduce a first-class live `Visit` that owns the tickets/receipts/payments, decouple it from the physical table, and move the `TableSession` snapshot from table-close to bill-close.**

- **Visit identity.** A live **Visit** (its own id, stamped at [[Seat (verb)|seat]]) becomes the key tickets and receipts hang off — `Tickets`/`Receipts` re-key from `tableId` to `visitId` (payments stay under `receiptId`). `VenueTable` gains a nullable `currentVisitId` (null ⇒ kosong). The live session fields currently embedded on the table row (pax, openedAt, guestName/guestNotes, reservationId, openAmount, readyCount, lastActorId) move onto the Visit, with the table label/zone frozen onto the visit for display after detach.

- **Two independent end-acts (either order):**
  - **Table close (detach)** — waiter/floor. Sets `table.currentVisitId = null`, `status = available`, stamps `visit.tableFreedAt`. **Keeps** the existing **all-tickets-terminal** gate and the **[[Table lock]]** requirement. Copy stays "Selesaikan Layanan" / "Lepaskan Meja".
  - **Bill close (Tutup tagihan)** — cashier/money, gated by `settleBill`. **Locks** the bill (stamps `visit.billClosedAt`). Two flavors: **Lunas** (requires outstanding == 0) and **tak tertagih** (write-off; records `lossAmount = outstanding`, needs a reason + manager-approved `refund`/comp authority, reported distinctly from comps).

- **The snapshot fires at the SECOND axis (deferred), not literally at bill close.** A `TableSession` (+children) is written — and the live visit/tickets/receipts deleted — **exactly once per visit**, by whichever act completes the pair: bill-close *when the table is already freed*, or table-close *when the bill was already locked*. The first act only records its timestamp and keeps the visit live (so a bill locked while guests linger doesn't strand the still-occupied table). Both orders converge:
  - normal: bill close (lock) while occupied → later table close snapshots → visit gone;
  - walkout: table close (detach) → bill still open on cashier, flagged → later bill close (pay or write-off) snapshots → visit gone.

- **Cashier lists open visits, not tables.** Attached *and* detached visits appear; detached-unpaid ones carry a visual flag and their frozen "Meja 7 · ditutup 19:40" label. A reseated table produces a **new** visit — old (detached) and new (live) coexist as two entries, never merge.

- **Corrections are pre-bill-close only.** Reopen/un-pay and post-payment void/comp/refund (ADR-0006) are allowed while the bill is open; after bill close the snapshot is immutable.

- **Past bills (cashier).** A per-table, last-7-days read-only view over snapshotted `TableSession`s (retention for reports is unchanged; 7 days is only the view window).

A schema migration re-keys live tickets/receipts onto a visit id and backfills a Visit per currently-occupied table.

## Considered options

- **Visit decoupled from table; snapshot at bill-close (chosen)** — the only model where the floor table frees instantly *and* an unpaid bill survives reuse cleanly. Cost: a `visitId` re-key + migration, and the cashier list now spans two visit shapes (attached/detached).
- **Snapshot at table-close; unpaid becomes an *open, settleable* `TableSession`** (rejected) — avoids the live re-key, but makes the historical snapshot table mutable (a settleable "history" row is a contradiction), and forces settlement code to run against both live receipts and snapshot rows.
- **Block reseat until the bill is cleared** (rejected) — keeps "one bill per table" and needs no visit id, but defeats the whole point: the floor can't reuse a table while the cashier chases a walkout. The user explicitly wants the table freed immediately.
- **Rename only, no behavior change** (rejected) — relabels the cashier button but leaves money and table fused; the walkout problem remains.
- **Zero-out walkouts as comps instead of a write-off** (rejected) — simpler, but buries genuine walkout loss inside comp metrics; an explicit `lossAmount` keeps reporting honest.

## Consequences

- **Reverses ADR-0023's "the table is the bill / no visit identity" stance** and its "Close snapshots" timing; ADR-0023's settlement, split-bill, tax/service, and payment model otherwise stand.
- Touch points for the re-key: seat, **[[Pindah meja (Move table)|move]]** (re-points a visit's table, ADR-0019), KDS/floor/cashier queries (table → currentVisit), and the close/settlement routes. Move semantics are unchanged in spirit (still one visit, one session) but now operate on `visitId`.
- New states the UI must surface: occupied + Lunas (paid, lingering), and **kosong-on-floor + open-bill-on-cashier** (detached unpaid).
- `settleBill` now also gates **bill close**; the cashier loses any table-freeing affordance.
- Migration risk: existing occupied tables must each get a backfilled Visit; pre-migration `TableSession`s remain valid history.
