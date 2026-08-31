# ADR-0090 — An offline order is an intent, not a row

Status: accepted
Date: 2026-08-09

## Context

A waiter walks into the corner of the terrace where the Wi-Fi dies. Today
everything they touch fails: `submitOrder` throws on an 8s timeout, `acquireLock`
throws, and when the socket comes back `_resync()` refetches the host's world and
replaces local state wholesale. Nothing is lost, because nothing was ever
captured. The waiter stands still until the signal returns.

The obvious fix — let the client write locally and merge later — is the one to
refuse. Everything that makes an order correct lives on the host: visit minting
(ADR-0024), ingredient coverage and per-line rejection (ADR-0041), the modifier
price snapshot (ADR-0011), the kitchen-ownership freeze (ADR-0071), the audit
writer, the idempotency table. A client that mints rows reimplements all six and
then drifts from them, and the drift shows up as a bill that is wrong in a way
nobody can reconstruct.

Two facts shaped the rest. The client has **no local database** — repositories
are in-memory `StateNotifier`s and prefs holds only mode, host, theme and
printers. And `restoreFromStoredToken` calls `/auth/me` inside a
`try { … } catch (_) { await storage.clearSession(); }`, so a waiter whose app
restarts while terputus has their JWT **deleted by a timeout** and is stranded on
`/pin`. Any offline story is worthless until that catch distinguishes 401 from
"no route to host".

## Decision

An offline write is an **intent**, never a row. The device keeps an
[[Antrean kirim]] — a FIFO of intents in a prefs JSON blob, capped at 200 —
and on reconnect replays them through the ordinary HTTP routes. The existing
`Idempotency` table makes replay safe with no new mechanism.

**The host always wins.** The client never merges, never resolves, never
self-authorises. It re-asks the question it could not ask before and reports the
answer.

Specifics, each of which was a live alternative:

- **Surface.** Only *seat table*, *submit dine-in order*, and *edit or void a
  line this device captured and has not yet delivered*. Settlement, discount,
  table move, stock override and takeaway are refused while terputus — money,
  cross-device state and privilege each need the authority present.
  **Amended by [ADR-0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md):**
  the refusal of settlement held while the kasir *was* the host; a client-mode
  `/kasir` loses the host the way a handset does, and money captured there is a
  journal rather than an intent. Discount and privilege keep their line — a
  manager step-up still has no offline path (ADR-0099).
- **No offline mode flag.** With the socket closed the client enqueues without
  attempting (a waiter must not eat 8s per tap); with it open it posts normally
  and enqueues only on transport failure. `WsConnState` drives the badge, never
  correctness.
- **Sessions survive, sign-ins do not.** `clearSession()` fires on 401/403 only;
  a transport failure restores from a cached `MeDto` marked unverified. A fresh
  PIN sign-in while terputus is refused — the hash is the host's, and caching
  PIN material on a shared handset buys convenience with a security regression.
- **Two timestamps.** `sentAt` is stamped at **delivery**, and a new nullable
  `capturedAt` carries the moment at the table. The kitchen cannot be late for
  food it had not received, so KDS, ADR-0081's tickers and every alert threshold
  keep reading `sentAt` untouched.
- **The visit is the conflict token.** An intent captured against a known visit
  carries it; one captured against a table with no open visit carries nothing
  and lets the host mint, as it always does. Nothing local ever crosses the
  wire — a queued line renders straight off the queue rather than being faked
  into the ticket map, so there are no placeholder ids to reconcile. If the
  table has since changed guests, the host **refuses**
  rather than attaching — the alternative silently bills a stranger for food they
  never ordered, and it looks correct on every screen.
- **Expiry is the business-day boundary** (`businessDayStartHour`), the same
  rollover that retires a [[Shift]] and buckets reports. An intent cannot be
  replayed into a day that has closed its books.
- **The queue belongs to the device, attribution to the author.** After a
  handover the drain runs on the new operator's bearer and the capability check
  is against *them*; `createdBy` stays the capturing waiter (ADR-0056 never
  backfills authorship) and `replayedBy` records who carried it. "Akhiri shift &
  keluar" is blocked on a non-empty queue — a shift summary over undelivered
  orders is a lie — while "Keluar" is not, because handing the handset over is
  the point. The block offers one way past it: discard the backlog out loud.
  That discard is device-local and unaudited, and cannot be otherwise — the
  audit writer lives on the host, and a host that could take the audit row would
  have taken the orders instead.
- **A refused seat refuses the orders behind it.** A table seated offline has no
  visit yet, so its queued orders carry no visit token and cannot check
  themselves against anything. If the host refuses the seat — someone else got
  there first — those orders are refused in the client rather than sent blind,
  because the alternative is hanging a stranger's food on whatever bill the
  table now holds. Orders for every other table drain normally.
- **No lock theatre.** A terputus device cannot hold the 7s lease, so it says so
  rather than faking one. A lease nobody can observe is exactly the ambiguous
  state the design principles ban. **Superseded in part by
  [ADR-0116](0116-a-lease-you-cannot-renew-still-lets-you-queue.md):** the
  no-fake-lease rule stands, but "cannot hold the lease" was read as "cannot
  write", which padlocked the table screen in exactly the condition this queue
  exists for — including the offline void of ADR-0114.
- **No client stock ledger.** Cached `habis` flags render as they last stood; the
  line is provisional and coverage is decided at delivery, as it always was.

## Consequences

A refused replay is normal operation, not an error, so it gets a real surface:
the [[Hasil pengiriman]], acknowledged explicitly and then resident on the Saya
tab until resolved. The cost of host-wins is that the waiter can be told, twenty
minutes late, that a dish was never sent — which is the honest version of a
situation whose dishonest version is a guest charged for a bill that grew after
they paid.

A [[Cashier|kasir]] can still settle a bill while lines sit on a dark handset.
Nothing can prevent that — the device is unreachable by definition — so the
replay is refused into the report instead, and the floor marks a table whose
handler has no live socket so the kasir has a reason to ask first.

The queue is a prefs blob because a shift's backlog is tens of intents. If it
ever needs querying rather than draining, that is the moment for Drift on the
client, and not before.
