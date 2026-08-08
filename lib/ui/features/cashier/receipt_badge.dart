import 'package:flutter/material.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/receipt_visuals.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';

/// The letter a [[Split bill]] receipt is known by — `A`, `B`, `C` — in its
/// own hue. One glyph, four surfaces: the receipt card's header, each owned
/// item's origin on the lines list, the assign sheet's rows, and the `/kasir`
/// tile's progress strip. Colour is the scan aid; the **letter** is the
/// identity, so a colour-blind cashier and a monochrome printed slip both
/// still work. See ADR-0063.
///
/// [filled] carries paid-ness on the `/kasir` strip only. Everywhere inside a
/// bill the badge is pure identity (always filled) — the card's own
/// Lunas/Belum chip owns the money state, and a guest's letter must not change
/// appearance the moment they pay.
class ReceiptBadge extends StatelessWidget {
  /// A single letter `A`–`Z`. Non-letter labels never reach here — call sites
  /// gate on `isReceiptLetter`.
  final String label;

  /// Optional unit count, rendered `A×2`. Used on the lines list where one
  /// dish can be split across receipts.
  final int? count;

  /// Solid hue fill (paid / plain identity) vs hue-outlined tint (unpaid).
  final bool filled;

  /// Tighter box for inline runs (line chips, the `/kasir` strip).
  final bool dense;

  /// The unassigned-units chip: reads `?×1` in [SatColors.warn], matching the
  /// amber tint the lines list already paints on a not-fully-assigned row.
  final bool unassigned;

  const ReceiptBadge(
    this.label, {
    this.count,
    this.filled = true,
    this.dense = false,
    super.key,
  }) : unassigned = false;

  const ReceiptBadge.unassigned({required int this.count, super.key})
    : label = '?',
      filled = false,
      dense = true,
      unassigned = true;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final hue = unassigned ? sc.warn : receiptHue(label);
    final text = count == null ? label : '$label×$count';
    final style = dense
        ? SatType.labelS(
            color: filled ? receiptInk : (unassigned ? hue : sc.textHi),
          )
        : SatType.labelM(color: filled ? receiptInk : sc.textHi);
    return Container(
      constraints: BoxConstraints(minWidth: dense ? 0 : Sp.s6),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Sp.s1h : Sp.s2,
        vertical: dense ? Sp.sHair : Sp.s1,
      ),
      alignment: Alignment.center,
      decoration: SatBox.d(
        // Unfilled leans on a tint rather than the bare surface: a pastel hue
        // as text on bone (Terang) is too low-contrast to read at 12pt, so the
        // border carries the identity and textHi carries the letter.
        color: filled ? hue : hue.withValues(alpha: 0.18),
        borderRadius: SatR.a(6),
        border: filled ? null : SatB.all(color: hue, width: 1.5),
      ),
      child: Text(text, style: style),
    );
  }
}
