import 'package:flutter/widgets.dart';

/// How much bottom space the shell's own chrome eats out of its child.
///
/// The phone shell floats its tab bar **over** the page — a `Stack`, not a
/// `bottomNavigationBar` — so a vertical scroll view has to end above it or
/// its last row is unreachable under a translucent slab.
///
/// The number is published by the thing that draws the bar. Asking
/// `MediaQuery` "am I a phone" answers a different question and gets it wrong
/// on the two screens that are mounted **both** inside the shell (`/counter`)
/// and pushed outside it on the root navigator (`/table/:id/menu`,
/// `/order/new`, `/takeaway/:visitId/menu`): same widget, same width, one bar
/// between them. That is why the old `SatLayout.bottomInset` is gone.
///
/// Zero when nothing is floating — the tablet shell (side rail, no bottom
/// chrome) and every root-navigator push, which have no `ShellInset` above
/// them at all.
class ShellInset extends InheritedWidget {
  /// Clearance, in logical pixels, between the bottom of the child area and
  /// the top edge of the floating chrome.
  final double bottom;

  const ShellInset({super.key, required this.bottom, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(ShellInset old) => old.bottom != bottom;
}

extension ShellInsetX on BuildContext {
  /// Clearance a vertical scroll view owes the shell's floating chrome.
  ///
  /// Add it to the scroll view's bottom padding. A screen with its own
  /// floating footer stacks the two: `shellInset` clears the bar, the
  /// screen's own constant clears its footer.
  double get shellInset => ShellInset.of(this);
}
