# Move table is a whole-session transfer, attributed to the final table

**Status:** accepted

## Context

A waiter needs to move a seated party to a different physical table (guest request, a wobbly table, a better spot). Tickets bind to a table by `tableId` only — they carry no table-label snapshot — so the KDS, Pesanan board, and reports all resolve a ticket's table live. That makes "move" cheap to express (re-point `tableId`) but raises a reporting question: a [[TableSession]] is only snapshotted at **close**, so where does a visit that lived on two tables get recorded?

## Decision

**A move is an atomic whole-session transfer onto an empty table, and the resulting visit is recorded as one session attributed to the final (target) table.**

- Single transactional endpoint `POST /tables/:srcId/move` (`{targetId, actorId}`), gated by `Capability.takeOrder`. In one DB transaction: guard `source != available` and `target == available`; `UPDATE tickets SET tableId=target WHERE tableId=source`; copy session fields (status, pax, openedAt, guestName, guestNotes, reservationId, readyCount, openAmount, lastActorId) onto the target; wipe the source back to `available` and clear its locks; set the target lock to the mover. Broadcast `tableUpdated` for **both** tables.
- **Target must be empty** (`available` + `active`). A move is never a merge. Cross-zone targets are allowed; a target with capacity below the moved pax is allowed with a soft client warning; a non-`available` target is `409`, and a source locked by a different active waiter is `409 table_locked`.
- **No new session at move time.** The `TableSession` snapshot still happens only at close, recording the target table's id/label with the original `openedAt` — so duration and subtotal span the whole visit, and the source table gets no session for this party.
- Each move writes an `AuditType.tableMoved` entry, the only durable record that the visit changed tables.

## Considered options

- **Whole-session move, final-table attribution (chosen)** — no schema change, sessions stay a single clean bill, KDS/orders follow for free via `tableId`. Cost: per-table reports under-count the source table (a party that started at 7 and closed at A2 counts entirely to A2); recoverable only via the audit log.
- **Add `movedFrom` to TableSessions** (rejected for now) — preserves "this visit started at table 7" in reports at the cost of a migration and a column used by one edge action. Can be added later if per-table accuracy is demanded.
- **Split into two sessions at move time** (rejected) — close-snapshot the source portion, start fresh on target. Keeps per-table reports precise but fragments one bill into two rows with awkwardly split duration/subtotal, and complicates the close gate.
- **Client orchestration via existing endpoints** (rejected) — seat target + repoint + close source in sequence. Non-atomic; a mid-sequence failure splits the session across two tables.

## Consequences

- Per-table sales/cover reports attribute a moved visit wholly to the final table; reconciling "where did this party actually sit" requires the audit log. Accepted as the simple default (see rejected `movedFrom` option if this becomes a real reporting need).
- KDS batch identity `(table, sentAt)` shifts to the target on move — the cook sees the order under the new table label, which is the intent.
- The mover is auto-navigated source → target detail holding the lock, so service continues without a read-only flash.
