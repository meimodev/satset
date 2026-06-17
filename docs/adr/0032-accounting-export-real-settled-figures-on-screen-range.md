# Accounting export: real settled figures, on-screen range bucketing

Status: accepted

The **Akuntansi** export kind (ADR-0030/0031 family) reports gross/net/tax/service/collected, payment-method totals, void-and-refund write-offs, and a per-day breakdown for a window. Two deliberate, non-obvious choices govern its numbers:

1. **Tax and service are the real settled figures**, summed from `table_sessions.taxAmount` / `serviceAmount` (computed at settlement by `bill_math.dart` from the venue's configurable `taxRateBps`, default 11%) — **not** the on-screen Reports KPI labelled "Pajak + Service", which is a cosmetic `net * 0.18` estimate. The two will not match; the export is the authoritative one.

2. **The window uses the same range rule as the on-screen report** (the snapshot's `_resolveRange`, bucketing by the session's report timestamp), **not** settlement-date (`closedAt`) accrual. This was chosen so the accounting total always ties out to the Net the admin saw on screen, at the cost of strict accrual correctness near a business-day boundary (a bill opened 23:50 and settled 00:10 books to the open-side day, not the settlement day).

## Considered options

- **Real tax vs. reuse the 18% KPI estimate** — the estimate is fine for a glanceable dashboard but wrong for books; reusing it would silently propagate a fabricated number into accounting. Rejected.
- **On-screen range rule vs. settlement-date accrual** — accrual is the textbook-correct anchor for revenue, but it would make the accounting export disagree with the on-screen Net for the same chip, which reads as a bug to the operator and erodes trust. We chose tie-out over accrual purity; the export footnotes the range basis so a bookkeeper knows.

## Consequences

- Only sessions visible to the snapshot's range filter appear; open/unsettled sessions (no finalized tax) are excluded.
- If the venue ever needs true accrual books, that is a new range mode, not a change to this one — do not silently switch the anchor.
