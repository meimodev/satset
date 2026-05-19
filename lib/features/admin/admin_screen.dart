import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import 'widgets/inventory_category_card.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = DummyData.inventoryItems;
    final categories = ['Minuman', 'Bahan Pokok', 'Perlengkapan'];
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 1 : (screenWidth < 900 ? 2 : 3);
    final hPadding = screenWidth < 600 ? AppSpacing.containerMargin : 40.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPadding, AppSpacing.md, hPadding, AppSpacing.xl + 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manajemen Inventaris', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, height: 1.2, color: AppColors.primary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Cari SKU atau nama...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.outline),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryOverride, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Item Baru'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = AppSpacing.lg;
              final itemWidth = crossCount == 1
                  ? availableWidth
                  : (availableWidth - (crossCount - 1) * spacing) / crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: categories.map((cat) {
                  final catItems = items.where((i) => i.category == cat).toList();
                  return SizedBox(
                    width: itemWidth,
                    child: InventoryCategoryCard(category: cat, items: catItems),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
