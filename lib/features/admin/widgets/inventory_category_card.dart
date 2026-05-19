import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../models/inventory_item.dart';

class InventoryCategoryCard extends StatelessWidget {
  const InventoryCategoryCard({
    super.key,
    required this.category,
    required this.items,
  });

  final String category;
  final List<InventoryItem> items;

  IconData get _categoryIcon {
    switch (category) {
      case 'Minuman':
        return Icons.local_cafe;
      case 'Bahan Pokok':
        return Icons.grain;
      case 'Perlengkapan':
        return Icons.checkroom;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
          ...items.map((item) {
            return InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                child: Row(
                  children: [
                    Icon(_categoryIcon, size: 20, color: AppColors.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.onSurface),
                          ),
                          Text(
                            'SKU: ${item.sku}',
                            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isLowStock ? AppColors.errorContainer : AppColors.tertiary,
                        borderRadius: BorderRadius.circular(4),
                        border: item.isLowStock ? Border.all(color: AppColors.error.withValues(alpha: 0.2)) : null,
                      ),
                      child: Text(
                        item.isLowStock ? 'STOK TIPIS' : 'AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: item.isLowStock ? AppColors.onErrorContainer : AppColors.onTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${item.currentStock.toStringAsFixed(0)} ${item.unit}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.isLowStock ? AppColors.error : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
