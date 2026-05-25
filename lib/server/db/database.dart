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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

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
        },
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
              'ON users(email) WHERE email IS NOT NULL');
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
