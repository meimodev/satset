import 'package:flutter/material.dart';

import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';

/// The slip as it will come off the roll, drawn from the **same**
/// [BillStrukData] the ESC/POS renderer is handed (ADR-0066).
///
/// One source of truth, two renderers: bytes for the printer, this for the
/// screen. That is a real duplication and it is deliberate — the alternative is
/// the cashier committing a money document sight-unseen, which is how a wrong
/// table label reaches a guest's hand.
///
/// Deliberately paper-coloured on both themes. This is a picture of a physical
/// object, not a surface of the app, and re-skinning it would make the preview
/// disagree with the thing it is previewing.
class PaperPreview extends StatelessWidget {
  final BillStrukData d;
  const PaperPreview(this.d, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    // 58mm at the roll's own aspect. Fixed, because a slip that reflows to the
    // pane width stops being a preview of anything.
    width: 280,
    padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: Sp.s5),
    color: satPaperGround,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _centre(d.venueName, bold: true),
        if (d.tagline.isNotEmpty) _centre(d.tagline, faint: true),
        if (d.address.isNotEmpty) _centre(d.address, faint: true),
        if (d.phone.isNotEmpty) _centre(d.phone, faint: true),
        if (d.header.isNotEmpty) _centre(d.header, faint: true),
        _rule(),
        _row(_title, d.docLabel.isEmpty ? '' : d.docLabel, bold: true),
        _row(
          d.guestName.isEmpty
              ? 'Meja ${d.tableLabel}'
              : '${d.tableLabel} · ${d.guestName}',
          formatClockId(d.at.toIso8601String()),
          faint: true,
        ),
        if (d.pax > 0) _row('${d.pax} tamu', '', faint: true),
        _rule(dashed: true),
        for (final l in d.lines) ..._line(l),
        _rule(dashed: true),
        _row('Subtotal', _money(d.subtotal)),
        // The Diskon row's position is the arithmetic, not decoration —
        // above Layanan when it reduced their base, below Pajak otherwise
        // (ADR-0038). Printing it in a fixed slot prints a sum that fails.
        if (d.discountAmount > 0 && d.taxAfterDiscount)
          _row(d.discountLabel, '−${_money(d.discountAmount)}'),
        if (d.serviceAmount > 0) _row('Layanan', _money(d.serviceAmount)),
        if (d.taxAmount > 0) _row('Pajak', _money(d.taxAmount)),
        if (d.discountAmount > 0 && !d.taxAfterDiscount)
          _row(d.discountLabel, '−${_money(d.discountAmount)}'),
        _rule(),
        _row('TOTAL', _money(d.total), bold: true),
        if (d.kind == BillDocKind.evenReceipt && d.billTotal != d.total)
          _row('Total tagihan', _money(d.billTotal), faint: true),
        if (d.payments.isNotEmpty) ...[
          _rule(dashed: true),
          for (final p in d.payments)
            _row(
              p.isRefund ? '${p.methodLabel} (refund)' : p.methodLabel,
              _money(p.amount),
            ),
          if (d.tenderedTotal != null) ...[
            _row('Tunai diterima', _money(d.tenderedTotal!), faint: true),
            _row(
              'Kembalian',
              _money(d.tenderedTotal! - d.paidNet),
              faint: true,
            ),
          ],
          _row(
            d.outstanding > 0 ? 'SISA' : 'LUNAS',
            d.outstanding > 0 ? _money(d.outstanding) : '0',
            bold: true,
          ),
        ] else if (d.outstanding > 0)
          _row('SISA', _money(d.outstanding), bold: true),
        _rule(),
        if (d.footer.isNotEmpty) _centre(d.footer, faint: true),
        _centre(
          d.thankYou.isEmpty ? 'Terima kasih' : d.thankYou,
          faint: true,
        ),
        if (d.social.isNotEmpty) _centre(d.social, faint: true),
      ],
    ),
  );

  String get _title => switch (d.kind) {
    BillDocKind.wholeBill =>
      d.payments.isEmpty ? 'TAGIHAN' : 'STRUK PEMBAYARAN',
    BillDocKind.itemizedReceipt => 'STRUK',
    BillDocKind.evenReceipt => 'STRUK BAGIAN',
  };

  /// The roll prints no currency symbol — the grouping alone is the number.
  String _money(int v) => formatIDR(v).replaceFirst('Rp ', '');

  List<Widget> _line(BillStrukLine l) => [
    _row(
      '${l.qty}× ${l.name}${l.variant.isEmpty ? '' : ' ${l.variant}'}',
      l.showPrice ? _money(l.lineTotal) : '',
    ),
    for (final m in l.modifiers) _sub(m),
    if (l.note.isNotEmpty) _sub('* ${l.note}'),
    if (l.hasDiscount) _row('  ${l.discountLabel}', '−${_money(l.discountAmount)}', faint: true),
  ];

  Widget _centre(String text, {bool bold = false, bool faint = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Sp.sHair),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: bold
              ? SatType.monoM(color: satPaperInk)
              : SatType.monoS(color: faint ? satPaperFaint : satPaperInk),
        ),
      );

  Widget _row(
    String left,
    String right, {
    bool bold = false,
    bool faint = false,
  }) {
    final style = bold
        ? SatType.monoM(color: satPaperInk)
        : SatType.monoS(color: faint ? satPaperFaint : satPaperInk);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sHair),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(left, style: style)),
          if (right.isNotEmpty) Text(right, style: style),
        ],
      ),
    );
  }

  Widget _sub(String text) => Padding(
    padding: const EdgeInsets.only(left: Sp.s3, bottom: Sp.sHair),
    child: Text(text, style: SatType.monoS(color: satPaperFaint)),
  );

  Widget _rule({bool dashed = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
    child: Text(
      List.filled(32, dashed ? '-' : '=').join(),
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: SatType.monoS(color: satPaperFaint),
    ),
  );
}

/// The preview wrapped for a modal: scrollable paper on a dimmed ground, so a
/// long bill is readable without the slip resizing.
class PaperPreviewBody extends StatelessWidget {
  final BillStrukData data;
  const PaperPreviewBody(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      color: sc.bg0,
      padding: const EdgeInsets.symmetric(vertical: Sp.s4),
      child: SingleChildScrollView(
        child: Center(
          child: Material(
            elevation: 2,
            borderRadius: SatR.a(4),
            clipBehavior: Clip.antiAlias,
            child: PaperPreview(data),
          ),
        ),
      ),
    );
  }
}
