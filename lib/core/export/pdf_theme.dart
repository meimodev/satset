import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/l10n/app_localizations.dart';

/// Shared PDF look for exports (ADR-0030) — the Heritage Hospitality palette
/// rendered with base-14 fonts (Times for display, Helvetica for body) so the
/// document is fully self-contained and renders offline, with no Google Fonts
/// network fetch.

const kPdfCream = PdfColor.fromInt(0xFFFBF9F4); // Soft Cream — page
const kPdfCard = PdfColor.fromInt(0xFFFFFFFF); // cards / table fill
const kPdfInk = PdfColor.fromInt(0xFF4A3728); // Rich Brown — primary ink
const kPdfInkMd = PdfColor.fromInt(0xFF6E5B4C);
const kPdfInkLo = PdfColor.fromInt(0xFF9C8C7E);
const kPdfAccent = PdfColor.fromInt(0xFFFF9233);
const kPdfBorder = PdfColor.fromInt(0xFFE7DFD3);
const kPdfHeadFill = PdfColor.fromInt(0xFFEDE6DA);

class PdfThemeBundle {
  final pw.ThemeData base;
  final pw.Font serif;
  final pw.Font serifBold;
  const PdfThemeBundle(this.base, this.serif, this.serifBold);
}

Future<PdfThemeBundle> pdfTheme() async {
  final serif = pw.Font.times();
  final serifBold = pw.Font.timesBold();
  final base = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
  ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 9, color: kPdfInk));
  return PdfThemeBundle(base, serif, serifBold);
}

pw.PageTheme pdfPageTheme(PdfThemeBundle t, {bool landscape = false}) =>
    pw.PageTheme(
      pageFormat: (landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4)
          .copyWith(
            marginLeft: 32,
            marginRight: 32,
            marginTop: 36,
            marginBottom: 36,
          ),
      theme: t.base,
      buildBackground: (ctx) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: kPdfCream),
      ),
    );

pw.Widget pdfRunningHeader(String text) => pw.Container(
  alignment: pw.Alignment.centerLeft,
  margin: const pw.EdgeInsets.only(bottom: 8),
  padding: const pw.EdgeInsets.only(bottom: 4),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: kPdfBorder, width: 0.5)),
  ),
  child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, color: kPdfInkLo)),
);

pw.Widget pdfFooter(AppL10n l, pw.Context ctx) => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(top: 8),
  child: pw.Text(
    l.expPageOf(ctx.pageNumber, ctx.pagesCount),
    style: pw.TextStyle(fontSize: 7.5, color: kPdfInkLo),
  ),
);

/// Venue branding letterhead bundle (ADR-0033) threaded into the PDF exporters.
/// Only the identity subset — never the customer footer/tagline/thank-you/QR.
class PdfBranding {
  final Uint8List? logoBytes;
  final String venueName;
  final String address;
  final String phone;
  const PdfBranding({
    this.logoBytes,
    this.venueName = '',
    this.address = '',
    this.phone = '',
  });
}

pw.Widget pdfTitleBlock({
  required String title,
  required String subtitle,
  List<String> meta = const [],
  // Venue branding letterhead (ADR-0033) — logo + identity above the title.
  // Only the identity subset; never the customer footer/tagline/QR.
  Uint8List? logoBytes,
  String? venueName,
  String? address,
  String? phone,
}) {
  // Resolve the display font from the document theme at build time.
  return pw.Builder(
    builder: (ctx) {
      final identity = [
        if (venueName != null && venueName.trim().isNotEmpty) venueName.trim(),
        if (address != null && address.trim().isNotEmpty) address.trim(),
        if (phone != null && phone.trim().isNotEmpty) phone.trim(),
      ];
      final hasLetterhead = logoBytes != null || identity.isNotEmpty;
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: kPdfInk, width: 1.2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (hasLetterhead) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null) ...[
                    pw.Image(pw.MemoryImage(logoBytes), height: 40),
                    pw.SizedBox(width: 10),
                  ],
                  if (identity.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (venueName != null && venueName.trim().isNotEmpty)
                            pw.Text(
                              venueName.trim(),
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: kPdfInk,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          for (final line in identity.skip(
                            venueName != null && venueName.trim().isNotEmpty
                                ? 1
                                : 0,
                          ))
                            pw.Text(
                              line,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: kPdfInkMd,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Text(
              title,
              style: pw.TextStyle(
                font: pw.Font.timesBold(),
                fontSize: 22,
                color: kPdfInk,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 11,
                color: kPdfAccent,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (meta.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              for (final m in meta)
                pw.Text(m, style: pw.TextStyle(fontSize: 8, color: kPdfInkMd)),
            ],
          ],
        ),
      );
    },
  );
}

pw.Widget pdfSectionTitle(String text) => pw.Container(
  margin: const pw.EdgeInsets.only(bottom: 6),
  child: pw.Text(
    text,
    style: pw.TextStyle(
      font: pw.Font.timesBold(),
      fontSize: 13,
      color: kPdfInk,
    ),
  ),
);

/// Compact zebra table. Columns from [numericFrom] onward are right-aligned.
///
/// [columnFlex] gives the columns relative widths. Without it `pw.Table` sizes
/// by content, which is fine for four columns and wrong for a dozen: a column
/// whose cells are all empty collapses until its own *header* wraps one letter
/// per line, while a column of ids takes the width the readable ones needed.
pw.Widget pdfTable(
  AppL10n l, {
  required List<String> headers,
  required List<List<String>> rows,
  int numericFrom = 9999,
  List<int>? columnFlex,
}) {
  if (rows.isEmpty) {
    return pw.Text(
      l.expNoData,
      style: pw.TextStyle(
        fontSize: 8.5,
        color: kPdfInkLo,
        fontStyle: pw.FontStyle.italic,
      ),
    );
  }

  pw.Alignment alignOf(int col) =>
      col >= numericFrom ? pw.Alignment.centerRight : pw.Alignment.centerLeft;

  pw.Widget cell(
    String text,
    int col, {
    bool header = false,
    bool alt = false,
  }) => pw.Container(
    alignment: alignOf(col),
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    color: header ? kPdfHeadFill : (alt ? kPdfCream : kPdfCard),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.5,
        color: header ? kPdfInk : kPdfInkMd,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  return pw.Table(
    border: pw.TableBorder.all(color: kPdfBorder, width: 0.5),
    columnWidths: columnFlex == null
        ? null
        : {
            for (var c = 0; c < columnFlex.length; c++)
              c: pw.FlexColumnWidth(columnFlex[c].toDouble()),
          },
    children: [
      pw.TableRow(
        children: [
          for (var c = 0; c < headers.length; c++)
            cell(headers[c], c, header: true),
        ],
      ),
      for (var i = 0; i < rows.length; i++)
        pw.TableRow(
          children: [
            for (var c = 0; c < rows[i].length; c++)
              cell(rows[i][c], c, alt: i.isOdd),
          ],
        ),
    ],
  );
}
