import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

class GuestStepper extends StatefulWidget {
  final int pax;
  final int max;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool enabled;
  final double size;

  const GuestStepper({
    super.key,
    required this.pax,
    required this.max,
    required this.onMinus,
    required this.onPlus,
    this.enabled = true,
    this.size = 36,
  });

  @override
  State<GuestStepper> createState() => _GuestStepperState();
}

class _GuestStepperState extends State<GuestStepper> {
  // Tracks the last pax so the count can slide up on increment, down on
  // decrement — a small spatial cue that mirrors the +/- the waiter just hit.
  late int _prevPax = widget.pax;

  @override
  void didUpdateWidget(covariant GuestStepper old) {
    super.didUpdateWidget(old);
    if (old.pax != widget.pax) _prevPax = old.pax;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final size = widget.size;
    final pax = widget.pax;
    final enabled = widget.enabled;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveMax = widget.max < 1 ? 1 : widget.max;
    final canMinus = enabled && pax > 0;
    final canPlus = enabled && pax < effectiveMax;
    final goingUp = pax >= _prevPax;
    return Container(
      height: size,
      decoration: SatBox.d(
        color: sc.bg3,
        borderRadius: SatR.a(size / 2),
        border: SatB.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, sc, Icons.remove_rounded,
              canMinus ? widget.onMinus : null, canMinus),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.person_outline,
                    size: size * 0.38, color: sc.textMd),
                SizedBox(width: size * 0.12),
                AnimatedSwitcher(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeOutQuart,
                  transitionBuilder: (child, anim) {
                    final slide = Tween<Offset>(
                      begin: Offset(0, goingUp ? 0.6 : -0.6),
                      end: Offset.zero,
                    ).animate(anim);
                    return ClipRect(
                      child: SlideTransition(
                        position: slide,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: Text(
                    '$pax/$effectiveMax',
                    key: ValueKey(pax),
                    style: SatType.sans(
                      size: size * 0.36,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _btn(context, sc, Icons.add_rounded,
              canPlus ? widget.onPlus : null, canPlus),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, SatColors sc, IconData icon, VoidCallback? cb, bool active) {
    final size = widget.size;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: cb,
        borderRadius: SatR.a(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: active ? sc.textHi : sc.textDim,
          ),
        ),
      ),
    );
  }
}
