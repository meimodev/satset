import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/user.dart';

/// Two-tier role model for the menu admin screen.
/// Admin = full CRUD. Staff = availability toggle only.
enum MenuPermission { admin, staff }

/// Selected category filter ('all' = no filter).
final menuAdminCategoryFilterProvider = StateProvider<String>((_) => 'all');

/// Search query for menu admin list.
final menuAdminSearchProvider = StateProvider<String>((_) => '');

/// Currently focused item id in tablet master-detail.
final menuAdminSelectedItemIdProvider = StateProvider<String?>((_) => null);

/// Top-level menu admin tab: items vs categories.
enum MenuAdminTab { items, categories }

final menuAdminTabProvider =
    StateProvider<MenuAdminTab>((_) => MenuAdminTab.items);

final menuPermissionProvider = Provider<MenuPermission>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.user?.role == UserRole.admin
      ? MenuPermission.admin
      : MenuPermission.staff;
});

/// Filtered list (search + category) used by the admin list.
final menuAdminFilteredItemsProvider = Provider<List<MenuItem>>((ref) {
  final all = ref.watch(menuItemsProvider);
  final cat = ref.watch(menuAdminCategoryFilterProvider);
  final q = ref.watch(menuAdminSearchProvider).trim().toLowerCase();
  return all.where((it) {
    if (cat != 'all' && it.categoryId != cat) return false;
    if (q.isEmpty) return true;
    return it.name.toLowerCase().contains(q) ||
        it.description.toLowerCase().contains(q);
  }).toList();
});

/// Counts shown in the header strip.
class MenuAdminCounts {
  final int total;
  final int eightySixed;
  final int categories;
  const MenuAdminCounts(this.total, this.eightySixed, this.categories);
}

final menuAdminCountsProvider = Provider<MenuAdminCounts>((ref) {
  final all = ref.watch(menuItemsProvider);
  final eightySix = all.where((i) => i.isEightySixed).length;
  // Excludes the synthetic "Semua" pseudo-category surfaced by the seed.
  final cats = ref.watch(menuCategoriesProvider).where((c) => c.id != 'all').length;
  return MenuAdminCounts(all.length, eightySix, cats);
});

/// Real categories without the "all" pseudo-row, for the rail.
final menuRealCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return ref
      .watch(menuCategoriesProvider)
      .where((c) => c.id != 'all')
      .toList();
});

/// Item count per category id, for the categories panel.
final menuCategoryItemCountsProvider = Provider<Map<String, int>>((ref) {
  final items = ref.watch(menuItemsProvider);
  final out = <String, int>{};
  for (final i in items) {
    out[i.categoryId] = (out[i.categoryId] ?? 0) + 1;
  }
  return out;
});
