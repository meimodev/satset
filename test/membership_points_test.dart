// The [[Poin]] ledger's arithmetic and its refusals, against an in-memory
// database and the real writers in `lib/server/members.dart`.
//
// What is actually being pinned:
//
//   - the balance is *derived* (`SUM(delta)`), never stored — ADR-0095's premise;
//   - it cannot go negative, so a balance can never be spent twice;
//   - the phone number is the identity: normalised on the way in, and a second
//     enrol on the same number is refused with the member who owns it (ADR-0092);
//   - an earn is idempotent per visit, because bill close can be reached twice;
//   - a reopen reverses the earn, and a *cancelled redemption* does not make
//     that earn look already reversed — the two are paired by sign;
//   - the report section keeps earn and redeem apart, and reports the standing
//     liability rather than the window's.
//
// See docs/adr/0092-a-member-is-a-phone-number.md and
// docs/adr/0095-points-earn-at-bill-close-and-never-expire.md.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // The program is off by default — a venue opts in (ADR-0091). Everything
    // below is about what happens once it is on.
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
          ),
        );
  });
  tearDown(() => db.close());

  Future<Member> enrol([String phone = '+62 812-3456-7890']) =>
      createMember(db, name: 'Budi', phone: phone);

  test('the phone number is the identity, however it was typed', () async {
    final m = await enrol();
    expect(m.phone, '081234567890');
    expect(await findMemberByPhone(db, '62 812 3456 7890'), isNotNull);

    // A second enrol on the same number names the member who owns it, so the
    // till can offer to use them rather than minting a twin.
    await expectLater(
      createMember(db, name: 'Budi Lagi', phone: '0812-3456-7890'),
      throwsA(
        isA<MemberException>()
            .having((e) => e.code, 'code', 'phone_taken')
            .having((e) => e.memberId, 'memberId', m.id),
      ),
    );
  });

  test('the balance is derived, and cannot go negative', () async {
    final m = await enrol();
    expect(await memberPoints(db, m.id), 0);

    await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 250000);
    expect(await memberPoints(db, m.id), 250);

    await expectLater(
      spendPoints(db, memberId: m.id, visitId: 'v1', points: 300),
      throwsA(
        isA<MemberException>().having(
          (e) => e.code,
          'code',
          'insufficient_points',
        ),
      ),
    );
    // Below the venue's minimum is its own refusal, and it names the floor.
    await expectLater(
      spendPoints(db, memberId: m.id, visitId: 'v1', points: 5),
      throwsA(
        isA<MemberException>()
            .having((e) => e.code, 'code', 'below_minimum')
            .having((e) => e.points, 'points', 10),
      ),
    );

    final amount = await spendPoints(
      db,
      memberId: m.id,
      visitId: 'v2',
      points: 100,
    );
    expect(amount, 100000);
    expect(await memberPoints(db, m.id), 150);
  });

  test(
    'an earn happens once per visit, however often close is reached',
    () async {
      final m = await enrol();
      await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 100000);
      await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 100000);
      await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 100000);
      expect(await memberPoints(db, m.id), 100);

      // A reopen takes it back; the re-close earns against the corrected bill
      // rather than un-reversing what was written.
      await reverseEarnForVisit(db, visitId: 'v1');
      expect(await memberPoints(db, m.id), 0);
      await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 60000);
      expect(await memberPoints(db, m.id), 60);
    },
  );

  test('a cancelled redemption does not consume the earn reversal', () async {
    final m = await enrol();
    await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 500000);
    await spendPoints(db, memberId: m.id, visitId: 'v1', points: 100);
    expect(await memberPoints(db, m.id), 400);

    // The cashier takes the redemption back off the unpaid bill: points return,
    // and the earn is untouched.
    await reverseRedeemForVisit(db, visitId: 'v1');
    expect(await memberPoints(db, m.id), 500);

    // Reopening the bill must still find the earn to reverse — this is the bug
    // pairing reversals by sign exists to prevent.
    await reverseEarnForVisit(db, visitId: 'v1');
    expect(await memberPoints(db, m.id), 0);
  });

  test('an adjustment needs a reason and moves the balance', () async {
    final m = await enrol();
    await expectLater(
      adjustPoints(db, memberId: m.id, delta: 50, note: '   '),
      throwsA(
        isA<MemberException>().having((e) => e.code, 'code', 'note_required'),
      ),
    );
    final after = await adjustPoints(
      db,
      memberId: m.id,
      delta: 50,
      note: 'Kompensasi',
    );
    expect(after.points, 50);
  });

  test(
    'merging moves the ledger and the history, then drops the loser',
    () async {
      final a = await enrol('081200000001');
      final b = await createMember(
        db,
        name: 'Budi HP baru',
        phone: '081200000002',
      );
      await earnPointsForVisit(db, memberId: a.id, visitId: 'v1', base: 100000);
      await earnPointsForVisit(db, memberId: b.id, visitId: 'v2', base: 50000);

      final merged = await mergeMembers(db, fromId: a.id, toId: b.id);
      expect(merged.id, b.id);
      expect(merged.points, 150);
      expect(await getMember(db, a.id), isNull);
    },
  );

  test('the report keeps earn and redeem apart', () async {
    final m = await enrol();
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2027, 1, 1);
    await earnPointsForVisit(
      db,
      memberId: m.id,
      visitId: 'v1',
      base: 300000,
      at: DateTime(2026, 6, 1),
    );
    await spendPoints(
      db,
      memberId: m.id,
      visitId: 'v1',
      points: 100,
      at: DateTime(2026, 6, 2),
    );

    final section = await memberReportSection(db, from: from, to: to);
    expect(section['pointsEarned'], 300);
    expect(section['pointsRedeemed'], 100);
    expect(section['pointsOutstanding'], 200);
    // What the venue owes if every standing point were spent tomorrow.
    expect(section['liabilityEstimate'], 200000);
  });
}
