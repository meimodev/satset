# Discount / tax stacking order: one `taxAfterDiscount` flag

[ADR-0023](0023-two-phase-settlement-and-split-bills.md) fixed the stack at **service-then-tax** (ID PB1 convention): service applies to the subtotal, then tax to `(subtotal + service)`. Inserting a [discount](0037-cashier-stage-catalog-discounts.md) opens a question venues genuinely disagree on — is tax computed on the pre-discount or post-discount amount? — and a naive "make it configurable" produces a combinatorial mess (does the discount also reduce the *service* base? does it differ per discount kind?). This ADR reduces it to **one boolean with two pipelines**.

## Decision

- **One flag: `taxAfterDiscount` on `VenueSettings`, default `true`.** Two whole pipelines, not a per-component matrix:

  ```
  taxAfterDiscount = true            (default, DPP-correct)
    base    = subtotal − discount
    service = base × svcRate         (or fixed)
    tax     = (base + service) × taxRate
    total   = base + service + tax

  taxAfterDiscount = false           (gross-then-promo accounting)
    service = subtotal × svcRate     (or fixed)
    tax     = (subtotal + service) × taxRate
    total   = subtotal + service + tax − discount
  ```

- **"Before tax" necessarily means "before service."** Service is upstream of tax, so a third mode with the discount wedged *between* them has no real-world referent. Refusing to model it is what keeps this to one boolean.
- **Default `true` because it is the DPP-correct reading** — a discount reduces the transaction value, so it reduces the taxable base. `false` exists for venues whose accounting wants promos reported against a gross figure.
- **Line discounts are always pre-tax; the flag governs order discounts only.** A line discount *is* a price change on that line — it is part of how the subtotal is derived, and taxing the undiscounted price of a line whose price changed is incoherent. Under `taxAfterDiscount = false`, only the whole-order discount is deferred to the grand total.
- **Line-then-order.** Because line discounts are folded into the subtotal, an order discount computes off the already-line-discounted subtotal. This falls out of the pipeline above rather than needing its own rule.
- **`computeBreakdown` stays the single money function.** It grows a discount argument and the flag; the cart [[Estimasi (cart estimate)|Estimasi]], settlement, and split math continue to share it. Percent math **truncates** (`~/`), matching existing service and tax rounding, and the resolved discount is **clamped so a total can never go negative** — a discount is not a refund and must not push money outward.
- **Print placement is driven by the flag, not a fixed template.** `BillStrukData` carries `taxAfterDiscount` so the Diskon row renders **above Layanan** when `true` and **below Pajak** when `false`:

  ```
  taxAfterDiscount = true          taxAfterDiscount = false
    Subtotal                         Subtotal
    Diskon Member 10%   -25.000      Layanan
    Layanan                          Pajak
    Pajak                            Diskon Member 10%   -25.000
    TOTAL                            TOTAL
  ```

  A fixed row position would print the discount where the arithmetic visibly does not work, and a guest checking the math on a 58mm slip would find the venue's receipt lying.

## Consequences

- One BOOL column on `venue_settings` (schema 34 → 35, additive, defaults to today's behaviour for a venue with no discounts).
- Every consumer of `computeBreakdown` — `menu_screen`, `review_screen`, `settlement_routes`, `tables_routes` — passes the discount and flag through. The function stays the one place rate math lives, which is the invariant [ADR-0023](0023-two-phase-settlement-and-split-bills.md) was protecting.
- `splitItemized` and `distributeFixed` are unchanged in shape: a percent order discount distributes linearly across receipts, and a fixed one fans out through the existing helper before breakdowns are computed.
- Flipping the flag on a live venue changes future totals only — settled history is snapshotted and never recomputed.
- Renderers and exporters now depend on this contract, not just the cashier screen. Changing the pipeline later means touching `bill_struk_renderer`, `bill_struk_data`, and both exporters together.
