// The membership *reading* surfaces: the ranked list in the Keanggotaan report
// block, the "belum kembali" cut on the directory, and a member's own visit
// history.
//
// What is being pinned:
//
//   - the ranked list carries every member who traded, up to its cap, and says
//     how many it left off — a capped list whose tail is silent reads as if the
//     hundredth name were the last one;
//   - per-member points are the ledger's own `memberId`, net of reversals — a
//     reopened bill must not leave the member looking like they kept the points;
//   - lapse is *derived* from the last settled visit on every read, never
//     stored, and an enrolment that never came back counts as lapsed;
//   - a member's visit history is newest-first, lifetime, and a walkout close
//     stays visible as one rather than passing for a small spend.
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
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberPointsEnabled: const Value(true),
            memberEarnPerThousand: const Value(1),
            memberPointValue: const Value(1000),
          ),
        );
  });
  tearDown(() => db.close());

  final now = DateTime.now().toUtc();

  Future<Member> enrol(String name, String phone) =>
      createMember(db, name: name, phone: phone);

  /// One settled bill against [memberId], [daysAgo] days back.
  Future<void> closeBill(
    String id, {
    String? memberId,
    required int daysAgo,
    int settled = 100000,
    int loss = 0,
    String kind = 'dineIn',
    String? tableLabel,
  }) => db
      .into(db.tableSessions)
      .insert(
        TableSessionsCompanion.insert(
          id: id,
          tableId: 't1',
          tableLabel: Value(tableLabel),
          zoneId: 'z1',
          closedAt: now.subtract(Duration(days: daysAgo)),
          memberId: Value(memberId),
          settledTotal: Value(settled),
          lossAmount: Value(loss),
          kind: Value(kind),
        ),
      );

  Future<Map<String, dynamic>> report({int days = 365}) => memberReportSection(
    db,
    from: now.subtract(Duration(days: days)),
    to: now.add(const Duration(days: 1)),
  );

  // ---------------------------------------------------------------------
  // The ranked list
  // ---------------------------------------------------------------------

  test('the ranked list ranks by spend and names its own tail', () async {
    // 120 members who each traded once, spending more the higher their index —
    // past the 100 the section carries.
    for (var i = 0; i < 120; i++) {
      final m = await enrol('M$i', '08120000${i.toString().padLeft(4, '0')}');
      await closeBill('s$i', memberId: m.id, daysAgo: 1, settled: 1000 * i);
    }

    final r = await report();
    final top = (r['top'] as List).cast<Map<String, dynamic>>();
    expect(top.length, 100, reason: 'the list is capped, not unbounded');
    expect(top.first['name'], 'M119', reason: 'spend desc');
    // The 20 it left off are counted, not silently dropped.
    expect(r['topTruncated'], 20);
    expect(r['activeMembers'], 120);
  });

  test('per-member points are net of a reversal, not the gross earn', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('s1', memberId: m.id, daysAgo: 1, settled: 100000);
    await earnPointsForVisit(db, memberId: m.id, visitId: 'v1', base: 100000);
    // The bill reopened: the earn is undone by a reversal, never edited.
    await reverseEarnForVisit(db, visitId: 'v1');
    await earnPointsForVisit(db, memberId: m.id, visitId: 'v2', base: 50000);

    final r = await report();
    final row = (r['top'] as List).first as Map<String, dynamic>;
    expect(row['points'], 50, reason: '100 earned, 100 reversed, 50 earned');
    expect(r['pointsEnabled'], isTrue);
  });

  test('a venue with points off says so rather than sending zeros', () async {
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberPointsEnabled: const Value(false),
          ),
        );
    expect((await report())['pointsEnabled'], isFalse);
  });

  // ---------------------------------------------------------------------
  // The lapsed cut
  // ---------------------------------------------------------------------

  test('lapse is read off the last settled visit, and never stored', () async {
    final regular = await enrol('Regular', '08120000001');
    final gone = await enrol('Gone', '08120000002');
    await enrol('Never', '08120000003');
    await closeBill('s1', memberId: regular.id, daysAgo: 3);
    await closeBill('s2', memberId: gone.id, daysAgo: 90);

    final lapsed = await listMembers(db, lapsedDays: 60);
    expect(
      lapsed.map((m) => m.name).toSet(),
      {'Gone', 'Never'},
      reason: 'an enrolment that never came back is exactly who this is for',
    );

    // A shorter cut catches more; the regular is still inside 30 days.
    expect((await listMembers(db, lapsedDays: 30)).length, 2);
    expect((await listMembers(db)).length, 3, reason: 'off by default');

    // Nothing was written: the same member stops being lapsed the moment a
    // fresh bill lands, with no status to update.
    await closeBill('s3', memberId: gone.id, daysAgo: 0);
    expect(
      (await listMembers(db, lapsedDays: 60)).map((m) => m.name),
      ['Never'],
    );
  });

  // ---------------------------------------------------------------------
  // A member's own history
  // ---------------------------------------------------------------------

  test('visit history is newest-first, lifetime, and keeps a walkout', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('old', memberId: m.id, daysAgo: 400, tableLabel: 'A1');
    await closeBill('mid', memberId: m.id, daysAgo: 40, kind: 'takeaway');
    await closeBill(
      'walk',
      memberId: m.id,
      daysAgo: 2,
      settled: 0,
      loss: 75000,
    );
    // Someone else's bill never appears on this member's file.
    final other = await enrol('Siti', '08120000002');
    await closeBill('theirs', memberId: other.id, daysAgo: 1);

    final rows = await memberVisits(db, m.id);
    expect(rows.map((v) => v.id), ['walk', 'mid', 'old']);
    expect(
      rows.last.tableLabel,
      'A1',
      reason: 'a bill older than any report window still belongs to the person',
    );
    expect(rows[1].kind, 'takeaway');
    // The walkout collected nothing. Read as a spend it would claim they paid.
    expect(rows.first.settledTotal, 0);
    expect(rows.first.lossAmount, 75000);

    // Growing limit, the cashier-history pattern: a page, then more of it.
    expect((await memberVisits(db, m.id, limit: 2)).map((v) => v.id), [
      'walk',
      'mid',
    ]);
  });
}
