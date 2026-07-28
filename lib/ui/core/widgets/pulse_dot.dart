import 'package:flutter/material.dart';

import '../design/skin.dart';

/// A status dot that breathes while something needs attention (ADR-0055).
///
/// The KDS drew one to mark an overdue ticket and the pin screen drew another
/// to mark a reachable server — same widget, two files, two different pulse
/// periods and two different ways of honouring reduced motion.
///
/// [glow] is the halo the pin screen wanted: without it the dot pulses by
/// opacity and scale alone, which is what the KDS wanted on a dense ticket
/// card where a spreading halo would touch its neighbours.
///
/// Reduced motion holds it at the midpoint rather than the trough — a dot
/// frozen at its dimmest reads as "off", which is the opposite of the fact it
/// is carrying.
class PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  final double size;
  final Color? glow;

  const PulseDot({
    super.key,
    required this.color,
    this.pulse = true,
    this.size = 6,
    this.glow,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse != old.pulse) _sync();
  }

  void _sync() {
    if (widget.pulse && !MediaQuery.disableAnimationsOf(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0.5;
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
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: SatBox.d(
            shape: BoxShape.circle,
            color: widget.glow == null
                ? widget.color.withValues(alpha: 0.55 + t * 0.45)
                : widget.color,
            boxShadow: widget.glow == null
                ? null
                : [BoxShadow(color: widget.glow!, spreadRadius: 2.0 + t * 2.5)],
          ),
        );
      },
    );
  }
}
