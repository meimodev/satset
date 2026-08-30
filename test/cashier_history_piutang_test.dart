// A bill settled on a member's tab must be tellable apart from one settled in
// cash, on the screen where a cashier scans — through the real shelf route and
// an in-memory database.
//
// Every failure here is silent. A `piutang` payment discharges the receipt's
// claim (ADR-0098), so the bill closes Lunas and lands in history looking
// exactly like a cash bill; the money owed is only discovered weeks later in
// the ledger. The three things that can go quietly wrong:
//
//   1. the row carries no tab amount, so the card can draw no pill;
//   2. the filter runs over the loaded page rather than the window, so it says
//      "3 tabs" when it means "3 in the 60 rows I happen to hold" — the bug
//      ADR-0079 kept out of the Lunas count;
//   3. a refunded tab still reads as outstanding, because the reversing leg
//      (ADR-0121) was summed as another charge instead of against one.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
  });
  tearDown(() => db.close());

  Future<Map<String, dynamic>> history(Handler router, String query) async {
    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/settlement/history$query'),
        headers: caller.headers,
      ),
    );
    return (jsonDecode(await res.readAsString()) as Map)
        .cast<String, dynamic>();
  }

  final base = DateTime.now().toUtc().subtract(const Duration(days: 1));

  /// One closed session, `i` minutes into the window.
  Future<void> closed(String id, int i) => db
      .into(db.tableSessions)
      .insert(
        TableSessionsCompanion.insert(
          id: id,
          tableId: 't1',
          zoneId: 'z1',
          closedAt: base.add(Duration(minutes: i)),
        ),
      );

  /// A snapshotted payment leg. A refund rides the same list as a negative
  /// amount, which is what makes the net honest without a second column.
  Future<void> leg(
    String id,
    String sessionId,
    String method,
    int amount, {
    bool isRefund = false,
  }) => db
      .into(db.tableSessionPayments)
      .insert(
        TableSessionPaymentsCompanion.insert(
          id: id,
          sessionId: sessionId,
          receiptId: 'r-$id',
          method: method,
          amount: amount,
          at: base,
          isRefund: Value(isRefund),
        ),
      );

  Map<String, dynamic> rowOf(Map<String, dynamic> body, String id) =>
      (body['rows'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((r) => r['sessionId'] == id);

  test('a row states what went on the tab, and a cash bill states zero', () async {
    await closed('s-tab', 1);
    await leg('p1', 's-tab', 'piutang', 150000);
    await closed('s-cash', 2);
    await leg('p2', 's-cash', 'tunai', 90000);
    final router = settlementRoutes(db, WsHub(), caller.auth).call;

    final body = await history(router, '?days=7&limit=60');

    expect(rowOf(body, 's-tab')['piutangAmount'], 150000);
    expect(rowOf(body, 's-cash')['piutangAmount'], 0);
    // The window total the filter chip carries — both bills' tabs, not the page's.
    expect(body['piutangTotal'], 150000);
  });

  test('a part-cash part-tab bill reports only the tab half', () async {
    // ADR-0098: a bill splits across methods for free, and the pill must state
    // what is owed rather than what the bill was worth.
    await closed('s-split', 1);
    await leg('p1', 's-split', 'tunai', 60000);
    await leg('p2', 's-split', 'piutang', 40000);
    final router = settlementRoutes(db, WsHub(), caller.auth).call;

    final body = await history(router, '?days=7&limit=60');

    expect(rowOf(body, 's-split')['piutangAmount'], 40000);
  });

  test('a refunded tab is not outstanding', () async {
    // The refund of a `piutang` leg unwinds as a ledger reversal (ADR-0121).
    // Summed as another charge it would leave the card claiming a debt nobody
    // owes — and the venue chasing a guest who settled.
    await closed('s-reversed', 1);
    await leg('p1', 's-reversed', 'piutang', 80000);
    await leg('p2', 's-reversed', 'piutang', -80000, isRefund: true);
    final router = settlementRoutes(db, WsHub(), caller.auth).call;

    final all = await history(router, '?days=7&limit=60');
    expect(rowOf(all, 's-reversed')['piutangAmount'], 0);
    expect(all['piutangTotal'], 0);

    // And it is not in the filtered list either.
    final only = await history(router, '?days=7&limit=60&onAccount=1');
    expect((only['rows'] as List), isEmpty);
    expect(only['total'], 0);
  });

  test('the filter counts the window, not the loaded page', () async {
    // 80 cash bills bury 5 tabs past the first page. A client-side filter over
    // 60 loaded rows would find some of them and confidently report a total.
    for (var i = 0; i < 80; i++) {
      await closed('c$i', i);
      await leg('pc$i', 'c$i', 'tunai', 10000);
    }
    for (var i = 0; i < 5; i++) {
      await closed('t$i', 100 + i);
      await leg('pt$i', 't$i', 'piutang', 20000);
    }
    final router = settlementRoutes(db, WsHub(), caller.auth).call;

    final body = await history(router, '?days=7&limit=60&onAccount=1');

    expect((body['rows'] as List).length, 5);
    expect(body['total'], 5, reason: 'the count read the page, not the window');
    // Unfiltered, the same window still reports every one of the 85.
    final unfiltered = await history(router, '?days=7&limit=60');
    expect(unfiltered['total'], 85);
    // The chip's number does not move when the filter goes on.
    expect(body['piutangTotal'], 100000);
    expect(unfiltered['piutangTotal'], 100000);
  });
}
