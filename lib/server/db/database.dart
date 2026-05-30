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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 24;

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
        },
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
              'ON users(email) WHERE email IS NOT NULL');
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
