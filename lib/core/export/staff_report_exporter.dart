import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the staff-focus export (ADR-0032). One combined row
/// per staff member — productivity + sales + integrity together. CSV is the
/// wide table verbatim; the PDF renders it as a single landscape table because
/// the columns do not fit a portrait page.

/// Built per call: a cached [DateFormat] freezes whichever locale was active
/// when it was first touched (ADR-0084).
DateFormat get _dateFull => DateFormat('d MMM yyyy, HH:mm');
DateFormat get _dateShort => DateFormat('d MMM yyyy');

String _windowLine(StaffReport s) =>
    '${_dateShort.format(s.rangeFrom.toLocal())} – ${_dateShort.format(s.rangeTo.toLocal())}';

/// `voidPct` arrives as a percent number (e.g. 2.1); `upsellRate` as a
/// fraction (e.g. 0.14).
String _pctNum(double v) => '${v.toStringAsFixed(1)}%';
String _pctFrac(double v) => '${(v * 100).round()}%';

List<String> _headers(AppL10n l) => [
  l.expColName,
  l.expColSessions,
  l.expColCover,
  l.expColItem,
  l.expNet,
  l.expColAvgBill,
  l.expColUpsellPct,
  l.expColVoidCount,
  l.expColVoidPct,
  l.expColLostVoid,
  l.expColTopReason,
];

List<String> _row(AppL10n l, StaffReportRow r) => [
  r.name,
  '${r.sessions}',
  '${r.covers}',
  '${r.items}',
  formatIDR(r.net),
  formatIDR(r.avgTicket),
  _pctFrac(r.upsellRate),
  '${r.voidCount}',
  _pctNum(r.voidPct),
  formatIDR(r.lostRupiah),
  r.topReasonCode == null ? '—' : voidReasonLabel(l, r.topReasonCode!),
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildStaffCsv(AppL10n l, StaffReport s) {
  final rows = <String>[];
  rows.add(csvRow([l.expStaffCsvTitle]));
  rows.add(
    csvRow([
      l.expPeriod,
      rangeLabel(l, s.range, from: s.rangeFrom, to: s.rangeTo),
    ]),
  );
  rows.add(csvRow([l.expRange, _windowLine(s)]));
  rows.add(csvRow([l.expGenerated, _dateFull.format(s.generatedAt.toLocal())]));
  rows.add('');
  rows.add(csvRow(_headers(l)));
  for (final r in s.rows) {
    rows.add(csvRow(_row(l, r)));
  }
  rows.add('');
  rows.add(
    csvRow([
      l.expTotalRow,
      '',
      '',
      '',
      formatIDR(s.net),
      '',
      '',
      '${s.voidCount}',
      '',
      formatIDR(s.lostRupiah),
      '',
    ]),
  );
  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildStaffPdf(
  AppL10n l,
  StaffReport s, {
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final range = rangeLabel(l, s.range, from: s.rangeFrom, to: s.rangeTo);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme, landscape: true),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(l.expStaffHeader(range)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.expStaffTitle,
          subtitle: range,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            l.expMetaRange(_windowLine(s)),
            l.expMetaGenerated(_dateFull.format(s.generatedAt.toLocal())),
            l.expStaffSortNote,
          ],
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.expStaffPerformance),
        pdfTable(
          l,
          headers: _headers(l),
          rows: [for (final r in s.rows) _row(l, r)],
          numericFrom: 1,
        ),
      ],
    ),
  );

  return doc.save();
}
