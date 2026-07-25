// The v36 migration runs one-way against shipped production data (v1.0.1), so
// its two data transforms are exercised directly here.
// See docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/stock.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<List<String>> capsOf(String roleId) async {
    final r = await (db.select(db.roles)..where((t) => t.id.equals(roleId)))
        .getSingle();
    return (jsonDecode(r.capabilitiesJson) as List).cast<String>();
  }

  test('legacy item stock counts become pcs ingredients with a 1-pcs recipe',
      () async {
    // v36 already dropped the columns from the schema, so stand the legacy
    // shape back up to migrate from.
    await db.customStatement('ALTER TABLE menu_items ADD COLUMN stock_count INTEGER');
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'cola',
          name: 'Coca-Cola',
          categoryId: 'drinks',
          basePrice: 15000,
          cost: const Value(9000),
        ));
    await db.into(db.menuItems).insert(MenuItemsCompanion.insert(
          id: 'nasi',
          name: 'Nasi Goreng',
          categoryId: 'mains',
          basePrice: 30000,
        ));
    await db.customStatement(
        "UPDATE menu_items SET stock_count = 24 WHERE id = 'cola'");

    await db.migrateItemStockCountsToIngredients();

    final ing = await (db.select(db.ingredients)
          ..where((i) => i.id.equals('ing_cola')))
        .getSingle();
    expect(ing.name, 'Coca-Cola');
    expect(ing.unit, 'pcs');
    expect(ing.stockOnHand, StockUnit.pcs.toBase(24));
    expect(unitPriceFromCostMicro(ing.costMicro, StockUnit.pcs), 9000);

    // The recipe makes one sale consume one bottle — behaviour preserved.
    final recipes = await loadRecipes(db);
    expect(recipes['cola']!.resolve(), {'ing_cola': StockUnit.pcs.toBase(1)});

    // An item that was never counted gets nothing, and so consumes nothing.
    expect(recipes['nasi'], isNull);

    // Re-running after a half-finished migration must not duplicate.
    await db.migrateItemStockCountsToIngredients();
    expect((await db.select(db.ingredients).get()).length, 1);
    expect((await db.select(db.recipeLines).get()).length, 1);
  });

  test('inventory capabilities backfill from the nearest existing authority',
      () async {
    Future<void> role(String id, List<Capability> caps) =>
        db.into(db.roles).insert(RolesCompanion.insert(
              id: id,
              name: id,
              capabilitiesJson:
                  Value(jsonEncode([for (final c in caps) c.name])),
            ));

    await role('manager', [Capability.adjustStock, Capability.markSoldOut]);
    await role('waiter', [Capability.takeOrder, Capability.markSoldOut]);
    await role('kitchen', [Capability.viewKds]);

    await db.backfillInventoryCapabilities();

    expect(await capsOf('manager'),
        containsAll(['manageIngredients', 'overrideStock']));
    // A waiter who could already flip habis keeps the valve open, but gains no
    // authority over the pantry itself.
    expect(await capsOf('waiter'), contains('overrideStock'));
    expect(await capsOf('waiter'), isNot(contains('manageIngredients')));
    // Nothing is granted to a role that held neither.
    expect(await capsOf('kitchen'), ['viewKds']);

    // Idempotent — a second pass must not double-grant.
    await db.backfillInventoryCapabilities();
    final manager = await capsOf('manager');
    expect(manager.where((c) => c == 'overrideStock').length, 1);
  });
}
