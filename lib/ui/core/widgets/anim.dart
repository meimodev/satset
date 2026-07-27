import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/design/skin.dart';

export 'package:satset/ui/core/design/motion.dart'
    show satEaseOut, motionEnabled, satMotion;

/// Shared motion primitives for SatSet screens. Every animation here collapses
/// to its final frame when the platform requests reduced motion, so callers
/// never need to branch on it themselves.
///
/// The curve itself is a token — `satEaseOut` in `design/motion.dart`, re-exported
/// here so a screen animating something bespoke needs one import, not two.

/// Fade + slide-up entrance, played once on mount. Give siblings increasing
/// [index] values for a staggered cascade (55ms per step).
///
/// Pass a stable [animKey] (e.g. an item id) for rows inside a recycling
/// `ListView.builder`: the cascade plays the first time that key is seen and
/// is skipped on every later mount, so scrolling back doesn't re-trigger it.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Object? animKey;
  const Reveal({super.key, required this.child, this.index = 0, this.animKey});

  /// Keys whose entrance has already played this session.
  static final Set<Object> _seen = {};

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: satEaseOut,
  );
  bool _skip = false;

  @override
  void initState() {
    super.initState();
    final key = widget.animKey;
    if (key != null && Reveal._seen.contains(key)) {
      _skip = true;
      _c.value = 1;
      return;
    }
    if (key != null) Reveal._seen.add(key);
    // Cap the cascade: a 40-row board would otherwise leave the last row
    // waiting two seconds, which reads as a hang rather than a reveal.
    final delay = 55 * widget.index.clamp(0, 10);
    if (delay == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
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
    if (_skip || MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Grows + fades a child in (or collapses it out) as it appears/disappears.
/// Wrap a conditional widget and pass [SizedBox.shrink()] for the absent state,
/// or a [ValueKey] that flips, and the swap animates height + opacity instead of
/// popping. Used for editor blocks that toggle on (tracked stock)
/// and for dynamic row lists growing/shrinking. Snaps under reduced motion.
class ExpandFade extends StatelessWidget {
  final Widget child;
  final int ms;
  final Alignment alignment;
  const ExpandFade({
    super.key,
    required this.child,
    this.ms = 220,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: satMotion(context, ms),
      switchInCurve: satEaseOut,
      switchOutCurve: satEaseOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      child: child,
    );
  }
}

/// Animates its own height when children are added/removed beneath it, so list
/// rows grow in / collapse out instead of jumping. Pairs with keyed children.
/// Collapses to a plain pass-through under reduced motion.
class AnimatedReflow extends StatelessWidget {
  final Widget child;
  final int ms;
  final Alignment alignment;
  const AnimatedReflow({
    super.key,
    required this.child,
    this.ms = 240,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: satMotion(context, ms),
      curve: satEaseOut,
      alignment: alignment,
      child: child,
    );
  }
}

/// Horizontal track + fill that grows from zero on first paint and eases to a
/// new width whenever [factor] changes (e.g. after a filter switch).
class AnimatedBarFill extends StatelessWidget {
  final double factor;
  final double height;
  final Color color;
  final Color track;
  final double radius;
  const AnimatedBarFill({
    super.key,
    required this.factor,
    required this.color,
    required this.track,
    this.height = 5,
    this.radius = 3,
  });

  @override
  Widget build(BuildContext context) {
    final f = factor.clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          height: height,
          decoration: SatBox.d(color: track, borderRadius: SatR.a(radius)),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: f),
          duration: satMotion(context, 620),
          curve: satEaseOut,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              height: height,
              decoration: SatBox.d(color: color, borderRadius: SatR.a(radius)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vertical bar that grows from the baseline to [height] px. Used by the
/// cover-trend and hourly-revenue mini charts.
class GrowBarV extends StatelessWidget {
  final double height;
  final double? width;
  final Color color;
  final BorderRadius radius;
  const GrowBarV({
    super.key,
    required this.height,
    this.width,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: satMotion(context, 560),
      curve: satEaseOut,
      builder: (context, h, _) => Container(
        width: width,
        height: h,
        decoration: SatBox.d(color: color, borderRadius: radius),
      ),
    );
  }
}

/// Tactile press feedback: dips to [pressedScale] on pointer-down and eases back
/// on release/cancel. Wraps any tappable so the press reads physically. The
/// child keeps owning the actual tap (InkWell ripple, onTap), this only adds the
/// scale. Collapses to a plain pass-through under reduced motion.
class PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  const PressScale({super.key, required this.child, this.pressedScale = 0.97});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: satEaseOut,
        child: widget.child,
      ),
    );
  }
}

/// Integer that rolls smoothly from its previous value to [value] whenever it
/// changes (e.g. a count updating after a filter or edit). [builder] renders the
/// interpolated, rounded number. Snaps instantly under reduced motion.
class AnimatedCount extends StatelessWidget {
  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;
  const AnimatedCount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: satEaseOut,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}
