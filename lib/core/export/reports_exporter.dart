import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the venue report export (ADR-0030). PDF carries the
/// full report; CSV carries the KPI block plus the key tables (staff, menu
/// top/slow, category mix, hourly) — visual-only sections are dropped.

final _dateFull = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _dateShort = DateFormat('d MMM yyyy', 'id_ID');

String _fmtIso(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : _dateFull.format(d.toLocal());
}

String _windowLine(ReportsSnapshotDto s) {
  final from = DateTime.tryParse(s.rangeFrom);
  final to = DateTime.tryParse(s.rangeTo);
  if (from == null || to == null) return '${s.rangeFrom} – ${s.rangeTo}';
  return '${_dateShort.format(from.toLocal())} – ${_dateShort.format(to.toLocal())}';
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildReportsCsv(
  ReportsSnapshotDto s,
  ReportRange range, {
  DateTime? from,
  DateTime? to,
}) {
  final rows = <String>[];
  void blank() => rows.add('');
  void section(String title) {
    blank();
    rows.add(csvRow([title.toUpperCase()]));
  }

  rows.add(csvRow(['Laporan SatSet']));
  rows.add(csvRow(['Periode', rangeLabelId(range, from: from, to: to)]));
  rows.add(csvRow(['Rentang', _windowLine(s)]));
  rows.add(csvRow(['Dibuat', _fmtIso(s.generatedAt)]));

  // KPIs (sales + ops), already server-formatted strings.
  section('Ringkasan');
  rows.add(csvRow(['Metrik', 'Nilai', 'Keterangan']));
  for (final k in [...s.sales.kpis, ...s.ops.kpis]) {
    rows.add(csvRow([k.label, k.value, k.sub]));
  }

  // Staff.
  section('Kinerja Staf');
  rows.add(
    csvRow(['Nama', 'Cover', 'Item', 'Rata tagihan', 'Void %', 'Net', 'Sesi']),
  );
  for (final r in s.staff.rows) {
    rows.add(
      csvRow([
        r.name,
        r.covers,
        r.items,
        formatIDR(r.avgTicket),
        _pct(r.voidPct),
        formatIDR(r.net),
        r.sessions,
      ]),
    );
  }

  // Menu — top sellers.
  section('Menu Terlaris');
  rows.add(csvRow(['Item', 'Qty', 'Pendapatan', 'Margin %']));
  for (final m in s.menu.top) {
    rows.add(csvRow([m.name, m.qty, formatIDR(m.revenue), '${m.marginPct}%']));
  }

  // Menu — slow movers.
  section('Menu Lambat');
  rows.add(csvRow(['Item', 'Qty', 'Pendapatan']));
  for (final m in s.menu.slow) {
    rows.add(csvRow([m.name, m.qty, formatIDR(m.revenue)]));
  }

  // Category mix.
  section('Komposisi Kategori');
  rows.add(csvRow(['Kategori', 'Porsi minggu ini', 'Porsi minggu lalu']));
  for (final c in s.menu.categoryMix) {
    rows.add(csvRow([c.name, _pct(c.shareThisWeek), _pct(c.shareLastWeek)]));
  }

  // Hourly sales.
  section('Penjualan per Jam');
  rows.add(csvRow(['Jam', 'Nilai']));
  for (var h = 0; h < s.sales.hourly.length; h++) {
    rows.add(csvRow(['${h.toString().padLeft(2, '0')}:00', s.sales.hourly[h]]));
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildReportsPdf(
  ReportsSnapshotDto s,
  ReportRange range, {
  DateTime? from,
  DateTime? to,
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(
              'Laporan SatSet · ${rangeLabelId(range, from: from, to: to)}',
            ),
      footer: pdfFooter,
      build: (ctx) => [
        pdfTitleBlock(
          title: 'Laporan SatSet',
          subtitle: rangeLabelId(range, from: from, to: to),
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            'Rentang: ${_windowLine(s)}',
            'Dibuat: ${_fmtIso(s.generatedAt)}',
          ],
        ),
        pw.SizedBox(height: 18),

        // KPI cards (sales + ops).
        pdfSectionTitle('Ringkasan'),
        _kpiGrid([...s.sales.kpis, ...s.ops.kpis]),

        // Takeaway split, if present.
        if (s.sales.takeaway != null) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle('Dine-in vs Bawa Pulang'),
          pdfTable(
            headers: const ['', 'Transaksi', 'Net'],
            rows: [
              [
                'Makan di tempat',
                '${s.sales.takeaway!.dineInCount}',
                formatIDR(s.sales.takeaway!.dineInNet),
              ],
              [
                'Bawa pulang',
                '${s.sales.takeaway!.count}',
                formatIDR(s.sales.takeaway!.net),
              ],
            ],
            numericFrom: 1,
          ),
        ],

        // Staff.
        pw.SizedBox(height: 14),
        pdfSectionTitle('Kinerja Staf'),
        pdfTable(
          headers: const [
            'Nama',
            'Cover',
            'Item',
            'Rata tagihan',
            'Void %',
            'Net',
            'Sesi',
          ],
          rows: [
            for (final r in s.staff.rows)
              [
                r.name,
                '${r.covers}',
                '${r.items}',
                formatIDR(r.avgTicket),
                _pct(r.voidPct),
                formatIDR(r.net),
                '${r.sessions}',
              ],
          ],
          numericFrom: 1,
        ),

        // Menu top.
        pw.SizedBox(height: 14),
        pdfSectionTitle('Menu Terlaris'),
        pdfTable(
          headers: const ['Item', 'Qty', 'Pendapatan', 'Margin'],
          rows: [
            for (final m in s.menu.top)
              [m.name, '${m.qty}', formatIDR(m.revenue), '${m.marginPct}%'],
          ],
          numericFrom: 1,
        ),

        // Menu slow.
        pw.SizedBox(height: 14),
        pdfSectionTitle('Menu Lambat'),
        pdfTable(
          headers: const ['Item', 'Qty', 'Pendapatan'],
          rows: [
            for (final m in s.menu.slow)
              [m.name, '${m.qty}', formatIDR(m.revenue)],
          ],
          numericFrom: 1,
        ),

        // Category mix.
        if (s.menu.categoryMix.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle('Komposisi Kategori'),
          pdfTable(
            headers: const ['Kategori', 'Minggu ini', 'Minggu lalu'],
            rows: [
              for (final c in s.menu.categoryMix)
                [c.name, _pct(c.shareThisWeek), _pct(c.shareLastWeek)],
            ],
            numericFrom: 1,
          ),
        ],

        // Hourly.
        if (s.sales.hourly.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle('Penjualan per Jam'),
          _hourlyBars(s.sales.hourly),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _kpiGrid(List<KpiTileDto> kpis) {
  if (kpis.isEmpty) return pw.SizedBox();
  return pw.Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final k in kpis)
        pw.Container(
          width: 158,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: kPdfCard,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: kPdfBorder, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                k.label.toUpperCase(),
                style: pw.TextStyle(fontSize: 7.5, color: kPdfInkLo),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                k.value,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: kPdfInk,
                ),
              ),
              if (k.sub.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  k.sub,
                  style: pw.TextStyle(fontSize: 7.5, color: kPdfInkLo),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

pw.Widget _hourlyBars(List<double> hourly) {
  final max = hourly.fold<double>(0, (m, v) => v > m ? v : m);
  return pw.Container(
    height: 90,
    padding: const pw.EdgeInsets.only(top: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (var h = 0; h < hourly.length; h++)
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  height: max <= 0 ? 1 : (hourly[h] / max) * 70 + 1,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                  decoration: pw.BoxDecoration(
                    color: kPdfAccent,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.SizedBox(height: 2),
                if (h % 3 == 0)
                  pw.Text(
                    '$h',
                    style: pw.TextStyle(fontSize: 6, color: kPdfInkLo),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
