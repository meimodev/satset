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
import 'package:drift/drift.dart' show Value;

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
    loadBill: (visitId, _) async => {'visitId': visitId, 'receipts': []},
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

  test(
    'captured authorization stays with the event after profile refresh',
    () async {
      var grant = 'before-revocation';
      final secured = SettlementJournal(
        db: db,
        send: (event) async => sent.add(event),
        captureGrant: () async => grant,
      );
      addTearDown(secured.dispose);
      await secured.append(
        visitId: 'v1',
        kind: SettlementEventKind.tableExpense,
        id: 'before',
      );
      grant = 'after-revocation';
      await secured.append(
        visitId: 'v1',
        kind: SettlementEventKind.tableExpense,
        id: 'after',
      );
      final captured = await secured.eventsFor('v1');
      expect(captured.map((e) => e.payload['captureGrant']), [
        'before-revocation',
        'after-revocation',
      ]);
    },
  );

  test('captured receipt snapshot travels with mint replay', () async {
    final mint = await journal.append(
      visitId: 'v1',
      id: 'r1',
      kind: SettlementEventKind.mintReceipt,
      payload: const {'assignAll': true},
    );
    await journal.recordReceiptSnapshot(mint.id, const {
      'subtotal': 20000,
      'total': 20000,
      'lines': [
        {'ticketId': 'tk1', 'qtyUnits': 1},
      ],
    });
    expect(
      (await journal.eventById(mint.id))?.payload['receiptSnapshot'],
      isA<Map>(),
    );
    await journal.drain();
    expect(sent.single.payload['receiptSnapshot'], isA<Map>());
  });

  test(
    'parked payment metadata reports even with no pending actions',
    () async {
      final payment = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 10000},
      );
      await (db.update(db.settlementEvents)
            ..where((e) => e.id.equals(payment.id)))
          .write(const SettlementEventsCompanion(status: Value('parked')));
      final reported = <SettlementEvent>[];
      final reconnect = SettlementJournal(
        db: db,
        send: (event) async => sent.add(event),
        reportLegacyParked: (events) async => reported.addAll(events),
      );
      await reconnect.drain();
      expect(reported.map((e) => e.id), [payment.id]);
      expect(sent, isEmpty);
      reconnect.dispose();
    },
  );

  test(
    'an interrupted drain retains delivered food for local projection',
    () async {
      var calls = 0;
      final interrupted = SettlementJournal(
        db: db,
        send: (event) async {
          if (++calls == 2) throw StateError('connection lost');
        },
      );
      final order = await interrupted.append(
        visitId: 'v1',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [
            {'ticketId': 't1', 'qty': 1, 'unitPrice': 55000},
          ],
        },
      );
      await interrupted.append(
        visitId: 'v1',
        kind: SettlementEventKind.mintReceipt,
      );
      await interrupted.drain();
      expect(
        (await interrupted.eventsFor('v1')).map((e) => e.id),
        contains(order.id),
      );
      interrupted.dispose();
    },
  );

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
    test('payment can credit visit when receipt mint fails', () async {
      final mint = await journal.append(
        visitId: 'v1',
        id: 'r1',
        kind: SettlementEventKind.mintReceipt,
        payload: const {},
      );
      final payment = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 10000},
      );
      final refund = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.refund,
        payload: {'receiptId': 'r1', 'paymentId': payment.id, 'amount': 5000},
      );
      refuse[mint.id] = 'no_visit';
      await journal.drain();
      expect(sent.map((e) => e.id), [payment.id, refund.id]);
      expect((await journal.eventById(mint.id))?.hasSyncError, isTrue);
      expect(await journal.eventById(payment.id), isNull);
    });

    test('keeps a refused payment for repair and holds its refund', () async {
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
        payload: {'receiptId': 'r1', 'paymentId': b.id, 'amount': 80000},
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
      expect(chain.strandedAmount, 0);
      expect(journal.state.parkedVisits, isEmpty);
      expect((await journal.eventById(b.id))?.hasSyncError, isTrue);
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
      expect(journal.state.parkedVisits, isEmpty);
      expect((await journal.eventById(bad.id))?.hasSyncError, isTrue);
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

    test('legacy parked records remain while new actions drain', () async {
      final bad = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 135000},
      );
      await db.customStatement(
        'UPDATE settlement_events SET status = ?, payload_json = ? WHERE id = ?',
        ['parked', '{"receiptId":"r1","amount":135000}', bad.id],
      );
      final next = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [
            {'itemId': 'i1', 'ticketId': 'tk1'},
          ],
        },
      );
      await journal.drain();
      expect(sent.map((e) => e.id), [next.id]);

      final chains = await journal.parkedChains();
      expect(chains, hasLength(1));
      expect(chains.single.visitId, 'v1');
      expect(chains.single.code, isNull);
      expect(chains.single.refused!.id, bad.id);
      expect(
        chains.single.strandedAmount,
        135000,
        reason: 'the cash is in the drawer and the sheet must name it',
      );

      expect(await journal.eventById(bad.id), isNotNull);
    });

    test('a pending legacy capture keeps its old parking policy', () async {
      final old = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1', 'amount': 9000},
      );
      await db.customStatement(
        'UPDATE settlement_events SET payload_json = ? WHERE id = ?',
        ['{"receiptId":"r1","amount":9000}', old.id],
      );
      refuse[old.id] = 'overpayment';
      await journal.drain();
      expect((await journal.eventById(old.id))?.isParked, isTrue);
      expect((await journal.parkedChains()).single.strandedAmount, 9000);
    });

    test('damaged payment stays for repair while an order drains', () async {
      final damaged = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r1'},
      );
      final order = await journal.append(
        visitId: 'v1',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [
            {'itemId': 'i1', 'ticketId': 'tk1'},
          ],
        },
      );
      await journal.drain();
      expect((await journal.eventById(damaged.id))?.needsRepair, isTrue);
      expect(sent.map((e) => e.id), [order.id]);
      await journal.repairAndResend(damaged.id, {
        'receiptId': 'r1',
        'amount': 5000,
      });
      await journal.drain();
      expect(sent.map((e) => e.id), [order.id, damaged.id]);
    });

    test(
      'order missing item ID waits for repair while next order drains',
      () async {
        final damaged = await journal.append(
          visitId: 'v1',
          kind: SettlementEventKind.submitOrder,
          payload: const {
            'lines': [
              {'ticketId': 'tk1'},
            ],
          },
        );
        final intact = await journal.append(
          visitId: 'v1',
          kind: SettlementEventKind.submitOrder,
          payload: const {
            'lines': [
              {'itemId': 'i2', 'ticketId': 'tk2'},
            ],
          },
        );

        await journal.drain();
        expect((await journal.eventById(damaged.id))?.needsRepair, isTrue);
        expect(sent.map((e) => e.id), [intact.id]);

        await journal.repairAndResend(damaged.id, const {
          'lines': [
            {'itemId': 'i1', 'ticketId': 'tk1'},
          ],
        });
        await journal.drain();
        expect(sent.map((e) => e.id), [intact.id, damaged.id]);
      },
    );

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
