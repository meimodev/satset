# ADR-0064 — The bill settles in an overlay, not a page

## Status

Accepted. Applies ADR-0048's two-containers-one-body shape to the cashier's
money surface, and retires a workaround ADR-0061 had already made unnecessary.

Serves `lib/ui/features/cashier/cashier_bill_screen.dart`.

## Context

The bill opened as a full page pushed onto the **root** navigator, with this
comment on the call site:

```dart
// Root navigator: the bill is a full page with its own AppBar and a
// bottom CTA. Pushed on the shell's navigator instead, the floating
// phone tab bar floats *over* it and swallows "Tutup tagihan".
```

That reasoning is sound and it is also obsolete. ADR-0061 moved every overlay
onto the root navigator by construction, so `showSatSheet` and `showSatDrawer`
clear the floating tab bar for the same reason the manual push did. The page
shape was buying nothing the overlay helpers do not already give.

What it cost was the cashier's place. Settling is done *against* the payable
list — which table, how much is outstanding, who is next. A full page replaces
that list; on a tablet, where the list is wide enough to keep reading, it
replaces it for no reason at all. The booking book had already answered this
(ADR-0048): a right-edge drawer on tablet, a tall bottom sheet on a phone,
one content widget behind both.

The page also carried a **Riwayat** shortcut in its `AppBar` — a per-table
past-bills screen, pushed on top of the bill. Stacked under a drawer that is
itself an overlay, a third full page is disorienting, and it duplicated a
surface that already exists: the Kasir **Riwayat** tab lists every closed bill
venue-wide and filters by table chip. CONTEXT.md already called per-table "a
filter, not a separate view" while shipping both.

## Decision

**The bill is an overlay.** `openCashierBill(context, {visitId})` is the one
entry point. It reads `context.layout.useTabletShell` itself — its only caller
does not otherwise need the flag — and picks:

- tablet: `showSatDrawer`, 560px, full height, left border. Wider than the
  booking book's measured 520 because the receipt cards carry a seven-button
  action `Wrap` that reflows to three rows below that.
- phone: `showSatSheet`, `heightFactor: 0.92`. A 560px side panel on a handset
  is the whole screen with extra steps.

`CashierBillScreen` becomes `CashierBillView` — content only, no `Scaffold`,
no `AppBar`. `SatSheetHeader` carries the title and the close button; the
`_CloseBar` stays pinned at the bottom of the column and drops its own
`MediaQuery` bottom inset, since both containers wrap the body in a `SafeArea`.

**Errors go inline, not into a `SnackBar`.** With no `Scaffold` of its own, a
`ScaffoldMessenger.of(context)` call resolves to the root one and renders the
message in the root `Scaffold` — *underneath* the modal barrier, behind a
sheet that covers 92% of the screen. On the money path an error must not be
something you dismiss the bill to read, so `_run` and `_closeBill` set a
`_error` string that renders as a dismissible warn line under the header.

**The per-table Riwayat screen is deleted**, along with its `AppBar` action,
the now-unused `tableId` parameter, and `pastBillsProvider` (its only
consumer). Per-table history is the venue-wide list with a table chip
selected. The server route keeps its optional `tableId`.

**Nested overlays stay global.** The assign, money, discount and printer
sheets and the confirm dialogs are already root-navigator modals and keep
rising from the bottom of the full screen, including on tablet where the bill
itself is a right-edge panel. Re-siting them inside the drawer needs a nested
`Navigator`; the cost is cosmetic disjointedness, and that is the cheaper
side.

**The surface stays dismissible.** Every action in the bill POSTs immediately
— there is no uncommitted local state — so tap-away and drag-to-dismiss lose
nothing.

## Consequences

- On tablet the cashier reads the bill against the list it came from. On phone
  the change is close to invisible: a sheet at 92% where a page used to be.
- The write-off dialog, the split-count prompt and the discount sheet now open
  as a third layer on a phone (sheet over sheet over list). Material handles
  the stacking; the depth is real but each layer is dismissible.
- `_CloseBar`'s bottom padding is now wrong if the view is ever mounted
  outside `openCashierBill`. It has one caller and that is the point of having
  one.
- The file is still named `cashier_bill_screen.dart` and no longer contains a
  screen. Renaming it is a pure-noise diff; it can ride along with the next
  real change to the file.
