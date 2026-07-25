# Stock deducts at send: ledger + balance, restock by lifecycle status

Status: accepted

Given ingredient-level inventory (ADR-0037), *when* stock moves and *what remembers it* are the two decisions that are expensive to change later, because both are baked into history the moment the feature ships. This ADR fixes them: stock deducts **when a line is sent to the kitchen**, every change appends a **self-contained [[Mutasi stok (Stock movement)|movement]] row** *and* updates a denormalised balance in the same transaction, and a [[Void (item)|void]] returns stock **only if the kitchen had not started the line**.

## Decision

1. **Deduct at send.** The ticket lifecycle is `sent → prep → cooked → ready → served`. Send is the one point that is already atomic and server-side (the idempotency-keyed transaction in `lib/server/routes/tickets_routes.dart`), and the last point at which refusing a line is still cheap. By `cooked` the ingredients are gone, so an "insufficient stock" answer has nothing left to prevent. Send is also the only point at which two waiters racing for the last portion can be resolved consistently.

2. **Ledger *and* denormalised balance.** Every change writes a `StockMovement` row and updates `Bahan.stockOnHand` inside one transaction. Six reasons, one uniform shape: `sale` (negative, ticket-linked), `voidReturn` (positive, ticket-linked), `waste` (negative), `receive` (positive), `adjust` (either sign, opname correction, reason text required), `produce` (both signs, batch-linked).

3. **Movements are self-contained.** Each row carries bahan, signed delta in milli-base units, reason, acting user, timestamp, a **nullable** `ticketId`, and a frozen `sourceLabel` (item + variant as ordered). Reads never join back to tickets. This mirrors the principle already in [[Modifier snapshot (on a sent line)]] — store the snapshot, not the reference.

4. **Void restocks only from `sent`.** A line voided while still `sent` returns its stock (`voidReturn`); voided from `prep`, `cooked`, or `ready` it is recorded as `waste`. The test is the line's **lifecycle status**, not its void reason code.

5. **Partial rejection with an override valve.** When stock cannot cover a line at send, only the **offending lines** are rejected — the rest of the batch is accepted, and the response names the bahan that ran out. A holder of `overrideStock` may send anyway; the movement is **still written**, so the balance goes negative deliberately.

6. **No pruning.** ~300 lines/day × ~4 bahan ≈ 1,200 rows/day, under half a million a year — SQLite does not notice, and stock history is the thing an owner looks backwards at.

7. **Variance is anchored to opname, not to the report's date range.** Opname is entered as an **absolute count** ("beras: 7.4 kg") and the system writes the difference as an `adjust` movement — so the `adjust` delta *is* the variance between what recipes said should be there and what was actually counted. A variance figure over an arbitrary range that starts and ends mid-count is meaningless.

## Considered options

- **Deduct at cooked / served / bill close.** Physically truer, and useless: by `cooked` the ingredient is already consumed, so a shortfall is discovered too late to act on. Deducting at bill close would leave stock motionless all service and break auto-habis entirely.
- **Always restock on void.** One branch. Rejected: a dish cooked and binned gets counted back into stock, so the venue sells food it does not have — the failure this whole feature exists to prevent.
- **Never restock on void.** Also one branch. Rejected: a line voided five seconds after send is charged as waste, understating stock and overstating loss.
- **Restock by void *reason code*** (`customerChange`/`wrongOrder` → return, `kitchenError` → waste). Rejected: it asks the waiter's stated motivation to predict a kitchen fact. A `customerChange` on a plated dish would wrongly restock. Status is a kitchen fact already on the ticket and requires no honesty. **Known ceiling:** a kitchen that leaves everything at `sent` until pickup makes every void look untouched — if that becomes the norm, falling back to reason codes is the escape hatch.
- **Balance only, no ledger.** The smallest possible diff. Rejected: when the cook insists there is 5 kg of beras and the app says 2, nothing on the device can say why — no way to separate theft from a bad recipe from a missed delivery. An untrustworthy number is worse than no number, because staff stop believing the habis flags and route around them.
- **Ledger only, balance as `SUM(delta)`.** Fully auditable. Rejected: every menu render and habis check becomes an aggregate over a growing table.
- **Reject the whole submit on shortfall.** Rejected: one out-of-stock side dish would kill a twelve-item order the waiter must re-key — punishing the venue for the app's bad data. Submit already creates one ticket per cart line, so partial rejection is the natural grain.
- **Allow negative silently, or block hard with no override.** Silent negatives make habis flags noise and the feature dies. A hard block with no valve reproduces the classic week-two inventory rollout death: counts drift, everything reads zero, staff cannot sell, feature is abandoned. The override keeps selling possible while making the drift *visible* — a negative bahan means exactly one thing: your counts are wrong, go do an opname.

## Consequences

- Deduction rides the **existing** idempotency-keyed submit transaction, so a retried submit cannot double-deduct.
- Every sale changes stock, but derived habis flags are broadcast **only when a flag flips** (ADR-0037) — otherwise the LAN would flood mid-service.
- `overrideStock` defaults off for existing roles, which would close the valve at the exact upgrade where it is most needed; migration therefore backfills it from `markSoldOut`.
- Movements survive the visit that caused them. Live ticket rows are deleted at [[Bill close (Tutup tagihan)|bill close]], so `ticketId` dangles by design and readers must rely on `sourceLabel`.
- A negative `stockOnHand` is a legitimate, meaningful state — reports and UI must render it as a signal rather than clamping it to zero.
