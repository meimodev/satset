// The cashier history page's two load-bearing promises, through the real shelf
// route and an in-memory database.
//
// Both failures are silent — no exception, just a wrong number on the money
// screen or a bill that quietly isn't in the list. The scroll trigger that
// grows the limit is deliberately not tested: it is plumbing you see working
// in ten seconds on the tablet, and a widget test for it is fixture cost for a
// bug nobody could miss.
//
// See docs/adr/0079-cashier-history-pages-by-growing-limit.md.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/data/models/bill_dto.dart'
    show historyPageCeiling, historyPageSize;
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<Map<String, dynamic>> history(Handler router, String query) async {
    final res = await router(
      Request('GET', Uri.parse('http://x/settlement/history$query')),
    );
    return (jsonDecode(await res.readAsString()) as Map).cast<String, dynamic>();
  }

  /// `count` closed sessions, one minute apart, newest last.
  Future<void> seedClosed(int count) async {
    final base = DateTime.now().toUtc().subtract(const Duration(days: 1));
    for (var i = 0; i < count; i++) {
      await db
          .into(db.tableSessions)
          .insert(
            TableSessionsCompanion.insert(
              id: 's${i.toString().padLeft(4, '0')}',
              tableId: 't1',
              zoneId: 'z1',
              closedAt: base.add(Duration(minutes: i)),
            ),
          );
    }
  }

  List<String> idsOf(Map<String, dynamic> body) => [
    for (final r in body['rows'] as List) r['sessionId'] as String,
  ];

  // ---------------------------------------------------------------------
  // 1. The count is the window, not the page.
  // ---------------------------------------------------------------------

  test('total counts the whole window while rows carry only a page', () async {
    // The exact failure ADR-0072 recorded for the audit log: derive the tile
    // from the rows you happen to have loaded and the Lunas chip reads "60" on
    // a venue that settled 200. Nothing throws; the number is just a lie.
    const closed = 200;
    await seedClosed(closed);
    final router = settlementRoutes(db, WsHub()).call;

    final body = await history(router, '?days=7&limit=$historyPageSize');

    expect(body['total'], closed, reason: 'total counted the page, not the window');
    expect((body['rows'] as List).length, historyPageSize);
  });

  // ---------------------------------------------------------------------
  // 2. A bigger limit is a superset — growing drops nothing.
  // ---------------------------------------------------------------------

  test('growing the limit keeps every row it already had, newest-first', () async {
    // Paging here is a refetch at a larger limit, not a cursor: page two is
    // "the newest 120" rather than "the 60 after the last one I saw". That is
    // only safe while the bigger fetch is a strict superset of the smaller,
    // ordered the same way — otherwise a bill visibly jumps or vanishes as the
    // cashier scrolls past the boundary.
    await seedClosed(150);
    final router = settlementRoutes(db, WsHub()).call;

    final first = idsOf(await history(router, '?days=7&limit=60'));
    final second = idsOf(await history(router, '?days=7&limit=120'));

    expect(first.length, 60);
    expect(second.length, 120);
    expect(
      second.take(60),
      first,
      reason: 'page two reordered or dropped rows page one had shown',
    );
    // Newest-first, so the freshest bill leads and the boundary is the oldest.
    expect(first.first, 's0149');
    expect(second.last, 's0030');
  });

  // ---------------------------------------------------------------------
  // 3. The ceiling holds.
  // ---------------------------------------------------------------------

  test('limit is clamped to the ceiling however much is asked for', () async {
    // Without this every `tableSession.closed` during a rush refetches whatever
    // the cashier last scrolled to, for the rest of the shift.
    await seedClosed(historyPageCeiling + 40);
    final router = settlementRoutes(db, WsHub()).call;

    final body = await history(router, '?days=7&limit=99999');

    expect((body['rows'] as List).length, historyPageCeiling);
    expect(body['total'], historyPageCeiling + 40);
  });
}
