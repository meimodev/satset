import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/data/repositories/accounting_report_repository.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the accounting export (ADR-0032). A bookkeeping view
/// of the chosen window: revenue summary on real settled figures, payment
/// method breakdown, void/refund write-offs, and a per-day breakdown. Tax and
/// service are the settled session figures, NOT the screen's 18% estimate.
///
/// Column headers and section titles follow the exporting device's language
/// (ADR-0083); every amount inside them stays `Rp 14.500` (ADR-0084). The
/// [DateFormat]s are built per call rather than held in top-level finals — a
/// cached formatter freezes whichever locale was active when the field was
/// first touched, which for a lazily-initialised top-level is "whichever screen
/// ran first".

DateFormat get _dateFull => DateFormat('d MMM yyyy, HH:mm');
DateFormat get _dateShort => DateFormat('d MMM yyyy');

String _windowLine(AccountingReport s) =>
    '${_dateShort.format(s.rangeFrom.toLocal())} – ${_dateShort.format(s.rangeTo.toLocal())}';

String _day(String ymd) {
  final d = DateTime.tryParse(ymd);
  return d == null ? ymd : _dateShort.format(d);
}

List<String> _methodHeaders(AppL10n l) => [
  l.expColMethod,
  l.expColAmount,
  l.expColTransactions,
  l.expRefund,
  l.expColRefundCount,
  l.expNet,
];

List<String> _voidHeaders(AppL10n l) => [
  l.expColReason,
  l.expColItem,
  l.expColLost,
];

List<String> _dailyHeaders(AppL10n l) => [
  l.expColDate,
  l.expColGross,
  l.expColVoid,
  l.expService,
  l.expTax,
  l.expDiscount,
  l.expNet,
  l.expColCollected,
  l.expRefund,
];

/// Per-preset rollup — answers "which promo is costing me money" (ADR-0039).
List<String> _discountHeaders(AppL10n l) => [
  l.expDiscount,
  l.expColScope,
  l.expColUsed,
  l.expColValue,
];

List<String> _discountRow(AppL10n l, AccountingDiscountRow d) => [
  d.label,
  d.scope == 'line' ? l.expScopeLine : l.expScopeOrder,
  '${d.count}',
  formatIDR(d.amount),
];

List<String> _methodRow(AppL10n l, AccountingMethodRow m) => [
  paymentMethodLabel(l, m.method),
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
  formatIDR(d.discount),
  formatIDR(d.net),
  formatIDR(d.collected),
  formatIDR(d.refunded),
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildAccountingCsv(AppL10n l, AccountingReport s) {
  final rows = <String>[];
  void blank() => rows.add('');
  void section(String title) {
    blank();
    rows.add(csvRow([title.toUpperCase()]));
  }

  final r = s.revenue;
  rows.add(csvRow([l.expAccountingCsvTitle]));
  rows.add(
    csvRow([
      l.expPeriod,
      rangeLabel(l, s.range, from: s.rangeFrom, to: s.rangeTo),
    ]),
  );
  rows.add(csvRow([l.expRange, _windowLine(s)]));
  rows.add(csvRow([l.expGenerated, _dateFull.format(s.generatedAt.toLocal())]));
  rows.add(csvRow([l.expNote, l.expAccountingNote]));

  section(l.expRevenueSummary);
  rows.add(csvRow([l.expColEntry, l.expColValue]));
  rows.add(csvRow([l.expGrossSubtotal, formatIDR(r.gross)]));
  rows.add(csvRow([l.expVoidCorrection, formatIDR(r.voidAmount)]));
  rows.add(csvRow([l.expDiscount, formatIDR(r.discount)]));
  rows.add(csvRow([l.expNet, formatIDR(r.net)]));
  rows.add(csvRow([l.expService, formatIDR(r.service)]));
  rows.add(csvRow([l.expTax, formatIDR(r.tax)]));
  rows.add(csvRow([l.expCollectedBilled, formatIDR(r.collected)]));
  rows.add(csvRow([l.expRefund, formatIDR(r.refunded)]));
  rows.add(csvRow([l.expSessionCount, r.sessionCount]));

  section(l.expMethodBreakdown);
  rows.add(csvRow(_methodHeaders(l)));
  for (final m in s.methods) {
    rows.add(csvRow(_methodRow(l, m)));
  }

  section(l.expWriteOffs);
  rows.add(csvRow(_voidHeaders(l)));
  for (final v in s.voids) {
    rows.add(csvRow(_voidRow(v)));
  }

  section(l.expDiscountByPreset);
  rows.add(csvRow(_discountHeaders(l)));
  for (final d in s.discounts) {
    rows.add(csvRow(_discountRow(l, d)));
  }

  section(l.expDailyBreakdown);
  rows.add(csvRow(_dailyHeaders(l)));
  for (final d in s.daily) {
    rows.add(csvRow(_dailyRow(d)));
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildAccountingPdf(
  AppL10n l,
  AccountingReport s, {
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final r = s.revenue;
  final range = rangeLabel(l, s.range, from: s.rangeFrom, to: s.rangeTo);

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
          : pdfRunningHeader(l.expAccountingHeader(range)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.expAccountingTitle,
          subtitle: range,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            l.expMetaRange(_windowLine(s)),
            l.expMetaGenerated(_dateFull.format(s.generatedAt.toLocal())),
            l.expMetaSessionCount(r.sessionCount),
          ],
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle(l.expRevenueSummary),
        kv(l.expGrossSubtotal, formatIDR(r.gross)),
        kv(l.expVoidCorrection, formatIDR(r.voidAmount)),
        kv(l.expDiscount, formatIDR(r.discount)),
        kv(l.expNet, formatIDR(r.net), strong: true),
        kv(l.expService, formatIDR(r.service)),
        kv(l.expTax, formatIDR(r.tax)),
        kv(l.expCollectedBilled, formatIDR(r.collected), strong: true),
        kv(l.expRefund, formatIDR(r.refunded)),
        pw.SizedBox(height: 6),
        pw.Text(
          l.expAccountingNote,
          style: pw.TextStyle(
            fontSize: 7.5,
            color: kPdfInkLo,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle(l.expMethodBreakdown),
        pdfTable(
          l,
          headers: _methodHeaders(l),
          rows: [for (final m in s.methods) _methodRow(l, m)],
          numericFrom: 1,
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle(l.expWriteOffs),
        pdfTable(
          l,
          headers: _voidHeaders(l),
          rows: [for (final v in s.voids) _voidRow(v)],
          numericFrom: 1,
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle(l.expDiscountByPreset),
        pdfTable(
          l,
          headers: _discountHeaders(l),
          rows: [for (final d in s.discounts) _discountRow(l, d)],
          numericFrom: 2,
        ),
        pw.SizedBox(height: 16),
        pdfSectionTitle(l.expDailyBreakdown),
        pdfTable(
          l,
          headers: _dailyHeaders(l),
          rows: [for (final d in s.daily) _dailyRow(d)],
          numericFrom: 1,
        ),
      ],
    ),
  );

  return doc.save();
}
