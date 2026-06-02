import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

/// Bootstrap status for the cashier payable list (spinner / retry banner).
final settlementStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

/// The cashier's venue-wide list of payable tables. WS `bill.updated`,
/// `table.updated`, and `tableSession.closed` all trigger a refetch (the list
/// shape is cheap and a closed/seated table changes membership). See ADR-0023.
class SettlementRepository extends StateNotifier<List<BillSummary>> {
  SettlementRepository({required this.ref}) : super(const []) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  bool _refetching = false;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(settlementStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(settlementStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(settlementStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(settlementStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        case WsEventTypes.connected:
        case WsEventTypes.billUpdated:
        case WsEventTypes.tableUpdated:
        case WsEventTypes.tableCreated:
        case WsEventTypes.tableDeleted:
        case WsEventTypes.ticketUpdated:
        case WsEventTypes.ticketCreated:
        case WsEventTypes.tableSessionClosed:
          unawaited(_refetch());
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() => _refetch();

  Future<void> _refetch() async {
    if (_refetching) return;
    _refetching = true;
    try {
      final cfg = ref.read(apiConfigProvider);
      if (cfg == null) return;
      final raw = await ref.read(apiClientProvider).getJson('/settlement/payable')
          as List;
      state = [
        for (final e in raw)
          BillSummary.fromJson((e as Map).cast<String, dynamic>())
      ];
      SatLog.repo('settlement.payable n=${state.length}');
    } catch (e) {
      SatLog.repo('settlement.payable fail $e');
      rethrow;
    } finally {
      _refetching = false;
    }
  }

  // ── mutations (each returns the fresh Bill; the family provider is the
  //    canonical detail source and is invalidated by the screen / WS) ──

  Future<Bill> fetchBill(String tableId) async {
    final raw = await ref
        .read(apiClientProvider)
        .getJson('/settlement/tables/$tableId/bill');
    return Bill.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<Bill> _billFrom(Object? raw) async {
    final map = (raw as Map).cast<String, dynamic>();
    return Bill.fromJson((map['bill'] as Map).cast<String, dynamic>());
  }

  Future<Bill> createReceipt(String tableId,
      {String mode = 'itemized', String? label, bool assignAll = false}) async {
    final raw = await ref.read(apiClientProvider).postJson(
        '/settlement/tables/$tableId/receipts',
        {'mode': mode, 'label': ?label, 'assignAll': assignAll});
    return _billFrom(raw);
  }

  Future<Bill> deleteReceipt(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .deleteJson('/settlement/receipts/$receiptId');
    return _billFrom(raw);
  }

  Future<Bill> assignLine(String receiptId, String ticketId, int qtyUnits) async {
    final raw = await ref.read(apiClientProvider).postJson(
        '/settlement/receipts/$receiptId/lines',
        {'ticketId': ticketId, 'qtyUnits': qtyUnits});
    return _billFrom(raw);
  }

  Future<Bill> splitEven(String tableId, int n) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/tables/$tableId/split-even', {'n': n});
    return _billFrom(raw);
  }

  Future<Bill> recordPayment(String receiptId,
      {required String method,
      required int amount,
      int? tendered,
      String? note}) async {
    final raw = await ref.read(apiClientProvider).postJson(
        '/settlement/receipts/$receiptId/payments',
        {'method': method, 'amount': amount, 'tendered': ?tendered, 'note': ?note});
    return _billFrom(raw);
  }

  Future<Bill> refund(String receiptId,
      {required String method, required int amount, String? note}) async {
    final raw = await ref.read(apiClientProvider).postJson(
        '/settlement/receipts/$receiptId/refund',
        {'method': method, 'amount': amount, 'note': ?note});
    return _billFrom(raw);
  }

  Future<Bill> reopen(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/reopen', const {});
    return _billFrom(raw);
  }

  // ── printing the money document (server renders to a VENUE printer; device
  //    printers render client-side via the picker). Returns null on success or
  //    a human message on failure. See ADR-0023 / ADR-0020. ──

  Future<String?> printBill(String tableId, String printerId) =>
      _print('/settlement/tables/$tableId/bill/print', printerId);

  Future<String?> printReceipt(String receiptId, String printerId) =>
      _print('/settlement/receipts/$receiptId/print', printerId);

  Future<String?> _print(String path, String printerId) async {
    try {
      await ref.read(apiClientProvider).postJson(path, {'printerId': printerId});
      return null;
    } on ApiException catch (e) {
      try {
        final j = e.body.isEmpty ? null : jsonDecode(e.body);
        if (j is Map && j['message'] is String) return j['message'] as String;
      } catch (_) {}
      return 'Gagal mencetak (${e.statusCode}).';
    }
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementRepository, List<BillSummary>>((ref) {
  ref.watch(apiConfigProvider);
  return SettlementRepository(ref: ref);
});

/// Canonical bill-detail source for one table. Re-fetched whenever the screen
/// invalidates it after a mutation, or on a WS `bill.updated`.
final billDetailProvider =
    FutureProvider.family.autoDispose<Bill, String>((ref, tableId) async {
  ref.watch(apiConfigProvider);
  // Refetch on any bill change broadcast for this table.
  final sub = ref.read(wsClientProvider).events.listen((ev) {
    if (ev.type == WsEventTypes.billUpdated &&
        ev.payload['tableId'] == tableId) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);
  return ref.read(settlementProvider.notifier).fetchBill(tableId);
});
