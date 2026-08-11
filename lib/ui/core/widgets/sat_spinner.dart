import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/spacing.dart';

/// Two sizes, because there turned out to be exactly two jobs (ADR-0055).
enum SatSpinnerSize {
  /// Inline: beside a row's trailing edge, inside a card, next to a label.
  sm,

  /// Standalone: the only thing on an otherwise empty screen.
  md,
}

/// The busy indicator (ADR-0055).
///
/// The sign-in screen drew four of these at 28, 24, 22 and 22 logical pixels —
/// and one of them was 24 wide by 22 tall, an oval nobody chose. A spinner
/// carries one bit; it does not need four sizes to carry it.
///
/// A whole-screen wait is a different problem: a skeleton that shows the shape
/// of what is coming beats a spinner that shows only that something is. Reach
/// for `SkeletonCard` there and keep this for the waits with no shape to
/// promise — a sign-in, a pairing handshake, a session restore.
class SatSpinner extends StatelessWidget {
  final SatSpinnerSize size;

  /// Defaults to `accentText`, which is the colour every existing site used.
  final Color? color;

  const SatSpinner({super.key, this.size = SatSpinnerSize.sm, this.color});

  @override
  Widget build(BuildContext context) {
    final d = switch (size) {
      SatSpinnerSize.sm => Sp.s6,
      SatSpinnerSize.md => Sp.s7,
    };
    return SizedBox(
      width: d,
      height: d,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? context.sat.accentText,
      ),
    );
  }
}
