# Bill discount preset visibility

## Finding

The bill screen correctly asks the preset repository for active `bill` presets. Venue Settings can author only `order` or `line`, and the preset CRUD route rejects anything except those two values. The database, settlement route, bill model, glossary, and ADR-0070 already support `bill`. This is an incomplete ADR-0070 implementation, not a bill-screen rendering defect.

## Decision ledger

| # | Question | Recommended answer | Variation / pushback point |
|---|---|---|---|
| 1 | Is `bill` a distinct preset scope? | Yes. Keep the documented scopes: `bill` = whole tab/table, `order` = one receipt, `line` = one item line. | Alias `order` to `bill`; rejected because it makes receipt-specific discounts ambiguous and contradicts ADR-0070. |
| 2 | Where must `bill` be enabled? | Add it to both the Venue Settings scope selector and the server CRUD allow-list/validation message. | UI-only; rejected because the server would still return `400 invalid`. |
| 3 | What should a new preset default to? | `bill`, because the header discount action is the common pre-receipt flow and the current complaint shows “whole order” is being read as whole bill. | Keep `order` as the default if receipt discounts are operationally more common. |
| 4 | What should the scope labels say? | EN: `Whole bill`, `One receipt`, `Per item`. ID: `Seluruh tagihan`, `Satu struk`, `Per item`. Avoid “whole order/pesanan” because the domain maps `order` to a receipt. | Keep current `Whole order / Seluruh pesanan`; cheaper, but preserves the ambiguity that caused the expectation mismatch. |
| 5 | What happens to existing `order` presets? | Preserve them as receipt presets. Owners who intended a table-wide discount edit that preset once and choose `Bill`. | Automatically migrate all `order` presets to `bill`; rejected because it silently changes valid receipt-specific pricing. |
| 6 | Is a database migration required? | No. `scope` is text, and the schema plus applied-discount tables already describe and store `bill`. | Add a constraint/schema migration; unnecessary unless the project later chooses database-level enum enforcement. |
| 7 | Should active/inactive behavior change? | No. Only active presets appear in cashier pickers; inactive remains the seasonal parking mechanism. | Show inactive presets disabled in the picker; adds noise and invites cashier confusion. |
| 8 | Should preset mutations update the local repository immediately? | Yes: after successful create/update/delete, update local state from the returned row/removal instead of depending solely on a WebSocket echo. Keep the broadcast for other devices. | Leave WebSocket-only consistency; smaller diff, but the authoring device can remain stale when its socket is disconnected. |
| 9 | Should the picker’s loading/empty-state behavior be redesigned now? | No. Fix the deterministic scope mismatch first. Revisit only if a preset still appears missing while the repository is loading or failed. | Add loading/error/retry handling now; more robust, but it is not needed to resolve the proven defect. |
| 10 | Do permissions or manager approval change? | No. Authoring remains `editSettings`; applying remains `applyDiscount` or manager step-up. | Broaden permissions; unrelated and increases money-path authority. |
| 11 | Is another ADR or glossary change needed? | No. `CONTEXT.md` and ADR-0070 already contain the accepted three-scope model. Code must catch up to them. | Revise ADR-0037 alone; misleading because ADR-0070 intentionally supersedes its two-scope decision. |
| 12 | What regression check is sufficient? | Add one focused test proving a `bill` preset is accepted by preset CRUD and returned in the catalogue, plus a UI assertion that Venue Settings offers/saves the Bill scope. Run `flutter analyze` and the focused tests. | Full settlement end-to-end suite; valuable later, but bill application is already implemented and this defect is at authoring. |

## Minimal implementation

1. Add `bill` to the server preset scope allow-list and update its validation copy.
2. Add localized `dscScopeBill`; rename the existing `order` label to receipt-specific wording.
3. Add the Bill segment to the Venue Settings editor and default new presets to `bill`.
4. Adopt successful CRUD results locally so the same device reflects changes without waiting for WebSocket delivery.
5. Add the focused regression checks above; run formatting, tests, and `flutter analyze`.

## Acceptance scenario

An owner creates an active `Whole bill / Seluruh tagihan` 10% preset in Venue Settings. Without restarting or reconnecting, a cashier opens an unpaid bill, taps its bill-level discount action, sees that preset, and can apply it. Existing receipt and line presets continue to appear only for their matching targets.
