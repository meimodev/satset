# ADR-0096 — An opname is a document, not a burst of adjustments

Status: accepted
Date: 2026-08-10

## Context

[[Mutasi stok (Stock movement)|Stock movements]] have been an append-only
ledger since [ADR-0041](0041-stock-deducts-at-send-ledger-and-balance.md), and
`POST /stock/count` writes an `adjust` row per counted [[Bahan (Ingredient)|bahan]]
with `sourceLabel: 'Opname'`. That is enough to keep the balance honest and
nothing more. Three gaps fall out of it, and all three are the same gap.

**An [[Opname (Stocktake)|opname]] has no identity.** `produce` groups its input
and output rows under a `batchId`; a count groups nothing. "The 3 August opname"
is not a thing this database holds — only a scatter of rows an eye might
group by timestamp. Two people counting different shelves at once are
indistinguishable from one person counting twice.

**A correct count leaves no trace.** `recordCount` returns early when
`delta == 0`. The lines a manager most wants to see — *I counted it, it was
right* — are precisely the lines that do not exist. Any document assembled from
`adjust` rows is silently a document of failures only.

**Nobody is told it happened.** No `AuditKind` mentions stock. A session that
rewrites the pantry by 4 kg never reaches `/audit`, while a Rp 20.000 comp does.

Meanwhile the counting surface is a transient `bool _opname` on the Stock
screen holding an in-memory map. A real pantry walk crosses a walk-in, a dry
store and a bar, takes forty minutes, and dies when the tablet sleeps.

## Decision

**An opname is a first-class entity with its own header and its own lines.**
`StockCounts` (id, actor, `startedAt`, `closedAt`, `closedBy`, scope, blind,
note) and `StockCountLines` (count id, bahan, `expectedQty`, `countedQty`,
`costMicro`, note). Movements carry a nullable `countId` back to the session.
Schema v52.

**A session is a draft that freezes per line.** It opens, survives an app kill,
and writes its movements only at close — but each line stamps `expectedQty` and
`costMicro` **at the moment that line is entered**, not at close. This is the
whole reason the line table exists. Count ayam at 14:02, the kitchen sells
three portions at 14:20, close at 14:40: freezing at close would fold those
three sales into the variance and blame the counter for them. The `sale`
movements stand on their own and the variance is what was actually found.

**Every counted line is recorded; only a non-zero variance moves stock.** The
count is the evidence, the movement is the consequence. Keeping zero-variance
rows out of `StockMovements` preserves the rule that a movement moved
something, and keeping them in `StockCountLines` preserves the fact that
somebody looked.

**A session records whether it was blind and whether it was full.** Blind is
the default: the expected number is hidden on a counted line until close. A
sighted count is a legitimate spot-check but it is weaker evidence, and a
variance figure that cannot say which it was cannot be argued with. `scope`
(`full` | `partial`) carries the completeness claim, so a full session can warn
on uncounted active bahan before it closes and the owner can ask whether March
was covered.

**A historic session values itself at its own costs, forever.** Same discipline
as the frozen `sourceLabel` and the report DTOs: a document is what was true
then.

**Close posts exactly one audit row** — `AuditKind.stockCountClosed`, carrying
actor, scope, line count and total variance value. The per-line detail is in
the document; the log's job is *something material happened, here is who*.
The name is persisted and can never be renamed, so it is chosen once.

**No backfill.** `countId` is nullable and pre-v52 `adjust` rows keep it null.
`/opname` starts empty at a trading venue and fills from the next count. The
generic seed writes real sessions going forward so a seeded venue demos with
data.

**The archive lives at `/opname`**, tablet-only, reached from the Venue hub,
opened by `viewReports` **or** `manageIngredients` — the list-of-capabilities
shape `/kas` already uses. Counting stays on the Stock screen. Export offers
both flavours — PDF as the filing copy, CSV for the accountant — built from the
loaded document rather than fetched from the server. The venue log renders its
CSV server-side because the client holds only the pages it scrolled; a session
has no paging, so the document in hand already *is* the whole session, and a
round-trip would only re-render what is on screen. No picker sheet either:
`export_sheet.dart` earns its picker by also choosing a range and a kind, and a
session has neither.

## Considered options

**Reuse `batchId` for the session id.** Zero migration. Rejected: one column
would mean two unrelated things, which is the same trap
[ADR-0040](0040-ingredient-level-inventory-replaces-item-stock-counts.md)
records for per-item stock counts — two answers to one question, disagreeing by
the end of the first service.

**Infer sessions by grouping `adjust` rows within N seconds.** No schema change.
Rejected: silently wrong the first time two people count different shelves at
once, which a real pantry produces weekly.

**Reconstruct historic sessions as flagged synthetic headers.** Rejected: a
reconstructed opname is a claim nobody made, fabricated into an
integrity-adjacent surface.

**Approval above a variance threshold before movements are written.** The right
eventual shape, deferred: it invents a third header state, a settings
threshold and a review queue, all before anyone has read one real opname
document. `closedBy` / `closedAt` leave it a clean upgrade with no migration.

## Consequences

A count is now recoverable, attributable, and readable a year later at the
numbers it was closed with. Shrinkage becomes a trend across sessions rather
than a lump sum in one report section.

Closing is a heavier act than the current fire-and-forget POST — it writes a
header, N lines, M movements and an audit row in one transaction, and it can
fail late, after forty minutes of walking. The transaction boundary is the
mitigation and the draft is the safety net; a failed close leaves the session
open with its lines intact.

Blind-by-default makes counting slower and slightly less comfortable. That is
the point: a sighted count is the cheapest way to produce a variance figure
nobody should trust.

`ReportStockSection` keeps its aggregate role unchanged. The two surfaces
answer different questions — *how much did we lose this month* against *what
happened on 3 August* — and neither is derived from the other.
