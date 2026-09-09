import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:satset/core/export/order_history_exporter.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reports_routes.dart';

import 'support/route_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TestCaller caller;
  final at = DateTime(2026, 9, 5, 12).toUtc();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db, userId: 'visit-waiter');
    await signInForTest(db, userId: 'item-orderer');
    await db
        .into(db.zones)
        .insert(ZonesCompanion.insert(id: 'z', name: 'Terrace', short: 'T'));
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm',
            name: 'Ani',
            phone: '08123456789',
            code: const Value('PRIVATE-CODE'),
            joinedAt: at,
          ),
        );
    await db
        .into(db.tableSessions)
        .insert(
          TableSessionsCompanion.insert(
            id: 's',
            tableId: 't',
            tableLabel: const Value('A1'),
            zoneId: 'z',
            closedAt: at,
            actorUserId: const Value('visit-waiter'),
            memberId: const Value('payer-is-not-consumer'),
            memberAttributionVersion: const Value(2),
            subtotal: const Value(40000),
            discountAmount: const Value(5350),
            settledTotal: const Value(34650),
          ),
        );
    for (final (id, price, qty, status, member) in [
      ('tea', 10000, 2, 'served', 'm'),
      ('cake', 20000, 1, 'served', null),
      ('void', 5000, 1, 'voided', 'deleted-member'),
    ]) {
      await db
          .into(db.tableSessionTickets)
          .insert(
            TableSessionTicketsCompanion.insert(
              id: id,
              sessionId: 's',
              ticketId: id,
              itemId: id,
              name: id,
              variantName: Value(id == 'tea' ? 'Large' : ''),
              course: 'DO-NOT-EXPORT-COURSE',
              qty: Value(qty),
              price: price,
              status: status,
              sentAt: at,
              memberId: Value(member),
              createdByUserId: Value(
                id == 'tea' ? 'item-orderer' : 'visit-waiter',
              ),
              note: Value(id == 'tea' ? 'No sugar, please\nLess ice' : null),
              modifiersJson: const Value('[{"label":"Extra lemon"}]'),
              voidReasonCode: Value(id == 'void' ? 'other' : null),
            ),
          );
    }
    for (final (id, subtotal, discount, total) in [
      ('r1', 28500, 4350, 25650),
      ('r2', 10000, 1000, 9000),
    ]) {
      await db
          .into(db.tableSessionReceipts)
          .insert(
            TableSessionReceiptsCompanion.insert(
              id: id,
              sessionId: 's',
              receiptId: id,
              label: Value(id),
              subtotal: Value(subtotal),
              discountAmount: Value(discount),
              total: Value(total),
              status: const Value('paid'),
            ),
          );
    }
    for (final (receipt, ticket) in [
      ('r1', 'tea'),
      ('r1', 'cake'),
      ('r2', 'tea'),
    ]) {
      await db
          .into(db.tableSessionReceiptLines)
          .insert(
            TableSessionReceiptLinesCompanion.insert(
              id: '$receipt-$ticket',
              sessionId: 's',
              receiptId: receipt,
              ticketId: ticket,
            ),
          );
    }
    for (final (id, receipt, ticket, amount, value) in [
      ('Member tier', 'r1', 'tea', 1000, 1000),
      ('Promo', 'r1', 'tea', 500, 500),
      ('Whole bill', null, null, 3850, 1000),
    ]) {
      await db
          .into(db.tableSessionDiscounts)
          .insert(
            TableSessionDiscountsCompanion.insert(
              id: id,
              sessionId: 's',
              receiptId: Value(receipt),
              ticketId: Value(ticket),
              name: id,
              kind: 'percent',
              value: Value(value),
              amount: Value(amount),
              at: at,
            ),
          );
    }
    await db
        .into(db.tableSessionPayments)
        .insert(
          TableSessionPaymentsCompanion.insert(
            id: 'payment',
            sessionId: 's',
            receiptId: 'r1',
            method: 'tunai',
            amount: 25650,
            cashierUserId: const Value('visit-waiter'),
            at: at,
          ),
        );
  });
  tearDown(() => db.close());

  Future<OrderHistory> history() async {
    final res = await reportsRoutes(db, caller.auth).call(
      Request(
        'GET',
        Uri.parse(
          'http://x/orders/history?range=custom&from=2026-09-04&to=2026-09-06',
        ),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 200);
    return OrderHistory.fromJson(
      jsonDecode(await res.readAsString()) as Map<String, dynamic>,
      ReportRange.custom,
    );
  }

  test(
    'history carries item identity and reconciled split-receipt discounts into both exports',
    () async {
      final h = await history();
      final visit = h.visits.single;
      final tea = visit.lines.firstWhere((l) => l.name == 'tea');
      final cake = visit.lines.firstWhere((l) => l.name == 'cake');
      expect(visit.zoneName, 'Terrace');
      expect(visit.waiterName, 'visit-waiter');
      expect(tea.ordererName, 'item-orderer');
      expect(tea.memberName, 'Ani');
      expect(cake.memberId, isNull);
      expect(tea.note, 'No sugar, please\nLess ice');
      expect(
        (tea.directDiscount, tea.sharedDiscount, tea.afterDiscount),
        (1500, 1850, 16650),
      );
      expect(
        (cake.directDiscount, cake.sharedDiscount, cake.afterDiscount),
        (0, 2000, 18000),
      );
      expect(
        visit.lines.fold<int>(0, (sum, l) => sum + l.afterDiscount!),
        h.net,
      );
      expect(visit.unallocatedDiscount, isNull);
      expect(
        tea.discounts.map((d) => d.name),
        containsAll(['Member tier', 'Promo', 'Whole bill']),
      );
      for (final locale in ['en', 'id']) {
        final l = lookupAppL10n(Locale(locale));
        final csv = buildOrderHistoryCsv(l, h, ReportRange.custom);
        for (final value in [
          'Terrace',
          'item-orderer',
          'visit-waiter',
          'Ani',
          'tea (Large)',
          'No sugar, please\nLess ice',
          'Extra lemon',
          'Whole bill',
          'Rp. 16.650',
          l.expUnassignedMember,
          l.expUnavailable,
          l.expSettledTotal,
        ]) {
          expect(csv, contains(value));
        }
        for (final removed in [
          'DO-NOT-EXPORT-COURSE',
          'PRIVATE-CODE',
          '08123456789',
          l.expColVariant,
          l.expColCourse,
        ]) {
          expect(csv, isNot(contains(removed)));
        }
        final pdf = await buildOrderHistoryPdf(l, h, ReportRange.custom);
        expect(ascii.decode(pdf.take(4).toList()), '%PDF');
        // Retain reviewable samples only when explicitly requested by the test run.
        final preview = Platform.environment['ORDER_EXPORT_PREVIEW_DIR'];
        if (preview != null) {
          await Directory(preview).create(recursive: true);
          await File('$preview/orders-$locale.pdf').writeAsBytes(pdf);
          await File('$preview/orders-$locale.csv').writeAsString(csv);
        }
      }
    },
  );

  test('receipt-wide discount rounding preserves every rupiah', () async {
    await db
        .into(db.tableSessionDiscounts)
        .insert(
          TableSessionDiscountsCompanion.insert(
            id: 'Receipt promo',
            sessionId: 's',
            receiptId: const Value('r1'),
            name: 'Receipt promo',
            kind: 'fixed',
            value: const Value(1),
            amount: const Value(1),
            at: at,
          ),
        );
    await (db.update(
      db.tableSessionReceipts,
    )..where((r) => r.receiptId.equals('r1'))).write(
      const TableSessionReceiptsCompanion(
        discountAmount: Value(4351),
        total: Value(25649),
      ),
    );
    await db
        .update(db.tableSessions)
        .write(
          const TableSessionsCompanion(
            discountAmount: Value(5351),
            settledTotal: Value(34649),
          ),
        );
    final visit = (await history()).visits.single;
    expect(
      visit.lines.firstWhere((l) => l.name == 'cake').sharedDiscount,
      2001,
    );
    expect(visit.lines.firstWhere((l) => l.name == 'tea').sharedDiscount, 1850);
    expect(visit.lines.fold<int>(0, (sum, l) => sum + l.afterDiscount!), 34649);
    expect(
      visit.lines
          .firstWhere((l) => l.name == 'tea')
          .discounts
          .map((d) => d.name),
      contains('Receipt promo'),
    );
  });

  test(
    'undiscounted legacy visits need no reconstructed receipt allocation',
    () async {
      await db.delete(db.tableSessionReceiptLines).go();
      await db.delete(db.tableSessionReceipts).go();
      await db.delete(db.tableSessionDiscounts).go();
      await db
          .update(db.tableSessions)
          .write(
            const TableSessionsCompanion(
              discountAmount: Value(0),
              settledTotal: Value(40000),
            ),
          );
      final visit = (await history()).visits.single;
      expect(visit.unallocatedDiscount, isNull);
      expect(
        visit.lines.every(
          (l) => l.directDiscount == 0 && l.sharedDiscount == 0,
        ),
        isTrue,
      );
      expect(
        visit.lines.fold<int>(0, (sum, l) => sum + l.afterDiscount!),
        40000,
      );
      // Orphan payments still survive in the synthetic receipt.
      expect(visit.receipts.single.payments.single.paymentId, 'payment');
    },
  );

  test('stacked offers cap once against the receipt-owned units', () async {
    await (db.update(
      db.tableSessionDiscounts,
    )..where((d) => d.id.equals('Promo'))).write(
      const TableSessionDiscountsCompanion(
        value: Value(10000),
        amount: Value(10000),
      ),
    );
    await (db.update(
      db.tableSessionReceipts,
    )..where((r) => r.receiptId.equals('r1'))).write(
      const TableSessionReceiptsCompanion(
        subtotal: Value(20000),
        discountAmount: Value(12000),
        total: Value(18000),
      ),
    );
    await db
        .update(db.tableSessions)
        .write(
          const TableSessionsCompanion(
            discountAmount: Value(13000),
            settledTotal: Value(27000),
          ),
        );
    final visit = (await history()).visits.single;
    final tea = visit.lines.firstWhere((l) => l.name == 'tea');
    expect(tea.directDiscount, 10000);
    expect(tea.sharedDiscount, 1000);
    expect(tea.afterDiscount, 9000);
    expect(visit.lines.fold<int>(0, (sum, l) => sum + l.afterDiscount!), 27000);
  });

  test(
    'missing historical assignments preserve totals without inventing item shares',
    () async {
      await db.delete(db.tableSessionReceiptLines).go();
      final visit = (await history()).visits.single;
      expect(visit.unallocatedDiscount, 5350);
      expect(
        visit.lines
            .where((l) => !l.isVoided)
            .every((l) => l.afterDiscount == null),
        isTrue,
      );
      expect(visit.lines.singleWhere((l) => l.isVoided).afterDiscount, 0);
      expect(
        visit.receipts.fold<int>(0, (sum, r) => sum + r.discountAmount),
        5350,
      );
      final csv = buildOrderHistoryCsv(
        lookupAppL10n(const Locale('en')),
        await history(),
        ReportRange.custom,
      );
      expect(csv, contains('Unallocated discount'));
      expect(csv, contains('Whole bill'));
    },
  );

  test(
    'overassigned quantities and amount receipts do not invent item shares',
    () async {
      await (db.update(db.tableSessionReceiptLines)
            ..where((a) => a.id.equals('r2-tea')))
          .write(const TableSessionReceiptLinesCompanion(qtyUnits: Value(2)));
      expect((await history()).visits.single.unallocatedDiscount, 5350);
      await (db.update(db.tableSessionReceiptLines)
            ..where((a) => a.id.equals('r2-tea')))
          .write(const TableSessionReceiptLinesCompanion(qtyUnits: Value(1)));
      await (db.update(db.tableSessionReceipts)
            ..where((r) => r.receiptId.equals('r2')))
          .write(const TableSessionReceiptsCompanion(mode: Value('even')));
      expect((await history()).visits.single.unallocatedDiscount, 5350);
    },
  );

  test(
    'unavailable identities stay distinct from unassigned members and takeaway has no zone',
    () async {
      await db.delete(db.members).go();
      await db.delete(db.zones).go();
      var h = await history();
      expect(h.visits.single.zoneName, isNull);
      var csv = buildOrderHistoryCsv(
        lookupAppL10n(const Locale('en')),
        h,
        ReportRange.custom,
      );
      expect(csv, contains('Unassigned'));
      expect(csv, contains('Unavailable'));
      expect(csv, isNot(contains('payer-is-not-consumer')));
      await db
          .update(db.tableSessions)
          .write(
            const TableSessionsCompanion(
              kind: Value('takeaway'),
              memberAttributionVersion: Value(null),
            ),
          );
      h = await history();
      expect(h.visits.single.zoneName, isNull);
      csv = buildOrderHistoryCsv(
        lookupAppL10n(const Locale('en')),
        h,
        ReportRange.custom,
      );
      expect(csv, isNot(contains('Unassigned')));
    },
  );
}
