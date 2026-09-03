// The member report (§Laporan pelanggan): the ranked list, and one member's own
// bills and product rollup.
//
// What is being pinned:
//
//   - a member's products are the units attributed to them the ADR-0118 way —
//     a named receipt's lines are that member's, everything else on the bill is
//     the owner's — so a split table does not credit one guest with the whole
//     order;
//   - a void is not a purchase: it leaves the rollup and the per-bill count;
//   - an [[Amount receipt]] claims money and owns no lines, so a member can
//     have spend and no items, and `untrackedSpend` names that gap rather than
//     leaving the two totals silently disagreeing;
//   - the history opens for a member who has since been deleted — the trade is
//     the venue's record and survives the person (ADR-0092);
//   - the ranked list carries a bigger cap than the venue block's, names its
//     own tail, and counts who came back against who came once.
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
  final from = now.subtract(const Duration(days: 365));
  final to = now.add(const Duration(days: 1));

  Future<Member> enrol(String name, String phone) =>
      createMember(db, name: name, phone: phone);

  Future<void> closeBill(
    String id, {
    String? memberId,
    int daysAgo = 1,
    int settled = 100000,
    String? tableLabel,
    int? memberAttributionVersion,
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
          memberAttributionVersion: Value(memberAttributionVersion),
          settledTotal: Value(settled),
          kind: const Value('dineIn'),
        ),
      );

  /// One snapshot line on [sessionId]. [ticketId] is the live id the receipt
  /// assignments point at.
  Future<void> line(
    String sessionId,
    String ticketId, {
    required String itemId,
    required String name,
    required int qty,
    required int price,
    String status = 'served',
    String? voidReasonCode,
    String? memberId,
  }) => db
      .into(db.tableSessionTickets)
      .insert(
        TableSessionTicketsCompanion.insert(
          id: 'snap-$sessionId-$ticketId',
          sessionId: sessionId,
          ticketId: ticketId,
          memberId: Value(memberId),
          itemId: itemId,
          name: name,
          course: 'mains',
          qty: Value(qty),
          price: price,
          status: status,
          voidReasonCode: Value(voidReasonCode),
          sentAt: now.subtract(const Duration(days: 1)),
        ),
      );

  Future<void> receipt(
    String sessionId,
    String receiptId, {
    String? memberId,
    String mode = 'itemized',
    int total = 0,
  }) => db
      .into(db.tableSessionReceipts)
      .insert(
        TableSessionReceiptsCompanion.insert(
          id: 'rsnap-$sessionId-$receiptId',
          sessionId: sessionId,
          receiptId: receiptId,
          mode: Value(mode),
          total: Value(total),
          memberId: Value(memberId),
        ),
      );

  Future<void> assign(
    String sessionId,
    String receiptId,
    String ticketId,
    int units,
  ) => db
      .into(db.tableSessionReceiptLines)
      .insert(
        TableSessionReceiptLinesCompanion.insert(
          id: 'l-$sessionId-$receiptId-$ticketId',
          sessionId: sessionId,
          receiptId: receiptId,
          ticketId: ticketId,
          qtyUnits: Value(units),
        ),
      );

  Future<Map<String, dynamic>> history(String id) =>
      memberHistory(db, id, from: from, to: to);

  // ---------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------

  test('a whole bill\'s lines are the owner\'s', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('s1', memberId: m.id, settled: 90000);
    await line(
      's1',
      'tk1',
      itemId: 'i-nasi',
      name: 'Nasi Goreng',
      qty: 2,
      price: 30000,
    );
    await line(
      's1',
      'tk2',
      itemId: 'i-teh',
      name: 'Es Teh',
      qty: 3,
      price: 10000,
    );

    final h = await history(m.id);
    final products = (h['products'] as List).cast<Map<String, dynamic>>();
    expect(products.length, 2);
    // Ranked by quantity: three glasses beat two plates.
    expect(products.first['itemId'], 'i-teh');
    expect(products.first['qty'], 3);
    expect(products.first['spend'], 30000);
    expect(products[1]['qty'], 2);
    expect(products[1]['spend'], 60000);
    expect(h['units'], 5);
    expect(h['spend'], 90000, reason: 'the owner takes the whole bill');
    expect(h['untrackedSpend'], 0);
  });

  test('ticket attribution credits only the ticket owner', () async {
    final ani = await enrol('Ani', '08120000011');
    final budi = await enrol('Budi', '08120000012');
    await closeBill('s-ticket', memberAttributionVersion: 2, settled: 60000);
    await line(
      's-ticket',
      'tk-ani',
      itemId: 'i-nasi',
      name: 'Nasi',
      qty: 1,
      price: 30000,
      memberId: ani.id,
    );
    await line(
      's-ticket',
      'tk-budi',
      itemId: 'i-teh',
      name: 'Teh',
      qty: 2,
      price: 15000,
      memberId: budi.id,
    );

    final aniHistory = await history(ani.id);
    final budiHistory = await history(budi.id);
    expect((aniHistory['products'] as List).single['name'], 'Nasi');
    expect((budiHistory['products'] as List).single['name'], 'Teh');
  });

  test(
    'a named receipt takes its own lines, the owner takes the rest',
    () async {
      final owner = await enrol('Budi', '08120000001');
      final friend = await enrol('Sari', '08120000002');
      await closeBill('s1', memberId: owner.id, settled: 100000);
      // Four plates on one ticket; the friend's receipt claims one of them.
      await line(
        's1',
        'tk1',
        itemId: 'i-nasi',
        name: 'Nasi Goreng',
        qty: 4,
        price: 25000,
      );
      await receipt('s1', 'r-friend', memberId: friend.id, total: 25000);
      await assign('s1', 'r-friend', 'tk1', 1);

      final theirs = await history(friend.id);
      expect(
        (theirs['products'] as List).first['qty'],
        1,
        reason: 'a share is one plate, not the table',
      );
      expect(theirs['spend'], 25000);

      final ownersRead = await history(owner.id);
      expect(
        (ownersRead['products'] as List).first['qty'],
        3,
        reason: 'the owner takes what is left, never the whole ticket again',
      );
      expect(ownersRead['spend'], 75000, reason: '100k less the 25k claimed');

      // The parts add back to the bill — the subtraction cannot lose a plate or
      // a rupiah.
      expect(theirs['units'] + ownersRead['units'], 4);
      expect(theirs['spend'] + ownersRead['spend'], 100000);
    },
  );

  test('a void is not a purchase', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('s1', memberId: m.id, settled: 30000);
    await line(
      's1',
      'tk1',
      itemId: 'i-nasi',
      name: 'Nasi Goreng',
      qty: 1,
      price: 30000,
    );
    await line(
      's1',
      'tk2',
      itemId: 'i-ayam',
      name: 'Ayam Bakar',
      qty: 1,
      price: 40000,
      status: 'voided',
      voidReasonCode: 'wrongItem',
    );

    final h = await history(m.id);
    final products = (h['products'] as List).cast<Map<String, dynamic>>();
    expect(products.length, 1);
    expect(products.single['itemId'], 'i-nasi');
    expect(h['units'], 1);
    // The bill still counts, and its money is still theirs — only the line goes.
    expect(h['visits'], 1);
    expect(h['spend'], 30000);
  });

  test('an amount receipt spends money and buys no items', () async {
    final owner = await enrol('Budi', '08120000001');
    final friend = await enrol('Sari', '08120000002');
    // Budi's table, split evenly: Sari's share claims money and owns no lines.
    await closeBill('s1', memberId: owner.id, settled: 100000);
    await line(
      's1',
      'tk1',
      itemId: 'i-nasi',
      name: 'Nasi Goreng',
      qty: 2,
      price: 50000,
    );
    await receipt(
      's1',
      'r-sari',
      memberId: friend.id,
      mode: 'even',
      total: 50000,
    );

    final h = await history(friend.id);
    expect(h['spend'], 50000);
    expect(h['units'], 0);
    expect((h['products'] as List), isEmpty);
    expect(
      h['untrackedSpend'],
      50000,
      reason: 'the gap between spend and products is named, not silent',
    );
  });

  // ---------------------------------------------------------------------
  // The record outliving the person
  // ---------------------------------------------------------------------

  test('a deleted member still has a history', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('s1', memberId: m.id, settled: 60000);
    await line(
      's1',
      'tk1',
      itemId: 'i-nasi',
      name: 'Nasi Goreng',
      qty: 2,
      price: 30000,
    );
    await deleteMember(db, id: m.id);

    // The directory row is gone — `GET /members/<id>` would 404 here.
    expect(await getMember(db, m.id), isNull);

    final h = await history(m.id);
    expect(h['visits'], 1);
    expect(h['spend'], 60000);
    expect((h['products'] as List).single['qty'], 2);
  });

  test('a window excludes a bill outside it', () async {
    final m = await enrol('Budi', '08120000001');
    await closeBill('s-old', memberId: m.id, daysAgo: 200, settled: 50000);
    await closeBill('s-new', memberId: m.id, daysAgo: 2, settled: 70000);
    await line(
      's-old',
      'tk1',
      itemId: 'i-nasi',
      name: 'Nasi Goreng',
      qty: 1,
      price: 50000,
    );
    await line(
      's-new',
      'tk2',
      itemId: 'i-ayam',
      name: 'Ayam Bakar',
      qty: 1,
      price: 70000,
    );

    final wide = await history(m.id);
    expect(wide['visits'], 2);

    final narrow = await memberHistory(
      db,
      m.id,
      from: now.subtract(const Duration(days: 30)),
      to: to,
    );
    expect(narrow['visits'], 1);
    expect(narrow['spend'], 70000);
    expect((narrow['products'] as List).single['itemId'], 'i-ayam');
  });

  // ---------------------------------------------------------------------
  // The ranked list
  // ---------------------------------------------------------------------

  test(
    'the list reaches past the venue block\'s cap and names its tail',
    () async {
      // 520 members who each traded once — past the 500 this report carries, and
      // well past the 100 the Keanggotaan block does.
      for (var i = 0; i < 520; i++) {
        final m = await enrol('M$i', '0812${i.toString().padLeft(7, '0')}');
        await closeBill('s$i', memberId: m.id, settled: 1000 + i);
      }

      final r = await memberTradeReport(db, from: from, to: to);
      final rows = (r['members'] as List).cast<Map<String, dynamic>>();
      expect(rows.length, 500);
      expect(r['membersTruncated'], 20);
      // The venue block travels in the same payload and keeps its own, smaller cap.
      expect((r['top'] as List).length, 100);
      expect(rows.first['name'], 'M519', reason: 'spend desc');
      expect(rows.first['phone'], isNotNull, reason: 'the list is searchable');
      expect(rows.first['lastVisitAt'], isNotNull);
    },
  );

  test(
    'returning is counted against once-only, and idle against the books',
    () async {
      final twice = await enrol('Budi', '08120000001');
      final once = await enrol('Sari', '08120000002');
      await enrol('Tono', '08120000003'); // enrolled, never came
      await closeBill('s1', memberId: twice.id, daysAgo: 3, settled: 40000);
      await closeBill('s2', memberId: twice.id, daysAgo: 1, settled: 60000);
      await closeBill('s3', memberId: once.id, daysAgo: 2, settled: 50000);

      final r = await memberTradeReport(db, from: from, to: to);
      expect(r['activeMembers'], 2);
      expect(r['returningMembers'], 1);
      expect(r['enrolledTotal'], 3);
      expect(
        r['idleMembers'],
        1,
        reason: 'Tono is on the books and did not come',
      );
      expect(r['earliestClosedAt'], isNotNull);

      final budi = (r['members'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['memberId'] == twice.id);
      expect(budi['visits'], 2);
      expect(budi['spend'], 100000);
    },
  );

  test(
    'the overview and the list divide the same split bill the same way',
    () async {
      final owner = await enrol('Budi', '08120000001');
      final friend = await enrol('Sari', '08120000002');
      await closeBill('s1', memberId: owner.id, settled: 120000);
      await receipt('s1', 'r-sari', memberId: friend.id, total: 45000);

      final r = await memberTradeReport(db, from: from, to: to);
      final rows = (r['members'] as List).cast<Map<String, dynamic>>();
      final byId = {for (final m in rows) m['memberId'] as String: m};
      expect(byId[friend.id]!['spend'], 45000);
      expect(byId[owner.id]!['spend'], 75000);
      // The bill itself is still one bill, counted on whoever held it.
      expect(r['memberBills'], 1);
      expect(r['memberNet'], 120000);
      expect(r['splitBills'], 1);
      // And the two halves of the payload agree, because they walk once.
      final top = (r['top'] as List).cast<Map<String, dynamic>>();
      expect(
        {for (final m in top) m['memberId']: m['spend']},
        {for (final m in rows) m['memberId']: m['spend']},
      );
    },
  );
}
