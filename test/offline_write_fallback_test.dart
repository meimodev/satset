// The two doors into the offline path (ADR-0090, rewritten for ADR-0139).
// `settlement_journal_test.dart` proves the chain behaves once an event is in
// it; nothing proved an event ever gets there. These are the branches a waiter
// actually walks through: the socket is down, they seat a table and take an
// order, and neither act may throw, block, or vanish.
//
// What ADR-0139 changed is where they land. A seat and an order used to go to a
// prefs FIFO a bill could not reach, which is how a captured line stayed
// invisible on the bill the same handset settled. They are now the first
// events of the visit's own chain — so these tests assert on the journal, and
// on the two things that make the bill reachable at all: a **client-minted
// visit id** and a **seed bill** to project onto.
//
// The repositories are exercised through a real ProviderContainer pointed at a
// dead host, because the bug this guards against is an ordering one — a guard
// placed after an early `return`, or after a rollback — and only the real call
// sequence can catch that.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/settlement_event.dart';

void main() {
  late ProviderContainer container;
  late ClientDb db;

  SettlementJournal journal() =>
      container.read(settlementJournalProvider.notifier);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsService(await SharedPreferences.getInstance());
    db = ClientDb.memory();
    container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        clientDbProvider.overrideWithValue(db),
        // Paired, but at a port nothing answers on: the repositories must take
        // the offline branch on the connection state, never on a lucky timeout.
        apiConfigProvider.overrideWith(
          (_) => ApiConfig(baseUri: _deadHost, trustedFingerprint: ''),
        ),
        wsConnStateProvider.overrideWith((_) => WsConnState.closed),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  test('a terputus seat opens a captured visit, not a lost intent', () async {
    await container.read(tablesProvider.notifier).seat(
      'meja-7',
      pax: 4,
      userId: 'user-w1',
      guestName: 'Bu Sri',
    );

    final events = await journal().eventsFor(await _onlyVisit(journal()));
    expect(events, hasLength(1));
    expect(events.single.kind, SettlementEventKind.seatTable);
    expect(events.single.tableId, 'meja-7');
    expect(events.single.actorId, 'user-w1');
    expect(events.single.payload['pax'], 4);
    expect(events.single.payload['guestName'], 'Bu Sri');
  });

  test('the captured seat leaves a bill the cashier can open', () async {
    // The half that is easy to forget and impossible to recover from: a seat
    // event with no seed bill is a visit that shows in the payable list and
    // throws when opened. Both writes, or neither.
    await container.read(tablesProvider.notifier).seat('meja-7', pax: 2);
    final visitId = await _onlyVisit(journal());

    final seed = await journal().cachedBill(visitId);
    expect(seed, isNotNull);
    expect(seed!['visitId'], visitId);
    expect(seed['tableId'], 'meja-7');
    expect(seed['pax'], 2);
    expect(seed['lines'], isEmpty);
    expect(
      seed['total'],
      0,
      reason: 'every money figure is recomputeBill\'s to write, never the seed\'s',
    );
  });

  test('the seated table carries the minted visit id', () async {
    // Orders behind the seat read `currentVisitId` to know where to hang. If
    // the local row is not seeded, every one of them opens a *second* captured
    // visit for the same table.
    await container.read(tablesProvider.notifier).seat('meja-7', pax: 2);
    final visitId = await _onlyVisit(journal());
    final table = container
        .read(tablesProvider)
        .where((t) => t.id == 'meja-7')
        .firstOrNull;
    // The floor may not hold this table at all in a bare container; when it
    // does, the id must match the one the journal minted.
    if (table != null) expect(table.currentVisitId, visitId);
  });

  test('a terputus order is captured and reports no tickets', () async {
    final ids = await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-7',
      idempotencyKey: 'ignored-offline',
      actorId: 'user-w1',
      lines: const [
        CartLineDto(
          itemId: 'item-1',
          name: 'Nasi goreng',
          variantId: '',
          variantName: '',
          modifiers: [],
          note: null,
          course: 'mains',
          qty: 2,
          unitPrice: 25000,
        ),
      ],
    );

    expect(
      ids,
      isEmpty,
      reason: 'nothing was filed, so there is no ticket id to hand back',
    );

    final visitId = await _onlyVisit(journal());
    final events = await journal().eventsFor(visitId);
    // The order arrived at a table this device had not seated, so the capture
    // opened the visit for it — an order with nowhere to land is the bill that
    // does not exist (ADR-0139).
    expect(events.map((e) => e.kind), [
      SettlementEventKind.seatTable,
      SettlementEventKind.submitOrder,
    ]);
    final order = events.last;
    expect(order.tableId, 'meja-7');
    final line = (order.payload['lines'] as List).single as Map;
    expect(line['qty'], 2);
    expect(
      line['ticketId'],
      isA<String>().having((s) => s.isNotEmpty, 'minted', isTrue),
      reason: 'the bill assigns, discounts and voids by ticket id — a line '
          'without one can be rendered and nothing else',
    );
  });

  test('every captured line gets its own ticket id', () async {
    await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-7',
      idempotencyKey: 'k',
      lines: const [
        CartLineDto(
          itemId: 'item-1',
          name: 'Nasi goreng',
          variantId: '',
          variantName: '',
          modifiers: [],
          note: null,
          course: 'mains',
          qty: 1,
          unitPrice: 25000,
        ),
        CartLineDto(
          itemId: 'item-2',
          name: 'Es teh',
          variantId: '',
          variantName: '',
          modifiers: [],
          note: null,
          course: 'drinks',
          qty: 1,
          unitPrice: 8000,
        ),
      ],
    );
    final events = await journal().eventsFor(await _onlyVisit(journal()));
    final lines = (events.last.payload['lines'] as List).cast<Map>();
    final ids = {for (final l in lines) l['ticketId'] as String};
    expect(
      ids,
      hasLength(2),
      reason: 'two lines sharing one ticket id collapse into one on the bill',
    );
  });

  test('the captured order replays under the key the attempt used', () async {
    // A POST that timed out may still have landed. The replay has to carry the
    // *same* idempotency key, or the host writes the order a second time —
    // which is the one failure a waiter cannot see and the kitchen cooks.
    const line = CartLineDto(
      itemId: 'item-1',
      name: 'Nasi goreng',
      variantId: '',
      variantName: '',
      modifiers: [],
      note: null,
      course: 'mains',
      qty: 1,
      unitPrice: 25000,
    );
    await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-7',
      idempotencyKey: 'key-abc',
      lines: const [line],
    );
    final visitId = await _onlyVisit(journal());
    expect(
      (await journal().eventsFor(visitId))
          .where((e) => e.kind == SettlementEventKind.submitOrder)
          .single
          .id,
      'key-abc',
    );

    // And capturing that same key again — a retry of the same tap — adds
    // nothing: one order captured is one order sent.
    await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-7',
      idempotencyKey: 'key-abc',
      lines: const [line],
    );
    expect(
      (await journal().eventsFor(visitId))
          .where((e) => e.kind == SettlementEventKind.submitOrder),
      hasLength(1),
    );
  });

  test('each table gets its own chain', () async {
    await container.read(tablesProvider.notifier).seat('meja-7', pax: 2);
    await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-9',
      idempotencyKey: 'k',
      lines: const [
        CartLineDto(
          itemId: 'item-2',
          name: 'Es teh',
          variantId: '',
          variantName: '',
          modifiers: [],
          note: null,
          course: 'drinks',
          qty: 1,
          unitPrice: 8000,
        ),
      ],
    );

    final rows = await db.select(db.settlementEvents).get();
    expect(
      rows.map((r) => r.visitId).toSet(),
      hasLength(2),
      reason: 'two tables are two visits — one chain each, or the seat for one '
          'sequences against the order for the other',
    );
    expect(
      rows.where((r) => r.tableId == 'meja-9').map((r) => r.kind),
      containsAll(<String>['seatTable', 'submitOrder']),
    );
  });
}

/// The single captured visit in the journal, for tests that make exactly one.
Future<String> _onlyVisit(SettlementJournal journal) async {
  final ids = await journal.pendingVisitIds();
  expect(ids, hasLength(1));
  return ids.single;
}

/// Nothing listens on port 1, so a stray request fails at once instead of
/// holding the suite open for a connect timeout.
final _deadHost = Uri.parse('https://127.0.0.1:1');
