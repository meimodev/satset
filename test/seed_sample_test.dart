// The sample seed's load-bearing properties: the guard that keeps it off a
// trading venue, the tag that lets the clear delete without truncating, the
// audit trail that makes the log readable, and the ledger invariant that a
// month of fabricated service must not break.
//
// See docs/adr/0073-the-generic-seed-fabricates-a-month.md.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';
import 'package:satset/server/db/seed_data.dart';
import 'package:satset/server/db/seed_history.dart';
import 'package:satset/server/shift.dart';

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

  test('the reference half seeds four zones and twenty tables', () async {
    await seedGenericRestaurant(db);
    expect((await db.select(db.zones).get()).length, 4);
    expect((await db.select(db.venueTables).get()).length, 20);
    // Enough menu that a report's item mix has a tail worth reading.
    expect((await db.select(db.menuItems).get()).length, greaterThan(35));
    // Reference-only: seeding the menu must not fabricate a single bill.
    expect(await db.select(db.tableSessions).get(), isEmpty);
    expect(await db.select(db.auditEntries).get(), isEmpty);
  });

  test('the reference half seeds two waiters and two kitchen', () async {
    await seedGenericRestaurant(db);
    final users = await db.select(db.users).get();
    expect(users.length, 4);
    expect(
      users.where((u) => u.roleId == DummyData.roleWaiterId).length,
      2,
      reason: 'one waiter makes every report column read the same name',
    );
    expect(users.where((u) => u.roleId == DummyData.roleKitchenId).length, 2);
    expect(users.map((u) => u.name).toSet(), {
      'Pelayan 1',
      'Pelayan 2',
      'Dapur 1',
      'Dapur 2',
    });
  });

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

    expect(await canSeedSample(db), isFalse);
    await expectLater(seedSampleVenue(db), throwsA(isA<SampleSeedRefused>()));
    // Refusal writes nothing.
    expect(await hasSampleData(db), isFalse);
  });

  test('archived history alone blocks the seed', () async {
    // A venue that traded and closed every bill has ZERO ticket rows — the
    // tickets were hard-deleted into TableSessions. A ticket-only guard would
    // let the sample month bury real history.
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
    expect(await canSeedSample(db), isFalse);
  });

  test(
    'seeds a month of settled history, ledger intact',
    () async {
      await seedSampleVenue(db);

      final sessions = await db.select(db.tableSessions).get();
      expect(sessions, isNotEmpty, reason: 'no settled history');
      expect(
        sessions.every((s) => s.id.startsWith(samplePrefix)),
        isTrue,
        reason: 'history rows must carry the sample tag',
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
      expect(
        sessions.fold<int>(0, (a, s) => a + s.settledTotal),
        greaterThan(0),
      );

      // Bills close during local trading hours. Authoring the service day in
      // UTC shifts every bill by the venue's offset and yields a restaurant
      // that trades overnight — invisible in a UTC test, obvious on a device.
      final closeHours = sessions.map((s) => s.closedAt.toLocal().hour);
      expect(
        closeHours.every((h) => h >= 11 && h <= 23),
        isTrue,
        reason: 'bills must close between 11:00 and 23:00 local',
      );

      // History-only (ADR-0073): nothing is left open on the floor.
      expect(await db.select(db.visits).get(), isEmpty);
      expect(await db.select(db.tickets).get(), isEmpty);
      final tables = await db.select(db.venueTables).get();
      expect(
        tables.every((t) => t.status == 'available'),
        isTrue,
        reason: 'a history-only seed must leave every table kosong',
      );

      // Balances never went negative — `overrideStock` is ungranted by design,
      // so a venue that sells past zero is a broken dataset (ADR-0042 §7).
      final ingredients = await db.select(db.ingredients).get();
      expect(ingredients.every((i) => i.stockOnHand >= 0), isTrue);

      await expectLedgerBalances();
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'the audit log gets both halves, and every row is tagged',
    () async {
      await seedSampleVenue(db);
      final rows = await db.select(db.auditEntries).get();
      expect(rows, isNotEmpty);
      // Tagged, or the clear silently strands them: `writeAudit` mints a uuid,
      // so without the idPrefix override none of these would be deletable.
      expect(
        rows.every((a) => a.id.startsWith(samplePrefix)),
        isTrue,
        reason: 'audit rows must carry the sample tag',
      );

      final types = rows.map((a) => a.type).toSet();
      // Service half — none of this comes free, the seed bypasses every route.
      for (final t in const ['fire', 'billClosed', 'paymentRecorded']) {
        expect(types, contains(t), reason: 'missing service audit type $t');
      }
      // Admin half — the rows ADR-0072 gates behind manageStaff. A gate with
      // nothing behind it cannot be seen to work.
      expect(
        types.any((t) => isAdminAuditType(AuditType.values.byName(t))),
        isTrue,
        reason: 'the manageStaff-gated half of the log must be non-empty',
      );

      // Attribution is snapshotted at write, not joined at read.
      expect(rows.where((a) => a.actorName != null), isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'clear removes the fabricated month and leaves the menu standing',
    () async {
      await seedSampleVenue(db);
      expect(await hasSampleData(db), isTrue);

      await clearSampleData(db);

      expect(await hasSampleData(db), isFalse);
      expect(await db.select(db.tableSessions).get(), isEmpty);
      expect(await db.select(db.visits).get(), isEmpty);
      expect(await db.select(db.tickets).get(), isEmpty);
      expect(await db.select(db.auditEntries).get(), isEmpty);
      expect(await db.select(db.receipts).get(), isEmpty);

      // The reference half survives untouched — that is the whole point of a
      // transactional-only clear (ADR-0073).
      expect(await db.select(db.menuItems).get(), isNotEmpty);
      expect((await db.select(db.zones).get()).length, 4);
      expect((await db.select(db.venueTables).get()).length, 20);
      expect(await db.select(db.users).get(), isNotEmpty);

      // Every surviving movement is the reference seed's opening receive — one
      // per bahan, nothing else. Asserting only that no *tagged* rows survive
      // is not enough: an untagged sale left behind deletes the purchases while
      // keeping the consumption, driving every balance deeply negative.
      final ingredients = await db.select(db.ingredients).get();
      final movements = await db.select(db.stockMovements).get();
      expect(
        movements.length,
        ingredients.length,
        reason: 'clear must leave exactly the opening receives',
      );
      expect(
        movements.every((m) => m.reason == 'receive'),
        isTrue,
        reason: 'no sale or purchase movement may survive the clear',
      );
      expect(
        ingredients.every((i) => i.stockOnHand > 0),
        isTrue,
        reason: 'balances must return to their opening stock, never negative',
      );
      await expectLedgerBalances();

      // A cleared venue can take the sample data again.
      expect(await canSeedSample(db), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'the fabricated month comes with a fabricated attendance shape',
    () async {
      // A hours report that opens empty teaches nobody what "unclosed" means
      // (ADR-0097), so the seed writes shifts through `openShift`/`endShift`
      // with deliberate variance: different totals per person, at least one
      // split day, and at least one forgotten sign-out.
      await seedSampleVenue(db);
      final shifts = await db.select(db.shifts).get();
      expect(shifts, isNotEmpty);

      final byUser = <String, List<Shift>>{};
      for (final s in shifts) {
        (byUser[s.userId] ??= []).add(s);
      }
      expect(
        byUser.length,
        greaterThan(1),
        reason: 'one staff member makes every column read the same',
      );
      expect(
        byUser.values.map((v) => v.length).toSet().length,
        greaterThan(1),
        reason: 'identical shift counts are not an attendance shape',
      );

      // A day someone signed in twice — the gap the report exists to show.
      final days = <String, int>{};
      for (final s in shifts) {
        final d = '${s.userId}|${s.startedAt.year}-${s.startedAt.month}-${s.startedAt.day}';
        days[d] = (days[d] ?? 0) + 1;
      }
      expect(days.values.any((n) => n > 1), isTrue, reason: 'no split day seeded');

      // A forgotten sign-out, retired by the next day's rollover, not invented.
      expect(
        shifts.any((s) => s.endedBy == ShiftEnd.rollover.name),
        isTrue,
        reason: 'the flag needs to have been seen once before it appears for real',
      );
      expect(
        shifts.every((s) => s.endedAt == null || !s.endedAt!.isBefore(s.startedAt)),
        isTrue,
      );

      // Attendance is transactional: it goes with the month it belongs to.
      await clearSampleData(db);
      expect(await db.select(db.shifts).get(), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'a real order written after seeding survives the clear',
    () async {
      // The tag is what separates "invented" from "real". A clear that deleted
      // by table would take the venue's own first order with it.
      await seedSampleVenue(db);
      await db
          .into(db.auditEntries)
          .insert(
            AuditEntriesCompanion.insert(
              id: 'real-audit-row',
              type: 'fire',
              title: 'Course Utama dibakar untuk Meja D1',
              at: DateTime.now(),
            ),
          );

      await clearSampleData(db);

      final survivors = await db.select(db.auditEntries).get();
      expect(survivors.map((a) => a.id), contains('real-audit-row'));
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'orders are organic, not uniform',
    () async {
      await seedSampleVenue(db);
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

      // The month spreads across the whole floor, not a corner of it.
      final tablesUsed = (await db.select(db.tableSessions).get())
          .map((s) => s.tableId)
          .toSet();
      expect(tablesUsed.length, greaterThan(15));

      // Orders are taken by waiters and split between them. Picking the actor
      // across every user row credits bills to the kitchen and to admin, and
      // the reports' Pelayan column is then fiction.
      final waiters = (await db.select(db.users).get())
          .where((u) => u.roleId == DummyData.roleWaiterId)
          .map((u) => u.id)
          .toSet();
      expect(waiters.length, 2);
      // Live tickets are snapshotted and deleted at bill close (ADR-0024), so
      // the month's attribution survives on the session snapshot, not Tickets.
      final takers = lines.map((t) => t.createdByUserId).toList();
      expect(takers, isNotEmpty);
      expect(
        takers.every(waiters.contains),
        isTrue,
        reason: 'a non-waiter was recorded as taking an order',
      );
      expect(
        takers.toSet().length,
        2,
        reason: 'the month must not land on a single waiter',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'history is written through the production order path',
    () async {
      await seedSampleVenue(db);
      // The real path writes a movement per ticket. Direct inserts with a daily
      // roll-up would leave far fewer, and none carrying a ticket id.
      final moves = await db.select(db.stockMovements).get();
      final sales = moves.where((m) => m.reason == 'sale').toList();
      expect(sales, isNotEmpty);
      expect(
        sales.where((m) => m.ticketId != null).length / sales.length,
        greaterThan(0.9),
        reason:
            'sale movements must be attributed to the ticket that caused them',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'the month leaves closed opname sessions behind',
    () async {
      await seedSampleVenue(db);
      final counts = await db.select(db.stockCounts).get();
      expect(counts, isNotEmpty, reason: 'a seeded venue counts weekly');
      expect(
        counts.every((c) => c.closedAt != null),
        isTrue,
        reason: 'the seed never leaves a walk half-finished',
      );
      final lines = await db.select(db.stockCountLines).get();
      expect(lines, isNotEmpty);
      // A document keeps the shelves it found correct — that is the half a
      // ledger of `adjust` rows cannot show (ADR-0096).
      expect(
        lines.any((l) => l.countedQty == l.expectedQty),
        isTrue,
        reason: 'zero-variance lines must survive the close',
      );
      // …and every movement it did produce points back at its session.
      final adjustments = (await db.select(
        db.stockMovements,
      ).get()).where((m) => m.reason == 'adjust');
      expect(adjustments, isNotEmpty);
      expect(
        adjustments.every((m) => m.countId != null),
        isTrue,
        reason: 'a seeded adjustment is always closed out of a count',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'seeding never drags the running app clock',
    () async {
      // Backdating a month by moving the global clock swings the live UI's
      // time and fires alerts against nonsense — the seed passes each row's
      // instant explicitly instead (ADR-0073).
      SatClock.clear();
      await seedSampleVenue(db);
      final drift = SatClock.now().difference(DateTime.now()).abs();
      expect(
        drift.inMinutes,
        lessThan(1),
        reason: 'seed must not leave the process clock shifted',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'the dataset is deterministic across runs',
    () async {
      await seedSampleVenue(db);
      final first = (await db.select(db.tableSessions).get()).fold<int>(
        0,
        (a, s) => a + s.settledTotal,
      );

      final db2 = AppDatabase(NativeDatabase.memory());
      await seedSampleVenue(db2);
      final second = (await db2.select(db2.tableSessions).get()).fold<int>(
        0,
        (a, s) => a + s.settledTotal,
      );
      await db2.close();

      expect(
        second,
        first,
        reason: 'fixed RNG seed must reproduce the dataset',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
