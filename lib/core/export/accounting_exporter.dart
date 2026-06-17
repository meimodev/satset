import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/repositories/accounting_report_repository.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the accounting export (ADR-0032). A bookkeeping view
/// of the chosen window: revenue summary on real settled figures, payment
/// method breakdown, void/refund write-offs, and a per-day breakdown. Tax and
/// service are the settled session figures, NOT the screen's 18% estimate.

final _dateFull = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _dateShort = DateFormat('d MMM yyyy', 'id_ID');
final _dayFmt = DateFormat('d MMM yyyy', 'id_ID');

const _methodLabel = {
  'tunai': 'Tunai',
  'kartu': 'Kartu',
  'qris': 'QRIS',
  'transfer': 'Transfer',
  'lainnya': 'Lainnya',
};

String _method(String m) => _methodLabel[m] ?? m;

String _windowLine(AccountingReport s) =>
    '${_dateShort.format(s.rangeFrom.toLocal())} – ${_dateShort.format(s.rangeTo.toLocal())}';

String _day(String ymd) {
  final d = DateTime.tryParse(ymd);
  return d == null ? ymd : _dayFmt.format(d);
}

const _revenueNote =
    'Pajak & service = nilai riil dari sesi terselesaikan (bukan estimasi 18% di layar). '
    'Rentang mengikuti aturan yang sama dengan laporan di layar (ADR-0032).';

const _methodHeaders = [
  'Metode',
  'Jumlah',
  'Transaksi',
  'Refund',
  'Refund (n)',
  'Net',
];
const _voidHeaders = ['Alasan', 'Item', 'Rugi'];
const _dailyHeaders = [
  'Tanggal',
  'Bruto',
  'Void',
  'Service',
  'Pajak',
  'Net',
  'Terkumpul',
  'Refund',
];

List<String> _methodRow(AccountingMethodRow m) => [
  _method(m.method),
  formatIDR(m.charged),
  '${m.chargedCount}',
  formatIDR(m.refunded),
  '${m.refundedCount}',
  formatIDR(m.net),
];

List<String> _voidRow(AccountingVoidRow v) => [
  v.label,
  '${v.count}',
  formatIDR(v.lostRupiah),
];

List<String> _dailyRow(AccountingDayRow d) => [
  _day(d.date),
  formatIDR(d.gross),
  formatIDR(d.voidAmount),
  formatIDR(d.service),
  formatIDR(d.tax),
  formatIDR(d.net),
  formatIDR(d.collected),
  formatIDR(d.refunded),
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildAccountingCsv(AccountingReport s) {
  final rows = <String>[];
  void blank() => rows.add('');
  void section(String title) {
    blank();
    rows.add(csvRow([title.toUpperCase()]));
  }

  final r = s.revenue;
  rows.add(csvRow(['Laporan Akuntansi SatSet']));
  rows.add(
    csvRow([
      'Periode',
      rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo),
    ]),
  );
  rows.add(csvRow(['Rentang', _windowLine(s)]));
  rows.add(csvRow(['Dibuat', _dateFull.format(s.generatedAt.toLocal())]));
  rows.add(csvRow(['Catatan', _revenueNote]));

  section('Ringkasan Pendapatan');
  rows.add(csvRow(['Pos', 'Nilai']));
  rows.add(csvRow(['Bruto (subtotal)', formatIDR(r.gross)]));
  rows.add(csvRow(['Void / koreksi', formatIDR(r.voidAmount)]));
  rows.add(csvRow(['Net', formatIDR(r.net)]));
  rows.add(csvRow(['Service', formatIDR(r.service)]));
  rows.add(csvRow(['Pajak', formatIDR(r.tax)]));
  rows.add(csvRow(['Terkumpul (tagihan)', formatIDR(r.collected)]));
  rows.add(csvRow(['Refund', formatIDR(r.refunded)]));
  rows.add(csvRow(['Jumlah sesi', r.sessionCount]));

  section('Rincian Metode Bayar');
  rows.add(csvRow(_methodHeaders));
  for (final m in s.methods) {
    rows.add(csvRow(_methodRow(m)));
  }

  section('Void & Refund (write-off)');
  rows.add(csvRow(_voidHeaders));
  for (final v in s.voids) {
    rows.add(csvRow(_voidRow(v)));
  }

  section('Rincian Harian');
  rows.add(csvRow(_dailyHeaders));
  for (final d in s.daily) {
    rows.add(csvRow(_dailyRow(d)));
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildAccountingPdf(AccountingReport s,
    {PdfBranding? branding}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final r = s.revenue;

  pw.Widget kv(String label, String value, {bool strong = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: kPdfInkMd,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: kPdfInk,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(
              'Laporan Akuntansi · ${rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo)}',
            ),
      footer: pdfFooter,
      build: (ctx) => [
        pdfTitleBlock(
          title: 'Laporan Akuntansi',
          subtitle: rangeLabelId(s.range, from: s.rangeFrom, to: s.rangeTo),
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            'Rentang: ${_windowLine(s)}',
            'Dibuat: ${_dateFull.format(s.generatedAt.toLocal())}',
            'Jumlah sesi: ${r.sessionCount}',
          ],
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle('Ringkasan Pendapatan'),
        kv('Bruto (subtotal)', formatIDR(r.gross)),
        kv('Void / koreksi', formatIDR(r.voidAmount)),
        kv('Net', formatIDR(r.net), strong: true),
        kv('Service', formatIDR(r.service)),
        kv('Pajak', formatIDR(r.tax)),
        kv('Terkumpul (tagihan)', formatIDR(r.collected), strong: true),
        kv('Refund', formatIDR(r.refunded)),
        pw.SizedBox(height: 6),
        pw.Text(
          _revenueNote,
          style: pw.TextStyle(
            fontSize: 7.5,
            color: kPdfInkLo,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle('Rincian Metode Bayar'),
        pdfTable(
          headers: _methodHeaders,
          rows: [for (final m in s.methods) _methodRow(m)],
          numericFrom: 1,
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle('Void & Refund (write-off)'),
        pdfTable(
          headers: _voidHeaders,
          rows: [for (final v in s.voids) _voidRow(v)],
          numericFrom: 1,
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle('Rincian Harian'),
        pdfTable(
          headers: _dailyHeaders,
          rows: [for (final d in s.daily) _dailyRow(d)],
          numericFrom: 1,
        ),
      ],
    ),
  );

  return doc.save();
}
