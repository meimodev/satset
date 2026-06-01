import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'seed_data.dart' as seed;

/// Seed the database on first boot using the existing in-memory `DummyData`.
/// Admin sign-in is now Firebase-backed (per-uid local rows are provisioned on
/// first sign-in — see ADR-0015), so no email/password admin row is seeded.
/// Idempotent.
Future<void> seedIfEmpty(AppDatabase db) async {
  await _ensureWaiterCanVoid(db);
  await _ensureAdminRole(db);

  final hasUsers = (await db.select(db.users).get()).isNotEmpty;
  // Historical session seed is independent of the demo-user gate so existing
  // dev installs also pick up plausible reports data. Self-skips when
  // tableSessions already has rows.
  if (hasUsers) {
    await _seedHistoricalSessions(db);
    return;
  }

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
              description: Value(it.description),
              basePrice: it.basePrice,
              // Heuristic seed cost: 35% of base price. Manager can override
              // per item via the admin editor; reports degrade gracefully when
              // cost = 0 (treated as full margin).
              cost: Value((it.basePrice * 0.35).round()),
              prepTime: Value(it.prepTime),
              variantsJson: Value(jsonEncode(it.variants
                  .map((v) => {'id': v.id, 'name': v.name, 'price': v.price})
                  .toList())),
              modifierGroupsJson: Value(jsonEncode(it.modifierGroups
                  .map((m) => {
                        'id': m.id,
                        'name': m.name,
                        'required': m.required,
                        'multi': m.multi,
                        'options': m.options
                            .map((o) => {
                                  'id': o.id,
                                  'name': o.name,
                                  'priceDelta': o.priceDelta,
                                })
                            .toList(),
                      })
                  .toList())),
              allergensJson: Value(jsonEncode(it.allergens)),
              dietaryJson: Value(jsonEncode(it.dietary)),
              unavailable: Value(it.unavailable),
              stockCount: Value(it.stockCount),
              autoSoldOutAtZero: Value(it.autoSoldOutAtZero),
            ),
          );
    }
  });

  // Synthesize 30 days of historical sessions so the reports screen has
  // immediate data on a fresh first boot. Idempotent — skipped if any
  // table_sessions row already exists.
  await _seedHistoricalSessions(db);

  // First-boot verification: every reference table the seed populates must
  // be non-empty before this future resolves, so callers can rely on the
  // database being usable. Throws StateError otherwise — better to crash
  // early than to ship a half-seeded server.
  final users = await db.select(db.users).get();
  final roles = await db.select(db.roles).get();
  final zones = await db.select(db.zones).get();
  final cats = await db.select(db.menuCategories).get();
  final menu = await db.select(db.menuItems).get();
  if (users.isEmpty ||
      roles.isEmpty ||
      zones.isEmpty ||
      cats.isEmpty ||
      menu.isEmpty) {
    throw StateError(
        'seedIfEmpty: post-seed verification failed (users=${users.length} '
        'roles=${roles.length} zones=${zones.length} '
        'cats=${cats.length} menu=${menu.length})');
  }
}

String _hashPin(String pin) {
  return sha256.convert(utf8.encode('satset.v1::$pin')).toString();
}

/// Backfill `voidItem` onto the waiter role for installs seeded before
/// self-served voids (ADR-0006). Idempotent: no-op once the cap is present.
Future<void> _ensureWaiterCanVoid(AppDatabase db) async {
  final role = await (db.select(db.roles)
        ..where((r) => r.id.equals(seed.DummyData.roleWaiterId)))
      .getSingleOrNull();
  if (role == null) return;
  final caps = (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (caps.contains('voidItem')) return;
  caps.add('voidItem');
  await (db.update(db.roles)
        ..where((r) => r.id.equals(seed.DummyData.roleWaiterId)))
      .write(RolesCompanion(capabilitiesJson: Value(jsonEncode(caps))));
}

/// Ensure the shared admin role exists so Firebase-provisioned admin users
/// (ServerAuth.provisionAdminUser) and the `/auth/me` role join resolve, even
/// on an upgraded install that predates a given role seed. See ADR-0015.
Future<void> _ensureAdminRole(AppDatabase db) async {
  final adminRole = await (db.select(db.roles)
        ..where((r) => r.id.equals(seed.DummyData.roleAdminId)))
      .getSingleOrNull();
  if (adminRole != null) return;
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

/// Synthesize 30 days of `TableSessions` + `TableSessionTickets` so the
/// reports screen renders meaningful aggregates on a fresh DB. Daily session
/// volume peaks Thu–Sat; ticket sentAt timestamps cluster between 11:00 and
/// 22:00 with a 17–19 dinner peak. ~6 % of tickets are voided across rotating
/// reason codes. Skipped if any session row already exists (idempotent).
Future<void> _seedHistoricalSessions(AppDatabase db) async {
  final existing =
      await (db.selectOnly(db.tableSessions)..addColumns([db.tableSessions.id]))
          .get();
  if (existing.isNotEmpty) return;

  final menu = await db.select(db.menuItems).get();
  if (menu.isEmpty) return;
  final zones = await db.select(db.zones).get();
  if (zones.isEmpty) return;
  final venueTables = await db.select(db.venueTables).get();
  // Waiters only (kitchen/admin/etc. do not open sessions in this seed).
  final users = await (db.select(db.users)
        ..where((u) => u.roleId.equals(seed.DummyData.roleWaiterId)))
      .get();
  if (users.isEmpty) return;

  const reasonCodes = ['outOfStock', 'wrongOrder', 'customerChange', 'kitchenError', 'comp', 'other'];
  const reasonText = {
    'outOfStock': 'Stok habis',
    'wrongOrder': 'Salah input pelayan',
    'customerChange': 'Tamu ganti pesanan',
    'kitchenError': 'Kualitas dapur',
    'comp': 'Kompensasi manajer',
    'other': 'Lainnya',
  };

  final rng = Random(42); // deterministic seed for reproducible demo data
  const uuid = Uuid();
  final now = DateTime.now();

  await db.transaction(() async {
    for (var d = 0; d < 30; d++) {
      final dayBase = DateTime(now.year, now.month, now.day - d);
      // Weekday 5=Fri, 6=Sat — heavier; 0=Mon lighter.
      final wd = dayBase.weekday; // 1..7
      final sessionCount = switch (wd) {
        5 || 6 => 12 + rng.nextInt(6), // Fri/Sat
        7 || 4 => 9 + rng.nextInt(5),  // Sun/Thu
        _ => 6 + rng.nextInt(5),
      };

      for (var s = 0; s < sessionCount; s++) {
        // Dinner-weighted hour distribution.
        final hourBucket = rng.nextDouble();
        final hour = hourBucket < 0.55
            ? 17 + rng.nextInt(3) // 17/18/19
            : hourBucket < 0.80
                ? 11 + rng.nextInt(5) // 11..15 lunch
                : 20 + rng.nextInt(3); // 20..22 late
        final minute = rng.nextInt(60);
        final openedAt = DateTime(dayBase.year, dayBase.month, dayBase.day, hour, minute);
        final durationMin = 25 + rng.nextInt(70); // 25..95 min
        final closedAt = openedAt.add(Duration(minutes: durationMin));
        final pax = 1 + rng.nextInt(5); // 1..5
        final actor = users[rng.nextInt(users.length)];
        final zone = zones[rng.nextInt(zones.length)];
        final venueTable = venueTables.isEmpty
            ? null
            : venueTables[rng.nextInt(venueTables.length)];

        final sessionId = uuid.v4();
        final ticketsInSession = 2 + rng.nextInt(7); // 2..8 line items

        var subtotal = 0;
        var voidAmount = 0;
        final ticketRows = <TableSessionTicketsCompanion>[];
        for (var t = 0; t < ticketsInSession; t++) {
          final item = menu[rng.nextInt(menu.length)];
          final qty = 1 + rng.nextInt(3); // 1..3
          final lineTotal = item.basePrice * qty;
          final sentAtOffset = rng.nextInt(durationMin.clamp(1, 999));
          final sentAt = openedAt.add(Duration(minutes: sentAtOffset));
          final isVoid = rng.nextDouble() < 0.06;
          final status = isVoid ? 'voided' : 'served';
          // Speed-of-service stamps (ADR-0013). Served lines get a kitchen
          // prep span (3..22 min — median ~13 straddles the 15-min target so
          // the SLA hit-rate demos around ~60%) and a short pickup lag.
          // Voided lines never reached ready → both NULL.
          final prepMins = isVoid ? 0 : 3 + rng.nextInt(20);
          final pickupMins = isVoid ? 0 : 1 + rng.nextInt(8);
          final readyAt = isVoid ? null : sentAt.add(Duration(minutes: prepMins));
          final servedAt =
              isVoid ? null : readyAt!.add(Duration(minutes: pickupMins));
          final reasonCode = isVoid ? reasonCodes[rng.nextInt(reasonCodes.length)] : null;
          // Each session gets a few add-ons from a fixed pool so the
          // modifier-attach report has something to count. Structured
          // snapshot shape — see docs/adr/0011-ticket-modifier-snapshot.md.
          final modifiers = <Map<String, dynamic>>[
            if (rng.nextDouble() < 0.55)
              {'groupId': 'spice', 'optionId': 'md', 'label': 'Pedas sedang', 'priceDelta': 0},
            if (rng.nextDouble() < 0.30)
              {'groupId': 'extras', 'optionId': 'krupuk', 'label': 'Kerupuk', 'priceDelta': 3000},
            if (rng.nextDouble() < 0.20)
              {'groupId': 'sauce', 'optionId': 'medium', 'label': 'Saus sedang', 'priceDelta': 0},
          ];

          if (isVoid) {
            voidAmount += lineTotal;
          } else {
            subtotal += lineTotal;
          }

          ticketRows.add(TableSessionTicketsCompanion.insert(
            id: uuid.v4(),
            sessionId: sessionId,
            ticketId: uuid.v4(),
            itemId: item.id,
            name: item.name,
            course: 'mains',
            qty: Value(qty),
            modifiersJson: Value(jsonEncode(modifiers)),
            price: item.basePrice,
            status: status,
            sentAt: sentAt,
            readyAt: Value(readyAt),
            servedAt: Value(servedAt),
            voidReason:
                reasonCode == null ? const Value.absent() : Value(reasonText[reasonCode]),
            voidReasonCode:
                reasonCode == null ? const Value.absent() : Value(reasonCode),
            createdByUserId: Value(actor.id),
          ));
        }

        await db.into(db.tableSessions).insert(TableSessionsCompanion.insert(
              id: sessionId,
              tableId: venueTable?.id ?? 'T${rng.nextInt(20) + 1}',
              tableLabel: Value(venueTable?.label),
              zoneId: zone.id,
              pax: Value(pax),
              openedAt: Value(openedAt),
              closedAt: closedAt,
              durationSec: Value(durationMin * 60),
              actorUserId: Value(actor.id),
              subtotal: Value(subtotal),
              voidAmount: Value(voidAmount),
              netTotal: Value(subtotal - voidAmount),
              ticketCount: Value(ticketsInSession),
            ));
        await db.batch((b) => b.insertAll(db.tableSessionTickets, ticketRows));
      }
    }
  });
}

