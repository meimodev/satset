/// The one way to put something above the current route (ADR-0061).
///
/// Every entry point here forces `useRootNavigator: true`. That is the whole
/// reason the file exists: on a phone `AppShell` paints the shell navigator as
/// `Positioned.fill` *underneath* the floating tab bar in the same `Stack`, so
/// an overlay pushed onto the shell navigator renders behind the tab bar — and
/// the tab bar stays tappable through what is supposed to be a modal barrier.
/// Material's default for that flag is `false`, which is why this kept
/// happening; `test/design_tokens_test.dart` now fails the raw calls outright.
///
/// Colour, corner radius and elevation come from `bottomSheetTheme` /
/// `dialogTheme` — never pass them here. Safe area and keyboard (`viewInsets`)
/// padding stay the body's job, as they always have been.
library;

import 'package:flutter/material.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/colors.dart';

/// Modal bottom sheet. Returns the value the body pops with, `null` on dismiss.
///
/// [bare] drops the themed background for a body that draws its own chrome —
/// a `DraggableScrollableSheet`, a card that floats clear of the edges.
///
/// [scrollControlled] defaults on so the sheet sizes to its content and rides
/// above the keyboard. Turn it off only for a body that genuinely wants
/// Material's 9/16-of-screen cap.
Future<T?> showSatSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool bare = false,
  bool dismissible = true,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: scrollControlled,
    isDismissible: dismissible,
    enableDrag: dismissible,
    barrierColor: satBarrier,
    backgroundColor: bare ? Colors.transparent : null,
    builder: builder,
  );
}

/// Centred modal dialog. Returns the value the body pops with, `null` on
/// dismiss. Pass `dismissible: false` for work the user must not tap away.
Future<T?> showSatDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: dismissible,
    barrierColor: satBarrier,
    builder: builder,
  );
}

/// Edge-anchored panel — a sheet that comes in from the side instead of the
/// bottom, for filter rails and the like on a wide screen.
Future<T?> showSatDrawer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  AlignmentGeometry alignment = Alignment.centerRight,
  bool dismissible = true,
  String? barrierLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: dismissible,
    barrierLabel: barrierLabel ?? AppStrings.close,
    barrierColor: satBarrier,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => Align(alignment: alignment, child: builder(ctx)),
  );
}
