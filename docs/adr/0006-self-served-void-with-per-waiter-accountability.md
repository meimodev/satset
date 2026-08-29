# Self-served void with per-waiter accountability

Voiding a sent ticket no longer requires a manager PIN. Any waiter with `Capability.voidItem` can void a pre-serve ticket (`sent | held | prep | cooked | ready`) on their own authority, picking a canonical reason code from a fixed taxonomy. Voids from `served` still need manager-gated comp/refund — that's a different power, not a void.

Manager-PIN theatre was masking the real control: the server already accepted any caller bearing `voidItem`, and the client-side audit row never persisted. The new design replaces the gate with **traceability** — every void emits a server-side audit row stamped with `actorUserId` from the JWT, and the ticket itself carries `actorUserId` + `voidReasonCode` so the reports screen can surface per-waiter void rate and lost rupiah by reason. Accountability is the deterrent.

## Consequences

- `actorUserId` added to `Tickets` and `TableSessionTickets` (snapshot must preserve attribution across session close).
- Reason taxonomy collapses to server-canonical codes (`wrongOrder`, `customerChange`, `outOfStock`, `kitchenError`, `other`). Client UI labels are display-only; the code rides the wire.
- Server enforces `voidReasonCode` on `tickets/<id>/transition` when target status is `voided` — UI-only enforcement is no longer sufficient now that the gate is gone. **Amended by [ADR-0114](0114-a-void-is-a-code-and-can-be-captured-offline.md):** this originally demanded non-empty `voidReason` too, which the client satisfied by sending the reason's label. ADR-0085 stopped it sending one, and four of the five reasons began answering `400`. Free text is now required only for the code `other`.
- Existing installs: `seed.dart` backfills `voidItem` onto the waiter role on boot (same pattern as the admin-role backfill at `seed.dart:176`).
- No undo. `voided` stays terminal; reverse transitions would complicate the KDS state machine. The reason picker is the only safety net.
