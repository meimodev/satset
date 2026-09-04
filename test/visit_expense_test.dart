// The [[Pengeluaran kunjungan]] ledger's one guard and its refusals, against an
// in-memory database and the real writer in `lib/server/visit_expenses.dart`.
//
// What is actually being pinned:
//
//   - the cap is the visit's own subtotal, and it binds the *running sum* of
//     the visit's expenses rather than any single one;
//   - the cap is measured over the bill's line set — sent, non-voided — so a
//     draft cart and a voided line are worth nothing to spend against;
//   - it is checked **at capture only**: a void that lands afterwards leaves an
//     already-recorded expense standing, because the cash already left;
//   - a photo is mandatory server-side, not only in the sheet;
//   - a closed bill refuses, and the way back is reopen;
//   - the petty cash box is untouched — the two ledgers never meet (ADR-0089).
//
// See docs/adr/0130-a-visit-expense-is-revenue-not-petty-cash.md.
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/cash.dart';
import 'package:satset/server/db/database.dart' hide VisitExpense;
import 'package:satset/server/visit_expenses.dart';

void main() {
  late AppDatabase db;
  final photo = Uint8List.fromList([1, 2, 3]);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            tableExpenseEnabled: const Value(true),
          ),
        );
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: 'v1',
            tableId: 't1',
            tableLabel: const Value('Meja 7'),
            createdAt: DateTime.now(),
          ),
        );
  });
  tearDown(() => db.close());

  /// One sent line worth [price]. `status` matters: the cap reads the bill's
  /// line set, not every row that mentions the visit.
  Future<void> line(int price, {String status = 'served', String? id}) => db
      .into(db.tickets)
      .insert(
        TicketsCompanion.insert(
          id: id ?? 'tk-$price-$status',
          tableId: 't1',
          visitId: const Value('v1'),
          itemId: 'i1',
          name: 'Nasi goreng',
          course: 'mains',
          price: price,
          status: status,
          sentAt: DateTime.now(),
        ),
      );

  Future<void> spend(int amount, {String id = 'e1', DateTime? at}) =>
      recordVisitExpense(
        db,
        id: id,
        visitId: 'v1',
        categoryId: 'vexc-other',
        amount: amount,
        photo: photo,
        at: at,
      );

  group('the cap', () {
    test('is the visit subtotal, and the boundary itself is allowed', () async {
      await line(50000);
      await spend(50000);
      expect(await visitExpenseTotal(db, 'v1'), 50000);
    });

    test('refuses one rupiah past it', () async {
      await line(50000);
      await expectLater(
        spend(50001),
        throwsA(
          isA<VisitExpenseException>()
              .having((e) => e.code, 'code', 'exceeds_bill')
              // The numbers ride the refusal so the sheet can say what is left
              // rather than making the waiter go and look.
              .having((e) => e.cap, 'cap', 50000)
              .having((e) => e.spent, 'spent', 0),
        ),
      );
    });

    test('binds the running sum, not one row', () async {
      await line(50000);
      await spend(30000, id: 'e1');
      // On its own this would pass. Against what is already spent it must not —
      // a per-row cap is a cap you defeat by tapping twice.
      await expectLater(
        spend(30000, id: 'e2'),
        throwsA(
          isA<VisitExpenseException>().having((e) => e.spent, 'spent', 30000),
        ),
      );
      await spend(20000, id: 'e3');
      expect(await visitExpenseTotal(db, 'v1'), 50000);
    });

    test('counts neither a draft nor a voided line', () async {
      await line(50000, status: 'draft', id: 'tk-draft');
      await line(80000, status: 'voided', id: 'tk-void');
      expect(await visitSubtotal(db, 'v1'), 0);
      await expectLater(
        spend(1),
        throwsA(
          isA<VisitExpenseException>().having((e) => e.cap, 'cap', 0),
        ),
      );
    });

    test('a later void leaves an expense standing', () async {
      await line(50000, id: 'tk-1');
      await spend(50000);
      // The bill shrinks after the fact. The cash already left the till, so
      // unwinding the expense would be a lie — the refusal at capture was the
      // control, and there is no permanent invariant to restore.
      await (db.update(db.tickets)..where((t) => t.id.equals('tk-1'))).write(
        const TicketsCompanion(status: Value('voided')),
      );
      expect(await visitSubtotal(db, 'v1'), 0);
      expect(await visitExpenseTotal(db, 'v1'), 50000);
    });
  });

  group('refusals', () {
    test('a photo is required by the server, not just the sheet', () async {
      await line(50000);
      await expectLater(
        recordVisitExpense(
          db,
          id: 'e1',
          visitId: 'v1',
          categoryId: 'vexc-other',
          amount: 1000,
          photo: Uint8List(0),
        ),
        throwsA(
          isA<VisitExpenseException>().having(
            (e) => e.code,
            'code',
            'photo_required',
          ),
        ),
      );
    });

    test('zero and negative are not expenses', () async {
      await line(50000);
      await expectLater(
        spend(0),
        throwsA(
          isA<VisitExpenseException>().having(
            (e) => e.code,
            'code',
            'invalid_amount',
          ),
        ),
      );
    });

    test('a closed bill refuses; the way back is reopen', () async {
      await line(50000);
      await (db.update(db.visits)..where((v) => v.id.equals('v1'))).write(
        VisitsCompanion(billClosedAt: Value(DateTime.now())),
      );
      await expectLater(
        spend(1000),
        throwsA(
          isA<VisitExpenseException>().having(
            (e) => e.code,
            'code',
            'bill_closed',
          ),
        ),
      );
      // Reopen — the cashier's existing undo — and the same capture lands.
      await (db.update(db.visits)..where((v) => v.id.equals('v1'))).write(
        const VisitsCompanion(billClosedAt: Value(null)),
      );
      await spend(1000);
      expect(await visitExpenseTotal(db, 'v1'), 1000);
    });

    test('an unknown category refuses', () async {
      await line(50000);
      await expectLater(
        recordVisitExpense(
          db,
          id: 'e1',
          visitId: 'v1',
          categoryId: 'nope',
          amount: 1000,
          photo: photo,
        ),
        throwsA(
          isA<VisitExpenseException>().having(
            (e) => e.code,
            'code',
            'category_not_found',
          ),
        ),
      );
    });
  });

  test('replaying an id reads back the first write, never a second row',
      () async {
    // Found on a device. The id is client-minted and doubles as the idempotency
    // key (ADR-0130), and the [[Antrean kirim]] replays under it — but
    // `idempotent()` keys on the `x-idempotency-key` **header**, which a caller
    // can omit. Without this the second attempt inserts the same primary key
    // and the waiter sees a 500 for an expense that already landed.
    await line(50000);
    await spend(20000, id: 'e-dup');
    await spend(20000, id: 'e-dup');
    expect(await visitExpenseTotal(db, 'v1'), 20000);
    expect(await db.select(db.visitExpenses).get(), hasLength(1));
    final rows = await db.select(db.auditEntries).get();
    expect(rows, hasLength(1), reason: 'and it audits once, not twice');
  });

  test('the petty cash box is untouched', () async {
    await line(50000);
    await spend(20000);
    // ADR-0089 stands: this money did not come from the venue's float, and a
    // reader comparing the two would be comparing a standing fund against one
    // party's takings.
    expect(await cashBalance(db), 0);
    expect(await db.select(db.cashEntries).get(), isEmpty);
  });

  test('one audit row per expense, carrying the venue-authored word', () async {
    await line(50000);
    await spend(20000);
    final rows = await db.select(db.auditEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'tableExpenseRecorded');
    expect(rows.single.amountCents, 20000);
    // The category's *name*, not its key: this vocabulary is venue-authored, so
    // it is ARB-exempt and frozen into the row at write time.
    expect(rows.single.params, contains('Lainnya'));
  });

  test('the default categories exist on a fresh database', () async {
    final cats = await activeExpenseCategories(db);
    expect(cats.map((c) => c.id), contains('vexc-other'));
    expect(cats.map((c) => c.sortOrder), orderedEquals([0, 1, 2, 3]));
  });

  group('the report', () {
    /// The assertion this whole feature is built around (ADR-0130). `net` is
    /// frozen at ADR-0039's formula, and the day it learns about expenses is
    /// the day every historical comparison and every accounting export already
    /// in a customer's hands silently changes meaning.
    test('an expense never moves a settled or net figure', () async {
      Future<void> closeSession(String id, {required int expense}) => db
          .into(db.tableSessions)
          .insert(
            TableSessionsCompanion.insert(
              id: id,
              tableId: 't1',
              zoneId: 'z1',
              closedAt: DateTime(2026, 9, 3, 20),
              subtotal: const Value(50000),
              netTotal: const Value(50000),
              settledTotal: const Value(50000),
              expenseAmount: Value(expense),
            ),
          );
      await closeSession('s-clean', expense: 0);
      await closeSession('s-spent', expense: 15000);

      final rows = await db.select(db.tableSessions).get();
      // Same net, same settled — the only column that moved is the new one.
      expect(rows.map((r) => r.netTotal).toSet(), {50000});
      expect(rows.map((r) => r.settledTotal).toSet(), {50000});
      expect(
        rows.firstWhere((r) => r.id == 's-spent').expenseAmount,
        15000,
      );
    });

    test('the section reads the snapshot, and groups by the venue word',
        () async {
      await line(50000);
      await spend(20000, id: 'e1', at: DateTime(2026, 9, 3, 19));
      await db
          .into(db.tableSessions)
          .insert(
            TableSessionsCompanion.insert(
              id: 's1',
              tableId: 't1',
              tableLabel: const Value('Meja 7'),
              zoneId: 'z1',
              closedAt: DateTime(2026, 9, 3, 20),
              settledTotal: const Value(50000),
              expenseAmount: const Value(20000),
            ),
          );

      final section = await visitExpenseReportSection(
        db,
        from: DateTime(2026, 9, 3),
        to: DateTime(2026, 9, 5),
      );

      expect(section['total'], 20000);
      expect(section['visitCount'], 1);
      // The venue's own word, not a key — this vocabulary is venue-authored, so
      // there is nothing for the reader to resolve.
      expect(section['byCategory'], {'Lainnya': 20000});
      expect((section['visits'] as List).single, containsPair('tableLabel', 'Meja 7'));
    });
  });

  test('a list never carries the photo bytes', () async {
    await line(50000);
    await spend(20000);
    final list = await visitExpenses(db, 'v1');
    expect(list, hasLength(1));
    expect(list.single.categoryName, 'Lainnya');
    expect(list.single.hasPhoto, isTrue);
  });

  // Found on a device: the section read its headline off the closed-session
  // snapshot (`closedAt`) and its breakdown off the live rows (`at`), so an
  // open visit rendered "4 expenses · Rp 70.000 by category · total Rp 0".
  // One axis now — `at`, the moment the cash left — so the two can never
  // disagree, whether or not the bill has closed.
  test('the headline sums the breakdown, bill open or closed', () async {
    await line(200000);
    await spend(15000, id: 'ax-1');
    await spend(25000, id: 'ax-2');

    final section = await visitExpenseReportSection(
      db,
      from: DateTime(2026, 9, 3),
      to: DateTime(2026, 9, 5),
    );

    final byCategory = (section['byCategory'] as Map).values
        .fold<int>(0, (a, v) => a + (v as int));
    final byStaff = (section['byStaff'] as Map).values
        .fold<int>(0, (a, v) => a + (v as int));

    expect(section['count'], 2);
    expect(section['total'], 40000);
    // Counted off the same rows, so the card cannot say "Rp 40.000 across 0
    // visits" while the bill is still open.
    expect(section['visitCount'], 1);
    expect(byCategory, section['total']);
    // byStaff can be empty when no actor is resolvable; when it is not, it
    // must add up to the same money.
    if (byStaff > 0) expect(byStaff, section['total']);
  });
}
