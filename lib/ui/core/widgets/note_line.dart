import 'package:flutter/widgets.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';

/// A quiet one-line note — a guest note or an item note. Reference text the
/// staff jotted down, **not** an alert: it never uses an attention/`urgent`
/// colour or loud iconography. Shared by the table detail, review, the Pesanan
/// board, and the KDS. See CONTEXT.md "Guest note / Item note".
///
/// [alert] is the one exception, and it exists for the KDS. The same string is
/// two different things depending on where it is read: at the table
/// "Alergi kacang" is a jotting, and at the pass it is the constraint that
/// decides whether the plate goes out or into the bin. The rule above is about
/// notes as reference; a cook reading one at 1–2 m through steam is not reading
/// reference. Only the kitchen ticket card passes it — see ADR-0051.
class NoteLine extends StatelessWidget {
  final String text;

  /// Low-emphasis lead-in, e.g. "Catatan" (guest note) or "Instruksi khusus"
  /// (item note).
  final String label;

  /// Renders the note as a filled `urgentSoft` block with high-contrast ink
  /// rather than a grey line. KDS only.
  final bool alert;

  const NoteLine({
    super.key,
    required this.text,
    this.label = 'Catatan',
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = text.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    final sc = context.sat;
    final body = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: SatType.labelS(color: alert ? sc.textHi : sc.textLo),
          ),
          TextSpan(
            text: t,
            style: alert
                ? SatType.labelM(color: sc.textHi)
                : SatType.bodyM(color: sc.textMd),
          ),
        ],
      ),
    );
    if (!alert) return body;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s2,
        vertical: Sp.s1h,
      ),
      decoration: SatBox.d(color: sc.urgentSoft, borderRadius: SatR.md),
      child: body,
    );
  }
}
