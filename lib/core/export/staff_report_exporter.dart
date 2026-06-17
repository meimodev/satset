import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the staff-focus export (ADR-0032). One combined row
/// per staff member — productivity + sales + integrity together. CSV is the
/// wide table verbatim; the PDF renders it as a single landscape table because
/// the columns do not fit a portrait page.

final _dateFull = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _dateShort = DateFormat('d MMM yyyy', 'id_ID');

String _windowLine(StaffReport s) =>
    '${_dateShort.format(s.rangeFrom.toLocal())} – ${_dateShort.format(s.rangeTo.toLocal())}';

/// `voidPct` arrives as a percent number (e.g. 2.1); `upsellRate` as a
/// fraction (e.g. 0.14).
String _pctNum(double v) => '${v.toStringAsFixed(1)}%';
String _pctFrac(double v) => '${(v * 100).round()}%';

const _headers = [
  'Nama',
  'Sesi',
  'Cover',
  'Item',
  'Net',
  'Rata tagihan',
  'Upsell %',
  'Void',
  'Void %',
  'Lost (void)',
  'Alasan teratas',
];

List<String> _row(StaffReportRow r) => [
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
  r.topReasonLabel ?? '—',
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildStaffCsv(StaffReport s) {
  final rows = <String>[];
  rows.add(csvRow(['Laporan Staf SatSet']));
  rows.add(
    csvRow([
      'Periode',
      rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo),
    ]),
  );
  rows.add(csvRow(['Rentang', _windowLine(s)]));
  rows.add(csvRow(['Dibuat', _dateFull.format(s.generatedAt.toLocal())]));
  rows.add('');
  rows.add(csvRow(_headers));
  for (final r in s.rows) {
    rows.add(csvRow(_row(r)));
  }
  rows.add('');
  rows.add(
    csvRow([
      'TOTAL',
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

Future<Uint8List> buildStaffPdf(StaffReport s, {PdfBranding? branding}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme, landscape: true),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(
              'Laporan Staf · ${rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo)}',
            ),
      footer: pdfFooter,
      build: (ctx) => [
        pdfTitleBlock(
          title: 'Laporan Staf',
          subtitle: rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo),
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            'Rentang: ${_windowLine(s)}',
            'Dibuat: ${_dateFull.format(s.generatedAt.toLocal())}',
            'Diurutkan menurut Net (tertinggi dahulu).',
          ],
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle('Kinerja Staf'),
        pdfTable(
          headers: _headers,
          rows: [for (final r in s.rows) _row(r)],
          numericFrom: 1,
        ),
      ],
    ),
  );

  return doc.save();
}
