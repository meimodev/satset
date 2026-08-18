# ADR-0100 — A ledger guard is only real inside a transaction

Status: accepted
Date: 2026-08-18

## Context

Three of the four one-writer modules hold an invariant expressed as a guard in
front of an insert:

- `cash.dart` — the box cannot go negative
  ([ADR-0088](0088-the-petty-cash-box-cannot-go-negative.md)), so `spendCash`
  reads `cashBalance` and refuses an amount larger than it.
- `members.dart` — a points balance cannot go negative
  ([ADR-0095](0095-points-earn-at-bill-close-and-never-expire.md)), so `spendPoints`
  reads `memberPoints` and refuses. `earnPointsForVisit` reads the visit's
  existing earn row and refuses a second one.
- `cash.dart` again — a reversal reads `reversedById` and refuses a row already
  reversed.

Every one of those balances is **derived**, not stored: it is `SUM(delta)` over
an append-only table, which is the whole reason the ledgers are trustworthy
(ADR-0088, ADR-0095). Nothing stores the number, so no `CHECK` constraint can
be written against it and no unique index can be made to stand in — the
database has no column to guard.

That leaves the guard living entirely in Dart, and until now it lived
*outside* any transaction: read the balance, `await`, then insert. Between
those two statements the event loop is free, and the embedded server serves
every tablet in the venue from one isolate. Two supervisors spending the last
of the box at the same time both read the same balance, both pass, and both
insert. The box goes negative — the one thing ADR-0088 exists to prevent.
The same shape overdraws a member's points, and double-earns a bill that gets
closed twice.

This is not a hot-contention problem. It is two tablets, not two hundred.
But the ledgers are the app's money story, and a rule that only holds when
nobody is in a hurry is not a rule.

## Decision

**A guard and the write it protects are one atomic step.** Every check-then-act
pair in the ledger writers runs inside `db.transaction`, with the balance or the
existence check re-read *inside* the transaction, not passed in from outside it.

This covers `spendCash`, `countCash` and `reverseCash` in `cash.dart`, and
`spendPoints` and `earnPointsForVisit` in `members.dart`.

`countCash` is in the set for a reason that is not overdraft: a variance
computed against a balance that moved before the insert records the wrong
finding, and the finding is the one number an opname exists to get right
([ADR-0089](0089-petty-cash-is-not-revenue.md)).

**The audit row goes inside the transaction too.** A ledger row without its
audit row is a movement nobody can explain, and the two rolling back together
is the only way to guarantee that never happens.

**The balance stays derived.** This decision buys atomicity without buying a
stored balance — the invariant `SUM(delta)` is unchanged, and remains the thing
a reader can verify by hand.

## Considered options

**Store the balance in a column with a `CHECK (balance >= 0)`.** The database
would then hold the invariant, which is where invariants belong. Rejected: it
un-derives the balance. A stored total is a second source of truth that can
disagree with the rows beneath it, and the reason the ledgers are auditable at
all is that there is nothing to disagree with. ADR-0088 and ADR-0095 both
turn on this; paying for concurrency with it is a bad trade at this scale.

**A process-wide mutex around each writer.** Simpler to reason about than a
transaction and it would work — the server is one isolate. Rejected: it is a
second locking mechanism sitting beside the one the database already provides,
correct only as long as nobody adds a second writer path, and invisible to
anyone reading the SQL.

**Leave it; the window is microseconds.** Rejected on principle rather than on
measurement. The window is small, the consequence is a wrong money number, and
the fix is six lines per writer.

## Consequences

`db.transaction` is now the shape a ledger writer takes, and a new one that
skips it is a review finding. The three writers that were already atomic by
accident — because they had no guard — are unchanged.

The hub broadcast inside `_post` now fires before the transaction commits.
Harmless in practice: the broadcast carries no balance, clients re-read, and a
rollback is a thrown exception the caller turns into an error response. Worth
knowing about if a listener is ever made to trust the event's contents.

`stock_counts.dart` — the fourth one-writer module — is not in scope here.
Its invariant is a session lifecycle, not a derived balance, and `closeCount`
already runs as one unit.
