# ADR-0137 — An export is a fresh uncapped fetch, not what the screen is holding

Status: accepted
Date: 2026-09-05

## Context

Membership had no export. The [[Pelanggan (member)]] directory could be
**imported** from a CSV since `member_import.dart` shipped, but nothing took
one back out, and the [[Laporan pelanggan]] — the one report that answers "who
are our regulars and what do they buy" — could only be read on a tablet.

The app already exports four things, in three different shapes:

- **Reports** — one `Ekspor` sheet with a `Jenis` picker, CSV or PDF, all four
  kinds gated `viewReports`. `Laporan` renders the in-memory snapshot;
  `Pesanan`, `Staf` and `Akuntansi` each hit a purpose-built JSON endpoint and
  render client-side.
- **Opname** — per document, client-side, CSV and PDF, no picker.
- **Audit** — `/audit/venue.csv`, rendered **by the server**, CSV only, because
  the client holds only the pages it has scrolled and a file built from that
  stops wherever the reader stopped.

The audit log's reasoning is the whole of this ADR, and every membership
surface has the same defect. `GET /members` clamps `1..500`, default 50.
`/members/report` caps its ranked list at 500 and ships the remainder as a
count. `/members/<id>/report` defaults `billLimit: 200` beside a `billsTotal`
that says how many there really were. Every one of those numbers is invisible
on screen — the list scrolls, the reader stops, the screen never claims to be
complete. A **file** does: it has a name, it is filed, it is mailed to an
accountant, and nothing in it says it is the first five hundred.

So the question was not "CSV or PDF" but "what is in the file", and there were
three answers available: render from loaded state (short), lift the existing
`limit` (the clamp silently wins, and a client asking for 100 000 gets 500 with
no error), or ask a route whose job is to answer completely.

## Decision

**An export is a fresh, uncapped fetch.** Three new read-only routes, each
mirroring a screen and each lifting that screen's cap:

| route | mirrors | gate |
|---|---|---|
| `GET /members/export` | the directory | `manageMembers` |
| `GET /members/report/export` | the ranked list | `viewReports` \|\| `manageMembers` |
| `GET /members/<id>/report/export` | one member's history | `viewReports` \|\| `manageMembers` |

They return **JSON** and the client renders the bytes, which is the
`/reports/staff` pattern and not the audit log's: the server carries no
`package:pdf`, and server-rendered CSV would forfeit the PDF filing copy and
put a second CSV writer on the server besides.

**Uncapped is bounded, and the bound refuses.** `kMemberExportMax` is 20 000.
Each route asks for one row past it and answers **413 `export_too_large`**,
naming the limit, when the extra row comes back. A LAN tablet laying fifty
thousand rows into a PDF is an out-of-memory crash, not a document — but a
*silent* stop at row 500 is the failure this ADR exists to remove, so the
ceiling is a refusal with a fix in it ("narrow the window") rather than a
quieter truncation further out. `membersTruncated` is stripped from the export
payload: on an uncapped answer it could only ever say zero.

**They gate what the screen gates, and nothing more.** `CONTEXT.md` §Export
says every export kind sits behind `viewReports` "because export exposes
historical financial data" — but that rule was written for the **order board**,
which is open to `takeOrder`, so exporting it genuinely widened what a role
could see. Here it widens nothing: a `manageMembers` holder already reads every
figure on both screens. Demanding `viewReports` on top would hand a directory
keeper a button that only ever refuses.

The directory export is the one exception in the other direction: it gates
`manageMembers` **alone**, narrower than `GET /members`, which the till and the
booking form also read. Finding one guest mid-service is not taking the
customer list off the device. That also settles masking without a masking rule:
ADR-0129 masks the phone for a `takeOrder`-only device, and such a device is
refused here before masking is a question. There is no masked export — a CSV of
salted digests is not a roster.

**The file is the screen.** The directory export carries the active search,
birthday and *belum kembali* filters, and names them in its header — "the
members who have not come back in ninety days" is the reason an owner takes a
roster, and a filtered file that did not say so reads as a shrinking
membership. The ranked export carries the search box and the active
`MemberSort`, applied client-side to the uncapped rows through
`rankedMemberRows` — one function, hoisted off the screen, so a second
filter-then-sort cannot drift.

**One export audits itself.** `AuditKind.memberDirectoryExported` (params:
`{rows}`), on `AuditType.memberChanged` rather than a type of its own. The two
report exports write nothing: they are aggregates over a window their reader
already had on screen. The directory is the roster — names, phone numbers,
birthdays, addresses — leaving the device through the Android share sheet, and
"who took the customer list, and when" is a question a venue is eventually
asked.

**Its own sheet, not a fifth `Jenis`.** `/member-report` gets one `Ekspor`
button opening a small sheet — kind (ranked list / one member) × format
(CSV/PDF), with the history kind disabled until a member is selected. It cannot
join the Reports sheet: that one reads `ReportRange`, and this screen runs on
`MemberRange`, a different enum on purpose because it carries an open-ended
`Semua` arm the accounting export must never be offered. The directory gets a
plain **Ekspor CSV** button beside its existing **Impor CSV** and **no format
picker** — a roster has one useful shape, and a sheet asking a question with
one answer is a step that buys nothing.

**Offline it refuses, loudly.** With the host dark the directory is served from
the [[Salinan pelanggan]], which is a lookup cache: maskable, and holding none
of the derived figures the file carries. The button is disabled while
`mirroredAt != null`, and any fetch that never reached the host says so in
those words rather than "export failed" — otherwise a reader retries a button
that cannot work until the host is back.

## Consequences

`exportFilename` gained `exportFilenameSlug`, which takes a window slug the
caller already has: `ReportRange` cannot spell `Semua`, and the directory has
no window at all. The three kind slugs (`pelanggan`, `laporan-pelanggan`,
`riwayat-pelanggan`) live in `member_exporter.dart` as `MemberExportKind` and
stay Indonesian in both languages, like every other export kind — a filename is
how a venue files a document, not copy.

The directory CSV leads with the nine columns the **importer** reads, in import
order, then the derived tail. That is a courtesy and explicitly **not** a
round-trip promise: the headers are localised like every other export's, and
points, stempel, [[Piutang]] and lifetime figures are not importable at all. A
re-importable template would be a different file and nobody has asked for one.

`memberHistory`'s bill cap was a hard `clamp(1, 500)` and is now
`clamp(1, kMemberExportMax)`; `memberTradeReport` gained a `rankLimit`
parameter defaulting to the screen's 500. Both defaults are unchanged, so no
existing read moved.

A new export surface now costs a route, a builder and a line in the sheet — but
it inherits the ceiling, the gate rule and the "file is the screen" rule for
free. What it must not inherit by accident is the audit row: that one is a
judgement about **what leaves the building**, not a step in the recipe.

## Alternatives considered

**Bump `limit` on the existing routes.** One line, no new endpoints — and
wrong in the specific way that is hard to see: the clamps are
`.clamp(1, 500)`, so a client asking for 100 000 receives 500 and a `200 OK`.
The truncation this ADR removes would have survived the fix meant to remove it.

**Server-rendered `.csv`, the audit log's shape.** Correct about completeness
and forfeits the PDF, which is the shape a venue actually files a member report
in. It also puts a second CSV writer on the server, where the first one exists
only because the audit log is paged.

**Render from loaded state, opname's shape.** Right for an opname, whose
document holds every line of its own session; wrong here, where every list on
screen is a server-capped page.

**A new `Capability` — `exportMemberData`.** Rejected on
[ADR-0132](0132-a-grantable-capability-must-gate-something.md): it would answer
"yes" wherever the screen already opened, and a capability that gates nothing
still renders a switch, still persists, still audits its own grant, and lets an
owner walk away believing they configured something.

**Join the Reports export sheet as two more `Jenis`.** One entry point for
everything is a real virtue. It costs either teaching a shared sheet a second
range enum or dropping `MemberRange.all` — and `Semua` is the arm that makes
the member report answer "who are our regulars", which is most of why anyone
exports it.

**Export the [[Salinan pelanggan]] when the host is dark, with a staleness
stamp.** Tempting, because the rows are right there. Rejected: the mirror can
be masked, holds no window aggregates at all, and a file that quietly differs
from the same file taken an hour later is worse than no file.
