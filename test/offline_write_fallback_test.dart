// The two doors into the offline path (ADR-0090). `send_queue_test.dart` proves
// the drain behaves once an intent is in the queue; nothing proved an intent
// ever gets there. These are the branches a waiter actually walks through: the
// socket is down, they seat a table and take an order, and neither act may
// throw, block, or vanish.
//
// The repositories are exercised through a real ProviderContainer pointed at a
// dead host, because the bug this guards against is an ordering one — a guard
// placed after an early `return`, or after a rollback — and only the real call
// sequence can catch that.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/models/order_dto.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/data/services/ws_client.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsService(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWith((_) async => prefs),
        // Paired, but at a port nothing answers on: the repositories must take
        // the offline branch on the connection state, never on a lucky timeout.
        apiConfigProvider.overrideWith(
          (_) => ApiConfig(baseUri: _deadHost, trustedFingerprint: ''),
        ),
        wsConnStateProvider.overrideWith((_) => WsConnState.closed),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a terputus seat is queued, not lost', () async {
    await container.read(tablesProvider.notifier).seat(
      'meja-7',
      pax: 4,
      userId: 'user-w1',
      guestName: 'Bu Sri',
    );

    final queued = container.read(sendQueueProvider);
    expect(queued, hasLength(1));
    expect(queued.single.kind, SendIntentKind.seatTable);
    expect(queued.single.tableId, 'meja-7');
    expect(queued.single.actorId, 'user-w1');
    expect(queued.single.payload['pax'], 4);
    expect(queued.single.payload['guestName'], 'Bu Sri');
  });

  test('a terputus order is queued and reports no tickets', () async {
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
    final queued = container.read(sendQueueProvider);
    expect(queued, hasLength(1));
    expect(queued.single.kind, SendIntentKind.submitOrder);
    expect(queued.single.lines.single['qty'], 2);
    expect(
      queued.single.expectedVisitId,
      isNull,
      reason: 'the table has no known visit — a made-up one would read to the '
          'host as "the guests changed" and be refused',
    );
  });

  test('the queued order replays under the key the attempt used', () async {
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
    expect(container.read(sendQueueProvider).single.id, 'key-abc');

    // And capturing that same key again — a retry of the same tap — adds
    // nothing: one order captured is one order sent.
    await container.read(ticketsProvider.notifier).submitOrder(
      tableId: 'meja-7',
      idempotencyKey: 'key-abc',
      lines: const [line],
    );
    expect(container.read(sendQueueProvider), hasLength(1));
  });

  test('both surface on the table they were captured for', () async {
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

    expect(container.read(pendingOrdersForTableProvider('meja-9')), hasLength(1));
    expect(
      container.read(pendingOrdersForTableProvider('meja-7')),
      isEmpty,
      reason: 'a seat is not a pending order — only lines belong in that block',
    );
  });
}

/// Nothing listens on port 1, so a stray request fails at once instead of
/// holding the suite open for a connect timeout.
final _deadHost = Uri.parse('https://127.0.0.1:1');
