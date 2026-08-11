// The [[Piutang]] ledger's arithmetic and its refusals, against an in-memory
// database and the real writer in `lib/server/debts.dart`.
//
// What is actually being pinned:
//
//   - the balance is *derived* (`SUM(delta)`), never stored — same premise the
//     points ledger and the cash box are built on;
//   - a charge cannot exceed the member's credit limit, and the limit resolves
//     from their own before the venue default;
//   - a collection cannot exceed the balance: nobody owes less than nothing;
//   - `writeOff` and `adjust` are exempt from that floor in the downward
//     direction only, because an uncorrectable error is worse than a negative;
//   - reversing a charge is idempotent, keyed by its `paymentId` — the receipt
//     reopen path can fire twice and a bill can carry two tab payments;
//   - the member lifecycle does not destroy money: a delete is refused while
//     anything is outstanding, and a merge carries the balance across;
//   - ageing is a FIFO walk of the ledger, so a part payment moves
//     `oldestUnpaidAt` forward only when it clears the oldest charge.
//
// See docs/adr/0098-a-tab-is-a-payment-method-not-a-write-off.md.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/member.dart';
import 'package:satset/server/db/database.dart' hide Member, MemberDebt;
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Both programs off by default (ADR-0091 / ADR-0098). Everything below is
    // about what happens once a venue has opted into tabs.
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberDebtEnabled: const Value(true),
            memberDebtLimit: const Value(200000),
            memberDebtOverdueDays: const Value(30),
          ),
        );
  });
  tearDown(() => db.close());

  Future<Member> enrol([String phone = '081234567890']) =>
      createMember(db, name: 'Budi', phone: phone);

  Future<void> charge(
    String memberId,
    int amount, {
    required String paymentId,
    DateTime? at,
  }) => chargeDebt(
    db,
    memberId: memberId,
    amount: amount,
    paymentId: paymentId,
    at: at,
  );

  test('the balance is derived, and a charge respects the limit', () async {
    final m = await enrol();
    expect(await memberDebt(db, m.id), 0);

    await charge(m.id, 150000, paymentId: 'pm1');
    expect(await memberDebt(db, m.id), 150000);

    // 150k + 60k is over the venue's 200k, and the refusal carries both
    // numbers so the till can say *why* rather than only that.
    await expectLater(
      charge(m.id, 60000, paymentId: 'pm2'),
      throwsA(
        isA<DebtException>()
            .having((e) => e.code, 'code', 'debt_limit_exceeded')
            .having((e) => e.balance, 'balance', 150000)
            .having((e) => e.limit, 'limit', 200000),
      ),
    );
    expect(await memberDebt(db, m.id), 150000);
  });

  test('a member limit beats the venue default, and 0 means no tab', () async {
    final m = await enrol();
    await updateMember(db, id: m.id, debtLimit: 500000);

    await charge(m.id, 400000, paymentId: 'pm1');
    expect(await memberDebt(db, m.id), 400000);

    final standing = await debtFor(db, m.id);
    expect(standing.limit, 500000);
    expect(standing.ownLimit, 500000);
    expect(standing.headroom, 100000);

    // Back to the venue default, which they are now over — headroom floors at
    // zero rather than going negative, so the till never offers a tab.
    await updateMember(db, id: m.id, clearDebtLimit: true);
    final back = await debtFor(db, m.id);
    expect(back.limit, 200000);
    expect(back.ownLimit, isNull);
    expect(back.headroom, 0);
  });

  test('a collection cannot exceed the balance', () async {
    final m = await enrol();
    await charge(m.id, 100000, paymentId: 'pm1');

    await expectLater(
      payDebt(db, memberId: m.id, amount: 120000, method: 'tunai'),
      throwsA(
        isA<DebtException>()
            .having((e) => e.code, 'code', 'overpayment')
            .having((e) => e.balance, 'balance', 100000),
      ),
    );

    // The non-cash photo rule is the live one (ADR-0025).
    await expectLater(
      payDebt(db, memberId: m.id, amount: 1000, method: 'qris'),
      throwsA(
        isA<DebtException>().having((e) => e.code, 'code', 'photo_required'),
      ),
    );

    await payDebt(db, memberId: m.id, amount: 100000, method: 'tunai');
    expect(await memberDebt(db, m.id), 0);
  });

  test('write-off and adjust may clear a balance a payment cannot', () async {
    final m = await enrol();
    await charge(m.id, 100000, paymentId: 'pm1');

    await writeOffDebt(db, memberId: m.id, amount: 40000, note: 'Tidak aktif');
    expect(await memberDebt(db, m.id), 60000);

    // A correction is signed, and kept apart from a write-off precisely so the
    // bad-debt figure stays "money we lost" rather than "losses plus typos".
    await adjustDebt(db, memberId: m.id, delta: -60000, note: 'Salah catat');
    expect(await memberDebt(db, m.id), 0);

    // Both refuse an empty reason: an unexplained movement of money is the one
    // row nobody can audit later.
    await expectLater(
      adjustDebt(db, memberId: m.id, delta: 1000, note: '  '),
      throwsA(
        isA<DebtException>().having((e) => e.code, 'code', 'note_required'),
      ),
    );
  });

  test('reversing a charge is idempotent per payment', () async {
    final m = await enrol();
    await charge(m.id, 50000, paymentId: 'pm1');
    await charge(m.id, 30000, paymentId: 'pm2');
    expect(await memberDebt(db, m.id), 80000);

    await reverseChargeForPayment(db, paymentId: 'pm1');
    expect(await memberDebt(db, m.id), 30000);

    // A reopen that fires twice — or a retry after a dropped response — must
    // not credit the member a second time.
    await reverseChargeForPayment(db, paymentId: 'pm1');
    expect(await memberDebt(db, m.id), 30000);

    // A bill carrying two tab payments reverses both, one call each.
    await reverseChargeForPayment(db, paymentId: 'pm2');
    expect(await memberDebt(db, m.id), 0);
  });

  test('a member who owes cannot be deleted', () async {
    final m = await enrol();
    await charge(m.id, 25000, paymentId: 'pm1');

    await expectLater(
      deleteMember(db, id: m.id),
      throwsA(
        isA<MemberException>().having(
          (e) => e.code,
          'code',
          'has_outstanding_debt',
        ),
      ),
    );

    // Say which it was — collected or forgiven — and the delete goes through.
    await writeOffDebt(db, memberId: m.id, amount: 25000, note: 'Menyerah');
    await deleteMember(db, id: m.id);
    expect(await memberDebt(db, m.id), 0);

    // ...and the loss stays booked. Deleting the person must not rewrite last
    // month's bad-debt total.
    final s = await debtReportSection(
      db,
      from: DateTime.now().subtract(const Duration(days: 1)),
      to: DateTime.now().add(const Duration(days: 1)),
    );
    expect(s['charged'], 25000);
    expect(s['writtenOff'], 25000);
    expect(s['debtorCount'], 0);
  });

  test('a merge carries the balance across', () async {
    final a = await enrol('081200000001');
    final b = await enrol('081200000002');
    await charge(a.id, 40000, paymentId: 'pm1');
    await charge(b.id, 15000, paymentId: 'pm2');

    await mergeMembers(db, fromId: a.id, toId: b.id);
    expect(await memberDebt(db, b.id), 55000);
    expect(await memberDebt(db, a.id), 0);
  });

  test('ageing walks the ledger FIFO', () async {
    final m = await enrol();
    final t0 = DateTime.now().subtract(const Duration(days: 40));
    final t1 = DateTime.now().subtract(const Duration(days: 10));
    await charge(m.id, 30000, paymentId: 'pm1', at: t0);
    await charge(m.id, 50000, paymentId: 'pm2', at: t1);

    // A part payment short of the oldest charge leaves it standing, so the age
    // still reads from the 40-day-old row.
    await payDebt(db, memberId: m.id, amount: 10000, method: 'tunai');
    var owing = (await listDebtors(db)).single;
    expect(owing.balance, 70000);
    expect(owing.oldestUnpaidAt, isNotNull);
    expect(owing.ageInDaysAt(DateTime.now()), greaterThanOrEqualTo(39));

    // Clearing it moves the age onto the newer charge — this is the whole
    // reason ageing is derived rather than a due-date column.
    await payDebt(db, memberId: m.id, amount: 20000, method: 'tunai');
    owing = (await listDebtors(db)).single;
    expect(owing.balance, 50000);
    expect(owing.ageInDaysAt(DateTime.now()), lessThan(39));
  });

  test('the report section separates a loss from a correction', () async {
    final m = await enrol();
    final from = DateTime.now().subtract(const Duration(days: 7));
    final to = DateTime.now().add(const Duration(days: 1));

    await charge(m.id, 100000, paymentId: 'pm1');
    await payDebt(db, memberId: m.id, amount: 20000, method: 'tunai');
    await writeOffDebt(db, memberId: m.id, amount: 30000, note: 'Menyerah');
    await adjustDebt(db, memberId: m.id, delta: -10000, note: 'Salah catat');

    // All three reducers report as positive amounts *taken off* the balance,
    // so the closing line reads as one subtraction and a downward correction
    // never looks like it grew the book.
    final s = await debtReportSection(db, from: from, to: to);
    expect(s['charged'], 100000);
    expect(s['collected'], 20000);
    expect(s['writtenOff'], 30000);
    expect(s['adjusted'], 10000);
    expect(s['closing'], 40000);
    expect(s['debtorCount'], 1);
  });
}
