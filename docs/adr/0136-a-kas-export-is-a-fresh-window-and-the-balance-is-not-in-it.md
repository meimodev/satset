# A kas export is a fresh window, and the balance is not in it

**Status:** Accepted — 2026-09-05 — **amends** [0088](0088-the-petty-cash-box-cannot-go-negative.md) and [0131](0131-a-venue-counts-more-than-one-tin.md) in what a ledger read may carry; neither is superseded.

The [[Kas kecil (petty cash)]] ledger could be read on `/kas` and nowhere else. It
now files: the screen carries a [[Jendela kas]], and that window leaves as CSV or
as a PDF with the proof photos in it. This ADR fixes three things that a naive
version of that feature gets wrong, each of which would be expensive to walk back
once a venue is filing against it.

## Context

**The screen is paged and the balance is not.** `/kas` grows a limit (ADR-0079)
and caps at 500 loaded rows. The balance beside it is `SUM(delta)` over all time
(ADR-0088), derived server-side, per box (ADR-0131) — and the whole point of a
petty cash box is that the number can be counted against the notes in the tin.
The moment a window exists, both of those facts are under pressure from the same
direction: a reader looking at June wants June's figures, and the two obvious
implementations — window the balance, or sum the loaded page — are each wrong in
a way that looks right on screen.

**An export of a paged list files the scroll position.** `audit_exporter.dart`
already says this in prose: *"the client holds only the pages it has scrolled, so
exporting from local state would produce a file that stops wherever the reader
happened to stop — a truncated record carrying the word 'lengkap'."* The venue
audit log solved it by rendering the CSV server-side.

**But this one has a PDF.** The audit log deliberately has no format picker
because a 500-row PDF of an audit trail serves nobody. A petty cash ledger is
filed — by an owner, for an accountant, on paper — and the thing that makes the
paper worth more than the spreadsheet is the receipts. Which means two formats,
and therefore a question the audit export never had to answer: who renders them.

**A proof photo is deliberately not on the ledger path.** `cash_routes.dart`
carries the invariant in a comment on the photo route — *"Blob never rides the
ledger path"* — which is what keeps a ledger page a few KB no matter how many
receipts were shot. An appendix of plates is exactly what that rule was written
to prevent, and it is also the reason to file a PDF at all.

## Decision

### 1. The window narrows the list; the balance is untouched

`GET /cash` takes `from` / `to`. Both absent is the **Semua** arm, which is what
the screen opens on — the behaviour it has always had, so a venue that never
touches the chips sees no change, and a tin that goes a fortnight without a
movement does not open empty.

`balance` and every `CashBox.balance` stay all-time. What the window produces
instead is **movement**: masuk, keluar, selisih, in a `totals` object beside the
entries, **summed by the server over every row in the window** regardless of
`limit`. A count's delta books to `variance` and never to inflow or outflow
(ADR-0089) — the one rule this shares with `cashReportSection`, which is why both
live in `cash.dart`.

The client never adds up a ledger. `CashWindowTotals` has no arithmetic in it.

### 2. An export is a fresh unpaged fetch that refuses rather than truncates

`limit=all` returns the whole window, capped at `kCashWindowMax` (5000). Past the
cap the route answers `window_too_large` and the sheet says *persempit rentang*.
It does **not** return the newest 5000: a short ledger that looks complete costs a
reconciliation, and narrowing the window costs one tap on chips that are already
on screen.

`CashRepository.fetchWindow()` is that call, and it exists so the exporter can
never be handed `state.entries`.

### 3. Both formats are rendered client-side, from one shape

The audit precedent points the other way, and we are departing from it *because*
of the PDF. A server-rendered CSV plus a client-rendered PDF is two renderers of
one ledger; they would eventually disagree about a retired category or a
transfer's other leg, and the export path is the one nobody looks at until an
accountant does. So the server owes the **window**, unpaged, and
`cash_exporter.dart` builds both files from it — the shape `opname_exporter.dart`
and `reports_exporter.dart` already use.

A retired or renamed [[Kategori kas (cash category)]] prints its **current** word.
This is an export of `/kas`, and `/kas` resolves on read (ADR-0135). `/audit`'s
frozen word — written into `auditParams` at movement time — stays `/audit`'s; the
asymmetry is the one 0135 already documented, and this is simply which side of it
a ledger export sits on.

There is **no running balance column**. The balance is order-dependent, and a
spreadsheet the reader re-sorts would carry a column of confident wrong numbers.
Reversals and both legs of a transfer are included with their linkage columns: a
ledger that hides its reversals is not a ledger.

### 4. Photos ride the PDF, and only the PDF

A documented exception to the ledger-path invariant, bounded four ways:

- **Only for a PDF, and only on request.** The CSV never fetches a byte; its
  `foto` column is a bare mark.
- **Fetched one at a time**, through the existing per-row `/cash/<id>/photo`
  route. Sixty parallel requests is how a LAN tablet stalls the socket the rest of
  the venue is on. Progress is determinate, because "menyiapkan" with no number is
  indistinguishable from a hang.
- **Downscaled to 700px q70** off the UI isolate, from the 1080px q80 capture.
  ~60 KB a plate. The appendix is a legibility aid; the full-size original never
  leaves the host, and `/kas` and `/audit` are where a proof is examined.
- **Capped at 60 plates.** Past it the appendix stops and the footer counts what
  was left out. The ledger itself is never truncated — only its pictures.

A failed fetch becomes a **placeholder plate**, never an aborted export. A photo
the host would not give up must not cost the accountant the ledger.

The appendix is a 4-up grid after the table, each plate captioned `#12 · 3 Sep ·
Rp 45.000 · Sayur`, and the row's `foto` column prints `#12`. One page per plate
would turn a forty-row ledger into a forty-page document in which the table — the
thing being filed — is the smallest part.

## Consequences

- `GET /cash` is the only ledger read. Screen and export share a serializer, a
  window resolver and a category resolution, so they cannot drift.
- A live movement arriving over the socket is admitted only when the window's top
  is open (`CashWindow.admits`). A row from today appearing in a June ledger is
  the same lie as a windowed balance. Admitting one also triggers a re-read,
  because the totals are the server's to sum.
- The Reports custom-range cap of 92 days does not apply here — that cap exists
  because the reports payload is per bill. `showCustomRangeSheet` took a
  `maxDays`; kas passes a year.
- Exporting writes **no audit row**. A read is not a movement, and
  `/audit/venue.csv` set that precedent. If a venue ever wants the act logged,
  that is a new `AuditKind`, not a change here.
- The gate is the existing read gate on `GET /cash`: `manageCash` ∨
  `editSettings` ∨ `viewReports`. An export is a read of what the caller can
  already read; a narrower gate on the same bytes is theatre.
- Still outstanding, and deliberately out of scope: `/reports`' own export writes
  every section except its Kas block, which renders on screen and silently
  vanishes from the file.
