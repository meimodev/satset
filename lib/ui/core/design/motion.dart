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

/// A duration that collapses to zero when the platform asks for reduced motion.
///
/// **Every `AnimatedFoo` takes its `duration:` from here.** Reduced motion is
/// not a preference about taste — a waiter who has turned it on has done so for
/// a reason, and an unguarded `duration:` ignores it silently, which is why
/// this is a function rather than a constant anyone can forget to wrap.
///
/// Zero, not "very short": Flutter renders the final frame immediately, which
/// is the required behaviour. A 1ms animation still schedules a transition.
Duration satMotion(BuildContext context, int ms) =>
    motionEnabled(context) ? Duration(milliseconds: ms) : Duration.zero;

/// Cross-fade for a status label changing underneath the reader — a ticket
/// moving prep → ready on a live push. Long enough to notice, short enough that
/// the new value is legible before a thumb reaches it.
const int satStatusXfadeMs = 280;
