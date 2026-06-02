# Settlement is a phase before Close, and a Bill splits into receipts, not bills

**Status:** accepted

## Context

Until now the end of a visit was a single act — [[Close (table) / Table session|Tutup meja]] — which required every ticket terminal, computed `netTotal = subtotal`, snapshotted a `TableSession`, and freed the table. It captured **no money and no payment method**, and the venue's tax/service toggles in `VenueSettings` were configured but **never applied to any total**. CONTEXT explicitly noted the guest's bill was "a separate, not-yet-built document". A cashier now needs a venue-wide screen to collect payment, support guests at one table paying with **separate receipts**, and confirm payment **manually** (there is no payment gateway).

## Decision

**End-of-visit becomes two distinct acts — Settlement then Close — and one [[Bill (tab)|Bill]] (the table's whole tab) splits into many receipts, each settled independently.**

- **Two phases.** [[Settlement (two-phase, precedes Close)|Settlement]] records [[Payment (manual confirmation)|payments]] against a Bill and may run while the table is still occupied; **Close is unchanged** (still all-terminal, lock-respecting, snapshots the session). The cashier screen (`/kasir`, gated by a new **`settleBill`** capability) lists every **payable** table — any occupied table with ≥1 sent line — and Settlement is **lock-free** (a waiter editing lines and a cashier taking money co-occur); only Close respects the [[Table lock]].
- **Bill is implicit.** No `Bills` table — the table *is* the bill; receipts carry `tableId`. A separate row would duplicate `VenueTable`'s open-at-seat / gone-at-close lifecycle for no gain (one visit = exactly one bill).
- **Split = one Bill, many Receipts.** A `Receipt` is **itemized** (owns line items via a qty-level assignment join — a `qty:3` line can split 2+1 across receipts) or **even** (carries only a share amount). Settlement is **incremental**: a receipt is paid once *its* lines are assigned, even while siblings are unassigned. A Bill is fully settled only when every line is assigned **and** every receipt paid — the gate for offering Close.
- **Tax/service finally bind, and `netTotal` is redefined.** Service applies to subtotal, then tax to (subtotal + service); each receipt computes on its own subtotal with the integer **rounding remainder pushed onto the largest receipt**. `TableSession` gains `serviceAmount`/`taxAmount`, and **`netTotal` now means the actually-settled total** (`subtotal − void + service + tax`), not the old `netTotal == subtotal`.
- **Payment is a manual attestation.** Method ∈ {tunai, kartu, qris, transfer, lainnya}, multi-tender per receipt, binary paid/unpaid, cash tendered/change informational. Recorded via the existing `Idempotency` path; emits a new `billUpdated` WS event. Post-payment corrections are a **Refund** (negative payment, manager-approved via the existing `refund` cap) plus a cashier **reopen** before Close.
- **A new money document, named apart from `Struk`.** [[Tagihan / Struk pembayaran (the money document)|Tagihan / Struk pembayaran]] reuses the two-scope printer infra (ADR-0020/0022) with a new renderer template; the no-money order-confirmation [[Struk (cetak struk meja)|Struk]] term is left untouched.

## Considered options

- **Two-phase Settle → Close (chosen)** — the only shape that supports "one guest pays and leaves early" and per-guest separate receipts without forcing the table closed on first payment. Cost: a paid-but-occupied window the floor must surface (a money badge, since status stays kitchen-driven).
- **Settle *is* Close (merge)** (rejected) — simplest, but cannot model a partially-paid or paid-yet-occupied table, and makes splitting incoherent (close is a single act).
- **Settlement as a fully independent ledger** (rejected) — maximum flexibility, but double-bookkeeping against the table lifecycle for no real benefit at one-venue scale.
- **Explicit `Bills` table** (rejected) — only justified if a table could hold concurrent bills; it can't. Would duplicate `VenueTable` lifecycle.
- **Whole-line-only or fractional split** (rejected) — whole-line can't model shared dishes; fractional invites float/rounding bugs and fiddly UI. Qty-level integer assignment is the middle path.
- **Overload `Struk` for the money document** (rejected) — `Struk` is defined as a no-money slip; reusing it would erase a deliberate distinction.

## Consequences

- **`netTotal` changes meaning.** Historical `TableSession.netTotal` rows equal their `subtotal` (tax/service never applied); rows after this feature include service+tax. Report queries reading `netTotal` as gross-of-tax must account for the discontinuity (existing reports at `reports_routes.dart` sum `subtotal` and `netTotal` — revenue figures shift once settlement is live).
- Settlement being lock-free admits a race: a line voided after its receipt was paid. Handled by the Refund + reopen rule, not by locking.
- Tables can be fully paid yet still occupied; the floor/cashier rely on a derived **outstanding** (full `openAmount` − paid) and a money badge, not on `status`.
- Close stays a separate capability/act; a cashier is not auto-granted Close or Refund. The cashier screen surfaces "Tutup meja" only as a convenience once fully settled, still calling the gated Close.
