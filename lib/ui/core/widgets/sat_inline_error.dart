import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// The red line that sits under a field, or under a form (ADR-0055).
///
/// The sign-in screen alone grew four of these — same glyph, same gap, same
/// type ramp, hand-built each time, and two of them without a [Flexible], so a
/// long server message overflowed rather than wrapping. Principle 3 says a
/// state must be unambiguous; four anatomies of the same state is how one of
/// them quietly stops matching the other three.
///
/// [center] is the form-level variant: a message about the whole attempt reads
/// centred under the button, while a message about one field hangs off its
/// left edge. Nothing else differs, which is the point.
class SatInlineError extends StatelessWidget {
  final String message;
  final bool center;

  const SatInlineError(this.message, {super.key, this.center = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: Sp.s3, color: sc.urgent),
        const SizedBox(width: Sp.s1h),
        Flexible(
          child: Text(
            message,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: SatType.bodyS(color: sc.urgent),
          ),
        ),
      ],
    );
  }
}
