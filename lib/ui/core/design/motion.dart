import 'package:flutter/widgets.dart';

/// Shared, reduced-motion-aware motion primitives. Heritage Hospitality is a
/// calm, serious surface — motion here is invisible feedback (fast deceleration,
/// transform + opacity only), never decoration. Every primitive collapses to a
/// static final state when the platform requests reduced motion.

/// Refined deceleration (≈ ease-out-quint). Used app-wide for entrances and
/// state changes so motion reads as one consistent hand.
const Curve satEaseOut = Cubic(0.22, 1, 0.36, 1);

/// True unless the OS asks to minimise animation (accessibility / battery).
bool motionEnabled(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Press-down scale for tappable surfaces. Complements (does not replace) the
/// underlying ink/colour feedback — gives the tile a physical "give" of ~3%.
/// No-op under reduced motion.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  const PressableScale({super.key, required this.child, this.pressedScale = 0.97});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = !motionEnabled(context);
    return Listener(
      onPointerDown: reduce ? null : (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance: fade + short upward slide. Index drives the cascade so a
/// list reveals top-to-bottom. Reveals once and stays revealed (survives parent
/// rebuilds); under reduced motion it renders final state immediately.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration stagger;
  final Duration duration;
  final double dy;

  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = Duration.zero,
    this.stagger = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 340),
    this.dy = 12,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: satEaseOut);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionEnabled(context)) {
      _c.value = 1;
      return;
    }
    // Cap the cascade so long lists don't accumulate a sluggish tail.
    final i = widget.index.clamp(0, 10);
    final delay = widget.baseDelay + widget.stagger * i;
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.dy),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
