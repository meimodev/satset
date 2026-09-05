// The [[Antrean setelmen]]'s own rules (ADR-0123): what a chain does when the
// host refuses, and — the one that shipped broken — that a receipt minted
// *into the journal* is findable by the payment queued behind it.
//
// The settle pane mints and pays in one gesture (ADR-0067). On a device that
// went dark, the receipt a captured payment names exists in no cached bill yet;
// resolving it only against the cache stranded the payment, the till fell
// through to a network call that could not succeed, and the guest's cash landed
// nowhere. That is what the first group pins.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/domain/models/settlement_event.dart';

void main() {
  late ClientDb db;
  late SettlementJournal journal;
  late List<SettlementEvent> sent;
  late Map<String, String> refuse;

  SettlementJournal build() => SettlementJournal(
    db: db,
    send: (e) async {
      final code = refuse[e.id];
      if (code != null) throw SettlementRefused(code);
      sent.add(e);
    },
  );

  setUp(() async {
    db = ClientDb.memory();
    sent = [];
    refuse = {};
    journal = build();
  });
  tearDown(() => db.close());

  group('a receipt minted into the journal', () {
    test('is found by the payment queued behind it', () async {
      final mint = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.mintReceipt,
        payload: const {'mode': 'itemized', 'assignAll': true},
      );
      // No cached bill at all: the till never opened this visit online, which
      // is the ordinary case for a bill settled from the payable list.
      expect(await journal.visitOfReceipt(mint.id), 'v1');
    });

    test('so is one of an even split\'s shares', () async {
      await journal.append(
        visitId: 'v2',
        kind: SettlementEventKind.splitEven,
        payload: const {
          'n': 3,
          'ids': ['s1', 's2', 's3'],
        },
      );
      expect(await journal.visitOfReceipt('s2'), 'v2');
    });

    test('a receipt nobody minted or cached is unknown', () async {
      expect(await journal.visitOfReceipt('nope'), isNull);
    });
  });

  group('a chain', () {
    test('halts on the first refusal and parks the rest untried', () async {
      final a = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.mintReceipt,
        payload: const {},
      );
      final b = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 80000},
      );
      final c = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.refund,
        payload: const {'receiptId': 'r1', 'amount': 80000},
      );
      refuse[b.id] = 'bill_closed';

      final report = await journal.drain();
      expect(sent.map((e) => e.id), [a.id]);
      // The refund must never land on its own: the payment it unwinds was
      // refused, so unwinding it would hand back money nobody took.
      expect(sent.any((e) => e.id == c.id), isFalse);

      final chain = report.chains.single;
      expect(chain.refused?.id, b.id);
      expect(chain.code, 'bill_closed');
      expect(chain.strandedAmount, 80000);
      expect(journal.state.parkedVisits, {'v1'});
    });

    test('other visits keep draining past one refusal', () async {
      final bad = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 10000},
      );
      final good = await journal.append(
        visitId: 'v2',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r2', 'amount': 20000},
      );
      refuse[bad.id] = 'visit_changed';

      await journal.drain();
      expect(sent.map((e) => e.id), [good.id]);
      expect(journal.state.parkedVisits, {'v1'});
      expect(journal.state.pendingVisits, {'v1'});
    });

    // The bug the device rig found: `pendingVisits` answers "which visits are
    // locally authoritative", and ADR-0129 keeps member- and venue-scope acts
    // out of it on purpose. A drain gated on that set never runs on a device
    // whose only captured act is an attach or an enrolment, and the guest's
    // membership sits in the journal forever.
    test('a member-scope-only journal still drains', () async {
      await journal.append(
        visitId: 'v9',
        kind: SettlementEventKind.attachMember,
        payload: const {'memberId': 'm1'},
      );
      await journal.append(
        visitId: kVenueScopeVisitId,
        kind: SettlementEventKind.enrolMember,
        payload: const {'name': 'Adi', 'phone': '0811'},
      );

      expect(
        journal.state.pendingVisits,
        isEmpty,
        reason: 'neither act confers local authority (ADR-0129)',
      );
      expect(
        await journal.pendingVisitIds(),
        isNotEmpty,
        reason: 'but both are queued, and the drain must ask the journal',
      );

      final report = await journal.drain();
      expect(sent.length, 2);
      expect(report.failures, isEmpty);
      expect(await journal.eventsFor('v9'), isEmpty);
    });

    // The refusal sheet is fed by an in-memory report the drain sets once. A
    // refusal that lands while /kasir is not mounted, or an app restart after
    // one, leaves the cash parked and nothing on screen — so the surface has
    // to be able to re-read what parked.
    test('a parked chain is readable back off the journal', () async {
      final bad = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 135000},
      );
      await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.closeBill,
        payload: const {},
      );
      refuse[bad.id] = 'overpayment';

      await journal.drain();

      final chains = await journal.parkedChains();
      expect(chains, hasLength(1));
      expect(chains.single.visitId, 'v1');
      expect(chains.single.code, 'overpayment');
      expect(chains.single.refused!.id, bad.id);
      expect(
        chains.single.strandedAmount,
        135000,
        reason: 'the cash is in the drawer and the sheet must name it',
      );

      await journal.acknowledge('v1');
      expect(await journal.parkedChains(), isEmpty);
    });

    test('a clean drain leaves nothing behind', () async {
      await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.mintReceipt,
        payload: const {},
      );
      await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 5000},
      );
      final report = await journal.drain();
      expect(report.failures, isEmpty);
      expect(journal.state.pendingVisits, isEmpty);
      expect(await journal.eventsFor('v1'), isEmpty);
    });
  });

  // The bill a drained visit falls back on next time the host goes away.
  //
  // Shipped broken: the reconnect sweep skipped the visit because its journal
  // was still draining, the drain's own refresh moments later found the sweep
  // clock fresh and did nothing, and the cache kept was the one taken *before*
  // the settlement it had just sent. Going dark again showed the cashier an
  // unpaid bill the host knew was half paid — an invitation to collect twice.
  group('the prefetch sweep', () {
    final now = DateTime.utc(2026, 8, 30, 23, 0);

    test('re-pulls a visit whose chain just drained', () {
      expect(
        SettlementRepository.shouldRefetchBill(
          // Cached before the offline settle, seven minutes ago.
          fetchedAt: now.subtract(const Duration(minutes: 7)),
          now: now,
          // Drained clean, so no longer local-authoritative.
          local: false,
        ),
        isTrue,
      );
    });

    test('leaves a local-authoritative visit alone', () {
      expect(
        SettlementRepository.shouldRefetchBill(
          fetchedAt: now.subtract(const Duration(minutes: 7)),
          now: now,
          local: true,
        ),
        isFalse,
      );
    });

    test('skipping one visit does not throttle it afterwards', () {
      // The whole bug in one line: the skip above must not be recorded as a
      // sweep, so the very next call still refetches.
      expect(
        SettlementRepository.shouldRefetchBill(
          fetchedAt: now.subtract(const Duration(minutes: 7)),
          now: now,
          local: false,
        ),
        isTrue,
      );
    });

    test('a fresh cache is left alone', () {
      expect(
        SettlementRepository.shouldRefetchBill(
          fetchedAt: now.subtract(const Duration(seconds: 30)),
          now: now,
          local: false,
        ),
        isFalse,
      );
    });

    test('a visit with no cache at all is pulled', () {
      expect(
        SettlementRepository.shouldRefetchBill(
          fetchedAt: null,
          now: now,
          local: false,
        ),
        isTrue,
      );
    });
  });

  // Without a cached list a cold boot with no host renders an empty `/kasir`:
  // every bill cached, none of them reachable, and a strip saying money is
  // still queued.
  group('the cached payable list', () {
    test('round-trips the host\'s own wire shape', () async {
      final raw = [
        {'visitId': 'v1', 'tableLabel': 'D1', 'total': 40000},
        {'visitId': 'v2', 'tableLabel': 'D2', 'total': 15000},
      ];
      await journal.cachePayable(raw);
      expect(await journal.cachedPayable(), raw);
    });

    test('is replaced whole, never merged', () async {
      await journal.cachePayable([
        {'visitId': 'v1'},
        {'visitId': 'v2'},
      ]);
      // v1 settled and left the host's list; it must leave ours too.
      await journal.cachePayable([
        {'visitId': 'v2'},
      ]);
      expect(await journal.cachedPayable(), [
        {'visitId': 'v2'},
      ]);
    });

    test('is null before anything has been cached', () async {
      expect(await journal.cachedPayable(), isNull);
    });
  });

  test('a full visit refuses rather than dropping the act', () async {
    for (var i = 0; i < SettlementJournal.maxPerVisit; i++) {
      await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: {'receiptId': 'r1', 'amount': i},
      );
    }
    expect(
      () => journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 1},
      ),
      throwsA(isA<SettlementJournalFull>()),
    );
  });
}
