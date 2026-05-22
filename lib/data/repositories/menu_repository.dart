import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';

class MenuRepository {
  MenuRepository(this._seed);

  final DummyDataService _seed;

  List<MenuCategory> categories() => _seed.categories();
  List<MenuItem> items() => _seed.items();
  MenuItem itemById(String id) => _seed.itemById(id);
}

final menuRepositoryProvider = Provider<MenuRepository>(
    (ref) => MenuRepository(ref.watch(dummyDataServiceProvider)));

final menuCategoriesProvider =
    Provider<List<MenuCategory>>((ref) => ref.watch(menuRepositoryProvider).categories());

final menuItemsProvider =
    Provider<List<MenuItem>>((ref) => ref.watch(menuRepositoryProvider).items());
