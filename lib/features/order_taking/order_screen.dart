import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../models/menu_item.dart';
import '../../models/modifier_group.dart';
import '../../models/venue_table.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/components/sat_button.dart';
import '../../design/format.dart';

class DraftOrderItem {
  final MenuItem item;
  final int quantity;
  final List<ModifierOption> selectedModifiers;
  final String? notes;

  const DraftOrderItem({
    required this.item,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.notes,
  });

  double get total => (item.price +
    selectedModifiers.fold(0.0, (sum, opt) => sum + opt.priceAdjustment)) * quantity;

  DraftOrderItem copyWith({
    MenuItem? item,
    int? quantity,
    List<ModifierOption>? selectedModifiers,
    String? notes,
  }) {
    return DraftOrderItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
    );
  }
}

final selectedOrderCategoryProvider = StateProvider<String?>((ref) => null);
final draftOrderProvider = StateProvider<List<DraftOrderItem>>((ref) => []);

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.table});

  final VenueTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCat = ref.watch(selectedOrderCategoryProvider);
    final draft = ref.watch(draftOrderProvider);
    final categories = DummyData.categories;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 4 : 6);

    final filteredItems = selectedCat == null
        ? DummyData.menuItems.where((i) => i.isAvailable).toList()
        : DummyData.itemsForCategory(selectedCat).where((i) => i.isAvailable).toList();

    final totalAmount = draft.fold(0.0, (sum, item) => sum + item.total);

    return Scaffold(
      appBar: AppBar(
        title: Text('Meja ${table.label} — Pesanan Baru'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.secondaryOverride)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: categories.map((cat) {
                final isSelected = selectedCat == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedOrderCategoryProvider.notifier).state =
                        isSelected ? null : cat.id;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: screenWidth < 600 ? 2.5 : 3.5,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final draftQty = draft.where((d) => d.item.id == item.id).fold(0, (sum, d) => sum + d.quantity);
                return _MenuItemCard(
                  item: item,
                  quantity: draftQty,
                  onTap: () => _addToOrder(context, ref, item),
                );
              },
            ),
          ),
          if (draft.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: AppColors.secondaryOverride),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${draft.length} item · ${draft.fold(0, (sum, i) => sum + i.quantity)} jumlah',
                          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                        ),
                        Text(
                          'Rp ${formatRupiah(totalAmount)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  SatButton(
                    label: 'Kirim Pesanan',
                    icon: Icons.send,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pesanan dikirim ke dapur!')),
                      );
                      ref.read(draftOrderProvider.notifier).state = [];
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _addToOrder(BuildContext context, WidgetRef ref, MenuItem item) {
    final modifierGroups = DummyData.modifierGroupsForItem(item.id);
    final requiredModifiers = modifierGroups.where((g) => g.isRequired).toList();

    if (requiredModifiers.isNotEmpty) {
      _showModifierSheet(context, ref, item, requiredModifiers);
    } else {
      _addItemToDraft(ref, item, []);
    }
  }

  void _addItemToDraft(WidgetRef ref, MenuItem item, List<ModifierOption> modifiers) {
    final draft = ref.read(draftOrderProvider).toList();
    final existingIndex = draft.indexWhere((d) => d.item.id == item.id);

    if (existingIndex >= 0) {
      draft[existingIndex] = draft[existingIndex].copyWith(
        quantity: draft[existingIndex].quantity + 1,
        selectedModifiers: modifiers,
      );
    } else {
      draft.add(DraftOrderItem(item: item, selectedModifiers: modifiers));
    }
    ref.read(draftOrderProvider.notifier).state = draft;
  }

  void _showModifierSheet(BuildContext context, WidgetRef ref, MenuItem item, List<ModifierGroup> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedOptions = <String, ModifierOption?>{};

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...groups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                            ),
                            if (group.isRequired)
                              const Text(
                                ' *Wajib',
                                style: TextStyle(fontSize: 12, color: AppColors.error),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...group.options.map((option) {
                          final isSelected = selectedOptions[group.id] == option;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (group.selectionType == SelectionType.single) {
                                    selectedOptions[group.id] = isSelected ? null : option;
                                  } else {
                                    selectedOptions[group.id] = isSelected ? null : option;
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    group.selectionType == SelectionType.single
                                        ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                                        : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                                    size: 20,
                                    color: AppColors.primaryOverride,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    option.name,
                                    style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                                  ),
                                  if (option.priceAdjustment > 0) ...[
                                    const Spacer(),
                                    Text(
                                      '+Rp ${formatRupiah(option.priceAdjustment)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  }),
                  SatButton(
                    label: 'Tambah ke Pesanan',
                    expanded: true,
                    onPressed: () {
                      final modifiers = selectedOptions.values.where((o) => o != null).cast<ModifierOption>().toList();
                      _addItemToDraft(ref, item, modifiers);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.onTap, this.quantity = 0});

  final MenuItem item;
  final VoidCallback onTap;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondaryOverride, width: 1),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${formatRupiah(item.price)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  ),
                ],
              ),
              if (quantity > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
