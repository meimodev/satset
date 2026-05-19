import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import 'widgets/menu_item_tile.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class ProductMatrixScreen extends ConsumerWidget {
  const ProductMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCat = ref.watch(selectedCategoryProvider);
    final categories = DummyData.categories;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 2 : 3;
    final hPadding = screenWidth < 600 ? AppSpacing.containerMargin : 40.0;

    final filteredItems = selectedCat == null
        ? DummyData.menuItems
        : DummyData.itemsForCategory(selectedCat);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPadding, AppSpacing.md, hPadding, AppSpacing.xl + 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matriks Produk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.02, color: AppColors.onBackground)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Ringkasan menu yang tersedia saat ini.', style: TextStyle(fontSize: 16, height: 1.6, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('Semua Menu', null, selectedCat == null),
                ...categories.map((cat) => _buildCategoryChip(cat.name, cat.id, selectedCat == cat.id)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: screenWidth < 600 ? 3.0 : 4.0,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) => MenuItemTile(item: filteredItems[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? catId, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(
        label: Text(label.toUpperCase()),
        backgroundColor: selected ? AppColors.primaryContainer : AppColors.surfaceLowest,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
        ),
        side: selected ? BorderSide.none : const BorderSide(color: AppColors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        onPressed: () {},
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
