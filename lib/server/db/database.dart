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
  ModifierGroups,
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
  int get schemaVersion => 15;

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
        },
      );

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

  Future<void> _safeDropColumn(String column) async {
    final cols = await customSelect(
      "PRAGMA table_info('users')",
    ).get();
    final exists = cols.any((r) => r.read<String>('name') == column);
    if (!exists) return;
    // SQLite 3.35+ supports DROP COLUMN. Wrap in try so older runtimes
    // degrade to a no-op rather than blocking boot.
    try {
      await customStatement('ALTER TABLE users DROP COLUMN $column');
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
