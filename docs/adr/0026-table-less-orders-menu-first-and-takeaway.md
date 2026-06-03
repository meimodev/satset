# Table-less orders: menu-first dine-in and takeaway visits

**Status:** accepted — extends [0024](0024-visit-decoupled-from-table-and-bill-close.md) (visit decoupled from table)

## Context

Order-taking is **table-first**: the flow is keyed on `/table/:id`, the cart is scoped per `tableId` (`cartProvider.family`), `ensureVisit` requires a `tableId`, and `POST /orders` mutates the table row (`status = pending`, `openedAt`). Two needs surfaced:

1. **Menu-first dine-in** — let a waiter build the cart *first* and assign a table last (an additive complement to the table-first flow, not a replacement).
2. **Takeaway** — orders that **never occupy a table**.

ADR-0024 already decoupled the bill/tickets from the table (re-keyed onto `visitId`) and introduced **detached** visits, so the settlement/cashier stack is table-agnostic (`/settlement/payable` iterates visits; bills carry a frozen `tableLabel`/`guestName`). But order **creation**, **KDS line labeling**, and the **end-of-visit lifecycle** are still table-bound. Two latent constraints block table-less orders: `POST /orders` fails / no-ops without a table row, and the KDS/Pesanan board resolve a line's label via `tableId → tablesProvider` (a table-less ticket is **silently dropped** from the Pesanan board and shows a **raw id** on the kitchen screen).

## Decision

**Add a table-less draft-order front end; bind it at commit to either a table (dine-in) or a takeaway Visit. Takeaway is a `Visit` with no table whose end-of-visit reuses ADR-0024's two-axis model, with handover replacing table-close.**

- **Pesanan baru (table-less draft).** A new Floor entry opens the menu with no table. The cart stays **client-local** — no `Visit`, no tickets, invisible to other devices — until commit. Two terminal bindings; the table-first flow is untouched.

- **Dine-in commit** reuses `POST /tables/:id/seat` (an `available` + `active` table only) + `POST /orders`. **No new server entity** for dine-in.

- **Takeaway = `Visit.kind == takeaway`.** No table row/tile; `tableLabel` = guest name + a **daily running number** (`"Bawa pulang #7"`); `guestName` required (its only handle); `pax = 0`. New nullable `kind` on **`Visits`** and **`TableSessions`** (default `dineIn`).

- **Takeaway lifecycle = ADR-0024 two-axis, handover ≙ table-close.** `tableFreedAt` is **null at creation** and is stamped by an explicit **handover ("Serahkan")** act — gated by `takeOrder` (waiter *or* cashier), reusing the **all-tickets-terminal** gate (can't hand over food still cooking). Bill-close is unchanged. The `TableSession` snapshot fires at the **second** axis, exactly like dine-in (pay-upfront → later handover snapshots; food-first → handover, bill stays on the cashier flagged, later pay snapshots).

- **New server surface:** a takeaway-create path (mint a `kind=takeaway` visit, insert tickets, **skip** the table mutation, idempotent like `/orders`) and a visit-scoped **handover** endpoint. KDS / orders board / Pesanan resolve a line's label via the **visit** (`visitId → tableLabel/guestName`) with a table fallback — which also fixes the table-less-ticket drop.

- **Takeaway home:** a Floor **"Bawa pulang" strip** (mirrors the Reservasi strip) + a **visit-keyed takeaway detail** (add items before handover, Serahkan, print). The cashier auto-lists it (`kind` flag, copy distinct from a walkout). Reports split takeaway vs dine-in; takeaway is excluded from per-cover / turn-time / occupancy metrics but counts in total sales, menu classification, void/comp, and non-cash-proof reports. Takeaway's printout is the visit-scoped money doc (Tagihan / Struk pembayaran); a no-money order slip is deferred.

## Considered options

- **Two-axis takeaway, handover ≙ table-close (chosen)** — the only model that lets a takeaway be **paid upfront** without the snapshot deleting still-cooking KDS tickets. Cost: a handover act + endpoint.
- **Born-detached visit, snapshot at bill-close** (rejected) — simplest, but `snapshotVisitAndDelete` on pay would hard-delete the live tickets of a paid-upfront order while the kitchen is still cooking it.
- **Pseudo "Bawa pulang" table** (rejected) — a table holds exactly one attached visit, so concurrent takeaways collide.
- **Separate takeaway entity** (rejected) — duplicates the entire bill/receipt/payment/snapshot stack, which is already visit-keyed (ADR-0024) and works table-agnostically.
- **Server-persisted draft before binding** (rejected) — a `Visit` needs a table or a takeaway binding; a table-less, takeaway-less draft has no honest identity. The cart stays client-local until commit.
- **Menu-first as a replacement for table-first** (rejected) — explicitly additive; the table-first flow stays.

## Consequences

- Schema migration adds `Visits.kind`, `TableSessions.kind`, and a takeaway running-number source; default `dineIn` leaves existing rows untouched.
- KDS / orders / Pesanan label resolution moves from a `tableId → table` lookup to the visit — fixing the latent drop of table-less tickets on the Pesanan board.
- New UI states: an active takeaway (no table tile — lives on the Floor strip) and a **handed-over-but-unpaid** takeaway on the cashier (distinct copy from a detached walkout).
- The dine-in menu-first path adds **no** server surface (reuses seat + orders); only takeaway adds endpoints (create + handover).
- The order-confirmation struk stays table-scoped; takeaway relies on the visit-scoped money doc until/unless a visit-scoped order slip is added.
