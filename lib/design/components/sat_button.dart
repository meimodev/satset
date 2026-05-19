import 'package:flutter/material.dart';
class SatButton extends StatelessWidget {
  const SatButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SatButtonVariant.primary,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SatButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    switch (variant) {
      case SatButtonVariant.primary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 48,
          child: FilledButton(
            onPressed: onPressed,
            child: child,
          ),
        );
      case SatButtonVariant.secondary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 48,
          child: OutlinedButton(
            onPressed: onPressed,
            child: child,
          ),
        );
      case SatButtonVariant.tertiary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          height: 48,
          child: TextButton(
            onPressed: onPressed,
            child: child,
          ),
        );
    }
  }
}

enum SatButtonVariant { primary, secondary, tertiary }
