import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../design/spacing.dart';
import 'sat_icon_button.dart';

/// The top of a bottom sheet (ADR-0055).
///
/// Owns the padding, the leading slot and — the part every sheet was
/// re-declaring — the close button, including its tooltip. What sits in the
/// middle is the sheet's own business: a menu item's photo and description, a
/// ticket's status chip and modifiers.
class SatSheetHeader extends StatelessWidget {
  /// Thumbnail, avatar, glyph. Sits before [child] at the top of the row.
  final Widget? leading;
  final Widget child;
  final VoidCallback onClose;
  final EdgeInsets padding;

  const SatSheetHeader({
    super.key,
    required this.child,
    required this.onClose,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(Sp.s4, Sp.s3, Sp.s2, Sp.s3h),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Sp.s3h)],
          Expanded(child: child),
          const SizedBox(width: Sp.s2),
          SatIconButton.plain(
            icon: Icons.close,
            tooltip: AppStrings.close,
            size: 36,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}
