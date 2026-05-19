import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../models/venue_table.dart';

class TableTile extends StatelessWidget {
  const TableTile({
    super.key,
    required this.table,
    required this.onTap,
  });

  final VenueTable table;
  final VoidCallback onTap;

  Color get _backgroundColor {
    switch (table.status) {
      case TableStatus.empty:
        return AppColors.surface;
      case TableStatus.ordering:
        return AppColors.primary;
      case TableStatus.waiting:
        return AppColors.primaryContainer;
      case TableStatus.ready:
        return AppColors.secondaryFixed;
    }
  }

  Color get _textColor {
    switch (table.status) {
      case TableStatus.empty:
        return AppColors.onSurfaceVariant;
      case TableStatus.ordering:
        return AppColors.onPrimary;
      case TableStatus.waiting:
        return AppColors.onPrimaryContainer;
      case TableStatus.ready:
        return AppColors.onSecondaryFixed;
    }
  }

  Color? get _borderColor {
    if (table.status == TableStatus.empty) return AppColors.outlineVariant;
    return null;
  }

  IconData get _icon {
    switch (table.status) {
      case TableStatus.empty:
        return Icons.chair;
      case TableStatus.ordering:
        return Icons.group;
      case TableStatus.waiting:
        return Icons.schedule;
      case TableStatus.ready:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _borderColor != null
                ? Border.all(color: _borderColor!, width: 1)
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              if (table.guestCount != null || table.isBooth) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 12, color: _textColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      table.isBooth ? 'Bilik · ${table.capacity} Org' : '${table.guestCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: _textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
