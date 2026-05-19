import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';

class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        _buildLegendItem(AppColors.primary, 'Terisi'),
        _buildLegendItem(Colors.transparent, 'Tersedia', border: AppColors.outline),
        _buildLegendItem(AppColors.secondaryContainer, 'Dipesan'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: border != null ? Border.all(color: border) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
