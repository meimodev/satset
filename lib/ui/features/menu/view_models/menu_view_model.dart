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

/// The menu grid's filter.
///
/// A non-empty [query] searches the whole menu and **ignores** [categoryId] —
/// a waiter typing "es teh" does not know or care which category it lives in,
/// and making them pick the right chip first defeats the search box. Matches
/// name and description, case-insensitive substring, same as the admin search.
List<MenuItem> filterMenuItems(
  List<MenuItem> items, {
  required String categoryId,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return items
        .where((i) => categoryId == 'all' || i.categoryId == categoryId)
        .toList();
  }
  return items
      .where(
        (i) =>
            i.name.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q),
      )
      .toList();
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
