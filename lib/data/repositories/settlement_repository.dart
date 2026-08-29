import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
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

  /// Mint a receipt. [lines] assigns in the same transaction — the
  /// tap-to-select-and-pay fast path needs mint + assign to be one act, so a
  /// failure cannot strand a half-built receipt on the bill (ADR-0067).
  Future<Bill> createReceipt(
    String visitId, {
    String mode = 'itemized',
    String? label,
    bool assignAll = false,
    List<BillReceiptLine> lines = const [],
    String? memberId,
  }) async => (await mintReceipt(
    visitId,
    mode: mode,
    label: label,
    assignAll: assignAll,
    lines: lines,
    memberId: memberId,
  )).bill;

  /// As [createReceipt], but hands back the new receipt's id.
  ///
  /// The settle pane mints and pays in one gesture (ADR-0067), so it needs the
  /// id the route already returns and [createReceipt] discards.
  Future<({String receiptId, Bill bill})> mintReceipt(
    String visitId, {
    String mode = 'itemized',
    String? label,
    bool assignAll = false,
    List<BillReceiptLine> lines = const [],

    /// The [[Pemilik struk]] this share is born for (ADR-0120). The pane mints
    /// at confirm, so there is no receipt to name afterwards without opening a
    /// window where a named struk is half-made.
    String? memberId,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/receipts',
      {
        'mode': mode,
        'label': ?label,
        'assignAll': assignAll,
        'memberId': ?memberId,
        if (lines.isNotEmpty)
          'lines': [
            for (final l in lines)
              {'ticketId': l.ticketId, 'qtyUnits': l.qtyUnits},
          ],
      },
    );
    final map = (raw as Map).cast<String, dynamic>();
    return (
      receiptId: map['receiptId'] as String,
      bill: Bill.fromJson((map['bill'] as Map).cast<String, dynamic>()),
    );
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

  /// Past bills (last `days`, default 7), newest-first, capped at `limit` rows.
  /// `tableId` null ⇒ venue-wide (the cashier's Riwayat tab); set ⇒ scoped to
  /// one table. The scoped form has no caller since ADR-0064 retired the
  /// bill-screen Riwayat shortcut — the route keeps it. See ADR-0024.
  ///
  /// Returns the page *and* the window's true total, which is not `rows.length`
  /// once the window outgrows a page — the cashier's Lunas count reads the
  /// total (ADR-0079).
  Future<PastBillPage> fetchHistory({
    String? tableId,
    int days = 7,
    int limit = historyPageSize,
  }) async {
    final scope = tableId != null && tableId.isNotEmpty
        ? '&tableId=$tableId'
        : '';
    final raw =
        await ref
                .read(apiClientProvider)
                .getJson('/settlement/history?days=$days&limit=$limit$scope')
            as Map;
    final json = raw.cast<String, dynamic>();
    return PastBillPage(
      rows: [
        for (final e in (json['rows'] as List? ?? const []))
          PastBillSummary.fromJson((e as Map).cast<String, dynamic>()),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
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

  /// Proof-photo bytes for one id (ADR-0025, ADR-0082), from whichever route
  /// [scope] names.
  ///
  /// [ProofScope.audit] is the expensive one — the server looks in both the live
  /// and snapshotted tables, because the venue log scrolls across the bill close
  /// and cannot know which side a row fell on. A caller that already knows keeps
  /// its cheaper single lookup.
  Future<Uint8List> proofPhoto(String id, ProofScope scope) {
    final path = switch (scope) {
      ProofScope.live => '/settlement/payments/$id/photo',
      ProofScope.history => '/settlement/history/payments/$id/photo',
      ProofScope.audit => '/audit/payments/$id/photo',
      ProofScope.cash => '/cash/$id/photo',
    };
    return ref.read(apiClientProvider).getBytes(path);
  }

  /// Unwind part or all of one payment **leg** (ADR-0121). The method is
  /// inherited from [paymentId] and never sent — a struk may hold two `tunai`
  /// legs, which a method cannot tell apart, and a `piutang` leg has no money
  /// method to name at all.
  Future<Bill> refund(
    String receiptId, {
    required String paymentId,
    required int amount,
    String? note,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/refund',
      {'paymentId': paymentId, 'amount': amount, 'note': ?note},
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

  /// The table-wide promo (ADR-0070). Attaches to the visit, not a receipt, so
  /// it can be applied before the first receipt is minted — which under
  /// ADR-0067 is most of the time. Rejected once any receipt is paid.
  Future<Bill> applyBillDiscount(
    String visitId, {
    required String presetId,
    String? approverPin,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/discounts',
      {'presetId': presetId, 'approverPin': ?approverPin},
    );
    return _billFrom(raw);
  }

  Future<Bill> removeBillDiscount(
    String visitId,
    String discountId, {
    String? approverPin,
  }) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/discounts/$discountId/remove',
      {'approverPin': ?approverPin},
    );
    return _billFrom(raw);
  }

  // ── membership at the till (ADR-0093). All four move a live bill, so they
  //    return one, like every other settlement act. ──

  /// Attach a [[Pelanggan (member)]]. The venue's standing member discount, if
  /// it configured one, lands in its own slot server-side — nothing here has to
  /// remember to apply it.
  Future<Bill> attachMember(String visitId, String memberId) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/member',
      {'memberId': memberId},
    );
    return _billFrom(raw);
  }

  Future<Bill> detachMember(String visitId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/visits/$visitId/member/detach', const {});
    return _billFrom(raw);
  }

  /// Spend points as money off this bill. The ledger row and the discount land
  /// together server-side or not at all.
  Future<Bill> redeemPoints(String visitId, int points) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/redeem',
      {'points': points},
    );
    return _billFrom(raw);
  }

  Future<Bill> removeRedeem(String visitId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/visits/$visitId/redeem/remove', const {});
    return _billFrom(raw);
  }

  // ── the [[Pemilik struk]]: the same four acts, one share at a time
  //    (ADR-0118). Each returns the whole bill because a share's give-back
  //    moves the bill's ladder, and the Siapa step draws every row. ──

  Future<Bill> attachReceiptMember(String receiptId, String memberId) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/member',
      {'memberId': memberId},
    );
    return _billFrom(raw);
  }

  Future<Bill> detachReceiptMember(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/member/detach', const {});
    return _billFrom(raw);
  }

  /// Spend this guest's points against their own share. The ceiling is what
  /// that share can absorb, not the whole bill.
  Future<Bill> redeemOnReceipt(String receiptId, int points) async {
    final raw = await ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/redeem',
      {'points': points},
    );
    return _billFrom(raw);
  }

  Future<Bill> removeReceiptRedeem(String receiptId) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/redeem/remove', const {});
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
      // The code, not the server's `message`: that message is a developer
      // string in the host tablet's language (ADR-0085).
      final l = ref.read(l10nProvider);
      return switch (e.code) {
        'no_lines' => l.prnErrNoLines,
        'print_failed' => l.prnErrNotConnected,
        'no_printer' => l.prnErrNoPrinter,
        _ => l.prnErrFailedCode('${e.statusCode}'),
      };
    }
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementRepository, List<BillSummary>>((ref) {
      ref.watch(apiConfigProvider);
      return SettlementRepository(ref: ref);
    });

/// Where a proof blob is read from. Four routes resolve an id, and the only
/// thing that differs between them is which.
enum ProofScope {
  /// A payment on a live, still-open bill.
  live,

  /// The snapshotted copy frozen at bill close — past bills, reports.
  history,

  /// Named by an audit row (ADR-0086); the server looks on both sides of the
  /// bill close, because the venue log scrolls across it.
  audit,

  /// A petty cash expense's receipt photo (§Kas kecil).
  cash,
}

/// Proof-photo bytes for one id, keyed by `(id, scope)`.
///
/// Cached rather than fetched per build: the same slip is shown on the live
/// bill, on the settled bill detail and on the venue log, and the thumb used to
/// rebuild a `Future` inside `build()`, so every theme flip and parent
/// `setState` re-pulled the JPEG over the pinned client. Null when unpaired.
/// See ADR-0082.
///
/// Was three near-identical providers, collapsed when petty cash became the
/// fourth caller — exactly the trigger the old `ponytail:` note named.
final proofPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String id, ProofScope scope})>((ref, key) async {
      if (ref.watch(apiConfigProvider) == null) return null;
      final bytes = await ref
          .read(settlementProvider.notifier)
          .proofPhoto(key.id, key.scope);
      ref.keepAlive();
      return bytes;
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

// The per-table `pastBillsProvider` went with the bill screen's Riwayat
// shortcut (ADR-0064) — per-table history is the venue-wide list filtered by
// its table chips. `fetchHistory` keeps its `tableId` parameter; the route
// still takes one.

/// How many history rows the cashier screen currently wants. Raised a page at a
/// time as they scroll (ADR-0079); never lowered while the screen is up, so
/// rows can't vanish from under a scrolled thumb when a bill closes.
final historyLimitProvider = StateProvider<int>((ref) {
  // A new pairing is a new venue's history — start at page one.
  ref.watch(apiConfigProvider);
  return historyPageSize;
});

/// Venue-wide past bills (last 7 days, newest `limit` rows) — backs the
/// cashier's Lunas segment. Refetched on *any* `tableSession.closed`: a bill
/// closed at any table lands a new history row, so membership of the
/// venue-wide list changes. See ADR-0024.
///
/// ponytail: paging is a growing limit refetched whole, not a cursor — unlike
/// the audit log next door (ADR-0072), whose pages are stable because nothing
/// prepends to them. Here every bill close invalidates page one, so cursor
/// pages would need reconciling against a list that moved underneath them.
/// Ceiling is `historyPageCeiling`; past that, cursor paging is the upgrade.
/// See ADR-0079.
final venueHistoryProvider = FutureProvider.autoDispose<PastBillPage>((
  ref,
) async {
  ref.watch(apiConfigProvider);
  // Watched, not family-keyed: re-running on a changed limit leaves the old
  // page on the `AsyncLoading`, so growing mid-scroll shows the rows already
  // there plus a foot spinner instead of collapsing the grid. A family would
  // hand back a brand-new, empty instance.
  final limit = ref.watch(historyLimitProvider);
  final sub = ref.read(wsClientProvider).events.listen((ev) {
    if (ev.type == WsEventTypes.tableSessionClosed) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return ref.read(settlementProvider.notifier).fetchHistory(limit: limit);
});
