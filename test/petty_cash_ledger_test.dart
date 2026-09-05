// The petty cash box's arithmetic and its two refusals, against an in-memory
// database and the real writers in `lib/server/cash.dart`.
//
// What is actually being pinned:
//
//   - the balance is *derived* (`SUM(delta)`), never stored — ADR-0088's premise;
//   - the box cannot go negative, and the two exemptions the ADR names still work;
//   - a count writes the variance as its delta, and a matching count still writes
//     a row;
//   - a row can be reversed once and only once;
//   - the report section keeps a count's variance out of in/out — ADR-0089's
//     whole point, and the easiest thing to get quietly wrong;
//   - every guard is *per box* and a transfer is one act in two rows — ADR-0131;
//   - a category belongs to one box, is the venue's own word, and renaming it
//     re-reads the whole ledger — ADR-0135.
//
// See docs/adr/0088-the-petty-cash-box-cannot-go-negative.md,
// docs/adr/0089-petty-cash-is-not-revenue.md and
// docs/adr/0131-a-venue-counts-more-than-one-tin.md and
// docs/adr/0135-a-category-is-the-venues-word-and-the-box-owns-it.md.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/server/cash.dart';
import 'package:satset/server/db/database.dart' hide CashEntry;

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('balance is derived from the ledger', () async {
    expect(await cashBalance(db), 0);
    await topUpCash(db, boxId: 'box-main',
      amount: 500000);
    await spendCash(db, boxId: 'box-main',
      amount: 120000, categoryId: 'ingredients');
    await spendCash(db, boxId: 'box-main',
      amount: 30000, categoryId: 'transport');
    expect(await cashBalance(db), 350000);

    final ledger = await cashLedger(db);
    expect(ledger.length, 3);
    // Newest first, and the sum of what is on screen is the balance only because
    // the whole ledger fits in one page here.
    expect(ledger.fold<int>(0, (a, e) => a + e.delta), 350000);
  });

  test('an expense larger than the box is refused, with the balance', () async {
    await topUpCash(db, boxId: 'box-main',
      amount: 100000);
    await expectLater(
      spendCash(db, boxId: 'box-main',
      amount: 100001, categoryId: 'other'),
      throwsA(
        isA<CashException>()
            .having((e) => e.code, 'code', 'insufficient_cash')
            .having((e) => e.balance, 'balance', 100000),
      ),
    );
    // The refusal wrote nothing.
    expect(await cashBalance(db), 100000);
    expect((await cashLedger(db)).length, 1);

    // Exactly the balance is allowed — a box emptied to zero is normal.
    await spendCash(db, boxId: 'box-main',
      amount: 100000, categoryId: 'other');
    expect(await cashBalance(db), 0);
  });

  test('a count writes the variance and may go negative', () async {
    await topUpCash(db, boxId: 'box-main',
      amount: 200000);

    // Short by 20k: the finding is the delta, the count is the absolute.
    final short = await countCash(db, boxId: 'box-main',
      counted: 180000);
    expect(short.kind, CashEntryKind.count);
    expect(short.delta, -20000);
    expect(short.countedAmount, 180000);
    expect(await cashBalance(db), 180000);

    // A matching count still writes a row — "someone checked" is a fact.
    final ok = await countCash(db, boxId: 'box-main',
      counted: 180000);
    expect(ok.delta, 0);
    expect((await cashLedger(db)).length, 3);

    // And a count is exempt from the negative check: an empty box whose ledger
    // says otherwise is a finding, not an invalid input.
    await countCash(db, boxId: 'box-main',
      counted: 0);
    expect(await cashBalance(db), 0);
  });

  test('a row reverses once, and a reversal is not itself reversible', () async {
    final top = await topUpCash(db, boxId: 'box-main',
      amount: 250000);
    expect(await cashBalance(db), 250000);

    await expectLater(
      reverseCash(db, entryId: top.id, note: '   '),
      throwsA(isA<CashException>().having((e) => e.code, 'code', 'note_required')),
    );

    final undo = (await reverseCash(
      db,
      entryId: top.id,
      note: 'salah masuk dua kali',
    )).single;
    expect(undo.delta, -250000);
    expect(undo.reversesId, top.id);
    expect(await cashBalance(db), 0);

    // The target now carries the back-link, which is what stops the UI offering
    // a second reversal.
    final target = (await cashLedger(db)).firstWhere((e) => e.id == top.id);
    expect(target.reversedById, undo.id);
    expect(target.canReverse, isFalse);

    await expectLater(
      reverseCash(db, entryId: top.id, note: 'lagi'),
      throwsA(
        isA<CashException>().having((e) => e.code, 'code', 'already_reversed'),
      ),
    );
    await expectLater(
      reverseCash(db, entryId: undo.id, note: 'lagi'),
      throwsA(
        isA<CashException>().having((e) => e.code, 'code', 'not_reversible'),
      ),
    );
    await expectLater(
      reverseCash(db, entryId: 'tidak-ada', note: 'lagi'),
      throwsA(isA<CashException>().having((e) => e.code, 'code', 'not_found')),
    );
  });

  test('a reversal may take the box below zero', () async {
    final top = await topUpCash(db, boxId: 'box-main',
      amount: 100000);
    await spendCash(db, boxId: 'box-main',
      amount: 100000, categoryId: 'ingredients');
    // The money is gone, but the top-up was still wrong — refusing this is what
    // ADR-0088 exempts, or the error would be permanent.
    await reverseCash(db, entryId: top.id, note: 'uang pribadi, bukan kas');
    expect(await cashBalance(db), -100000);
  });

  test('the report section keeps count variance out of in and out', () async {
    final from = DateTime(2026, 8, 1);
    final to = DateTime(2026, 9, 1);

    await topUpCash(db, boxId: 'box-main',
      amount: 300000, at: DateTime(2026, 7, 20));
    await topUpCash(db, boxId: 'box-main',
      amount: 500000, at: DateTime(2026, 8, 5));
    await spendCash(
      db,
      boxId: 'box-main',
      amount: 120000,
      categoryId: 'ingredients',
      at: DateTime(2026, 8, 6),
    );
    await spendCash(
      db,
      boxId: 'box-main',
      amount: 80000,
      categoryId: 'ingredients',
      at: DateTime(2026, 8, 7),
    );
    await spendCash(
      db,
      boxId: 'box-main',
      amount: 40000,
      categoryId: 'transport',
      at: DateTime(2026, 8, 8),
    );
    // Ledger now says 560000; the box holds 550000.
    await countCash(db, boxId: 'box-main',
      counted: 550000, at: DateTime(2026, 8, 9));

    final s = await cashReportSection(db, from: from, to: to);
    expect(s['opening'], 300000, reason: 'July top-up only');
    expect(s['inflow'], 500000);
    expect(s['outflow'], 240000);
    expect(s['variance'], -10000, reason: 'the count, not a purchase');
    expect(s['closing'], 550000);
    expect(s['count'], 5);
    // The venue's own words, not codes (ADR-0135).
    expect(s['byCategory'], {'Belanja bahan': 200000, 'Transport': 40000});

    // The invariant the section exists to keep: opening + in − out + variance.
    expect(
      (s['opening'] as int) +
          (s['inflow'] as int) -
          (s['outflow'] as int) +
          (s['variance'] as int),
      s['closing'],
    );
  });

  group('more than one tin (ADR-0131)', () {
    /// A second box, funded, so the two can be told apart by their balances.
    Future<String> secondBox(AppDatabase db, {int fund = 0}) async {
      final box = await createCashBox(db, name: 'Kas Dapur');
      if (fund > 0) await topUpCash(db, boxId: box.id, amount: fund);
      return box.id;
    }

    test('a full box does not make an empty one spendable', () async {
      final dapur = await secondBox(db);
      await topUpCash(db, boxId: 'box-main', amount: 1000000);

      // Venue-wide there is a million rupiah. In the tin being spent from there
      // is nothing, and the notes are what the guard is about.
      await expectLater(
        spendCash(
          db,
          boxId: dapur,
          amount: 50000,
          categoryId: 'ingredients',
        ),
        throwsA(
          isA<CashException>()
              .having((e) => e.code, 'code', 'insufficient_cash')
              .having((e) => e.balance, 'balance', 0),
        ),
      );

      expect(await cashBalance(db, boxId: 'box-main'), 1000000);
      expect(await cashBalance(db, boxId: dapur), 0);
      expect(await cashBalance(db), 1000000, reason: 'venue-wide is the sum');
    });

    test('a transfer writes two linked rows and nets the venue to zero',
        () async {
      final dapur = await secondBox(db);
      await topUpCash(db, boxId: 'box-main', amount: 800000);
      final before = await cashBalance(db);

      final legs = await transferCash(
        db,
        fromId: 'box-main',
        toId: dapur,
        amount: 300000,
      );

      expect(legs.length, 2);
      expect(legs[0].delta, -300000);
      expect(legs[1].delta, 300000);
      expect(legs[0].transferPeerId, legs[1].id);
      expect(legs[1].transferPeerId, legs[0].id);
      // Nothing was bought, so neither leg may reach the by-category breakdown.
      expect(legs[0].categoryId, isNull);
      expect(legs[1].categoryId, isNull);

      expect(await cashBalance(db, boxId: 'box-main'), 500000);
      expect(await cashBalance(db, boxId: dapur), 300000);
      expect(await cashBalance(db), before, reason: 'internal movement');

      // One audit line for the pair — the second leg is the same act.
      final audits = await db.select(db.auditEntries).get();
      expect(
        audits.where((a) => a.kind == 'cashTransferred').length,
        1,
      );
    });

    test('a transfer is refused above the source balance, and into itself',
        () async {
      final dapur = await secondBox(db);
      await topUpCash(db, boxId: 'box-main', amount: 100000);

      await expectLater(
        transferCash(db, fromId: 'box-main', toId: dapur, amount: 100001),
        throwsA(
          isA<CashException>()
              .having((e) => e.code, 'code', 'insufficient_cash')
              .having((e) => e.balance, 'balance', 100000),
        ),
      );
      await expectLater(
        transferCash(
          db,
          fromId: 'box-main',
          toId: 'box-main',
          amount: 1000,
        ),
        throwsA(isA<CashException>().having((e) => e.code, 'code', 'same_box')),
      );
      await expectLater(
        transferCash(db, fromId: 'box-main', toId: 'tidak-ada', amount: 1000),
        throwsA(
          isA<CashException>().having((e) => e.code, 'code', 'box_not_found'),
        ),
      );
      // Every refusal wrote nothing.
      expect((await cashLedger(db)).length, 1);
    });

    test('reversing one leg of a transfer undoes both', () async {
      final dapur = await secondBox(db);
      await topUpCash(db, boxId: 'box-main', amount: 800000);
      final legs = await transferCash(
        db,
        fromId: 'box-main',
        toId: dapur,
        amount: 300000,
      );

      final undo = await reverseCash(
        db,
        entryId: legs[0].id,
        note: 'pindah ke kas yang salah',
      );

      // Two counter-entries, one per leg. Undoing only the out-leg would leave
      // money standing in Kas Dapur that never left Kas Utama.
      expect(undo.length, 2);
      expect(await cashBalance(db, boxId: 'box-main'), 800000);
      expect(await cashBalance(db, boxId: dapur), 0);

      // And the pair is now spent: neither leg may be reversed again, from
      // either end.
      for (final leg in legs) {
        await expectLater(
          reverseCash(db, entryId: leg.id, note: 'lagi'),
          throwsA(
            isA<CashException>()
                .having((e) => e.code, 'code', 'already_reversed'),
          ),
        );
      }
    });

    test('a box holding money cannot be retired', () async {
      final dapur = await secondBox(db, fund: 250000);

      await expectLater(
        updateCashBox(db, id: dapur, active: false),
        throwsA(
          isA<CashException>()
              .having((e) => e.code, 'code', 'box_not_empty')
              .having((e) => e.balance, 'balance', 250000),
        ),
      );

      // Emptied — by transfer, which is the way that does not invent an expense
      // — it retires, and its history survives the retirement.
      await transferCash(
        db,
        fromId: dapur,
        toId: 'box-main',
        amount: 250000,
      );
      final retired = await updateCashBox(db, id: dapur, active: false);
      expect(retired.active, isFalse);
      expect(
        (await cashLedger(db, boxId: dapur)).isNotEmpty,
        isTrue,
        reason: 'retiring hides the box, it never deletes its rows',
      );

      // A rename does not touch the rows either.
      final renamed = await updateCashBox(db, id: dapur, name: 'Kas Bar');
      expect(renamed.name, 'Kas Bar');
      await expectLater(
        updateCashBox(db, id: dapur, name: '   '),
        throwsA(
          isA<CashException>().having((e) => e.code, 'code', 'name_required'),
        ),
      );
    });

    test('the report section sums its boxes, and a transfer nets out',
        () async {
      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 9, 1);
      final dapur = await secondBox(db);

      await topUpCash(
        db,
        boxId: 'box-main',
        amount: 900000,
        at: DateTime(2026, 8, 2),
      );
      await transferCash(
        db,
        fromId: 'box-main',
        toId: dapur,
        amount: 400000,
        at: DateTime(2026, 8, 3),
      );
      await spendCash(
        db,
        boxId: dapur,
        amount: 150000,
        categoryId: 'ingredients',
        at: DateTime(2026, 8, 4),
      );

      final s = await cashReportSection(db, from: from, to: to);
      final byBox = (s['byBox'] as List).cast<Map<String, dynamic>>();
      final main = byBox.firstWhere((b) => b['id'] == 'box-main');
      final kitchen = byBox.firstWhere((b) => b['id'] == dapur);

      // Per box a transfer is real movement.
      expect(main['inflow'], 900000);
      expect(main['outflow'], 400000);
      expect(main['closing'], 500000);
      expect(kitchen['inflow'], 400000);
      expect(kitchen['outflow'], 150000);
      expect(kitchen['closing'], 250000);

      // Venue-wide it cancels, with no rule needed to exclude it: the totals
      // are the sum of the boxes.
      expect(s['inflow'], 1300000);
      expect(s['outflow'], 550000);
      expect(s['closing'], 750000);
      expect(
        s['closing'],
        (main['closing'] as int) + (kitchen['closing'] as int),
      );
      // A transfer buys nothing, so it never reaches the category breakdown.
      expect(s['byCategory'], {'Belanja bahan': 150000});
    });
  });

  group('the box owns its vocabulary (ADR-0135)', () {
    test('every box starts with the five stock words, under their old '
        'enum names', () async {
      // The whole migration story: a pre-v75 row reading `ingredients` finds
      // this row under its own box, so nothing had to be backfilled.
      final main = await cashCategoryList(db, boxId: 'box-main');
      expect(main.map((c) => c.id), [
        'ingredients',
        'operations',
        'transport',
        'dailyWage',
        'other',
      ]);
      expect(main.first.name, 'Belanja bahan');

      // And a box created later gets the same five, so a fresh tin can take an
      // expense the moment it exists.
      final kitchen = await createCashBox(db, name: 'Kas Dapur');
      final theirs = await cashCategoryList(db, boxId: kitchen.id);
      expect(theirs.map((c) => c.id), main.map((c) => c.id));
    });

    test('a category from another box is refused', () async {
      final kitchen = await createCashBox(db, name: 'Kas Dapur');
      await topUpCash(db, boxId: kitchen.id, amount: 100000);
      final sayur = await createCashCategory(
        db,
        boxId: 'box-main',
        name: 'Sayur',
      );

      await expectLater(
        spendCash(db, boxId: kitchen.id, amount: 1000, categoryId: sayur.id),
        throwsA(
          isA<CashException>().having((e) => e.code, 'code', 'unknown_category'),
        ),
      );
      // A retired word is refused the same way — the picker hides it, and the
      // writer is what actually enforces it.
      await updateCashCategory(
        db,
        boxId: kitchen.id,
        id: 'transport',
        active: false,
      );
      await expectLater(
        spendCash(db, boxId: kitchen.id, amount: 1000, categoryId: 'transport'),
        throwsA(
          isA<CashException>().having((e) => e.code, 'code', 'unknown_category'),
        ),
      );
      // Neither refusal wrote anything.
      expect(await cashBalance(db, boxId: kitchen.id), 100000);
    });

    test('a rename re-reads the ledger and the report, and the audit line '
        'keeps what it wrote', () async {
      await topUpCash(db, boxId: 'box-main', amount: 500000);
      await spendCash(
        db,
        boxId: 'box-main',
        amount: 60000,
        categoryId: 'ingredients',
      );

      await updateCashCategory(
        db,
        boxId: 'box-main',
        id: 'ingredients',
        name: 'Belanja pasar',
      );

      // The entry stores the id, so the word follows the rename.
      final row = (await cashLedger(db)).firstWhere(
        (e) => e.kind == CashEntryKind.expense,
      );
      expect(row.categoryId, 'ingredients');
      expect(row.categoryName, 'Belanja pasar');

      final section = await cashReportSection(
        db,
        from: DateTime(2000),
        to: DateTime(2100),
      );
      expect(section['byCategory'], {'Belanja pasar': 60000});

      // The audit params are frozen prose: they say what was chosen at the time.
      final audit = await db
          .customSelect("SELECT params FROM audit_entries "
              "WHERE kind = 'cashSpent'")
          .getSingle();
      expect(audit.read<String>('params'), contains('Belanja bahan'));
    });

    test('two tins that authored the same word read as one venue line, '
        'and each box keeps its own breakdown', () async {
      final kitchen = await createCashBox(db, name: 'Kas Dapur');
      await topUpCash(db, boxId: 'box-main', amount: 500000);
      await topUpCash(db, boxId: kitchen.id, amount: 500000);
      final a = await createCashCategory(db, boxId: 'box-main', name: 'Sayur');
      final b = await createCashCategory(db, boxId: kitchen.id, name: 'Sayur');
      expect(a.id, isNot(b.id), reason: 'two rows, one word');

      await spendCash(db, boxId: 'box-main', amount: 30000, categoryId: a.id);
      await spendCash(db, boxId: kitchen.id, amount: 20000, categoryId: b.id);

      final section = await cashReportSection(
        db,
        from: DateTime(2000),
        to: DateTime(2100),
      );
      expect(section['byCategory'], {'Sayur': 50000});
      final boxes = (section['byBox'] as List).cast<Map<String, dynamic>>();
      expect(
        boxes.firstWhere((x) => x['id'] == 'box-main')['byCategory'],
        {'Sayur': 30000},
      );
      expect(
        boxes.firstWhere((x) => x['id'] == kitchen.id)['byCategory'],
        {'Sayur': 20000},
      );
    });

    test('a box may be retired down to no categories, and the expense is '
        'then refused', () async {
      await topUpCash(db, boxId: 'box-main', amount: 100000);
      for (final c in await cashCategoryList(db, boxId: 'box-main')) {
        await updateCashCategory(
          db,
          boxId: 'box-main',
          id: c.id,
          active: false,
        );
      }
      expect(
        await cashCategoryList(db, boxId: 'box-main', activeOnly: true),
        isEmpty,
      );
      await expectLater(
        spendCash(db, boxId: 'box-main', amount: 1000, categoryId: 'other'),
        throwsA(
          isA<CashException>().having((e) => e.code, 'code', 'unknown_category'),
        ),
      );
    });
  });
}
