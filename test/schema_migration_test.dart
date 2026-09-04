// The migration harness. `database.dart` carries 60 hand-rolled `if (from <
// N)` branches and, until this file, four tests — each of which exercised a
// data-transform helper directly and none of which ran a migration.
//
// Three gates here:
//
//  1. `drift_schemas/` holds a dump per version. The verifier stands a
//     database up at the oldest one and migrates it forward, then compares
//     the result against what Dart declares — which is how the v63 repair in
//     `database.dart` was found in the first place. Bumping `schemaVersion`
//     means dumping the new version, or this test fails asking for it:
//
//       dart run drift_dev schema dump lib/server/db/database.dart drift_schemas/
//       dart run drift_dev schema generate drift_schemas/ test/generated/schema/
//
//  2. A fresh install matches the declared schema. `onCreate` is hand-written
//     — `createAll()` plus six index helpers — so an index added to a
//     migration branch and not to `onCreate` would leave new venues without
//     it, silently and forever.
//
//  3. The long upgrade path actually runs. A venue on v13 replaying every
//     branch up to the current version is the case nothing covered, and the three oldest
//     data transforms (v14, v20, v21) are asserted on real rows.
//
// See ADR-0104 for why the server DB is the source of truth in Server mode.
import 'dart:convert';

import 'package:drift/drift.dart' show Migrator, Value;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';

import 'generated/schema/schema.dart';

/// Columns that existed at v13 and were dropped somewhere on the way to v62.
/// A synthetic replay has to put them back: the branch that *reads* one runs
/// before the branch that drops it, so without these the chain dies on a
/// `no such column` that says nothing about any real venue.
const _droppedSinceV13 = <String>[
  'ALTER TABLE tickets ADD COLUMN special_instructions TEXT',
  'ALTER TABLE table_session_tickets ADD COLUMN special_instructions TEXT',
  'ALTER TABLE menu_items ADD COLUMN stock_count INTEGER',
];

void main() {
  /// A database carrying the current schema, created through `onCreate`.
  Future<AppDatabase> freshDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // force onCreate
    return db;
  }

  /// A [freshDb] with the v13-era columns restored, ready to replay the
  /// upgrade chain over.
  Future<AppDatabase> legacyDb() async {
    final db = await freshDb();
    for (final stmt in _droppedSinceV13) {
      await db.customStatement(stmt);
    }
    return db;
  }

  /// Replay the migration branches in `(from, to]`. Defaults to the whole
  /// remaining chain, which is what a real venue does.
  Future<void> replayFrom(AppDatabase db, int from, {int? to}) =>
      db.migration.onUpgrade(Migrator(db), from, to ?? db.schemaVersion);

  group('schema baseline', () {
    test('the v62 dump migrates to the current version and validates', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final connection = await verifier.startAt(62);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, db.schemaVersion);
    });

    test('a fresh install matches the declared schema', () async {
      final db = await freshDb();
      addTearDown(db.close);

      await db.validateDatabaseSchema();
    });
  });

  group('upgrade chain', () {
    test('a v13 venue reaches the current version', () async {
      final db = await legacyDb();
      addTearDown(db.close);

      await replayFrom(db, 13);

      // Every branch ran; the shape it left behind is the declared one.
      await db.validateDatabaseSchema();
    });
  });

  group('v14 — cost and void reasons', () {
    test('cost backfills at 35% of base price, and only where unset', () async {
      final db = await legacyDb();
      addTearDown(db.close);

      await db.into(db.menuItems).insert(
        MenuItemsCompanion.insert(
          id: 'nasi',
          name: 'Nasi Goreng',
          categoryId: 'mains',
          basePrice: 30000,
        ),
      );
      await db.into(db.menuItems).insert(
        MenuItemsCompanion.insert(
          id: 'kopi',
          name: 'Kopi Tubruk',
          categoryId: 'drinks',
          basePrice: 12000,
          cost: const Value(9000),
        ),
      );

      await replayFrom(db, 13, to: 14);

      final rows = {
        for (final r in await db.select(db.menuItems).get()) r.id: r.cost,
      };
      expect(rows['nasi'], 10500, reason: '30000 * 0.35');
      expect(rows['kopi'], 9000, reason: 'an explicit cost is left alone');
    });

    test('a free-text void reason becomes a code', () async {
      final db = await legacyDb();
      addTearDown(db.close);

      const reasons = {
        't1': 'Stok habis',
        't2': 'Salah input kasir',
        't3': 'Tamu ganti pesanan',
        't4': 'Gosong di dapur',
        't5': 'Digratiskan, comp manajer',
        't6': 'Sesuatu yang lain',
      };
      Future<void> ticket(String id, {String? reason}) => db
          .into(db.tickets)
          .insert(
            TicketsCompanion.insert(
              id: id,
              tableId: 't-1',
              itemId: 'i-1',
              name: 'Nasi Goreng',
              course: 'mains',
              price: 30000,
              status: reason == null ? 'sent' : 'void',
              sentAt: DateTime.now(),
              voidReason: Value(reason),
            ),
          );
      for (final e in reasons.entries) {
        await ticket(e.key, reason: e.value);
      }
      // A live ticket with no reason must stay NULL, not become 'other'.
      await ticket('t7');

      await replayFrom(db, 13, to: 14);

      final codes = {
        for (final r in await db
            .customSelect('SELECT id, void_reason_code FROM tickets')
            .get())
          r.read<String>('id'): r.read<String?>('void_reason_code'),
      };
      expect(codes['t1'], 'outOfStock');
      expect(codes['t2'], 'wrongOrder');
      expect(codes['t3'], 'customerChange');
      expect(codes['t4'], 'kitchenError');
      expect(codes['t5'], 'comp');
      expect(codes['t6'], 'other', reason: 'unknown reasons fall through');
      expect(codes['t7'], isNull, reason: 'no reason is not a reason');
    });
  });

  group('v20 — shared modifier groups become embedded', () {
    test('an item\'s id list resolves into the group objects', () async {
      final db = await legacyDb();
      addTearDown(db.close);

      // Stand the pre-v20 shape back up: a shared table plus an id list.
      await db.customStatement(
        'CREATE TABLE modifier_groups (id TEXT NOT NULL PRIMARY KEY, '
        'name TEXT NOT NULL, required INTEGER NOT NULL, '
        'multi INTEGER NOT NULL, options_json TEXT NOT NULL)',
      );
      await db.customStatement(
        "ALTER TABLE menu_items ADD COLUMN modifier_group_ids_json "
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await db.customStatement(
        'INSERT INTO modifier_groups (id, name, required, multi, options_json) '
        "VALUES ('g-spice', 'Level pedas', 1, 0, ?)",
        [
          jsonEncode([
            {'id': 'o-mild', 'name': 'Tidak pedas', 'priceDelta': 0},
            {'id': 'o-hot', 'name': 'Pedas', 'priceDelta': 2000},
          ]),
        ],
      );
      await db.into(db.menuItems).insert(
        MenuItemsCompanion.insert(
          id: 'nasi',
          name: 'Nasi Goreng',
          categoryId: 'mains',
          basePrice: 30000,
        ),
      );
      await db.customStatement(
        "UPDATE menu_items SET modifier_group_ids_json = ? WHERE id = 'nasi'",
        [
          jsonEncode(['g-spice', 'g-vanished']),
        ],
      );

      await replayFrom(db, 19, to: 20);

      final row = await (db.select(
        db.menuItems,
      )..where((t) => t.id.equals('nasi'))).getSingle();
      final groups = jsonDecode(row.modifierGroupsJson) as List;
      expect(
        groups,
        hasLength(1),
        reason: 'an id with no group behind it is dropped, not embedded null',
      );
      final g = groups.single as Map<String, dynamic>;
      expect(g['id'], 'g-spice');
      expect(g['name'], 'Level pedas');
      expect(g['required'], isTrue);
      expect(g['multi'], isFalse);
      expect((g['options'] as List), hasLength(2));

      // The shared table and the id column are gone.
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='modifier_groups'",
          )
          .get();
      expect(tables, isEmpty);
    });
  });

  group('v21 — the 86 rename', () {
    test('the flag column and the capability string both move', () async {
      final db = await legacyDb();
      addTearDown(db.close);

      await db.customStatement(
        'ALTER TABLE menu_items ADD COLUMN auto_eighty_six_at_zero '
        'INTEGER NOT NULL DEFAULT 0',
      );
      await db.into(db.menuItems).insert(
        MenuItemsCompanion.insert(
          id: 'nasi',
          name: 'Nasi Goreng',
          categoryId: 'mains',
          basePrice: 30000,
        ),
      );
      await db.customStatement(
        "UPDATE menu_items SET auto_eighty_six_at_zero = 1 WHERE id = 'nasi'",
      );
      await db.customStatement(
        'INSERT INTO roles (id, name, capabilities_json) VALUES (?, ?, ?)',
        [
          'role-waiter-legacy',
          'Pelayan',
          jsonEncode(['takeOrder', 'toggle86']),
        ],
      );

      await replayFrom(db, 20, to: 21);

      // Read raw: the column is dropped again at v36, when item-level stock
      // becomes ingredient-level (ADR-0040), so it has no Dart getter.
      final item = await db
          .customSelect(
            "SELECT auto_sold_out_at_zero AS f FROM menu_items WHERE id = 'nasi'",
          )
          .getSingle();
      expect(item.read<int>('f'), 1);

      final cols = await db.customSelect("PRAGMA table_info('menu_items')").get();
      expect(
        cols.map((r) => r.read<String>('name')),
        isNot(contains('auto_eighty_six_at_zero')),
      );

      final role = await (db.select(
        db.roles,
      )..where((t) => t.id.equals('role-waiter-legacy'))).getSingle();
      final caps = (jsonDecode(role.capabilitiesJson) as List).cast<String>();
      expect(caps, contains('markSoldOut'));
      expect(caps, isNot(contains('toggle86')));

      // The enum-to-rows half of the same branch.
      final tags = await db.select(db.menuTags).get();
      expect(tags, isNotEmpty, reason: 'menu tags are seeded by this branch');
    });
  });

  group('v73 — more than one tin', () {
    test('every pre-v73 movement and its audit line name Kas Utama', () async {
      final db = await freshDb();
      addTearDown(db.close);

      // A v72 venue has no boxes table. The ledger column is left in place —
      // SQLite cannot drop one, and a real v72 row reaches v73 through the
      // column's own default anyway, which is what the insert below pins.
      await db.customStatement('DROP TABLE cash_boxes');
      await db.customStatement(
        "INSERT INTO cash_entries (id, kind, delta, at) "
        "VALUES ('c-old', 'expense', -50000, 0)",
      );
      await db.customStatement(
        "INSERT INTO audit_entries (id, type, title, at, kind, params) "
        "VALUES ('a-old', 'cashMovement', 'Pengeluaran kas', 0, 'cashSpent', ?)",
        [jsonEncode({'amount': 'Rp. 50.000', 'category': 'ingredients'})],
      );
      // An unrelated row must not be touched: the backfill is scoped by type.
      await db.customStatement(
        "INSERT INTO audit_entries (id, type, title, at, kind, params) "
        "VALUES ('a-void', 'void', 'Batal', 0, 'voidItem', ?)",
        [jsonEncode({'name': 'Nasi Goreng'})],
      );

      await replayFrom(db, 72, to: 73);

      // The venue starts with exactly one box, and it is the one every row was
      // backfilled to.
      final boxes = await db.select(db.cashBoxes).get();
      expect(boxes.map((b) => b.id), ['box-main']);
      expect(boxes.single.name, 'Kas Utama');

      final entry = await db
          .customSelect("SELECT box_id FROM cash_entries WHERE id = 'c-old'")
          .getSingle();
      expect(entry.read<String>('box_id'), 'box-main');

      // The audit params are frozen JSON, so the backfill is the only thing
      // standing between an upgraded venue and a sentence with a hole in it.
      final audit = await db
          .customSelect("SELECT params FROM audit_entries WHERE id = 'a-old'")
          .getSingle();
      final params =
          (jsonDecode(audit.read<String>('params')) as Map).cast<String, dynamic>();
      expect(params['box'], 'Kas Utama');
      expect(params['amount'], 'Rp. 50.000', reason: 'nothing else moved');

      final other = await db
          .customSelect("SELECT params FROM audit_entries WHERE id = 'a-void'")
          .getSingle();
      expect(
        (jsonDecode(other.read<String>('params')) as Map).containsKey('box'),
        isFalse,
      );
    });
  });
}
