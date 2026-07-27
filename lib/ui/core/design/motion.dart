import 'package:flutter/widgets.dart';

/// Motion *tokens*. Widgets built on them live in `core/widgets/anim.dart` —
/// `core/design/` holds no widgets (see CATALOG.md).
///
/// Motion here is invisible feedback (fast deceleration, transform + opacity
/// only), never decoration, and every primitive built on these collapses to a
/// static final state when the platform requests reduced motion.

/// Refined deceleration (≈ ease-out-quint). Used app-wide for entrances and
/// state changes so motion reads as one consistent hand.
const Curve satEaseOut = Cubic(0.22, 1, 0.36, 1);

/// True unless the OS asks to minimise animation (accessibility / battery).
bool motionEnabled(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
