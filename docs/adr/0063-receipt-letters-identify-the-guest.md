# ADR-0063 — A receipt is identified by a persisted letter, not its position

## Status

Accepted. Extends ADR-0023 (two-phase settlement and split bills), which
introduced the `Receipt` entity and its `label` field but never said what a
label is *for*.

## Context

ADR-0023 gave one [[Bill (tab)]] many receipts so guests at one table can pay
separately. It left the label free-form, and the UI filled it with the first
thing that came to hand:

- `Split per item` → `Tamu 1`, and each `Tambah struk` after it
  `Tamu ${receipts.length + 1}`.
- `Split rata` → `Bagian 1/3`, server-side.
- `Bayar penuh` → `Tagihan`.

`Tamu 1` names a slot, not a person. Standing at the till holding cash, the
cashier's actual question is *which of these is the guest in front of me* — and
nothing on the card answered it. The receipt card did already list each
receipt's owned items, but as a sub-detail under the label, below the fold of a
glance.

Three things made the naive fixes wrong:

1. **`Tamu ${length + 1}` is not even stable within a session.** Delete `Tamu 2`
   and the next `Tambah struk` mints `Tamu 2` again, now owning different food.
2. **An even share has no identity to give.** It owns no lines by construction
   (ADR-0037), so `Bagian 1/3` and `Bagian 2/3` are interchangeable. Rendering
   them as N full receipt cards implied a per-guest distinction the model does
   not have, and buried the only fact that matters — how many are still owing —
   under a screen of scroll.
3. **The label reaches paper.** `bill_struk_builder` passes it to the printed
   slip's meta line. Any scheme that re-numbers receipts can put a different
   name on the screen than on the slip already in a guest's hand.

## Decision

**A receipt's identity is a persisted capital letter in `Receipt.label`.**

- `Split per item` creates `A`; each further receipt takes the **lowest unused**
  letter, so deleting `B` leaves a gap that the next add refills. A guest's
  letter never changes under them.
- Rendering: `receiptTitle()` maps a single `A`–`Z` to `Tamu A` and passes
  everything else through — `Tagihan`, `Bagian 1/3`, and legacy `Tamu 1` all
  read as themselves. No migration, no new endpoint, no schema change.
- A letter carries a **hue**, from a six-entry ramp. The letter is the identity;
  the hue is a scan aid. Past six letters the hue repeats and the letter alone
  disambiguates, which is what a monochrome printed slip and a colour-blind
  cashier were relying on anyway.
- The same badge renders on four surfaces: the receipt card header, each unit's
  origin on the lines list (`A×2  B×1`, with an amber `?×1` for unassigned), the
  assign sheet's rows, and the `/kasir` tile's progress strip.
- **Even splits collapse into one card** of thin per-share rows: per-head
  amount, `2 dari 3 lunas`, and a row per share. A row opens that share's own
  `_ReceiptCard` in a sheet, so pay / reopen / refund / diskon / cetak keep
  exactly one implementation.
- `/settlement/payable` gains a thin `receipts: [{label, paid}]` so the list can
  draw the strip without shipping every line and payment for every open visit.

### The hue ramp

Only six semantic hues exist in `SatColors`, and `success` / `warn` / `urgent`
are spoken for by paid / unpaid / destructive. So the ramp is drawn from
`ZonePresets.colorHexes` — an existing curated set — minus its green
(`0xFF4DD487`, reads "paid") and red (`0xFFFF5C5C`, reads "urgent"), leaving
blue, violet, teal, pink, gold, amber. It is declared literally in
`receipt_visuals.dart` rather than indexed out of `ZonePresets`, so reordering
the zone picker cannot silently re-colour a bill.

The badge's filled state paints a fixed dark ink rather than a theme token:
the badge is its own surface, every ramp hue is a light pastel, and a themed
ink would flip to near-white under Gelap and vanish.

## Consequences

- Letters can have gaps (`A`, `C`). That is the point, and it reads as
  deliberate rather than as a bug.
- Bills already open when this ships keep their `Tamu 1` labels and simply
  wear no badge. They still settle, print, and close.
- Colour never carries state alone. `success` / `warn` keep sole ownership of
  Lunas / Belum bayar; the receipt hue lives only on the badge and the unpaid
  card's outline. The `/kasir` strip's filled-vs-outlined is a shape cue backed
  by the tile's existing Lunas / Sebagian chip.
- `receiptTitle` / `isReceiptLetter` / `nextReceiptLetter` live in
  `domain/models/receipt_label.dart` (plain Dart) because the printed slip and
  the server read them too; only `receiptHue` and the ink sit in
  `ui/core/design/receipt_visuals.dart`.
- `ReceiptBadge` stays cashier-local rather than joining
  `ui/core/widgets/CATALOG.md`. Receipt letters are a settlement concept, not
  app vocabulary; if another area ever shows one, it promotes then (ADR-0055).

## Alternatives rejected

**Derive the letter from list index.** One expression, no persistence — and it
re-letters every receipt after a delete, including ones whose slips are printed.

**A typed guest name.** The strongest handle, and the one a cashier would
actually recognise. Rejected for now: it needs a `PATCH` on the receipt and
keyboard work mid-rush, and the items a guest ordered already identify them
without any data entry. Reachable later — `label` is free-form and
`receiptTitle` already passes non-letters through untouched.

**New `SatColors` tokens for the ramp.** Fully theme-aware and purpose-built,
at the cost of six new tokens across nine skins for one screen.

**Leave even splits as N cards.** Honest to the entity count, dishonest about
what the entities mean, and the worst scroll on the screen.
