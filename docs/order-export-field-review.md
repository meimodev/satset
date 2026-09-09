# Orders export field review

Status: rounds 1–2 accepted; final allocation rule and scope confirmation pending.

Scope: Reports → Export → Orders, CSV and PDF. This is the closed-visit order history export, not the summary Report export.

## Existing exported fields

| Section | Existing fields | Proposed treatment |
|---|---|---|
| Report header | Period label, date range, generated time, visit count, item-line count, net | Keep the range, generation time and totals. Check the meaning of net before changing its label. |
| Visit header | Table or takeaway label, party size, visit waiter, closed time, net | Keep; add zone. Visit waiter does not identify who submitted each item. |
| Item identity | Item name, variant, modifiers | Keep names and modifiers; fold variant into the item description, as PDF already does. |
| Item operations | Sent time, course, quantity, status, void reason | Keep except course, proposed for removal. Preserve voided lines and their reasons. |
| Item money | Unit price, line total | Keep; make clear whether totals are before or after discounts. |
| Receipt | Receipt label, subtotal, discount total, service, tax, total, status | Keep settlement figures. Receipt status is currently CSV-only. |
| Payment | Time, method, cashier, amount, refund flag, proof | Keep. CSV shows proof presence; PDF includes proof images when available. |

CSV uses separate variant and void-reason columns. PDF incorporates the variant into the item description and the void reason into the status text.

Source: [order_history_exporter.dart](../lib/core/export/order_history_exporter.dart), CSV builder at line 53, PDF item table at line 223, visit block at line 270 and receipt block at line 310.

## Requested additions

| Data | Intended meaning |
|---|---|
| Item note | The special instructions attached to that Ticket line, not the visit's guest note. |
| Item orderer | The staff member who submitted that Ticket. Distinct from the visit/table waiter. |
| Zone | The order's historical zone, with no invented zone for takeaway or unavailable history. |
| Item discounts | Applied discount names and reductions; direct discounts and allocated shared discounts must remain distinguishable. |
| Ticket owner | The member who consumed the item, independently of the payer or debtor. Unassigned lines remain unassigned. |

These distinctions already exist in [CONTEXT.md](../CONTEXT.md): Orderer, Waiter, Guest note / Item note, Diskon and Pemilik tiket. No new glossary term or architectural decision has been accepted in this interview.

## Accepted decisions — round 1

1. **Staff attribution.** Show the item orderer on every line and retain the visit waiter in the visit header.
2. **Discount coverage.** Show direct item discounts plus the item's share of receipt/bill discounts, separately.
3. **Field cleanup.** Remove Course and fold Variant into Item. Retain modifiers, quantities, prices, status, void reasons and settlement details.

## Verified data availability

The history endpoint in `lib/server/routes/reports_routes.dart:944` omits the requested data from its payload; the export DTO and renderers consequently cannot show it. Closed-history snapshots already retain:

| Requested data | Existing storage |
|---|---|
| Item note | `TableSessionTickets.note`, `lib/server/db/tables.dart:850` |
| Item orderer | `TableSessionTickets.createdByUserId`, `tables.dart:868` |
| Zone | `TableSessions.zoneId`, `tables.dart:755` |
| Item consumer | `TableSessionTickets.memberId`, `tables.dart:843` |
| Applied discounts | `TableSessionDiscounts`, `tables.dart:1177`: receipt/ticket links, preset, name, kind, value, amount, source, author, approver and time |

Historical availability still depends on when a record was created. Staff, zone and member identities are stored as IDs; names need directory lookup and missing/deleted fallbacks. Shared discount amounts per item require calculation rather than reading an existing per-item amount column.

Current item Total is `price × quantity`, before discounts, including voided rows. Visit/report Net is `settledTotal`, after discounts and including service and tax; it does not subtract visit expenses. These are different bases and must be labelled clearly.

The export selects closed visits by closing time. Its fetcher currently strips waiter/server, zone and category screen filters (`lib/data/repositories/order_history_repository.dart:249`). Adding a zone field alone does not change that filtering behavior.

Ready/served times, visit subtotal/void amount, receipt mode and internal IDs exist in the DTO but are not currently visible export columns. They are not candidates for visual cleanup.

## Accepted decisions — round 2

4. **Money labels and detail.** Show Before discounts, Direct discount, Shared discount, and After discounts (before tax/service) per item; rename visit/report Net to Settled total.
5. **Historical names.** Use current available names with honest missing/deleted fallbacks, distinguishing an unassigned consumer from unavailable historical identity. Never infer consumer from payer. No new name snapshots.
6. **Member identity.** Show member name only; omit member code and phone.

## Final proposed output

Visit headers retain table/takeaway label, party size, visit waiter and closing time, add zone, and label the financial total Settled total.

Item data: sent time; item description including variant; modifiers; item note; orderer; member name; quantity; unit price; before-discount amount; applied discount descriptions; effective direct-discount amount; allocated shared-discount amount; after-discount amount before tax/service; status; void reason. PDF may render descriptive data under the item instead of making every value a narrow column.

Remove Course and the separate Variant column. Retain receipt and payment details, including proof handling. Keep existing date-window and closed-visit scope.

## Final proposed allocation rule — needs confirmation

Use frozen historical receipt totals and discount records. Do not recompute past settlement from current prices, presets, tax or service settings.

Show discount names/source descriptions separately from the effective direct/shared totals. A 10% member offer plus a 100% promo can promise 110%, but only the item's price is actually deducted. Do not label each stored offer amount as an independently deducted amount.

Allocate shared discounts proportionally using recorded eligible item values and receipt quantities, with the existing integer `distributeFixed` helper so rounding preserves totals. Label these amounts as allocated shares. For histories that cannot support trustworthy item allocation, show the discount at receipt/visit level as unallocated and mark the affected item amounts unavailable; do not fabricate a precise split or quietly use zero.

Amount receipts have no item quantities, and older histories may lack or contain inconsistent receipt assignments. These require explicit handling; the snapshot is not a complete per-item financial ledger. Old rows may also lack discount data/source distinctions introduced later.

Implementation references: `lib/domain/use_cases/bill_math.dart:145` (`distributeFixed`) supplies proportional rounding. `bill_recompute.dart:213` and `:255` explain aggregate discount clamping. `lib/server/members.dart:405` describes historical quantity attribution, but member reports do not supply a reusable item discount allocator.

## Verification for implementation

Check both CSV and PDF output and history payloads with distinct per-item authors/members, item notes, zones, direct and shared discounts, capped stacks, split quantities, voids and unavailable legacy allocation. Money shares must reconcile to stored totals. Run the relevant export/history tests and `flutter analyze`.

Application code has not been changed. The requested grilling workflow resolves these choices before implementation.
