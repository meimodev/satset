# 07 · Reports, audit, printing & the cloud consoles

This area covers everything that turns what happened on the floor into a
number a human can read, a paper slip a guest can hold, or a fact a fleet
operator or off-site owner can see without a LAN connection: the Laporan
report screen and its nine sections, the report-range/business-day windowing
that every one of those sections shares, CSV/PDF export (four kinds, two
formats), the venue-wide audit log with its ADR-0085 structured-event
rendering and ADR-0086 proof-photo linkage, the two-scope (venue/device) ×
two-transport (wifi/Bluetooth) printer system with its shared ESC/POS
renderer and reachability heartbeat, the Owner's read-only cloud report
snapshot, the Fleet super-admin console and its Cloud Functions backend, the
venue subscription notice/cutoff, and the mandatory update gate.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Laporan (Reports) | `/reports` (shell) | `viewReports` | `GET /reports/snapshot` |
| Report ranges & business-day window | — (shared by all report/export endpoints) | `viewReports` | `reportWindow()` in `lib/server/routes/reports_routes.dart:77` |
| Ekspor (Export: report/orders/staff/accounting) | sheet off `/reports` | `viewReports` | `GET /orders/history`, `GET /reports/staff`, `GET /reports/accounting` |
| Catatan audit (venue audit log) | `/audit` (shell, tablet only) | `viewReports` (+`manageStaff` for admin rows) | `GET /audit/venue`, `GET /audit/venue.csv` |
| Struk & Tagihan printing | in-flow (table detail, cashier, sent, takeaway) | any staff (print); `editSettings` (delete venue printer) | `POST /tables/<id>/print`, `POST /printers/<id>/test` |
| Printer (scope × transport, discovery, heartbeat) | printer picker sheet | any staff (add/test); `editSettings` (delete) | `GET/POST /printers`, `PATCH/DELETE /printers/<id>` |
| Laporan Venue (Owner cloud report) | `/owner` | Firebase `owner` role | Firestore `reports/{vid}`, `report_requests/{vid}` |
| Fleet console (Super admin) | `/fleet` | Firebase `super` role | Cloud Functions in `functions/index.js` |
| Langganan (subscription notice & cutoff) | shell banner | `editSettings` (notice); none (cutoff sweep) | Firestore `venues/{vid}`, scheduled `sweepLapsedSubscriptions` |
| Pembaruan wajib (Update gate) | app-wide `Stack` layer | Main Device only (install) | Firestore `config/release_gate`, `/healthz` |

## Laporan (Reports)

**What** — The on-site aggregate report: sales, staff, menu, ops, petty cash,
membership, receivables and attendance, over a chosen date window, computed
live from the host's own Drift DB.

**Who** — Owner/admin (`viewReports`), on-site, LAN-paired.

**Where** — `AdminPage` (tablet) / phone list at `/reports`
(`lib/ui/features/admin/reports_screen.dart:33`), inside the app shell.

**How to use**
1. Open the Venue hub → **Laporan** (`context.l10n.venueHubSectionReports`).
2. Pick a range chip: **Hari ini** / **Kemarin** / **7 hari** / **30 hari** /
   **Bulan ini** / **Khusus** (custom, opens a date-range sheet, capped at 92
   inclusive days — `kCustomRangeMaxDays` in
   `lib/data/repositories/reports_repository.dart:23`, mirrored server-side as
   `_customRangeMaxDays` in `lib/server/routes/reports_routes.dart:58`).
3. Optionally filter by waiter, zone or category (three dropdown chips —
   `_filterRow` in `reports_screen.dart:296`).
4. Read the freshness dot: green + "Live" while the range includes today,
   muted + "Snapshot" once it has ended (`_freshnessDot`,
   `reports_screen.dart:154`).
5. Tap **Ekspor** to open the export sheet (see below), or the refresh icon to
   force a resync.
6. Tap a section tab to switch between the nine report sections (see below).

**Under the hood**
- Repository: `ReportsRepository` (`lib/data/repositories/reports_repository.dart:102`)
  refetches `GET /reports/snapshot` on every `reportsQueryProvider` change
  (range/server/zone/category), decoding into `ReportsSnapshotDto`.
- Server: `GET /reports/snapshot` in `lib/server/routes/reports_routes.dart:128`,
  gated `Capability.viewReports`. Reads `TableSession` + `TableSessionTicket`
  rows in the resolved `[from, to)` window (plus a same-length prior window for
  week-over-week comparisons), and computes every section in one pass — no
  second server round-trip per section.
- Tables read: `table_sessions`, `table_session_tickets`, `menu_items`,
  `menu_categories`, `zones`, `users`, `reservations`, `audit_entries` (for the
  money-audit block), plus calls into `cashReportSection`
  (`lib/server/cash.dart`), `memberReportSection` (`lib/server/members.dart`),
  `debtReportSection` (`lib/server/debts.dart`) and `shiftReportSection`
  (`lib/server/shift.dart`) for the sections those files own.
- Rendering: `ReportSectionsView` (`lib/ui/features/admin/report_sections_view.dart`,
  shared verbatim with the Owner's cloud view) and, when the venue's
  `ringkasReport` counter switch is on, a `ReportRingkas` compact card above
  it (`lib/ui/features/admin/report_ringkas.dart`, ADR-0109 §Kedai).

**The nine sections** (`_Section` enum, `report_sections_view.dart:70`,
labels from `app_id.arb`):

| Key | Indonesian label | Always available? |
|---|---|---|
| `sales` | Penjualan | yes |
| `staff` | Staf | yes |
| `menu` | Menu | yes |
| `bahan` | Bahan | only if `showStock` (owner's cloud view passes `showStock: false` — stock is a live-only concern, ADR-0036) |
| `ops` | Operasi | yes |
| `kas` | Kas kecil | yes |
| `members` | Keanggotaan | only if `snapshot.members.enabled` |
| `piutang` | Piutang | only if `snapshot.piutang.enabled` |
| `jamKerja` | Jam kerja | yes |

`Sales` carries the compact `salesKpis` (net, gross, tax+service, void),
weekday cover trend, hourly revenue histogram, and a `takeaway`/`dine-in`
split (ADR-0026); it also reads back `badDebt` (written off receivables) from
the `piutang` section so a bad debt shows as a loss against revenue already
booked (ADR-0098) — `reports_routes.dart:847-864`. `Ops` carries
turn-time, prep/pickup speed-of-service (ADR-0013/0043), a 7×12 weekday×hour
heatmap, reservation lateness/no-show, and void reasons/per-staff void
breakdown. `Menu` carries top/slow sellers, modifier attach rate, category mix
week-over-week, and a menu-engineering (star/plow/puzzle/dog) matrix plus
basket pairs.

**Offline behaviour** — The screen is entirely LAN-gated: it requires
`apiConfigProvider != null` (paired) and a live query to the host. There is no
offline cache of the report snapshot itself; a disconnected client shows the
loading/error state until reconnected.

**ADRs** — `docs/adr/0030-client-side-range-scoped-export.md` (range chip is
shared with export), `docs/adr/0032-accounting-export-real-settled-figures-on-screen-range.md`
(the on-screen tax/service KPI ties to the accounting export),
`docs/adr/0085-an-audit-event-is-structured-not-a-sentence.md` (report tiles
and void reasons ship as `key`+`args`/codes, rendered by
`lib/core/localization/report_copy.dart`, never as server-composed
Indonesian prose).

**Gotchas** — `reports_routes.dart` deliberately knows nothing about an `all`
range; that unbounded window exists only on the member report
(`members_routes.dart`), because the reports payload is per-bill and would
grow without a ceiling. `reportWindow` is public specifically so the member
routes reuse the identical rollover math — a report and the member report
disagreeing about where "yesterday" ends would put the same 02:00 bill in two
different nights.

## Report ranges & the business-day window

**What** — The shared `[from, to)` half-open window resolver every
report/export endpoint calls, anchored on the venue's own business-day start
hour rather than the calendar date.

**Where** — `reportWindow()`, `lib/server/routes/reports_routes.dart:77`.

**How it works**
- `today` = `[businessDayStart(now, hour), +1 day)`.
- `yesterday` = the business day before that.
- `d7` / `d30` = the trailing 7 or 30 business days, ending at tomorrow's
  boundary.
- `month` = calendar-month start (at the business-day hour) through
  tomorrow's boundary.
- `custom` = `from`/`to` query params parsed as calendar dates, each snapped
  to the business-day boundary (`from` → that day's start, `to` → the *next*
  day's start, since the end is exclusive), swapped if inverted, and capped at
  `_customRangeMaxDays` (92 inclusive days) measured from `start`.
- Malformed custom bounds fall back to `today`.

`businessDayStartHour` is read per-request from `venue_settings` (default
`4` — `_defaultBusinessDayStartHour`, line 19), so a trade that runs past
midnight still buckets with the night it belongs to instead of splitting at
00:00.

**Callers** — `reports_routes.dart` itself (`/reports/snapshot`,
`/orders/history`, `/reports/staff`, `/reports/accounting`), and
`members_routes.dart` reuses the same function for every preset range short
of `all` (which it resolves separately, on purpose — see Gotchas above).

**Client mirror** — `ReportRange` enum
(`lib/data/repositories/reports_repository.dart:10`) with the identical six
keys (`today|yesterday|d7|d30|month|custom`) and the identical 92-day cap
(`kCustomRangeMaxDays`), so a hand-crafted request past the client's own UI
still hits the server's independent enforcement.

**Gotcha** — Custom-range dates arrive already meaning "that calendar day's
service" (midnight-anchored), while every other preset anchors on the
business-day boundary; `reportWindow`'s inner `bod()` helper exists
specifically to reconcile the two without opening a window three hours in the
future at 01:00, which is what naively anchoring "today" on the calendar date
used to do.

## Ekspor (Export: report / orders / staff / accounting)

**What** — On-device CSV or PDF generation for four purpose-built payloads,
handed off through the Android share sheet. No file is ever rendered
server-side.

**Who** — `viewReports` (gated on both the Reports screen and the order
board, even though the order board itself is otherwise open to `takeOrder` —
export exposes historical financial data).

**Where** — `showExportSheet` (`lib/ui/core/widgets/export_sheet.dart:72`),
reached from the **Ekspor** button on `/reports`.

**How to use**
1. Tap **Ekspor**.
2. Pick a **Jenis** (kind) chip: **Laporan** / **Pesanan** / **Staf** /
   **Akuntansi**. Laporan is disabled (and the sheet defaults to Pesanan
   instead) when no in-memory report snapshot exists yet.
3. Pick **CSV** or **PDF** (PDF is the sheet's default).
4. Tap the share action; the file is written to a temp dir and handed to
   `SharePlus.instance.share`.

There is deliberately **no separate range picker inside the sheet** — every
kind reads whatever range chip (including a committed custom window) is
already active on the Reports screen.

**The four kinds** (`_ExportKind`, `export_sheet.dart:33`):

| Kind | `fileKind` slug | Server endpoint | PDF builder | CSV builder |
|---|---|---|---|---|
| Laporan | `laporan` | reuses the in-memory `/reports/snapshot` | `buildReportsPdf` | `buildReportsCsv` |
| Pesanan | `riwayat-pesanan` | `GET /orders/history?range=` | `buildOrderHistoryPdf` | `buildOrderHistoryCsv` |
| Staf | `laporan-staf` | `GET /reports/staff?range=` | `buildStaffPdf` | `buildStaffCsv` |
| Akuntansi | `akuntansi` | `GET /reports/accounting?range=` | `buildAccountingPdf` | `buildAccountingCsv` |

All four builders live in `lib/core/export/{reports,order_history,staff_report,accounting}_exporter.dart`.

**Under the hood**
- `GET /orders/history` (`reports_routes.dart:917`) returns closed visits in
  the window as a line-item tree grouped by visit, each with its receipt tree
  (`table_session_receipts`) and payment tree (`table_session_payments`,
  including `hasPhoto`/refund flags but never proof-photo bytes — those are
  fetched on demand per-photo for the PDF, ADR-0031).
- `GET /reports/staff` (`reports_routes.dart:1122`) unions everyone who ran a
  session, voided a line, *or* clocked in, into one combined row (sessions,
  covers, net, avg ticket, upsell rate, void count/%, lost rupiah, top void
  reason, attendance minutes/days/unclosed shifts) — ADR-0032's "one row per
  staff member, not two exports."
- `GET /reports/accounting` (`reports_routes.dart:1278`) computes revenue off
  the real settled `taxAmount`/`serviceAmount` columns (never a `net * 0.18`
  estimate), a payment-method breakdown with refunds on their own line, a
  per-preset discount rollup, void write-offs by reason, and a
  per-calendar-day breakdown for ledger posting.
- PDF branding: `_branding()` in `export_sheet.dart:112` builds a
  `PdfBranding` (logo + venue name/address/phone) — the **letterhead subset**
  of the venue's receipt branding block, never the customer-facing
  footer/tagline/thank-you/QR (ADR-0033).
- Filenames: `satset-<kind>-<range-slug>-<timestamp>.<ext>`
  (`exportFilename`, `lib/core/export/export_share.dart:80`).
- CSV encoding: UTF-8 with a BOM (`csvBytes`,
  `lib/core/export/export_share.dart:122`) so Excel renders `Rp` and
  Indonesian text without mojibake.

**Offline behaviour** — Same as Reports: requires a live paired connection to
fetch the underlying window payload. No queued/offline export.

**ADRs** — `docs/adr/0030-client-side-range-scoped-export.md` (client-side
generation, why not server-rendered),
`docs/adr/0031-order-export-moves-to-reports-with-bill-and-proof.md` (order
history's receipt/payment tree + on-demand photo pull),
`docs/adr/0032-accounting-export-real-settled-figures-on-screen-range.md`
(staff export is one combined row; accounting figures tie to the on-screen
KPI), `docs/adr/0033-venue-receipt-branding-block.md` (letterhead-only PDF
branding).

**Gotchas** — The live order board (`/orders`) never gains a date filter or
reloads for export — the export sheet's range is scoped entirely inside
itself so the board's real-time mental model stays untouched. A report/order
DTO shape change that affects export must be reflected in the CSV/PDF
builders by hand; nothing generates them from the DTO.

## Catatan audit (venue audit log)

**What** — The venue-wide integrity record: every act that moves money or
alters state without a straightforward sale — voids, comps, discounts,
refunds, table moves, petty-cash movements, membership acts, receivable
movements, stock counts/waste, menu kill/restore, self-order decisions, and
staff/role admin acts (gated separately). Paged back through history,
tablet-only.

**Who** — `viewReports`; admin-flavoured rows (staff/role edits) additionally
require `manageStaff`.

**Where** — `/audit` (`lib/ui/features/admin/audit_screen.dart:35`), reached
from the Venue hub. The phone route renders `_AuditPhoneNotice` instead of the
table — six columns side by side is what lets a manager scan forty rows for
the one that looks wrong, and that does not survive a phone.

**How to use**
1. Open the Venue hub → **Catatan audit**.
2. Read the six summary tiles (`_AuditTiles`,
   `audit_screen.dart:253`) — void count+rupiah, comp, discount, refund, menu
   kill, order edit — computed server-side over the *whole* filtered window,
   not just loaded rows.
3. Filter by window (**Hari ini** / **Kemarin** / **7 hari** / **Semua**) and
   optionally by one `AuditType` in the two toolbar dropdowns.
4. Scroll; new rows arriving over WebSocket while scrolled away from the head
   are held behind a **"N baru"** pill (`_NewRowsButton`) rather than
   spliced in, so the row under a manager's finger never moves mid-read.
5. Tap a row carrying a camera glyph to open its payment's proof photo
   (`_AuditProofPage`, ADR-0086) — only non-cash tenders carry one.
6. Tap **Ekspor** to pull the full (unpaged) CSV for the active filters.

**Under the hood**
- Repository: `VenueAuditRepository`
  (`lib/data/repositories/venue_audit_repository.dart:182`) — keyset-paged
  (`before` cursor on `(at, id)`, never offset), caps at `kAuditMaxLoaded =
  1000` loaded rows (line 115) with a `capped` flag distinguishing "log
  ended" from "screen stopped fetching."
- Server: `GET /audit/venue`
  (`lib/server/routes/reference_routes.dart:829`), gated `viewReports`. Page
  one only carries `summary` (`_venueAuditSummary`,
  `reference_routes.dart:201`), a server-side `{count, amount}` per
  `AuditType` over the *whole* filtered window via `GROUP BY`. Admin rows
  (`isAdminAuditType`, `lib/domain/models/audit_entry.dart:99`) are stripped
  from both the page and the summary unless the caller also holds
  `manageStaff` — a hidden count is itself a disclosure.
- Export: `GET /audit/venue.csv`
  (`reference_routes.dart:869`), same filter builder
  (`_venueAuditFilter`, `reference_routes.dart:162`), unpaged and rendered
  server-side — the client only ever holds the pages it scrolled, so a
  client-built export would silently truncate at wherever the reader stopped.
  Triggered from `exportAuditCsv`
  (`lib/core/export/audit_exporter.dart:20`) — no format picker, since a
  500-row PDF of an audit trail serves nobody.
- Proof photo: `GET /audit/payments/<id>/photo`
  (`lib/server/routes/settlement_routes.dart:1710`) — looks in both
  `table_session_payments` and the live `payments` table, because the log
  scrolls across a bill close and cannot know which side a row fell on.
- Own-shift feed: `GET /audit`
  (`reference_routes.dart:791`) is a *separate*, narrower endpoint — the
  signed-in user's own rows for the current business day, scoped from the
  bearer, never a query parameter (ADR-0065). `AuditRepository`
  (`lib/data/repositories/audit_repository.dart:23`) is its client, powering
  the personal "Saya" tab elsewhere; it is not the venue log.

**Row shape** — `AuditEntry` (`lib/domain/models/audit_entry.dart:157`):
`type` (`AuditType`, drives filter/tile/admin-split), `kind` (`AuditKind`
name, the sentence axis — see the full table below), `params` (named
strings for the sentence template), `amountCents` (a **magnitude**, never
signed — direction lives in `type`, so every void/comp/discount/refund tile
sums cleanly within its type), `actorName`/`actorRoleName` (snapshotted at
write time, live-join fallback only for rows written before schema v43), and
`paymentId` (non-null ⇒ has a proof photo, ADR-0086).

**Offline behaviour** — LAN-only; the screen requires a live paired
connection and shows nothing offline (no local cache of the venue log — it is
explicitly *not* part of the client Drift DB / offline-settlement journal
described in ADR-0123, because it is a read-and-drain-nothing venue-wide
record, not a per-visit chain).

**ADRs** — `docs/adr/0072-venue-audit-log.md` (the log itself, keyset
paging, server-side summary, admin-row gating),
`docs/adr/0085-an-audit-event-is-structured-not-a-sentence.md` (kind+params
instead of a frozen sentence),
`docs/adr/0086-proof-lives-on-the-audit-trail.md` (`payment_id` column, the
camera glyph, the report's non-cash payments card being removed in favour of
this).

**Gotchas** — Rows written before schema v43 have no amount and no actor
snapshot; the table renders `—` rather than guessing. Rows written before
ADR-0085 (`kind == null`) fall back to the frozen `title` column forever —
that sentence is genuinely what was recorded, and inventing structure for
history would be guessing at it. Rows written before v48 have no
`payment_id` and show no camera glyph — a payment that closed before v48 had
its id regenerated on close, so there is nothing left to point at.

## Full AuditKind table

`AuditKind` (`lib/domain/models/audit_kind.dart:23`) is the **sentence**
axis — one value per distinct phrasing, each rendered by an exhaustive switch
in `auditText()` (`lib/core/localization/audit_text.dart:17`). It is
persisted verbatim in `audit_entries.kind` and joined against an ARB
template in both locales at read time. **Never rename a value** — the name is
the join key; renaming one silently orphans every row already written under
the old spelling, and the reader falls back to whatever frozen Indonesian
`title` the writer composed at write time (the pre-ADR-0085 behaviour), which
is what makes a rename's damage silent rather than a crash. Adding one means
an ARB template in both locales and a new switch arm — the compiler enforces
the arm because the switch in `auditText` is exhaustive.

This is a distinct enum from `AuditType` (`lib/domain/models/audit_entry.dart:1`,
the **act/filter** axis — drives the log's type chips, its six summary tiles,
and the `isAdminAuditType` staff/role gate). One `AuditType` can be phrased
several ways as different `AuditKind`s (e.g. `billClosed` reads differently
when the bill was written off).

| AuditKind | Act it records | Key params |
|---|---|---|
| `fire` | A course was fired | `course`, `table` |
| `modify` | A line edited without changing quantity | `name` |
| `modifyQty` | A line's quantity changed | `oldQty`, `newQty`, `name` |
| `voidItem` | A line voided | `qty`, `name`, `amount` |
| `comp` | A line voided with reason `comp` (ADR-0072) | `qty`, `name`, `amount` |
| `voidItemAtTable` | Seed's flatter void phrasing, keyed by table | `name`, `table` |
| `modifyAtTable` | Seed's flatter modify phrasing | `name`, `table` |
| `tableMoved` | A visit moved tables | `src`, `tgt` |
| `paymentRecorded` | A payment was recorded | `amount`, `method`, `label` |
| `refund` | A refund (negative payment) was recorded | `amount`, `method`, `label` |
| `paymentAtTable` | Seed's flatter payment phrasing | `method`, `table` |
| `discountApplied` | A discount applied (order scope) | `name` |
| `discountAppliedLine` | A discount applied (line scope) | `name` |
| `discountRemoved` | A discount removed | `name` |
| `discountBillApplied` | A bill-scope discount applied | `name` |
| `discountBillRemoved` | A bill-scope discount removed | `name` |
| `discountAtTable` | Seed's fabricated flat discount | `percent`, `table` |
| `billReopenedReceipt` | One receipt reopened | `label` |
| `billReopened` | Whole bill reopened | `table` |
| `billClosed` | Bill closed, settled | `table` |
| `billWrittenOff` | Bill closed as walkout / write-off | `amount`, `table` |
| `settlementArrivedLate` | An offline-captured settlement act (ADR-0123) reached the host after its business day had closed | `table`, `amount`, `captured` |
| `cashToppedUp` | Petty cash isi kas | `amount` |
| `cashSpent` | Petty cash pengeluaran | `amount`, `category` |
| `cashCounted` | Petty cash opname kas | `counted`, `variance` |
| `cashReversed` | Petty cash pembatalan | `amount` |
| `stockCountClosed` | A stok opname session closed | `lines`, `variance` |
| `stockWasted` | Stock thrown away | `what`, `value` |
| `openItemSold` | An off-menu (Item bebas) line sold | `name`, `price` |
| `guestOrderAccepted` | A guest self-order accepted | `table`, `lines` |
| `guestOrderRejected` | A guest self-order rejected | `table`, `lines` |
| `guestCodesRotated` | Table QR codes remint (`Ubah semua kode`) | `tables` |
| `guestOrderingEnabled` | Self-order switched on | — |
| `guestOrderingDisabled` | Self-order switched off | — |
| `memberCreated` | A member enrolled | `name` |
| `memberDeleted` | A member deleted (anonymised) | `name` |
| `memberMerged` | Two member records merged | `from`, `to` |
| `memberPointsAdjusted` | Points hand-adjusted | `name`, `points` |
| `memberPointsRedeemed` | Points redeemed as a discount | `name`, `points`, `amount` |
| `debtCharged` | A piutang charge raised | `member`, `amount`, `bill` |
| `debtPaid` | A piutang collection | `member`, `amount`, `method` |
| `debtReversed` | A piutang charge reversed (receipt reopened) | `member`, `amount`, `bill` |
| `debtWrittenOff` | A piutang write-off (bad debt) | `member`, `amount` |
| `debtAdjusted` | A piutang hand correction (signed) | `member`, `amount` |
| `menuKilled` | Manual sold-out toggle (on) | `name` |
| `menuRestored` | Manual sold-out toggle (off) | `name` |
| `signInFailed` | A PIN attempt that opened nothing (ADR-0112) | `device`, `attempt` |
| `staffCreated` | A staff PIN user created | `name` |
| `staffDeleted` | A staff PIN user deleted | `name` |
| `staffDisabled` | A staff PIN user disabled | `name` |
| `staffEnabled` | A staff PIN user enabled | `name` |
| `staffPinSet` | A staff PIN set | `name` |
| `staffPinReset` | A staff PIN reset | `name` |
| `staffRoleChanged` | A user's role changed | `name`, `from`, `to` |
| `roleCreated` | A role created | `name` |
| `roleDeleted` | A role deleted | `name` |
| `roleColorChanged` | A role's colour changed | `name` |
| `roleRenamed` | A role renamed | `from`, `to` |
| `roleCapabilityChanged` | A role's capability set changed | `name`, `changes` |
| `venueOpened` | Buka kedai (ADR-0111) | — |
| `venueClosed` | Tutup kedai (ADR-0111) | — |
| `sampleDataLoaded` | The sample seed ran (ADR-0073) | — |

## Struk & Tagihan printing (renderers)

**What** — Two document families sharing one physical-transport machinery
but rendered by two separate, purpose-built renderers: the no-money
guest-facing **Struk** (order confirmation) and the money-carrying
**Tagihan / Struk pembayaran** (bill / receipt) pair.

**Who** — Any staff (waiter prints a Struk; cashier prints a Tagihan/Struk
pembayaran/debt slip/QR poster).

**Where** — Table detail screen, Tutup meja flow, order-sent screen (Struk);
cashier bill screen, debt-collect sheet (money docs); admin self-order screen
(table QR poster). Entry points collected in
`lib/ui/features/printing/printer_picker.dart`
(`printTableStruk`, `printBillStruk`, `printBillSelection`, `printDebtSlip`,
`printTableQr`, `printAllTableQr`).

**How to use**
1. From a table's action menu, tap **Cetak struk meja** — refuses with a
   toast if there are no sent, non-voided lines to confirm
   (`printTableStruk`, `printer_picker.dart:82`).
2. From the cashier bill screen, tap **Cetak** on the whole bill or on one
   split receipt — the state (Tagihan vs Struk pembayaran) is read off the
   document, never chosen by the cashier: no payment recorded yet ⇒ Tagihan,
   any payment recorded ⇒ Struk pembayaran. A preview sheet
   (`_PreviewSheet`, `printer_picker.dart:363`) shows exactly what will print
   before the picker opens (ADR-0066/"look before you print") — dismissing it
   prints nothing.
3. Pick a printer from the picker sheet (see Printer section below).

**Under the hood**
- `StrukRenderer.render` (`lib/core/printing/struk_renderer.dart:33`) —
  the order-confirmation slip: table/pax/time, guest name/note, lines with
  modifiers/notes, **no prices, tax, service, or total**. Used both
  server-side (venue printers) and client-side (device printers) — same
  bytes either way.
- `BillStrukRenderer.render` (`lib/core/printing/bill_struk_renderer.dart:87`) —
  the money document. Branches on `d.isDebtSlip` (piutang collection slip,
  ADR-0098 — no lines, no table, just what was taken/how/what remains owed),
  `d.isEven` (even-split reference list, price-less), and the ordinary
  itemized case (subtotal → discount → service/tax in the
  `taxAfterDiscount`-driven order → total → payment block →
  member points/punch line → `receiptOwners` block for `memberSplit`
  venues, ADR-0118). Footer QR renders only on money docs, never the
  order-confirmation Struk (ADR-0033).
- `StrukSocket.send`/`.probe` (`lib/core/printing/struk_socket.dart`) — the
  raw TCP (raw-9100) transport, shared by server and client.
- `BtPrinterService.send`/`.probe`
  (`lib/data/services/bt_printer_service.dart:28`) — the Bluetooth Classic
  (RFCOMM/SPP) transport, wrapping `print_bluetooth_thermal`, device-scope
  only.
- Both renderers read the same venue-wide receipt branding block
  (`VenueSettings`: logo, name/address — read-only, cloud-mirrored — phone,
  header, tagline, social line, footer, thank-you, footer QR + caption) —
  ADR-0033. Logo is a JPEG blob + monotonic `logoRev`, fetched via
  `GET /venue/logo`, never inlined in the settings JSON.
- Server-side rendering for a venue printer happens in
  `POST /tables/<id>/print` (`lib/server/routes/tables_routes.dart`, printer
  test in `lib/server/routes/printers_routes.dart:173`); the client only
  triggers it (`printersRepositoryProvider.printTable`,
  `lib/data/repositories/printers_repository.dart:133`).

**Offline behaviour** — Printing works fully on-LAN with no cloud
dependency. A Struk print for a table with no sendable lines refuses
client-side before any transport is attempted.

**ADRs** — `docs/adr/0020-two-scope-printers-shared-renderer.md` (one shared
renderer, two transports), `docs/adr/0033-venue-receipt-branding-block.md`
(the branding block), `docs/adr/0122-a-selection-prints-before-it-is-a-receipt.md`
(`printBillSelection` / Rincian pilihan — a tapped-but-unminted Per item
selection prints as a provisional Tagihan with no receipt letter, so it can
never be mistaken for evidence a receipt exists).

**Gotchas** — Never overload "Struk" for the money document — CONTEXT.md
treats "Struk" (order slip), "Tagihan" (pre-payment bill) and "Struk
pembayaran" (post-payment receipt) as three distinct, non-interchangeable
words in both languages. A device printer's registration does not survive a
reinstall (the bond/label lives in local prefs, not the server DB).

## Printer (scope × transport, discovery, heartbeat)

**What** — Every receipt printer the app can target, described by two
independent traits: **scope** (venue, shared / device, private to one phone)
and **transport** (wifi ESC/POS raw-9100, or Bluetooth Classic SPP). Only
three of the four combinations are legal — `venue+bluetooth` is impossible,
because the Main Device's server cannot open an RFCOMM socket to a printer
bonded to a waiter's phone.

**Who** — Any authenticated staff may add, discover, or test a printer;
**only `editSettings`** may delete a **venue** printer (shared config —
`printers_routes.dart:120`). A device printer has no shared-config authz at
all — it is local prefs on one phone.

**Where** — The print picker sheet (`_PrinterPickerSheet`,
`lib/ui/features/printing/printer_picker.dart:433`), opened inline from
every print action — never a standalone admin screen for clients (though
`/system` (admin) also lists venue printers for management).

**How to use**
1. Trigger any print action; the sheet opens and **immediately** starts
   live discovery (mDNS wifi + enumerated paired Bluetooth) — no manual "Cari
   printer" button (removed in ADR-0022).
2. Rows pop in as they resolve, deduped by address (`host:port` for wifi, MAC
   for Bluetooth), merged across venue-registered / device-registered /
   freshly-discovered-wifi / paired-Bluetooth. A registered identity wins the
   dedup and keeps its label/scope.
3. Only **online** printers are tappable; offline ones sit in a greyed
   "Offline" section; a disabled venue printer is hidden entirely.
4. Tap a row to print. Tapping an unregistered discovered wifi printer or a
   paired-but-unregistered Bluetooth printer prints immediately and lazily
   persists it as a **device** printer.
5. **Tambah manual** (wifi only — Bluetooth is added by pairing in Android
   settings) opens a dialog to name a host:port and choose venue/device
   scope.

**Under the hood**
- Discovery: `PrinterDiscoveryService.stream()`
  (`lib/data/services/printer_discovery_service.dart:45`) — mDNS browse over
  `_pdl-datastream._tcp` and `_printer._tcp`, streaming results (not a
  frozen one-shot batch) so the sheet never sits blank for 4 seconds.
- Bluetooth: `BtPrinterService`
  (`lib/data/services/bt_printer_service.dart:28`) — enumerates **only
  OS-bonded** devices (`pairedPrinters()`), never air-scans for unpaired
  ones; requests `BLUETOOTH_CONNECT` lazily on first sheet-open.
- Heartbeat (reachability, ADR-0022):
  - **Venue wifi** — the Main Device runs a periodic TCP connect-and-close
    probe on every enabled venue printer every ~15s
    (`ServerRuntime`/printer heartbeat tick), writes `lastSeenAt`, and
    broadcasts `printerUpdated` over WebSocket. Client online window is 30s
    (`_venueOnlineWindow`, `printer_picker.dart:46`) — coupled to the 15s
    server tick so a healthy printer never flips offline between two probes.
  - **Device wifi/Bluetooth** — the owning phone probes its own registered
    and discovered printers itself (`_probe`, `printer_picker.dart:506`),
    immediately on sheet-open and every 10s while it stays open. Held in
    local state only; never crosses devices.
  - A probe is **connect-only** — it never sends bytes, so reachability
    checks cannot themselves spew a struk.
- Persistence: venue printers live in the server's `printers` Drift table
  (`lib/server/db/tables.dart`), exposed via `PrintersRepository`
  (`lib/data/repositories/printers_repository.dart:16`) and broadcast over
  WS (`printerCreated`/`printerUpdated`/`printerDeleted`). Device printers
  are `DevicePrinter` (`lib/data/models/device_printer.dart:24`), persisted
  in `SharedPreferences` via `devicePrintersProvider`.
- Server routes: `GET/POST /printers`, `PATCH/DELETE /printers/<id>`,
  `POST /printers/<id>/test` — all in `printers_routes.dart:78`. Add/test is
  gated by `_requireAuth` (any valid staff bearer); patch/delete by
  `_requireCap(..., Capability.editSettings)`.
- Test print is a **real** ESC/POS slip (`StrukRenderer.renderTest`), not a
  stub — "connected" means the socket write actually succeeded
  (ADR-0020's original stub only bumped `lastSeenAt` on a fake success).

**Offline behaviour** — Printer discovery and printing are pure LAN/Bluetooth
operations, work fully without internet, and are unaffected by the
offline-settlement journal (ADR-0123) — a print job is not a queued intent;
it either succeeds against a reachable transport now or the picker shows it
offline.

**ADRs** — `docs/adr/0020-two-scope-printers-shared-renderer.md` (original
two-scope model, wifi-only, deferred Bluetooth),
`docs/adr/0022-bluetooth-printers-live-discovery-and-heartbeat.md`
(supersedes 0020: Bluetooth ships, auto-discovery on open, the heartbeat
model, "online means a heartbeat answered" replacing the old test-print-only
dot).

**Gotchas** — `venue+bluetooth` must be rejected in the add flow — it is a
structurally impossible combination, not merely discouraged. Device printers
carry no server-side audit trail; only venue prints can be stamped
server-side. The venue `printers` table's `kind` column is vestigial
post-ADR-0022 (venue can never be Bluetooth) — only `DevicePrinter` gained a
`transport` field.

## Laporan Venue (Owner cloud report snapshot)

**What** — A read-only, off-site view of one venue's aggregate report,
published by the host into Firestore on a fixed cadence, for a stakeholder
who has no LAN access to the venue at all.

**Who** — Firebase `owner` role (`admins/{uid}.role == 'owner'`), bound to
one `venueId`. Never pairs, never runs a local server, never touches Drift.

**Where** — `/owner` (`lib/ui/features/owner/owner_report_screen.dart:28`),
diverted to at Firebase login (before the pair gate), same as `super` →
`/fleet`.

**How to use**
1. Sign in with an owner Firebase account.
2. Land directly on `OwnerReportScreen` — no pairing, no PIN.
3. Read the freshness line (`_freshnessLine`, `owner_report_screen.dart:268`)
   — "Diperbarui N menit lalu" or a pending state if a refresh was
   requested and no newer `generatedAt` has landed within 2 minutes.
4. Switch between the two published ranges: **Hari ini** / **7 hari**
   (`kOwnerReportRanges`, `lib/data/services/owner_report_service.dart:23`
   — no arbitrary date-picking off-site).
5. Tap the refresh icon to request an on-demand republish (debounced 30s,
   `_refreshCooldown`, line 42).
6. Scroll the same `ReportSectionsView` the on-site admin sees (`showStock:
   false` — no live stock section off-site), followed by
   `OwnerMoneyAuditBlock` — the money half of the venue log, published
   because the owner has no route to `/audit` at all.

**Under the hood**
- Publish side (host, Server mode): `OwnerReportPublisher`
  (`owner_report_service.dart:78`) fetches `/reports/snapshot` for each of
  the two ranges on server start/stop and every `kOwnerReportInterval` = 30
  minutes, writes to `reports/{vid}`, and listens on `report_requests/{vid}`
  for a manual-refresh command newer than its own last publish.
- Read side (owner device): `OwnerReportService.watch(vid)`
  (line 199) streams `reports/{vid}`; `requestRefresh(vid)` stamps
  `report_requests/{vid}.requestedAt`.
- Firestore array-of-array workaround: `encodeNestedForFirestore`/`decodeNestedFromFirestore`
  (`owner_report_service.dart:39`) wrap any list-inside-a-list (the report's
  7×12 hourly heatmap) in a `{$list: [...]}` map — Firestore rejects nested
  arrays outright, and this bug silently killed **every** owner publish
  before the wrap was added, taking sales/staff/menu down with the offending
  field.
- Open-debt field: the publisher also writes `openDebt` beside the ranges —
  read by the Fleet console's `updateVenue` callable to refuse removing the
  `members` module while a venue still owes money (see Fleet console below).
  Absent reads as zero (fail-open) — a host that cannot answer must not be
  able to block its own operator.
- Money-audit block: `OwnerMoneyAuditBlock`
  (`lib/ui/features/owner/owner_money_audit_block.dart:26`) — rows from
  `moneyAudit` in the snapshot (`amountCents IS NOT NULL`, newest 500 per
  range, `truncated` flag), rendered via the same `auditText()` resolver as
  the on-site log, but with **no tap target and no proof photos** — the
  bytes never leave the LAN.

**Offline behaviour** — The owner is entirely cloud-mediated and has no
offline path of its own; the *host*'s publish loop tolerates the venue being
offline (a refresh request simply waits, and the owner sees a stale
`generatedAt` rather than a hanging spinner).

**ADRs** — `docs/adr/0036-owner-cloud-report-snapshot.md` (the whole
feature — publish path, refresh command, floor-powerless exclusions),
`docs/adr/0086-proof-lives-on-the-audit-trail.md` (amends 0036: the removed
non-cash-payments report card is replaced by the money-audit block).

**Gotchas** — The owner's entire Firestore footprint is read-`reports/{vid}`
+ write-`report_requests/{vid}.requestedAt` — no `venues/{vid}` read at all;
freshness/offline is derived purely from `generatedAt` not advancing. An
owner doc counts toward the Fleet console's venue-delete guard (a venue with
an owner attached cannot be deleted). Since ADR-0077 retired the
admin-client door, the owner role is also the *only* remaining way to check
a venue's numbers from off the LAN — a single-person venue that wants this
needs a second email address, because Firebase Auth is one account per
email and the admin/owner roles cannot share one.

## Fleet console (Super admin)

**What** — The cloud control plane for the whole SatSet customer base: an
urgency-sorted list of every venue, per-venue subscription/module/admin
management, the global release gate override, and a fleet-wide audit trail.

**Who** — Firebase `super` role (`admins/{uid}.role == 'super'`). No venue,
no local server, no pairing, no Drift — purely Firebase Auth + Firestore +
Cloud Functions.

**Where** — `/fleet`
(`lib/ui/features/fleet/fleet_console_screen.dart:48`), diverted to at
Firebase login. Per-venue detail lives one level down in
`VenueEditScreen` (`lib/ui/features/fleet/venue_edit_screen.dart`).

**How to use**
1. Sign in with a super-admin Firebase account.
2. Land on the venue list — the kicker line reads "N of M online"
   (`context.l10n.fltOnlineOf`).
3. Once the fleet holds ≥6 venues, a search box and three lens chips appear
   (**Semua** / trouble / billing / off) — the lenses overlap deliberately
   (a lapsed venue can show under both "trouble" and "billing").
4. The list is grouped into four bands by urgency rank — **Trouble** (kill
   lockout risk, past cutoff, or overdue), **Ending** (subscription ending
   soon), **Idle**, **Running** — trouble sorted to the top.
5. Tap a tile to open `VenueEditScreen` for identity, billing, module and
   account management; use the tile's `⋮` menu for the fast-path kill switch
   (**Aktifkan**/**Tangguhkan**) without opening the venue first.
6. Toolbar actions: **+ Venue** (name/address/plan only — term and price
   belong to the editor), the update-alt icon for the **release gate**
   override dialog, and sign-out.

**Under the hood**
- All reads are live Firestore, gated by an `isSuper()` security rule that
  `get()`s the caller's own `admins/{uid}` doc.
- **Every mutation goes through a Cloud Functions callable** (`functions/index.js`,
  server-enforced authz via `assertSuper()`, line 129) — the client never
  writes `venues/{}` or `admins/{}` directly:

| Callable | Line | What it does |
|---|---|---|
| `createAdmin` | `functions/index.js:265` | Creates a Firebase Auth user + `admins/{uid}` doc, role ∈ {`admin`,`owner`}; caps one **active** `admin` per venue (ADR-0077) |
| `setAdminStatus` | `:346` | Flips `active`/`suspended`, mirrors onto the Auth user's `disabled` flag; re-enforces the one-active-admin cap on this door too |
| `deleteAdmin` | `:383` | Deletes the Auth user + doc, best-effort on an already-gone user |
| `resetAdminPassword` | `:419` | Mints an 8-digit dictated temp password (ADR-0075), sets `mustChangePassword` |
| `changeOwnPassword` | `:462` | The admin's own self-service password change; clears `mustChangePassword` |
| `sweepExpiredTempPasswords` | `:509` | Hourly `onSchedule`: re-randomizes any temp password past `OTP_TTL_MS` (24h) |
| `sweepLapsedSubscriptions` | `:561` | Hourly `onSchedule`: auto-suspends `active` venues past their billing cutoff (ADR-0076) |
| `createVenue` | `:598` | Creates `venues/{vid}`; a `trial` starts holding every module (ADR-0108) |
| `updateVenue` | `:631` | Edits name/address/`addOns`/`counterConfig`; refuses removing `members` while `venueOpenDebt(vid) > 0` |
| `setVenueStatus` | `:694` | The kill switch — `active`/`suspended` |
| `setVenueBilling` | `:711` | Sets `plan`/`billingCycle`/`priceMonthly`/`trialStartAt`/`paidUntil` |
| `setReleaseGate` | `:776` | Writes `config/release_gate` (`min`/`recommended`/`latest`), enforcing `min ≤ recommended ≤ latest` on the merged result |
| `deleteVenue` | `:819` | Refuses while the venue still has any `admins` doc |

- Every mutating callable writes a `fleet_audit/{id}` row via
  `writeFleetAudit()` (`functions/index.js:197`) — best-effort, never rolls
  back the mutation on a failed audit write, and never carries a credential
  (a password reset audits the email, never the digits).
- Module keys (`MODULES = ['members', 'selfOrder']`) and mode keys
  (`MODE_MODULES = ['counterService', 'bypassKds', 'memberSplit']`) are
  persisted strings under the same never-rename rule as `AuditKind`
  (`functions/index.js:34-60`).

**Offline behaviour** — None. The super admin is online-only by design; every
mutation is a network round trip, and Firestore's own cache serving the read
side offline is the only tolerance.

**ADRs** — `docs/adr/0016-fleet-superadmin-cloud-control-plane.md` (the
console itself, the venue-becomes-cloud-entity move, Cloud-Functions-only
mutations), `docs/adr/0018-cloud-owned-venue-identity-mirror.md` (venue
name/address mirror into the host's local `VenueSettings`),
`docs/adr/0059-password-recovery-goes-through-the-developer.md`,
`docs/adr/0075-dictated-temporary-password.md` (the OTP flow),
`docs/adr/0077-one-admin-one-device.md` (one active admin per venue,
admin-client retirement).

**Gotchas** — `plan` selects which billing rules apply; it gates **no
feature** inside the venue (the embedded server knows nothing about the
cloud plan) — entitlement is the orthogonal `addOns`/module axis (ADR-0107,
outside this area's scope but touched by `updateVenue`). `banned` was
removed as a status (`STATUSES = ['active', 'suspended']`) — an existing
`status: 'banned'` doc parses to `unknown` and stays blocked, since every
gate tests `isActive`.

## Langganan (subscription notice & cutoff)

**What** — The venue-side half of billing: a shell banner telling the
venue's own admin its subscription is ending or lapsed, and the hourly sweep
that actually suspends a lapsed venue.

**Who** — Notice is gated `editSettings` (commercial, not operational —
unlike the ungated offline-grace banner beside it); the cutoff sweep runs
unattended.

**Where** — `VenueBillingBanner`, third in the shell banner stack under
`AdminGraceBanner` and above `UpdateBanner`.

**How to use** — Nothing to operate; the banner appears automatically when
the live `venues/{vid}` snapshot the eligibility listener already holds
crosses a threshold, and taps through to WhatsApp with the venue's name and
id prefilled — there is no in-app payment.

**Under the hood**
- **Trial**: cuts off on `paidUntil` exactly, no grace — "going dark is what
  a trial is for."
- **Partner**: cuts off `fleetGraceAfterLapse` (7 days) after `paidUntil` —
  half the 14-day warning window (`fleetRenewWarn`), so 14 days of banner
  before the date plus 7 after is three weeks of visible notice before a
  service interruption.
- `paidUntil == null` never lapses.
- The sweep (`sweepLapsedSubscriptions`, `functions/index.js:561`) flips
  `status` to `suspended`; **`Aktifkan` is disabled in the Fleet console
  while a venue is past its cutoff+grace** — the only way back is a future
  `paidUntil`, which removes the need for any `autoSuspendedAt` bookkeeping
  to stop the sweep re-firing on a venue an operator has since revived.
- Every automatic cutoff writes `fleet_audit` with `actorUid: 'system'`,
  action `autoSuspendVenue`.

**Offline behaviour** — The banner reads from Firestore's own offline cache
(the eligibility listener the venue already holds), so it survives a network
drop showing the last-known state; the sweep itself is server-side and
unaffected by any one venue's connectivity.

**ADRs** — `docs/adr/0074-venue-subscription-notice-without-enforcement.md`
(superseded — mirroring stands, "no enforcement" invariant does not),
`docs/adr/0076-two-plans-and-a-subscription-that-cuts-off.md` (two plans,
`billingStatus` deleted, the actual cutoff, `banned` removed).

**Gotchas** — `billingStatus` no longer exists as a field — it was deleted
specifically because it could disagree with `paidUntil` (the worst state the
console could hold: "paid" with a date three weeks gone, healthy on every
surface, billing nobody). A trial gets **no** grace window on purpose — a
grace window on trials would make the stated end date not the end date.

## Pembaruan wajib (Update gate)

**What** — A three-tier version floor (`min`/`recommended`/`latest`) in one
global Firestore doc, enforced as a non-dismissible full-app block below
`min` and a persistent host-only nag between `min` and `latest`.

**Who** — Every device is subject to the block; only the Main Device (the
one running the embedded server) can act on either the block or the nag —
every other device is told to fetch an admin.

**Where** — `UpdateBlock` (`lib/ui/core/widgets/update_block.dart:27`), a
`Stack` layer above the router in the app builder (not a pushed route, not a
redirect-ladder rung); `UpdateBanner`
(`lib/ui/core/widgets/update_banner.dart:26`) in the shell banner stack.

**How to use**
- **Below `min`**: the app is covered immediately, wherever the user is, by
  a non-dismissible `PopScope(canPop: false)` block naming the installed and
  minimum versions. On the Main Device, a **Perbarui** button downloads the
  APK and hands it to Android's installer (`appUpdateServiceProvider`); every
  other device sees "minta admin memperbarui perangkat ini."
- **Between `recommended` and `latest`**: only the Main Device sees a quiet
  shell banner ("Versi X tersedia · Anda di Y") with the same install action,
  no sheet, no snooze, no release notes.

**Under the hood**
- `ReleaseGate` domain model (`lib/domain/models/release_gate.dart:27`) —
  three plain `MAJOR.MINOR.PATCH` strings; **an absent or unparseable side
  always compares equal**, never lesser — so a missing floor can never read
  as "below everything."
- `verdictFor(installed)` → `UpdateVerdict.none | .recommended | .blocked`.
  Everything unknown fails open — no doc, no network, an unparseable version
  all resolve to `none`.
- `ReleaseGateRepository`
  (`lib/data/repositories/release_gate_repository.dart:28`) — **only the
  host reads Firestore** (`config/release_gate`, live listener); every other
  device learns the gate from the host, once at bootstrap via the
  unauthenticated `GET /healthz` (`lib/server/routes/health_routes.dart:20`)
  and then live on the `release.gate` WebSocket broadcast
  (`WsEventTypes.releaseGate`). The gate is cached to `SharedPreferences` so
  a blocked device stays blocked across a restart and across losing its
  host.
- Write side: Codemagic's `/push-deploy` writes `config/release_gate` from
  the release tag's severity suffix (`v1.2.0` → `latest` only; `-recommended`
  → also `recommended`; `-breaking` → also `min`), **after** the GitHub
  Release publishes successfully — never before, since a floor rising while
  the APK is still uploading points the whole fleet at a download that does
  not exist. The Fleet console's release-gate dialog
  (`ReleaseGateDialog`, `fleet_console_screen.dart:783`) is the only
  correction that reaches a venue nobody can drive to.
- Comparison is on `versionName` alone (`package_info_plus`); the build
  number is invisible to the gate.
- The block never tears down the embedded server — a blocked host that
  stopped serving would tell every client "host offline" instead of "fetch
  an admin," the wrong instruction at the worst moment.

**Offline behaviour** — An unpaired client has no gate at all and is never
blocked (it has no host to have heard from). A paired client persists the
last gate it saw and stays gated (or ungated) with the host down.

**ADRs** — ADR-0130 (the whole feature) and ADR-0131 (the reversal: every
device installs, the host mirrors the APK over the LAN, the `/me` version
line becomes the pull surface). ADR-0130 was numbered 0087 until the
collision with `0087-permissions-are-edited-one-role-at-a-time.md` was
resolved; a pre-0131 comment citing "ADR-0087" for the update gate means
0130.

**Gotchas** — `min` is a **policy** floor, not a wire-compatibility floor —
the LAN protocol is unaffected, and the host never rejects a client for its
version. This is deliberately harsher than the offline-grace lock elsewhere
in the app, which only bites on restart; a mis-tagged `-breaking` darkens
every venue mid-service, and the console override is the mitigation, not a
cure. A per-venue floor was explicitly rejected — the gate is fleet-wide,
because it states which builds are acceptable anywhere, not a staged-rollout
schedule.
