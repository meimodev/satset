// Integrity of the seeded inventory dataset: recipe lines reference bahan and
// menu ids that actually exist, quantities are in a compatible unit, and the
// ledger sums to the balance. A typo in an option id produces a recipe that
// silently never resolves — this test is what fails instead.
//
// See docs/adr/0042-generic-seed-covers-inventory-and-recipes.md.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';
import 'package:satset/server/db/seed_inventory_data.dart';
import 'package:satset/server/stock.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedGenericRestaurant(db);
  });

  tearDown(() => db.close());

  test('every recipe line points at a seeded bahan', () async {
    final ids = {for (final i in await db.select(db.ingredients).get()) i.id};
    final lines = await db.select(db.recipeLines).get();
    expect(lines, isNotEmpty);
    for (final l in lines) {
      expect(
        ids,
        contains(l.ingredientId),
        reason:
            '${l.ownerKind}/${l.ownerId} references unknown bahan '
            '"${l.ingredientId}"',
      );
    }
  });

  test('recipe quantities are authored in a compatible unit', () {
    final unitOf = {for (final b in seedIngredients) b.id: b.unit};
    final all = <SeedQty>[
      for (final r in seedItemRecipes.values) ...[
        ...r.base,
        for (final v in r.byVariant.values) ...v,
        for (final o in r.byOption.values) ...o,
      ],
      for (final lines in seedIngredientRecipes.values) ...lines,
    ];
    for (final q in all) {
      final unit = unitOf[q.ingredientId];
      expect(unit, isNotNull, reason: 'unknown bahan "${q.ingredientId}"');
      expect(
        unit!.acceptsEntryIn(q.unit),
        isTrue,
        reason:
            '${q.ingredientId} is held in ${unit.label} but the recipe '
            'is written in ${q.unit.label}',
      );
      expect(
        q.base,
        greaterThan(0),
        reason: '${q.ingredientId} qty rounds to 0',
      );
    }
  });

  test('item recipes reference real items, variants and options', () async {
    final items = {
      for (final i in await db.select(db.menuItems).get()) i.id: i,
    };
    List<String> idsIn(String json, String key) => [
      for (final e in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
        if (key == 'variant')
          e['id'] as String
        else ...[
          for (final o
              in (e['options'] as List? ?? const [])
                  .cast<Map<String, dynamic>>())
            o['id'] as String,
        ],
    ];

    for (final entry in seedItemRecipes.entries) {
      final item = items[entry.key];
      expect(item, isNotNull, reason: 'recipe for unknown item "${entry.key}"');
      final variantIds = idsIn(item!.variantsJson, 'variant').toSet();
      final optionIds = idsIn(item.modifierGroupsJson, 'option').toSet();
      for (final v in entry.value.byVariant.keys) {
        expect(
          variantIds,
          contains(v),
          reason: '${entry.key} has no variant "$v"',
        );
      }
      for (final o in entry.value.byOption.keys) {
        expect(
          optionIds,
          contains(o),
          reason: '${entry.key} has no modifier option "$o"',
        );
      }
    }
  });

  test('produced bahan consume only non-produced bahan (one level)', () {
    final produced = {
      for (final b in seedIngredients)
        if (b.batchYield != null) b.id,
    };
    expect(produced, isNotEmpty);
    for (final e in seedIngredientRecipes.entries) {
      expect(
        produced,
        contains(e.key),
        reason: '${e.key} has a batch recipe but no batchYield',
      );
      for (final q in e.value) {
        expect(
          produced,
          isNot(contains(q.ingredientId)),
          reason: '${e.key} nests produced bahan "${q.ingredientId}"',
        );
      }
    }
  });

  test('the ledger sums to every balance', () async {
    final movements = await db.select(db.stockMovements).get();
    final summed = <String, int>{};
    for (final m in movements) {
      summed[m.ingredientId] = (summed[m.ingredientId] ?? 0) + m.delta;
    }
    for (final b in await db.select(db.ingredients).get()) {
      expect(
        summed[b.id] ?? 0,
        b.stockOnHand,
        reason: 'ledger and balance disagree for ${b.id}',
      );
    }
  });

  test(
    'the cocktails are deliberately recipe-less and never auto-habis',
    () async {
      final flags = await deriveStockFlags(db);
      for (final id in ['margarita', 'negroni', 'rose']) {
        expect(seedItemRecipes.containsKey(id), isFalse);
        expect(flags[id]?.autoSoldOut ?? false, isFalse);
      }
    },
  );

  test('one bahan opens below its reorder threshold, none at zero', () async {
    final rows = await db.select(db.ingredients).get();
    final low = [
      for (final b in rows)
        if (b.lowStockAt != null && b.stockOnHand <= b.lowStockAt!) b.id,
    ];
    expect(low, ['udang']);
    expect(rows.where((b) => b.stockOnHand <= 0), isEmpty);
  });

  test('re-seeding never rewrites stock a venue has moved', () async {
    await db.transaction(
      () => writeMovement(
        db,
        ingredientId: 'beras',
        delta: -StockUnit.kg.toBase(5),
        reason: StockReason.waste,
      ),
    );
    final after = await _onHand(db, 'beras');

    await seedGenericRestaurant(db);

    expect(await _onHand(db, 'beras'), after);
    final receives = (await db.select(db.stockMovements).get()).where(
      (m) => m.ingredientId == 'beras' && m.reason == 'receive',
    );
    expect(receives.length, 1, reason: 'opening stock received twice');
  });
}

Future<int> _onHand(AppDatabase db, String id) async {
  final row = await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(id))).getSingleOrNull();
  return row!.stockOnHand;
}
