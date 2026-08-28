// A bill discount holds one slot per **source** (ADR-0094): a cashier's promo,
// the member's standing discount and a points redemption are three different
// give-backs and stack by design. The rule that stops any one of them being
// applied twice is not route code — it is `idx_discounts_bill_source_uniq`, a
// partial unique index on `(visit_id, source) WHERE receipt_id IS NULL AND
// visit_id IS NOT NULL`.
//
// Nothing pinned it, and a partial index is exactly the kind that stops
// existing quietly: change the predicate and every route still passes, because
// the routes check first and rely on the index only for the race.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> disc({
    required String id,
    String? visitId,
    String? receiptId,
    String source = 'manual',
  }) => db
      .into(db.discounts)
      .insert(
        DiscountsCompanion.insert(
          id: id,
          visitId: Value(visitId),
          receiptId: Value(receiptId),
          source: Value(source),
          name: 'Diskon',
          kind: 'percent',
          at: DateTime(2026, 8, 22),
        ),
      );

  test('the three sources coexist on one bill', () async {
    await disc(id: 'd1', visitId: 'v1', source: 'manual');
    await disc(id: 'd2', visitId: 'v1', source: 'member');
    await disc(id: 'd3', visitId: 'v1', source: 'redeem');
    final rows = await (db.select(
      db.discounts,
    )..where((x) => x.visitId.equals('v1'))).get();
    expect(
      rows.length,
      3,
      reason: 'stacking is the point — one slot each, not one between them',
    );
  });

  test('a source cannot be applied twice to the same bill', () async {
    await disc(id: 'd1', visitId: 'v1', source: 'member');
    await expectLater(
      disc(id: 'd2', visitId: 'v1', source: 'member'),
      throwsA(isA<SqliteException>()),
      reason: 'the index is the guard; the route check only wins the race',
    );
  });

  test('the same source on another bill is a different slot', () async {
    await disc(id: 'd1', visitId: 'v1', source: 'manual');
    await disc(id: 'd2', visitId: 'v2', source: 'manual');
    expect((await db.select(db.discounts).get()).length, 2);
  });

  test('a receipt-scoped row is outside the index entirely', () async {
    // The predicate is `receipt_id IS NULL`. A receipt- or line-scope discount
    // has no such contest to settle, and several may share a visit.
    await disc(id: 'd1', visitId: 'v1', source: 'manual');
    await disc(id: 'd2', visitId: 'v1', receiptId: 'r1', source: 'manual');
    await disc(id: 'd3', visitId: 'v1', receiptId: 'r2', source: 'manual');
    expect((await db.select(db.discounts).get()).length, 3);
  });

  test('the pre-v51 one-per-visit index is gone', () async {
    // Leaving it would keep a member discount from ever coexisting with a
    // promo, which is the whole of ADR-0094 undone — and it would do it
    // silently, since both indexes raise the same constraint error.
    final names = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'discounts'",
        )
        .map((r) => r.read<String>('name'))
        .get();
    expect(names, contains('idx_discounts_bill_source_uniq'));
    expect(names, isNot(contains('idx_discounts_bill_uniq')));
  });
}
