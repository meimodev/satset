// The four rules that make an opname a document rather than a burst of
// adjustments, each one a thing that was silently wrong before ADR-0096:
//
//   1. a bahan counted and found correct is recorded;
//   2. nothing moves until close;
//   3. a sale during the walk does not land in the variance;
//   4. closing twice does not double the movements.
//
// See docs/adr/0096-an-opname-is-a-document-not-a-burst-of-adjustments.md.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/stock.dart';
import 'package:satset/server/stock_counts.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: 'beras',
            name: 'Beras',
            unit: 'kg',
            stockOnHand: Value(StockUnit.kg.toBase(10)),
            costMicro: Value(costMicroFromUnitPrice(12000, StockUnit.kg)),
          ),
        );
    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: 'ayam',
            name: 'Ayam',
            unit: 'pcs',
            stockOnHand: Value(StockUnit.pcs.toBase(8)),
            costMicro: Value(costMicroFromUnitPrice(9000, StockUnit.pcs)),
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> onHand(String id) async =>
      (await (db.select(
        db.ingredients,
      )..where((i) => i.id.equals(id))).getSingle()).stockOnHand;

  Future<List<StockMovementRow>> movements() =>
      db.select(db.stockMovements).get();

  test('a bahan found correct is a line, not a movement', () async {
    final countId = await openCount(db);
    await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'beras',
      counted: StockUnit.kg.toBase(10), // exactly what was expected
    );
    final result = await db.transaction(
      () => closeCount(db, countId: countId),
    );

    // The count says somebody looked; the ledger says nothing moved.
    expect(result!.lines, 1);
    expect(result.movements, 0);
    expect(result.varianceValue, 0);
    expect(await countLines(db, countId), hasLength(1));
    expect(await movements(), isEmpty);
  });

  test('nothing moves until close, and the movement carries the count', () async {
    final countId = await openCount(db);
    await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'beras',
      counted: StockUnit.kg.toBase(9),
    );
    expect(await onHand('beras'), StockUnit.kg.toBase(10));
    expect(await movements(), isEmpty);

    await db.transaction(() => closeCount(db, countId: countId));

    expect(await onHand('beras'), StockUnit.kg.toBase(9));
    final rows = await movements();
    expect(rows, hasLength(1));
    expect(rows.single.reason, StockReason.adjust.name);
    expect(rows.single.countId, countId);
  });

  test('a sale during the walk does not land in the variance', () async {
    final countId = await openCount(db);
    // 14:02 — the counter finds 8 pcs of ayam, which is what the app expects.
    await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'ayam',
      counted: StockUnit.pcs.toBase(8),
    );

    // 14:20 — the kitchen sells three portions while the walk continues.
    await db.transaction(
      () => writeMovement(
        db,
        ingredientId: 'ayam',
        delta: -StockUnit.pcs.toBase(3),
        reason: StockReason.sale,
      ),
    );
    expect(await onHand('ayam'), StockUnit.pcs.toBase(5));

    // 14:40 — close. The expectation was frozen at entry, so the variance is
    // zero: the three portions are the sale's business, not the counter's.
    final result = await db.transaction(
      () => closeCount(db, countId: countId),
    );
    expect(result!.deltas['ayam'], 0);
    expect(result.varianceValue, 0);
    expect(await onHand('ayam'), StockUnit.pcs.toBase(5));
  });

  test('closing twice does not double the movements', () async {
    final countId = await openCount(db);
    await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'beras',
      counted: StockUnit.kg.toBase(7),
    );
    await db.transaction(() => closeCount(db, countId: countId));
    final second = await db.transaction(
      () => closeCount(db, countId: countId),
    );

    expect(second, isNull);
    expect(await movements(), hasLength(1));
    expect(await onHand('beras'), StockUnit.kg.toBase(7));

    // One audit row for the session, never one per line.
    final audits = await db.select(db.auditEntries).get();
    expect(audits, hasLength(1));
    expect(audits.single.kind, AuditKind.stockCountClosed.name);
  });

  test('re-entering a line keeps the first expectation', () async {
    final countId = await openCount(db);
    await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'beras',
      counted: StockUnit.kg.toBase(9),
    );
    // A sale moves the shelf, then the counter corrects their own typo.
    await db.transaction(
      () => writeMovement(
        db,
        ingredientId: 'beras',
        delta: -StockUnit.kg.toBase(2),
        reason: StockReason.sale,
      ),
    );
    final line = await recordCountLine(
      db,
      countId: countId,
      ingredientId: 'beras',
      counted: StockUnit.kg.toBase(8),
    );

    // One line, still measured against what the shelf claimed at 14:02.
    expect(await countLines(db, countId), hasLength(1));
    expect(line!.expectedQty, StockUnit.kg.toBase(10));
    expect(line.countedQty, StockUnit.kg.toBase(8));
  });

  test('two commits of one line at once do not collide', () async {
    // The Stok field commits on Enter and again on losing focus, so this is
    // the ordinary keyboard flow, not an exotic one. Unserialised, both calls
    // read no existing line and the second trips the unique index.
    final countId = await openCount(db);
    final both = await Future.wait([
      recordCountLine(
        db,
        countId: countId,
        ingredientId: 'beras',
        counted: StockUnit.kg.toBase(9),
      ),
      recordCountLine(
        db,
        countId: countId,
        ingredientId: 'beras',
        counted: StockUnit.kg.toBase(9),
      ),
    ]);

    expect(both.every((l) => l != null), isTrue);
    expect(await countLines(db, countId), hasLength(1));
  });
}
