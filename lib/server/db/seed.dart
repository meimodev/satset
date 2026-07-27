import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../stock.dart';
import 'database.dart';
import 'seed_data.dart' as seed;
import 'seed_inventory_data.dart';

/// Always-on **infra** seed. Runs on every Server boot; idempotent.
///
/// Seeds only what the server needs to function regardless of whether the
/// venue has loaded sample data: the shared **admin role** (so a
/// Firebase-provisioned admin uid can resolve its role — see ADR-0015) and a
/// `voidItem` backfill on the waiter role (ADR-0006). It deliberately does
/// **not** seed zones/tables/menu/staff — that generic restaurant dataset is
/// offered to the admin via the first-run prompt (`seedGenericRestaurant`,
/// see ADR-0017) and never auto-loaded.
Future<void> seedInfra(AppDatabase db) async {
  await _ensureAdminRole(db);
  await _ensureWaiterCanVoid(db);
}

/// Whether the host DB still has no sample restaurant data — drives the
/// first-run generic-seed prompt. Infra rows (the admin role) and
/// Firebase-provisioned admin user rows do not count: a venue is considered
/// "set up" once it has any zone, any menu item, or any non-admin user
/// (a seeded or manually-added waiter/kitchen/etc.).
Future<bool> needsGenericSeed(AppDatabase db) async {
  final zones = await db.select(db.zones).get();
  if (zones.isNotEmpty) return false;
  final items = await db.select(db.menuItems).get();
  if (items.isNotEmpty) return false;
  final users = await db.select(db.users).get();
  final hasNonAdminUser = users.any(
    (u) => u.roleId != seed.DummyData.roleAdminId,
  );
  return !hasNonAdminUser;
}

/// The prompted **generic restaurant** dataset (ADR-0017): 2 zones
/// (Dalam / Luar) with 2 tables each, the generic menu (categories + items),
/// the inventory half — bahan + resep with opening stock (ADR-0042) — and
/// 2 staff — one waiter, one kitchen — with their roles + capabilities.
///
/// Idempotent (`insertOnConflictUpdate`). Seeds **no** PIN admin (admin is
/// Firebase-only) and **no** fake report history. Safe to call from the
/// admin-triggered seed endpoint; callers should broadcast the relevant WS
/// events afterward so paired devices refetch.
Future<void> seedGenericRestaurant(AppDatabase db) async {
  await seedInfra(db);

  await db.transaction(() async {
    // Roles (waiter + kitchen; admin handled by seedInfra).
    for (final r in seed.DummyData.genericRoles()) {
      await db
          .into(db.roles)
          .insertOnConflictUpdate(
            RolesCompanion.insert(
              id: r.id,
              name: r.name,
              colorHex: Value(_hex(r.colorHex)),
              capabilitiesJson: Value(
                jsonEncode(r.capabilities.map((c) => c.name).toList()),
              ),
            ),
          );
    }

    // Zones.
    var zi = 0;
    for (final z in seed.DummyData.genericZones) {
      await db
          .into(db.zones)
          .insertOnConflictUpdate(
            ZonesCompanion.insert(
              id: z.id,
              name: z.name,
              short: z.short,
              colorHex: Value(_hex(z.colorHex)),
              iconKey: Value(z.iconKey),
              sortOrder: Value(zi++),
            ),
          );
    }

    // Tables (2 per zone).
    for (final t in seed.DummyData.genericTables) {
      await db
          .into(db.venueTables)
          .insertOnConflictUpdate(
            VenueTablesCompanion.insert(
              id: t.id,
              zoneId: t.zoneId,
              label: Value(t.id),
              pax: Value(t.pax),
              capacity: Value(t.pax),
              status: const Value('available'),
            ),
          );
    }

    // Staff (1 waiter + 1 kitchen, hashed PINs).
    for (final u in seed.DummyData.genericUsers) {
      await db
          .into(db.users)
          .insertOnConflictUpdate(
            UsersCompanion.insert(
              id: u.id,
              name: u.name,
              initials: u.initials,
              roleId: u.roleId ?? u.role.name,
              zoneAssigned: Value(u.zoneAssigned),
              pinHash: _hashPin(u.pin),
              disabled: Value(u.disabled),
              avatarColorHex: Value(u.avatarColorHex),
            ),
          );
    }

    // Menu categories.
    var ci = 0;
    for (final c in seed.DummyData.categories) {
      await db
          .into(db.menuCategories)
          .insertOnConflictUpdate(
            MenuCategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              sortOrder: Value(ci++),
            ),
          );
    }

    // Menu items.
    for (final it in seed.DummyData.items) {
      await db
          .into(db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: it.id,
              name: it.name,
              categoryId: it.categoryId,
              description: Value(it.description),
              basePrice: it.basePrice,
              // Heuristic seed cost: 35% of base price. Manager overrides per
              // item in the editor; reports treat cost=0 as full margin.
              cost: Value((it.basePrice * 0.35).round()),
              prepTime: Value(it.prepTime),
              variantsJson: Value(
                jsonEncode(
                  it.variants
                      .map(
                        (v) => {'id': v.id, 'name': v.name, 'price': v.price},
                      )
                      .toList(),
                ),
              ),
              modifierGroupsJson: Value(
                jsonEncode(
                  it.modifierGroups
                      .map(
                        (m) => {
                          'id': m.id,
                          'name': m.name,
                          'required': m.required,
                          'multi': m.multi,
                          'options': m.options
                              .map(
                                (o) => {
                                  'id': o.id,
                                  'name': o.name,
                                  'priceDelta': o.priceDelta,
                                },
                              )
                              .toList(),
                        },
                      )
                      .toList(),
                ),
              ),
              allergensJson: Value(jsonEncode(it.allergens)),
              dietaryJson: Value(jsonEncode(it.dietary)),
              unavailable: Value(it.unavailable),
            ),
          );
    }

    await _seedInventory(db);
  });

  // Recipes changed which items *can* go habis, so the cached flag signatures
  // no longer describe the same menu.
  stockFlags.invalidate();
}

/// Bahan + resep (ADR-0042).
///
/// Bahan are **insert-if-absent**: `stockOnHand` is the one number in this
/// dataset that becomes real the moment the venue starts trading, and
/// `/seed/generic` can be re-posted at any time. Recipes are reference data
/// like the menu itself and are replaced wholesale.
Future<void> _seedInventory(AppDatabase db) async {
  for (final b in seedIngredients) {
    final existing = await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals(b.id))).getSingleOrNull();
    if (existing != null) continue;

    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: b.id,
            name: b.name,
            unit: b.unit.name,
            lowStockAt: Value(b.lowAtBase),
            batchYield: Value(b.batchYieldBase),
          ),
        );
    // Opening stock arrives the way real stock does — a `receive` movement
    // that also prices the moving average — so the ledger sums to the balance
    // from the first row (ADR-0041 §2). This is not fake report history: no
    // sales, no wastage, one arrival per bahan.
    await receiveStock(
      db,
      ingredientId: b.id,
      qty: b.openingBase,
      unitCostMicro: b.costMicro,
      sourceLabel: 'Stok awal',
      note: 'Contoh data restoran',
    );
  }

  for (final e in seedIngredientRecipes.entries) {
    await writeRecipes(
      db,
      e.key,
      seedRecipePayload(SeedRecipe(base: e.value)),
      ownerKind: 'ingredient',
    );
  }
  for (final e in seedItemRecipes.entries) {
    await writeRecipes(db, e.key, seedRecipePayload(e.value));
  }
}

String _hex(int v) =>
    '#${v.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

String _hashPin(String pin) {
  return sha256.convert(utf8.encode('satset.v1::$pin')).toString();
}

/// Backfill `voidItem` onto the waiter role for installs seeded before
/// self-served voids (ADR-0006). Idempotent: no-op once present or if the
/// waiter role does not exist yet.
Future<void> _ensureWaiterCanVoid(AppDatabase db) async {
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(seed.DummyData.roleWaiterId))).getSingleOrNull();
  if (role == null) return;
  final caps = (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (caps.contains('voidItem')) return;
  caps.add('voidItem');
  await (db.update(db.roles)
        ..where((r) => r.id.equals(seed.DummyData.roleWaiterId)))
      .write(RolesCompanion(capabilitiesJson: Value(jsonEncode(caps))));
}

/// Ensure the shared admin role exists so Firebase-provisioned admin users
/// (`ServerAuth.provisionAdminUser`) and the `/auth/me` role join resolve,
/// even on an install that predates a given role seed. See ADR-0015.
Future<void> _ensureAdminRole(AppDatabase db) async {
  final adminRole = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).getSingleOrNull();
  if (adminRole != null) return;
  await db
      .into(db.roles)
      .insertOnConflictUpdate(
        RolesCompanion.insert(
          id: seed.DummyData.roleAdminId,
          name: 'Admin',
          colorHex: const Value('#C08AFF'),
          capabilitiesJson: Value(
            jsonEncode([
              for (final c
                  in seed.DummyData.initialRoles()
                      .firstWhere((r) => r.id == seed.DummyData.roleAdminId)
                      .capabilities)
                c.name,
            ]),
          ),
        ),
      );
}
