import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:satset/core/printing/printer_branding.dart';
import 'package:satset/core/printing/struk_data.dart';
import 'package:satset/l10n/app_localizations.dart';

/// The single, shared ESC/POS renderer. Turns a [StrukData] into printer bytes
/// for a 58mm thermal roll. Used by BOTH the server (venue printers) and a
/// client (its own device printers) so output is identical regardless of who
/// transmits — see docs/adr/0020-two-scope-printers-shared-renderer.md.
///
/// `esc_pos_utils_plus` loads its capability profile from a package asset via
/// `rootBundle`; the embedded server runs in-process inside the Flutter app, so
/// this works server-side too.
///
/// Copy follows the **printing device's** language (ADR-0083) — the server for
/// a venue printer, the handset for a device one — which is why [AppL10n]
/// arrives as a parameter: a shelf route holds no `BuildContext` and no `Ref`,
/// and passes `satL10n`. Venue-authored lines (name, tagline, header, footer,
/// thank-you) are never translated.
class StrukRenderer {
  static const _paper = PaperSize.mm58;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _clock(DateTime t) {
    final l = t.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  /// Renders a full guest order-confirmation struk (no prices).
  static Future<List<int>> render(AppL10n l, StrukData d) async {
    final profile = await CapabilityProfile.load();
    final g = Generator(_paper, profile);
    final out = <int>[];

    // Header: optional logo, venue name large, tagline, header, address/phone.
    out.addAll(logoRasterBytes(g, d.logoBytes));
    out.addAll(
      g.text(
        d.venueName.isEmpty ? 'SatSet' : d.venueName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    if (d.tagline.trim().isNotEmpty) {
      out.addAll(
        g.text(
          d.tagline.trim(),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    if (d.header.trim().isNotEmpty) {
      for (final line in d.header.trim().split('\n')) {
        out.addAll(
          g.text(line, styles: const PosStyles(align: PosAlign.center)),
        );
      }
    }
    if (d.address.trim().isNotEmpty) {
      out.addAll(
        g.text(
          d.address.trim(),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    if (d.phone.trim().isNotEmpty) {
      out.addAll(
        g.text(d.phone.trim(), styles: const PosStyles(align: PosAlign.center)),
      );
    }
    if (d.social.trim().isNotEmpty) {
      out.addAll(
        g.text(
          d.social.trim(),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    out.addAll(g.hr());

    // Table + party + time.
    out.addAll(
      g.text(
        l.strukTableLine(d.tableLabel, d.pax, _clock(d.at)),
        styles: const PosStyles(bold: true),
      ),
    );
    if (d.guestName.trim().isNotEmpty) {
      out.addAll(g.text(l.strukGuest(d.guestName.trim())));
    }
    if (d.guestNote.trim().isNotEmpty) {
      out.addAll(g.text(l.strukNote(d.guestNote.trim())));
    }
    out.addAll(g.hr());

    // Lines: "qty x name", then variant / modifiers / note indented.
    for (final l in d.lines) {
      out.addAll(
        g.text(
          '${l.qty}x ${l.name}${l.variant.isEmpty ? '' : ' (${l.variant})'}',
          styles: const PosStyles(bold: true),
        ),
      );
      for (final m in l.modifiers) {
        if (m.trim().isEmpty) continue;
        out.addAll(g.text('  + ${m.trim()}'));
      }
      if (l.note.trim().isNotEmpty) {
        out.addAll(g.text('  * ${l.note.trim()}'));
      }
    }
    out.addAll(g.hr());

    // Footer: "verifikasi pesanan" + optional receipt footer + sign-off.
    out.addAll(
      g.text(l.strukVerify, styles: const PosStyles(align: PosAlign.center)),
    );
    if (d.footer.trim().isNotEmpty) {
      for (final line in d.footer.trim().split('\n')) {
        out.addAll(
          g.text(line, styles: const PosStyles(align: PosAlign.center)),
        );
      }
    }
    final thanks = d.thankYou.trim().isEmpty
        ? l.strukThanks
        : d.thankYou.trim();
    out.addAll(g.text(thanks, styles: const PosStyles(align: PosAlign.center)));
    out.addAll(g.feed(2));
    out.addAll(g.cut());
    return out;
  }

  /// A short slip used by the "Tes cetak" action to prove a printer is wired.
  static Future<List<int>> renderTest(
    AppL10n l,
    String label,
    String host,
    int port,
  ) async {
    final profile = await CapabilityProfile.load();
    final g = Generator(_paper, profile);
    final out = <int>[];
    out.addAll(
      g.text(
        l.strukTestTitle,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    out.addAll(g.hr());
    out.addAll(g.text(label, styles: const PosStyles(align: PosAlign.center)));
    out.addAll(
      g.text('$host:$port', styles: const PosStyles(align: PosAlign.center)),
    );
    out.addAll(
      g.text(
        _clock(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    out.addAll(
      g.text(
        l.strukTestOk,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    out.addAll(g.feed(2));
    out.addAll(g.cut());
    return out;
  }
}
