# Accounting export: real settled figures, on-screen range bucketing

Status: accepted — **point 1 amended 2026-08-27** (see Amendment below).

The **Akuntansi** export kind (ADR-0030/0031 family) reports gross/net/tax/service/collected, payment-method totals, void-and-refund write-offs, and a per-day breakdown for a window. Two deliberate, non-obvious choices govern its numbers:

1. **Tax and service are the real settled figures**, summed from `table_sessions.taxAmount` / `serviceAmount` (computed at settlement by `bill_math.dart` from the venue's configurable `taxRateBps`, default 11%). The on-screen Reports KPI labelled "Pajak + Service" sums the same two columns, so the two tie out.

2. **The window uses the same range rule as the on-screen report** (the snapshot's `_resolveRange`, bucketing by the session's report timestamp), **not** settlement-date (`closedAt`) accrual. This was chosen so the accounting total always ties out to the Net the admin saw on screen, at the cost of strict accrual correctness near a business-day boundary (a bill opened 23:50 and settled 00:10 books to the open-side day, not the settlement day).

## Considered options

- **Real tax vs. reuse the 18% KPI estimate** — the estimate was wrong for books; reusing it would have propagated a fabricated number into accounting. Rejected. (The estimate itself was later retired too — see the Amendment.)
- **On-screen range rule vs. settlement-date accrual** — accrual is the textbook-correct anchor for revenue, but it would make the accounting export disagree with the on-screen Net for the same chip, which reads as a bug to the operator and erodes trust. We chose tie-out over accrual purity; the export footnotes the range basis so a bookkeeper knows.

## Consequences

- Only sessions visible to the snapshot's range filter appear; open/unsettled sessions (no finalized tax) are excluded.
- If the venue ever needs true accrual books, that is a new range mode, not a change to this one — do not silently switch the anchor.

## Amendment — 2026-08-27

Point 1 used to end: *"…**not** the on-screen Reports KPI labelled 'Pajak + Service', which is a cosmetic `net * 0.18` estimate. The two will not match; the export is the authoritative one."*

That carve-out is retired. The KPI now sums `taxAmount` / `serviceAmount` off the same session rows the export does, so there is one tax number in the venue and no reader has to know which surface is the honest one.

The estimate was never cheaper than the truth: the sales section already folds those rows, and the two columns sit on them. What it did cost was a venue that charges neither tax nor service, since `net * 0.18` was unconditional — such a venue was shown 18% of its takings as tax it had not taken, on the one screen an owner reads to find out what they took.

Point 2 (the range rule) is untouched and still governs both surfaces.
