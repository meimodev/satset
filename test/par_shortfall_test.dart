// **Par + Belanja** — the shopping list is a *derivation*, never a stored list.
//
// A par is a target, not an order: nothing is remembered between builds, so the
// only thing that can be wrong is the arithmetic and the storage under it. Both
// are held here.
//
//   - `shortfall` is what the Belanja card lists and prices. Its two boundaries
//     are the ones a reader gets wrong: an ingredient **at** its par is not on
//     the list, and one **above** it contributes zero rather than a negative —
//     a signed gap would quietly net a well-stocked bahan against a short one
//     and under-buy the whole shop.
//   - a par with no value is **null, not zero**, and an edit that never mentions
//     it must leave it standing. The menu-admin editor posts a whole ingredient
//     on every save, so "absent means unchanged, explicit null means clear" is
//     the difference between keeping a target and silently dropping it.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/stock_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  Ingredient bahan({int? par, int onHand = 0}) => Ingredient(
    id: 'susu',
    name: 'Susu',
    unit: StockUnit.l,
    stockOnHand: StockUnit.l.toBase(onHand.toDouble()),
    parLevel: par == null ? null : StockUnit.l.toBase(par.toDouble()),
    costMicro: costMicroFromUnitPrice(20000, StockUnit.l),
  );

  group('shortfall — what to buy, and what not to', () {
    test('under par, the gap is what to buy', () {
      expect(bahan(par: 5, onHand: 2).shortfall, StockUnit.l.toBase(3.0));
    });

    test('at par, nothing is bought', () {
      expect(bahan(par: 5, onHand: 5).shortfall, 0);
    });

    test('over par contributes zero, never a negative', () {
      // A signed gap would net a well-stocked bahan against a short one and
      // under-buy the whole shop.
      expect(bahan(par: 5, onHand: 9).shortfall, 0);
    });

    test('no par is not a par of zero — it is off the list', () {
      expect(bahan(onHand: 0).shortfall, 0);
    });

    test('the list prices the gap, not the shelf', () {
      final i = bahan(par: 5, onHand: 2);
      expect(valueOf(i.shortfall, i.costMicro), 60000);
      expect(i.stockValue, 40000, reason: 'what is held is a different sum');
    });
  });

  group('a par survives the edit that does not mention it', () {
    late AppDatabase db;
    late Handler router;
    late TestCaller caller;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      caller = await signInForTest(db);
      router = stockRoutes(db, WsHub(), caller.auth).call;
    });

    tearDown(() => db.close());

    Future<Response> save(Map<String, dynamic> body) async => router(
      Request(
        'POST',
        Uri.parse('http://x/stock/ingredients'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode({'id': 'susu', 'name': 'Susu', 'unit': 'l', ...body}),
      ),
    );

    Future<int?> storedPar() async => (await (db.select(
      db.ingredients,
    )..where((i) => i.id.equals('susu'))).getSingle()).parLevel;

    test('a fresh bahan has no par at all', () async {
      expect((await save(const {})).statusCode, 200);
      expect(await storedPar(), isNull);
    });

    test('a par is stored in base units and read back', () async {
      await save({'parLevel': StockUnit.l.toBase(5.0)});
      expect(await storedPar(), StockUnit.l.toBase(5.0));
    });

    test('an edit that never mentions it leaves it standing', () async {
      await save({'parLevel': StockUnit.l.toBase(5.0)});
      await save(const {'lowStockAt': 1000});
      expect(
        await storedPar(),
        StockUnit.l.toBase(5.0),
        reason: 'absent is unchanged, or every save drops the target',
      );
    });

    test('an explicit null is how a par is cleared', () async {
      await save({'parLevel': StockUnit.l.toBase(5.0)});
      await save(const {'parLevel': null});
      expect(await storedPar(), isNull);
    });
  });
}
