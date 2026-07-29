# ADR-0061 — Leaving the menu discards the cart

## Status

Accepted. Covers the in-progress cart (`cartProvider`) on the way *out* of
`MenuScreen`, in all three flows that reach it. Sent tickets are untouched.
Builds on [ADR-0060](0060-the-cart-stacks-identical-lines-and-lets-you-edit-them.md).

## Context

`cartProvider` is a `family` keyed by table id, draft uuid, or takeaway visit
id. It is read in exactly two places — `MenuScreen` and `ReviewScreen`. Nothing
else in the app renders it: the table detail screen shows sent items and a
context panel, and says "Belum ada item" whether or not a cart is sitting in
memory against that table.

So backing out of the menu with items in the cart left them **invisible**. They
were not sent, not shown, and not recoverable except by walking back into the
menu for that exact table — which nothing prompted the waiter to do. On the
table and takeaway flows the key is stable, so those orphans persisted for the
life of the process. `/order/new` half-hid the problem: `startNewDraft` mints a
fresh uuid on each entry, so the stale cart stayed alive in the family but
became unreachable.

Every existing `clear()` call was post-submit. There was no discard affordance
anywhere in the app.

## Decision

**Leaving the menu is the discard.** There is no state where a cart usefully
survives the screen that owns it, so backing out clears it rather than
stranding it.

**Confirm when there is something to lose, and only then.** An empty cart pops
with no friction. A non-empty one raises a sheet first. The cart holds typed
work — modifiers, per-line notes, quantities — with no other copy, and back
sits alone on the app bar where a rushed mis-tap is cheap to make and
expensive to undo. This is the guard against data loss; it is not a
general-purpose "are you sure".

**Both back sources go through one handler.** `MenuScreen` wraps its whole
build in `PopScope(canPop: false)` and routes the Android gesture / nav-bar
back into the same `_handleBack` as the app-bar button. Wiring only the button
would have left the guard off the gesture waiters actually use — the exact
path that loses carts. `build` was split into a small `build` and
`_buildScreen` so the one `PopScope` also covers the loading and error
branches, which have no back affordance of their own but are still poppable.

**All three flows, no per-flow branch.** Table, draft and takeaway share the
handler. Takeaway had the identical bug; the draft flow's `startNewDraft` masks
it rather than fixing it, and clearing on the way out disposes the content too.

**Copy.** `Batalkan pesanan ini?` / `N item belum terkirim akan dihapus.` /
`[Batal] [Ya, batalkan]`, in `AppStrings`. The count leads the body because it
is the fact that decides the answer.

## Consequences

- Re-entering the menu for a table always starts empty. Building an order
  across two visits to the menu screen is no longer possible — it was only
  possible by accident, and invisibly.
- `startNewDraft` is now belt-and-braces for `/order/new` rather than the only
  thing keeping that flow clean. It stays: process death and other exits do not
  route through `_handleBack`.
- Review → back → menu is untouched. Review is *pushed on top of* menu, so the
  cart is still on screen after that pop; only menu's own back leaves the flow.
- Post-submit paths are unaffected. They clear the cart and then navigate, so
  by the time any back press unwinds through the menu the cart is already
  empty and the guard is silent.
- The confirm is a fourth private copy of a sheet shape that also exists in
  `staff_screen`, `zone_admin_screen` and `cashier_bill_screen`. Promoting one
  `showSatConfirm` into `core/widgets` is the right fix and is deliberately
  left for its own change — doing it here would have pulled three unrelated
  screens plus the CATALOG and `/book` obligations into a cart commit.
- `Ya, batalkan` sits next to `Batal`, and *pesanan* elsewhere in the app means
  an order the kitchen already holds. This wording was chosen knowing that;
  if it reads as voiding a sent order in practice, the title is the thing to
  change, not the behaviour.
- Covered by `patrol_test/menu_back_discard_test.dart`, which drives the real
  Android back key rather than the button, because that is the path a widget
  test cannot reach.
