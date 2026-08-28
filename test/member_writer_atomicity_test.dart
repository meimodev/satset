// A ledger guard only holds inside a transaction (ADR-0100), and three of the
// member writers were outside one.
//
// The balance is `SUM(delta)` — nothing stores it — so no `CHECK` constraint
// can hold the floor and the guard is Dart and nothing else. Dart between a
// read and a write is a window:
//
//   - `_post` read the balance, then inserted. Two hand adjustments, or an
//     adjustment racing a redemption, could each see a balance that covers
//     them and both land. `spendPoints` and `earnPointsForVisit` brought their
//     own transaction and were fine; the hand adjustment and the two reversals
//     had none.
//   - `deleteMember` read the debt balance, then deleted the person. A charge
//     landing in that window takes a live receivable out with them, which is
//     the one outcome that function exists to refuse.
//   - `mergeMembers` repointed five tables and deleted a row, unwrapped. A
//     failure halfway leaves points naming one person and debt naming another,
//     with no repair from outside.
//
// A race cannot be staged honestly in a single-isolate test, so the boundary
// is asserted where it actually lives — in the source — and the guards are
// then exercised through the nesting to prove the wrap did not break them.
import 'dart:io';

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
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberPointsEnabled: const Value(true),
            memberEarnPerThousand: const Value(1),
            memberPointValue: const Value(1000),
            memberRedeemMin: const Value(10),
            memberDebtEnabled: const Value(true),
            memberDebtLimit: const Value(100000),
          ),
        );
  });
  tearDown(() => db.close());

  Future<Member> enrol([String phone = '+62 812-3456-7890']) =>
      createMember(db, name: 'Budi', phone: phone);

  group('the boundary is where the guard is', () {
    final source = File('lib/server/members.dart').readAsStringSync();

    /// The body of a top-level `Future<...> name(` declaration, up to the next
    /// one. Crude on purpose — it only has to answer "does this function open
    /// a transaction", and a false pass would need the *next* function's wrap
    /// to be the one it finds, which the ordering here rules out.
    String bodyOf(String src, String name) {
      final start = src.indexOf(
        RegExp('^Future<[^>]*> $name\\(', multiLine: true),
      );
      expect(start, isNonNegative, reason: '$name has moved or been renamed');
      final next = src.indexOf(RegExp(r'^Future<', multiLine: true), start + 1);
      return src.substring(start, next == -1 ? src.length : next);
    }

    for (final writer in [
      '_post',
      'deleteMember',
      'mergeMembers',
      'spendPoints',
      'earnPointsForVisit',
    ]) {
      test('members.$writer reads and writes inside one transaction', () {
        expect(
          bodyOf(source, writer),
          contains('db.transaction('),
          reason: 'a derived balance has no CHECK to fall back on',
        );
      });
    }

    // The tab ledger is the same family with the same shape, and it had *no*
    // transaction anywhere in the file — including under the credit limit,
    // which is the one guard here standing between a venue and money it will
    // not get back. Its guards are handed down into `_post` rather than run
    // ahead of it, so the boundary is asserted in one place.
    final debts = File('lib/server/debts.dart').readAsStringSync();

    test('debts._post wraps the guard it was handed', () {
      final body = bodyOf(debts, '_post');
      expect(body, contains('db.transaction('));
      expect(body, contains('if (guard != null) await guard();'));
    });

    for (final writer in ['chargeDebt', 'payDebt']) {
      test('$writer hands its refusal down instead of running it first', () {
        final body = bodyOf(debts, writer);
        expect(
          body,
          contains('guard: () async {'),
          reason: 'a check run before _post is a check outside the transaction',
        );
        expect(
          body.indexOf('await memberDebt('),
          greaterThan(body.indexOf('guard: () async {')),
          reason: 'the balance is read inside the guard, not above the call',
        );
      });
    }
  });

  group('the guards still hold through the nesting', () {
    test('a hand adjustment cannot take the balance below zero', () async {
      final m = await enrol();
      await adjustPoints(db, memberId: m.id, delta: 30, note: 'goodwill');

      await expectLater(
        adjustPoints(db, memberId: m.id, delta: -31, note: 'oops'),
        throwsA(
          isA<MemberException>().having(
            (e) => e.code,
            'code',
            'insufficient_points',
          ),
        ),
      );
      expect(
        await memberPoints(db, m.id),
        30,
        reason: 'the refused adjustment left no row behind',
      );
    });

    test('a redemption still works with _post nested inside it', () async {
      // `spendPoints` opens a transaction and `_post` now opens another inside
      // it. Drift makes the inner one a savepoint; if it did not, this throws.
      final m = await enrol();
      await adjustPoints(db, memberId: m.id, delta: 100, note: 'seed');

      final amount = await spendPoints(
        db,
        memberId: m.id,
        visitId: 'visit-1',
        points: 40,
      );

      expect(amount, 40 * 1000);
      expect(await memberPoints(db, m.id), 60);
    });

    test('an earn still works with _post nested inside it', () async {
      final m = await enrol();
      final earned = await earnPointsForVisit(
        db,
        memberId: m.id,
        visitId: 'visit-2',
        base: 50000,
      );
      expect(earned, 50);
      expect(await memberPoints(db, m.id), 50);
    });

    test('deleting refuses while a receivable is live, and keeps it', () async {
      final m = await enrol();
      await chargeDebt(
        db,
        memberId: m.id,
        amount: 25000,
        paymentId: 'pay-3',
        visitId: 'visit-3',
      );

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
      expect(await getMember(db, m.id), isNotNull);
      expect(await memberDebt(db, m.id), 25000);
    });

    test('deleting a settled member takes the person, not the trade', () async {
      final m = await enrol();
      await adjustPoints(db, memberId: m.id, delta: 10, note: 'seed');
      await chargeDebt(
        db,
        memberId: m.id,
        amount: 25000,
        paymentId: 'pay-4',
        visitId: 'visit-4',
      );
      await payDebt(db, memberId: m.id, amount: 25000, method: 'tunai');

      await deleteMember(db, id: m.id);

      expect(await getMember(db, m.id), isNull);
      final debts = await db.select(db.memberDebts).get();
      expect(
        debts,
        hasLength(2),
        reason: 'the charge and the settlement are money that moved',
      );
      expect(await db.select(db.memberPoints).get(), isEmpty);
    });

    test('a merge leaves one person holding both ledgers', () async {
      final a = await enrol('0811111111');
      final b = await createMember(
        db,
        name: 'Budi Duplikat',
        phone: '0822222222',
      );
      await adjustPoints(db, memberId: a.id, delta: 30, note: 'seed a');
      await adjustPoints(db, memberId: b.id, delta: 20, note: 'seed b');

      await mergeMembers(db, fromId: b.id, toId: a.id);

      expect(await getMember(db, b.id), isNull);
      expect(
        await memberPoints(db, a.id),
        50,
        reason: 'both ledgers repointed, or neither did',
      );
    });
  });
}
