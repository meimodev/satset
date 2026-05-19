import 'package:flutter/material.dart';
import '../colors.dart';

class SatChip extends StatelessWidget {
  const SatChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor ?? AppColors.onTertiaryContainer),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.onTertiaryContainer,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
