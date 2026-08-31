# ADR-0123 — An offline settlement is a journal, not an intent

Status: accepted
Date: 2026-08-30

Amends [ADR-0090](0090-an-offline-order-is-an-intent-not-a-row.md), which
refused settlement offline by name.

## Context

ADR-0090 gave the waiter an [[Antrean kirim]] and drew the line at money:
"Settlement, discount, table move, stock override and takeaway are refused while
terputus — money, cross-device state and privilege each need the authority
present." That held while the [[Cashier|kasir]] was the host. It stops holding
the moment a venue runs `/kasir` on a **client-mode** device — a second tablet at
the counter, a phone the owner settles from — because that device loses the host
exactly the way a waiter's handset does, and the guest at the counter is holding
out cash.

A [[Bill (tab)]] cannot be captured the way an order can. An order is one intent
with one answer; a settlement is a *sequence* — mint a receipt, assign lines,
apply a discount, take a payment, refund a leg, close — where each act reads the
state the previous one wrote. ADR-0090's flat FIFO of independent intents has no
shape for that, and its own closing paragraph anticipated this: *"if it ever
needs querying rather than draining, that is the moment for Drift on the client,
and not before."* This is that moment; the client database is
[ADR-0124](0124-the-client-holds-a-database-for-money-it-cannot-send.md).

The other reason settlement is not an intent: the cashier must **read** what they
captured. A waiter's queued line renders straight off the queue and needs no
totals. A cashier has to be told the outstanding, the change due, and whether the
bill is now lunas — all of which are derived, and all of which the host computes
today.

## Decision

An offline settlement is an **[[Antrean setelmen|append-only journal of events
per visit]]**, projected locally into the same `Bill` the host would have
returned, and replayed through the ordinary routes on reconnect. The host still
always wins.

- **The projection and the replay are the same function.** `recomputeBill(lines,
  receipts, discounts, payments, config) → Bill` moves into `domain/` as a pure
  function, beside `computeBreakdown`, and **the server route calls it too**. The
  offline bill is `lastServerBill + localEvents` run through it; the post-drain
  server bill is the same events run through the same function. A second
  implementation would quote the guest one number at the counter and a different
  one after drain, with nothing to say which was right.
- **Ids are minted by the client, always — online included.** Receipt, payment
  and discount ids become client-supplied uuids and double as the idempotency
  key. Minting only offline would give one row two provenances and leave the
  offline branch exercised only offline, which is where an untested branch is
  worst. The acts that ids do not cover — `assignLine`, `splitEven`,
  `deleteReceipt`, `reopen` — pass the **journal event id** to the existing
  `Idempotency` table, exactly as `POST /orders` does. No new mechanism.
- **A visit with a non-empty journal is local-authoritative** until its chain
  drains clean, even after the socket returns. Otherwise a live write lands ahead
  of the queued events and the projection the cashier is looking at is a lie.
  This is [ADR-0116](0116-a-lease-you-cannot-renew-still-lets-you-queue.md)'s
  rule on a second surface: *a visit you cannot settle against the host is still
  a visit you can settle.*
- **Refuse on contradiction, never on staleness.** A waiter sent two more dishes
  while the cashier was dark: the payment is now short. That is a correct bill
  with an outstanding, not a conflict. The refusal set is narrow and factual —
  the visit was already bill-closed by someone else, the receipt is gone, the
  line was voided or reassigned, the redeem exceeds the live balance, the member
  was merged away, a payment or refund names a receipt that no longer exists.
  Refusing a stale-but-consistent payment would throw away real money to protect
  a total.
- **Ordered chains, halted on first refusal.** Events replay per visit in
  capture order; a refusal parks the rest of *that visit's* chain untried while
  other visits keep draining. Best-effort per event would land a refund whose
  payment was refused. A single all-or-nothing transaction is the honest ideal
  and needs a bulk endpoint, which ADR-0090 bans by name.
- **This device's orders drain before this device's money.** `SendQueue` empties
  first, then the journal — so a payment does not replay against a bill that does
  not yet contain the food. Only for this device; another handset's backlog lands
  when it lands, which is what the staleness rule above already covers.
- **Every event carries `capturedAt`, and the host honours it** — for
  `payments.at`, the audit row, `billClosedAt` and business-day attribution. A
  payment taken at 23:50 and drained at 00:10 belongs to the shift that collected
  it; drain-time stamping makes the closing shift short and the opening one over
  in the same stroke. The audit row carries both moments, so the venue log can
  say "collected 23:50, recorded 00:10".
- **Settlement events never expire.** ADR-0090 retires an order at the
  business-day boundary because a day that closed its books cannot absorb it. The
  same rule applied to a payment discards cash that is physically in the drawer.
  A drain landing after **Tutup kedai** (ADR-0111) is accepted, backdated, and
  audited under its own kind so the discrepancy has a name when the owner finds
  it.
- **Two acts stay online-only.** A **manager step-up** (`resolveStepUp`) verifies
  a PIN server-side against a salted hash (ADR-0112); caching hashes on a shared
  handset makes a stolen tablet a manager, and
  [ADR-0099](0099-an-admin-sign-in-has-no-offline-path.md) already settled that
  authority does not travel offline. A cashier who *holds* `applyDiscount` keeps
  every discount offline; one who would have borrowed it waits. And **member
  lookup** stays server-side (ADR-0092 makes the phone number the identity — a
  mirrored directory is the venue's customer list walking out in a stolen
  tablet), so offline you may only act on the member **already attached** to the
  cached bill. Redeeming their [[Poin]] offline *is* allowed: the balance is a
  read the client already holds, a stale one over-redeems by a little, and
  `spendPoints` refuses it at drain (ADR-0100) where the cashier can re-collect.
- **Offline printing is device-scope only, and drops the points block.** A
  server-scope printer is unreachable by definition. A points or stempel balance
  printed from stale local data is a number the guest can photograph and argue
  from next week; an absent block is a shrug.
- **No gate.** Not a [[Modul]], not a mode key. ADR-0090 shipped offline capture
  ungated and this is the same promise on the other half of the flow — and a mode
  key fails closed (ADR-0109), which would turn the fallback off on precisely the
  venue that has never phoned home.

## Consequences

**Two islanded devices can both collect the same bill in full, and nothing
prevents it.** A designated-offline-cashier flag would be a lease granted by the
host that just vanished — ADR-0116's exact anti-pattern. So the answer is to make
it loud rather than impossible: the second chain is refused at drain with the
other device's payments listed, and reconciling the cash is a human act the
software's job is to *surface*.

A refused settlement chain is cash already in the drawer, so it gets a heavier
surface than the [[Hasil pengiriman]]: a blocking sheet on `/kasir` naming the
visit, which events landed, which are parked, and the rupiah delta between what
was collected and what the host now believes. Acknowledging it writes an audit
row. Never auto-retried.

The full `Bill` is prefetched and kept fresh for **every open visit** while
online, not just the one the cashier opened. Caching on open only would make the
feature's availability depend on where a thumb happened to be five minutes
earlier, which is the worst possible property for a fallback.

Moving `recomputeBill` into `domain/` means the settlement route materialises its
Drift rows into plain records before computing. That is the price of the two
sides being provably the same, and the thing that keeps it true is a **parity
test**: one event sequence — lines, receipts, all three discount sources, a
member, a redeem, partial payments — run through the server routes and through
the local projection, asserting the two `Bill`s are identical, plus a drain test
asserting the post-drain server bill equals the pre-drain local projection.
Without it the shared function drifts the first time someone edits one side.
