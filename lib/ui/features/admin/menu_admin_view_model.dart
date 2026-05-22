import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/dummy_data_seed.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/user.dart';

/// Two-tier role model for the menu admin screen.
/// Admin = full CRUD. Staff = availability toggle only.
enum MenuPermission { admin, staff }

class MenuItemsNotifier extends StateNotifier<List<MenuItem>> {
  MenuItemsNotifier(DummyDataService seed)
      : super(List.of(seed.items()));

  void _commit(List<MenuItem> next) {
    DummyData.items
      ..clear()
      ..addAll(next);
    state = List.of(next);
  }

  void toggleAvailability(String id) {
    final next = [
      for (final it in state)
        if (it.id == id) it.copyWith(unavailable: !it.unavailable) else it,
    ];
    _commit(next);
  }

  void adjustStock(String id, int delta) {
    final next = [
      for (final it in state)
        if (it.id == id)
          it.copyWith(stockCount: ((it.stockCount ?? 0) + delta).clamp(0, 9999))
        else
          it,
    ];
    _commit(next);
  }

  void upsertItem(MenuItem item) {
    final idx = state.indexWhere((i) => i.id == item.id);
    final next = List<MenuItem>.of(state);
    if (idx == -1) {
      next.add(item);
    } else {
      next[idx] = item;
    }
    _commit(next);
  }

  void removeItem(String id) {
    final next = state.where((i) => i.id != id).toList();
    _commit(next);
  }

  void reorder(int oldIndex, int newIndex) {
    final next = List<MenuItem>.of(state);
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final m = next.removeAt(oldIndex);
    next.insert(to, m);
    _commit(next);
  }
}

final menuItemsNotifierProvider =
    StateNotifierProvider<MenuItemsNotifier, List<MenuItem>>(
        (ref) => MenuItemsNotifier(ref.watch(dummyDataServiceProvider)));

/// Selected category filter ('all' = no filter).
final menuAdminCategoryFilterProvider = StateProvider<String>((_) => 'all');

/// Search query for menu admin list.
final menuAdminSearchProvider = StateProvider<String>((_) => '');

/// Currently focused item id in tablet master-detail.
final menuAdminSelectedItemIdProvider = StateProvider<String?>((_) => null);

final menuPermissionProvider = Provider<MenuPermission>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.user?.role == UserRole.admin
      ? MenuPermission.admin
      : MenuPermission.staff;
});

/// Filtered list (search + category) used by the admin list.
final menuAdminFilteredItemsProvider = Provider<List<MenuItem>>((ref) {
  final all = ref.watch(menuItemsNotifierProvider);
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
  final all = ref.watch(menuItemsNotifierProvider);
  final eightySix = all.where((i) => i.isEightySixed).length;
  // Excludes the synthetic "Semua" pseudo-category from the seed.
  final cats = (ref.watch(dummyDataServiceProvider).categories())
      .where((c) => c.id != 'all')
      .length;
  return MenuAdminCounts(all.length, eightySix, cats);
});

/// Real categories without the "all" pseudo-row, for the rail.
final menuRealCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return ref
      .watch(dummyDataServiceProvider)
      .categories()
      .where((c) => c.id != 'all')
      .toList();
});
