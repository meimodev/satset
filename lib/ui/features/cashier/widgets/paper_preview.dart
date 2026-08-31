import 'package:flutter/material.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/l10n/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
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
          _row(_title(l10n), d.docLabel.isEmpty ? '' : d.docLabel, bold: true),
          if (d.isDebtSlip) ...[
            _row(
              d.memberName,
              formatClockId(d.at.toIso8601String()),
              bold: true,
            ),
            if (d.cashierName.isNotEmpty)
              _row(l10n.strukDebtCashier(d.cashierName), '', faint: true),
            _rule(dashed: true),
            _row(
              d.payments.isEmpty
                  ? l10n.strukDebtPaid
                  : d.payments.first.methodLabel,
              _money(d.total),
              bold: true,
            ),
            _row(l10n.strukDebtBalance, _money(d.debtBalanceAfter), bold: true),
          ] else ...[
            _row(
              d.guestName.isEmpty
                  ? l10n.tableNamed(d.tableLabel)
                  : '${d.tableLabel} · ${d.guestName}',
              formatClockId(d.at.toIso8601String()),
              faint: true,
            ),
            if (d.pax > 0) _row(l10n.rcpPaxCount(d.pax), '', faint: true),
            _rule(dashed: true),
            for (final l in d.lines) ..._line(l),
            _rule(dashed: true),
            _row(l10n.strukSubtotal, _money(d.subtotal)),
            // The Diskon row's position is the arithmetic, not decoration —
            // above Layanan when it reduced their base, below Pajak otherwise
            // (ADR-0038). Printing it in a fixed slot prints a sum that fails.
            if (d.discountAmount > 0 && d.taxAfterDiscount)
              _row(
                d.discountLabel.isEmpty ? l10n.strukDiscount : d.discountLabel,
                '−${_money(d.discountAmount)}',
              ),
            if (d.serviceAmount > 0)
              _row(l10n.strukService, _money(d.serviceAmount)),
            if (d.taxAmount > 0) _row(l10n.strukTax, _money(d.taxAmount)),
            if (d.discountAmount > 0 && !d.taxAfterDiscount)
              _row(
                d.discountLabel.isEmpty ? l10n.strukDiscount : d.discountLabel,
                '−${_money(d.discountAmount)}',
              ),
            _rule(),
            _row(l10n.strukTotal, _money(d.total), bold: true),
            if (d.kind == BillDocKind.evenReceipt && d.billTotal != d.total)
              _row(l10n.strukBillTotal, _money(d.billTotal), faint: true),
            if (d.payments.isNotEmpty) ...[
              _rule(dashed: true),
              for (final p in d.payments)
                _row(
                  p.isRefund
                      ? l10n.rcpRefundLine(p.methodLabel)
                      : p.methodLabel,
                  _money(p.amount),
                ),
              // Both conditions are the renderer's, not this widget's: the roll
              // omits a zero change line and prints the settled word centred
              // with no figure beside it. A preview that adds "Kembalian Rp. 0"
              // and "LUNAS 0" is showing the cashier a slip that will not come
              // out of the printer, which is the drift this widget exists to
              // catch.
              if (d.tenderedTotal != null && d.tenderedTotal! > 0) ...[
                _row(
                  l10n.strukCashReceived,
                  _money(d.tenderedTotal!),
                  faint: true,
                ),
                if (d.tenderedTotal! - d.paidNet > 0)
                  _row(
                    l10n.cpdChange,
                    _money(d.tenderedTotal! - d.paidNet),
                    faint: true,
                  ),
              ],
              if (d.outstanding > 0)
                _row(l10n.strukOutstanding, _money(d.outstanding), bold: true)
              else
                _centred(l10n.strukSettled),
            ] else if (d.outstanding > 0)
              _row(l10n.strukOutstanding, _money(d.outstanding), bold: true),
            // Who each share was for (ADR-0118). The roll prints this block on
            // the settled whole-bill doc, so the preview must too — a named row
            // on paper the cashier cannot see before printing is exactly the
            // drift this preview exists to prevent.
            if (!d.isTagihan && d.receiptOwners.isNotEmpty) ...[
              _rule(dashed: true),
              _row(l10n.strukReceiptOwners, '', bold: true),
              for (final row in d.receiptOwners) _row(row, ''),
            ],
          ],
          _rule(),
          if (d.footer.isNotEmpty) _centre(d.footer, faint: true),
          _centre(
            d.thankYou.isEmpty ? l10n.strukThanks : d.thankYou,
            faint: true,
          ),
          if (d.social.isNotEmpty) _centre(d.social, faint: true),
        ],
      ),
    );
  }

  String _title(AppL10n l10n) => switch (d.kind) {
    BillDocKind.wholeBill =>
      d.payments.isEmpty ? l10n.strukBillTitle : l10n.strukReceiptTitle,
    BillDocKind.itemizedReceipt => l10n.rcpItemizedReceipt,
    BillDocKind.evenReceipt => l10n.rcpSplitReceipt,
    BillDocKind.debtCollection => l10n.strukDebtTitle,
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
    if (l.hasDiscount)
      _row('  ${l.discountLabel}', '−${_money(l.discountAmount)}', faint: true),
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

  /// A line the roll centres and prints without a figure beside it.
  Widget _centred(String text) => Padding(
    padding: const EdgeInsets.only(bottom: Sp.sHair),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: SatType.monoM(color: satPaperInk),
    ),
  );

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
