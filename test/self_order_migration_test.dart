// The v56 [[Pesan mandiri]] migration (ADR-0105), driven through `onUpgrade`
// the way a real device drives it.
//
// This exists for the same reason `cashier_migration_test.dart` does, and it
// caught the same class of bug: the first cut created
// `idx_venue_tables_guest_code` *before* `ALTER TABLE venue_tables ADD COLUMN
// guest_code`, so a venue that had already traded died on
// `no such column: guest_code` while a fresh install sailed through `onCreate`.
// A schema change that only works on new installs is not a schema change.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Rewind the freshly-created (v56) schema to the v55 shape a device
  /// upgrading from main would actually present.
  Future<void> rewindToV55() async {
    for (final t in ['guest_order_lines', 'guest_orders', 'guest_sessions']) {
      await db.customStatement('DROP TABLE IF EXISTS $t');
    }
    await db.customStatement('DROP INDEX IF EXISTS idx_venue_tables_guest_code');
    await db.customStatement(
      'ALTER TABLE venue_tables DROP COLUMN guest_ordering_enabled',
    );
    await db.customStatement('ALTER TABLE venue_tables DROP COLUMN guest_code');
    for (final c in [
      'guest_visible',
      'guest_featured',
      'guest_stock_override',
      'guest_override_at',
    ]) {
      await db.customStatement('ALTER TABLE menu_items DROP COLUMN $c');
    }
    for (final c in [
      'guest_ordering_enabled',
      'guest_note_enabled',
      'guest_hours_start_min',
      'guest_hours_end_min',
      'guest_max_items',
      'guest_session_hours',
      'sound_guest_pending',
    ]) {
      await db.customStatement('ALTER TABLE venue_settings DROP COLUMN $c');
    }
  }

  Future<void> upgrade() => db.migration.onUpgrade(db.createMigrator(), 55, 56);

  Future<Set<String>> columnsOf(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return {for (final r in rows) r.data['name'] as String};
  }

  test('upgrading from 55 lands every guest column and table', () async {
    await rewindToV55();
    await upgrade();

    expect(
      await columnsOf('venue_tables'),
      containsAll(['guest_ordering_enabled', 'guest_code']),
    );
    expect(
      await columnsOf('menu_items'),
      containsAll([
        'guest_visible',
        'guest_featured',
        'guest_stock_override',
        'guest_override_at',
      ]),
    );
    expect(
      await columnsOf('venue_settings'),
      containsAll([
        'guest_ordering_enabled',
        'guest_note_enabled',
        'guest_hours_start_min',
        'guest_hours_end_min',
        'guest_max_items',
        'guest_session_hours',
        'sound_guest_pending',
      ]),
    );
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(
      {for (final r in tables) r.data['name'] as String},
      containsAll(['guest_sessions', 'guest_orders', 'guest_order_lines']),
    );
  });

  test('a venue that already has tables comes out with codes on all of them', () async {
    await rewindToV55();
    for (final id in ['t1', 't2', 't3']) {
      await db.customStatement(
        "INSERT INTO venue_tables (id, zone_id, label) VALUES (?, 'z1', ?)",
        [id, id.toUpperCase()],
      );
    }
    await upgrade();

    final rows = await db
        .customSelect('SELECT id, guest_code FROM venue_tables')
        .get();
    expect(rows, hasLength(3));
    final codes = {for (final r in rows) r.data['guest_code'] as String};
    expect(codes.every((c) => c.length == 8), isTrue);
    expect(codes, hasLength(3), reason: 'a code is unique per table');
  });

  test('the unique code index survives, and it is partial', () async {
    await rewindToV55();
    await upgrade();
    // Two blank codes must not collide — the index is `WHERE guest_code <> ''`
    // precisely so a table inserted before its mint does not break the insert.
    for (final id in ['a', 'b']) {
      await db.customStatement(
        "INSERT INTO venue_tables (id, zone_id, guest_code) VALUES (?, 'z1', '')",
        [id],
      );
    }
    final idx = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_venue_tables_guest_code'",
        )
        .get();
    expect(idx, hasLength(1));
  });

  test('the migration is re-runnable — a half-applied upgrade retries', () async {
    await rewindToV55();
    await upgrade();
    await upgrade();
    expect(await columnsOf('venue_tables'), contains('guest_code'));
  });
}
