# ADR-0124 — The client holds a database, for money it cannot send

Status: accepted
Date: 2026-08-30

## Context

Since ADR-0090 the client has had **no local database** on purpose: repositories
are in-memory `StateNotifier`s, and the one thing that must survive a restart —
the [[Antrean kirim]] — is a JSON blob in prefs, capped at 200 intents. That was
the right call for a drain-only backlog, and ADR-0090 named the condition that
would change it: *"if it ever needs querying rather than draining, that is the
moment for Drift on the client, and not before."*

[ADR-0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md) is that
condition arriving. An offline settlement is read as well as replayed: the
cashier needs the outstanding, the change, the lunas state, and which of a
visit's events have landed. That is a query over per-visit ordered events plus a
cache of full `Bill` documents for every open visit — tens of documents each
holding lines, receipts, discounts and payments. Prefs is a single blob that is
rewritten whole on every append; putting a shift of money documents in it means
re-serialising the lot to record one payment.

## Decision

A second Drift database on the client, under `lib/data/db/`, holding two things:
the **[[Antrean setelmen]]** (per-visit ordered settlement events) and the
**cached `Bill`** for every open visit.

- **It belongs to the device, not the session** — ADR-0090's rule, for the same
  reason: handsets are shared, and a backlog must survive the handover ADR-0065
  exists to allow.
- **`SendQueue` does not move into it.** Orders and money have different
  lifetimes (one expires at the business-day boundary, the other never — ADR-0123)
  and different failure surfaces. Migrating it is risk for no gain; it stays in
  prefs.
- **It is a cache and a journal, never a source of truth.** Nothing here is
  authoritative once its chain has drained; the host's answer replaces it. It
  holds no menu, no stock, no member directory (ADR-0123 refuses that one
  explicitly), no history.
- **It carries its own `schemaVersion` and its own dump harness**, like
  `lib/server/db/`. `build_runner`'s scope in CLAUDE.md gains `lib/data/db/**`.
- **Bounded on two axes.** Events cap per visit (a bill that took a hundred acts
  is a bug, not a busy night) and globally; the cached bills follow the open-visit
  list and are dropped when a visit closes clean. Both caps surface through the
  refusal sheet rather than dropping silently.

- **The payable list is cached too, and that is not an optimisation.** Caching
  every open visit's bill (ADR-0123 §Q19) buys nothing on a cold boot with no
  host, because the list a cashier taps through is fetched rather than derived:
  the screen renders empty, over a strip saying money is still queued. One row
  holding the host's own `/settlement/payable` array, replaced whole on every
  successful fetch and read only when the fetch fails and nothing is loaded yet.
  A bill that left the host's list is settled or gone, so merging would resurrect
  it. Settled *history* is deliberately not cached — the `Lunas` segment reads 0
  on a dark till, which is honest; the open bills are what a cashier must reach.

## Consequences

The layer rule holds: the database is `data/`, the projection it feeds is the
pure `recomputeBill` in `domain/`, and `test/layering_test.dart`'s frozen
allowlist gains nothing.

The obvious next temptation is to put the menu, the stock flags and the member
directory here too and call the client offline-capable. Resist it per feature and
per ADR — this database exists because money captured on a dark handset must be
readable before it is deliverable, and each new table needs its own argument of
that weight. The member directory has already been refused once (ADR-0123).
