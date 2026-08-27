import 'dart:typed_data';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Live receipt-branding preview (ADR-0033). A Flutter mock of a 58mm thermal
/// slip — NOT the real ESC/POS bytes (those aren't renderable here). It mirrors
/// the money-doc renderer layout (logo → name → tagline → address → phone →
/// social → header → lines → totals → footer → thank-you → QR) so the admin
/// sees, roughly, what prints as they type. Fed by the in-progress draft, so it
/// updates on every keystroke.
class ReceiptPreviewData {
  final Uint8List? logoBytes;
  final String venueName;
  final String address;
  final String phone;
  final String tagline;
  final String social;
  final String header;
  final String footer;
  final String thankYou;
  final String qrUrl;
  final String qrCaption;

  /// What the venue actually charges. The preview prints the tax and service
  /// lines the same way settlement computes them — a venue that charges
  /// neither must not see a tax line on its own receipt.
  final TaxServiceConfig charges;

  const ReceiptPreviewData({
    this.logoBytes,
    this.venueName = '',
    this.address = '',
    this.phone = '',
    this.tagline = '',
    this.social = '',
    this.header = '',
    this.footer = '',
    this.thankYou = '',
    this.qrUrl = '',
    this.qrCaption = '',
    this.charges = const TaxServiceConfig(
      taxEnabled: false,
      taxRateBps: 0,
      serviceEnabled: false,
      serviceMode: 'percent',
      serviceRateBps: 0,
      serviceFixedAmount: 0,
    ),
  });
}

class ReceiptPreview extends StatelessWidget {
  final ReceiptPreviewData data;
  const ReceiptPreview({super.key, required this.data});

  // Paper-coloured thermal mock; fixed ink colours (not theme) — a receipt is
  // always dark ink on white paper regardless of the app's light/dark mode.
  static const _paper = Color(0xFFFDFDFB);
  static const _ink = Color(0xFF1A1A1A);
  static const _inkLo = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    final d = data;
    // Same fallback the renderers use (`bill_struk_renderer`, `struk_renderer`)
    // — a preview that invents its own sign-off is a preview of nothing.
    final money = computeBreakdown(113000, d.charges);
    final thanks = d.thankYou.trim().isEmpty
        ? context.l10n.strukThanks
        : d.thankYou.trim();
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: SatBox.d(
        color: _paper,
        borderRadius: SatR.a(6),
        border: SatB.all(color: const Color(0xFFE3E0D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.logoBytes != null) ...[
            Center(
              child: Image.memory(
                d.logoBytes!,
                height: 56,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _center(
            d.venueName.isEmpty
                ? context.l10n.rcpVenueNamePlaceholder
                : d.venueName,
            size: 15,
            weight: FontWeight.w700,
          ),
          if (d.tagline.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            _center(d.tagline.trim(), size: 10.5, color: _inkLo, italic: true),
          ],
          const SizedBox(height: 6),
          if (d.address.trim().isNotEmpty)
            _center(d.address.trim(), size: 10.5, color: _inkLo),
          if (d.phone.trim().isNotEmpty)
            _center(d.phone.trim(), size: 10.5, color: _inkLo),
          if (d.social.trim().isNotEmpty)
            _center(d.social.trim(), size: 10.5, color: _inkLo),
          if (d.header.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _center(d.header.trim(), size: 11),
          ],
          _dashes(),
          _center(
            context.l10n.strukBillTitle,
            size: 11.5,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 2),
          _line(context.l10n.rcpSampleTable, 'No. 0042', muted: true),
          _dashes(),
          _line('2× Nasi Goreng', formatIDR(60000)),
          _line('1× Es Teh', formatIDR(8000)),
          _line('1× Ayam Bakar', formatIDR(45000)),
          _dashes(),
          _line(context.l10n.strukSubtotal, formatIDR(money.subtotal)),
          if (money.serviceAmount > 0)
            _line(
              d.charges.serviceMode == 'fixed'
                  ? context.l10n.strukService
                  : '${context.l10n.strukService} '
                        '${_pct(d.charges.serviceRateBps)}',
              formatIDR(money.serviceAmount),
            ),
          if (money.taxAmount > 0)
            _line(
              '${context.l10n.strukTax} ${_pct(d.charges.taxRateBps)}',
              formatIDR(money.taxAmount),
            ),
          const SizedBox(height: 2),
          _line(context.l10n.strukTotal, formatIDR(money.total), strong: true),
          _dashes(),
          if (d.footer.trim().isNotEmpty) ...[
            _center(d.footer.trim(), size: 10.5, color: _inkLo),
            const SizedBox(height: 8),
          ],
          _center(thanks, size: 11, weight: FontWeight.w600),
          if (d.qrUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: d.qrUrl.trim(),
                version: QrVersions.auto,
                size: 96,
                padding: EdgeInsets.zero,
                backgroundColor: _paper,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _ink,
                ),
              ),
            ),
            if (d.qrCaption.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _center(d.qrCaption.trim(), size: 10, color: _inkLo),
            ],
          ],
        ],
      ),
    );
  }

  Widget _center(
    String text, {
    double size = 11,
    Color color = _ink,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: SatType.mono(size: size, color: color, weight: weight).copyWith(
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.35,
      ),
    );
  }

  Widget _line(
    String left,
    String right, {
    bool strong = false,
    bool muted = false,
  }) {
    final color = muted ? _inkLo : _ink;
    final w = strong ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              left,
              style: SatType.mono(size: 11, color: color, weight: w),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            right,
            style: SatType.mono(size: 11, color: color, weight: w),
          ),
        ],
      ),
    );
  }

  /// `1100` → `11%`, `250` → `2.5%`.
  static String _pct(int bps) {
    final v = bps / 100.0;
    return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}%';
  }

  Widget _dashes() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      '------------------------------',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: SatType.monoS(color: _inkLo),
    ),
  );
}
