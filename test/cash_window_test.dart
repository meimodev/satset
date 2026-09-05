// The [[Jendela kas]] and what leaves through it (ADR-0136).
//
// What is actually being pinned:
//
//   - a window narrows the *list* and never the balance — the failure this
//     feature exists to avoid;
//   - the server sums movement over the whole window, and a count's delta books
//     to variance rather than to outflow (ADR-0089, one window later);
//   - `admits` keeps a live row out of a closed window — a row from today
//     landing in a June ledger is the same lie as a windowed balance;
//   - a custom span's last day is whole, because the bound is half-open;
//   - the export's photo cap counts what it leaves behind, and the ledger itself
//     is never truncated by it.
//
// See docs/adr/0136-a-kas-export-is-a-fresh-window-and-the-balance-is-not-in-it.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:satset/core/export/cash_exporter.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/domain/models/cash_window.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/server/cash.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart' hide CashEntry;
import 'package:satset/server/routes/cash_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  group('CashWindow', () {
    final now = DateTime(2026, 9, 5, 14, 30);

    test('all admits everything', () {
      expect(CashWindow.all.admits(DateTime(2019, 1, 1)), isTrue);
      expect(CashWindow.all.admits(now), isTrue);
      expect(CashWindow.all.query, isEmpty);
    });

    test('a rolling window snaps to midnight and stays open at the top', () {
      final w = CashWindow.rolling(CashWindowKind.d30, now: now);
      expect(w.from, DateTime(2026, 8, 6));
      expect(w.to, isNull);
      // Open at the top is what lets a movement arriving over the socket land
      // in the window the reader is looking at.
      expect(w.admits(now.add(const Duration(hours: 9))), isTrue);
      expect(w.admits(DateTime(2026, 8, 5, 23, 59)), isFalse);
    });

    test('a rolling window is stable across calls with the same day', () {
      // Not merely tidy: a bound rebuilt from a moving clock is a new value on
      // every frame, and a provider keyed on it refetches forever.
      expect(
        CashWindow.rolling(CashWindowKind.d90, now: now),
        CashWindow.rolling(CashWindowKind.d90, now: now.add(const Duration(minutes: 5))),
      );
    });

    test('a custom span keeps its last day whole', () {
      final w = CashWindow.custom(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
      expect(w.from, DateTime(2026, 6, 1));
      expect(w.to, DateTime(2026, 7, 1));
      expect(w.admits(DateTime(2026, 6, 30, 23, 59)), isTrue);
      expect(w.admits(DateTime(2026, 7, 1)), isFalse);
      // And a live row stamped today stays out of it.
      expect(w.admits(now), isFalse);
    });
  });

  group('ledger and totals', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    final june = DateTime(2026, 6, 15, 10);
    final sept = DateTime(2026, 9, 2, 10);

    Future<void> seed() async {
      await topUpCash(db, boxId: 'box-main', amount: 500000, at: june);
      await spendCash(
        db,
        boxId: 'box-main',
        amount: 120000,
        categoryId: 'ingredients',
        at: june.add(const Duration(hours: 2)),
      );
      await topUpCash(db, boxId: 'box-main', amount: 200000, at: sept);
      await spendCash(
        db,
        boxId: 'box-main',
        amount: 50000,
        categoryId: 'transport',
        at: sept.add(const Duration(hours: 1)),
      );
    }

    test('a window narrows the list and leaves the balance alone', () async {
      await seed();
      final all = await cashLedger(db);
      expect(all.length, 4);

      final w = CashWindow.custom(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
      final windowed = await cashLedger(db, from: w.from, to: w.to);
      expect(windowed.length, 2);

      // The whole point: the balance is all-time no matter what the list shows.
      expect(await cashBalance(db, boxId: 'box-main'), 530000);
    });

    test('totals are the window\'s movement, not the page\'s', () async {
      await seed();
      final w = CashWindow.custom(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
      final t = await cashWindowTotals(db, from: w.from, to: w.to);
      expect(t['inflow'], 500000);
      expect(t['outflow'], 120000);
      expect(t['variance'], 0);

      // A page of one row must not change what the window says.
      final onePage = await cashLedger(db, limit: 1, from: w.from, to: w.to);
      expect(onePage.length, 1);
      expect(
        await cashWindowTotals(db, from: w.from, to: w.to),
        {'inflow': 500000, 'outflow': 120000, 'variance': 0},
      );
    });

    test('a count books to variance, never to outflow', () async {
      await topUpCash(db, boxId: 'box-main', amount: 300000, at: june);
      // Counter finds 280.000 in a box the ledger says holds 300.000.
      await countCash(db, boxId: 'box-main', counted: 280000, at: june);
      final t = await cashWindowTotals(db);
      expect(t['inflow'], 300000);
      // ADR-0089: a shortfall found at the count is a finding, not a purchase.
      expect(t['outflow'], 0);
      expect(t['variance'], -20000);
    });

    test('totals and the list are scoped to one box', () async {
      await createCashBox(db, name: 'Kas Dapur');
      final boxes = await cashBoxList(db);
      final dapur = boxes.firstWhere((b) => b.name == 'Kas Dapur');
      await topUpCash(db, boxId: 'box-main', amount: 100000, at: june);
      await topUpCash(db, boxId: dapur.id, amount: 70000, at: june);

      expect((await cashWindowTotals(db, boxId: dapur.id))['inflow'], 70000);
      expect((await cashLedger(db, boxId: dapur.id)).length, 1);
      // The venue arm still sees both.
      expect((await cashWindowTotals(db))['inflow'], 170000);
    });

    test('a null limit reads the whole window', () async {
      await seed();
      final unpaged = await cashLedger(db, limit: null);
      expect(unpaged.length, 4);
    });
  });

  group('export', () {
    CashEntry proofRow(String id) => CashEntry(
      id: id,
      boxId: 'box-main',
      kind: CashEntryKind.expense,
      delta: -1000,
      hasPhoto: true,
      at: DateTime(2026, 9, 1),
    );

    test('the photo cap counts what it leaves behind', () {
      final many = [for (var i = 0; i < kCashPhotoMax + 7; i++) proofRow('e$i')];
      expect(proofCandidates(many).length, kCashPhotoMax);
      expect(proofsOmitted(many), 7);
    });

    test('the cap trims plates, never rows', () {
      final many = [for (var i = 0; i < kCashPhotoMax + 7; i++) proofRow('e$i')];
      // The ledger the document prints is still every row handed to it — only
      // the appendix is bounded.
      expect(many.length, kCashPhotoMax + 7);
      expect(proofCandidates(many).length, lessThan(many.length));
    });

    test('the documents actually render, plates and all', () async {
      // A layout throw in the appendix is invisible until somebody exports, and
      // by then they are standing in front of an accountant. One real render.
      TestWidgetsFlutterBinding.ensureInitialized();
      final l = await AppL10n.delegate.load(const Locale('id'));
      final rows = [
        for (var i = 0; i < 9; i++) proofRow('e$i'),
        CashEntry(
          id: 'rev',
          boxId: 'box-main',
          kind: CashEntryKind.reversal,
          delta: 1000,
          reversesId: 'e0',
          at: DateTime(2026, 9, 2),
        ),
      ];
      String boxName(CashEntry e) => 'Kas Utama';
      String? categoryName(CashEntry e) => 'Sayur';
      const totals = CashWindowTotals(inflow: 5000, outflow: 9000);
      final w = CashWindow.custom(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      final csv = buildCashCsv(
        l,
        entries: rows,
        window: w,
        totals: totals,
        boxLabel: 'Kas Utama',
        boxName: boxName,
        categoryName: categoryName,
      );
      // A reversal is in the file — a ledger that hides them is not a ledger.
      // The reversal is in the file *and* findable: its own id is a column, so
      // the row it undoes can be looked up.
      expect(csv, contains('rev'));
      expect(csv, contains('e0'));
      expect(csv.split('\r\n').length, greaterThan(rows.length));

      final pdf = await buildCashPdf(
        l,
        entries: rows,
        window: w,
        totals: totals,
        boxLabel: 'Kas Utama',
        boxName: boxName,
        categoryName: categoryName,
        // A null-bytes plate is the failed-fetch path, which must render.
        proofs: [
          for (var i = 0; i < 6; i++)
            CashProof(index: i + 1, entry: rows[i], bytes: null),
        ],
        omitted: 3,
      );
      expect(pdf.length, greaterThan(1000));
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    });

    test('rows without a proof are never fetched for', () {
      final mixed = [
        proofRow('a'),
        CashEntry(
          id: 'b',
          boxId: 'box-main',
          kind: CashEntryKind.topUp,
          delta: 5000,
          at: DateTime(2026, 9, 1),
        ),
      ];
      expect(proofCandidates(mixed).map((e) => e.id), ['a']);
      expect(proofsOmitted(mixed), 0);
    });
  });

  group('GET /cash', () {
    late AppDatabase db;
    final hub = WsHub();
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Response> get(TestCaller caller, String query) {
      final router = cashRoutes(db, hub, caller.auth);
      return router.call(
        Request(
          'GET',
          Uri.parse('http://x/cash$query'),
          headers: caller.headers,
        ),
      );
    }

    test('the response carries the window totals beside the all-time balance',
        () async {
      final caller = await signInForTest(db);
      await topUpCash(db, boxId: 'box-main', amount: 400000,
          at: DateTime(2026, 6, 10));
      await spendCash(db, boxId: 'box-main', amount: 25000,
          categoryId: 'transport', at: DateTime(2026, 9, 1));

      final res = await get(
        caller,
        '?from=2026-06-01T00:00:00.000&to=2026-07-01T00:00:00.000',
      );
      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect((body['entries'] as List).length, 1);
      // The window's movement...
      expect(body['totals'], {'inflow': 400000, 'outflow': 0, 'variance': 0});
      // ...and the balance that ignores it. This pairing is the ADR.
      expect(body['balance'], 375000);
    });

    test('an unpaged read past the cap refuses rather than truncating',
        () async {
      final caller = await signInForTest(db);
      // One row over the ceiling. Written straight to the table: the point is
      // the route's arithmetic, not the writer's.
      await db.batch((b) {
        b.insertAll(db.cashEntries, [
          for (var i = 0; i <= kCashWindowMax; i++)
            CashEntriesCompanion.insert(
              id: 'row-$i',
              boxId: const Value('box-main'),
              kind: CashEntryKind.topUp.name,
              delta: 1,
              at: DateTime(2026, 9, 1).add(Duration(seconds: i)),
            ),
        ]);
      });

      final res = await get(caller, '?limit=all');
      expect(res.statusCode, 400);
      expect(
        jsonDecode(await res.readAsString())['code'],
        'window_too_large',
      );
    });

    test('a viewReports reader may export what it may read', () async {
      final caller = await signInForTest(db, caps: {Capability.viewReports});
      final res = await get(caller, '?limit=all');
      expect(res.statusCode, 200);
    });
  });
}
