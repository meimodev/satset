import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:satset/core/printing/bill_struk_data.dart';

/// The single, shared ESC/POS renderer for the MONEY document
/// ([[Tagihan / Struk pembayaran]]). Turns a [BillStrukData] into printer bytes
/// for a 58mm thermal roll. Used by BOTH the server (venue printers) and a
/// client (its own device printers) so output is identical regardless of who
/// transmits — see docs/adr/0023 + 0020.
///
/// Sibling to [StrukRenderer] (the no-money order slip) — kept apart on purpose
/// so the deliberate "Struk carries no money" distinction survives. The title
/// and payment block are driven purely by [BillStrukData.isTagihan].
class BillStrukRenderer {
  static const _paper = PaperSize.mm58;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _clock(DateTime t) {
    final l = t.toLocal();
    return '${_two(l.day)}/${_two(l.month)} ${_two(l.hour)}:${_two(l.minute)}';
  }

  /// Indonesian rupiah, '.' as the thousands separator. Pure — no `intl`, so it
  /// runs identically server- and client-side.
  static String _money(int n) {
    final neg = n < 0;
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}Rp$b';
  }

  static List<int> _kv(Generator g, String k, int v, {bool bold = false}) {
    return g.row([
      PosColumn(
        text: k,
        width: 7,
        styles: PosStyles(bold: bold),
      ),
      PosColumn(
        text: _money(v),
        width: 5,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  /// Indented sub-lines under a printed item: its chosen modifiers and the
  /// guest's item note, so the bill doubles as an order check. See ADR-0026.
  static List<int> _lineExtras(Generator g, BillStrukLine l) {
    final out = <int>[];
    for (final m in l.modifiers) {
      out.addAll(g.text('   $m'));
    }
    if (l.note.trim().isNotEmpty) {
      out.addAll(g.text('   * ${l.note.trim()}'));
    }
    return out;
  }

  static Future<List<int>> render(BillStrukData d) async {
    final profile = await CapabilityProfile.load();
    final g = Generator(_paper, profile);
    final out = <int>[];

    // ── header: venue identity ──
    out.addAll(g.text(
      d.venueName.isEmpty ? 'SatSet' : d.venueName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    if (d.header.trim().isNotEmpty) {
      for (final line in d.header.trim().split('\n')) {
        out.addAll(g.text(line, styles: const PosStyles(align: PosAlign.center)));
      }
    }
    if (d.address.trim().isNotEmpty) {
      out.addAll(g.text(d.address.trim(),
          styles: const PosStyles(align: PosAlign.center)));
    }
    if (d.phone.trim().isNotEmpty) {
      out.addAll(g.text(d.phone.trim(),
          styles: const PosStyles(align: PosAlign.center)));
    }

    // ── document title: Tagihan vs Struk pembayaran ──
    out.addAll(g.hr());
    out.addAll(g.text(
      d.isTagihan ? 'TAGIHAN' : 'STRUK PEMBAYARAN',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));

    // ── meta: table / party / time / which receipt ──
    out.addAll(g.text(
      'Meja ${d.tableLabel}  ·  ${d.pax} org  ·  ${_clock(d.at)}',
      styles: const PosStyles(bold: true),
    ));
    if (d.guestName.trim().isNotEmpty) {
      out.addAll(g.text('Tamu: ${d.guestName.trim()}'));
    }
    if (d.docLabel.trim().isNotEmpty &&
        d.kind != BillDocKind.wholeBill) {
      out.addAll(g.text(d.docLabel.trim(),
          styles: const PosStyles(bold: true)));
    }
    out.addAll(g.hr());

    // ── body lines ──
    if (d.isEven) {
      out.addAll(g.text('Patungan meja:',
          styles: const PosStyles(bold: true)));
      for (final l in d.lines) {
        out.addAll(g.text(
          '  ${l.qty}x ${l.name}${l.variant.isEmpty ? '' : ' (${l.variant})'}',
        ));
        out.addAll(_lineExtras(g, l));
      }
    } else {
      for (final l in d.lines) {
        out.addAll(g.row([
          PosColumn(
            text: '${l.qty}x ${l.name}'
                '${l.variant.isEmpty ? '' : ' (${l.variant})'}',
            width: 8,
          ),
          PosColumn(
            text: l.showPrice ? _money(l.lineTotal) : '',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]));
        out.addAll(_lineExtras(g, l));
      }
    }
    out.addAll(g.hr());

    // ── totals ──
    if (d.isEven) {
      out.addAll(_kv(g, 'Total tagihan', d.billTotal));
      out.addAll(_kv(g, d.docLabel.isEmpty ? 'Bagian' : d.docLabel, d.total,
          bold: true));
    } else {
      out.addAll(_kv(g, 'Subtotal', d.subtotal));
      if (d.serviceAmount > 0) out.addAll(_kv(g, 'Layanan', d.serviceAmount));
      if (d.taxAmount > 0) out.addAll(_kv(g, 'Pajak', d.taxAmount));
      out.addAll(_kv(g, 'TOTAL', d.total, bold: true));
    }

    // ── payment block (only when paid ⇒ Struk pembayaran) ──
    if (!d.isTagihan) {
      out.addAll(g.hr(ch: '-'));
      for (final p in d.payments) {
        out.addAll(_kv(
          g,
          p.isRefund ? 'Refund ${p.methodLabel}' : 'Bayar ${p.methodLabel}',
          p.amount,
        ));
      }
      if (d.tenderedTotal != null && d.tenderedTotal! > 0) {
        out.addAll(_kv(g, 'Tunai diterima', d.tenderedTotal!));
        final change = d.tenderedTotal! - d.paidNet;
        if (change > 0) out.addAll(_kv(g, 'Kembali', change));
      }
      if (d.outstanding > 0) {
        out.addAll(_kv(g, 'SISA', d.outstanding, bold: true));
      } else {
        out.addAll(g.text('LUNAS',
            styles: const PosStyles(align: PosAlign.center, bold: true)));
      }
    }

    // ── footer ──
    out.addAll(g.hr());
    out.addAll(g.text('Terima kasih',
        styles: const PosStyles(align: PosAlign.center)));
    if (d.footer.trim().isNotEmpty) {
      for (final line in d.footer.trim().split('\n')) {
        out.addAll(g.text(line, styles: const PosStyles(align: PosAlign.center)));
      }
    }
    out.addAll(g.feed(2));
    out.addAll(g.cut());
    return out;
  }
}
