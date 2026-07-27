// Deterministic proof of the inventory spine: recipe → deduction at send →
// partial rejection → void restock vs waste, through the *real* shelf routes
// and an in-memory database.
//
// See docs/adr/0040-ingredient-level-inventory-replaces-item-stock-counts.md
// and docs/adr/0041-stock-deducts-at-send-ledger-and-balance.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/ingredient.dart' show StockReason;
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:shelf/shelf.dart';

void main() {
  late AppDatabase db;
  late Handler router;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // auth omitted -> capability checks pass; WsHub broadcast no-ops.
    router = ticketsRoutes(db, WsHub()).call;
    stockFlags.invalidate();

    // Menu: Nasi Ayam, Reguler (1 portion of rice + 1 chicken) and Besar
    // (2 chicken — a variant recipe REPLACES the base, it does not scale it).
    await db
        .into(db.menuItems)
        .insert(
          MenuItemsCompanion.insert(
            id: 'i1',
            name: 'Nasi Ayam',
            categoryId: 'c1',
            basePrice: 25000,
            variantsJson: Value(
              jsonEncode([
                {'id': 'v-reg', 'name': 'Reguler', 'price': 25000},
                {'id': 'v-besar', 'name': 'Besar', 'price': 35000},
              ]),
            ),
          ),
        );
    await db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(
            id: 'beras',
            name: 'Beras',
            unit: 'kg',
            // 10 kg, in milligrams.
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
            stockOnHand: Value(StockUnit.pcs.toBase(2)),
          ),
        );
    await db.transaction(
      () => writeRecipes(db, 'i1', {
        'base': [
          {'ingredientId': 'beras', 'qty': StockUnit.g.toBase(200)},
          {'ingredientId': 'ayam', 'qty': StockUnit.pcs.toBase(1)},
        ],
        'byVariant': {
          'v-besar': [
            {'ingredientId': 'beras', 'qty': StockUnit.g.toBase(350)},
            {'ingredientId': 'ayam', 'qty': StockUnit.pcs.toBase(2)},
          ],
        },
        'byOption': {
          'opt-keju': [
            {'ingredientId': 'beras', 'qty': StockUnit.g.toBase(30)},
          ],
        },
      }),
    );
  });

  tearDown(() async => db.close());

  Future<Map<String, dynamic>> order(
    String idem,
    List<Map<String, dynamic>> lines,
  ) async {
    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/orders'),
        body: jsonEncode({
          'tableId': 't1',
          'idempotencyKey': idem,
          'actorId': null,
          'lines': [
            for (final l in lines)
              {'course': 'main', 'unitPrice': 25000, 'name': 'Nasi Ayam', ...l},
          ],
        }),
      ),
    );
    return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
  }

  Future<int> onHand(String id) async => (await (db.select(
    db.ingredients,
  )..where((i) => i.id.equals(id))).getSingle()).stockOnHand;

  test('milli-base units convert exactly and never drift', () {
    expect(StockUnit.kg.toBase(0.2), StockUnit.g.toBase(200));
    expect(StockUnit.l.toBase(1), StockUnit.ml.toBase(1000));
    // 1000 deductions of 0.2 kg must land exactly on 8 kg from 10 kg — the
    // whole reason quantities are integers rather than doubles.
    var stock = StockUnit.kg.toBase(10);
    for (var i = 0; i < 10; i++) {
      stock -= StockUnit.kg.toBase(0.2);
    }
    expect(stock, StockUnit.kg.toBase(8));
    // Count presets are labels, never inter-convertible.
    expect(StockUnit.butir.acceptsEntryIn(StockUnit.siung), isFalse);
    expect(StockUnit.kg.acceptsEntryIn(StockUnit.g), isTrue);
    expect(StockUnit.kg.acceptsEntryIn(StockUnit.ml), isFalse);
  });

  test('sending a line deducts its recipe at send', () async {
    final res = await order('idem-1', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    expect((res['ticketIds'] as List).length, 1);
    expect(await onHand('beras'), StockUnit.g.toBase(9800));
    expect(await onHand('ayam'), StockUnit.pcs.toBase(1));
  });

  test('a variant recipe replaces the base rather than scaling it', () async {
    await order('idem-2', [
      {'itemId': 'i1', 'variantName': 'Besar', 'qty': 1},
    ]);
    expect(await onHand('ayam'), 0);
    expect(await onHand('beras'), StockUnit.g.toBase(9650));
  });

  test('qty multiplies, and lines compete for the last portion', () async {
    // Two Reguler need 2 chicken; stock has exactly 2, so both fit.
    final res = await order('idem-3', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 2},
    ]);
    expect(res['rejected'], isNull);
    expect(await onHand('ayam'), 0);

    // A third line now has nothing left: rejected, and it names what ran out.
    final second = await order('idem-4', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    expect((second['ticketIds'] as List), isEmpty);
    final rejected = (second['rejected'] as List).cast<Map<String, dynamic>>();
    expect(rejected.single['ingredients'], ['Ayam']);
    // Rejection must not have touched stock.
    expect(await onHand('ayam'), 0);
  });

  test(
    'only the offending line is rejected; the rest of the order lands',
    () async {
      await order('idem-5', [
        {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 2},
      ]);
      // Now: no chicken. `i-free` has no recipe at all, so it consumes nothing
      // and must never be blocked — the default that lets a live venue migrate
      // one dish at a time.
      await db
          .into(db.menuItems)
          .insert(
            MenuItemsCompanion.insert(
              id: 'i-free',
              name: 'Es Teh',
              categoryId: 'c1',
              basePrice: 5000,
            ),
          );
      final res = await order('idem-6', [
        {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
        {'itemId': 'i-free', 'name': 'Es Teh', 'qty': 1},
      ]);
      expect((res['ticketIds'] as List).length, 1);
      expect((res['rejected'] as List).length, 1);
    },
  );

  test('modifier option recipes add on top of the resolved recipe', () async {
    await order('idem-7', [
      {
        'itemId': 'i1',
        'variantName': 'Reguler',
        'qty': 1,
        'modifiers': [
          {
            'groupId': 'g1',
            'optionId': 'opt-keju',
            'label': 'Keju',
            'priceDelta': 5000,
          },
        ],
      },
    ]);
    // 200 g base + 30 g from the option.
    expect(await onHand('beras'), StockUnit.g.toBase(9770));
  });

  test('void while still `sent` returns the stock', () async {
    final res = await order('idem-8', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    final id = (res['ticketIds'] as List).first as String;
    expect(await onHand('ayam'), StockUnit.pcs.toBase(1));

    await router(
      Request(
        'POST',
        Uri.parse('http://x/tickets/$id/transition'),
        body: jsonEncode({
          'status': 'voided',
          'voidReason': 'Tamu berubah pikiran',
          'voidReasonCode': 'customerChange',
        }),
      ),
    );

    expect(await onHand('ayam'), StockUnit.pcs.toBase(2));
    final reasons = await _reasons(db, id);
    expect(reasons, containsAll([StockReason.sale, StockReason.voidReturn]));
    expect(reasons, isNot(contains(StockReason.waste)));
  });

  test('void after the kitchen started books waste, not a return', () async {
    final res = await order('idem-9', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    final id = (res['ticketIds'] as List).first as String;
    await router(
      Request(
        'POST',
        Uri.parse('http://x/tickets/$id/transition'),
        body: jsonEncode({'status': 'prep'}),
      ),
    );
    await router(
      Request(
        'POST',
        Uri.parse('http://x/tickets/$id/transition'),
        body: jsonEncode({
          'status': 'voided',
          // A reason that WOULD have restocked under reason-code logic — the
          // point of testing status instead: the pan was already hit.
          'voidReason': 'Tamu berubah pikiran',
          'voidReasonCode': 'customerChange',
        }),
      ),
    );

    // Reversal + waste net to zero: the ingredients are genuinely gone.
    expect(await onHand('ayam'), StockUnit.pcs.toBase(1));
    expect(await _reasons(db, id), contains(StockReason.waste));
  });

  test('derived habis is per-variant, and clears when stock returns', () async {
    // Burn the chicken down to one.
    await order('idem-10', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    var flags = await deriveStockFlags(db);
    // Besar needs 2 chicken and cannot be made; Reguler still can, so the item
    // itself is NOT habis.
    expect(flags['i1']!.soldOutVariantIds, {'v-besar'});
    expect(flags['i1']!.autoSoldOut, isFalse);

    await order('idem-11', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    flags = await deriveStockFlags(db);
    expect(flags['i1']!.autoSoldOut, isTrue);

    // Receiving un-habises with no flag to clear — availability is derived.
    await db.transaction(
      () =>
          receiveStock(db, ingredientId: 'ayam', qty: StockUnit.pcs.toBase(5)),
    );
    flags = await deriveStockFlags(db);
    expect(flags['i1'], isNull);
  });

  test('flip detection stays silent while stock merely ticks down', () async {
    // A private cache: the /orders route consumes the global one as it goes.
    final cache = StockFlagCache();
    await cache.refreshAndDetectFlip(db);

    // 200 g off 10 kg of rice crosses no threshold — nobody can see it, so it
    // must not re-broadcast the menu to every device mid-service.
    await db.transaction(
      () => writeMovement(
        db,
        ingredientId: 'beras',
        delta: -StockUnit.g.toBase(200),
        reason: StockReason.sale,
      ),
    );
    expect(await cache.refreshAndDetectFlip(db), isFalse);

    // Taking a chicken makes Besar unmakeable — that IS visible, so it flips.
    await db.transaction(
      () => writeMovement(
        db,
        ingredientId: 'ayam',
        delta: -StockUnit.pcs.toBase(1),
        reason: StockReason.sale,
      ),
    );
    expect(await cache.refreshAndDetectFlip(db), isTrue);
    expect(
      await cache.refreshAndDetectFlip(db),
      isFalse,
      reason: 'no further change, so no re-broadcast',
    );
  });

  test(
    'receive blends the moving average; opname writes the variance',
    () async {
      // 10 kg @ 12000/kg, receiving 10 kg @ 16000/kg ⇒ 14000/kg.
      await db.transaction(
        () => receiveStock(
          db,
          ingredientId: 'beras',
          qty: StockUnit.kg.toBase(10),
          unitCostMicro: costMicroFromUnitPrice(16000, StockUnit.kg),
        ),
      );
      final row = await (db.select(
        db.ingredients,
      )..where((i) => i.id.equals('beras'))).getSingle();
      expect(unitPriceFromCostMicro(row.costMicro, StockUnit.kg), 14000);

      // Opname finds 19 kg where the app expected 20 — the adjust delta IS the
      // variance.
      final delta = await db.transaction(
        () => recordCount(
          db,
          ingredientId: 'beras',
          counted: StockUnit.kg.toBase(19),
        ),
      );
      expect(delta, StockUnit.kg.toBase(-1));
      expect(await onHand('beras'), StockUnit.kg.toBase(19));
    },
  );

  test(
    'produce deducts inputs, credits the yield, and prices the output',
    () async {
      await db
          .into(db.ingredients)
          .insert(
            IngredientsCompanion.insert(
              id: 'sambal',
              name: 'Sambal',
              unit: 'kg',
              batchYield: Value(StockUnit.kg.toBase(2)),
            ),
          );
      await db
          .into(db.ingredients)
          .insert(
            IngredientsCompanion.insert(
              id: 'cabai',
              name: 'Cabai',
              unit: 'kg',
              stockOnHand: Value(StockUnit.kg.toBase(5)),
              costMicro: Value(costMicroFromUnitPrice(40000, StockUnit.kg)),
            ),
          );
      await db.transaction(
        () => writeRecipes(db, 'sambal', {
          'base': [
            {'ingredientId': 'cabai', 'qty': StockUnit.kg.toBase(1)},
          ],
        }, ownerKind: 'ingredient'),
      );

      await db.transaction(
        () => produceBatch(db, ingredientId: 'sambal', batches: 1),
      );

      expect(await onHand('cabai'), StockUnit.kg.toBase(4));
      expect(await onHand('sambal'), StockUnit.kg.toBase(2));
      // 1 kg of chilli at 40000 yields 2 kg of sambal ⇒ 20000/kg.
      final sambal = await (db.select(
        db.ingredients,
      )..where((i) => i.id.equals('sambal'))).getSingle();
      expect(unitPriceFromCostMicro(sambal.costMicro, StockUnit.kg), 20000);
    },
  );

  test('a retried submit does not double-deduct', () async {
    await order('idem-same', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    final after = await onHand('ayam');
    await order('idem-same', [
      {'itemId': 'i1', 'variantName': 'Reguler', 'qty': 1},
    ]);
    expect(await onHand('ayam'), after);
  });
}

Future<Set<StockReason>> _reasons(AppDatabase db, String ticketId) async {
  final rows = await (db.select(
    db.stockMovements,
  )..where((m) => m.ticketId.equals(ticketId))).get();
  return {
    for (final r in rows)
      StockReason.values.firstWhere((v) => v.name == r.reason),
  };
}
