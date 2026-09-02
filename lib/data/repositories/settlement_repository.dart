import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/settlement_projection.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
      state = _summaries(raw);
      SatLog.repo('settlement.payable n=${state.length}');
      unawaited(_journal.cachePayable(raw));
      unawaited(_prefetchBills());
    } catch (e) {
      SatLog.repo('settlement.payable fail $e');
      // A cold boot with no host. The bills are all cached (ADR-0123 §Q19) but
      // the list that reaches them is fetched, so without this the cashier
      // opens `/kasir` to an empty screen and a strip telling them money is
      // still queued — every bill present and none of them reachable.
      if (state.isEmpty) {
        final cached = await _journal.cachedPayable();
        if (cached != null) {
          state = _summaries(cached);
          SatLog.repo('settlement.payable cached n=${state.length}');
          return;
        }
      }
      rethrow;
    } finally {
      _refetching = false;
    }
  }

  /// Keep a full [[Bill (tab)]] cached for **every** open visit, not just the
  /// one the cashier happened to open (ADR-0123 §Q19).
  ///
  /// Caching on open only would make the offline fallback's availability depend
  /// on where a thumb was five minutes ago, which is the worst possible
  /// property for a fallback. Throttled per visit: a bill is re-pulled when its
  /// cache is missing or older than [_billCacheTtl], so the ordinary WS churn
  /// does not turn one list refresh into twenty round trips.
  static const _billCacheTtl = Duration(minutes: 2);

  List<BillSummary> _summaries(List<dynamic> raw) => [
    for (final e in raw)
      BillSummary.fromJson((e as Map).cast<String, dynamic>()),
  ];

  /// Whether the prefetch sweep should re-pull this visit's bill.
  ///
  /// Pulled out because the two conditions interact, and the interaction is
  /// what shipped broken: skipping a local-authoritative visit is right, but
  /// only if skipping it does not also *count* as having swept it.
  static bool shouldRefetchBill({
    required DateTime? fetchedAt,
    required DateTime now,
    required bool local,
  }) {
    if (local) return false;
    if (fetchedAt == null) return true;
    return now.difference(fetchedAt) >= _billCacheTtl;
  }

  Future<void> _prefetchBills() async {
    final now = SatClock.now();
    final journal = _journal;
    // Per visit, not one clock for the sweep. A global throttle skips the
    // visit that just drained: it was [[Kunjungan otoritatif-lokal]] when the
    // reconnect sweep ran, so it was passed over, and the drain's own refresh
    // moments later then found the sweep clock fresh and did nothing — leaving
    // a cache that predates the settlement it just sent. The next time the
    // till goes dark that bill reads unpaid, and the cashier collects twice.
    final ages = await journal.cacheAges();
    for (final b in state) {
      if (!shouldRefetchBill(
        fetchedAt: ages[b.visitId],
        now: now,
        // A visit the till is already carrying answers off its own journal; its
        // cache is the base those events apply to and must not be overwritten
        // with a host view that predates them.
        local: ref.read(settlementJournalProvider).isLocal(b.visitId),
      )) {
        continue;
      }
      try {
        final raw = await ref
            .read(apiClientProvider)
            .getJson('/settlement/visits/${b.visitId}/bill');
        await journal.cacheBill(
          b.visitId,
          (raw as Map).cast<String, dynamic>(),
        );
      } catch (_) {
        // The host went away mid-sweep. Whatever is cached stays cached.
        return;
      }
    }
  }

  // ── mutations (each returns the fresh Bill; the family provider is the
  //    canonical detail source and is invalidated by the screen / WS) ──

  Future<Bill> fetchBill(String visitId) async {
    // A visit the till is still carrying answers off its own journal — asking
    // the host would render the world as it was before the backlog landed
    // (ADR-0123 §local-authoritative).
    if (await _isLocal(visitId)) return _project(visitId);
    try {
      final raw = await ref
          .read(apiClientProvider)
          .getJson('/settlement/visits/$visitId/bill');
      final map = (raw as Map).cast<String, dynamic>();
      await _journal.cacheBill(visitId, map);
      return Bill.fromJson(map);
    } catch (_) {
      // The host went away mid-read. The cached bill is what the cashier was
      // last shown, and it is settleable — that is the whole point of caching
      // every open visit rather than only the one somebody opened.
      final bill = await _project(visitId);
      return bill;
    }
  }

  Future<Bill> _billFrom(Object? raw) async {
    final map = (raw as Map).cast<String, dynamic>();
    final bill = (map['bill'] as Map).cast<String, dynamic>();
    await _journal.cacheBill(bill['visitId'] as String? ?? '', bill);
    return Bill.fromJson(bill);
  }

  // ── the offline path (ADR-0123) ───────────────────────────────────────────

  SettlementJournal get _journal =>
      ref.read(settlementJournalProvider.notifier);

  /// Is this visit [[Kunjungan otoritatif-lokal|local-authoritative]]?
  ///
  /// Three ways in, and the journal is the one that outlives the outage: a
  /// visit whose chain has not drained keeps taking its acts locally even
  /// after the socket returns, or a live write lands ahead of the queued
  /// events and the projection the cashier is reading becomes a lie.
  Future<bool> _isLocal(String visitId) async {
    if (ref.read(settlementJournalProvider).isLocal(visitId)) return true;
    return ref.read(wsConnStateProvider) != WsConnState.open;
  }

  Future<bool> _isLocalReceipt(String receiptId) async {
    final v = await _visitOfReceipt(receiptId);
    return v != null && await _isLocal(v);
  }

  ProjectionConfig _projectionConfig() {
    final v = ref.read(venueSettingsProvider);
    return ProjectionConfig(
      tax: v.toTaxServiceConfig(),
      pointValue: v.memberPointValue,
    );
  }

  /// The cached bill with this visit's journal applied. Throws when the visit
  /// was never cached — a bill this device has never seen cannot be settled
  /// from nothing.
  Future<Bill> _project(String visitId) async {
    final cached = await _journal.cachedBill(visitId);
    if (cached == null) {
      throw StateError('no cached bill for $visitId');
    }
    final events = await _journal.eventsFor(visitId);
    return Bill.fromJson(projectBill(cached, events, _projectionConfig()));
  }

  /// Perform one settlement act, online or captured.
  ///
  /// [id] is minted **before** the request goes out and is both the row id the
  /// act creates and its idempotency key — which is what lets a request that
  /// timed out after the host committed be replayed harmlessly, and what lets
  /// a captured act name the row it made.
  ///
  /// A 4xx is the host refusing an online caller and is rethrown untouched. A
  /// transport failure is captured instead: the cashier is standing in front of
  /// a guest and refusing the act is worse than replaying it.
  Future<Bill> _act({
    required String visitId,
    required SettlementEventKind kind,
    required Map<String, dynamic> payload,
    required Future<Object?> Function(String id) online,
    String? id,
  }) async {
    final eventId = id ?? _uuid.v4();
    if (await _isLocal(visitId)) {
      await _capture(visitId, kind, payload, eventId);
      return _project(visitId);
    }
    try {
      return await _billFrom(await online(eventId));
    } on ApiException {
      rethrow;
    } catch (_) {
      await _capture(visitId, kind, payload, eventId);
      return _project(visitId);
    }
  }

  /// The visit a receipt belongs to, off the cached bills.
  ///
  /// Receipt-scoped routes name only the receipt, but the journal is ordered
  /// **per visit** — a chain is what makes a settlement replayable, and a
  /// receipt with no visit has no chain to join.
  Future<String?> _visitOfReceipt(String receiptId) =>
      _journal.visitOfReceipt(receiptId);

  /// [_act] for a route that names a receipt rather than a visit.
  ///
  /// A receipt whose visit this device has never cached cannot be captured, so
  /// the online call is made and its failure surfaces — better a refusal the
  /// cashier sees than an event with nowhere to replay.
  Future<Bill> _actOnReceipt(
    String receiptId,
    SettlementEventKind kind,
    Map<String, dynamic> payload,
    Future<Object?> Function(String id) online, {
    String? id,
  }) async {
    final visitId = await _visitOfReceipt(receiptId);
    if (visitId == null) return _billFrom(await online(id ?? _uuid.v4()));
    return _act(
      visitId: visitId,
      kind: kind,
      id: id,
      payload: {'receiptId': receiptId, ...payload},
      online: online,
    );
  }

  Future<void> _capture(
    String visitId,
    SettlementEventKind kind,
    Map<String, dynamic> payload,
    String id,
  ) async {
    try {
      await _journal.append(
        visitId: visitId,
        kind: kind,
        payload: payload,
        id: id,
        actorId: ref.read(authStateProvider).user?.id ?? '',
      );
    } on SettlementJournalFull {
      // A cap trips through the same surface a refusal does, never as a silent
      // drop: what is being refused here is an act on money.
      _refuse(ref.read(l10nProvider).cshJournalFull, 'journal_full');
    }
  }

  /// Surface a client-side refusal on the shell's error bus (ADR-0103) and
  /// stop the act. Used where the till itself says no — a manager step-up
  /// while terputus, a full journal — rather than the host.
  Never _refuse(String message, [String code = 'refused']) {
    ref
        .read(errorBusServiceProvider)
        .push(message, level: AppErrorLevel.error, code: code);
    throw StateError(code);
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
    // The id is minted here, not by the host (ADR-0123) — the settle pane pays
    // in the same gesture, and a captured payment has to be able to name the
    // struk it is for before that struk has ever reached the host.
    final receiptId = _uuid.v4();
    final lineSpecs = [
      for (final l in lines) {'ticketId': l.ticketId, 'qtyUnits': l.qtyUnits},
    ];
    final bill = await _act(
      visitId: visitId,
      kind: SettlementEventKind.mintReceipt,
      id: receiptId,
      payload: {
        'mode': mode,
        'label': ?label,
        'assignAll': assignAll,
        'memberId': ?memberId,
        if (lineSpecs.isNotEmpty) 'lines': lineSpecs,
      },
      online: (id) => ref
          .read(apiClientProvider)
          .postJson('/settlement/visits/$visitId/receipts', {
            'id': id,
            'mode': mode,
            'label': ?label,
            'assignAll': assignAll,
            'memberId': ?memberId,
            if (lineSpecs.isNotEmpty) 'lines': lineSpecs,
          }, idempotencyKey: id),
    );
    return (receiptId: receiptId, bill: bill);
  }

  Future<Bill> deleteReceipt(String receiptId) async => _actOnReceipt(
    receiptId,
    SettlementEventKind.deleteReceipt,
    const {},
    (id) => ref
        .read(apiClientProvider)
        .deleteJson('/settlement/receipts/$receiptId', idempotencyKey: id),
  );

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

  Future<Bill> assignLine(String receiptId, String ticketId, int qtyUnits) =>
      _actOnReceipt(
        receiptId,
        SettlementEventKind.assignLine,
        {'ticketId': ticketId, 'qtyUnits': qtyUnits},
        (id) => ref.read(apiClientProvider).postJson(
          '/settlement/receipts/$receiptId/lines',
          {'ticketId': ticketId, 'qtyUnits': qtyUnits},
          idempotencyKey: id,
        ),
      );

  Future<Bill> splitEven(String visitId, int n) {
    // One id per share, minted here for the same reason a receipt's is: the
    // guest is told which slip is theirs before the host has heard of it.
    final ids = [for (var i = 0; i < n; i++) _uuid.v4()];
    return _act(
      visitId: visitId,
      kind: SettlementEventKind.splitEven,
      payload: {'n': n, 'ids': ids},
      online: (id) => ref.read(apiClientProvider).postJson(
        '/settlement/visits/$visitId/split-even',
        {'n': n, 'ids': ids},
        idempotencyKey: id,
      ),
    );
  }

  /// Bill close (Tutup tagihan). `writeOff` records a tak-tertagih loss
  /// (needs the refund cap + reason, server-enforced). See ADR-0024.
  Future<void> closeBill(
    String visitId, {
    bool writeOff = false,
    String? reason,
  }) => _act(
    visitId: visitId,
    kind: SettlementEventKind.closeBill,
    payload: {'writeOff': writeOff, 'reason': ?reason},
    online: (id) => ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/bill-close',
      {'writeOff': writeOff, 'reason': ?reason},
      idempotencyKey: id,
    ),
  );

  /// Takeaway handover ("Serahkan") — the first/second axis for a Bawa pulang
  /// visit, replacing table-close. Server stamps `tableFreedAt`; if the bill is
  /// already closed it snapshots + deletes. See ADR-0026.
  Future<void> handover(String visitId) async {
    await ref
        .read(apiClientProvider)
        .postJson('/visits/$visitId/handover', const {});
  }

  /// Reopen (unlock) a locked-but-not-yet-snapshotted bill.
  Future<Bill> reopenBill(String visitId) => _act(
    visitId: visitId,
    kind: SettlementEventKind.reopenBill,
    payload: const {},
    online: (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/visits/$visitId/reopen',
          const {},
          idempotencyKey: id,
        ),
  );

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
    bool onAccount = false,
  }) async {
    final scope = tableId != null && tableId.isNotEmpty
        ? '&tableId=$tableId'
        : '';
    // Filtered server-side, never over the loaded page: the rows on the wire
    // are one page of the window, so a client-side filter would report "3
    // tabs" when it means "3 in the 60 rows I happen to hold". Same trap
    // ADR-0079 kept out of the Lunas count.
    final tabs = onAccount ? '&onAccount=1' : '';
    final raw =
        await ref
                .read(apiClientProvider)
                .getJson(
                  '/settlement/history?days=$days&limit=$limit$scope$tabs',
                )
            as Map;
    final json = raw.cast<String, dynamic>();
    return PastBillPage(
      rows: [
        for (final e in (json['rows'] as List? ?? const []))
          PastBillSummary.fromJson((e as Map).cast<String, dynamic>()),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
      piutangTotal: (json['piutangTotal'] as num?)?.toInt() ?? 0,
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
    String? memberId,
  }) => _actOnReceipt(
    receiptId,
    SettlementEventKind.recordPayment,
    {
      'method': method,
      'amount': amount,
      'tendered': ?tendered,
      'note': ?note,
      // Carried on the event so a captured proof still reaches the host. It
      // never enters the projection — the money has to add up offline, the
      // photo only has to arrive.
      'photoBase64': ?photoBase64,
      'memberId': ?memberId,
    },
    (id) => ref
        .read(apiClientProvider)
        .postJson('/settlement/receipts/$receiptId/payments', {
          'id': id,
          'method': method,
          'amount': amount,
          'tendered': ?tendered,
          'note': ?note,
          'photoBase64': ?photoBase64,
          'memberId': ?memberId,
        }, idempotencyKey: id),
  );

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
  }) => _actOnReceipt(
    receiptId,
    SettlementEventKind.refund,
    {'paymentId': paymentId, 'amount': amount, 'note': ?note},
    (id) => ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/refund',
      {'id': id, 'paymentId': paymentId, 'amount': amount, 'note': ?note},
      idempotencyKey: id,
    ),
  );

  Future<Bill> reopen(String receiptId) => _actOnReceipt(
    receiptId,
    SettlementEventKind.reopenReceipt,
    const {},
    (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/receipts/$receiptId/reopen',
          const {},
          idempotencyKey: id,
        ),
  );

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
    // A manager step-up has no offline path (ADR-0123, following ADR-0099):
    // the PIN is verified against a salted hash on the host, and caching those
    // on a shared handset makes a stolen tablet a manager. A cashier who holds
    // `applyDiscount` outright keeps every discount offline.
    if (approverPin != null && await _isLocalReceipt(receiptId)) {
      _refuse(ref.read(l10nProvider).cshApprovalOffline, 'approval_offline');
    }
    return _actOnReceipt(
      receiptId,
      SettlementEventKind.applyDiscount,
      {'presetId': presetId, 'ticketId': ?ticketId},
      (id) => ref
          .read(apiClientProvider)
          .postJson('/settlement/receipts/$receiptId/discounts', {
            'id': id,
            'presetId': presetId,
            'ticketId': ?ticketId,
            'approverPin': ?approverPin,
          }, idempotencyKey: id),
    );
  }

  Future<Bill> removeDiscount(
    String receiptId,
    String discountId, {
    String? approverPin,
  }) async {
    if (approverPin != null && await _isLocalReceipt(receiptId)) {
      _refuse(ref.read(l10nProvider).cshApprovalOffline, 'approval_offline');
    }
    return _actOnReceipt(
      receiptId,
      SettlementEventKind.removeDiscount,
      {'discountId': discountId},
      (id) => ref.read(apiClientProvider).postJson(
        '/settlement/receipts/$receiptId/discounts/$discountId/remove',
        {'approverPin': ?approverPin},
        idempotencyKey: id,
      ),
    );
  }

  /// The table-wide promo (ADR-0070). Attaches to the visit, not a receipt, so
  /// it can be applied before the first receipt is minted — which under
  /// ADR-0067 is most of the time. Rejected once any receipt is paid.
  Future<Bill> applyBillDiscount(
    String visitId, {
    required String presetId,
    String? approverPin,
  }) async {
    if (approverPin != null && await _isLocal(visitId)) {
      _refuse(ref.read(l10nProvider).cshApprovalOffline, 'approval_offline');
    }
    return _act(
      visitId: visitId,
      kind: SettlementEventKind.applyBillDiscount,
      payload: {'presetId': presetId},
      online: (id) => ref.read(apiClientProvider).postJson(
        '/settlement/visits/$visitId/discounts',
        {'id': id, 'presetId': presetId, 'approverPin': ?approverPin},
        idempotencyKey: id,
      ),
    );
  }

  Future<Bill> removeBillDiscount(
    String visitId,
    String discountId, {
    String? approverPin,
  }) async {
    if (approverPin != null && await _isLocal(visitId)) {
      _refuse(ref.read(l10nProvider).cshApprovalOffline, 'approval_offline');
    }
    return _act(
      visitId: visitId,
      kind: SettlementEventKind.removeBillDiscount,
      payload: {'discountId': discountId},
      online: (id) => ref.read(apiClientProvider).postJson(
        '/settlement/visits/$visitId/discounts/$discountId/remove',
        {'approverPin': ?approverPin},
        idempotencyKey: id,
      ),
    );
  }

  // ── membership at the till (ADR-0093). All four move a live bill, so they
  //    return one, like every other settlement act. ──

  /// Attach a [[Pelanggan (member)]]. The venue's standing member discount, if
  /// it configured one, lands in its own slot server-side — nothing here has to
  /// remember to apply it.
  Future<Bill> attachMember(String visitId, String memberId) => _act(
    visitId: visitId,
    kind: SettlementEventKind.attachMember,
    payload: {'memberId': memberId},
    online: (id) => ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/member',
      {'memberId': memberId},
      idempotencyKey: id,
    ),
  );

  Future<Bill> detachMember(String visitId) => _act(
    visitId: visitId,
    kind: SettlementEventKind.detachMember,
    payload: const {},
    online: (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/visits/$visitId/member/detach',
          const {},
          idempotencyKey: id,
        ),
  );

  Future<Bill> assignTicketMembers(
    String visitId,
    List<String> ticketIds,
    String? memberId,
  ) => _act(
    visitId: visitId,
    kind: SettlementEventKind.assignTicketMembers,
    payload: {'ticketIds': ticketIds, 'memberId': memberId},
    online: (id) => ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/ticket-members',
      {'ticketIds': ticketIds, 'memberId': memberId},
      idempotencyKey: id,
    ),
  );

  /// Spend points as money off this bill. The ledger row and the discount land
  /// together server-side or not at all.
  Future<Bill> redeemPoints(String visitId, int points) => _act(
    visitId: visitId,
    kind: SettlementEventKind.redeemPoints,
    payload: {'points': points},
    online: (id) => ref.read(apiClientProvider).postJson(
      '/settlement/visits/$visitId/redeem',
      {'points': points},
      idempotencyKey: id,
    ),
  );

  Future<Bill> removeRedeem(String visitId) => _act(
    visitId: visitId,
    kind: SettlementEventKind.removeRedeem,
    payload: const {},
    online: (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/visits/$visitId/redeem/remove',
          const {},
          idempotencyKey: id,
        ),
  );

  // ── the [[Pemilik struk]]: the same four acts, one share at a time
  //    (ADR-0118). Each returns the whole bill because a share's give-back
  //    moves the bill's ladder, and the Siapa step draws every row. ──

  Future<Bill> attachReceiptMember(String receiptId, String memberId) =>
      _actOnReceipt(
        receiptId,
        SettlementEventKind.attachReceiptMember,
        {'memberId': memberId},
        (id) => ref.read(apiClientProvider).postJson(
          '/settlement/receipts/$receiptId/member',
          {'memberId': memberId},
          idempotencyKey: id,
        ),
      );

  Future<Bill> detachReceiptMember(String receiptId) => _actOnReceipt(
    receiptId,
    SettlementEventKind.detachReceiptMember,
    const {},
    (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/receipts/$receiptId/member/detach',
          const {},
          idempotencyKey: id,
        ),
  );

  /// Spend this guest's points against their own share. The ceiling is what
  /// that share can absorb, not the whole bill.
  Future<Bill> redeemOnReceipt(String receiptId, int points) => _actOnReceipt(
    receiptId,
    SettlementEventKind.redeemOnReceipt,
    {'points': points},
    (id) => ref.read(apiClientProvider).postJson(
      '/settlement/receipts/$receiptId/redeem',
      {'points': points},
      idempotencyKey: id,
    ),
  );

  Future<Bill> removeReceiptRedeem(String receiptId) => _actOnReceipt(
    receiptId,
    SettlementEventKind.removeReceiptRedeem,
    const {},
    (id) => ref
        .read(apiClientProvider)
        .postJson(
          '/settlement/receipts/$receiptId/redeem/remove',
          const {},
          idempotencyKey: id,
        ),
  );

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
/// Whether the cashier is looking only at bills that went out on a member's
/// tab (ADR-0098). Watched by [venueHistoryProvider] rather than filtered in
/// the widget, because the window is paged — see `fetchHistory`.
final historyOnAccountProvider = StateProvider<bool>((ref) {
  ref.watch(apiConfigProvider);
  return false;
});

final venueHistoryProvider = FutureProvider.autoDispose<PastBillPage>((
  ref,
) async {
  ref.watch(apiConfigProvider);
  // Watched, not family-keyed: re-running on a changed limit leaves the old
  // page on the `AsyncLoading`, so growing mid-scroll shows the rows already
  // there plus a foot spinner instead of collapsing the grid. A family would
  // hand back a brand-new, empty instance.
  final limit = ref.watch(historyLimitProvider);
  final onAccount = ref.watch(historyOnAccountProvider);
  final sub = ref.read(wsClientProvider).events.listen((ev) {
    if (ev.type == WsEventTypes.tableSessionClosed) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return ref
      .read(settlementProvider.notifier)
      .fetchHistory(limit: limit, onAccount: onAccount);
});
