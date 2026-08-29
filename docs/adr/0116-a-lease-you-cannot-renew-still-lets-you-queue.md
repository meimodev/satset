# ADR-0116 — A lease you cannot renew still lets you queue

Status: accepted
Date: 2026-08-29

Amends [ADR-0001](0001-table-locking-and-seat-semantics.md), supersedes one
consequence bullet of [ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md),
and completes [ADR-0114](0114-a-void-is-a-code-and-can-be-captured-offline.md).

## Context

Two ADRs describe offline writes on a dine-in table, and a third quietly made
both unreachable.

ADR-0090 gives `submitOrder` and `seat` an [[Antrean kirim]] and spends a whole
consequence bullet on what happens to *orders queued behind a table seated
offline*. ADR-0114 gives a [[Void (item)]] the same queue, for the stated reason
that "the guest changes their mind in exactly the place the signal does not
reach". Both were built, tested and shipped.

Neither could be reached from the [[Table (meja)|table]] detail screen, which is
the only dine-in door to both. That screen collapsed three different situations
into one boolean:

```dart
final readOnly = lockedByOther || (!_ownsLock && !_acquiring);
```

The [[Table lock]] is acquired over HTTP. A handset that cannot reach the host
cannot acquire the lease either — `_acquireLock`'s `catch` clears `_acquiring`,
`_ownsLock` stays false, and the screen padlocks itself. So the one condition
the queue exists for was the exact condition that hid it: the FAB read
**Hanya lihat**, the line cards stopped taking taps, and a waiter standing in a
dead corner with a guest cancelling a dish had no way to say so. ADR-0114's
scenario, refused by a lock the host was not even asserting.

ADR-0090's "No lock theatre" bullet is what licensed this, and it is right about
the thing it was aimed at — a terputus device must not *claim* a lease. It went
one step further than it needed to and treated "cannot hold the lease" as
"cannot write", which is a different sentence.

## Decision

### Terputus-without-a-lease is a third state, not a locked table

The screen distinguishes:

- **Locked out** — someone else holds the lease, or we are online and simply
  have not got it. Blocks everything, exactly as before.
- **Terputus, nobody else holding** — order and void stay open; everything else
  waits.
- **Held** — the ordinary case.

The lease itself is untouched: nothing is faked, nothing is claimed, no
heartbeat is sent, and the host arbitrates on drain as it always did. What
changes is only what the *client* refuses to offer while it cannot ask.

### Exactly the two acts with a queue behind them, and no others

`submitOrder` and `voidTicket` are the only `SendIntentKind` arms a table detail
can produce, so they are the only two the screen unlocks. Seating stays where it
was — a [[Kosong|kosong]] table holds no lock in the first place (ADR-0001), so
it never had this problem.

Everything else on the screen — fire a course, mark served, close the table,
edit the guest count — stays disabled while terputus. Not because a lock says
so, but because none of them has an intent: enabling them would invent an
optimistic local state that no queue will ever reconcile. The rule is
**a control is offered offline iff the [[Antrean kirim]] will accept what it
produces**, which is also why the signal read is `wsConnStateProvider` — the
same one `submitOrder` and the void path consult when deciding to enqueue.
Deliberately *not* the lock request's `catch`: that swallows a capability denial
into the same branch as a dead socket, and would offer the FAB to a waiter the
host had just refused.

### The padlock keeps one meaning

The lock glyph on the primary action means "someone else has this table", never
"the network is down". The two states now render differently — the offline one
keeps the `+` and adds a note saying which half of the screen is still live —
because an enabled button beside a dead socket reads as a bug unless something
says otherwise, and a padlock that means two things is the ambiguous state
ADR-0090's bullet was itself trying to prevent.

The line card gains the same split: `readOnly` still hides **Tandai disajikan**
(nothing queues a serve), while the tap that opens the action sheet survives,
because the sheet behind it can queue a void. Callers with no lease to lose —
[[Bawa pulang|takeaway]] (ADR-0026) — pass nothing and follow `readOnly`, as
they always did.

### The badge has to be honest, so the socket pings

Keying on `wsConnStateProvider` only works if that state is true. A dead Wi-Fi
does not close a TCP socket — the interface disappears with no FIN and no RST —
so before this the client reported LIVE for minutes after walking out of range,
which device testing caught immediately: the padlock came back, and the whole
decision above went with it. The WebSocket now carries a 5s keepalive ping, so a
drop surfaces in seconds.

That is a fix to ADR-0090's signal, not just to this screen. The same stale
`open` is what `submitOrder` reads to decide it must enqueue rather than spend
an 8s timeout on a POST that cannot land.

### A lease refused for want of a host is re-asked when the host returns

The screen watches the socket as well as the table row: on `open`, with no lease
and nobody else holding one, it schedules the same auto-acquire the release path
uses. Without it the waiter stays lease-less — and, once the socket is back,
*locked out* rather than offline — until they back out of the table and come in
again.

### The drained board re-pulls, and the guard that stopped it coalesces

ADR-0090 has the drain re-pull the tickets after a replay, because "the
repositories' own `connected` resync already ran — before these orders existed".
It did not. Both the repository resync and the drain hang off the same
`connected` event, so the drain's `resyncNow()` always arrived while the
reconnect GET was still in the air, and `_resync`'s stampede guard **dropped**
it. That GET had left before the replayed void and the replayed order landed,
so its response then clobbered the WS deltas that had already applied them: the
tablet showed the pre-drain world, while a second device showed the truth.

The guard now coalesces instead of dropping — a resync asked for mid-flight
re-runs once the current pass finishes — and its `catch` moved inside the loop,
so a pass that failed still honours the re-run queued behind it. The same
change is in `TablesRepository`, and the drain re-pulls it too: a replayed seat
is a table fact, and a replayed order moves the tab.

### The sheet obeys the same rule as the screen

`LineItemActionSheet` hides fire, edit, serve and unserve while terputus and
keeps the void. Offering a serve there while the card behind it hides its own
serve button is the same control by another route, and it has nothing to queue.

## Consequences

- ADR-0090's consequence bullet "**No lock theatre**" is superseded. A terputus
  device still does not hold or fake a lease; it may now still write through the
  queue. The unobservable-lease ban stands — this decision adds no lease.
- ADR-0090's "a refused seat refuses the orders behind it" bullet becomes
  reachable for the first time. It was written against a flow the UI did not
  permit.
- Two devices composing orders for the same table while both are terputus is now
  possible. It always was in principle — the lease is advisory, and its TTL is
  7s — and the host resolves it the same way: both drains land, both sets of
  lines join the same visit. The lock's job is to stop two waiters *editing the
  same live screen*, not to serialise the queue.
- The waiter is told what is queued and what is waiting, in one line, only while
  the state is active. Nothing else on the screen changes appearance offline.
