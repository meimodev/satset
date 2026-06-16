import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/design/format.dart';

/// CSV + PDF builders for the order-list (order history) export. Line items
/// grouped by visit, voids included and flagged, plus the bill settlement per
/// receipt — totals breakdown and the payments tendered, with inline proof
/// photos in the PDF (ADR-0031). The board stays live; this only renders the
/// chosen window pulled from /orders/history.

final _dateFull = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _dateShort = DateFormat('d MMM yyyy', 'id_ID');
final _clock = DateFormat('HH:mm', 'id_ID');

const _methodLabel = {
  'tunai': 'Tunai',
  'kartu': 'Kartu',
  'qris': 'QRIS',
  'transfer': 'Transfer',
  'lainnya': 'Lainnya',
};

String _method(String m) => _methodLabel[m] ?? m;

String _visitTitle(OrderHistoryVisit v) =>
    v.isTakeaway ? '${v.tableLabel} · Bawa pulang' : 'Meja ${v.tableLabel}';

String _mods(OrderHistoryLine l) => l.modifiers.join(' · ');

String _statusId(OrderHistoryLine l) {
  if (l.isVoided) return 'Dibatalkan';
  return switch (l.status) {
    'served' => 'Disajikan',
    'ready' => 'Siap',
    'prep' || 'cooked' => 'Dimasak',
    'sent' => 'Dikirim',
    'held' => 'Ditahan',
    _ => l.status,
  };
}

String _payAmount(OrderHistoryPayment p) =>
    p.isRefund ? '-${formatIDR(p.amount.abs())}' : formatIDR(p.amount);

String _windowLine(OrderHistory h) =>
    '${_dateShort.format(h.rangeFrom.toLocal())} – ${_dateShort.format(h.rangeTo.toLocal())}';

// ─── CSV ────────────────────────────────────────────────────────────────────

String buildOrderHistoryCsv(OrderHistory h, ReportRange range,
    {DateTime? from, DateTime? to}) {
  final rows = <String>[];
  rows.add(csvRow(['Riwayat Pesanan SatSet']));
  rows.add(csvRow(['Periode', rangeLabelId(range, from: from, to: to)]));
  rows.add(csvRow(['Rentang', _windowLine(h)]));
  rows.add(csvRow(['Dibuat', _dateFull.format(h.generatedAt.toLocal())]));
  rows.add(csvRow(['Total kunjungan', h.visitCount]));
  rows.add(csvRow(['Total baris', h.lineCount]));
  rows.add(csvRow(['Net', formatIDR(h.net)]));

  for (final v in h.visits) {
    rows.add('');
    rows.add(csvRow([
      'KUNJUNGAN',
      _visitTitle(v),
      'Pax',
      v.pax,
      'Pelayan',
      v.waiterName ?? '—',
      'Tutup',
      _dateFull.format(v.closedAt.toLocal()),
      'Net',
      formatIDR(v.net),
    ]));
    rows.add(csvRow([
      'Jam',
      'Item',
      'Varian',
      'Modifier',
      'Course',
      'Qty',
      'Harga',
      'Total',
      'Status',
      'Alasan void',
    ]));
    for (final l in v.lines) {
      rows.add(csvRow([
        _clock.format(l.sentAt.toLocal()),
        l.name,
        l.variantName,
        _mods(l),
        l.course,
        l.qty,
        formatIDR(l.price),
        formatIDR(l.lineTotal),
        _statusId(l),
        l.voidReasonLabel ?? '',
      ]));
    }

    // Bill settlement: per-receipt totals + payments (ADR-0031).
    for (final r in v.receipts) {
      rows.add(csvRow([
        'TAGIHAN',
        r.label.isEmpty ? '—' : r.label,
        'Subtotal',
        formatIDR(r.subtotal),
        'Service',
        formatIDR(r.serviceAmount),
        'Pajak',
        formatIDR(r.taxAmount),
        'Total',
        formatIDR(r.total),
        'Status',
        r.status,
      ]));
      if (r.payments.isNotEmpty) {
        rows.add(csvRow(
            ['Jam', 'Metode', 'Kasir', 'Jumlah', 'Refund', 'Bukti foto']));
        for (final p in r.payments) {
          rows.add(csvRow([
            _clock.format(p.at.toLocal()),
            _method(p.method),
            p.cashierName ?? '—',
            _payAmount(p),
            p.isRefund ? 'Ya' : '',
            p.hasPhoto ? 'Ada' : '—',
          ]));
        }
      }
    }
  }

  return rows.join('\r\n');
}

// ─── PDF ────────────────────────────────────────────────────────────────────

Future<Uint8List> buildOrderHistoryPdf(
  OrderHistory h,
  ReportRange range, {
  Map<String, Uint8List> photos = const {},
  DateTime? from,
  DateTime? to,
}) async {
  final theme = await pdfTheme();
  final doc = pw.Document(theme: theme.base);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pdfPageTheme(theme),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pdfRunningHeader('Riwayat Pesanan · ${rangeLabelId(range, from: from, to: to)}'),
      footer: pdfFooter,
      build: (ctx) => [
        pdfTitleBlock(
          title: 'Riwayat Pesanan',
          subtitle: rangeLabelId(range, from: from, to: to),
          meta: [
            'Rentang: ${_windowLine(h)}',
            'Dibuat: ${_dateFull.format(h.generatedAt.toLocal())}',
            'Kunjungan: ${h.visitCount}  ·  Baris: ${h.lineCount}  ·  Net: ${formatIDR(h.net)}',
          ],
        ),
        pw.SizedBox(height: 16),
        if (h.isEmpty)
          pw.Text('Tidak ada kunjungan pada rentang ini.',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: kPdfInkLo,
                  fontStyle: pw.FontStyle.italic))
        else
          for (final v in h.visits) ..._visitBlock(v, photos),
      ],
    ),
  );

  return doc.save();
}

List<pw.Widget> _visitBlock(
        OrderHistoryVisit v, Map<String, Uint8List> photos) =>
    [
      pw.SizedBox(height: 12),
      _visitHeader(v),
      pdfTable(
        headers: const [
          'Jam',
          'Item',
          'Modifier',
          'Course',
          'Qty',
          'Harga',
          'Total',
          'Status',
        ],
        rows: [
          for (final l in v.lines)
            [
              _clock.format(l.sentAt.toLocal()),
              l.variantName.isEmpty ? l.name : '${l.name} (${l.variantName})',
              _mods(l),
              l.course,
              '${l.qty}',
              formatIDR(l.price),
              formatIDR(l.lineTotal),
              l.isVoided
                  ? 'Batal · ${l.voidReasonLabel ?? ''}'.trim()
                  : _statusId(l),
            ],
        ],
        numericFrom: 4,
      ),
      for (final r in v.receipts) ..._receiptBlock(r, photos),
    ];

pw.Widget _visitHeader(OrderHistoryVisit v) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(color: kPdfInk),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              _visitTitle(v),
              style: pw.TextStyle(
                font: pw.Font.timesBold(),
                fontSize: 11,
                color: kPdfCream,
              ),
            ),
          ),
          pw.Text(
            'Pax ${v.pax}  ·  ${v.waiterName ?? '—'}  ·  ${_dateFull.format(v.closedAt.toLocal())}',
            style: const pw.TextStyle(fontSize: 7.5, color: kPdfHeadFill),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            formatIDR(v.net),
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: kPdfCream),
          ),
        ],
      ),
    );

// One receipt's settlement block: totals strip + payment rows. Each non-cash
// payment renders its proof as an enlarged card under the row (ADR-0031
// amendment) so the amount on the capture is legible for audit.
List<pw.Widget> _receiptBlock(
    OrderHistoryReceipt r, Map<String, Uint8List> photos) {
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
              r.label.isEmpty ? 'Tagihan' : r.label,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: kPdfInk),
            ),
          ),
          pw.Text(
            'Subtotal ${formatIDR(r.subtotal)}  ·  Service ${formatIDR(r.serviceAmount)}  ·  Pajak ${formatIDR(r.taxAmount)}  ·  Total ${formatIDR(r.total)}',
            style: const pw.TextStyle(fontSize: 7.5, color: kPdfInkMd),
          ),
        ],
      ),
    ),
    if (r.payments.isEmpty)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: pw.Text('Belum ada pembayaran tercatat.',
            style: pw.TextStyle(
                fontSize: 7.5,
                color: kPdfInkLo,
                fontStyle: pw.FontStyle.italic)),
      )
    else
      for (final p in r.payments) _paymentRow(p, photos[p.paymentId]),
  ];
}

// Payment text line + (non-cash only) its enlarged proof card, kept together as
// one non-spanning Container so MultiPage never splits a row from its proof
// (ADR-0031 amendment). Cash renders text-only; non-cash always renders a proof
// area — the card if bytes arrived, else a `Bukti tidak termuat` placeholder, so
// a missing proof reads as a flag instead of blending into a cash row.
pw.Widget _paymentRow(OrderHistoryPayment p, Uint8List? photo) {
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
                '${_method(p.method)}  ·  ${p.cashierName ?? '—'}'
                '${p.isRefund ? '  ·  Refund' : ''}',
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: kPdfInk),
              ),
            ),
            pw.Text(_clock.format(p.at.toLocal()),
                style: const pw.TextStyle(fontSize: 7.5, color: kPdfInkLo)),
            pw.SizedBox(width: 10),
            pw.Text(
              _payAmount(p),
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: p.isRefund ? kPdfAccent : kPdfInk),
            ),
          ],
        ),
        if (isNonCash) ...[
          pw.SizedBox(height: 5),
          _proofCard(p, photo),
        ],
      ],
    ),
  );
}

// Bordered proof card: caption tying it back to its payment + the capture at
// BoxFit.contain (never cover — cropping can chop the amount being verified),
// height-capped so a multi-tender visit can't explode the page.
pw.Widget _proofCard(OrderHistoryPayment p, Uint8List? photo) => pw.Container(
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
            'Bukti · ${_method(p.method)}  ·  ${_payAmount(p)}',
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
                  child: pw.Image(pw.MemoryImage(photo),
                      fit: pw.BoxFit.contain),
                ),
              ),
            )
          else
            _proofMissing(),
        ],
      ),
    );

pw.Widget _proofMissing() => pw.Container(
      height: 36,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: kPdfAccent, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text('Bukti tidak termuat',
          style: pw.TextStyle(
              fontSize: 8,
              color: kPdfAccent,
              fontStyle: pw.FontStyle.italic)),
    );
