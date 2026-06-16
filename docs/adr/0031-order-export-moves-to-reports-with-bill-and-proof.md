# Order export moves to Reports and carries bill totals, payments, and proof photos

**Status:** accepted — supersedes the *location* decision in [0030](0030-client-side-range-scoped-export.md)

## Context

[[ADR-0030]] placed the order-history export on the **Pesanan order board** and scoped its range inside the export sheet so the live board stayed live. The board location was chosen mainly to keep the export next to the data it mirrors.

Two things have since changed the calculus:

- The board is a **waiter operational surface** (`takeOrder`), but the export exposes historical financial data and is gated `viewReports`. The trigger sat on a screen most of its users couldn't action.
- The export was **line-items only** — it showed each visit's items and a `net`, but none of the **bill settlement** that closed the visit: no tax/service breakdown, no record of *how* the bill was paid, and no link to the mandatory non-cash proof photos ([[ADR-0025]]).

The Reports screen is already the financial, `viewReports`-gated home and already hosts the report-summary export. The payment data needed for enrichment already exists in the per-session snapshots written at bill close (`TableSessionReceipts`, `TableSessionPayments`), and proof photos already have an on-demand history route.

## Decision

**Move the order-history export to the Reports screen, and enrich it with the bill settlement: totals breakdown, the payments list, and inline proof photos.**

- **Location.** The export trigger leaves the order board entirely and lands on Reports as a **second pill** (`Ekspor pesanan`) beside the existing report-summary `Ekspor`. The board keeps zero coupling to history. ADR-0030's binding constraint — *the live board is never turned into a historical browser* — is preserved; only the button's location changes, and the range is still picked inside the export sheet.
- **Enrichment shape.** Each visit block, below its line items, gains a **per-receipt** section (split bills grouped under their receipt label):
  - **Bill totals** — subtotal, service, tax, grand total, status — from `TableSessionReceipts`.
  - **Payments list** — every tender from `TableSessionPayments`: method, amount, cashier name, time, refund flag. Cash is included with a blank proof.
- **Server.** `GET /orders/history` joins `TableSessionReceipts` + `TableSessionPayments` by `sessionId` and nests them under each visit (grouped by `receiptId`). It returns each payment's `id` and a `hasPhoto` flag — **never the photo bytes** (ADR-0025: the blob does not ride the list path).
- **Proof photos.** PDF only. During PDF build the client fetches each non-cash payment's photo from `GET /settlement/history/payments/<id>/photo` and embeds it as an **inline thumbnail** beside its payment row. Fetches run with bounded concurrency and a failed fetch is skipped gracefully (row renders text-only). CSV cannot carry binary, so it gets a **`Bukti foto` column** = `Ada` / `—`.

## Considered options

- **Move to Reports, enrich, inline proof (chosen)** — puts the export with its real audience and gating, and the inline proof keeps each photo next to the payment it attests. Cost: per-payment photo fetch over LAN during PDF build (mitigated by bounded concurrency + graceful skip); larger PDFs.
- **Keep on the order board** (rejected) — the ADR-0030 status quo, but leaves a financial export on a waiter surface and ignores the settlement data now available.
- **Server embeds photos in the history JSON as base64** (rejected) — one round-trip, but violates ADR-0025 (blobs never on the list path), bloats the JSON unboundedly, and forces the client to hold every photo in memory even for CSV.
- **Proof photos in an end appendix** (rejected for now) — smaller inline rows, but detaches each proof from its payment, weakening the audit read.

## Consequences

- `GET /orders/history` grows a join over two snapshot tables and a nested receipt/payment shape; the order-history export models and the CSV/PDF builders grow receipt + payment + proof rows.
- A large range with many non-cash payments means many photo fetches and a heavier PDF; the build shows progress and tolerates partial photo failure.
- The order board loses its only history coupling — the export trigger and its `viewReports` gate now live solely on Reports.
- ADR-0030 remains the record for *why the export is client-side and range-scoped*; this ADR overrides only *where it lives* and *what it contains*.

## Amendment — proof renders as an enlarged block, not a thumbnail

The original decision embedded each proof as a **28pt inline thumbnail** beside its payment row. A thumbnail is too small to **read the amount/digits** on the captured payment-confirmation, which is the actual audit act — confirming the proof backs the tendered amount. The thumbnail therefore failed the reason the proof rides the PDF at all.

Revised rendering (PDF only; fetch path, concurrency, and CSV `Bukti foto` column unchanged):

- **Enlarged block under the row.** The payment row stays a single text line (method · cashier · time · amount); its proof renders as a **bordered card directly beneath it**, not inline. The proof stays glued to its payment — preserving this ADR's original rejection of an end-appendix — it just grows.
- **`contain`, never `cover`.** A capped box (~140pt tall, full content-column wide) with `BoxFit.contain` so the whole capture is always shown. `cover` is forbidden: cropping can chop the very digits being verified. The cap keeps a multi-payment visit from exploding the page; an image taller than a page is the accepted edge case.
- **Caption.** A thin `Bukti · <method> · <amount>` caption re-links the block to its row, defending against a page break separating them.
- **Atomic unit.** The text row + proof card are kept together so MultiPage pushes the whole unit to the next page rather than splitting row from proof.
- **Three explicit states** — cash → text row, no proof area; non-cash + photo → the proof card; non-cash with `hasPhoto` but a **failed fetch** → a framed `Bukti tidak termuat` placeholder. A non-cash tender never renders silently proof-less, so a genuinely missing proof reads as the red flag it is rather than blending into a cash row.

Cost over the thumbnail: taller blocks and more page breaks on visits with many non-cash tenders. PDF *byte* size is unchanged — the full photo bytes were already fetched and embedded; only the render box grew.
