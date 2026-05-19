import 'package:flutter/material.dart';
import '../colors.dart';
import '../shapes.dart';

class SatCard extends StatelessWidget {
  const SatCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceLowest,
        border: Border.all(color: AppColors.secondaryOverride, width: 1),
        borderRadius: BorderRadius.circular(AppShapes.sm),
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.sm),
        child: card,
      );
    }

    return card;
  }
}
