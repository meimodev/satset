# Receipt preview

Status: implemented in the `codex/receipt-preview` worktree following confirmation of shared understanding.

## Agreed behavior

- Every guest order slip, bill, payment receipt, and reprint requires a preview and explicit Print confirmation.
- Include the table-detail order slip and all other entry points for these documents.
- Use the flow: choose printer, preview, confirm Print.
- Match the printed document's content and the selected printer's paper width.
- Cancelling the preview sends nothing to the printer.
- QR labels, bulk QR printing, and printer test pages are outside this change.
- The preview is read-only. Corrections happen on the originating order or billing screen.
- If the source order or bill changes while the preview is open, refresh the preview and require confirmation again before printing.
- Cancelling or failing to print affects printing only: recorded payments remain intact and table status stays unchanged.

- After a failed print, keep the preview open with an explicit Retry button. Remind the user to check whether paper printed before retrying; never retry automatically.
- Allow offline printing from locally available data to a reachable local printer, with an offline notice. Refresh and require confirmation again when newer data becomes available.

## Acceptance checks

- Every guest-document entry point, including table detail, order-sent, takeaway, cashier, selection slips, debt-payment slips, and reprints, reaches printer selection followed by a read-only preview.
- Dismissing the preview sends no print job, reverses no recorded payment, and changes no table status.
- The confirmed document matches the preview's content and 58 mm print width for both shared and device printers.
- A changed source document requires an updated preview and a new confirmation; a shared printer must not silently substitute newer content after confirmation.
- Failed attempts retain the preview and allow only an explicit retry, with the duplicate-print reminder.
- Offline local printing displays the notice and uses locally available data; newly available updates require review again.
- QR and test printing retain their existing behavior.

## Existing behavior to account for

- Both receipt renderers use 58 mm paper; printer models have no width setting. Matching the existing print width therefore means 58 mm.
- Shared-printer paths currently rebuild documents from IDs on the main device, while device-printer paths can render captured document data. Freshness and preview matching must cover both paths.
- Debt collection offers printing after recording payment.
- The table finish dialog's print action leaves the table live; closing is a separate action.
- Print failures currently dismiss the picker and display an error.

## Implementation

- One preview captures the existing receipt renderers' commands for both order slips and money documents, including logos, QR codes, notes, and payment details.
- Printer selection precedes preview; confirmation re-reads the source and compares a render with a stable timestamp. Changes require another confirmation.
- Shared printers receive the confirmed bytes through an authenticated, size-limited host relay using only registered, enabled receipt printers. The host does not substitute a freshly rendered document.
- Offline fallbacks are disclosed, including refresh failures that occur before the connection indicator detects the outage. Explicit host rejection prevents printing a cached bill.
- Failed sends retain the preview and require an explicit retry with a duplicate-print reminder. No printing action reverses payment or closes a table.

## Validation

- Flutter static analysis: zero issues.
- Rendering parity, timestamp, selection-slip, preview confirmation/cancellation/retry, shared-printer relay, UI convention, and offline settlement regression checks pass.
- Physical printer output has not been tested with hardware.

## Domain language

Use the existing distinctions in `CONTEXT.md`: an order slip has no prices;
a bill requests payment; a payment receipt records payment. Receipt preview
covers all three without changing their document names.
