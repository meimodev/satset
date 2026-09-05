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

/// A `byCategory` / `byMethod` / `byStaff` map as rows, biggest first.
///
/// The screen sorts these the same way; a file that listed them in map order
/// would rank the same data differently from the report it came from.
List<MapEntry<String, int>> _byValueDesc(Map<String, int> m) =>
    m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
    rows.add(csvRow([kpiLabel(l, k), kpiValue(l, k), kpiSub(l, k)]));
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

  // Kas kecil (§Kas kecil). Its own block because none of it is revenue
  // (ADR-0089) — no figure here appears in Sales and no figure in Sales is net
  // of it. Skipped whole when the window saw no movement: an empty section in a
  // filing copy reads as a system that failed to fetch, not as a quiet box.
  if (s.kas.count > 0) {
    section(l.rptSecKas);
    rows.add(csvRow([l.expColMetric, l.expColValue]));
    rows.add(csvRow([l.rptKasOpening, formatIDR(s.kas.opening)]));
    rows.add(csvRow([l.rptKasIn, formatIDR(s.kas.inflow)]));
    rows.add(csvRow([l.rptKasOut, formatIDR(s.kas.outflow)]));
    // Signed on purpose: which way a count went is the finding.
    rows.add(csvRow([l.rptKasVariance, formatIDR(s.kas.variance)]));
    rows.add(csvRow([l.rptKasClosing, formatIDR(s.kas.closing)]));
    if (s.kas.byCategory.isNotEmpty) {
      blank();
      rows.add(csvRow([l.rptKasByCategory]));
      rows.add(csvRow([l.expColCategory, l.expColValue]));
      for (final e in _byValueDesc(s.kas.byCategory)) {
        rows.add(csvRow([e.key, formatIDR(e.value)]));
      }
    }
    // Only once the venue keeps more than one tin (ADR-0131): with one box the
    // block above already is the per-box answer, and repeating it under a
    // heading reads as two different figures.
    if (s.kas.byBox.length > 1) {
      blank();
      rows.add(csvRow([l.rptKasByBox]));
      rows.add(
        csvRow([
          l.kasColBox,
          l.rptKasOpening,
          l.rptKasIn,
          l.rptKasOut,
          l.rptKasVariance,
          l.rptKasClosing,
        ]),
      );
      for (final b in s.kas.byBox) {
        rows.add(
          csvRow([
            b.name,
            formatIDR(b.opening),
            formatIDR(b.inflow),
            formatIDR(b.outflow),
            formatIDR(b.variance),
            formatIDR(b.closing),
          ]),
        );
      }
      // Each tin's own vocabulary, which the venue-wide map above cannot
      // answer: two boxes may have authored the same word (ADR-0135).
      for (final b in s.kas.byBox) {
        if (b.byCategory.isEmpty) continue;
        blank();
        rows.add(csvRow(['${b.name} — ${l.rptKasByCategory}']));
        rows.add(csvRow([l.expColCategory, l.expColValue]));
        for (final e in _byValueDesc(b.byCategory)) {
          rows.add(csvRow([e.key, formatIDR(e.value)]));
        }
      }
    }
  }

  // Pengeluaran kunjungan (ADR-0130) — the mirror of Kas: petty cash is not
  // revenue and this is, which is why neither may sit inside Sales.
  if (s.pengeluaran.count > 0) {
    section(l.rptSecPengeluaran);
    rows.add(csvRow([l.expColMetric, l.expColValue]));
    rows.add(csvRow([l.rptKpiExpense, formatIDR(s.pengeluaran.total)]));
    rows.add(csvRow([l.expColCount, s.pengeluaran.count]));
    if (s.pengeluaran.byCategory.isNotEmpty) {
      blank();
      rows.add(csvRow([l.expColCategory, l.expColValue]));
      for (final e in _byValueDesc(s.pengeluaran.byCategory)) {
        rows.add(csvRow([e.key, formatIDR(e.value)]));
      }
    }
    if (s.pengeluaran.byStaff.isNotEmpty) {
      blank();
      rows.add(csvRow([l.expColStaff, l.expColValue]));
      for (final e in _byValueDesc(s.pengeluaran.byStaff)) {
        rows.add(csvRow([e.key, formatIDR(e.value)]));
      }
    }
    if (s.pengeluaran.visits.isNotEmpty) {
      blank();
      rows.add(csvRow([l.expColTable, l.rptKpiExpense, l.expColTotal]));
      for (final v in s.pengeluaran.visits) {
        rows.add(
          csvRow([
            v.tableLabel,
            formatIDR(v.expenseAmount),
            formatIDR(v.settledTotal),
          ]),
        );
      }
    }
  }

  // Keanggotaan — the ranked list, exactly as the section ranks it. Only when
  // the venue runs a program; the points column follows its own toggle, so an
  // export never carries a column of structural zeros.
  if (s.members.enabled && s.members.top.isNotEmpty) {
    section(l.rptMembersTop);
    rows.add(
      csvRow([
        l.rptMembersColName,
        l.rptMembersColVisits,
        l.rptMembersColAvg,
        if (s.members.pointsEnabled) l.rptMembersColPoints,
        l.rptMembersColSpend,
      ]),
    );
    for (final m in s.members.top) {
      rows.add(
        csvRow([
          m.name ?? l.rptMembersGone,
          m.visits,
          formatIDR(m.avgSpend),
          if (s.members.pointsEnabled) m.points,
          formatIDR(m.spend),
        ]),
      );
    }
    if (s.members.topTruncated > 0) {
      rows.add(csvRow([l.rptMembersMore(s.members.topTruncated)]));
    }
    // How the window was counted, in the file itself (ADR-0118). A ranked list
    // read a year later cannot say whether a row is a whole bill or one share
    // of one, and the export is the copy that outlives the screen.
    if (s.members.splitBills > 0) {
      rows.add(csvRow([l.rptMembersSplitNote]));
    }
  }

  // Piutang (ADR-0098). Not revenue — the sale was booked the night it was
  // eaten — so nothing here may be added to Sales.
  if (s.piutang.enabled) {
    section(l.rptSecPiutang);
    rows.add(csvRow([l.expColMetric, l.expColValue]));
    rows.add(csvRow([l.rptPiutangOpening, formatIDR(s.piutang.opening)]));
    rows.add(csvRow([l.rptPiutangCharged, formatIDR(s.piutang.charged)]));
    rows.add(csvRow([l.rptPiutangCollected, formatIDR(s.piutang.collected)]));
    rows.add(csvRow([l.rptPiutangWrittenOff, formatIDR(s.piutang.writtenOff)]));
    rows.add(csvRow([l.rptPiutangClosing, formatIDR(s.piutang.closing)]));
    rows.add(
      csvRow([
        l.rptPiutangOverdue(s.piutang.overdueDays),
        formatIDR(s.piutang.overdueTotal),
      ]),
    );
    if (s.piutang.byMethod.isNotEmpty) {
      blank();
      rows.add(csvRow([l.rptPiutangByMethod]));
      rows.add(csvRow([l.expColMethod, l.expColValue]));
      for (final e in _byValueDesc(s.piutang.byMethod)) {
        rows.add(csvRow([e.key, formatIDR(e.value)]));
      }
    }
    if (s.piutang.debtors.isNotEmpty) {
      blank();
      rows.add(csvRow([l.rptPiutangDebtors(s.piutang.debtorCount)]));
      rows.add(csvRow([l.expColName, l.expColPhone, l.expColBalance]));
      for (final d in s.piutang.debtors) {
        rows.add(
          csvRow([
            d.name.isEmpty ? l.rptMembersGone : d.name,
            d.phone,
            formatIDR(d.balance),
          ]),
        );
      }
      // The list is a capped page; the full one lives on /members. Saying so in
      // the file matters more than on screen — a filing copy outlives the
      // screen that could have shown the rest.
      if (s.piutang.debtorsTruncated) rows.add(csvRow([l.rptPiutangMore]));
    }
  }

  // Jam kerja. Deliberately not folded into Staf: that block is what someone
  // sold, this one is whether they were here.
  if (s.jamKerja.staff.isNotEmpty) {
    section(l.rptSecJamKerja);
    rows.add(
      csvRow([
        l.expColName,
        l.expColDays,
        l.expColShifts,
        l.expColHours,
        l.expColUnclosed,
      ]),
    );
    for (final r in s.jamKerja.staff) {
      rows.add(
        csvRow([
          r.name,
          r.days,
          r.shifts,
          l.rptJamHours(r.minutes ~/ 60, r.minutes % 60),
          r.unclosed,
        ]),
      );
    }
    // The section's headline caveat travels with it: a venue with unclosed
    // shifts is not reading real hours.
    if (s.jamKerja.unclosed > 0) rows.add(csvRow([l.rptJamUnclosedNote]));
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

        // Kas kecil — none of it revenue (ADR-0089), which is why it is its
        // own block and not a line inside Sales. Absent when the window saw no
        // movement: an empty section in a filing copy reads as a failed fetch.
        if (s.kas.count > 0) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.rptSecKas),
          pdfTable(
            l,
            headers: [l.expColMetric, l.expColValue],
            rows: [
              [l.rptKasOpening, formatIDR(s.kas.opening)],
              [l.rptKasIn, formatIDR(s.kas.inflow)],
              [l.rptKasOut, formatIDR(s.kas.outflow)],
              // Signed: which way a count went is the finding.
              [l.rptKasVariance, formatIDR(s.kas.variance)],
              [l.rptKasClosing, formatIDR(s.kas.closing)],
            ],
            numericFrom: 1,
          ),
          if (s.kas.byCategory.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pdfTable(
              l,
              headers: [l.rptKasByCategory, l.expColValue],
              rows: [
                for (final e in _byValueDesc(s.kas.byCategory))
                  [e.key, formatIDR(e.value)],
              ],
              numericFrom: 1,
            ),
          ],
          // Only above one tin (ADR-0131) — with a single box the block above
          // already is the per-box answer.
          if (s.kas.byBox.length > 1) ...[
            pw.SizedBox(height: 8),
            pdfTable(
              l,
              headers: [
                l.kasColBox,
                l.rptKasOpening,
                l.rptKasIn,
                l.rptKasOut,
                l.rptKasVariance,
                l.rptKasClosing,
              ],
              rows: [
                for (final b in s.kas.byBox)
                  [
                    b.name,
                    formatIDR(b.opening),
                    formatIDR(b.inflow),
                    formatIDR(b.outflow),
                    formatIDR(b.variance),
                    formatIDR(b.closing),
                  ],
              ],
              numericFrom: 1,
            ),
          ],
        ],

        // Pengeluaran kunjungan (ADR-0130) — revenue-affecting, unlike Kas,
        // and for that reason equally outside Sales.
        if (s.pengeluaran.count > 0) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.rptSecPengeluaran),
          pdfTable(
            l,
            headers: [l.expColMetric, l.expColValue],
            rows: [
              [l.rptKpiExpense, formatIDR(s.pengeluaran.total)],
              [l.expColCount, '${s.pengeluaran.count}'],
            ],
            numericFrom: 1,
          ),
          if (s.pengeluaran.byCategory.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pdfTable(
              l,
              headers: [l.expColCategory, l.expColValue],
              rows: [
                for (final e in _byValueDesc(s.pengeluaran.byCategory))
                  [e.key, formatIDR(e.value)],
              ],
              numericFrom: 1,
            ),
          ],
          if (s.pengeluaran.byStaff.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pdfTable(
              l,
              headers: [l.expColStaff, l.expColValue],
              rows: [
                for (final e in _byValueDesc(s.pengeluaran.byStaff))
                  [e.key, formatIDR(e.value)],
              ],
              numericFrom: 1,
            ),
          ],
        ],

        // Keanggotaan — the ranked list. Absent when the venue runs no
        // program, and the points column follows its own toggle.
        if (s.members.enabled && s.members.top.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.rptMembersTop),
          pdfTable(
            l,
            headers: [
              l.rptMembersColName,
              l.rptMembersColVisits,
              l.rptMembersColAvg,
              if (s.members.pointsEnabled) l.rptMembersColPoints,
              l.rptMembersColSpend,
            ],
            rows: [
              for (final m in s.members.top)
                [
                  m.name ?? l.rptMembersGone,
                  '${m.visits}',
                  formatIDR(m.avgSpend),
                  if (s.members.pointsEnabled) '${m.points}',
                  formatIDR(m.spend),
                ],
            ],
            numericFrom: 1,
          ),
          if (s.members.topTruncated > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                l.rptMembersMore(s.members.topTruncated),
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          if (s.members.splitBills > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                l.rptMembersSplitNote,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
        ],

        // Piutang (ADR-0098) — a collection is not revenue, the sale was
        // booked the night it was eaten.
        if (s.piutang.enabled) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.rptSecPiutang),
          pdfTable(
            l,
            headers: [l.expColMetric, l.expColValue],
            rows: [
              [l.rptPiutangOpening, formatIDR(s.piutang.opening)],
              [l.rptPiutangCharged, formatIDR(s.piutang.charged)],
              [l.rptPiutangCollected, formatIDR(s.piutang.collected)],
              [l.rptPiutangWrittenOff, formatIDR(s.piutang.writtenOff)],
              [l.rptPiutangClosing, formatIDR(s.piutang.closing)],
              [
                l.rptPiutangOverdue(s.piutang.overdueDays),
                formatIDR(s.piutang.overdueTotal),
              ],
            ],
            numericFrom: 1,
          ),
          if (s.piutang.debtors.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pdfTable(
              l,
              headers: [l.expColName, l.expColPhone, l.expColBalance],
              rows: [
                for (final d in s.piutang.debtors)
                  [
                    d.name.isEmpty ? l.rptMembersGone : d.name,
                    d.phone,
                    formatIDR(d.balance),
                  ],
              ],
              numericFrom: 2,
            ),
            if (s.piutang.debtorsTruncated)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  l.rptPiutangMore,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
          ],
        ],

        // Jam kerja — whether someone was here, which the Staf block above
        // deliberately does not answer.
        if (s.jamKerja.staff.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pdfSectionTitle(l.rptSecJamKerja),
          pdfTable(
            l,
            headers: [
              l.expColName,
              l.expColDays,
              l.expColShifts,
              l.expColHours,
              l.expColUnclosed,
            ],
            rows: [
              for (final r in s.jamKerja.staff)
                [
                  r.name,
                  '${r.days}',
                  '${r.shifts}',
                  l.rptJamHours(r.minutes ~/ 60, r.minutes % 60),
                  '${r.unclosed}',
                ],
            ],
            numericFrom: 1,
          ),
          // The caveat travels with the numbers: a venue with unclosed shifts
          // is not reading real hours.
          if (s.jamKerja.unclosed > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                l.rptJamUnclosedNote,
                style: const pw.TextStyle(fontSize: 8),
              ),
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
                kpiValue(l, k),
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
