// Patrol end-to-end test for the menu *categories* admin flow.
//
// We don't boot the real `main()` here: in Server mode it stands up the
// embedded shelf server (TLS + mDNS + port binds) which collides with
// Patrol's on-device service (port 8082) and hangs the run — same reason
// app_boot_test.dart pumps the widget tree directly. See docs/testing/patrol.md.
//
// Instead we mount MenuAdminScreen under the real SatSet theme with two
// provider overrides:
//   * menuPermissionProvider -> admin (unlocks the Kategori tab + CRUD)
//   * menuRepositoryProvider -> an in-memory fake so category mutations
//     resolve locally instead of hitting the LAN server.
// The UI, view-models, dialogs and reorderable list are all the real thing —
// only the network tail is faked. That exercises the full add / rename / delete
// category journey end-to-end on-device.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/features/admin/menu_admin_screen.dart';
import 'package:satset/ui/features/admin/menu_admin_view_model.dart';

/// In-memory MenuRepository: category mutations update [state] directly,
/// no apiConfig / HTTP required. Seeded with two starter categories.
class _FakeMenuRepository extends MenuRepository {
  _FakeMenuRepository(Ref ref) : super(ref: ref) {
    // apiConfig is null in the test scope, so super's _bootstrap returns
    // before clearing state — this seed survives.
    state = const MenuSnapshot(
      categories: [
        MenuCategory(id: 'c1', name: 'Makanan'),
        MenuCategory(id: 'c2', name: 'Minuman'),
      ],
      items: [],
      tags: [],
    );
  }

  int _seq = 0;

  @override
  Future<void> createCategory(String name) async {
    state = state.copyWith(
      categories: [
        ...state.categories,
        MenuCategory(id: 'new${_seq++}', name: name),
      ],
    );
  }

  @override
  Future<void> renameCategory(String id, String name) async {
    state = state.copyWith(
      categories: [
        for (final c in state.categories)
          if (c.id == id) MenuCategory(id: c.id, name: name) else c,
      ],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(
      categories: [for (final c in state.categories) if (c.id != id) c],
    );
  }
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      menuPermissionProvider.overrideWithValue(MenuPermission.admin),
      menuRepositoryProvider.overrideWith((ref) => _FakeMenuRepository(ref)),
    ],
    child: MaterialApp(
      theme: satTheme(SatTheme.amberTerang),
      home: const Scaffold(body: MenuAdminScreen()),
    ),
  );
}

void main() {
  patrolTest('admin can add, rename, and delete a menu category', ($) async {
    await $.pumpWidget(_harness());
    // Fixed pumps — pumpAndSettle can stall on google_fonts' first-launch
    // fetch (see app_boot_test.dart).
    for (var i = 0; i < 5; i++) {
      await $.pump(const Duration(milliseconds: 400));
    }

    // Switch to the Kategori tab.
    await $('Kategori').tap();

    // Seed categories are visible.
    expect($('Makanan'), findsOneWidget);
    expect($('Minuman'), findsOneWidget);

    // --- ADD ---------------------------------------------------------
    await $('+ Tambah kategori').tap();
    await $(TextField).enterText('Makanan Penutup');
    await $('Simpan').tap();
    expect($('Makanan Penutup'), findsOneWidget);

    // --- RENAME ------------------------------------------------------
    // First row is "Makanan"; tap its edit pencil and rename it.
    await $(Icons.edit_outlined).first.tap();
    await $(TextField).enterText('Makanan Utama');
    await $('Simpan').tap();
    expect($('Makanan Utama'), findsOneWidget);
    expect($('Makanan'), findsNothing);

    // --- DELETE ------------------------------------------------------
    // First row ("Makanan Utama") has 0 items, so its delete is allowed and
    // resolves silently. Tap it and confirm the row is gone.
    await $(Icons.delete_outline).first.tap();
    expect($('Makanan Utama'), findsNothing);
    expect($('Minuman'), findsOneWidget);
  });
}
