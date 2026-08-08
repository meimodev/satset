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
//     whole point, and the easiest thing to get quietly wrong.
//
// See docs/adr/0088-the-petty-cash-box-cannot-go-negative.md and
// docs/adr/0089-petty-cash-is-not-revenue.md.
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
    await topUpCash(db, amount: 500000);
    await spendCash(db, amount: 120000, category: CashCategory.ingredients);
    await spendCash(db, amount: 30000, category: CashCategory.transport);
    expect(await cashBalance(db), 350000);

    final ledger = await cashLedger(db);
    expect(ledger.length, 3);
    // Newest first, and the sum of what is on screen is the balance only because
    // the whole ledger fits in one page here.
    expect(ledger.fold<int>(0, (a, e) => a + e.delta), 350000);
  });

  test('an expense larger than the box is refused, with the balance', () async {
    await topUpCash(db, amount: 100000);
    await expectLater(
      spendCash(db, amount: 100001, category: CashCategory.other),
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
    await spendCash(db, amount: 100000, category: CashCategory.other);
    expect(await cashBalance(db), 0);
  });

  test('a count writes the variance and may go negative', () async {
    await topUpCash(db, amount: 200000);

    // Short by 20k: the finding is the delta, the count is the absolute.
    final short = await countCash(db, counted: 180000);
    expect(short.kind, CashEntryKind.count);
    expect(short.delta, -20000);
    expect(short.countedAmount, 180000);
    expect(await cashBalance(db), 180000);

    // A matching count still writes a row — "someone checked" is a fact.
    final ok = await countCash(db, counted: 180000);
    expect(ok.delta, 0);
    expect((await cashLedger(db)).length, 3);

    // And a count is exempt from the negative check: an empty box whose ledger
    // says otherwise is a finding, not an invalid input.
    await countCash(db, counted: 0);
    expect(await cashBalance(db), 0);
  });

  test('a row reverses once, and a reversal is not itself reversible', () async {
    final top = await topUpCash(db, amount: 250000);
    expect(await cashBalance(db), 250000);

    await expectLater(
      reverseCash(db, entryId: top.id, note: '   '),
      throwsA(isA<CashException>().having((e) => e.code, 'code', 'note_required')),
    );

    final undo = await reverseCash(
      db,
      entryId: top.id,
      note: 'salah masuk dua kali',
    );
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
    final top = await topUpCash(db, amount: 100000);
    await spendCash(db, amount: 100000, category: CashCategory.ingredients);
    // The money is gone, but the top-up was still wrong — refusing this is what
    // ADR-0088 exempts, or the error would be permanent.
    await reverseCash(db, entryId: top.id, note: 'uang pribadi, bukan kas');
    expect(await cashBalance(db), -100000);
  });

  test('the report section keeps count variance out of in and out', () async {
    final from = DateTime(2026, 8, 1);
    final to = DateTime(2026, 9, 1);

    await topUpCash(db, amount: 300000, at: DateTime(2026, 7, 20));
    await topUpCash(db, amount: 500000, at: DateTime(2026, 8, 5));
    await spendCash(
      db,
      amount: 120000,
      category: CashCategory.ingredients,
      at: DateTime(2026, 8, 6),
    );
    await spendCash(
      db,
      amount: 80000,
      category: CashCategory.ingredients,
      at: DateTime(2026, 8, 7),
    );
    await spendCash(
      db,
      amount: 40000,
      category: CashCategory.transport,
      at: DateTime(2026, 8, 8),
    );
    // Ledger now says 560000; the box holds 550000.
    await countCash(db, counted: 550000, at: DateTime(2026, 8, 9));

    final s = await cashReportSection(db, from: from, to: to);
    expect(s['opening'], 300000, reason: 'July top-up only');
    expect(s['inflow'], 500000);
    expect(s['outflow'], 240000);
    expect(s['variance'], -10000, reason: 'the count, not a purchase');
    expect(s['closing'], 550000);
    expect(s['count'], 5);
    expect(s['byCategory'], {
      CashCategory.ingredients.name: 200000,
      CashCategory.transport.name: 40000,
    });

    // The invariant the section exists to keep: opening + in − out + variance.
    expect(
      (s['opening'] as int) +
          (s['inflow'] as int) -
          (s['outflow'] as int) +
          (s['variance'] as int),
      s['closing'],
    );
  });
}
