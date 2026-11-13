import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/core/localization/locale_view_model.dart';

void safePop(BuildContext context, {String fallback = '/tables'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

/// Sends the system back (button or gesture) through [safePop], so it does
/// what the screen's own back arrow does. For a route outside the shell that
/// can become the only page — after a `context.go` to it — where back would
/// otherwise close the app with no `ExitGuard` to catch it.
class SafePopScope extends StatelessWidget {
  final String fallback;
  final Widget child;
  const SafePopScope({
    super.key,
    this.fallback = '/tables',
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) safePop(context, fallback: fallback);
    },
    child: child,
  );
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
      label: semanticLabel ?? context.l10n.back,
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
