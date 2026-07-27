// The demo seed's load-bearing properties: the guard that keeps it off a
// trading venue, the tag that lets reset delete without truncating, and the
// ledger invariant that a month of fabricated service must not break.
//
// See docs/adr/0052-demo-seed-a-venue-mid-service.md.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/seed_demo.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  /// Σ movements == stockOnHand, for every bahan (ADR-0041).
  Future<void> expectLedgerBalances() async {
    final ingredients = await db.select(db.ingredients).get();
    expect(ingredients, isNotEmpty);
    for (final i in ingredients) {
      final rows = await (db.select(
        db.stockMovements,
      )..where((m) => m.ingredientId.equals(i.id))).get();
      final sum = rows.fold<int>(0, (a, m) => a + m.delta);
      expect(sum, i.stockOnHand, reason: 'ledger != balance for ${i.id}');
    }
  }

  test('refuses on a venue that has already traded', () async {
    await seedGenericRestaurant(db);
    final table = (await db.select(db.venueTables).get()).first;
    await db
        .into(db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: 'real-ticket',
            tableId: table.id,
            itemId: 'gado-gado',
            name: 'Gado-gado',
            course: 'mains',
            price: 50000,
            status: 'served',
            sentAt: DateTime.now(),
          ),
        );

    expect(await canSeedDemo(db), isFalse);
    await expectLater(
      seedDemoVenue(db),
      throwsA(isA<DemoSeedRefused>()),
    );
    // Refusal writes nothing.
    expect(await hasDemoData(db), isFalse);
  });

  test(
    'seeds a month of history plus a live snapshot, ledger intact',
    () async {
      await seedDemoVenue(db);

      final sessions = await db.select(db.tableSessions).get();
      expect(sessions, isNotEmpty, reason: 'no settled history');
      expect(
        sessions.every((s) => s.id.startsWith(demoPrefix)),
        isTrue,
        reason: 'history rows must carry the demo tag',
      );
      // History spans back a month, not just today.
      final oldest = sessions
          .map((s) => s.closedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      expect(
        DateTime.now().toUtc().difference(oldest).inDays,
        greaterThan(20),
        reason: 'history should span roughly a month',
      );
      // Money actually landed: settled totals are non-zero.
      expect(sessions.fold<int>(0, (a, s) => a + s.settledTotal), greaterThan(0));

      // Bills close during local trading hours. Authoring the service day in
      // UTC shifts every bill by the venue's offset and yields a restaurant
      // that trades overnight — invisible in a UTC test, obvious on a device.
      final closeHours = sessions.map((s) => s.closedAt.toLocal().hour);
      expect(
        closeHours.every((h) => h >= 11 && h <= 23),
        isTrue,
        reason: 'bills must close between 11:00 and 23:00 local',
      );

      // The live half exists and is tagged.
      final visits = await db.select(db.visits).get();
      expect(visits, isNotEmpty, reason: 'no live snapshot');
      expect(visits.every((v) => v.id.startsWith(demoPrefix)), isTrue);
      final tickets = await db.select(db.tickets).get();
      expect(tickets.every((t) => t.id.startsWith(demoPrefix)), isTrue);
      // Live states the UI needs: something ready, something voided.
      expect(tickets.any((t) => t.status == 'ready'), isTrue);
      expect(tickets.any((t) => t.status == 'voided'), isTrue);

      // Balances never went negative — `overrideStock` is ungranted by design,
      // so a venue that sells past zero is a broken dataset (ADR-0042 §7).
      final ingredients = await db.select(db.ingredients).get();
      expect(ingredients.every((i) => i.stockOnHand >= 0), isTrue);

      await expectLedgerBalances();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('reset removes every demo row and repairs balances', () async {
    await seedDemoVenue(db);
    expect(await hasDemoData(db), isTrue);

    await resetDemoVenue(db);

    expect(await hasDemoData(db), isFalse);
    expect(await db.select(db.tableSessions).get(), isEmpty);
    expect(await db.select(db.visits).get(), isEmpty);
    expect(await db.select(db.tickets).get(), isEmpty);
    expect(await db.select(db.reservations).get(), isEmpty);
    // The generically-seeded venue survives untouched.
    expect(await db.select(db.menuItems).get(), isNotEmpty);
    expect(
      (await db.select(db.venueTables).get()).any(
        (t) => !t.id.startsWith(demoPrefix),
      ),
      isTrue,
    );
    // Every surviving movement is the generic seed's opening receive — one
    // per bahan, nothing else. Asserting only that no *tagged* rows survive is
    // not enough: the production path mints its own ids, and an untagged
    // sale left behind deletes the purchases while keeping the consumption,
    // driving every balance deeply negative.
    final ingredients = await db.select(db.ingredients).get();
    final movements = await db.select(db.stockMovements).get();
    expect(movements.every((m) => !m.id.startsWith(demoPrefix)), isTrue);
    expect(
      movements.length,
      ingredients.length,
      reason: 'reset must leave exactly the opening receives',
    );
    expect(
      movements.every((m) => m.reason == 'receive'),
      isTrue,
      reason: 'no sale or purchase movement may survive reset',
    );
    expect(
      ingredients.every((i) => i.stockOnHand > 0),
      isTrue,
      reason: 'balances must return to their opening stock, never negative',
    );
    await expectLedgerBalances();

    // A clean venue can take the demo again.
    expect(await canSeedDemo(db), isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('reset restores authored availability, not blanket-available', () async {
    await seedGenericRestaurant(db);
    final authored = (await db.select(db.menuItems).get())
        .where((i) => i.unavailable)
        .map((i) => i.id)
        .toSet();

    await seedDemoVenue(db);
    await resetDemoVenue(db);

    final after = (await db.select(db.menuItems).get())
        .where((i) => i.unavailable)
        .map((i) => i.id)
        .toSet();
    expect(
      after,
      authored,
      reason: 'reset must not make deliberately-unavailable items orderable',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('archived history alone blocks the seed', () async {
    // A venue that traded and closed every bill has ZERO ticket rows — the
    // tickets were hard-deleted into TableSessions. A ticket-only guard would
    // let the demo bury real history.
    await seedGenericRestaurant(db);
    await db
        .into(db.tableSessions)
        .insert(
          TableSessionsCompanion.insert(
            id: 'real-session',
            tableId: 'D1',
            zoneId: 'indoor',
            closedAt: DateTime.now(),
          ),
        );
    expect(await db.select(db.tickets).get(), isEmpty);
    expect(await canSeedDemo(db), isFalse);
  });

  test('orders are organic, not uniform', () async {
    await seedDemoVenue(db);
    final lines = await db.select(db.tableSessionTickets).get();
    expect(lines.length, greaterThan(500));

    // Popularity spread: the top seller must clearly outsell the tail, or the
    // mix table is not being applied (ADR-0053 §6).
    final byItem = <String, int>{};
    for (final l in lines) {
      byItem[l.itemId] = (byItem[l.itemId] ?? 0) + 1;
    }
    final counts = byItem.values.toList()..sort();
    expect(
      counts.last / counts.first,
      greaterThan(4),
      reason: 'flat popularity means the weights are not applied',
    );

    // Arrival curve: the busiest hour must stand well clear of the quietest.
    final byHour = <int, int>{};
    for (final s in await db.select(db.tableSessions).get()) {
      final h = s.openedAt?.toLocal().hour;
      if (h != null) byHour[h] = (byHour[h] ?? 0) + 1;
    }
    final hours = byHour.values.toList()..sort();
    expect(
      hours.last / hours.first,
      greaterThan(3),
      reason: 'flat hourly curve is the clearest tell of fabricated data',
    );

    // Drinks attach to most covers; that is what makes a bill look real.
    final drinks = lines.where((l) => l.course == 'drinks-now').length;
    expect(drinks / lines.length, greaterThan(0.2));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('history is written through the production order path', () async {
    await seedDemoVenue(db);
    // The real path writes a movement per ticket. Direct inserts with a daily
    // roll-up would leave far fewer, and none carrying a ticket id.
    final moves = await db.select(db.stockMovements).get();
    final sales = moves.where((m) => m.reason == 'sale').toList();
    expect(sales, isNotEmpty);
    expect(
      sales.where((m) => m.ticketId != null).length / sales.length,
      greaterThan(0.9),
      reason: 'sale movements must be attributed to the ticket that caused them',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('seeding never drags the running app clock', () async {
    // Backdating a month by moving the global clock swings the live UI's
    // time and fires alerts against nonsense — the seed passes each order's
    // instant explicitly instead. Caught on device, not in tests.
    SatClock.clear();
    await seedDemoVenue(db);
    final drift = SatClock.now().difference(DateTime.now()).abs();
    expect(
      drift.inMinutes,
      lessThan(1),
      reason: 'seed must not leave the process clock shifted',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('the dataset is deterministic across runs', () async {
    await seedDemoVenue(db);
    final first = (await db.select(db.tableSessions).get())
        .fold<int>(0, (a, s) => a + s.settledTotal);

    final db2 = AppDatabase(NativeDatabase.memory());
    await seedDemoVenue(db2);
    final second = (await db2.select(db2.tableSessions).get())
        .fold<int>(0, (a, s) => a + s.settledTotal);
    await db2.close();

    expect(second, first, reason: 'fixed RNG seed must reproduce the dataset');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
