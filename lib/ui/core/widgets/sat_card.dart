import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'anim.dart';

/// The app's card surface (ADR-0055).
///
/// Generalises `TabletCard` off the tablet shell. Three shapes:
/// [SatCard.plain] is a surface, [SatCard.section] adds the caps header that
/// eighteen private `_XCard` classes were each drawing by hand, and
/// [SatCard.tappable] adds press feedback and the `Semantics` that a
/// `GestureDetector` around a card never remembers to carry.
///
/// Screen-specific *composition* still belongs in the screen. This owns the
/// surface, the header, and the press behaviour — not the layout inside.
class SatCard extends StatelessWidget {
  /// Section caps. Uppercased here; pass it in sentence case.
  final String? header;
  final Widget? headerTrailing;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// Raises the card onto the next step of the neutral ramp and firms its
  /// border. For a card that *is* a selection, not one that merely contains
  /// one.
  final bool selected;

  const SatCard.plain({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.s5),
  }) : header = null,
       headerTrailing = null,
       onTap = null,
       selected = false;

  const SatCard.section({
    super.key,
    required this.header,
    required this.child,
    this.headerTrailing,
    this.padding = const EdgeInsets.all(Sp.s5),
  }) : onTap = null,
       selected = false;

  const SatCard.tappable({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(Sp.s5),
    this.selected = false,
    this.header,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final body = Container(
      decoration: SatBox.d(
        color: selected ? sc.bg3 : sc.bg2,
        border: SatB.all(color: selected ? sc.border2 : sc.border0),
        borderRadius: SatR.card,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    header!.toUpperCase(),
                    style: SatType.caption(color: sc.textLo),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: Sp.s3),
          ],
          child,
        ],
      ),
    );

    if (onTap == null) return body;

    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        child: GestureDetector(onTap: onTap, child: body),
      ),
    );
  }
}
