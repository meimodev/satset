import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/models/member_report_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the three membership exports (ADR-0137).
///
/// One file for all three because they share every helper and one of them —
/// the ranked list — is the header block of another. Splitting them would put
/// the same date formatter and the same "how a share is spelled" decision in
/// two places, which is how two files describing the same window stop agreeing.
///
/// Nothing here fetches. Each builder is handed a payload that came from an
/// **uncapped export endpoint**, never from the screen's own capped snapshot —
/// that separation is the whole point of the ADR, and a builder that reached
/// for a repository could quietly undo it.
///
/// The directory is **CSV only**. A two-thousand-row roster rendered as a PDF
/// is a document nobody reads and a tablet that runs out of memory trying; the
/// audit log's export makes the same call for the same reason. The two report
/// exports carry both, because a window's numbers are something a venue files.

/// Which export a file is, as the slug that goes into its name.
///
/// The slugs stay Indonesian in both languages, like every other export kind:
/// a filename is part of how a venue files a document, and a download whose
/// name changes with a device setting is not the same download.
///
/// They live here rather than on the sheet that spells them because
/// `design_tokens_test.dart` bans an Indonesian word in a Dart literal under
/// `lib/ui` — rightly, since that is how copy skips the ARB. A filename is not
/// copy, and the file that builds the file is where its name belongs.
enum MemberExportKind {
  directory('pelanggan'),
  ranked('laporan-pelanggan'),
  history('riwayat-pelanggan');

  const MemberExportKind(this.slug);
  final String slug;
}

/// `satset-laporan-pelanggan-30-hari-20260905-1432.csv`. Pass an empty
/// [rangeSlug] for the directory, which is a roster and has no window.
String memberExportFilename(
  MemberExportKind kind,
  ExportFormat format, {
  String rangeSlug = '',
}) => exportFilenameSlug(kind: kind.slug, slug: rangeSlug, format: format);

/// Why an export did not happen, in the venue's words.
///
/// Three outcomes and they are genuinely different acts, so they get three
/// sentences: **413** is the ceiling, and the only one with a fix the reader
/// can act on — narrow the window or the filters. Anything that is not an
/// [ApiException] at all never reached the host, which on this screen means the
/// directory is being served from the [[Salinan pelanggan]]; the copy says so,
/// because "export failed" would leave a reader retrying a button that cannot
/// work until the host is back.
///
/// The ceiling is read out of the refusal body rather than pinned client-side:
/// the number lives on the server, and a second copy here would be the one that
/// goes stale.
String memberExportError(AppL10n l, Object e) {
  if (e is! ApiException) return l.memExpErrOffline;
  if (e.statusCode == 413) {
    var limit = 0;
    try {
      limit = ((jsonDecode(e.body) as Map)['limit'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Body was not the JSON we expected; the sentence still reads with 0.
    }
    return l.memExpErrTooLarge(limit);
  }
  return l.memExpErrFailed;
}

/// Built per call: a cached [DateFormat] freezes whichever locale was active
/// the first time it was touched (ADR-0084).
DateFormat get _day => DateFormat('d MMM yyyy');
DateFormat get _stamp => DateFormat('d MMM yyyy, HH:mm');

String _dayOf(DateTime? t) => t == null ? '' : _day.format(t.toLocal());
String _stampOf(DateTime? t) => t == null ? '' : _stamp.format(t.toLocal());

/// `3/10`, or empty when the venue runs no punch card. Empty rather than `0/0`:
/// a column of zeroes reads as "nobody has any stamps" instead of "there is no
/// stamp program", and those are different facts.
String _punch(MemberDto m) =>
    m.punchTarget <= 0 ? '' : '${m.member.punchProgress}/${m.punchTarget}';

// ─── directory ──────────────────────────────────────────────────────────────

/// The filters the file was taken under, spelled out for its header.
///
/// A roster export carries its filters (ADR-0137) — "the members who have not
/// come back in ninety days" is the reason an owner takes one — so the file has
/// to say which members it is, or the next reader cannot tell a filtered export
/// from a shrinking membership.
String memberFilterLine(
  AppL10n l, {
  String query = '',
  int? birthdayMonth,
  int? lapsedDays,
}) {
  final parts = <String>[
    if (query.trim().isNotEmpty) '${l.memExpFilterSearch}: ${query.trim()}',
    if (birthdayMonth != null)
      '${l.memFieldBirthday}: ${DateFormat('MMMM').format(DateTime(2000, birthdayMonth))}',
    if (lapsedDays != null) '${l.memLapsedLabel}: $lapsedDays',
  ];
  return parts.isEmpty ? l.memExpFilterNone : parts.join(' · ');
}

/// The nine enrolment columns first, in the order the CSV **importer** reads
/// them, then everything the venue derived afterwards.
///
/// Deliberately not a promise of round-trip: the words are localised like every
/// other export's headers (ADR-0083), and the derived tail is not importable at
/// all. What the shared order buys is a person opening both files in the same
/// spreadsheet and recognising the left-hand half.
List<String> _dirHeaders(AppL10n l) => [
  l.memFieldName,
  l.memFieldPhone,
  l.memFieldBirthday,
  l.memFieldNote,
  l.memFieldKabupaten,
  l.memFieldKecamatan,
  l.memFieldKelurahan,
  l.memFieldStreet,
  l.memColDebtLimit,
  l.memExpColCode,
  l.memColPoints,
  l.memColPunch,
  l.memColDebt,
  l.memColVisits,
  l.memColLifetime,
  l.memExpColLastVisit,
  l.memColJoined,
];

List<String> _dirRow(MemberDto m) {
  final a = m.member.address;
  return [
    m.member.name,
    m.member.phone,
    _dayOf(m.member.birthday),
    m.member.note ?? '',
    a.kabupaten ?? '',
    a.kecamatan ?? '',
    a.kelurahan ?? '',
    a.text ?? '',
    // Raw digits, not formatted rupiah: this column mirrors an import field,
    // and `Rp 1.000.000` is not a number a spreadsheet will add up.
    '${m.member.debtLimit}',
    m.member.code,
    '${m.member.points}',
    _punch(m),
    '${m.member.debt}',
    '${m.member.visitCount}',
    '${m.member.lifetimeSpend}',
    _dayOf(m.member.lastVisitAt),
    _dayOf(m.member.joinedAt),
  ];
}

String buildMemberDirectoryCsv(
  AppL10n l,
  List<MemberDto> members, {
  required String filterLine,
  DateTime? at,
}) => [
  csvRow([l.memExpDirTitle]),
  csvRow([l.memExpTaken, _stampOf(at ?? SatClock.now())]),
  csvRow([l.memExpFilters, filterLine]),
  csvRow([l.memExpRows, '${members.length}']),
  '',
  csvRow(_dirHeaders(l)),
  for (final m in members) csvRow(_dirRow(m)),
].join('\r\n');

// ─── ranked list ────────────────────────────────────────────────────────────

/// The KPI block, as label/value pairs. Same figures and same words as the
/// tiles on screen — they read off the same DTO, so a file and the screen it
/// came from cannot disagree about how many members came back.
List<List<String>> _rankSummary(AppL10n l, MemberReportDto r) => [
  [l.mrpKpiNew, '${r.enrolled}'],
  [l.mrpKpiActive, '${r.activeMembers}'],
  [l.mrpKpiReturn, '${r.returningMembers}'],
  [l.memExpTotalEnrolled, '${r.enrolledTotal}'],
  [l.memExpIdle, '${r.idleMembers}'],
  [l.mrpMemberBills, '${r.memberBills}'],
  [l.mrpKpiSpend, formatIDR(r.memberNet)],
  [l.mrpGuestBills, '${r.guestBills}'],
  [l.mrpGuestNet, formatIDR(r.guestNet)],
  [l.mrpKpiAvg, formatIDR(r.avgMemberBill)],
  if (r.splitEnabled) [l.mrpSplitBills, '${r.splitBills}'],
  if (r.pointsEnabled) ...[
    [l.mrpPointsEarned, '${r.pointsEarned}'],
    [l.mrpPointsRedeemed, '${r.pointsRedeemed}'],
    [l.mrpPointsAdjusted, '${r.pointsAdjusted}'],
    [l.mrpKpiPoints, '${r.pointsOutstanding}'],
    [l.memExpLiability, formatIDR(r.liabilityEstimate)],
  ],
];

List<String> _rankHeaders(AppL10n l) => [
  l.memFieldName,
  l.memFieldPhone,
  l.mrpSortVisits,
  l.mrpSortSpend,
  l.mrpSortPoints,
  l.memExpColLastVisit,
];

List<String> _rankRow(MemberTradeDto m) => [
  m.name ?? '',
  m.phone ?? '',
  '${m.visits}',
  formatIDR(m.spend),
  '${m.points}',
  _dayOf(m.lastVisitAt),
];

String buildMemberRankedCsv(
  AppL10n l,
  MemberReportDto report,
  List<MemberTradeDto> rows, {
  required String windowLabel,
  required String sortLabel,
}) => [
  csvRow([l.mrpTitle]),
  csvRow([l.memExpWindow, windowLabel]),
  csvRow([l.memExpSortedBy, sortLabel]),
  csvRow([l.memExpRows, '${rows.length}']),
  '',
  csvRow([l.memExpSecSummary]),
  for (final pair in _rankSummary(l, report)) csvRow(pair),
  '',
  csvRow(_rankHeaders(l)),
  for (final m in rows) csvRow(_rankRow(m)),
].join('\r\n');

Future<Uint8List> buildMemberRankedPdf(
  AppL10n l,
  MemberReportDto report,
  List<MemberTradeDto> rows, {
  required String windowLabel,
  required String sortLabel,
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader('${l.mrpTitle} · $windowLabel'),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.mrpTitle,
          subtitle: windowLabel,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            '${l.memExpSortedBy}: $sortLabel',
            '${l.memExpRows}: ${rows.length}',
          ],
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.memExpSecSummary),
        pdfTable(
          l,
          headers: [l.memExpSecSummary, l.mrpColValue],
          rows: _rankSummary(l, report),
          numericFrom: 1,
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.memExpKindRanked),
        pdfTable(
          l,
          headers: _rankHeaders(l),
          rows: [for (final m in rows) _rankRow(m)],
          numericFrom: 2,
        ),
      ],
    ),
  );
  return doc.save();
}

// ─── one member's history ───────────────────────────────────────────────────

/// Who the file is about. Falls back to the id when the directory row is gone —
/// a deleted member leaves their trade behind (ADR-0092), and this export is
/// one of the two places that trade is read back.
String memberHistoryHeading(AppL10n l, MemberHistoryDto h) {
  final m = h.member;
  final name = (m?['name'] as String?) ?? '';
  final phone = (m?['phone'] as String?) ?? '';
  if (name.isEmpty && phone.isEmpty) return l.mrpDeleted;
  return [name, phone].where((s) => s.isNotEmpty).join(' · ');
}

List<List<String>> _historySummary(AppL10n l, MemberHistoryDto h) => [
  [l.mrpStatVisits, '${h.visits}'],
  [l.mrpStatSpend, formatIDR(h.spend)],
  [l.mrpStatItems, '${h.units}'],
  [l.mrpKpiAvg, formatIDR(h.avgBill)],
  if (h.untrackedSpend > 0)
    [l.memExpUntracked, formatIDR(h.untrackedSpend)],
];

/// A share is only worth naming when the bill was actually split — on a bill
/// held alone, "pemilik" is a word that says nothing, exactly as the screen
/// decides not to draw the badge.
///
/// Which is why the column comes and goes with the document: a venue that does
/// not split bills would otherwise carry a header and forty blank cells in
/// every file it ever exports. A table cannot drop a cell per row the way the
/// screen drops a badge, so the whole column stands down when nothing in the
/// window was shared.
bool _anySplit(MemberHistoryDto h) => h.bills.any((b) => b.shared);

List<String> _billHeaders(AppL10n l, {required bool split}) => [
  l.mrpColWhen,
  l.mrpColTable,
  l.memExpColPax,
  l.mrpColValue,
  l.mrpColShare,
  if (split) l.memExpColOwner,
  l.memExpColUnits,
];

List<String> _billRow(AppL10n l, MemberBillDto b, {required bool split}) => [
  _stampOf(b.closedAt),
  b.tableLabel ?? '',
  '${b.pax}',
  formatIDR(b.billTotal),
  formatIDR(b.share),
  if (split) (b.shared ? (b.owner ? l.mrpBillOwner : l.mrpBillGuestOf) : ''),
  '${b.units}',
];

List<String> _productHeaders(AppL10n l) => [
  l.mrpColItem,
  l.mrpColQty,
  l.mrpColValue,
  l.mrpColLast,
];

List<String> _productRow(MemberProductDto p) => [
  p.name,
  '${p.qty}',
  formatIDR(p.spend),
  _dayOf(p.lastAt),
];

String buildMemberHistoryCsv(
  AppL10n l,
  MemberHistoryDto h, {
  required String windowLabel,
}) => [
  csvRow([l.memExpHistTitle]),
  csvRow([l.memFieldName, memberHistoryHeading(l, h)]),
  csvRow([l.memExpWindow, windowLabel]),
  '',
  csvRow([l.memExpSecSummary]),
  for (final pair in _historySummary(l, h)) csvRow(pair),
  '',
  csvRow([l.mrpTabVisits]),
  csvRow(_billHeaders(l, split: _anySplit(h))),
  for (final b in h.bills) csvRow(_billRow(l, b, split: _anySplit(h))),
  '',
  csvRow([l.mrpTabProducts]),
  csvRow(_productHeaders(l)),
  for (final p in h.products) csvRow(_productRow(p)),
].join('\r\n');

Future<Uint8List> buildMemberHistoryPdf(
  AppL10n l,
  MemberHistoryDto h, {
  required String windowLabel,
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final who = memberHistoryHeading(l, h);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader('$who · $windowLabel'),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.memExpHistTitle,
          subtitle: who,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            '${l.memExpWindow}: $windowLabel',
            '${l.mrpStatVisits}: ${h.visits}',
            '${l.mrpStatSpend}: ${formatIDR(h.spend)}',
          ],
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.memExpSecSummary),
        pdfTable(
          l,
          headers: [l.memExpSecSummary, l.mrpColValue],
          rows: _historySummary(l, h),
          numericFrom: 1,
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.mrpTabVisits),
        pdfTable(
          l,
          headers: _billHeaders(l, split: _anySplit(h)),
          rows: [
            for (final b in h.bills) _billRow(l, b, split: _anySplit(h)),
          ],
          numericFrom: 2,
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.mrpTabProducts),
        pdfTable(
          l,
          headers: _productHeaders(l),
          rows: [for (final p in h.products) _productRow(p)],
          numericFrom: 1,
        ),
      ],
    ),
  );
  return doc.save();
}
