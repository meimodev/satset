# The member directory travels with the device

**Status:** Accepted — 2026-09-04 — **amends** [0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md).

ADR-0123 shipped the offline settlement journal with two acts held back as
online-only: a **manager step-up**, and **member lookup**. The step-up stands —
authority does not travel offline (ADR-0099) and a cached PIN hash on a shared
handset is a stolen manager. This ADR overturns the other one. The [[Pelanggan
(member)]] directory now travels with the device: a **[[Salinan pelanggan]]**,
filled ahead of the outage, searchable and assignable while dark, and — new
here — **enrollable** while dark by whoever may enrol online.

0123's member bullet stays in place with a pointer to this file, because the
reasoning it gives is still the reasoning; what changed is the answer.

## Context

0123 declined a mirrored directory in one sentence: *"a mirrored directory is
the venue's customer list walking out in a stolen tablet."* ADR-0092 makes the
**phone number** the identity, so the mirror is not a convenience index — it is
the venue's contactable customer list, on hardware that gets lost.

Against that stood the shape of the actual floor. `MembersRepository` is a pure
server read — `/members`, `/members/lookup`, `limit=100`, prefix search
server-side — and ADR-0128 deliberately left it uncached while caching the
settings payload beside it. So on a dark device:

- the [[Cashier|kasir]] could act only on the member **already attached** to the
  cached bill, and the lookup sheet withdrew enrolment outright;
- a [[Waiter|pelayan]] could not attach a regular to a [[Ticket]] at all, though
  ADR-0125 made the ticket an attribution site precisely so they could;
- a venue that runs its whole [[Poin]] and [[Kartu stempel (punch card)]]
  program off recognition at the till simply stopped running it for the length
  of the outage.

The offline promise is the product (§Design Principles 6: *degrade loudly, fail
safely*). A program the venue sells to its guests going dark with the Wi-Fi is
not degrading — it is off.

Two facts in the code shaped the compromise:

`/members/lookup` — the route a `takeOrder` holder may call — already **masks the
number**:

```dart
return '•••• $tail';
```

and `/members` carries a comment saying enrolment is deliberately not theirs:
*"Enrolment stays at the till and the admin sheet — creating a customer record
is a data-quality act."* Whatever the mirror does, it may not quietly hand a
walking handset the two things the online routes withheld from it.

## Decision

**A mirror, on every paired device, masked exactly where the wire already
masked.** The full record — name, number, birthday, note, tier, balances —
reaches a device holding `settleBill` or `manageMembers`. A `takeOrder`-only
device gets a **masked mirror**: the number is stored as a salted hash plus its
last four digits, so typing a full number still finds the guest and the screen
still shows `•••• 8821`, and a pulled database file yields no dialable list.
Note, birthday and address travel with the number — they are contact details
too, and a masked mirror is not the place for the venue's notes on a person.
The payload varies by capability at the route, not at the widget.

The hash is **salted per venue**, and the salt lives in `flutter_secure_storage`
rather than in the sqlite file. An unsalted digest of a phone number is not a
mask at all: the number space is small enough to walk end to end, so the file
alone would hand back every number and the masking would be the theatre this
ADR rejected under (c) below. With the salt in the platform keystore, the
database file on its own is not enough. A device that can search by number can
still brute-force its own mirror — that is inherent in being able to search at
all, and it is not the threat: the threat is the file.

This is the accepted risk, stated plainly: **on a till, the clear-text customer
list is on the device.** The masking covers the phones, which are the hardware
that walks; it does not cover the tablet at the counter, and 0123's objection
survives there in full. The lever against it is the venue switch below, not a
technical mitigation.

**One read route, a cursor, and tombstones.** `GET /members/sync?since=<cursor>`
returns upserts and tombstones in one ordered stream, paged, and the client
persists the cursor. Caching whatever pages the user happened to browse was
never an option — a member nobody scrolled to is exactly the member the search
box is for.

The cursor is a **revision counter, not a timestamp**, and that was a bug before
it was a decision: drift stores a `DateTime` at **second** granularity, so a
change landing in the same second as the cursor and sorting below it is skipped
— silently, and forever, because nothing revisits a row that did not move. The
test that pins a points adjustment re-syncing its member is what found it. So
`Members.mirrorRev` is an integer from a sequence shared with
`MemberTombstones.rev`, one cursor resumes both streams, and there are no ties
to break.

Two things this cost. Every writer must advance the revision — `touchMember` is
the one function that does, and `members.dart`, `debts.dart` and the bill close
all call it, because a mirror carries figures derived from all three. And
**tombstones needed a table**: `deleteMember` and `mergeMembers` both
`DELETE FROM members`, so there is no surviving row to read as a tombstone. What
ADR-0092 anonymises is the *trade* — a closed bill keeps its `memberId` and
renders as "Pelanggan dihapus" — which is a different thing from the directory
row, and reading the summary as the latter is how this ADR first got it wrong.

**The mirror lives in the client database** (`lib/data/db/`, v2→v3, one
`createTable(cachedMembers)` branch). This widens ADR-0124's charter from "a
database for money it cannot send" to "money it cannot send, and the directory
that money names"; low thousands of rows with prefix search on two columns is
not a prefs blob, and a second Drift file buys a tidy sentence in exchange for a
second connection, lifecycle and migration path.

**It dies with the certificate, not the address** (ADR-0128's rule, learned the
hard way there): the mirror is stamped with the fingerprint it came from and
dropped only when a config names a different one. It is also dropped when the
sync route answers **404** — the venue withdrawing the feature, by switching
membership or mirroring off, takes the copy with it. There is no separate
unpair wipe because the app has no unpair flow to hang one on; re-pairing to
another venue arrives as a different fingerprint, which is the case that
matters. It is **not** wiped on staff sign-out — shift change is constant, and a
mirror that cannot refill while dark is a feature that deletes itself on the
device that needs it.

**An owner can switch it off, and it is a plain boolean.** A
`venue_settings` flag defaulting **on**, cached whole per ADR-0128 — explicitly
**not** a [[Modul]] and **not** a mode key. A mode key fails closed (ADR-0109),
which would switch the mirror off on precisely the never-phoned-home venue this
exists for. It is the only answer an owner has to *"is my customer list on the
phone my waiter lost"*, so it has to be a switch and not an entitlement.

**Search and assign are open; enrol is not.** Offline search and offline
attach — to a [[Ticket]] (ADR-0125) or a [[Pemilik struk|struk]] (ADR-0118) —
are open to any device that can do them online. **Enrol** stays gated to
`settleBill` / `manageMembers`, mirroring the online rule. Offline capture has
never granted authority the caller lacked online (ADR-0099; ADR-0114 keeps a
void's 403 as a business refusal), and the alternative makes a dark network a
privilege escalation.

**Every member act queues in the [[Antrean setelmen]]**, not the [[Antrean
kirim]] — one queue, one drain order, one place to read what is parked. Two
adjustments make that safe:

- Enrol has **no visit**, so visit-less acts share a **venue-scope chain** on
  the device, drained ahead of every per-visit chain. An assign that names a
  member the host has never heard of must land second.
- Member-scope events are **excluded from the local-authority test**. 0123's test
  is `journal.isNotEmpty || wsConnState != open`, so without this a pelayan
  tagging a regular at order time would make that [[Visit]] a [[Kunjungan
  otoritatif-lokal]] **on their handset**, and the two-islanded-tills case
  (ADR-0116) would go from exceptional to routine. An act that moves no money
  earns no settlement authority.

**A same-phone enrol folds at drain.** An offline enrol mints a client-side uuid
that doubles as its idempotency key, the house rule since 0123. When the drain
finds that number already in the directory — two dark tills enrolled the same
walk-in, or the guest was already a member — the host **folds** the arrival into
the existing record through the merge path that already exists, answers with the
winning id, and the mirror rewrites its own. It is audited under one new kind,
`memberEnrolFoldedAtDrain` (`{from}`, `{to}`), and deliberately
**not** as `memberMerged` — that kind means a human chose to merge, and hiding
the drain's own decision inside it is how an owner ends up unable to explain
their own directory. Refusing instead would be wrong rather than safe: under
ADR-0092 the same number **is** the same person.

**A [[Pendaftaran terlipat]] is not a contradiction**, so it does not halt the
chain. 0123's rule holds: refuse on contradiction, never on staleness.

**Stale numbers show their age; stale money does not move.** [[Poin]], stempel
progress and [[Piutang]] render **with the timestamp they were
true at** — a stamped number a kasir can caveat is useful, a bare one the guest
photographs is what 0123 was avoiding. Every **debt write** — a charge, a
payment, a write-off, an adjustment — stays online-only. Redeeming poin offline
stays allowed exactly as 0123 allowed it (the over-redeem is small and
`spendPoints` refuses it at drain, ADR-0100); a debt ceiling honoured against a
stale balance is a ceiling that has stopped capping, which is a different size
of mistake. The offline struk still drops the points block.

## Consequences

- The clear-text directory is on every till, and the masked one on every phone.
  That is a real widening of the venue's exposure, taken deliberately, with the
  venue switch as its only off-ramp.
- `Members` gains `mirrorRev` and every writer that changes what a mirror shows
  must advance it through `touchMember` — including the two ledgers in
  `debts.dart` and `members.dart`, and the bill close, whose visit count and
  `lastVisitAt` are derived from trade rather than from the member row. A writer
  that forgets does not fail; it silently drops that member out of every device's
  copy until some unrelated edit moves them again, which is the same failure
  class `writeAudit` and `cash.dart` exist to prevent.
- A column added to `venue_settings` from here on must also be listed in the v63
  rebuild's `newColumns`. That branch copies the *declared* schema, so a column
  it has never heard of is selected out of a table that predates it — which
  fails the upgrade, not just the test.
- The [[Antrean setelmen]] now carries acts that are not money, and its authority
  test grew an exclusion. The chain-vs-FIFO distinction in `CONTEXT.md` still
  holds; "everything in here is money" no longer does.
- Enrolment can now produce a record whose id the client chose and the host
  discarded. Anything holding a member id across a drain has to survive the
  rewrite.
- Pinned by four tests: the client v2→v3 migration (a journal survives the
  bump), `members_sync_routes` (cursor, tombstone, **and payload masking per
  capability**), fold-at-drain (two enrols, one number, one survivor, one
  `memberEnrolFoldedAtDrain` row), and the server schema dump.
  `settlement_offline_parity_test` is deliberately **not** extended: it exists
  because money must compute identically on both sides, and none of these acts
  compute money.

## Alternatives considered

- **Redacted mirror everywhere** (id, name, last four, balances; no birthday, no
  note, no clear number). Strictly safer and rejected: the till reads the number
  back to confirm identity, and the venue that greets birthdays loses the list
  it greets from.
- **Encrypt the mirror at rest** with a key in `flutter_secure_storage`.
  Theatre on a rooted device — the key ships on the same hardware as the file.
- **Enrol online-only** (search and assign offline, enrolment waits). Cheaper,
  and it dodges the fold entirely. Rejected because the walk-in who becomes a
  member *is* the enrolment moment; deferring it to the next reconnect means it
  does not happen.
- **Server-assigned ids with a local temp id.** Removes the fold's id rewrite for
  the common case and adds a rewrite pass over every reference for all cases — a
  ticket, a receipt and a poin row can each name that member before the drain.
- **The [[Antrean kirim]] for enrol and ticket-assign.** The natural home for a
  fire-and-forget intent, and it splits the member story across two queues with
  two drain orders. One queue with an authority exclusion is the smaller lie.
- **A mode key for the switch.** Fails closed, which turns the mirror off on the
  venue that has never phoned home — the exact trap 0123 named and ADR-0109
  documents.
