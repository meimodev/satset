// **Item bebas** — the two places an off-menu line must *not* turn up.
//
// `test/open_item_test.dart` holds the writing side: who may sell one, that a
// price needs a reason, and that it reaches the KDS and the audit log. This
// file holds the reading side, which is all exclusions — and an exclusion is
// the kind of line a refactor drops without a single test going red.
//
//   - **the guest plane.** A guest may not name their own price, so an open
//     item can never be ordered from a phone. The lookup happens to refuse it
//     already (no `menu_items` row carries the reserved id), which is exactly
//     why the explicit guard matters: the day someone inserts such a row for
//     any reason, the accident stops protecting us.
//   - **menu engineering.** Every off-menu line in the venue's history shares
//     one reserved id, so ranking them as an item invents a dish: one pile of
//     revenue with no menu row behind it, therefore no cost, therefore a 100%
//     margin, sitting at the top of the star list. Sales still counts the
//     money — the exclusion is about the ranking, not about the revenue.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/menu_item.dart' show openItemId;
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reports_routes.dart';
import 'package:satset/server/self_order.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            guestOrderingEnabled: const Value(true),
          ),
        );
  });

  tearDown(() => db.close());

  group('the guest plane', () {
    setUp(() async {
      await db
          .into(db.venueTables)
          .insertOnConflictUpdate(
            VenueTablesCompanion.insert(
              id: 't1',
              zoneId: 'z1',
              guestCode: const Value('CODE0001'),
            ),
          );
    });

    test('a guest may not order an item bebas, row or no row', () async {
      // The reserved id planted as a real, guest-visible menu row: the id
      // lookup no longer refuses it, and only the explicit guard is left.
      await db
          .into(db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: openItemId,
              name: 'Item bebas',
              categoryId: 'mains',
              basePrice: 1000,
              guestVisible: const Value(true),
            ),
          );

      final session = await openGuestSession(db, tableId: 't1', ttlHours: 4);
      expect(
        () => submitGuestOrder(
          db,
          session: session,
          tableId: 't1',
          lines: [
            {'itemId': openItemId, 'qty': 1},
          ],
        ),
        throwsA(
          isA<SelfOrderException>().having(
            (e) => e.code,
            'code',
            'item_unavailable',
          ),
        ),
      );
    });
  });

  group('menu engineering', () {
    /// One closed bill in today's window holding an ordinary line and an
    /// off-menu one.
    Future<void> tradeToday() async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: 'kopi',
              name: 'Kopi Susu',
              categoryId: 'drinks',
              basePrice: 20000,
              cost: const Value(8000),
            ),
          );
      await db
          .into(db.tableSessions)
          .insert(
            TableSessionsCompanion.insert(
              id: 's1',
              tableId: 't1',
              zoneId: 'z1',
              openedAt: Value(now.subtract(const Duration(hours: 1))),
              closedAt: now,
              pax: const Value(2),
              subtotal: const Value(70000),
              settledTotal: const Value(70000),
            ),
          );
      var n = 0;
      Future<void> line(String itemId, String name, int price) => db
          .into(db.tableSessionTickets)
          .insert(
            TableSessionTicketsCompanion.insert(
              id: 'tst-${n++}',
              sessionId: 's1',
              ticketId: 'tk-$n',
              itemId: itemId,
              name: name,
              course: 'mains',
              price: price,
              status: 'served',
              sentAt: now.subtract(const Duration(minutes: 30)),
            ),
          );
      await line('kopi', 'Kopi Susu', 20000);
      // The dear one, so it would head the ranking if it were ranked at all.
      await line(openItemId, 'Tumpeng ulang tahun', 50000);
    }

    Future<Map<String, dynamic>> snapshot() async {
      final caller = await signInForTest(db);
      final res = await reportsRoutes(db, caller.auth).call(
        Request(
          'GET',
          Uri.parse('http://x/reports/snapshot?range=today'),
          headers: caller.headers,
        ),
      );
      expect(res.statusCode, 200);
      return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    }

    test('an off-menu line is money, not a dish', () async {
      await tradeToday();
      final body = await snapshot();
      final top = ((body['menu'] as Map)['top'] as List).cast<Map>();

      expect(
        top.map((r) => r['itemId']),
        isNot(contains(openItemId)),
        reason: 'one reserved id is every off-menu line ever sold',
      );
      expect(
        top.map((r) => r['itemId']),
        contains('kopi'),
        reason: 'the ordinary line is ranked as usual',
      );
      // Both lines are still revenue — the bill is what Sales reads, and it
      // does not care which lines had a menu row behind them.
      final net = ((body['sales'] as Map)['kpis'] as List)
          .cast<Map>()
          .firstWhere((k) => k['key'] == 'net');
      expect(net['rupiah'], 70000);
    });

    test('and it does not sit at the top of the slow list either', () async {
      await tradeToday();
      final body = await snapshot();
      final slow = ((body['menu'] as Map)['slow'] as List).cast<Map>();
      expect(slow.map((r) => r['itemId']), isNot(contains(openItemId)));
    });
  });
}
