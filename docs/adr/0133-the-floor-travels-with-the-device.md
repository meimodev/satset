# The floor travels with the device

**Status:** Accepted — 2026-09-04 — **extends** [0128](0128-a-client-caches-the-venue-settings-whole.md).

A client-mode device now keeps a **[[Salinan lantai]]** — its own copy of the
zones, tables, acknowledged [[Ticket]] lines and menu snapshot — written as it
watches them change and painted before the first frame of the next cold boot.

## Context

ADR-0090 gave a [[Terputus (client disconnected)|terputus]] handset somewhere to
put its writes, and ADR-0123 gave a dark till somewhere to put its money. Both
solved *sending*. Neither noticed that the thing a write aims at was never kept.

`TablesRepository`, `ZonesRepository`, `TicketsRepository` and `MenuRepository`
are in-memory `StateNotifier`s over `GET /tables`, `/zones`, `/tickets` and
`/menu`. Nothing persists. That is invisible most of the time, because they live
as long as the app: a handset that loses its host *mid-shift* keeps the whole
floor in RAM and degrades exactly as designed.

The hole is the **cold boot**. Android kills a backgrounded app on a phone in an
apron pocket as a matter of routine, and the waiter who reopens it away from the
host gets:

- an empty floor — no zones, no tables, no way to reach a party at all;
- an empty board — every table reading "no lines", including tables with food on
  them;
- an empty menu — so even a floor restored by hand would dead-end one screen
  later;
- and, underneath, an [[Antrean kirim]] full of orders aimed at tables the
  device could no longer name.

ADR-0128 had already answered the identical question one layer up and stated the
rule: **stale beats absent**, and the copy must be painted in the *constructor*,
because a widget's first build reads state before any microtask runs and the
first frame is the one that was wrong. It cached the venue's settings whole and
deliberately left the floor alone. This ADR finishes the job.

Two facts in the code shaped the design:

- **`seat` already mutates local state optimistically** and *keeps* that
  mutation when it falls back to the queue. So the floor's most important row —
  the table a waiter just sat a party at, offline — exists only as a domain
  object, with no server payload behind it.
- **`sendOrder` does the same for lines**, minting optimistic `Ticket`s that
  mirror what the host will write. Queued *intents* were already surfaced
  separately (`pending_orders_block`); these are a different thing, and they
  live in repository state.

Both mean a copy written only on a successful refetch is worse than useless: it
would cold-boot to a free table with a queued order hanging under it — the two
halves of one act disagreeing.

## Decision

### 1. Four collections, client mode only

Tables, zones, acknowledged ticket lines, and the menu snapshot. The menu is in
scope because a restored floor whose only affordance dead-ends is not
"accessible"; photos are **not**, since they are fetched per `(id, rev)` and
already degrade to initials rather than a broken image (ADR-0014).

The copy runs on a **client** only. The host tablet talks HTTP to a server
inside its own process; a copy whose invalidation story is "the paired
certificate changed" is nonsense on the device holding that certificate.

Bills and closed-visit history stay out. The bill is already cached under
ADR-0123's own rules and must keep answering to them; history is a report, and a
report that is silently a day stale is worse than one that says it cannot load.

### 2. Prefs, one key per collection, stamped with the certificate

Not the client database, against two Drift precedents (ADR-0124, ADR-0129).
Those exist because the journal and the member directory are **queried** — a
directory of low thousands searched by prefix is a query. The floor is not: it
is read whole, once, on the first frame. And a lazily-opened sqlite file cannot
answer synchronously, which is the one thing ADR-0128 proved matters.

Four keys and not one blob, because each collection has its own refetch, its own
WS deltas and its own decode failure; a single blob would let one bad payload
throw the other three away.

The copy **dies with the certificate, not the address** — ADR-0080's rule, and
the one ADR-0128 got wrong first. It shares `satset.venue_cache_fp` with the
settings cache: both die on the same event, so they carry one label between
them.

> `ponytail:` a ~500-item, ~200-table venue would put low MB through a
> synchronous prefs read at boot. The upgrade path is the client database, the
> way ADR-0124 already went for the journal. A cap that silently disabled the
> copy on the largest venues would be worse than the ceiling.

### 3. Written from state, debounced, through one hook

Each repository overrides its `state` setter, so **every** mutation is captured
at one point — the WS delta and the optimistic seat alike. Writing is debounced
~2s: a busy floor is dozens of `tableUpdated` frames a minute, and serialising
per burst is the same answer as serialising per frame for a fraction of the
disk.

Restoring goes through `super.state`, deliberately bypassing that hook: the
setter would re-stamp the copy with *now*, and a floor restored from yesterday
would then tell the banner it synced this second.

### 4. One wire shape, one parse path

The copy stores what each collection already speaks, and re-parses through the
same code the network response does. Tables and tickets need a domain-to-wire
`_toDto` for the optimistic rows that never round-tripped a server; the menu
needs none, because every menu mutation ends in a full refetch, so the last
payload the host sent is always the whole truth and is stored verbatim.

The alternative — a second serialization of the same concept, or deriving the
optimistic mutation back out of the send queue at boot — puts the floor's truth
in two places that can disagree.

### 5. It never expires; it confesses instead

Only a foreign fingerprint drops it. A floor from yesterday is wrong about who
is sitting where but **right about what tables and zones exist**, and that
second half is the half a waiter cannot reconstruct. Expiring at the
business-day rollover would delete the durable part to punish the volatile part.

The volatile part is confessed by a single stamped notice — `FloorStaleBanner`,
on the floor and pesanan screens only, and only when the paint came from the
copy *and* the host is away. One banner, not a stamp per tile: it is one fact
about the whole screen, and twenty timestamps is noise on the surface that has
to survive a half-second glance. A handset that was running when the host died
holds live state and is told nothing.

The banner is deliberately **absent from the menu**, whose staleness is the
frozen sold-out flag. Those flags ship as-is: an item the kitchen killed while
the device was dark still reads available, and one since restocked still reads
dead — but the flag was true when written and usually still is, and a banner
over a menu that is 99% right teaches the waiter to dismiss the banner on the
two screens where it means something.

### 6. It gates nothing

The copy decides nothing about what may be written. The floor stays fully
actionable offline, with no new lock: the [[Antrean kirim]] already accepts
`seat` and `submitOrder`, and settlement is already governed by
[[Kunjungan otoritatif-lokal]], which is a stricter test than anything this
would add. Inventing a second lock here means two answers to "may I write
offline".

Two dark handsets can now both cold-boot showing the same table free and both
seat it. That is ADR-0116's case at a higher frequency, not a new one, and it
keeps ADR-0116's answer: **loud at drain, never prevented**. A lease is granted
by a host that just vanished.

## Consequences

- A waiter's handset restarts away from the host and finds the venue where they
  left it — including the party they seated while dark.
- The `state = const []` wipe at the top of each `_bootstrap` is gone. It
  existed to clear stale dummy rows and now runs *after* the constructor painted
  the copy, where it would re-acquire the empty floor this removes.
- Guest names and notes are written to disk in the clear and survive sign-out —
  the same posture as ADR-0129's mirror, and for the same reason: the copy
  belongs to the device, not the session, and a shared handset is signed out at
  end of shift, which is precisely when it is next cold-booted. Hiding the name
  from the copy would protect nothing that is not already on the screen while
  losing the label a waiter finds the party by.
- The staleness stamp is a plain `ValueNotifier` on `FloorCache`, **not** a
  Riverpod provider. The repositories set it from inside their own constructors,
  and Riverpod forbids a provider mutating another provider while it builds.
  Restoring *is* construction, so the stamp cannot live in the provider graph.
- `test/offline_floor_cache_test.dart` pins the cold boot, the stamp, the
  fingerprint wipe, the server-mode exclusion, one bad payload not taking the
  other three down, and a local mutation reaching disk.
