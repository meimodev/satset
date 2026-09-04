import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/capability.dart';

/// What this session may do on the menu admin screen.
///
/// Keyed off capabilities, not the legacy `UserRole` bucket: CONTEXT.md is
/// explicit that `waiter`/`kitchen`/`admin` is a seed-and-reporting
/// classification and never a permission. Reading it as one meant an `editMenu`
/// holder was admitted by the route gate and then handed a read-only screen,
/// while anything carrying `editSettings` got full CRUD it was never granted.
///
/// Not persisted anywhere, unlike [Capability] — renaming an arm costs nothing.
enum MenuPermission {
  /// `editMenu` — the whole catalogue: items, categories, tags, prices.
  full,

  /// `markSoldOut` without `editMenu`: the availability toggle and nothing
  /// else. The seeded Kitchen role, which may pull tonight's dish but not
  /// reprice it (ADR-0132).
  soldOutOnly,

  /// Neither. The route admits either capability, and a role can lose one while
  /// the screen is still open.
  readOnly,
}

/// Selected category filter ('all' = no filter).
final menuAdminCategoryFilterProvider = StateProvider<String>((_) => 'all');

/// Search query for menu admin list.
final menuAdminSearchProvider = StateProvider<String>((_) => '');

/// Currently focused item id in tablet master-detail.
final menuAdminSelectedItemIdProvider = StateProvider<String?>((_) => null);

/// Top-level menu admin tab: items, categories, or tags (allergen/diet).
enum MenuAdminTab { items, categories, tags }

final menuAdminTabProvider = StateProvider<MenuAdminTab>(
  (_) => MenuAdminTab.items,
);

final menuPermissionProvider = Provider<MenuPermission>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.has(Capability.editMenu)) return MenuPermission.full;
  if (auth.has(Capability.markSoldOut)) return MenuPermission.soldOutOnly;
  return MenuPermission.readOnly;
});

/// Whether this session may flip an item's availability.
///
/// Deliberately **not** derived from [MenuPermission]: `editMenu` and
/// `markSoldOut` are orthogonal, so the tiers cannot express it. An owner may
/// hold the catalogue and not the toggle, and `MenuPermission.full` would then
/// render a button whose only outcome is the 403 this exists to stop — the same
/// shape of bug, one enum further along. Ask the capability the write costs.
final menuCanMarkSoldOutProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).has(Capability.markSoldOut),
);

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
  final int soldOut;
  final int categories;
  const MenuAdminCounts(this.total, this.soldOut, this.categories);
}

final menuAdminCountsProvider = Provider<MenuAdminCounts>((ref) {
  final all = ref.watch(menuItemsProvider);
  final soldOut = all.where((i) => i.isSoldOut).length;
  // Excludes the synthetic "Semua" pseudo-category surfaced by the seed.
  final cats = ref
      .watch(menuCategoriesProvider)
      .where((c) => c.id != 'all')
      .length;
  return MenuAdminCounts(all.length, soldOut, cats);
});

/// Real categories without the "all" pseudo-row, for the rail.
final menuRealCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return ref.watch(menuCategoriesProvider).where((c) => c.id != 'all').toList();
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
