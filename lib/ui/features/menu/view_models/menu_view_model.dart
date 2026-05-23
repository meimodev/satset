import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';

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
      : super(MenuScreenState(
          categories: ref.read(menuCategoriesProvider),
          items: ref.read(menuItemsProvider),
        )) {
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
        (ref) => MenuViewModel(ref));
