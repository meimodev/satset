import 'package:flutter/widgets.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// A quiet one-line note — a guest note or an item note. Reference text the
/// staff jotted down, **not** an alert: it never uses an attention/`urgent`
/// colour or loud iconography. Shared by the table detail, review, the Pesanan
/// board, and the KDS. See CONTEXT.md "Guest note / Item note".
class NoteLine extends StatelessWidget {
  final String text;

  /// Low-emphasis lead-in, e.g. "Catatan" (guest note) or "Instruksi khusus"
  /// (item note).
  final String label;

  const NoteLine({super.key, required this.text, this.label = 'Catatan'});

  @override
  Widget build(BuildContext context) {
    final t = text.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    final sc = context.sat;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: SatType.labelS(color: sc.textLo),
          ),
          TextSpan(
            text: t,
            style: SatType.bodyM(color: sc.textMd),
          ),
        ],
      ),
    );
  }
}
