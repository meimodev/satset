import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/menu_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/modifier_group.dart';

/// Snapshot held by the repository so UI can subscribe to one source.
class MenuSnapshot {
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<ModifierGroup> modifierGroups;
  const MenuSnapshot({
    required this.categories,
    required this.items,
    required this.modifierGroups,
  });

  static const empty = MenuSnapshot(
    categories: [],
    items: [],
    modifierGroups: [],
  );
}

/// Surfaces bootstrap progress so the menu/table-detail UIs can render
/// loading and error states. Mirrors [tablesStatusProvider].
final menuStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

/// LAN-aware menu cache.
///
/// When [apiConfigProvider] is set the repository fetches `/menu`, maps
/// the [MenuSnapshotDto] into domain models, and exposes the result via
/// [state]. [DummyDataService] is retained as a pre-pair fallback and as
/// the server seed source; it is NOT silently returned during LAN mode.
class MenuRepository extends StateNotifier<MenuSnapshot> {
  MenuRepository({required this.ref, required DummyDataService seed})
      : _seed = seed,
        super(MenuSnapshot(
          categories: seed.categories(),
          items: seed.items(),
          modifierGroups: const [],
        )) {
    _bootstrap();
  }

  final Ref ref;
  final DummyDataService _seed;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(menuStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    state = MenuSnapshot.empty;
    ref.read(menuStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.getJson('/menu') as Map<String, dynamic>;
      final dto = MenuSnapshotDto.fromJson(raw);
      state = _toDomain(dto);
      ref.read(menuStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(menuStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _bootstrap();

  MenuSnapshot _toDomain(MenuSnapshotDto d) {
    final groups = [for (final g in d.modifierGroups) _modGroupFromDto(g)];
    final groupsById = {for (final g in groups) g.id: g};
    return MenuSnapshot(
      categories: [
        for (final c in d.categories) MenuCategory(id: c.id, name: c.name),
      ],
      items: [for (final i in d.items) _itemFromDto(i, groupsById)],
      modifierGroups: groups,
    );
  }

  MenuItem _itemFromDto(MenuItemDto i, Map<String, ModifierGroup> groups) {
    return MenuItem(
      id: i.id,
      name: i.name,
      categoryId: i.categoryId,
      station: Station.values.firstWhere(
        (s) => s.name == i.station,
        orElse: () => Station.kitchen,
      ),
      description: i.description,
      basePrice: i.basePrice,
      prepTime: i.prepTime,
      variants: [
        for (final v in i.variants) Variant(id: v.id, name: v.name, price: v.price),
      ],
      modifierGroups: [
        for (final id in i.modifierGroupIds)
          if (groups[id] != null) groups[id]!,
      ],
      allergens: [for (final a in i.allergens) _allergen(a)]
          .whereType<Allergen>()
          .toList(),
      dietary: [for (final d in i.dietary) _dietary(d)]
          .whereType<DietaryTag>()
          .toList(),
      unavailable: i.unavailable,
      stockCount: i.stockCount,
      autoEightySixAtZero: i.autoEightySixAtZero,
    );
  }

  ModifierGroup _modGroupFromDto(ModifierGroupDto g) => ModifierGroup(
        id: g.id,
        name: g.name,
        required: g.required,
        multi: g.multi,
        options: [
          for (final o in g.options)
            ModifierOption(id: o.id, name: o.name, priceDelta: o.priceDelta),
        ],
      );

  Allergen? _allergen(String name) =>
      Allergen.values.where((a) => a.name == name).cast<Allergen?>().firstOrNull;
  DietaryTag? _dietary(String name) =>
      DietaryTag.values.where((d) => d.name == name).cast<DietaryTag?>().firstOrNull;

  // Pre-pair / dev convenience: hand back a seed item by id. Returns the
  // server-loaded item when the repository has bootstrapped.
  MenuItem itemById(String id) {
    final inState = state.items.where((i) => i.id == id).firstOrNull;
    return inState ?? _seed.itemById(id);
  }
}

final menuRepositoryProvider =
    StateNotifierProvider<MenuRepository, MenuSnapshot>(
        (ref) => MenuRepository(
              ref: ref,
              seed: ref.watch(dummyDataServiceProvider),
            ));

final menuCategoriesProvider = Provider<List<MenuCategory>>(
    (ref) => ref.watch(menuRepositoryProvider).categories);

final menuItemsProvider = Provider<List<MenuItem>>(
    (ref) => ref.watch(menuRepositoryProvider).items);
