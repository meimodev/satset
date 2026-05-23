import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'package:satset/data/services/dummy_data_seed.dart' as seed;
import 'database.dart';

/// Seed the database on first boot using the existing in-memory `DummyData`.
/// Idempotent: skips if reference tables already populated.
Future<void> seedIfEmpty(AppDatabase db) async {
  final hasUsers = (await db.select(db.users).get()).isNotEmpty;
  if (hasUsers) return;

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
            onDuty: Value(u.onDuty),
            disabled: Value(u.disabled),
          ));
    }
    // Tables
    for (final t in seed.DummyData.tables) {
      await db.into(db.venueTables).insertOnConflictUpdate(
            VenueTablesCompanion.insert(
              id: t.id,
              zoneId: t.zoneId,
              label: Value(t.label),
              pax: Value(t.pax),
              active: Value(t.active),
              status: Value(t.status.name),
              openAmount: Value(t.openAmount),
              readyCount: Value(t.readyCount),
              lastActorId: Value(t.lastActorId),
            ),
          );
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
    // Tickets — must be awaited inside the transaction, not fire-and-forget.
    final ticketsByTable = seed.DummyData.initialTicketsByTable();
    for (final entry in ticketsByTable.entries) {
      final tableId = entry.key;
      for (final t in entry.value) {
        await db.into(db.tickets).insertOnConflictUpdate(
              TicketsCompanion.insert(
                id: t.id,
                tableId: tableId,
                itemId: t.itemId,
                name: t.name,
                variantName: Value(t.variantName),
                course: t.course.name,
                station: t.station.name,
                qty: Value(t.qty),
                modifiersJson: Value(jsonEncode(t.modifiers)),
                specialInstructions: Value(t.specialInstructions),
                price: t.price,
                status: t.status.name,
                sentAt: DateTime.tryParse(t.sentAt) ?? DateTime.now(),
                voidReason: Value(t.voidReason),
                voidApprovedBy: Value(t.voidApprovedBy),
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
  final zones = await db.select(db.zones).get();
  final tables = await db.select(db.venueTables).get();
  final menu = await db.select(db.menuItems).get();
  final tickets = await db.select(db.tickets).get();
  if (users.isEmpty ||
      zones.isEmpty ||
      tables.isEmpty ||
      menu.isEmpty ||
      tickets.isEmpty) {
    throw StateError(
        'seedIfEmpty: post-seed verification failed (users=${users.length} '
        'zones=${zones.length} tables=${tables.length} menu=${menu.length} '
        'tickets=${tickets.length})');
  }
}

String _hashPin(String pin) {
  return sha256.convert(utf8.encode('satset.v1::$pin')).toString();
}
