// **Buang** — `wasteStock`, the deliberate-destruction writer: a spoiled jug of
// milk, a dropped plate, a tray of pastries nobody bought.
//
// It writes to two ledgers at once and nothing pinned either. What is being
// held here:
//
//   - the book is **not clamped at zero** (ADR-0041). Binning more than the
//     book says you held means the book was wrong, and a clamp hides that
//     forever — the negative balance *is* the finding;
//   - **one audit row per act, never per bahan**. Throwing away one portion of
//     a dish explodes into five movements and is still one thing the cook did,
//     so a five-ingredient bin must not put five rows in front of the owner;
//   - the row carries the **money destroyed**, valued at each bahan's own
//     moving-average cost, which is also what the call returns so the screen
//     can show it back;
//   - a zero or negative quantity and an unknown bahan are **skipped, not
//     errors** — a Buang sheet with an untouched row must still save the rows
//     that were touched.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/stock.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Susu: 2 litres on the book at Rp 20.000/l.
    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: 'susu',
            name: 'Susu',
            unit: 'l',
            stockOnHand: Value(StockUnit.l.toBase(2)),
            costMicro: Value(costMicroFromUnitPrice(20000, StockUnit.l)),
          ),
        );
    // Gula: 1 kg at Rp 15.000/kg.
    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: 'gula',
            name: 'Gula',
            unit: 'kg',
            stockOnHand: Value(StockUnit.kg.toBase(1)),
            costMicro: Value(costMicroFromUnitPrice(15000, StockUnit.kg)),
          ),
        );
  });

  tearDown(() async => db.close());

  Future<int> onHand(String id) async => (await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(id))).getSingle()).stockOnHand;

  Future<List<AuditEntry>> auditRows() => (db.select(
    db.auditEntries,
  )..where((a) => a.kind.equals(AuditKind.stockWasted.name))).get();

  Future<List<StockMovementRow>> movements() =>
      db.select(db.stockMovements).get();

  test('binning drops the book and returns what it cost', () async {
    final value = await wasteStock(
      db,
      qtyByIngredient: {'susu': StockUnit.l.toBase(1)},
      sourceLabel: 'Susu basi',
      userId: 'u1',
    );

    expect(await onHand('susu'), StockUnit.l.toBase(1));
    expect(value, 20000, reason: 'one litre at its moving-average cost');

    final moves = await movements();
    expect(moves, hasLength(1));
    expect(moves.single.delta, -StockUnit.l.toBase(1));
    expect(moves.single.reason, StockReason.waste.name);
  });

  test('the book is not clamped at zero — a negative is the finding', () async {
    // Three litres binned against two on the book: the extra litre is real, and
    // the book was wrong before anyone opened the sheet.
    await wasteStock(
      db,
      qtyByIngredient: {'susu': StockUnit.l.toBase(3)},
      sourceLabel: 'Kulkas mati',
      userId: 'u1',
    );

    expect(
      await onHand('susu'),
      -StockUnit.l.toBase(1),
      reason: 'clamping at zero would hide that the book was wrong',
    );
  });

  test('one act is one audit row, however many bahan it touched', () async {
    final value = await wasteStock(
      db,
      qtyByIngredient: {
        'susu': StockUnit.l.toBase(1),
        'gula': StockUnit.g.toBase(500),
      },
      sourceLabel: 'Adonan gagal',
      userId: 'u1',
      note: 'Tumpah',
    );

    expect(await movements(), hasLength(2), reason: 'a movement per bahan');

    final rows = await auditRows();
    expect(rows, hasLength(1), reason: 'but one row per act');
    expect(rows.single.reason, 'Tumpah');
    expect(
      rows.single.amountCents,
      value,
      reason: 'the row carries the money the act destroyed',
    );
    expect(value, 20000 + 7500, reason: 'each bahan at its own cost');
  });

  test('an untouched or unknown row is skipped, not an error', () async {
    final value = await wasteStock(
      db,
      qtyByIngredient: {
        'susu': StockUnit.l.toBase(1),
        'gula': 0,
        'garam': StockUnit.g.toBase(100),
      },
      sourceLabel: 'Susu basi',
      userId: 'u1',
    );

    expect(value, 20000, reason: 'only the litre of milk was destroyed');
    expect(await onHand('gula'), StockUnit.kg.toBase(1), reason: 'untouched');
    expect(
      await movements(),
      hasLength(1),
      reason: 'a zero qty and an unknown bahan write nothing',
    );
    expect(await auditRows(), hasLength(1), reason: 'the act still happened');
  });
}
