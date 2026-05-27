import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/colors.dart';

/// Static placeholder card used while ReportsRepository loads. Avoids a
/// full shimmer dependency — a flat soft-grey block is enough for the brief
/// flash between mount and first paint.
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;
  const SkeletonCard({super.key, this.height = 120, this.margin});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(sc.textLo),
          ),
        ),
      ),
    );
  }
}
