# ADR-0142: Per-item presets follow units and preserve existing applications

Status: Accepted and implemented.

## Context

The cashier selects a line-scoped preset, but fixed discounts currently resolve once against that line's total. A Rp5,000 preset on three Rp20,000 coffees therefore deducts only Rp5,000. The accepted meaning of “Per item” is Rp5,000 for each unit in the selected line, giving Rp15,000 off.

Applied discounts snapshot their kind and value without distinguishing a per-line amount from a per-unit amount. Recalculation also reaches paid receipts during payment corrections. Globally multiplying every stored fixed line discount by quantity would silently reinterpret earlier transactions.

## Decision

- The cashier chooses a line and a preset. The preset automatically applies to every unit in that selected line, without an individual-unit selection step or automatic selection of other lines.
- A newly applied fixed line preset discounts each unit by its fixed value, capped at the unit's price. Existing stack limits continue to prevent negative totals.
- Discounts follow the selected units when divided across receipts. Three discounted coffees split as one and two receive Rp5,000 and Rp10,000 off respectively; splitting must neither lose nor duplicate the benefit.
- Existing applied discounts retain their original calculation, including on unpaid receipts and after reopening or refunding. Newly applied presets use the per-unit rule. Existing preset definitions remain usable; compatibility belongs to each application, not to when the preset was created.
- Whole-bill and whole-receipt presets keep their current scope and calculation. Percentage presets retain their current arithmetic; their base already includes the applicable quantity.

## Consequences for implementation

New per-unit applications use existing discount records with a visit and ticket but no receipt. This ownership shape distinguishes them from legacy receipt-owned applications without rewriting old snapshots or adding another pricing column. A schema-76 index migration gives each ticket its own manual slot alongside bill presets. Older payloads without the `perUnit` marker retain legacy behavior. Snapshot values remain independent of later catalogue edits.

The shared recomputation allocates a ticket-owned preset to each receipt's units and retains the discount on unassigned units. Receipt deletion therefore cannot erase the selection. Receipt views and archived snapshots carry each payer's share; paid units prevent changing the ticket's preset until reopened.

Pending cashier previews retain the preset kind and value and recalculate for the selected quantity. The discount picker, printed selection, server settlement and offline projection use the same resolver.

Relevant implementation areas: `lib/domain/use_cases/bill_math.dart`, `lib/domain/use_cases/bill_recompute.dart`, `lib/domain/use_cases/settlement_projection.dart`, `lib/server/db/tables.dart`, `lib/server/routes/settlement_routes.dart`, `lib/ui/features/cashier/cashier_bill_screen.dart`, and `lib/ui/features/cashier/widgets/settle_pane.dart`.

## Acceptance scenarios

1. Select a Rp5,000 fixed preset on three Rp20,000 coffees: discount Rp15,000, net Rp45,000 before service and tax. Other lines are unaffected.
2. Split those coffees one plus two: discounts Rp5,000 plus Rp10,000, combined Rp15,000. Reallocation preserves the same benefit per unit without duplication.
3. Select a fixed value above the unit price: each unit reaches zero, never a negative amount. Other discount sources still obey the existing combined cap.
4. Change a pending selection from three units to two: preview and confirmed settlement both show Rp10,000 off for those two units.
5. Load a legacy Rp5,000 fixed application on three coffees: it retains the old Rp5,000 deduction on recomputation, including payment correction paths. It is never silently multiplied to Rp15,000.
6. Apply an existing catalogue preset anew: the new application uses per-unit pricing. Later catalogue edits do not alter its snapshot.
7. Verify server and offline results agree, and bill-scope, receipt-scope and percentage arithmetic remain unchanged. Run focused pricing/allocation regression tests and `flutter analyze` when implementing.

## Rejected alternative

Multiplying every fixed line discount by quantity is a smaller code change but changes historical applications and cannot safely preserve paid receipts. Preserving legacy semantics is an intentional compatibility requirement.
