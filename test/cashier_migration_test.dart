import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';

/// The v42 cashier migration (ADR-0066..0070), driven through `onUpgrade` the
/// way a real device drives it.
///
/// This exists because the first cut shipped a `TableMigration` without
/// `newColumns`, so the rebuild selected `visit_id` out of a table that did not
/// have it yet and the whole upgrade died on
/// `no such column: visit_id`. Nothing in the suite caught it: every other DB
/// test builds a fresh database through `onCreate`, which never runs a
/// migration at all. A schema change that only works on new installs is not a
/// schema change.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Rewind the freshly-created (v42) schema to the v41 shape a device
  /// upgrading from main would actually present.
  Future<void> rewindToV41() async {
    await db.customStatement('DROP TABLE discounts');
    await db.customStatement('''
      CREATE TABLE discounts (
        id TEXT NOT NULL PRIMARY KEY,
        receipt_id TEXT NOT NULL,
        ticket_id TEXT,
        preset_id TEXT,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        value INTEGER NOT NULL DEFAULT 0,
        amount INTEGER NOT NULL DEFAULT 0,
        by_user_id TEXT,
        approved_by_user_id TEXT,
        at INTEGER NOT NULL
      )
    ''');
    for (final t in ['visits', 'table_sessions']) {
      await db.customStatement('ALTER TABLE $t DROP COLUMN channel');
      await db.customStatement('ALTER TABLE $t DROP COLUMN prepaid');
    }
  }

  Future<void> upgrade() =>
      db.migration.onUpgrade!(db.createMigrator(), 41, 42);

  Future<Set<String>> columnsOf(String table) async {
    final rows = await db
        .customSelect('PRAGMA table_info($table)')
        .get();
    return {for (final r in rows) r.data['name'] as String};
  }

  test('upgrading from 41 adds the takeaway channel to both tables', () async {
    await rewindToV41();
    await upgrade();
    for (final t in ['visits', 'table_sessions']) {
      expect(await columnsOf(t), containsAll(['channel', 'prepaid']));
    }
  });

  test('the discounts rebuild adds visit_id and keeps existing rows', () async {
    await rewindToV41();
    // A receipt-scoped discount from before the upgrade. It must survive the
    // table rebuild — this is the one migration step that copies data rather
    // than just adding a column, so it is the one that can lose some.
    await db.customStatement(
      "INSERT INTO discounts (id, receipt_id, ticket_id, name, kind, value, "
      "amount, at) VALUES ('d1', 'r1', NULL, 'Diskon Member', 'percent', "
      "1000, 9300, 0)",
    );

    await upgrade();

    expect(await columnsOf('discounts'), contains('visit_id'));
    final rows = await db.customSelect('SELECT * FROM discounts').get();
    expect(rows, hasLength(1));
    expect(rows.single.data['id'], 'd1');
    expect(rows.single.data['receipt_id'], 'r1');
    expect(rows.single.data['amount'], 9300);
    // Every pre-existing row is receipt-scoped, so the new key is null.
    expect(rows.single.data['visit_id'], isNull);
  });

  test('receipt_id is nullable afterwards, so a bill discount can land', () async {
    await rewindToV41();
    await upgrade();
    // The whole point of the rebuild: a bill-scope discount belongs to the
    // visit and has no receipt (ADR-0070). Under the v41 NOT NULL this throws.
    await db.customStatement(
      "INSERT INTO discounts (id, receipt_id, visit_id, name, kind, value, "
      "amount, at) VALUES ('d2', NULL, 'v1', 'Diskon Meja', 'percent', 2000, "
      "20000, 0)",
    );
    final rows = await db
        .customSelect("SELECT * FROM discounts WHERE id = 'd2'")
        .get();
    expect(rows.single.data['visit_id'], 'v1');
    expect(rows.single.data['receipt_id'], isNull);
  });

  test('at most one bill discount per visit', () async {
    await rewindToV41();
    await upgrade();
    Future<void> insert(String id) => db.customStatement(
      "INSERT INTO discounts (id, receipt_id, visit_id, name, kind, value, "
      "amount, at) VALUES ('$id', NULL, 'v1', 'Diskon', 'percent', 1000, 0, 0)",
    );
    await insert('d1');
    // ADR-0037's no-stacking rule, enforced by the partial unique index rather
    // than by route code — so it holds even if a caller forgets to check.
    expect(insert('d2'), throwsA(anything));
  });

  test('the upgrade is idempotent', () async {
    await rewindToV41();
    await upgrade();
    // Devices retry a failed upgrade on the next launch, and `_safeAddColumnOn`
    // exists for exactly that. Running it twice must not throw.
    await upgrade();
    expect(await columnsOf('discounts'), contains('visit_id'));
  });
}
