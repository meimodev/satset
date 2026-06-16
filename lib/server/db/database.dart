import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:satset/domain/models/user.dart' show avatarColorPalette;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Roles,
  Zones,
  VenueTables,
  Visits,
  MenuCategories,
  MenuItems,
  MenuTags,
  Tickets,
  Sessions,
  Devices,
  PairTokens,
  Idempotency,
  AuditEntries,
  VenueSettings,
  Printers,
  TableSessions,
  TableSessionTickets,
  TableSessionCourses,
  Reservations,
  Receipts,
  ReceiptLines,
  Payments,
  TableSessionReceipts,
  TableSessionPayments,
  DailyCounters,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 32;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Idempotent: a previous failed migration may have already
            // added one or both columns before crashing. Tolerate the
            // "duplicate column" SQL error on re-run.
            await _safeAddColumn('email');
            await _safeAddColumn('password_hash');
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
                'ON users(email) WHERE email IS NOT NULL');
          }
          if (from < 3) {
            await _safeDropColumn('on_duty');
          }
          if (from < 4) {
            await _safeAddColumn('avatar_color_hex', type: 'INTEGER');
            await _backfillAvatarColors();
          }
          if (from < 5) {
            await _safeAddColumnOn(
                'venue_tables', 'locked_by', type: 'TEXT');
            await _safeAddColumnOn(
                'venue_tables', 'locked_by_name', type: 'TEXT');
            await _safeAddColumnOn(
                'venue_tables', 'locked_at', type: 'INTEGER');
            await _safeAddColumnOn(
                'venue_tables', 'lock_expires_at', type: 'INTEGER');
          }
          if (from < 6) {
            await _safeAddColumnOn(
                'venue_tables', 'opened_at', type: 'INTEGER');
          }
          if (from < 7) {
            // Wipe stale demo table + ticket seed; the app now requires
            // tables to be created via the admin floor editor.
            await customStatement('DELETE FROM tickets');
            await customStatement('DELETE FROM venue_tables');
          }
          if (from < 8) {
            await _safeAddColumnOn(
                'venue_tables', 'capacity', type: 'INTEGER NOT NULL DEFAULT 2');
            // Pre-v8 `pax` doubled as seat count (admin floor labelled it
            // "Kapasitas kursi"). Promote it to the new capacity column and
            // reset pax to 1 so the stepper has headroom on existing rows.
            await customStatement(
                'UPDATE venue_tables SET capacity = pax WHERE pax > capacity');
            await customStatement(
                'UPDATE venue_tables SET pax = 1 WHERE pax > 1');
          }
          if (from < 9) {
            await m.createTable(venueSettings);
            await customStatement(
                "INSERT OR IGNORE INTO venue_settings(id) VALUES('default')");
          }
          if (from < 10) {
            await _safeAddColumnOn('venue_settings', 'display_name',
                type: "TEXT NOT NULL DEFAULT 'Warung Sebelah'");
            await _safeAddColumnOn('venue_settings', 'legal_name',
                type: "TEXT NOT NULL DEFAULT ''");
            await _safeAddColumnOn('venue_settings', 'address',
                type: "TEXT NOT NULL DEFAULT ''");
            await _safeAddColumnOn('venue_settings', 'phone',
                type: "TEXT NOT NULL DEFAULT ''");
            await _safeAddColumnOn('venue_settings', 'receipt_header',
                type: "TEXT NOT NULL DEFAULT ''");
            await _safeAddColumnOn('venue_settings', 'receipt_footer',
                type: "TEXT NOT NULL DEFAULT ''");
          }
          if (from < 11) {
            await m.createTable(printers);
          }
          if (from < 12) {
            await _safeAddColumnOn('tickets', 'created_by_user_id',
                type: 'TEXT');
          }
          if (from < 13) {
            await m.createTable(tableSessions);
            await m.createTable(tableSessionTickets);
            await m.createTable(tableSessionCourses);
          }
          if (from < 14) {
            await _safeAddColumnOn('menu_items', 'cost',
                type: 'INTEGER NOT NULL DEFAULT 0');
            await _safeAddColumnOn('tickets', 'void_reason_code', type: 'TEXT');
            await _safeAddColumnOn(
                'table_session_tickets', 'void_reason_code', type: 'TEXT');
            // Backfill cost = basePrice * 0.35 for already-seeded items so the
            // matrix has plausible margins on existing installs. New seed paths
            // set this explicitly per item.
            await customStatement(
                'UPDATE menu_items SET cost = CAST(base_price * 0.35 AS INTEGER) WHERE cost = 0');
            // Backfill void_reason_code from free-text reason via substring
            // heuristic. Unknown reasons fall through to "other".
            await customStatement(
                "UPDATE tickets SET void_reason_code = CASE "
                "WHEN void_reason IS NULL THEN NULL "
                "WHEN lower(void_reason) LIKE '%stok%' OR lower(void_reason) LIKE '%habis%' THEN 'outOfStock' "
                "WHEN lower(void_reason) LIKE '%salah%' OR lower(void_reason) LIKE '%input%' THEN 'wrongOrder' "
                "WHEN lower(void_reason) LIKE '%ganti%' OR lower(void_reason) LIKE '%batal%' THEN 'customerChange' "
                "WHEN lower(void_reason) LIKE '%dapur%' OR lower(void_reason) LIKE '%gosong%' OR lower(void_reason) LIKE '%kualitas%' THEN 'kitchenError' "
                "WHEN lower(void_reason) LIKE '%comp%' OR lower(void_reason) LIKE '%gratis%' THEN 'comp' "
                "ELSE 'other' END WHERE void_reason_code IS NULL");
            await customStatement(
                "UPDATE table_session_tickets SET void_reason_code = CASE "
                "WHEN void_reason IS NULL THEN NULL "
                "WHEN lower(void_reason) LIKE '%stok%' OR lower(void_reason) LIKE '%habis%' THEN 'outOfStock' "
                "WHEN lower(void_reason) LIKE '%salah%' OR lower(void_reason) LIKE '%input%' THEN 'wrongOrder' "
                "WHEN lower(void_reason) LIKE '%ganti%' OR lower(void_reason) LIKE '%batal%' THEN 'customerChange' "
                "WHEN lower(void_reason) LIKE '%dapur%' OR lower(void_reason) LIKE '%gosong%' OR lower(void_reason) LIKE '%kualitas%' THEN 'kitchenError' "
                "WHEN lower(void_reason) LIKE '%comp%' OR lower(void_reason) LIKE '%gratis%' THEN 'comp' "
                "ELSE 'other' END WHERE void_reason_code IS NULL");
          }
          if (from < 15) {
            await _safeAddColumnOn('venue_settings', 'business_day_start_hour',
                type: 'INTEGER NOT NULL DEFAULT 4');
            await m.createTable(reservations);
          }
          if (from < 16) {
            await _safeAddColumnOn('venue_tables', 'guest_name', type: 'TEXT');
            await _safeAddColumnOn('venue_tables', 'guest_notes', type: 'TEXT');
            await _safeAddColumnOn(
                'venue_tables', 'reservation_id', type: 'TEXT');
          }
          if (from < 17) {
            // Wipe seeded reservations; reservations are now created entirely
            // via the UI flow.
            await customStatement('DELETE FROM reservations');
          }
          if (from < 18) {
            await _safeAddColumnOn('tickets', 'voided_by_user_id',
                type: 'TEXT');
            await _safeAddColumnOn(
                'table_session_tickets', 'voided_by_user_id', type: 'TEXT');
          }
          if (from < 19) {
            await _safeDropColumnOn('menu_items', 'station');
            await _safeDropColumnOn('tickets', 'station');
            await _safeDropColumnOn('table_session_tickets', 'station');
          }
          if (from < 20) {
            // Modifier groups become per-item private, embedded as JSON on the
            // item. Backfill from the now-removed shared ModifierGroups table,
            // resolving each item's id list, then drop the table + id column.
            // See docs/adr/0009-per-item-embedded-modifiers.md.
            await _safeAddColumnOn('menu_items', 'modifier_groups_json',
                type: "TEXT NOT NULL DEFAULT '[]'");
            await _backfillEmbeddedModifiers();
            await _safeDropColumnOn('menu_items', 'modifier_group_ids_json');
            await customStatement('DROP TABLE IF EXISTS modifier_groups');
          }
          if (from < 21) {
            // Rename auto_eighty_six_at_zero → auto_sold_out_at_zero
            // (add + copy + drop; DROP no-ops on pre-3.35 SQLite, leaving a
            // harmless dead column). See docs/adr/0010 + the "Habis" rename.
            await _safeAddColumnOn('menu_items', 'auto_sold_out_at_zero',
                type: 'INTEGER NOT NULL DEFAULT 0');
            final oldCols =
                await customSelect("PRAGMA table_info('menu_items')").get();
            if (oldCols.any(
                (r) => r.read<String>('name') == 'auto_eighty_six_at_zero')) {
              await customStatement('UPDATE menu_items '
                  'SET auto_sold_out_at_zero = auto_eighty_six_at_zero');
            }
            await _safeDropColumnOn('menu_items', 'auto_eighty_six_at_zero');
            // Capability rename: rewrite the stored string in every role.
            await customStatement(
                'UPDATE roles SET capabilities_json = '
                "replace(capabilities_json, '\"toggle86\"', '\"markSoldOut\"')");
            // Allergen / diet enums become data rows.
            await m.createTable(menuTags);
            await _seedMenuTags();
          }
          if (from < 22) {
            // Modifier snapshots become structured objects
            // ({groupId, optionId, label, priceDelta}) on both the live and
            // closed-session ticket tables. Rewrite any legacy bare-string
            // entries in place. See docs/adr/0011-ticket-modifier-snapshot.md.
            await _migrateModifierSnapshots('tickets');
            await _migrateModifierSnapshots('table_session_tickets');
          }
          if (from < 23) {
            // Ticket lifecycle timestamps for speed-of-service + a unified,
            // configurable service target. No backfill: pre-v23 rows never
            // captured ready/served events, so they stay NULL and drop out of
            // speed metrics. See docs/adr/0013.
            await _safeAddColumnOn('tickets', 'ready_at', type: 'INTEGER');
            await _safeAddColumnOn('tickets', 'served_at', type: 'INTEGER');
            await _safeAddColumnOn(
                'table_session_tickets', 'ready_at', type: 'INTEGER');
            await _safeAddColumnOn(
                'table_session_tickets', 'served_at', type: 'INTEGER');
            await _safeAddColumnOn('venue_settings', 'prep_target_mins',
                type: 'INTEGER NOT NULL DEFAULT 15');
          }
          if (from < 24) {
            // Item note column renamed special_instructions → note (single
            // canonical name across all layers). Add + copy + drop; DROP
            // no-ops on pre-3.35 SQLite, leaving a harmless dead column.
            // See CONTEXT.md "Guest note / Item note".
            await _safeAddColumnOn('tickets', 'note', type: 'TEXT');
            await _safeAddColumnOn('table_session_tickets', 'note',
                type: 'TEXT');
            await customStatement(
                'UPDATE tickets SET note = special_instructions '
                'WHERE special_instructions IS NOT NULL');
            await customStatement(
                'UPDATE table_session_tickets SET note = special_instructions '
                'WHERE special_instructions IS NOT NULL');
            await _safeDropColumnOn('tickets', 'special_instructions');
            await _safeDropColumnOn(
                'table_session_tickets', 'special_instructions');
          }
          if (from < 25) {
            // Menu item photos: JPEG blob + monotonic rev for cache-busting.
            // See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
            await _safeAddColumnOn('menu_items', 'photo', type: 'BLOB');
            await _safeAddColumnOn('menu_items', 'photo_rev',
                type: 'INTEGER NOT NULL DEFAULT 0');
          }
          if (from < 26) {
            // Firebase admin identity. Per-uid local user rows are
            // auto-provisioned on first Firebase sign-in (audit identity);
            // capabilities stay local. See ADR-0015.
            await _safeAddColumn('firebase_uid');
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_unique '
                'ON users(firebase_uid) WHERE firebase_uid IS NOT NULL');
          }
          if (from < 27) {
            // Demo seed is gone (ADR-0017): the server no longer auto-loads
            // sample data, admin is Firebase-only (no PIN admin), and the
            // generic restaurant set is now prompted. Wipe the old auto-seeded
            // demo content + fake report history from existing (pre-production)
            // installs so they start from the same clean state as fresh ones.
            // Preserves the shared admin role, Firebase-provisioned admin
            // users, venue settings, and menu-tag definitions.
            await customStatement('DELETE FROM table_session_courses');
            await customStatement('DELETE FROM table_session_tickets');
            await customStatement('DELETE FROM table_sessions');
            await customStatement('DELETE FROM tickets');
            await customStatement('DELETE FROM reservations');
            await customStatement('DELETE FROM venue_tables');
            await customStatement('DELETE FROM menu_items');
            await customStatement('DELETE FROM menu_categories');
            await customStatement('DELETE FROM zones');
            // Drop every PIN user (incl. the old PIN admin "Pak Nyoman");
            // Firebase-provisioned admins carry a firebase_uid and survive.
            await customStatement(
                'DELETE FROM users WHERE firebase_uid IS NULL');
            // Keep only the shared admin role; waiter/kitchen/manager demo
            // roles are removed (the generic seed re-creates waiter/kitchen).
            await customStatement(
                "DELETE FROM roles WHERE id != 'role-admin'");
          }
          if (from < 28) {
            // Two-phase settlement + split bills (ADR-0023). New live tables
            // for receipts/payments and their session snapshots; tax/service
            // amounts added to TableSessions (netTotal redefined — pre-v28
            // rows keep netTotal == subtotal, new columns default 0).
            await m.createTable(receipts);
            await m.createTable(receiptLines);
            await m.createTable(payments);
            await m.createTable(tableSessionReceipts);
            await m.createTable(tableSessionPayments);
            await _safeAddColumnOn('table_sessions', 'service_amount',
                type: 'INTEGER NOT NULL DEFAULT 0');
            await _safeAddColumnOn('table_sessions', 'tax_amount',
                type: 'INTEGER NOT NULL DEFAULT 0');
          }
          if (from < 29) {
            // Visit decoupled from table; bill-close (cashier) snapshots, not
            // table-close (waiter). New live Visits table; visitId on tickets/
            // receipts; current_visit_id on tables; loss/cashier on sessions.
            // Backfill one Visit per currently-occupied table and stamp its
            // live tickets/receipts. See ADR-0024.
            await m.createTable(visits);
            await _safeAddColumnOn('tickets', 'visit_id', type: 'TEXT');
            await _safeAddColumnOn('receipts', 'visit_id', type: 'TEXT');
            await _safeAddColumnOn('venue_tables', 'current_visit_id',
                type: 'TEXT');
            await _safeAddColumnOn('venue_tables', 'bill_closed_at',
                type: 'INTEGER');
            await _safeAddColumnOn('venue_tables', 'money_state',
                type: 'TEXT');
            await _safeAddColumnOn('table_sessions', 'loss_amount',
                type: 'INTEGER NOT NULL DEFAULT 0');
            await _safeAddColumnOn('table_sessions', 'bill_closed_by',
                type: 'TEXT');
            await _backfillVisits();
          }
          if (from < 30) {
            // Mandatory proof photo on non-cash payments (ADR-0025). Nullable
            // JPEG blob on live payments and their session snapshot; no backfill
            // (pre-feature payments stay photo-less).
            await _safeAddColumnOn('payments', 'photo', type: 'BLOB');
            await _safeAddColumnOn('table_session_payments', 'photo',
                type: 'BLOB');
          }
          if (from < 31) {
            // Table-less orders: takeaway visits (ADR-0026). A `kind` column on
            // live + snapshot visits (default dineIn leaves all existing rows
            // untouched) and a daily counter table for the takeaway pickup
            // number. No backfill.
            await _safeAddColumnOn('visits', 'kind',
                type: "TEXT NOT NULL DEFAULT 'dineIn'");
            await _safeAddColumnOn('table_sessions', 'kind',
                type: "TEXT NOT NULL DEFAULT 'dineIn'");
            await m.createTable(dailyCounters);
          }
          if (from < 32) {
            // Guest QR self-ordering (ADR-0027/0028). Venue master toggle +
            // per-table opt-in, both default off (no venue auto-exposed).
            await _safeAddColumnOn('venue_settings', 'guest_ordering_enabled',
                type: 'INTEGER NOT NULL DEFAULT 0');
            await _safeAddColumnOn('venue_tables', 'guest_ordering_enabled',
                type: 'INTEGER NOT NULL DEFAULT 0');
          }
        },
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
              'ON users(email) WHERE email IS NOT NULL');
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_unique '
              'ON users(firebase_uid) WHERE firebase_uid IS NOT NULL');
          await into(venueSettings).insertOnConflictUpdate(
            VenueSettingsCompanion.insert(
              id: 'default',
              displayName: const Value('Warung Sebelah'),
              legalName: const Value('PT Warung Sebelah Bali'),
              address: const Value(
                  'Jl. Pantai Berawa No. 17, Canggu, Bali 80361'),
              phone: const Value('+62 813 3700 2244'),
              receiptHeader: const Value('Warung Sebelah · Berawa'),
              receiptFooter:
                  const Value('Terima kasih · Sampai jumpa lagi'),
            ),
          );
          await _seedMenuTags();
        },
      );

  /// Default allergen / diet tags. Ids equal the legacy enum names so existing
  /// items' `allergens_json` / `dietary_json` refs stay valid with no item
  /// migration. INSERT OR IGNORE preserves any admin edits on re-run.
  Future<void> _seedMenuTags() async {
    const allergens = [
      ['gluten', 'Gluten', 'GL'],
      ['nut', 'Kacang', 'NU'],
      ['dairy', 'Susu', 'DA'],
      ['shellfish', 'Kerang', 'SH'],
      ['egg', 'Telur', 'EG'],
      ['soy', 'Kedelai', 'SO'],
      ['sesame', 'Wijen', 'SE'],
      ['sulfites', 'Sulfit', 'SU'],
    ];
    const diets = [
      ['vegetarian', 'Vegetarian', 'VG'],
      ['vegan', 'Vegan', 'VN'],
      ['glutenFree', 'Bebas gluten', 'GF'],
      ['dairyFree', 'Bebas susu', 'DF'],
      ['spicy', 'Pedas', 'PD'],
      ['halal', 'Halal', 'HL'],
      ['signature', 'Andalan', 'AD'],
    ];
    Future<void> ins(List<List<String>> rows, String kind) async {
      for (var i = 0; i < rows.length; i++) {
        await customStatement(
          'INSERT OR IGNORE INTO menu_tags(id, kind, name, code, sort_order) '
          'VALUES(?, ?, ?, ?, ?)',
          [rows[i][0], kind, rows[i][1], rows[i][2], i],
        );
      }
    }

    await ins(allergens, 'allergen');
    await ins(diets, 'diet');
  }

  Future<void> _safeAddColumn(String column, {String type = 'TEXT'}) =>
      _safeAddColumnOn('users', column, type: type);

  Future<void> _safeAddColumnOn(
    String table,
    String column, {
    String type = 'TEXT',
  }) async {
    final cols = await customSelect("PRAGMA table_info('$table')").get();
    final exists = cols.any((r) => r.read<String>('name') == column);
    if (exists) return;
    await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
  }

  /// Walk users with NULL avatar_color_hex and assign sequential palette
  /// colors. Recycles past the palette length so a venue with >12 staff
  /// still gets every row populated — duplicates are allowed per spec.
  Future<void> _backfillAvatarColors() async {
    final rows = await customSelect(
      'SELECT id FROM users WHERE avatar_color_hex IS NULL ORDER BY id',
    ).get();
    for (var i = 0; i < rows.length; i++) {
      final id = rows[i].read<String>('id');
      final c = avatarColorPalette[i % avatarColorPalette.length];
      await customStatement(
        'UPDATE users SET avatar_color_hex = ? WHERE id = ?',
        [c, id],
      );
    }
  }

  /// Backfill one [[Visit]] per currently-occupied table (ADR-0024). Mirrors
  /// the table's live session fields onto a new visit row, points the table at
  /// it via current_visit_id, and stamps that visit_id onto the table's live
  /// tickets + receipts so the bill keys off the visit going forward.
  Future<void> _backfillVisits() async {
    final rows = await customSelect(
      "SELECT id, label, zone_id, pax, opened_at, guest_name, guest_notes, "
      "reservation_id, last_actor_id FROM venue_tables "
      "WHERE status != 'available'",
    ).get();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    for (final r in rows) {
      final tableId = r.read<String>('id');
      final visitId = '$tableId-v0';
      await customStatement(
        'INSERT OR IGNORE INTO visits(id, table_id, table_label, zone_id, pax, '
        'opened_at, guest_name, guest_notes, reservation_id, last_actor_id, '
        'created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)',
        [
          visitId,
          tableId,
          r.read<String?>('label'),
          r.read<String?>('zone_id') ?? '',
          r.read<int?>('pax') ?? 0,
          r.read<int?>('opened_at'),
          r.read<String?>('guest_name'),
          r.read<String?>('guest_notes'),
          r.read<String?>('reservation_id'),
          r.read<String?>('last_actor_id'),
          now,
        ],
      );
      await customStatement(
        'UPDATE venue_tables SET current_visit_id = ? WHERE id = ?',
        [visitId, tableId],
      );
      await customStatement(
        'UPDATE tickets SET visit_id = ? WHERE table_id = ? AND visit_id IS NULL',
        [visitId, tableId],
      );
      await customStatement(
        'UPDATE receipts SET visit_id = ? WHERE table_id = ? AND visit_id IS NULL',
        [visitId, tableId],
      );
    }
  }

  /// Resolve each item's `modifier_group_ids_json` against the shared
  /// `modifier_groups` table and write the full groups into the new
  /// `modifier_groups_json` column. Tolerant of a missing old column/table
  /// (leaves the default '[]').
  Future<void> _backfillEmbeddedModifiers() async {
    final itemCols =
        await customSelect("PRAGMA table_info('menu_items')").get();
    final hasIds = itemCols
        .any((r) => r.read<String>('name') == 'modifier_group_ids_json');
    if (!hasIds) return;
    final groupRows = await customSelect(
            'SELECT id, name, required, multi, options_json FROM modifier_groups')
        .get();
    final groupsById = {
      for (final g in groupRows)
        g.read<String>('id'): {
          'id': g.read<String>('id'),
          'name': g.read<String>('name'),
          'required': g.read<bool>('required'),
          'multi': g.read<bool>('multi'),
          'options': jsonDecode(g.read<String>('options_json')),
        },
    };
    final items = await customSelect(
            'SELECT id, modifier_group_ids_json FROM menu_items')
        .get();
    for (final it in items) {
      final ids =
          (jsonDecode(it.read<String>('modifier_group_ids_json')) as List)
              .cast<String>();
      final embedded = [
        for (final id in ids)
          if (groupsById[id] != null) groupsById[id]!,
      ];
      await customStatement(
        'UPDATE menu_items SET modifier_groups_json = ? WHERE id = ?',
        [jsonEncode(embedded), it.read<String>('id')],
      );
    }
  }

  /// Rewrite legacy `modifiers_json` entries into the structured snapshot
  /// shape. A bare-string entry becomes `{groupId, optionId, label,
  /// priceDelta}`; a `"group:option"` string keeps its two parts. Entries
  /// already objects pass through untouched. Shallow — does not resolve
  /// bare ids against the (possibly edited) menu. See ADR-0011.
  Future<void> _migrateModifierSnapshots(String table) async {
    final rows =
        await customSelect('SELECT id, modifiers_json FROM $table').get();
    for (final r in rows) {
      final id = r.read<String>('id');
      List<dynamic> decoded;
      try {
        decoded = jsonDecode(r.read<String>('modifiers_json')) as List;
      } catch (_) {
        continue;
      }
      var changed = false;
      final out = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
          continue;
        }
        changed = true;
        final s = e.toString();
        final parts = s.split(':');
        out.add(parts.length == 2
            ? {
                'groupId': parts[0],
                'optionId': parts[1],
                'label': parts[1],
                'priceDelta': 0,
              }
            : {'groupId': '', 'optionId': '', 'label': s, 'priceDelta': 0});
      }
      if (changed) {
        await customStatement(
          'UPDATE $table SET modifiers_json = ? WHERE id = ?',
          [jsonEncode(out), id],
        );
      }
    }
  }

  Future<void> _safeDropColumn(String column) => _safeDropColumnOn('users', column);

  Future<void> _safeDropColumnOn(String table, String column) async {
    final cols = await customSelect(
      "PRAGMA table_info('$table')",
    ).get();
    final exists = cols.any((r) => r.read<String>('name') == column);
    if (!exists) return;
    // SQLite 3.35+ supports DROP COLUMN. Wrap in try so older runtimes
    // degrade to a no-op rather than blocking boot.
    try {
      await customStatement('ALTER TABLE $table DROP COLUMN $column');
    } catch (_) {}
  }

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'satset.sqlite'));
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
    );
    return AppDatabase(executor);
  }
}
