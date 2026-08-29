# ADR-0119 — A member report reads what they bought

Status: accepted
Date: 2026-08-29

Reads [ADR-0118](0118-member-attribution-rides-the-receipt.md) (the receipt is
the attribution grain) and extends its subtraction from money to **lines**.
Reads [ADR-0092](0092-a-member-is-a-phone-number.md) (a delete anonymises,
never erases), [ADR-0068](0068-an-even-receipt-is-an-amount-receipt.md) (an
amount receipt owns no lines) and [ADR-0091](0091-membership-lives-in-the-venue-not-the-cloud.md) (an
unentitled member route answers 404). Does not change what
`memberReportSection` prints on `/reports`.

## Context

The venue report's Keanggotaan block answers the program's headline question —
do members spend more, and come back — for the venue as a whole. It cannot
answer the two questions an owner asks next:

- **Who are they?** The block ranks the top 100 by spend and reports the
  remainder as a count. There is no way to browse the directory's trade, sort
  it another way, or find one regular by name.
- **What do they actually buy?** Nothing anywhere joins a member to a menu
  item. `GET /members/<id>/visits` returns bills — table, pax, total, discount,
  loss — and stops there.

Both are answerable off rows the venue already keeps.
`table_session_tickets` holds every line ever settled, forever, with its item
id, name, qty, unit price and void status. `table_sessions.member_id` names the
[[Pemilik tagihan]] and `table_session_receipts.member_id` +
`table_session_receipt_lines` name the [[Pemilik struk]] and the units their
share claims. The question was never whether the data exists. It was what the
answer *means* on a bill more than one member was on.

## Decision

### 1. A new screen, not a bigger section

`/member-report`, tablet-only, opening to `viewReports` **or** `manageMembers`
— the `/kas` and `/opname` shape, because the person who enrols the guests and
the person who reads their spending back are rarely the same one. Two panes:
the ranked list is browsed and sorted on the left, one member is read against
their own history on the right.

The Keanggotaan block on `/reports` is **left exactly as it was**. A closed
month must keep printing what it printed, and a report window shared with sales,
staff and stock is the wrong place for a per-person drill.

### 2. Lines divide the way money does

ADR-0118 states member spend as a **subtraction**: a receipt naming somebody
other than the owner is theirs, and the owner takes everything left. Products
follow the same rule at qty grain — a line assigned to a receipt belongs to that
receipt's [[Pemilik struk]]; a receipt nobody named, and every unit on no
receipt at all, belongs to the [[Pemilik tagihan]].

That rule was already implemented once, inside `punchStatus`, because
[[Kartu stempel (punch card)|stempel]] has to count units the same way. It is
now `memberUnitsOf` and both callers read it. Two copies of a subtraction is how
one screen comes to say a guest ate three plates and the next says four.

Two consequences are deliberate:

- **A void is not a purchase.** It leaves the rollup and the per-bill item
  count, so a bill a member did settle can legitimately show zero items. Stempel
  still reads voids, because a comp is a reward there — which is exactly why
  `memberUnitsOf` returns units and lets its caller decide what a voided one
  means.
- **An amount receipt buys nothing.** It claims money and owns no lines
  (ADR-0068), so a member who settled an even share has spend and no products.
  The gap is real, so it is **named**: `untrackedSpend` is reported and shown,
  because two totals that are supposed to disagree read as a bug when nothing
  says so.

### 3. The history opens where the directory 404s

`GET /members/<id>/report` does **not** go through `getMember`. A member deleted
under ADR-0092 leaves their trade behind as an orphan `member_id`, and those
bills are the venue's record of what it sold rather than the person's data. The
route answers for an id with no directory row; `GET /members/<id>`, which is
about the person, correctly keeps 404ing. The list renders such a row as
"Pelanggan dihapus" and still opens it.

### 4. Two window resolvers, on purpose

`reportWindow` (formerly `_windowFor` in `reports_routes.dart`) is now public,
so this report and `/reports` land on the same business-day rollover — a report
disagreeing with the accounting one about where yesterday ends would file the
same 02:00 bill in two different nights.

`all` is resolved **in the members route only**, and `MemberRange` is a separate
enum from `ReportRange` rather than a seventh arm on it. `/reports` renders
`ReportRange.values` straight, so an `all` arm there would hand the accounting
report an unbounded window — and that payload is **per bill**, which is what the
92-day cap exists to bound. The member report is aggregated to a capped list
plus a rollup and does not grow with the span, so it can carry the arm the other
cannot. The open start labels itself with `earliestClosedAt`, the venue's real
first trading day, rather than the sentinel year the query uses.

### 5. The list is capped server-side and sorted client-side

500 rows, five times the venue block's 100, with the remainder as a count. The
screen sorts and filters the rows it already holds: a sort that cost a LAN round
trip would be slower for no gain, and the cap is the only thing standing between
a browse screen and a venue-sized payload.

### 6. One walk, two halves

`memberTradeReport` scans the window once and hands the result to
`memberReportSection`, which now takes the scans as optional parameters. The
tiles and the list therefore cannot disagree about the same split bill — they
are two readings of one pass, not two passes.

## Consequences

- `memberReportSection` is unchanged on the wire. Its internals moved into
  `memberWindowTrade` / `memberWindowPoints` / `memberPointsOutstanding`, and
  its per-id name lookup became one batched query instead of N.
- A new ledger-shaped reader must use `memberUnitsOf` for line attribution. A
  second implementation of the subtraction is a review finding, the same way a
  second cash writer is.
- Export is **not** built. `export_sheet` carries a shared `_ExportKind`
  contract and adding an arm touches every other report; the screen ships
  without it until somebody asks.
- Nothing here is gated on `memberSplit`. The attribution is read
  unconditionally, for the reason ADR-0118 §6 gives: the mode gates the write
  and the picker, never the read, and a window that was attributed keeps
  reporting as attributed after the mode is unticked.
