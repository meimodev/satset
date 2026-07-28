# ADR-0056 — The Pesanan board scopes to the table you handle

## Status

Accepted. Narrows the meaning of `lastActorId` established in ADR-0001
(table locking and seat semantics).

## Context

The Pesanan board (`/orders`) was venue-wide: every live ticket in the
building, flattened into three buckets, identical on every handset. In a
venue with four waiters that is four sections of noise to find your own two
tables in — and the busiest, least forgiving reader (a waiter mid-rush,
glancing for half a second) pays that cost on every look.

Scoping the board to the signed-in user requires picking which of the two
identities the domain already carries means "mine":

- **[[Orderer]]** — `createdBy` on the ticket, stamped server-side from the
  JWT at submit and never rewritten. Frozen to whoever *typed* the line.
- **[[Waiter]]** — `lastActorId` on the table row. Who *most recently acted
  on* the table.

Authorship is the stable choice: it never changes under you. It is also the
wrong unit of work. A waiter works a **section**, not a list of lines they
personally typed. Under authorship, taking over a colleague's table on a
shift change shows you nothing on it, and food you did not type but are now
responsible for is invisible.

`lastActorId` matches the real unit — but it was written by *every* mutation
on the table, including two that are not takeovers at all:

- `POST /tables/<id>/ready/decrement` — clearing a ready plate. Running a
  colleague's food to the pass is the single most common act of help on a
  floor; it stole their entire table.
- `PATCH /tables/<id>/pax` — fixing a headcount. A correction, not a claim.

Two further facts shaped the edges. A guest self-order (ADR-0028) is inserted
by `guest_routes` with **no** `createdByUserId`, and the approve endpoint
never backfills one — so guest lines have no author at all, only a table.
And `close` / `release` write `lastActorId: null` while lines can still be
live, so a row can end up with neither identity set.

## Decision

### The board scopes by handler, with authorship as the fallback

A row is yours when **any** of:

1. its table's `lastActorId` is you — the primary rule;
2. its `createdBy` is you — covers table-less (takeaway) rows, which have no
   table to handle, and keeps your outstanding food on screen after a table
   legitimately moves on;
3. **nobody** owns it — both null. An unowned live line is precisely the one
   at risk of being forgotten, so it shows to everyone rather than to no one.

With no signed-in user the board degrades to its old venue-wide self rather
than going blank. The rule is one pure function, `ownsOrderRow`, in
`lib/ui/features/orders/view_models/orders_scope.dart`.

### `lastActorId` narrows to mean "handler"

The two non-ownership writes are removed, server and client. Writers left:
**seat**, **mark pending**, **move**, **explicit handover**, and **ticket
submit** — the five ops that actually constitute taking a table on. Viewing a
table and acquiring its lock never wrote it and still do not.

### Siap diambil is never scoped

The scope governs **Disiapkan** and **Selesai** only. The Siap bucket stays
venue-wide for everyone, because the *Pesanan siap* cue (ADR-0044) already
sounds on every waiter's handset: a scoped Siap list means four phones chime
and three of them show an empty screen. Pickup lag is the quality killer the
glossary already names; a ready plate is everyone's problem the moment it
exists.

### The Milik saya / Semua switch is session-scoped

A two-state switch over the scoped buckets, defaulting to **Milik saya**.
Held in an auth-scoped notifier that resets on every change of signed-in
user, **not** in device prefs like the theme (ADR-0045): the handsets are
shared, and this is a *who am I* setting, not a *which room am I in* one. It
is not `autoDispose` — leaving the tab mid-shift should not silently discard
a scope you chose on purpose.

## Alternatives considered

**Scope by author (`createdBy`) only.** Stable, needs no server change, and
was the initial recommendation. Rejected because it models the wrong unit of
work: a section, not a typing history. It also strands approved guest orders,
which have no author, on nobody's board.

**Add a `handlerUserId` column,** leaving `lastActorId` as pure audit. The
honest model, and the right end state. Deferred because the explicit-handover
endpoint (`PATCH /tables/<id>/handler`) already exists with **no UI calling
it** — a wrong `handlerUserId` would be uncorrectable except by re-seating
the table. Narrowing the existing column buys the same behaviour today
without a migration; revisit when handover gets a real affordance.

**Stamp a `queuedByUserId` on the transition into `sent`,** so the waiter who
approves a guest order or fires a held course owns it. Rejected: a fired held
course was still ordered by its author, who is the one who will deliver it,
and rule 1 already gives approved guest lines to whoever seated the visit.

**Hard scope with no switch.** Rejected: covering a colleague's section is an
ordinary shift event, and a hard scope makes it a dead end. **Scoping by
capability** instead of a switch was rejected for making one screen silently
mean different things to two people standing next to each other.

## Consequences

- A waiter's board shows their section. The count line in the header reflects
  the scope, so it never contradicts the list below it.
- Empty-because-scoped and empty-because-quiet are **different copy**. A
  waiter must never read "nothing is cooking" while the kitchen is slammed.
- `lastActorId` is now load-bearing rather than advisory: a spurious write
  moves a colleague's section onto your screen and yours off it. Any new
  table mutation must decide, explicitly, whether it is a takeover.
- `/orders` is gated on `takeOrder`, which an owner also holds — a manager who
  never seats a table sees an empty board until they press **Semua**.
  Accepted; the switch is the escape hatch.
- `decrementReady`, `setPax`, `incrementPax` and `decrementPax` lost their
  `userId` parameters. The `/tables/<id>/pax` route ignores a client-sent
  `actorId`, and `/ready/decrement` no longer reads a body.
- `orders_view_model.dart` is deleted. It computed the same board and had no
  consumers; leaving it would have left an unscoped copy of the rule lying
  next to the real one.
