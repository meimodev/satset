# Per-item automatic debtor selection

Status: implemented and verified.
Date: 2026-09-08

## Observed behavior

The Per item settlement pane finds a shared Ticket owner and displays a
suggestion. It does not assign the payment debtor. The payment button requires
the separate debtor selection, which also supplies the member's credit
headroom and the member ID submitted with payment. Selecting the same person
in the picker therefore enables payment.

This follows ADR-0126's suggestion-only decision, but conflicts with the
expected automatic selection workflow.

## Agreed behavior

- For Per item + Piutang, automatically assign the shared member when every
  selected item belongs to that member. A second picker selection is unnecessary.
- The ordinary payment checks must still pass before Pay becomes available.
- The cashier can choose a different debtor through Penanggung utang.

- Automatic assignment follows item-selection changes and clears for mixed
  owners, unowned items, or an empty selection.
- A deliberate manual debtor choice survives item-selection changes within the
  current payment. Switching settlement mode or visit, completing the payment
  attempt, or detaching resets it.

The user approved implementation on 2026-09-08 with these recommended rules.

## Implementation and verification

The pane resolves the shared member by ID and uses that member consistently
for the displayed name, remaining credit, payment validation, and submitted
payment member ID. Outdated lookup responses are ignored after the selection
changes. A missing member or failed lookup leaves payment blocked. The debtor
and payment method are captured at confirmation before asynchronous receipt
creation can rebuild the pane.

Verification completed:

- Eight settlement-pane widget tests cover paying without opening the picker,
  refreshed lookup for the next payment, insufficient credit, lookup failure,
  changing selected owners, ambiguous ownership, manual override, stale lookup
  responses, mode changes, and debtor preservation during receipt creation.
- All 20 tests passed across `settle_pane_automatic_debtor_test.dart`,
  `piutang_picker_gate_test.dart`, `per_item_payment_methods_test.dart`, and
  `member_lookup_sheet_test.dart`.
- `flutter analyze`: zero issues.

ADR-0126 and the Payment glossary now document this behavior. Automatic UI assignment
still submits an explicit debtor ID; it does not add a server-side owner fallback.

## Android emulator verification

Verified on the Medium Tablet emulator (Android API 35) with the debug APK.
The QA order on table D2 contains one Air Mineral (Rp15,000), labelled
`QA_auto_debtor`, owned by Adi Nugroho.

- Per item + Piutang automatically populated Adi Nugroho and Rp500,000 remaining
  credit, enabling payment without opening Penanggung utang.
- Deselecting the item cleared the automatic debtor and disabled payment;
  reselecting restored the member and enabled payment.
- Submitting payment succeeded, and the receipt showed Piutang / Lunas.
- Reopening that QA receipt returned it to unpaid and reversed the test payment.
  Removing the unpaid receipt to release its item allocation remains pending:
  the emulator returned to the login screen before cleanup finished.
