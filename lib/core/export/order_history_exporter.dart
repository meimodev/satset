import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the order-list (order history) export. Line items
/// grouped by visit, voids included and flagged, plus the bill settlement per
/// receipt — totals breakdown and the payments tendered, with inline proof
/// photos in the PDF (ADR-0031). The board stays live; this only renders the
/// chosen window pulled from /orders/history.

/// Built per call: a cached [DateFormat] freezes whichever locale was active
/// when it was first touched (ADR-0084).
DateFormat get _dateFull => DateFormat('d MMM yyyy, HH:mm');
DateFormat get _dateShort => DateFormat('d MMM yyyy');
DateFormat get _clock => DateFormat('HH:mm');

String _visitTitle(AppL10n l, OrderHistoryVisit v) => v.isTakeaway
    ? l.expTakeawayVisit(v.tableLabel)
    : l.expTableVisit(v.tableLabel);

String _mods(OrderHistoryLine l) => l.modifiers.join(' · ');

String _status(AppL10n l, OrderHistoryLine line) {
  if (line.isVoided) return l.expStatusVoided;
  return switch (line.status) {
    'served' => l.expStatusServed,
    'ready' => l.expStatusReady,
    'prep' || 'cooked' => l.expStatusCooked,
    'sent' => l.expStatusSent,
    'held' => l.expStatusHeld,
    _ => line.status,
  };
}

String _payAmount(OrderHistoryPayment p) =>
    p.isRefund ? '-${formatIDR(p.amount.abs())}' : formatIDR(p.amount);

String _windowLine(OrderHistory h) =>
    '${_dateShort.format(h.rangeFrom.toLocal())} – ${_dateShort.format(h.rangeTo.toLocal())}';

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildOrderHistoryCsv(
  AppL10n l,
  OrderHistory h,
  ReportRange range, {
  DateTime? from,
  DateTime? to,
}) {
  final rows = <String>[];
  rows.add(csvRow([l.expOrdersCsvTitle]));
  rows.add(csvRow([l.expPeriod, rangeLabel(l, range, from: from, to: to)]));
  rows.add(csvRow([l.expRange, _windowLine(h)]));
  rows.add(csvRow([l.expGenerated, _dateFull.format(h.generatedAt.toLocal())]));
  rows.add(csvRow([l.expVisitCount, h.visitCount]));
  rows.add(csvRow([l.expLineCount, h.lineCount]));
  rows.add(csvRow([l.expNet, formatIDR(h.net)]));

  for (final v in h.visits) {
    rows.add('');
    rows.add(
      csvRow([
        l.expVisitSection,
        _visitTitle(l, v),
        l.expColPax,
        v.pax,
        l.expColWaiter,
        v.waiterName ?? '—',
        l.expColClosed,
        _dateFull.format(v.closedAt.toLocal()),
        l.expNet,
        formatIDR(v.net),
      ]),
    );
    rows.add(
      csvRow([
        l.expColTime,
        l.expColItem,
        l.expColVariant,
        l.expColModifier,
        l.expColCourse,
        l.expColQty,
        l.expColPrice,
        l.expColTotal,
        l.expColStatus,
        l.expColVoidReason,
      ]),
    );
    for (final line in v.lines) {
      rows.add(
        csvRow([
          _clock.format(line.sentAt.toLocal()),
          line.name,
          line.variantName,
          _mods(line),
          line.course,
          line.qty,
          formatIDR(line.price),
          formatIDR(line.lineTotal),
          _status(l, line),
          line.voidReasonCode == null
              ? ''
              : voidReasonLabel(l, line.voidReasonCode!),
        ]),
      );
    }

    // Bill settlement: per-receipt totals + payments (ADR-0031).
    for (final r in v.receipts) {
      rows.add(
        csvRow([
          l.expBillSection,
          r.label.isEmpty ? '—' : r.label,
          l.expColSubtotal,
          formatIDR(r.subtotal),
          l.expDiscount,
          formatIDR(r.discountAmount),
          l.expService,
          formatIDR(r.serviceAmount),
          l.expTax,
          formatIDR(r.taxAmount),
          l.expColTotal,
          formatIDR(r.total),
          l.expColStatus,
          r.status,
        ]),
      );
      if (r.payments.isNotEmpty) {
        rows.add(
          csvRow([
            l.expColTime,
            l.expColMethod,
            l.expColCashier,
            l.expColAmount,
            l.expRefund,
            l.expColProofPhoto,
          ]),
        );
        for (final p in r.payments) {
          rows.add(
            csvRow([
              _clock.format(p.at.toLocal()),
              paymentMethodLabel(l, p.method),
              p.cashierName ?? '—',
              _payAmount(p),
              p.isRefund ? l.expYes : '',
              p.hasPhoto ? l.expPresent : '—',
            ]),
          );
        }
      }
    }
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildOrderHistoryPdf(
  AppL10n l,
  OrderHistory h,
  ReportRange range, {
  Map<String, Uint8List> photos = const {},
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
          : pdfRunningHeader(l.expOrdersHeader(label)),
      footer: (ctx) => pdfFooter(l, ctx),
      build: (ctx) => [
        pdfTitleBlock(
          title: l.expOrdersTitle,
          subtitle: label,
          logoBytes: branding?.logoBytes,
          venueName: branding?.venueName,
          address: branding?.address,
          phone: branding?.phone,
          meta: [
            l.expMetaRange(_windowLine(h)),
            l.expMetaGenerated(_dateFull.format(h.generatedAt.toLocal())),
            l.expMetaVisitLines(h.visitCount, h.lineCount, formatIDR(h.net)),
          ],
        ),
        pw.SizedBox(height: 16),
        if (h.isEmpty)
          pw.Text(
            l.expNoVisits,
            style: pw.TextStyle(
              fontSize: 9,
              color: kPdfInkLo,
              fontStyle: pw.FontStyle.italic,
            ),
          )
        else
          for (final v in h.visits) ..._visitBlock(l, v, photos),
      ],
    ),
  );

  return doc.save();
}

List<pw.Widget> _visitBlock(
  AppL10n l,
  OrderHistoryVisit v,
  Map<String, Uint8List> photos,
) => [
  pw.SizedBox(height: 12),
  _visitHeader(l, v),
  pdfTable(
    l,
    headers: [
      l.expColTime,
      l.expColItem,
      l.expColModifier,
      l.expColCourse,
      l.expColQty,
      l.expColPrice,
      l.expColTotal,
      l.expColStatus,
    ],
    rows: [
      for (final line in v.lines)
        [
          _clock.format(line.sentAt.toLocal()),
          line.variantName.isEmpty
              ? line.name
              : '${line.name} (${line.variantName})',
          _mods(line),
          line.course,
          '${line.qty}',
          formatIDR(line.price),
          formatIDR(line.lineTotal),
          line.isVoided
              ? l
                    .expVoidedWithReason(
                      line.voidReasonCode == null
                          ? ''
                          : voidReasonLabel(l, line.voidReasonCode!),
                    )
                    .trim()
              : _status(l, line),
        ],
    ],
    numericFrom: 4,
  ),
  for (final r in v.receipts) ..._receiptBlock(l, r, photos),
];

pw.Widget _visitHeader(AppL10n l, OrderHistoryVisit v) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  decoration: const pw.BoxDecoration(color: kPdfInk),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Expanded(
        child: pw.Text(
          _visitTitle(l, v),
          style: pw.TextStyle(
            font: pw.Font.timesBold(),
            fontSize: 11,
            color: kPdfCream,
          ),
        ),
      ),
      pw.Text(
        l.expVisitMeta(
          v.pax,
          v.waiterName ?? '—',
          _dateFull.format(v.closedAt.toLocal()),
        ),
        style: const pw.TextStyle(fontSize: 7.5, color: kPdfHeadFill),
      ),
      pw.SizedBox(width: 10),
      pw.Text(
        formatIDR(v.net),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: kPdfCream,
        ),
      ),
    ],
  ),
);

// One receipt's settlement block: totals strip + payment rows. Each non-cash
// payment renders its proof as an enlarged card under the row (ADR-0031
// amendment) so the amount on the capture is legible for audit.
List<pw.Widget> _receiptBlock(
  AppL10n l,
  OrderHistoryReceipt r,
  Map<String, Uint8List> photos,
) {
  return [
    pw.SizedBox(height: 4),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(color: kPdfHeadFill),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              r.label.isEmpty ? l.expBillHeading : r.label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: kPdfInk,
              ),
            ),
          ),
          pw.Text(
            l.expReceiptTotals(
              formatIDR(r.subtotal),
              r.discountAmount > 0
                  ? l.expReceiptDiscountPart(formatIDR(r.discountAmount))
                  : '',
              formatIDR(r.serviceAmount),
              formatIDR(r.taxAmount),
              formatIDR(r.total),
            ),
            style: const pw.TextStyle(fontSize: 7.5, color: kPdfInkMd),
          ),
        ],
      ),
    ),
    if (r.payments.isEmpty)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: pw.Text(
          l.expNoPayments,
          style: pw.TextStyle(
            fontSize: 7.5,
            color: kPdfInkLo,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      )
    else
      for (final p in r.payments) _paymentRow(l, p, photos[p.paymentId]),
  ];
}

// Payment text line + (non-cash only) its enlarged proof card, kept together as
// one non-spanning Container so MultiPage never splits a row from its proof
// (ADR-0031 amendment). Cash renders text-only; non-cash always renders a proof
// area — the card if bytes arrived, else a `Bukti tidak termuat` placeholder, so
// a missing proof reads as a flag instead of blending into a cash row.
pw.Widget _paymentRow(AppL10n l, OrderHistoryPayment p, Uint8List? photo) {
  final isNonCash = p.method != 'tunai';
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: kPdfBorder, width: 0.5)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                l.expPaymentActor(
                  paymentMethodLabel(l, p.method),
                  p.cashierName ?? '—',
                  p.isRefund ? l.expPaymentRefundPart : '',
                ),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: kPdfInk,
                ),
              ),
            ),
            pw.Text(
              _clock.format(p.at.toLocal()),
              style: const pw.TextStyle(fontSize: 7.5, color: kPdfInkLo),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              _payAmount(p),
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: p.isRefund ? kPdfAccent : kPdfInk,
              ),
            ),
          ],
        ),
        if (isNonCash) ...[pw.SizedBox(height: 5), _proofCard(l, p, photo)],
      ],
    ),
  );
}

// Bordered proof card: caption tying it back to its payment + the capture at
// BoxFit.contain (never cover — cropping can chop the amount being verified),
// height-capped so a multi-tender visit can't explode the page.
pw.Widget _proofCard(AppL10n l, OrderHistoryPayment p, Uint8List? photo) =>
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 1),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: kPdfCard,
        border: pw.Border.all(color: kPdfBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            l.expProofCaption(paymentMethodLabel(l, p.method), _payAmount(p)),
            style: pw.TextStyle(fontSize: 7, color: kPdfInkLo),
          ),
          pw.SizedBox(height: 4),
          if (photo != null)
            pw.SizedBox(
              height: 140,
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.ClipRRect(
                  horizontalRadius: 3,
                  verticalRadius: 3,
                  child: pw.Image(
                    pw.MemoryImage(photo),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            )
          else
            _proofMissing(l),
        ],
      ),
    );

pw.Widget _proofMissing(AppL10n l) => pw.Container(
  height: 36,
  alignment: pw.Alignment.center,
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: kPdfAccent, width: 0.5),
    borderRadius: pw.BorderRadius.circular(3),
  ),
  child: pw.Text(
    l.expProofMissing,
    style: pw.TextStyle(
      fontSize: 8,
      color: kPdfAccent,
      fontStyle: pw.FontStyle.italic,
    ),
  ),
);
