import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';

/// Order-flow menu search query.
///
/// `autoDispose` so a query never survives into the next table's order. The
/// admin screen's sticky [menuAdminSearchProvider] equivalent is a long-lived
/// tab; this screen is a fresh push per table, where a leftover filter reads
/// as a broken menu.
final menuSearchProvider = StateProvider.autoDispose<String>((_) => '');

/// The menu grid's filter, and its order.
///
/// A non-empty [query] searches the whole menu and **ignores** [categoryId] —
/// a waiter typing "es teh" does not know or care which category it lives in,
/// and making them pick the right chip first defeats the search box. Matches
/// name and description, case-insensitive substring, same as the admin search.
///
/// [rank] is the [[Menu populer]] order (ADR-0113): item id → lines sold in the
/// last 30 business days, **frozen by the caller at mount** so the grid cannot
/// reshuffle under a thumb when a `menuUpdated` event lands mid-order. Highest
/// first, then by name — so an item nobody has sold sits at the bottom of an
/// alphabetical tail rather than wherever it happened to be inserted.
///
/// Two callers deliberately pass no [rank] and keep the server's order: the
/// menu admin list, where a stable list is what an owner hunting an item to
/// edit wants, and a live search, where results reshuffling as the venue trades
/// costs more than the ranking buys.
List<MenuItem> filterMenuItems(
  List<MenuItem> items, {
  required String categoryId,
  required String query,
  Map<String, int>? rank,
}) {
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    return items
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q),
        )
        .toList();
  }
  final out = items
      .where((i) => categoryId == 'all' || i.categoryId == categoryId)
      .toList();
  if (rank == null) return out;
  out.sort((a, b) {
    final byRank = (rank[b.id] ?? 0).compareTo(rank[a.id] ?? 0);
    return byRank != 0 ? byRank : a.name.compareTo(b.name);
  });
  return out;
}

class MenuScreenState {
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final String? selectedCategoryId;
  const MenuScreenState({
    required this.categories,
    required this.items,
    this.selectedCategoryId,
  });

  MenuScreenState copyWith({String? selectedCategoryId}) => MenuScreenState(
    categories: categories,
    items: items,
    selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
  );
}

class MenuViewModel extends StateNotifier<MenuScreenState> {
  MenuViewModel(this.ref)
    : super(
        MenuScreenState(
          categories: ref.read(menuCategoriesProvider),
          items: ref.read(menuItemsProvider),
        ),
      ) {
    ref.listen(menuItemsProvider, (_, n) {
      state = MenuScreenState(
        categories: state.categories,
        items: n,
        selectedCategoryId: state.selectedCategoryId,
      );
    });
  }

  final Ref ref;

  void selectCategory(String id) =>
      state = state.copyWith(selectedCategoryId: id);
}

final menuViewModelProvider =
    StateNotifierProvider.autoDispose<MenuViewModel, MenuScreenState>(
      (ref) => MenuViewModel(ref),
    );
