import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:satset/server/self_order.dart' show mintMissingGuestCodes;

import 'package:satset/domain/models/capability.dart';

import '../pin.dart' as pin_lib;
import '../stock.dart';
import '../ws_hub.dart';
import 'database.dart';
import 'seed_data.dart' as seed;
import 'seed_history.dart';
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
  await _ensureDefaultCashBox(db);
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

/// The **reference half** of the generic restaurant dataset (ADR-0017): 4
/// zones with 20 tables between them, the generic menu (categories + items),
/// the inventory half — bahan + resep with opening stock (ADR-0042) — and
/// 4 staff — two waiters, two kitchen — with their roles + capabilities.
///
/// Idempotent (`insertOnConflictUpdate`). Seeds **no** PIN admin (admin is
/// Firebase-only).
///
/// This writes no transactional rows. The fabricated month that makes the
/// reports and the audit log readable is [seedSampleVenue], which runs this
/// first and then generates on top of it (ADR-0073).
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

    // Every table gets a code, so the QR sheet is printable the moment a venue
    // switches [[Pesan mandiri]] on rather than needing a rotate first
    // (ADR-0105). Only blanks are filled: re-running this seed must not kill
    // every QR already printed and stuck to a table.
    await mintMissingGuestCodes(db);

    // Staff (2 waiters + 2 kitchen, hashed PINs).
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
              // ponytail: the seed's own three drink categories, not a
              // general rule — a real venue ticks the box per item on the
              // Menu tamu tab, because category names are venue-authored.
              alcohol: Value(
                const {'beer', 'wine', 'cocktails'}.contains(it.categoryId),
              ),
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

/// **The** sample dataset (ADR-0073): the reference half above, plus a
/// fabricated month of settled service and the audit trail that goes with it.
///
/// One action, not two. ADR-0052 §1 kept these apart so an owner loading
/// sample data on opening day would not inherit invented walkouts; ADR-0073
/// merges them and moves that protection onto [canSeedSample] (which refuses
/// outright on a venue that has traded) plus [clearSampleData] (which removes
/// every fabricated row and leaves the menu standing).
///
/// Writes ~1500 bills through the production order path. Expect several
/// minutes on a mid-range tablet — callers run it as a job and report progress
/// rather than blocking on it.
Future<void> seedSampleVenue(
  AppDatabase db, {
  WsHub? hub,
  void Function(int day, int total)? onDay,
}) async {
  if (!await canSeedSample(db)) {
    throw const SampleSeedRefused(
      'Venue sudah punya riwayat pesanan. Contoh data tidak dimuat.',
    );
  }
  await seedGenericRestaurant(db);

  final rng = sampleRng();
  final menu = await loadSampleMenu(db);
  if (menu.isEmpty) return;

  // Turn the program on before the month runs, or the seeded bills attach
  // nobody and the Keanggotaan report is a screen of zeroes on a venue that is
  // meant to demonstrate it. Points and the punch card only — no member
  // discount preset, because a standing discount the seeded bills never
  // applied would make the directory disagree with the history.
  await (db.update(db.venueSettings)..where((s) => s.id.equals('default')))
      .write(
        VenueSettingsCompanion(
          membersEnabled: const Value(true),
          memberPointsEnabled: const Value(true),
          memberPunchEnabled: const Value(true),
          // The one item a regular buys every visit — which is what a punch
          // card is for. A venue whose punch item is the wagyu burger has a
          // card nobody ever fills.
          memberPunchItemId: Value(
            menu.any((m) => m.id == 'kopi-susu') ? 'kopi-susu' : menu.first.id,
          ),
          // Tabs on too, with a limit a regular can actually reach (ADR-0098).
          // The Piutang section is otherwise a block of zeroes on the one
          // venue meant to show what a tab looks like once it has run a month.
          memberDebtEnabled: const Value(true),
          memberDebtLimit: const Value(500000),
        ),
      );

  // A detached hub when none is attached (tests, headless seeding): the close
  // path broadcasts per visit, and a month of backdated sessions has no live
  // listener worth notifying anyway.
  await seedHistory(db, hub ?? WsHub(), rng, menu, onDay: onDay);
  await seedAdminAudit(db, rng);
  await recomputeBalances(db);
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

/// One hasher for the whole server (ADR-0112). Seeded staff get salted
/// hashes like everybody else — a seeded venue must not be the one place a
/// PIN is stored the old way.
String _hashPin(String pin) => pin_lib.hashPin(pin);

/// Backfill `voidItem` onto the waiter role for installs seeded before
/// self-served voids (ADR-0006). Idempotent: no-op once present or if the
/// waiter role does not exist yet.
/// The venue always has somewhere to file a cash movement (ADR-0131).
///
/// `onCreate` and the v73 migration both insert `box-main`, so this is a third
/// belt: a venue whose boxes were all somehow deactivated still boots with one
/// to post against, and a rename survives because the insert ignores conflicts.
Future<void> _ensureDefaultCashBox(AppDatabase db) async {
  await db
      .into(db.cashBoxes)
      .insert(
        CashBoxesCompanion.insert(id: 'box-main', name: 'Kas Utama'),
        mode: InsertMode.insertOrIgnore,
      );
  // And somewhere to file what it was spent on (ADR-0135), on the same belt:
  // a box with no categories cannot take an expense at all.
  await db.seedCashCategories();
}

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
///
/// Its capabilities are **reconciled on every boot**, not written once: the
/// admin role *is* `Capability.values` by definition and the Staf sheet shows it
/// read-only, so a stored snapshot is the one set nobody can repair. Adding a
/// capability to the enum used to leave every existing venue's admin at 19/20
/// with no way back — which is exactly how `manageCash` shipped unreachable.
Future<void> _ensureAdminRole(AppDatabase db) async {
  final all = jsonEncode([for (final c in Capability.values) c.name]);
  final adminRole = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).getSingleOrNull();
  if (adminRole != null) {
    if (adminRole.capabilitiesJson != all) {
      await (db.update(db.roles)
            ..where((r) => r.id.equals(seed.DummyData.roleAdminId)))
          .write(RolesCompanion(capabilitiesJson: Value(all)));
    }
    return;
  }
  await db
      .into(db.roles)
      .insertOnConflictUpdate(
        RolesCompanion.insert(
          id: seed.DummyData.roleAdminId,
          name: 'Admin',
          colorHex: const Value('#C08AFF'),
          capabilitiesJson: Value(all),
        ),
      );
}
