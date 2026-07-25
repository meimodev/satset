# `settledTotal` instead of redefining `netTotal` a second time

`TableSessions.netTotal` has already meant two different things. Before [ADR-0023](0023-two-phase-settlement-and-split-bills.md) it was simply `subtotal`; that ADR redefined it to `subtotal − void + service + tax` and left a standing warning against reading historical rows under the old meaning. Adding a [discount](0037-cashier-stage-catalog-discounts.md) would force a **third** redefinition, leaving three eras in one column distinguishable only by date. Instead, `netTotal` is frozen at its current formula forever and a new column carries the money actually collected.

## Decision

- **`netTotal` keeps its ADR-0023 formula permanently**: `subtotal − void + service + tax`. It does **not** learn about discounts. From ADR-0023 onward its meaning never changes again, so a query spanning last year and next year compares like with like.
- **New `settledTotal` = `netTotal − discount`** is the money-collected figure. All reporting, exports, and the cashier's outstanding math migrate to it. `netTotal` becomes a legacy pre-discount net, retained for continuity.
- **New `discountAmount`** on `TableSessions` (and on `Receipts` / `TableSessionReceipts`) so the reduction is a first-class figure rather than a difference between two totals.
- **Nothing is backfilled.** Pre-discount rows get `discountAmount = 0` and `settledTotal == netTotal`, which is already true of them. The single documented anomaly stays the pre-ADR-0023 era where `netTotal == subtotal`.
- **Reporting surfaces a `Diskon` line** beside Bruto / Pajak / Layanan in the accounting and order-history exports, plus a **`GROUP BY presetId`** per-preset rollup ("Member 10% — 12×, Rp 340.000") in the accounting export only. That rollup is the payoff for choosing a preset catalog over ad-hoc entry in [ADR-0037](0037-cashier-stage-catalog-discounts.md), and it is the reason `presetId` is retained beside the snapshot. No new Reports screen section — it stays a query, not a UI project.

## Considered options

- **Redefine `netTotal` in place.** Fewer columns, and the name would keep matching what it holds. Rejected: a third meaning in one column is a trap that costs more, every time someone reads history, than the column saves once. The existing `CONTEXT.md` warning about era-1 rows is evidence the first redefinition already hurt.
- **Add `discountAmount` alone, leave `netTotal` computing the old formula.** Rejected outright: `netTotal` would silently stop equalling money collected. A wrong number is worse than a redefined one.
- **Fold the discount into the reported gross.** Rejected: it hides the cost of promos inside the one figure the owner uses to judge the business, and makes Bruto stop meaning "what we rang up". Void and refund write-offs are already kept visible for exactly this reason, and a discount is the same kind of deliberate revenue give-back.

## Consequences

- Two new columns on `table_sessions`, one on `receipts` and `table_session_receipts`. Schema 34 → 35, additive.
- Two total columns coexist and a future reader will ask why. `netTotal` is the answer to "what did we ring up net of voids", `settledTotal` to "what did we collect" — worth stating wherever either is read.
- Any query still reading `netTotal` as revenue is now subtly wrong for discounted bills. Migrating every reporting call site to `settledTotal` is part of shipping this, not a follow-up.
- Comps continue to land in the void/write-off figure and never in Diskon, so the two give-back figures stay disjoint and summable.
