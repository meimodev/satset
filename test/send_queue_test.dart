import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/send_queue_drain.dart';
import 'package:satset/data/services/send_queue_service.dart';

/// The drain is the whole feature (ADR-0090): everything else is plumbing that
/// fails loudly, while a drain that reorders, double-sends, or quietly loses an
/// intent fails as a bill that is wrong tomorrow. These are the properties that
/// must hold.
void main() {
  late PrefsService prefs;
  var corrupted = false;

  Future<PrefsService> freshPrefs([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    return PrefsService(await SharedPreferences.getInstance());
  }

  setUp(() async {
    prefs = await freshPrefs();
  });

  tearDown(SatClock.clear);

  /// Move the app clock to a fixed instant. `SatClock` shifts by an offset
  /// rather than freezing, which is what the drain needs — it reads the clock
  /// twice and must see time move normally between the two.
  void travelTo(DateTime t) => SatClock.adopt(t.difference(DateTime.now()));

  Future<SendIntent> enqueueOrder(
    SendQueue q, {
    required String tableId,
    String actor = 'user-1',
    String? expectedVisitId,
  }) => q.enqueue(
    kind: SendIntentKind.submitOrder,
    tableId: tableId,
    actorId: actor,
    expectedVisitId: expectedVisitId,
    payload: {
      'lines': [
        {'itemId': 'item-1', 'name': 'Nasi goreng', 'qty': 1, 'unitPrice': 25000},
      ],
    },
  );

  test('drains in capture order, one at a time', () async {
    final sent = <String>[];
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        sent.add(i.tableId);
        return {'ticketIds': <String>['t-${i.tableId}'], 'visitId': 'v-1'};
      },
    );
    await enqueueOrder(q, tableId: 'a');
    await enqueueOrder(q, tableId: 'b');
    await enqueueOrder(q, tableId: 'c');

    final report = await q.drain();

    expect(sent, ['a', 'b', 'c'], reason: 'FIFO — the guest remembers the order');
    expect(report.outcomes.length, 3);
    expect(report.failures, isEmpty);
    expect(q.state, isEmpty);
  });

  test('a refused intent is reported and does not strand the ones behind it',
      () async {
    final sent = <String>[];
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        sent.add(i.tableId);
        if (i.tableId == 'b') {
          throw const ApiException(409, '{}', 'visit_changed');
        }
        return {'ticketIds': <String>['t'], 'visitId': 'v-1'};
      },
    );
    await enqueueOrder(q, tableId: 'a');
    await enqueueOrder(q, tableId: 'b', expectedVisitId: 'v-old');
    await enqueueOrder(q, tableId: 'c');

    final report = await q.drain();

    expect(sent, ['a', 'b', 'c'], reason: 'one refusal must not stop the drain');
    expect(report.interrupted, isFalse);
    expect(report.failures.length, 1);
    expect(report.failures.single.kind, SendOutcomeKind.refused);
    expect(report.failures.single.code, 'visit_changed');
    expect(report.failures.single.intent.tableId, 'b');
    expect(q.state, isEmpty, reason: 'a refusal is an answer, not a retry');
  });

  test('a partial stock rejection still counts as delivered, and is surfaced',
      () async {
    final q = SendQueue(
      prefs: prefs,
      send: (_) async => {
        'ticketIds': <String>['t-1'],
        'visitId': 'v-9',
        'rejected': [
          {'itemId': 'item-2', 'name': 'Ayam', 'ingredients': <String>['ayam']},
        ],
      },
    );
    await enqueueOrder(q, tableId: 'a');

    final report = await q.drain();
    final only = report.outcomes.single;

    expect(only.kind, SendOutcomeKind.delivered);
    expect(only.visitId, 'v-9');
    expect(only.rejectedLines, hasLength(1));
    expect(only.needsAttention, isTrue, reason: 'the waiter must be told');
  });

  test('transport failure stops the drain and keeps the backlog', () async {
    var calls = 0;
    final q = SendQueue(
      prefs: prefs,
      send: (_) async {
        calls++;
        throw Exception('no route to host');
      },
    );
    await enqueueOrder(q, tableId: 'a');
    await enqueueOrder(q, tableId: 'b');

    final report = await q.drain();

    expect(calls, 1, reason: 'stop on the first failure, do not hammer');
    expect(report.interrupted, isTrue);
    expect(report.outcomes, isEmpty);
    expect(q.state, hasLength(2), reason: 'nothing may be lost');
  });

  test('a rejected bearer stalls rather than dropping the orders', () async {
    final q = SendQueue(
      prefs: prefs,
      send: (_) async => throw const ApiException(403, '{}', 'forbidden'),
    );
    await enqueueOrder(q, tableId: 'a');

    final report = await q.drain();

    expect(report.interrupted, isTrue);
    expect(q.state, hasLength(1));
  });

  Future<SendIntent> enqueueVoid(
    SendQueue q, {
    required String ticketId,
    String tableId = 'a',
    String actor = 'user-1',
  }) => q.enqueue(
    id: 'void-$ticketId',
    kind: SendIntentKind.voidTicket,
    tableId: tableId,
    actorId: actor,
    payload: {
      'ticketId': ticketId,
      'voidReasonCode': 'customerChange',
      'voidReason': '',
      'name': 'Nasi goreng',
      'qty': 1,
    },
  );

  test('a refused void does not stall the orders behind it', () async {
    // `served → voided` costs `compItem`, which a waiter may simply not hold.
    // That is a business refusal about one line, not a broken bearer — and
    // stalling on it strands every order queued behind a comp the venue was
    // never going to allow.
    final sent = <SendIntentKind>[];
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        sent.add(i.kind);
        if (i.kind == SendIntentKind.voidTicket) {
          throw const ApiException(403, '{}', 'forbidden');
        }
        return {'ticketIds': <String>[], 'visitId': 'v-1'};
      },
    );
    await enqueueVoid(q, ticketId: 'tk-1');
    await enqueueOrder(q, tableId: 'b');

    final report = await q.drain();

    expect(report.interrupted, isFalse);
    expect(sent, [SendIntentKind.voidTicket, SendIntentKind.submitOrder]);
    expect(q.state, isEmpty, reason: 'both were answered');
    expect(
      report.outcomes.first.kind,
      SendOutcomeKind.refused,
      reason: 'the void is refused, not stalled',
    );
  });

  test('a rejected bearer on an order still stalls a void behind it', () async {
    // The 401/403 stall is only relaxed for the void itself. An order the
    // bearer cannot carry must still hold the whole backlog.
    final q = SendQueue(
      prefs: prefs,
      send: (_) async => throw const ApiException(403, '{}', 'forbidden'),
    );
    await enqueueOrder(q, tableId: 'a');
    await enqueueVoid(q, ticketId: 'tk-1');

    final report = await q.drain();

    expect(report.interrupted, isTrue);
    expect(q.state, hasLength(2));
  });

  test('voiding the same line twice offline queues one intent', () async {
    // The key is `void-<ticketId>`, so the dedupe is the idempotency: four
    // taps on a dead socket must leave one intent and one answer, not four.
    final q = SendQueue(prefs: prefs, send: (_) async => {});
    await enqueueVoid(q, ticketId: 'tk-1');
    await enqueueVoid(q, ticketId: 'tk-1');
    await enqueueVoid(q, ticketId: 'tk-2');

    expect(q.state, hasLength(2));
  });

  test('the idempotency key survives a retry', () async {
    final keys = <String>[];
    var failFirst = true;
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        keys.add(i.id);
        if (failFirst) {
          failFirst = false;
          throw Exception('timeout after the host committed');
        }
        return {'ticketIds': <String>['t'], 'visitId': 'v-1'};
      },
    );
    await enqueueOrder(q, tableId: 'a');

    await q.drain();
    await q.drain();

    expect(keys, hasLength(2));
    expect(keys.first, keys.last,
        reason: 'a stable key is what stops the food being cooked twice');
  });

  test('an intent that outlived its business day expires unsent', () async {
    final q = SendQueue(prefs: prefs, businessDayStartHour: 4, send: (_) async {
      fail('an expired intent must never reach the host');
    });
    // Captured 21:00 on the 7th, drained 10:00 on the 8th — the 04:00 rollover
    // sits between them, so this is last night's order arriving into a day that
    // has closed its books. Pinned to fixed instants: an offset alone would
    // make the test pass or fail depending on the hour it runs at.
    travelTo(DateTime(2026, 8, 7, 21));
    await enqueueOrder(q, tableId: 'a');
    travelTo(DateTime(2026, 8, 8, 10));

    final report = await q.drain();

    expect(report.outcomes.single.kind, SendOutcomeKind.expired);
    expect(q.state, isEmpty);
  });

  test('an expense outlives its business day; an order does not', () async {
    // ADR-0130. The two intents differ on exactly this: an order nobody wants
    // this morning is right to drop, while an expense is money that already
    // left the till — discarding it destroys the only record that it did.
    final sent = <SendIntentKind>[];
    final q = SendQueue(
      prefs: prefs,
      businessDayStartHour: 4,
      send: (i) async {
        sent.add(i.kind);
        return {'visitId': 'v-1'};
      },
    );
    travelTo(DateTime(2026, 8, 7, 21));
    await enqueueOrder(q, tableId: 'a');
    await q.enqueue(
      kind: SendIntentKind.tableExpense,
      tableId: 'a',
      actorId: 'user-1',
      expectedVisitId: 'v-1',
      payload: {
        'visitId': 'v-1',
        'amount': 15000,
        'categoryId': 'vexc-other',
      },
    );
    travelTo(DateTime(2026, 8, 8, 10));

    final report = await q.drain();

    expect(sent, [SendIntentKind.tableExpense]);
    expect(
      report.outcomes.map((o) => o.kind),
      [SendOutcomeKind.expired, SendOutcomeKind.delivered],
    );
    expect(q.state, isEmpty);
  });

  test('a refused expense does not stall the orders behind it', () async {
    // The cap refusal is a 400 and a business fact about one row, so it takes
    // `voidTicket`'s posture (ADR-0114, ADR-0130): recorded, dropped, and the
    // backlog keeps moving. Stalling here would strand a shift of orders behind
    // a tissue receipt the bill could not cover.
    final sent = <String>[];
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        sent.add(i.kind.name);
        if (i.kind == SendIntentKind.tableExpense) {
          throw const ApiException(400, '{"code":"exceeds_bill"}', 'exceeds_bill');
        }
        return {'visitId': 'v-1'};
      },
    );
    await q.enqueue(
      kind: SendIntentKind.tableExpense,
      tableId: 'a',
      actorId: 'user-1',
      payload: {'visitId': 'v-1', 'amount': 999999, 'categoryId': 'c'},
    );
    await enqueueOrder(q, tableId: 'b');

    final report = await q.drain();

    expect(sent, ['tableExpense', 'submitOrder']);
    expect(report.interrupted, isFalse);
    expect(report.outcomes.first.kind, SendOutcomeKind.refused);
    expect(report.outcomes.first.code, 'exceeds_bill');
    expect(report.outcomes.last.kind, SendOutcomeKind.delivered);
    expect(q.state, isEmpty);
  });

  test('a revoked capability refuses one expense, not the backlog', () async {
    // A 403 stalls for an order — the bearer cannot carry the backlog. For an
    // expense it is `recordTableExpense` having been revoked, which is a fact
    // about one row.
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        if (i.kind == SendIntentKind.tableExpense) {
          throw const ApiException(403, '{"code":"forbidden"}', 'forbidden');
        }
        return {'visitId': 'v-1'};
      },
    );
    await q.enqueue(
      kind: SendIntentKind.tableExpense,
      tableId: 'a',
      actorId: 'user-1',
      payload: {'visitId': 'v-1', 'amount': 1000, 'categoryId': 'c'},
    );
    await enqueueOrder(q, tableId: 'b');

    final report = await q.drain();

    expect(report.interrupted, isFalse);
    expect(q.state, isEmpty);
  });

  test('a night that runs past midnight is still one business day', () async {
    var sent = 0;
    final q = SendQueue(
      prefs: prefs,
      businessDayStartHour: 4,
      send: (_) async {
        sent++;
        return {'ticketIds': <String>['t'], 'visitId': 'v-1'};
      },
    );
    // 23:00 captured, 02:00 delivered. Same service, so it must go through —
    // the boundary is 04:00, not midnight.
    travelTo(DateTime(2026, 8, 7, 23));
    await enqueueOrder(q, tableId: 'a');
    travelTo(DateTime(2026, 8, 8, 2));

    final report = await q.drain();

    expect(sent, 1);
    expect(report.outcomes.single.kind, SendOutcomeKind.delivered);
  });

  test('the queue survives a restart', () async {
    final q = SendQueue(prefs: prefs, send: (_) async => {});
    await enqueueOrder(q, tableId: 'a', actor: 'waiter-7');

    // Same prefs backing store, brand-new queue — a dead battery, not a bug.
    final revived = SendQueue(
      prefs: await freshPrefs({
        'flutter.satset.send_queue': prefs.sendQueueJson()!,
      }),
      send: (_) async => {},
    );

    expect(revived.state, hasLength(1));
    expect(revived.state.single.id, q.state.single.id);
    expect(revived.state.single.actorId, 'waiter-7');
  });

  test('voiding the last undelivered line drops the whole intent', () async {
    final q = SendQueue(prefs: prefs, send: (_) async => {});
    final intent = await enqueueOrder(q, tableId: 'a');

    await q.rewriteLines(intent.id, const []);

    expect(q.state, isEmpty);
    expect(prefs.sendQueueJson(), isNull);
  });

  test('dropping one line keeps the rest of the order, and its key', () async {
    final q = SendQueue(prefs: prefs, send: (_) async => {});
    final intent = await q.enqueue(
      kind: SendIntentKind.submitOrder,
      tableId: 'a',
      actorId: 'user-1',
      payload: {
        'lines': [
          {'itemId': 'i1', 'name': 'Nasi goreng', 'qty': 1},
          {'itemId': 'i2', 'name': 'Es teh', 'qty': 2},
        ],
      },
    );

    await q.rewriteLines(intent.id, [intent.lines.first]);

    expect(q.state.single.lines.map((l) => l['itemId']), ['i1']);
    expect(
      q.state.single.id,
      intent.id,
      reason: 'the id is the idempotency key — a rewrite that mints a new one '
          'would let an edited order land twice',
    );
  });

  test('the queue refuses to grow past its cap', () async {
    final q = SendQueue(prefs: prefs, send: (_) async => {});
    for (var i = 0; i < SendQueue.maxIntents; i++) {
      await enqueueOrder(q, tableId: 't$i');
    }

    expect(
      () => enqueueOrder(q, tableId: 'one-too-many'),
      throwsA(isA<SendQueueFull>()),
      reason: 'swallowing an order is worse than refusing it out loud',
    );
  });

  test('an order captured before prefs resolve outlives them landing', () async {
    // Prefs arrive a few frames into boot. A waiter can order in those frames,
    // and the queue used to be rebuilt — and disposed — when they did.
    final stored = await freshPrefs();
    await enqueueOrder(
      SendQueue(prefs: stored, send: (_) async => {}),
      tableId: 'from-last-night',
    );

    final pending = Completer<PrefsService>();
    final q = SendQueue(prefs: pending.future, send: (_) async => {});
    await enqueueOrder(q, tableId: 'captured-during-boot');
    pending.complete(stored);
    await pumpEventQueue();

    expect(
      q.state.map((i) => i.tableId),
      ['from-last-night', 'captured-during-boot'],
      reason: 'the stored backlog is older, and FIFO is the whole contract',
    );
  });

  test('a refused seat refuses the orders captured behind it', () async {
    final sent = <String>[];
    final q = SendQueue(
      prefs: prefs,
      send: (i) async {
        sent.add('${i.kind.name}:${i.tableId}');
        if (i.kind == SendIntentKind.seatTable) {
          throw const ApiException(409, '{}', 'already_seated');
        }
        return {'ticketIds': <String>[], 'visitId': 'v-host'};
      },
    );
    await q.enqueue(
      kind: SendIntentKind.seatTable,
      tableId: 'm7',
      actorId: 'user-1',
      payload: {'pax': 2},
    );
    await enqueueOrder(q, tableId: 'm7');
    // A different table's order must be unaffected — the refusal is about one
    // table's guests, not about the drain.
    await enqueueOrder(q, tableId: 'm8');

    final report = await q.drain();

    expect(
      sent,
      ['seatTable:m7', 'submitOrder:m8'],
      reason: 'the m7 order must never reach the host — it has no visit token '
          'and the table now holds someone else',
    );
    expect(
      report.failures.map((o) => o.code),
      ['already_seated', 'visit_changed'],
    );
    expect(q.isEmpty, isTrue);
  });

  /// An admin logout nulls `apiConfigProvider` while `AppShell` is still
  /// mounted, and the shell watches this provider. `wsClientProvider` throws
  /// rather than returning null without a config, so an unguarded `watch` here
  /// paints a red frame on the way to `/pin`.
  /// A backlog that will not parse used to be deleted on sight. It is still
  /// the orders a waiter took while the handset was cut off: unreplayable, but
  /// not nothing. So it moves aside instead, and somebody is told.
  group('a backlog that cannot be read', () {
    Future<SendQueue> loadFrom(String blob) async {
      final p = await freshPrefs({'satset.send_queue': blob});
      return SendQueue(
        prefs: p,
        send: (_) async => const {},
        onCorrupt: () => corrupted = true,
      );
    }

    test('is set aside verbatim rather than deleted', () async {
      const blob = '{not json at all';
      final p = await freshPrefs({'satset.send_queue': blob});
      final q = SendQueue(prefs: p, send: (_) async => const {});
      addTearDown(q.dispose);

      expect(q.state, isEmpty, reason: 'nothing in it can be replayed');
      // The write is fire-and-forget, so let the microtasks run.
      await Future<void>.delayed(Duration.zero);
      expect(p.sendQueueQuarantineJson(), blob);
      expect(
        p.sendQueueJson(),
        isNull,
        reason: 'and it does not stay where it will be re-read every boot',
      );
    });

    test('is announced, not swallowed', () async {
      corrupted = false;
      final q = await loadFrom('[{"kind":');
      addTearDown(q.dispose);
      expect(corrupted, isTrue);
    });

    test('a queue that parses says nothing and quarantines nothing', () async {
      corrupted = false;
      final p = await freshPrefs({'satset.send_queue': '[]'});
      final q = SendQueue(
        prefs: p,
        send: (_) async => const {},
        onCorrupt: () => corrupted = true,
      );
      addTearDown(q.dispose);

      expect(corrupted, isFalse);
      expect(p.sendQueueQuarantineJson(), isNull);
    });
  });

  test('drain trigger is inert without an ApiConfig', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(apiConfigProvider), isNull);
    expect(() => container.read(sendQueueDrainProvider), returnsNormally);
  });
}
