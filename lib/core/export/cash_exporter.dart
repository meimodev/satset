/// The [[Kas kecil (petty cash)]] ledger, filed (ADR-0136).
///
/// Rendered here rather than on the server, unlike the venue audit CSV: this one
/// has a PDF too, and a server that rendered the CSV while the client rendered
/// the PDF would be two renderers of one ledger — disagreeing, eventually, about
/// a retired category or a transfer's other leg. What the server owes is the
/// *window*, unpaged; what it must never be handed is the pages a reader
/// happened to scroll.
///
/// A retired or renamed [[Kategori kas (cash category)]] prints its **current**
/// word, because this is an export of `/kas` and `/kas` resolves on read
/// (ADR-0135). The frozen word at movement time stays `/audit`'s.
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/domain/models/cash_window.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';


/// How wide a proof photo is re-encoded for the appendix.
///
/// Captured at 1080px q80 (~200 KB); at this size it is ~60 KB and a receipt is
/// still readable. The appendix is a legibility aid, not evidence — the
/// full-size original never leaves the host, and `/kas` and `/audit` are where
/// it is examined.
const _kPhotoWidth = 700;
const _kPhotoQuality = 70;

/// How many plates one document carries.
///
/// Sixty at appendix size is a few MB, which is a share-sheet file. Past it the
/// appendix stops and the footer says how many were left behind — the ledger
/// itself is never truncated, only its pictures.
const kCashPhotoMax = 60;

/// One row's proof, fetched and shrunk, carrying the number the table points at.
class CashProof {
  /// 1-based, and printed in the table's `foto` column as `#12`. What makes the
  /// appendix navigable on paper.
  final int index;
  final CashEntry entry;

  /// Null when the fetch failed — the plate renders as a placeholder and the
  /// export carries on. A photo the LAN would not give up must not cost the
  /// accountant the ledger.
  final Uint8List? bytes;

  const CashProof({required this.index, required this.entry, this.bytes});
}

/// Re-encode one proof for the appendix, off the UI isolate.
///
/// `Isolate.run` rather than a pool: sixty decodes on the main isolate is a
/// visible stall on a tablet, and the sheet is showing determinate progress
/// while this runs anyway.
Future<Uint8List> shrinkProof(Uint8List raw) => Isolate.run(() {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  final scaled = decoded.width <= _kPhotoWidth
      ? decoded
      : img.copyResize(decoded, width: _kPhotoWidth);
  return img.encodeJpg(scaled, quality: _kPhotoQuality);
});

/// Which rows carry a proof, capped, in the order the table prints them.
List<CashEntry> proofCandidates(List<CashEntry> entries) => [
  for (final e in entries)
    if (e.hasPhoto) e,
].take(kCashPhotoMax).toList();

/// How many proofs the cap left behind, for the footer line.
int proofsOmitted(List<CashEntry> entries) {
  final total = entries.where((e) => e.hasPhoto).length;
  return total > kCashPhotoMax ? total - kCashPhotoMax : 0;
}

// ─── shared row shape ───────────────────────────────────────────────────────

List<String> _headers(AppL10n l) => [
  // The row's own id leads, because the last three columns reference rows by
  // id: without it, `membalikkan: e0` names a row the file cannot show.
  l.kasColId,
  l.kasColWhen,
  l.kasColBox,
  l.kasColKind,
  l.kasColCategory,
  l.kasColDelta,
  l.kasColNote,
  l.kasColActor,
  l.kasColPhoto,
  l.kasColReverses,
  l.kasColReversedBy,
  l.kasColTransferPeer,
];

/// Deliberately **no running balance column**. The balance is `SUM(delta)` and
/// therefore row-order dependent; a spreadsheet the reader re-sorts would carry
/// a column of confident wrong numbers. The window's totals are on the document,
/// summed by the server (ADR-0136).
/// A row reference short enough to read on paper.
///
/// The PDF prints the first segment of a uuid, the CSV prints the whole thing.
/// A full id in a paper column takes the width the readable columns need, and
/// nobody transcribes 36 characters anyway; a spreadsheet has no such problem
/// and may be joined against. Applied to the linkage columns identically, so
/// `membalikkan: cde7ba93` still finds its row on the page.
String _ref(String? id, {required bool short}) =>
    id == null ? '' : (short && id.length > 8 ? id.substring(0, 8) : id);

List<String> _row(
  AppL10n l,
  CashEntry e, {
  required String Function(CashEntry) boxName,
  required String? Function(CashEntry) categoryName,
  required Map<String, int> proofIndex,
  bool shortRefs = false,
}) => [
  _ref(e.id, short: shortRefs),
  '${formatShortDateId(e.at)} ${formatClockId(e.at.toIso8601String())}',
  boxName(e),
  cashEntryKindLabel(l, e.kind),
  categoryName(e) ?? '',
  formatIDR(e.delta),
  e.note ?? '',
  e.actorName ?? l.kasActorUnknown,
  // A reference where there is a plate, a bare mark where the proof exists but
  // did not fit the cap — the reader still learns `/kas` can show it.
  !e.hasPhoto
      ? ''
      : (proofIndex[e.id] != null ? '#${proofIndex[e.id]}' : l.kasPhotoYes),
  _ref(e.reversesId, short: shortRefs),
  _ref(e.reversedById, short: shortRefs),
  _ref(e.transferPeerId, short: shortRefs),
];

/// Relative column widths for the PDF. The three id columns and the two the
/// venue writes into (catatan, kategori) carry the slack; `foto` needs just
/// enough not to wrap its own header.
const _kColumnFlex = [6, 7, 6, 8, 7, 7, 10, 6, 4, 7, 7, 7];

/// The window, spelled for a document header.
String cashWindowLabel(AppL10n l, CashWindow w) => switch (w.kind) {
  CashWindowKind.all => l.kasWindowAll,
  CashWindowKind.d30 => l.kasWindowDays(30),
  CashWindowKind.d90 => l.kasWindowDays(90),
  CashWindowKind.d365 => l.kasWindowDays(365),
  CashWindowKind.custom => customRangeLabel(
    w.from!,
    // Rendered inclusive: the bound is half-open, so the last whole day is the
    // one before it. A span reading "1 Jun – 2 Jul" for a June export is the
    // kind of off-by-one an accountant notices and nobody else does.
    w.to!.subtract(const Duration(days: 1)),
  ),
};

/// The document's header lines.
///
/// [includeScope] is false for the PDF, which carries the box and the window in
/// its subtitle — the CSV has no subtitle, so they lead its block instead.
/// "Kas: Kas Dapur · Rentang: 30 hari" — the export's scope in one line, on the
/// document and on the sheet that offers it, so both name the same thing the
/// same way.
String cashScopeLine(AppL10n l, String boxLabel, CashWindow window) =>
    '${l.kasMetaBox(boxLabel)} · ${l.kasMetaWindow(cashWindowLabel(l, window))}';

List<String> _metaLines(
  AppL10n l,
  CashWindow window,
  CashWindowTotals totals,
  String boxLabel,
  int rows, {
  bool includeScope = true,
}) => [
  if (includeScope) ...[
    l.kasMetaBox(boxLabel),
    l.kasMetaWindow(cashWindowLabel(l, window)),
  ],
  l.kasMetaRows(rows),
  l.kasMetaInflow(formatIDR(totals.inflow)),
  l.kasMetaOutflow(formatIDR(totals.outflow)),
  l.kasMetaVariance(formatIDR(totals.variance)),
];

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildCashCsv(
  AppL10n l, {
  required List<CashEntry> entries,
  required CashWindow window,
  required CashWindowTotals totals,
  required String boxLabel,
  required String Function(CashEntry) boxName,
  required String? Function(CashEntry) categoryName,
}) {
  final rows = <String>[
    csvRow([l.kasCsvTitle]),
    for (final line in _metaLines(l, window, totals, boxLabel, entries.length))
      csvRow([line]),
    '',
    csvRow(_headers(l)),
    for (final e in entries)
      csvRow(
        _row(
          l,
          e,
          boxName: boxName,
          categoryName: categoryName,
          // No plates in a CSV, so every proof renders as the bare mark.
          proofIndex: const {},
        ),
      ),
  ];
  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildCashPdf(
  AppL10n l, {
  required List<CashEntry> entries,
  required CashWindow window,
  required CashWindowTotals totals,
  required String boxLabel,
  required String Function(CashEntry) boxName,
  required String? Function(CashEntry) categoryName,
  List<CashProof> proofs = const [],
  int omitted = 0,
  PdfBranding? branding,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);
  final windowLine = cashWindowLabel(l, window);
  final proofIndex = {for (final p in proofs) p.entry.id: p.index};

  doc.addPage(
    pw.MultiPage(
      // Landscape: eleven columns, three of which are ids.
      pageTheme: pdfPageTheme(theme, landscape: true),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader(l.kasPdfHeader(windowLine)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.kasCsvTitle,
          // Labelled, not '$boxLabel · $windowLine': a venue on the Semua box
          // over the Semua window would otherwise print the same word twice
          // with nothing saying which is which.
          subtitle: cashScopeLine(l, boxLabel, window),
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: _metaLines(
            l,
            window,
            totals,
            boxLabel,
            entries.length,
            includeScope: false,
          ),
        ),
        pw.SizedBox(height: 18),
        pdfSectionTitle(l.kasPdfLedger),
        pdfTable(
          l,
          headers: _headers(l),
          rows: [
            for (final e in entries)
              _row(
                l,
                e,
                boxName: boxName,
                categoryName: categoryName,
                proofIndex: proofIndex,
                shortRefs: true,
              ),
          ],
          numericFrom: 5,
          columnFlex: _kColumnFlex,
        ),
        if (proofs.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pdfSectionTitle(l.kasPdfProofs),
          if (omitted > 0) ...[
            pw.Text(
              l.kasPdfProofsOmitted(omitted),
              style: pw.TextStyle(fontSize: 8.5, color: kPdfInkLo),
            ),
            pw.SizedBox(height: 8),
          ],
          _proofGrid(l, proofs, boxName: boxName, categoryName: categoryName),
        ],
      ],
    ),
  );

  return doc.save();
}

/// Four plates a row, each captioned with the number its ledger row prints.
///
/// A grid and not one page per plate: forty proofs would otherwise turn a
/// forty-row ledger into a forty-page document, and the table — which is the
/// thing being filed — would be the smallest part of it.
pw.Widget _proofGrid(
  AppL10n l,
  List<CashProof> proofs, {
  required String Function(CashEntry) boxName,
  required String? Function(CashEntry) categoryName,
}) {
  const perRow = 4;
  final chunks = <List<CashProof>>[
    for (var i = 0; i < proofs.length; i += perRow)
      proofs.sublist(i, (i + perRow).clamp(0, proofs.length)),
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final chunk in chunks)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < perRow; i++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 8),
                    child: i < chunk.length
                        ? _proofPlate(
                            l,
                            chunk[i],
                            boxName: boxName,
                            categoryName: categoryName,
                          )
                        : pw.SizedBox(),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _proofPlate(
  AppL10n l,
  CashProof p, {
  required String Function(CashEntry) boxName,
  required String? Function(CashEntry) categoryName,
}) {
  final e = p.entry;
  final caption = [
    '#${p.index}',
    formatShortDateId(e.at),
    formatIDR(e.delta),
    categoryName(e) ?? boxName(e),
  ].join(' · ');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        height: 130,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: kPdfBorder, width: 0.5),
          color: kPdfCard,
        ),
        alignment: pw.Alignment.center,
        child: p.bytes == null
            // Loud, not silent: the plate is here, the picture is not, and the
            // footer counts how many did that.
            ? pw.Text(
                l.kasPdfProofMissing,
                style: pw.TextStyle(fontSize: 8, color: kPdfInkLo),
              )
            : pw.Image(pw.MemoryImage(p.bytes!), fit: pw.BoxFit.contain),
      ),
      pw.SizedBox(height: 3),
      pw.Text(caption, style: pw.TextStyle(fontSize: 7.5, color: kPdfInkMd)),
    ],
  );
}

/// `satset-kas-20260905-1432.csv`
///
/// The `kas` slug stays Indonesian in both languages, like every other export
/// slug: it is part of a filename a venue may already be filing by, and a
/// download whose name changes with a device setting is not the same download.
String cashExportFilename(ExportFormat format, {DateTime? at}) {
  final t = (at ?? SatClock.now()).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'satset-kas-${t.year}${two(t.month)}${two(t.day)}'
      '-${two(t.hour)}${two(t.minute)}.${format.ext}';
}
