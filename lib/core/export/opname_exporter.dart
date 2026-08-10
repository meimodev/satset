import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/domain/models/stock_count.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for one stok opname session (ADR-0096).
///
/// Rendered client-side, unlike the venue log's CSV: an opname has no paging.
/// The document view holds every line of the session it is showing — including
/// the ones found correct — so "the file is the whole session" is already true
/// of what is in hand, and a server round-trip would only re-render it.
///
/// The PDF is the filing copy: a venue that counts its pantry keeps the sheet.
/// The CSV is the accountant's, hence the raw base quantities alongside the
/// display ones.

/// Built per call: a cached [DateFormat] freezes whichever locale was active
/// when it was first touched (ADR-0084).
DateFormat get _stamp => DateFormat('d MMM yyyy, HH:mm');

String _stampOf(DateTime? t) => t == null ? '—' : _stamp.format(t.toLocal());

String _qty(StockCountLine l, int base) =>
    formatQty(base, stockUnitFromKey(l.unit ?? StockUnit.pcs.name));

String _signed(StockCountLine l) =>
    '${l.variance > 0 ? '+' : ''}${_qty(l, l.variance)}';

List<String> _headers(AppL10n l) => [
  l.opnColItem,
  l.opnColExpected,
  l.opnColCounted,
  l.opnColVariance,
  l.opnColValue,
];

List<String> _row(StockCountLine line) => [
  line.name ?? line.ingredientId,
  _qty(line, line.expectedQty),
  _qty(line, line.countedQty),
  line.variance == 0 ? '0' : _signed(line),
  formatIDR(line.value),
];

String _scopeLine(AppL10n l, StockCount c) =>
    '${stockCountScopeLabel(l, c.scope)} · '
    '${c.blind ? l.opnTagBlind : l.opnTagSighted}';

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildOpnameCsv(AppL10n l, StockCount c) {
  final rows = <String>[
    csvRow([l.opnCsvTitle]),
    csvRow([l.opnCsvStarted, _stampOf(c.startedAt)]),
    csvRow([l.opnCsvClosed, _stampOf(c.closedAt)]),
    csvRow([l.opnCsvMode, _scopeLine(l, c)]),
    csvRow([l.opnKpiLines, '${c.lines.length}']),
    csvRow([l.opnKpiVariance, formatIDR(c.varianceValue)]),
    if (c.note != null && c.note!.isNotEmpty) csvRow([l.opnCsvNote, c.note]),
    '',
    csvRow(_headers(l)),
    for (final line in c.lines) csvRow(_row(line)),
  ];
  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildOpnamePdf(
  AppL10n l,
  StockCount c, {
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final head = _stampOf(c.startedAt);
  final exact = c.lines.where((e) => e.variance == 0).length;

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(l.opnPdfHeader(head)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.opnCsvTitle,
          subtitle: _scopeLine(l, c),
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            l.opnMetaStarted(head),
            l.opnMetaClosed(_stampOf(c.closedAt)),
            l.opnMetaTally(c.lines.length, exact),
            l.opnMetaVariance(formatIDR(c.varianceValue)),
          ],
        ),
        pw.SizedBox(height: 18),
        if (c.note != null && c.note!.isNotEmpty) ...[
          pw.Text(c.note!),
          pw.SizedBox(height: 12),
        ],
        pdfSectionTitle(l.opnPdfLines),
        pdfTable(
          l,
          headers: _headers(l),
          // Every line, correct ones included: the document's whole point is
          // that "counted and matched" is a finding, not an absence.
          rows: [for (final line in c.lines) _row(line)],
          numericFrom: 1,
        ),
      ],
    ),
  );

  return doc.save();
}

/// `satset-opname-20260810-1432.pdf`
String opnameFilename(StockCount c, ExportFormat format) {
  final t = (c.closedAt ?? c.startedAt).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'satset-opname-${t.year}${two(t.month)}${two(t.day)}'
      '-${two(t.hour)}${two(t.minute)}.${format.ext}';
}
