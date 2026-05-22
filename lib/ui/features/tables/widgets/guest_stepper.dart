import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

class GuestStepper extends StatelessWidget {
  final int pax;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool enabled;
  final double size;

  const GuestStepper({
    super.key,
    required this.pax,
    required this.onMinus,
    required this.onPlus,
    this.enabled = true,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final canMinus = enabled && pax > 1;
    final canPlus = enabled && pax < 12;
    return Container(
      height: size,
      decoration: BoxDecoration(
        color: sc.bg3,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: sc.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, sc, Icons.remove_rounded, canMinus ? onMinus : null, canMinus),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.35),
            child: Text(
              '$pax tamu',
              style: SatType.sans(
                size: size * 0.36,
                weight: FontWeight.w600,
                color: sc.textHi,
                letterSpacing: -0.1,
              ),
            ),
          ),
          _btn(context, sc, Icons.add_rounded, canPlus ? onPlus : null, canPlus),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, SatColors sc, IconData icon, VoidCallback? cb, bool active) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: cb,
        borderRadius: BorderRadius.circular(size / 2),
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
