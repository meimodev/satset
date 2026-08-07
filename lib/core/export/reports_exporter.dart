import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the venue report export (ADR-0030). PDF carries the
/// full report; CSV carries the KPI block plus the key tables (staff, menu
/// top/slow, category mix, hourly) — visual-only sections are dropped.

/// Built per call: a cached [DateFormat] freezes whichever locale was active
/// when it was first touched, and for a lazily-initialised top-level that is
/// "whichever screen ran first" (ADR-0084).
DateFormat get _dateFull => DateFormat('d MMM yyyy, HH:mm');
DateFormat get _dateShort => DateFormat('d MMM yyyy');

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

/// Same seven columns in the CSV and the PDF — one list so they cannot drift.
List<String> _staffHeaders(AppL10n l) => [
  l.expColName,
  l.expColCover,
  l.expColItem,
  l.expColAvgBill,
  l.expColVoidPct,
  l.expNet,
  l.expColSessions,
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildReportsCsv(
  AppL10n l,
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

  rows.add(csvRow([l.expReportCsvTitle]));
  rows.add(csvRow([l.expPeriod, rangeLabel(l, range, from: from, to: to)]));
  rows.add(csvRow([l.expRange, _windowLine(s)]));
  rows.add(csvRow([l.expGenerated, _fmtIso(s.generatedAt)]));

  // KPIs (sales + ops), already server-formatted strings.
  section(l.expSummary);
  rows.add(csvRow([l.expColMetric, l.expColValue, l.expColCaption]));
  for (final k in [...s.sales.kpis, ...s.ops.kpis]) {
    rows.add(csvRow([kpiLabel(l, k), k.value, kpiSub(l, k)]));
  }

  // Staff.
  section(l.expStaffPerformance);
  rows.add(csvRow(_staffHeaders(l)));
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
  section(l.expTopMenu);
  rows.add(
    csvRow([l.expColItem, l.expColQty, l.expColRevenue, l.expColMarginPct]),
  );
  for (final m in s.menu.top) {
    rows.add(csvRow([m.name, m.qty, formatIDR(m.revenue), '${m.marginPct}%']));
  }

  // Menu — slow movers.
  section(l.expSlowMenu);
  rows.add(csvRow([l.expColItem, l.expColQty, l.expColRevenue]));
  for (final m in s.menu.slow) {
    rows.add(csvRow([m.name, m.qty, formatIDR(m.revenue)]));
  }

  // Category mix.
  section(l.expCategoryMix);
  rows.add(
    csvRow([l.expColCategory, l.expColShareThisWeek, l.expColShareLastWeek]),
  );
  for (final c in s.menu.categoryMix) {
    rows.add(csvRow([c.name, _pct(c.shareThisWeek), _pct(c.shareLastWeek)]));
  }

  // Hourly sales.
  section(l.expHourlySales);
  rows.add(csvRow([l.expColHour, l.expColValue]));
  for (var h = 0; h < s.sales.hourly.length; h++) {
    rows.add(csvRow(['${h.toString().padLeft(2, '0')}:00', s.sales.hourly[h]]));
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildReportsPdf(
  AppL10n l,
  ReportsSnapshotDto s,
  ReportRange range, {
  DateTime? from,
  DateTime? to,
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final label = rangeLabel(l, range, from: from, to: to);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(l.expReportHeader(label)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.expReportCsvTitle,
          subtitle: label,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            l.expMetaRange(_windowLine(s)),
            l.expMetaGenerated(_fmtIso(s.generatedAt)),
          ],
        ),
        pw.SizedBox(height: 18),

        // KPI cards (sales + ops).
        pdfSectionTitle(l.expSummary),
        _kpiGrid(l, [...s.sales.kpis, ...s.ops.kpis]),

        // Takeaway split, if present.
        if (s.sales.takeaway != null) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.expDineInVsTakeaway),
          pdfTable(
            l,
            headers: ['', l.expColTransactions, l.expNet],
            rows: [
              [
                l.expDineIn,
                '${s.sales.takeaway!.dineInCount}',
                formatIDR(s.sales.takeaway!.dineInNet),
              ],
              [
                l.expTakeaway,
                '${s.sales.takeaway!.count}',
                formatIDR(s.sales.takeaway!.net),
              ],
            ],
            numericFrom: 1,
          ),
        ],

        // Staff.
        pw.SizedBox(height: 14),
        pdfSectionTitle(l.expStaffPerformance),
        pdfTable(
          l,
          headers: _staffHeaders(l),
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
        pdfSectionTitle(l.expTopMenu),
        pdfTable(
          l,
          headers: [l.expColItem, l.expColQty, l.expColRevenue, l.expColMargin],
          rows: [
            for (final m in s.menu.top)
              [m.name, '${m.qty}', formatIDR(m.revenue), '${m.marginPct}%'],
          ],
          numericFrom: 1,
        ),

        // Menu slow.
        pw.SizedBox(height: 14),
        pdfSectionTitle(l.expSlowMenu),
        pdfTable(
          l,
          headers: [l.expColItem, l.expColQty, l.expColRevenue],
          rows: [
            for (final m in s.menu.slow)
              [m.name, '${m.qty}', formatIDR(m.revenue)],
          ],
          numericFrom: 1,
        ),

        // Category mix.
        if (s.menu.categoryMix.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.expCategoryMix),
          pdfTable(
            l,
            headers: [l.expColCategory, l.expColThisWeek, l.expColLastWeek],
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
          pdfSectionTitle(l.expHourlySales),
          _hourlyBars(s.sales.hourly),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _kpiGrid(AppL10n l, List<KpiTileDto> kpis) {
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
                kpiLabel(l, k).toUpperCase(),
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
