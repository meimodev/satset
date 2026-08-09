import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/send_queue_service.dart';

/// The drain is the whole feature (ADR-0090): everything else is plumbing that
/// fails loudly, while a drain that reorders, double-sends, or quietly loses an
/// intent fails as a bill that is wrong tomorrow. These are the properties that
/// must hold.
void main() {
  late PrefsService prefs;

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
}
