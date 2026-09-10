import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/captured_tickets.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/settlement_projection.dart';

const _line = {
  'itemId': 'food',
  'ticketId': 'ticket-1',
  'name': 'Lumpia',
  'course': 'starters',
  'qty': 1,
  'unitPrice': 55000,
};
const _config = ProjectionConfig(
  tax: TaxServiceConfig(
    taxEnabled: false,
    taxRateBps: 0,
    serviceEnabled: false,
    serviceMode: 'percent',
    serviceRateBps: 0,
    serviceFixedAmount: 0,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ClientDb db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = ClientDb.memory();
  });
  tearDown(() => db.close());

  test(
    'unknown baseline displays known lines and cannot create payment receipts',
    () async {
      final container = ProviderContainer(
        overrides: [
          clientDbProvider.overrideWithValue(db),
          wsConnStateProvider.overrideWithValue(WsConnState.closed),
        ],
      );
      addTearDown(container.dispose);
      final journal = container.read(settlementJournalProvider.notifier);
      await journal.append(
        visitId: 'adopted',
        tableId: 'table',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      final repo = container.read(settlementProvider.notifier);
      final bill = await repo.fetchBill('adopted');
      expect(bill.historyAvailable, isFalse);
      expect(bill.lines.single.ticketId, 'ticket-1');
      expect(bill.subtotal, 55000);
      expect(await journal.cachedBill('adopted'), isNull);
      await expectLater(
        repo.mintReceipt('adopted', assignAll: true),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'bill_history_unavailable',
          ),
        ),
      );
      expect(await journal.eventsFor('adopted'), hasLength(1));
    },
  );

  test(
    'a locally seated visit can order, pay and close while offline',
    () async {
      final container = ProviderContainer(
        overrides: [
          clientDbProvider.overrideWithValue(db),
          wsConnStateProvider.overrideWithValue(WsConnState.closed),
        ],
      );
      addTearDown(container.dispose);
      final journal = container.read(settlementJournalProvider.notifier);
      final visit = await journal.openCapturedVisit(tableId: 'table', pax: 1);
      await journal.append(
        visitId: visit,
        tableId: 'table',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      final repo = container.read(settlementProvider.notifier);
      final bill = await repo.fetchBill(visit);
      expect(bill.historyAvailable, isTrue);
      final receipt = await repo.mintReceipt(visit, assignAll: true);
      final paid = await repo.recordPayment(
        receipt.receiptId,
        method: 'cash',
        amount: bill.total,
      );
      expect(paid.outstanding, 0);
      await repo.closeBill(visit);
      expect((await repo.fetchBill(visit)).billClosedAt, isNotNull);
    },
  );

  test(
    'acknowledged prefix survives restart and snapshot failure without resending',
    () async {
      var failSnapshot = true;
      final sent = <String>[];
      final baseline = capturedBillSeed(
        visitId: 'v',
        tableId: 'table',
        openedAt: DateTime.utc(2026),
      );
      var host = baseline;
      SettlementJournal build() => SettlementJournal(
        db: db,
        send: (e) async {
          sent.add(e.id);
          host = projectBill(host, [e], _config);
        },
        loadBill: (_, _) async {
          if (failSnapshot) throw StateError('offline');
          return host;
        },
      );
      var journal = build();
      await journal.cacheBill('v', baseline);
      await journal.append(
        visitId: 'v',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      expect((await journal.drain()).interrupted, isTrue);
      expect((await journal.eventsFor('v')).single.isAcknowledged, isTrue);
      journal.dispose();
      journal = build();
      final source = await journal.projectionFor('v');
      expect(projectBill(source.bill!, source.events, _config)['total'], 55000);
      failSnapshot = false;
      await journal.drain();
      expect(sent, hasLength(1));
      expect(await journal.eventsFor('v'), isEmpty);
      expect((await journal.cachedBill('v'))!['total'], 55000);
      journal.dispose();
    },
  );

  test(
    'capture during checkpoint is retained and projected exactly once',
    () async {
      late SettlementJournal journal;
      final baseline = capturedBillSeed(
        visitId: 'v',
        tableId: 'table',
        openedAt: DateTime.utc(2026),
      );
      var host = baseline;
      var appended = false;
      journal = SettlementJournal(
        db: db,
        send: (e) async {
          host = projectBill(host, [e], _config);
        },
        loadBill: (_, _) async {
          if (!appended) {
            appended = true;
            await journal.append(
              visitId: 'v',
              kind: SettlementEventKind.submitOrder,
              payload: {
                'lines': [
                  {..._line, 'ticketId': 'ticket-2'},
                ],
              },
            );
          }
          return host;
        },
      );
      await journal.cacheBill('v', baseline);
      await journal.append(
        visitId: 'v',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      await journal.drain();
      final source = await journal.projectionFor('v');
      expect(source.events, hasLength(1));
      expect(
        projectBill(source.bill!, source.events, _config)['total'],
        110000,
      );
      await journal.drain();
      expect((await journal.cachedBill('v'))!['total'], 110000);
      journal.dispose();
    },
  );

  test(
    'refusal survives restart and blocks new work without blocking other visits',
    () async {
      SettlementJournal build() => SettlementJournal(
        db: db,
        send: (_) async => throw const SettlementRefused('receipt_deleted'),
      );
      var journal = build();
      await journal.append(
        visitId: 'v',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      await journal.drain();
      journal.dispose();
      journal = build();
      await expectLater(
        journal.append(visitId: 'v', kind: SettlementEventKind.submitOrder),
        throwsA(isA<SettlementVisitReadOnly>()),
      );
      await journal.append(
        visitId: 'other',
        kind: SettlementEventKind.submitOrder,
      );
      expect((await journal.parkedChains()).single.visitId, 'v');
      journal.dispose();
    },
  );

  for (final refused in [false, true]) {
    test(
      'production replay checkpoints floor or parks partial rejection ($refused)',
      () async {
        final prefs = PrefsService(await SharedPreferences.getInstance());
        await prefs.setAppMode(AppMode.client);
        final api = _CheckpointApi(refused: refused);
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWith((_) async => prefs),
            apiConfigProvider.overrideWith((_) => _apiConfig),
            apiClientProvider.overrideWithValue(api),
            clientDbProvider.overrideWithValue(db),
            wsConnStateProvider.overrideWithValue(WsConnState.closed),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(api.close);
        await container.read(prefsServiceProvider.future);
        final journal = container.read(settlementJournalProvider.notifier);
        await journal.openCapturedVisit(visitId: 'v', tableId: 'table', pax: 1);
        await journal.append(
          visitId: 'v',
          tableId: 'table',
          id: 'order',
          kind: SettlementEventKind.submitOrder,
          payload: const {
            'lines': [_line],
          },
        );
        final result = await journal.drain();
        if (refused) {
          expect(result.failures, hasLength(1));
          expect((await journal.parkedChains()).single.code, 'out_of_stock');
          await expectLater(
            journal.assertWritable('v'),
            throwsA(isA<SettlementVisitReadOnly>()),
          );
        } else {
          expect(result.interrupted, isFalse);
          expect(await journal.eventsFor('v'), isEmpty);
          expect(
            container.read(visibleTicketsProvider)['v']!.single.id,
            'ticket-1',
          );
          final persisted = jsonDecode(prefs.floorJson('tickets')!) as Map;
          expect((persisted['v'] as List).single['id'], 'ticket-1');
          expect((await journal.cachedBill('v'))!['total'], 55000);
        }
      },
    );
  }

  test(
    'concurrent captures allocate distinct ordered sequence numbers',
    () async {
      final journal = SettlementJournal(db: db, send: (_) async {});
      await Future.wait(
        List.generate(
          20,
          (i) => journal.append(
            visitId: 'v',
            id: 'event-$i',
            kind: SettlementEventKind.submitOrder,
          ),
        ),
      );
      expect(
        (await journal.eventsFor('v')).map((e) => e.seq),
        List.generate(20, (i) => i),
      );
      journal.dispose();
    },
  );

  test(
    'restart refusal report preserves its delivered prefix and stranded cash',
    () async {
      var journal = SettlementJournal(
        db: db,
        send: (e) async {
          if (e.kind == SettlementEventKind.recordPayment) {
            throw const SettlementRefused('receipt_deleted');
          }
        },
      );
      await journal.append(
        visitId: 'v',
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
      );
      await journal.append(
        visitId: 'v',
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'r', 'amount': 55000},
      );
      await journal.drain();
      journal.dispose();
      journal = SettlementJournal(db: db, send: (_) async {});
      final report = (await journal.parkedChains()).single;
      expect(report.delivered.single.kind, SettlementEventKind.submitOrder);
      expect(report.strandedAmount, 55000);
      expect(report.code, 'receipt_deleted');
      journal.dispose();
    },
  );

  test(
    'captured floor view deduplicates host echoes and applies captured voids',
    () {
      final order = SettlementEvent(
        id: 'o',
        visitId: 'v',
        seq: 0,
        kind: SettlementEventKind.submitOrder,
        payload: const {
          'lines': [_line],
        },
        capturedAt: DateTime.utc(2026),
        tableId: 'table',
      );
      final captured = projectCapturedTickets({}, [order]);
      final echoed = projectCapturedTickets(captured, [order]);
      expect(echoed['v'], hasLength(1));
      final voided = projectCapturedTickets(echoed, [
        order,
        SettlementEvent(
          id: 'void',
          visitId: 'v',
          seq: 1,
          kind: SettlementEventKind.voidTicket,
          payload: const {
            'ticketId': 'ticket-1',
            'voidReasonCode': 'guest_changed_mind',
          },
          capturedAt: DateTime.utc(2026),
        ),
      ]);
      expect(voided['v']!.single.status.name, 'voided');
      expect(voided['v']!.single.course.name, 'starters');
    },
  );
}

final _apiConfig = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:1'),
  trustedFingerprint: '',
);

class _CheckpointApi extends ApiClient {
  _CheckpointApi({required this.refused})
    : super(config: _apiConfig, storage: SecureStorageService());
  final bool refused;
  @override
  Future<dynamic> postJson(
    String path,
    Object body, {
    String? idempotencyKey,
    Duration? timeout,
  }) async {
    if (path == '/orders') {
      return {
        'ticketIds': refused ? [] : ['ticket-1'],
        'rejected': refused
            ? [
                {'reason': 'out_of_stock'},
              ]
            : [],
      };
    }
    return {};
  }

  @override
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    if (path == '/tickets') {
      return [
        {
          ..._line,
          'id': 'ticket-1',
          'tableId': 'table',
          'visitId': 'v',
          'price': 55000,
          'status': 'sent',
          'sentAt': DateTime.utc(2026).toIso8601String(),
        },
      ];
    }
    if (path == '/tables') return <Object>[];
    if (path.endsWith('/bill')) {
      return {
        ...capturedBillSeed(
          visitId: 'v',
          tableId: 'table',
          openedAt: DateTime.utc(2026),
        ),
        'lines': [
          {..._line, 'lineTotal': 55000},
        ],
        'subtotal': 55000,
        'total': 55000,
        'outstanding': 55000,
      };
    }
    return {};
  }
}
