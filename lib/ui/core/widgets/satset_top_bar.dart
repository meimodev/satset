import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

class SatBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  /// Overrides the screen-reader name. Defaults to "Kembali"; pass something
  /// specific when the glyph is not a back arrow.
  final String? semanticLabel;
  const SatBackButton({
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_back,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final fg = SatShape.brutal && SatShape.brutalPaper
        ? SatShape.ink
        : sc.textHi;
    return Semantics(
      button: true,
      label: semanticLabel ?? AppStrings.back,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: SatBox.d(
            color: SatShape.brutal
                ? (SatShape.brutalPaper ? sc.bg1 : sc.bg2)
                : sc.bg2,
            borderRadius: SatR.a(12),
            border: SatB.all(
              color: SatShape.brutal ? SatShape.ink : sc.border0,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}
