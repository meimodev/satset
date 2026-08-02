# ADR-0079 — Cashier history pages by growing limit, not cursor

## Status

Accepted. Bounds the `Lunas` / `Semua` half of the cashier screen defined in
ADR-0066, whose history source is ADR-0024. Deliberately does **not** follow
the keyset paging ADR-0072 established for the venue audit log.

## Context

`GET /settlement/history` returned every closed session in its 7-day window,
unbounded. The generic seed fabricates ~1500 bills a month (ADR-0073), so a
seeded or busy venue puts ~350 rows on the wire — and `venueHistoryProvider`
refetches **the whole list on every `tableSession.closed` WS event**. During a
rush that is not a one-time load cost, it is a continuous one.

The render side was worse. `_Masonry` sits inside a `SliverToBoxAdapter` and
builds every card up front — its own comment names the ceiling ("tens, not
thousands") and prescribes `SliverMasonryGrid` as the upgrade.

We took neither obvious fix.

## Decision

**Bound the input instead of making the grid lazy.** The route takes a `limit`
(default 60, hard ceiling 300). At 60 cards an eager masonry is a non-issue, so
`_Masonry` is untouched — no new dependency, and it keeps round-robin packing,
which is what makes reading order match the sort (biggest outstanding first,
left to right). `SliverMasonryGrid` packs by column height and would have
broken that ordering to solve a problem we no longer have.

**Page by refetching at a larger limit, not by cursor.** Scrolling near the
end raises `historyLimitProvider`; the provider re-runs and fetches the newest
N. `venueHistoryProvider` watches that limit rather than being keyed on it by
family, because a re-run keeps the previous page attached to the `AsyncLoading`
— the grid shows the rows already there plus a foot spinner, where a new family
instance would have handed back an empty one and collapsed the grid mid-scroll.

**The response is `{rows, total}`, not a bare array.** `total` counts the whole
window server-side. Every count on the screen reads it; none reads
`rows.length`. This is ADR-0072's lesson applied verbatim — *"counting loaded
rows would print '3 pembatalan' on a venue with forty"* — and it is why the
wire shape changed rather than the client inferring a count it cannot know.

**Only history is capped.** Open bills (`Perlu ditagih`) stay unbounded: they
are a work queue, they are bounded by physical tables anyway, and one hidden
below a scroll threshold is money that walks out.

## Why not cursor paging, given ADR-0072 did

This is the question a reader will actually have, since the audit log does
keyset paging one directory over.

Audit pages are stable — nothing prepends to the log while you read it. Cashier
history is the opposite: **every bill close inserts at the head**, and that same
event invalidates the list. Cursor pages would then have to be reconciled
against a list that moved underneath them — you hold pages 2..n fetched against
a head that no longer exists. Refetching the newest N is always internally
coherent, at the cost of re-sending rows the client already had.

That cost is the trade. Re-fetching 60→120 rows to show page two is wasteful,
and it is O(n²) if someone pages deep. Both are bounded by the ceiling, and a
cashier paging far into history is rare — the common act is settling today's
bills, which page one covers whole.

## Consequences

- **The 300 ceiling is load-bearing, not a round number.** The grown limit
  persists for the life of the screen (lowering it would delete rows under a
  scrolled thumb), and every bill close refetches at whatever it currently is.
  Uncapped, one idle scroll to the end of a busy week leaves the app refetching
  a fat payload on every close for the rest of the shift. At the ceiling the
  grid says so and points at Laporan.
- **Any filter over this list must be server-side.** `CONTEXT.md` describes a
  per-table filter chip that narrows the venue-wide list *client-side*. That
  chip does not exist in the code, and if it is ever built that way it will
  report "no bills" for a table whose bills are simply below the page boundary.
- **If deep paging ever becomes a real cashier act**, cursor paging is the
  upgrade — and it will have to answer the head-insert problem this ADR dodged.
