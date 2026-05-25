import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'database.dart';
import 'seed_data.dart' as seed;

/// Default admin email/password seeded on first boot. PIN-only sign-in is
/// for demo users; the dedicated admin row uses email+password.
const String defaultAdminId = 'admin';
const String defaultAdminEmail = 'admin@satset.local';
const String defaultAdminPassword = 'admin123';

String _hashPassword(String pw) =>
    sha256.convert(utf8.encode('satset.v1.pw::$pw')).toString();

/// Seed the database on first boot using the existing in-memory `DummyData`,
/// plus a dedicated admin row with email+password credentials.
/// Idempotent: skips when the dedicated admin already exists.
Future<void> seedIfEmpty(AppDatabase db) async {
  await _seedDedicatedAdmin(db);

  final hasUsers = (await db.select(db.users).get()).isNotEmpty;
  // Demo seed runs only when the table holds nothing beyond the dedicated
  // admin row (i.e. exactly one user with the well-known admin id).
  final onlyAdminPresent = hasUsers &&
      (await (db.select(db.users)..where((u) => u.id.equals(defaultAdminId)))
              .getSingleOrNull()) !=
          null &&
      (await db.select(db.users).get()).length == 1;
  if (hasUsers && !onlyAdminPresent) return;

  await db.transaction(() async {
    // Roles
    for (final r in seed.DummyData.initialRoles()) {
      await db.into(db.roles).insertOnConflictUpdate(RolesCompanion.insert(
            id: r.id,
            name: r.name,
            colorHex: Value('#${r.colorHex.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'),
            capabilitiesJson:
                Value(jsonEncode(r.capabilities.map((c) => c.name).toList())),
          ));
    }
    // Zones
    var zi = 0;
    for (final z in seed.DummyData.zones) {
      await db.into(db.zones).insertOnConflictUpdate(ZonesCompanion.insert(
            id: z.id,
            name: z.name,
            short: z.short,
            colorHex: Value('#${z.colorHex.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'),
            iconKey: Value(z.iconKey),
            sortOrder: Value(zi++),
          ));
    }
    // Users (with hashed PINs)
    for (final u in seed.DummyData.users) {
      await db.into(db.users).insertOnConflictUpdate(UsersCompanion.insert(
            id: u.id,
            name: u.name,
            initials: u.initials,
            roleId: u.roleId ?? u.role.name,
            zoneAssigned: Value(u.zoneAssigned),
            pinHash: _hashPin(u.pin),
            disabled: Value(u.disabled),
            avatarColorHex: Value(u.avatarColorHex),
          ));
    }
    // Categories
    var ci = 0;
    for (final c in seed.DummyData.categories) {
      await db.into(db.menuCategories).insertOnConflictUpdate(
            MenuCategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              sortOrder: Value(ci++),
            ),
          );
    }
    // Menu items
    for (final it in seed.DummyData.items) {
      await db.into(db.menuItems).insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: it.id,
              name: it.name,
              categoryId: it.categoryId,
              station: it.station.name,
              description: Value(it.description),
              basePrice: it.basePrice,
              prepTime: Value(it.prepTime),
              variantsJson: Value(jsonEncode(it.variants
                  .map((v) => {'id': v.id, 'name': v.name, 'price': v.price})
                  .toList())),
              modifierGroupIdsJson:
                  Value(jsonEncode(it.modifierGroups.map((m) => m.id).toList())),
              allergensJson:
                  Value(jsonEncode(it.allergens.map((a) => a.name).toList())),
              dietaryJson:
                  Value(jsonEncode(it.dietary.map((d) => d.name).toList())),
              unavailable: Value(it.unavailable),
              stockCount: Value(it.stockCount),
              autoEightySixAtZero: Value(it.autoEightySixAtZero),
            ),
          );
      for (final mg in it.modifierGroups) {
        await db.into(db.modifierGroups).insertOnConflictUpdate(
              ModifierGroupsCompanion.insert(
                id: mg.id,
                name: mg.name,
                required: Value(mg.required),
                multi: Value(mg.multi),
                optionsJson: Value(jsonEncode(mg.options
                    .map((o) => {
                          'id': o.id,
                          'name': o.name,
                          'priceDelta': o.priceDelta,
                        })
                    .toList())),
              ),
            );
      }
    }
  });

  // First-boot verification: every reference table the seed populates must
  // be non-empty before this future resolves, so callers can rely on the
  // database being usable. Throws StateError otherwise — better to crash
  // early than to ship a half-seeded server.
  final users = await db.select(db.users).get();
  final roles = await db.select(db.roles).get();
  final zones = await db.select(db.zones).get();
  final cats = await db.select(db.menuCategories).get();
  final menu = await db.select(db.menuItems).get();
  final mods = await db.select(db.modifierGroups).get();
  if (users.isEmpty ||
      roles.isEmpty ||
      zones.isEmpty ||
      cats.isEmpty ||
      menu.isEmpty ||
      mods.isEmpty) {
    throw StateError(
        'seedIfEmpty: post-seed verification failed (users=${users.length} '
        'roles=${roles.length} zones=${zones.length} '
        'cats=${cats.length} menu=${menu.length} mods=${mods.length})');
  }
}

String _hashPin(String pin) {
  return sha256.convert(utf8.encode('satset.v1::$pin')).toString();
}

Future<void> _seedDedicatedAdmin(AppDatabase db) async {
  final existing =
      await (db.select(db.users)..where((u) => u.id.equals(defaultAdminId)))
          .getSingleOrNull();
  if (existing != null) return;
  // Ensure the admin role is present so the FK-like join in /auth/me resolves.
  final adminRole = await (db.select(db.roles)
        ..where((r) => r.id.equals(seed.DummyData.roleAdminId)))
      .getSingleOrNull();
  if (adminRole == null) {
    await db.into(db.roles).insertOnConflictUpdate(RolesCompanion.insert(
          id: seed.DummyData.roleAdminId,
          name: 'Admin',
          colorHex: const Value('#C08AFF'),
          capabilitiesJson: Value(jsonEncode([
            for (final c in seed.DummyData.initialRoles()
                .firstWhere((r) => r.id == seed.DummyData.roleAdminId)
                .capabilities)
              c.name,
          ])),
        ));
  }
  await db.into(db.users).insert(UsersCompanion.insert(
        id: defaultAdminId,
        name: 'Administrator',
        initials: 'AD',
        roleId: seed.DummyData.roleAdminId,
        pinHash: '',
        email: const Value(defaultAdminEmail),
        passwordHash: Value(_hashPassword(defaultAdminPassword)),
      ));
}
