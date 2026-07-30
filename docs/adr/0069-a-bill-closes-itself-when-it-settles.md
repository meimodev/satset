# ADR-0069 — A bill closes itself when it settles

## Status

Accepted. Supersedes ADR-0024's two-phase settlement for the **Lunas** path only;
ADR-0024's decoupling of the visit from the table, and its tak-tertagih write-off,
both stand.

## Context

ADR-0024 split the end of a visit into two independent axes and gave the cashier
**Tutup tagihan** as the money one. On the Lunas path that act does no work the
system could not do itself: it is only reachable when the bill is already fully
settled, it takes no input, and there is exactly one sensible answer. `_CloseBar`
mounts, the cashier taps it, the bill closes.

The design source has no close act at all. `due === 0` *is* done, and the settle pane
becomes a confirmation panel with print buttons.

The source is right about this one. A confirmation that can only be confirmed is not
a safety beat, it is a step — and it is a step at the busiest moment of a cashier's
shift, after the guest has paid and is standing there waiting for their slip.

## Decision

**The server closes the visit the moment it becomes fully settled** — `fullyAssigned
&& allReceiptsPaid`, the predicate ADR-0068 redefined. Snapshot rules are unchanged:
if the table is already free the visit snapshots and deletes, otherwise the snapshot
defers to table close, exactly as ADR-0024 wrote it.

**The manual close survives for the write-off only.** Tak tertagih ends a bill with
outstanding > 0, so the automatic close can never fire on that path — the two do not
overlap, and the surviving button means precisely one thing.

### Reopen is now the only undo

This is the cost, and it is real. With a confirming tap there was a beat between "the
money is in" and "this bill is finished". Auto-close removes it, so a mis-tapped final
payment closes the bill immediately.

The mitigation is placement, not process: **the settled pane carries a top-level
`Buka ulang`**, not one buried in a per-receipt sheet. Reopen is already audited and
already refuses once the visit is snapshotted, so its guarantees are unchanged — what
changes is that it must be the first thing visible on the pane a cashier lands on
after a mistake.

## Consequences

- **`Lunas` as a live state effectively disappears.** A settled-but-open bill now
  exists for the duration of a database write. The cashier's `Lunas` segment therefore
  reads closed bills out of history rather than filtering the live list — which is what
  a cashier meant by "already paid" anyway.
- **Takeaway handover needs re-checking.** `handover` snapshots and deletes a bill that
  is already closed (ADR-0026). Bills now close earlier, so the ordering it assumed —
  handover first, close later — inverts for a prepaid order. The gate is the same; only
  which axis lands first has changed.
- ADR-0024's copy rule holds: this act is never called "Tutup meja", and freeing the
  floor table stays the waiter's.
- Worth stating plainly, because it is the thing a future reader will question: **this
  removes a confirmation from the money path.** It was accepted knowingly, on the
  grounds that a confirmation with one possible answer confirms nothing.
