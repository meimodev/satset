import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/menu_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/domain/models/modifier_group.dart';

/// Snapshot held by the repository so UI can subscribe to one source.
class MenuSnapshot {
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<MenuTag> tags;
  const MenuSnapshot({
    required this.categories,
    required this.items,
    this.tags = const [],
  });

  static const empty = MenuSnapshot(categories: [], items: [], tags: []);

  MenuSnapshot copyWith({
    List<MenuCategory>? categories,
    List<MenuItem>? items,
    List<MenuTag>? tags,
  }) => MenuSnapshot(
    categories: categories ?? this.categories,
    items: items ?? this.items,
    tags: tags ?? this.tags,
  );
}

/// Surfaces bootstrap progress so the menu/table-detail UIs can render
/// loading and error states. Mirrors [tablesStatusProvider].
final menuStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

/// LAN-aware menu cache.
///
/// The router pair-gate guarantees an [ApiConfig] is populated before this
/// repository is read, so [_bootstrap] always fetches `/menu` from the
/// LAN server, maps the [MenuSnapshotDto] into domain models, and exposes
/// the result via [state]. No in-memory fallback.
class MenuRepository extends StateNotifier<MenuSnapshot> {
  MenuRepository({required this.ref}) : super(MenuSnapshot.empty) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    SatLog.repo('menu.bootstrap');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(menuStatusProvider.notifier).state = const AsyncValue.data(null);
      return;
    }
    state = MenuSnapshot.empty;
    ref.read(menuStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(menuStatusProvider.notifier).state = const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('menu.bootstrap fail $e');
      ref.read(menuStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
    // WS: any peer's menu mutation triggers a full refetch. Cheap; the
    // snapshot is small and refetch keeps modifier-group state consistent.
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.menuUpdated) return;
      SatLog.repo('menu.ws update kind=${ev.payload['kind']}');
      unawaited(_refetch());
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _refetch() async {
    final api = ref.read(apiClientProvider);
    final raw = await api.getJson('/menu') as Map<String, dynamic>;
    final dto = MenuSnapshotDto.fromJson(raw);
    state = _toDomain(dto);
    SatLog.repo(
      'menu.loaded cats=${state.categories.length} items=${state.items.length}',
    );
  }

  Future<void> refresh() {
    SatLog.repo('menu.refresh');
    return _bootstrap();
  }

  MenuSnapshot _toDomain(MenuSnapshotDto d) {
    return MenuSnapshot(
      categories: [
        for (final c in d.categories) MenuCategory(id: c.id, name: c.name),
      ],
      items: [for (final i in d.items) _itemFromDto(i)],
      tags: [
        for (final t in d.tags)
          MenuTag(
            id: t.id,
            kind: menuTagKindFromKey(t.kind),
            name: t.name,
            code: t.code,
            sortOrder: t.sortOrder,
          ),
      ],
    );
  }

  MenuItem _itemFromDto(MenuItemDto i) {
    return MenuItem(
      id: i.id,
      name: i.name,
      categoryId: i.categoryId,
      description: i.description,
      basePrice: i.basePrice,
      cost: i.cost,
      prepTime: i.prepTime,
      variants: [
        for (final v in i.variants)
          Variant(id: v.id, name: v.name, price: v.price),
      ],
      modifierGroups: [for (final g in i.modifierGroups) _modGroupFromDto(g)],
      allergens: List<String>.of(i.allergens),
      dietary: List<String>.of(i.dietary),
      unavailable: i.unavailable,
      photoRev: i.photoRev,
      autoSoldOut: i.autoSoldOut,
      soldOutVariantIds: List<String>.of(i.soldOutVariantIds),
      soldOutOptionIds: List<String>.of(i.soldOutOptionIds),
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

  /// Lookup an item by id from the snapshot. Returns null when the
  /// repository has not yet loaded the item — callers must handle the
  /// absence rather than receive a stale dummy.
  MenuItem? itemById(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---------- mutations ----------

  /// Insert when [item.id] is absent from state, otherwise PATCH.
  /// Pre-LAN (no apiConfig): updates local state only. In LAN mode the WS
  /// `menu.updated` event drives a refetch that supersedes the optimistic
  /// state, so other clients converge as well.
  Future<void> upsertItem(MenuItem item) async {
    final isInsert = !state.items.any((i) => i.id == item.id);
    SatLog.repo('menu.upsert id=${item.id} insert=$isInsert');
    final prev = state;
    state = state.copyWith(
      items: isInsert
          ? [...state.items, item]
          : [
              for (final i in state.items)
                if (i.id == item.id) item else i,
            ],
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final body = _itemToJson(item);
      final raw = isInsert
          ? await ref.read(apiClientProvider).postJson('/menu/items', body)
          : await ref
                .read(apiClientProvider)
                .patchJson('/menu/items/${item.id}', body);
      final dto = MenuItemDto.fromJson((raw as Map).cast<String, dynamic>());
      _mergeServerItem(dto);
    } catch (e) {
      SatLog.repo('menu.upsert fail $e');
      state = prev;
      rethrow;
    }
  }

  /// Upload (replace) an item's photo. Server bumps photoRev and returns the
  /// updated item, which we merge so the new rev busts the bytes cache.
  /// The item row must already exist — callers save the item first.
  Future<void> uploadPhoto(String id, List<int> bytes) async {
    SatLog.repo('menu.photo.upload id=$id bytes=${bytes.length}');
    if (ref.read(apiConfigProvider) == null) return;
    final raw = await ref
        .read(apiClientProvider)
        .putBytes('/menu/items/$id/photo', bytes);
    if (raw is Map) {
      _mergeServerItem(MenuItemDto.fromJson(raw.cast<String, dynamic>()));
    }
  }

  /// Clear an item's photo (back to the avatar fallback).
  Future<void> deletePhoto(String id) async {
    SatLog.repo('menu.photo.delete id=$id');
    if (ref.read(apiConfigProvider) == null) return;
    final raw = await ref
        .read(apiClientProvider)
        .deleteJson('/menu/items/$id/photo');
    if (raw is Map) {
      _mergeServerItem(MenuItemDto.fromJson(raw.cast<String, dynamic>()));
    }
  }

  Future<void> removeItem(String id) async {
    SatLog.repo('menu.remove id=$id');
    final prev = state;
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id != id) i,
      ],
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      await ref.read(apiClientProvider).deleteJson('/menu/items/$id');
    } catch (e) {
      SatLog.repo('menu.remove fail $e');
      state = prev;
      rethrow;
    }
  }

  Future<void> toggleAvailability(String id) async {
    final cur = state.items.where((i) => i.id == id).firstOrNull;
    if (cur == null) return;
    final next = !cur.unavailable;
    SatLog.repo('menu.soldOut id=$id → $next');
    final prev = state;
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == id) i.copyWith(unavailable: next) else i,
      ],
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).postJson(
        '/menu/items/$id/availability',
        {'unavailable': next},
      );
      final dto = MenuItemDto.fromJson((raw as Map).cast<String, dynamic>());
      _mergeServerItem(dto);
    } catch (e) {
      SatLog.repo('menu.soldOut fail $e');
      state = prev;
      rethrow;
    }
  }

  // ---------- categories ----------

  Future<void> createCategory(String name) async {
    SatLog.repo('menu.category.create $name');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    await ref.read(apiClientProvider).postJson('/menu/categories', {
      'name': name,
    });
    await _refetch();
  }

  Future<void> renameCategory(String id, String name) async {
    SatLog.repo('menu.category.rename $id → $name');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    await ref.read(apiClientProvider).patchJson('/menu/categories/$id', {
      'name': name,
    });
    await _refetch();
  }

  /// Delete a category. Throws if the server rejects (e.g. non-empty → 409).
  Future<void> deleteCategory(String id) async {
    SatLog.repo('menu.category.delete $id');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    await ref.read(apiClientProvider).deleteJson('/menu/categories/$id');
    await _refetch();
  }

  Future<void> reorderCategories(List<String> ids) async {
    SatLog.repo('menu.category.reorder ${ids.length}');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    await ref.read(apiClientProvider).postJson('/menu/categories/reorder', {
      'ids': ids,
    });
    await _refetch();
  }

  // ---------- helpers ----------

  void _mergeServerItem(MenuItemDto dto) {
    final merged = _itemFromDto(dto);
    state = state.copyWith(
      items: state.items.any((i) => i.id == merged.id)
          ? [
              for (final i in state.items)
                if (i.id == merged.id) merged else i,
            ]
          : [...state.items, merged],
    );
  }

  Map<String, dynamic> _itemToJson(MenuItem it) => {
    'id': it.id,
    'name': it.name,
    'categoryId': it.categoryId,
    'description': it.description,
    'basePrice': it.basePrice,
    'cost': it.cost,
    'prepTime': it.prepTime,
    'variants': [
      for (final v in it.variants)
        {'id': v.id, 'name': v.name, 'price': v.price},
    ],
    'modifierGroups': [
      for (final g in it.modifierGroups)
        {
          'id': g.id,
          'name': g.name,
          'required': g.required,
          'multi': g.multi,
          'options': [
            for (final o in g.options)
              {'id': o.id, 'name': o.name, 'priceDelta': o.priceDelta},
          ],
        },
    ],
    'allergens': it.allergens,
    'dietary': it.dietary,
    // Availability derived from ingredient stock is server-owned and never
    // posted back by a client (ADR-0040).
    'unavailable': it.unavailable,
  };

  // ---------- tags ----------

  Future<void> createTag(MenuTagKind kind, String name, String code) async {
    SatLog.repo('menu.tag.create $name');
    if (ref.read(apiConfigProvider) == null) return;
    await ref.read(apiClientProvider).postJson('/menu/tags', {
      'kind': kind == MenuTagKind.diet ? 'diet' : 'allergen',
      'name': name,
      'code': code,
    });
    await _refetch();
  }

  Future<void> updateTag(String id, {String? name, String? code}) async {
    SatLog.repo('menu.tag.update $id');
    if (ref.read(apiConfigProvider) == null) return;
    await ref.read(apiClientProvider).patchJson('/menu/tags/$id', {
      'name': ?name,
      'code': ?code,
    });
    await _refetch();
  }

  Future<void> deleteTag(String id) async {
    SatLog.repo('menu.tag.delete $id');
    if (ref.read(apiConfigProvider) == null) return;
    await ref.read(apiClientProvider).deleteJson('/menu/tags/$id');
    await _refetch();
  }

  Future<void> reorderTags(List<String> ids) async {
    SatLog.repo('menu.tag.reorder ${ids.length}');
    if (ref.read(apiConfigProvider) == null) return;
    await ref.read(apiClientProvider).postJson('/menu/tags/reorder', {
      'ids': ids,
    });
    await _refetch();
  }
}

final menuRepositoryProvider =
    StateNotifierProvider<MenuRepository, MenuSnapshot>((ref) {
      ref.watch(apiConfigProvider);
      return MenuRepository(ref: ref);
    });

/// Photo bytes for one menu item, keyed by `(id, rev)`. A photoRev change
/// produces a new key → fresh fetch; the stale-rev entry auto-disposes. Only
/// invoked when rev > 0 (MenuPhoto shows the avatar otherwise). Fetched over
/// the pinned client (see ApiClient.getBytes). Returns null when unpaired.
final menuPhotoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String id, int rev})>((ref, key) async {
      if (key.rev <= 0) return null;
      if (ref.watch(apiConfigProvider) == null) return null;
      final bytes = await ref
          .read(apiClientProvider)
          .getBytes('/menu/items/${key.id}/photo');
      ref.keepAlive();
      return bytes;
    });

final menuCategoriesProvider = Provider<List<MenuCategory>>(
  (ref) => ref.watch(menuRepositoryProvider).categories,
);

final menuItemsProvider = Provider<List<MenuItem>>(
  (ref) => ref.watch(menuRepositoryProvider).items,
);

/// Item id → its own `Waktu siap` override, null where the item inherits the
/// venue default. Built once per menu snapshot so the KDS, the order boards and
/// the alert sweep can all resolve a line's target without re-scanning the menu
/// per line. See ADR-0043.
/// `dependencies` is required, not decorative: the widget book overrides
/// [menuItemsProvider] in a nested scope, and without this declaration this
/// provider would keep serving the root menu inside it.
final prepTimeByItemProvider = Provider<Map<String, int?>>((ref) {
  return {for (final i in ref.watch(menuItemsProvider)) i.id: i.prepTime};
}, dependencies: [menuItemsProvider]);

/// All tags, snapshot order (sorted server-side by kind+sortOrder).
final menuTagsProvider = Provider<List<MenuTag>>(
  (ref) => ref.watch(menuRepositoryProvider).tags,
);

/// Tag id → tag, for resolving the ids stored on items.
final menuTagsByIdProvider = Provider<Map<String, MenuTag>>((ref) {
  return {for (final t in ref.watch(menuTagsProvider)) t.id: t};
});

/// Tags of a given kind, in sort order.
List<MenuTag> menuTagsOfKind(List<MenuTag> all, MenuTagKind kind) => [
  for (final t in all)
    if (t.kind == kind) t,
];
