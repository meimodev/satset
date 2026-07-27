import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

/// Bootstrap status for the cashier payable list (spinner / retry banner).
final settlementStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

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
      ref.read(settlementStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    ref.read(settlementStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(settlementStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      ref.read(settlementStatusProvider.notifier).state = AsyncValue.error(
        e,
        st,
      );
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
      final raw =
          await ref.read(apiClientProvider).getJson('/settlement/payable')
              as List;
      state = [
        for (final e in raw)
          BillSummary.fromJson((e as Map).cast<String, dynamic>()),
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

  Future<Bill> fetchBill(String visitId) async {
    final raw = await ref
        .read(apiClientProvider)
        .getJson('/settlement/visits/$visitId/bill');
    return Bill.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<Bill> _billFrom(Object? raw) async {
    final map = (raw as Map).cast<String, dynamic>();
    return Bill.fromJson((map['bill'] as Map).cast<String, dynamic>());
  }

  Future<Bill> createReceipt(
    String visitId, {
    String mode = 'itemized',
    String? label,
    bool assignAll = false,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/receipts',
      {'mode': mode, 'label': ?label, 'assignAll': assignAll},
    );
    return _billFrom(raw);
  }

  Future<Bill> deleteReceipt(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .deleteJson('/settlement/receipts/$receiptId');
    return _billFrom(raw);
  }

  /// Undo the chosen billing method while no money has been taken: drop every
  /// receipt so the bill returns to the mode chooser. Caller must gate on
  /// `paidAmount == 0` — the server rejects deleting a paid receipt.
  Future<Bill> resetBilling(Bill bill) async {
    Bill? last;
    for (final r in bill.receipts) {
      last = await deleteReceipt(r.id);
    }
    return last ?? bill;
  }

  Future<Bill> assignLine(
    String receiptId,
    String ticketId,
    int qtyUnits,
  ) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/lines',
      {'ticketId': ticketId, 'qtyUnits': qtyUnits},
    );
    return _billFrom(raw);
  }

  Future<Bill> splitEven(String visitId, int n) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/split-even',
      {'n': n},
    );
    return _billFrom(raw);
  }

  /// Bill close (Tutup tagihan). `writeOff` records a tak-tertagih loss
  /// (needs the refund cap + reason, server-enforced). See ADR-0024.
  Future<void> closeBill(
    String visitId, {
    bool writeOff = false,
    String? reason,
  }) async {
    await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/bill-close',
      {'writeOff': writeOff, 'reason': ?reason},
    );
  }

  /// Takeaway handover ("Serahkan") — the first/second axis for a Bawa pulang
  /// visit, replacing table-close. Server stamps `tableFreedAt`; if the bill is
  /// already closed it snapshots + deletes. See ADR-0026.
  Future<void> handover(String visitId) async {
    await ref
        .read(apiClientProvider)
        .postJson('/visits/$visitId/handover', const {});
  }

  /// Reopen (unlock) a locked-but-not-yet-snapshotted bill.
  Future<Bill> reopenBill(String visitId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/visits/$visitId/reopen', const {});
    return _billFrom(raw);
  }

  /// Past bills (last `days`, default 7), newest-first. `tableId` null ⇒
  /// venue-wide (the cashier's Riwayat tab); set ⇒ scoped to one table (the
  /// bill-screen Riwayat shortcut). One endpoint, both callers. See ADR-0024.
  Future<List<PastBillSummary>> fetchHistory({
    String? tableId,
    int days = 7,
  }) async {
    final path = tableId != null && tableId.isNotEmpty
        ? '/settlement/history?days=$days&tableId=$tableId'
        : '/settlement/history?days=$days';
    final raw = await ref.read(apiClientProvider).getJson(path) as List;
    return [
      for (final e in raw)
        PastBillSummary.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  /// One past bill's full detail (Struk pembayaran view) from a session.
  Future<Bill> fetchSessionBill(String sessionId) async {
    final raw = await ref
        .read(apiClientProvider)
        .getJson('/settlement/sessions/$sessionId/bill');
    return Bill.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<Bill> recordPayment(
    String receiptId, {
    required String method,
    required int amount,
    int? tendered,
    String? note,
    String? photoBase64,
  }) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/payments', {
          'method': method,
          'amount': amount,
          'tendered': ?tendered,
          'note': ?note,
          'photoBase64': ?photoBase64,
        });
    return _billFrom(raw);
  }

  /// Proof-photo bytes for a non-cash payment (ADR-0025). [history] reads the
  /// snapshotted (past-bill / report) blob; otherwise the live payment blob.
  Future<Uint8List> paymentPhoto(String paymentId, {bool history = false}) {
    final base = history
        ? '/settlement/history/payments'
        : '/settlement/payments';
    return ref.read(apiClientProvider).getBytes('$base/$paymentId/photo');
  }

  Future<Bill> refund(
    String receiptId, {
    required String method,
    required int amount,
    String? note,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/refund',
      {'method': method, 'amount': amount, 'note': ?note},
    );
    return _billFrom(raw);
  }

  Future<Bill> reopen(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/reopen', const {});
    return _billFrom(raw);
  }

  // ── discounts (ADR-0037). Cashier-stage only; the cashier picks a preset,
  //    never a free-typed rate. `ticketId` null ⇒ whole-order discount.
  //    `approverPin` carries a manager step-up when the signed-in user lacks
  //    `applyDiscount`; it is verified server-side, so an omitted or wrong PIN
  //    simply fails with `approval_required`. ──

  Future<Bill> applyDiscount(
    String receiptId, {
    required String presetId,
    String? ticketId,
    String? approverPin,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/discounts',
      {
        'presetId': presetId,
        'ticketId': ?ticketId,
        'approverPin': ?approverPin,
      },
    );
    return _billFrom(raw);
  }

  Future<Bill> removeDiscount(
    String receiptId,
    String discountId, {
    String? approverPin,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/discounts/$discountId/remove',
      {'approverPin': ?approverPin},
    );
    return _billFrom(raw);
  }

  // ── printing the money document (server renders to a VENUE printer; device
  //    printers render client-side via the picker). Returns null on success or
  //    a human message on failure. See ADR-0023 / ADR-0020. ──

  Future<String?> printBill(String visitId, String printerId) =>
      _print('/settlement/visits/$visitId/bill/print', printerId);

  Future<String?> printReceipt(String receiptId, String printerId) =>
      _print('/settlement/receipts/$receiptId/print', printerId);

  Future<String?> _print(String path, String printerId) async {
    try {
      await ref.read(apiClientProvider).postJson(path, {
        'printerId': printerId,
      });
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

/// Canonical bill-detail source for one VISIT. Re-fetched whenever the screen
/// invalidates it after a mutation, or on a WS `bill.updated`/`tableSession.closed`.
final billDetailProvider = FutureProvider.family.autoDispose<Bill, String>((
  ref,
  visitId,
) async {
  ref.watch(apiConfigProvider);
  final sub = ref.read(wsClientProvider).events.listen((ev) {
    if ((ev.type == WsEventTypes.billUpdated &&
            ev.payload['visitId'] == visitId) ||
        (ev.type == WsEventTypes.tableSessionClosed &&
            ev.payload['visitId'] == visitId)) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);
  return ref.read(settlementProvider.notifier).fetchBill(visitId);
});

/// Per-table past bills (last 7 days). Keyed by tableId — backs the bill
/// screen's Riwayat shortcut. Refetched on `tableSession.closed` for *this*
/// table (a new past bill landed there).
final pastBillsProvider = FutureProvider.family
    .autoDispose<List<PastBillSummary>, String>((ref, tableId) async {
      ref.watch(apiConfigProvider);
      final sub = ref.read(wsClientProvider).events.listen((ev) {
        if (ev.type == WsEventTypes.tableSessionClosed &&
            ev.payload['tableId'] == tableId) {
          ref.invalidateSelf();
        }
      });
      ref.onDispose(sub.cancel);
      return ref
          .read(settlementProvider.notifier)
          .fetchHistory(tableId: tableId);
    });

/// Venue-wide past bills (last 7 days) — backs the cashier's Riwayat tab.
/// Refetched on *any* `tableSession.closed`: a bill closed at any table lands a
/// new history row, so membership of the venue-wide list changes. See ADR-0024.
final venueHistoryProvider = FutureProvider.autoDispose<List<PastBillSummary>>((
  ref,
) async {
  ref.watch(apiConfigProvider);
  final sub = ref.read(wsClientProvider).events.listen((ev) {
    if (ev.type == WsEventTypes.tableSessionClosed) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return ref.read(settlementProvider.notifier).fetchHistory();
});
