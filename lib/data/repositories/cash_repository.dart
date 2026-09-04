import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/core/time/sat_clock.dart';

/// How many ledger rows a page carries. Paged by **growing limit** (ADR-0079)
/// rather than by cursor: the box is small, and a growing limit means an
/// incoming row can be prepended at the head without shifting an offset out
/// from under the reader.
const _kCashPage = 50;

/// Where the growing limit stops growing.
///
/// A growing limit re-reads the whole window every page, which is the price
/// ADR-0079 pays for being able to prepend an incoming row without shifting an
/// offset. That price is fine at two or three pages and silly at twenty: the
/// tenth `loadMore` on a busy box re-transfers five hundred rows to append
/// fifty. The box is small by design, so a reader who reaches this is looking
/// for something a filter would find faster.
const kCashMaxLoaded = 500;

class CashState {
  final List<CashEntry> entries;

  /// The venue's boxes with their own balances (ADR-0131), in picker order.
  final List<CashBox> boxes;

  /// Which box the ledger and the hero are showing. **Null is the "Semua"
  /// arm** — every box's rows in one list, the venue total in the hero.
  final String? selectedBoxId;

  /// Authoritative, from the server. Never summed from [entries] — a page is
  /// not the ledger, and adding up what happens to be loaded would print a
  /// confident wrong number.
  ///
  /// This is the **venue** total. A box's own balance lives on its [CashBox];
  /// summing boxes is safe because each one came from the server derived, which
  /// is what makes a transfer's two socket frames land correctly in any order.
  final int balance;

  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const CashState({
    this.entries = const [],
    this.boxes = const [],
    this.selectedBoxId,
    this.balance = 0,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  /// Whether paging stopped at [kCashMaxLoaded] rather than at the end of the
  /// ledger. The two look identical from the bottom of a list, and only one of
  /// them means the box has no older movements.
  bool get capped => entries.length >= kCashMaxLoaded;

  /// The box in view, or null on the "Semua" arm.
  CashBox? get selectedBox {
    for (final b in boxes) {
      if (b.id == selectedBoxId) return b;
    }
    return null;
  }

  /// What the hero shows: the selected box's balance, or the venue total.
  int get shownBalance => selectedBox?.balance ?? balance;

  /// What the hero is captioned with, or null for the venue total.
  ///
  /// A venue with one box names it: "semua kas" is only a real answer when
  /// there is more than one tin, and on a single-box venue it would caption the
  /// box's own balance with a word the screen never uses anywhere else.
  String? get heroCaption =>
      selectedBox?.name ??
      (multiBox
          ? null
          : boxes.where((b) => b.active).map((b) => b.name).firstOrNull);

  /// Boxes offered in the picker. A retired one stays out unless it is what the
  /// reader is currently looking at — walking into a box and having it vanish
  /// from under them is worse than showing a tin nobody funds any more.
  List<CashBox> get pickableBoxes => [
    for (final b in boxes)
      if (b.active || b.id == selectedBoxId) b,
  ];

  /// Whether the box selector is worth drawing at all. A venue with one box
  /// sees the screen it has always seen.
  bool get multiBox => boxes.where((b) => b.active).length > 1;

  /// The name for a row's box, for the "Semua" list. Falls back to the id so a
  /// row whose box has somehow gone renders something rather than nothing.
  String boxNameOf(String id) {
    for (final b in boxes) {
      if (b.id == id) return b.name;
    }
    return id;
  }

  /// When the box was last verified against the notes inside it — the second
  /// most useful fact the header carries after the balance itself.
  ///
  /// Null once the reader has paged past no count at all; that reads as "never
  /// counted", which is true of a box nobody has opname'd and honest about a
  /// count older than the loaded window.
  DateTime? get lastCountAt {
    for (final e in entries) {
      if (e.kind == CashEntryKind.count) return e.at;
    }
    return null;
  }

  CashState copyWith({
    List<CashEntry>? entries,
    List<CashBox>? boxes,
    String? selectedBoxId,
    bool clearSelectedBox = false,
    int? balance,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => CashState(
    entries: entries ?? this.entries,
    boxes: boxes ?? this.boxes,
    selectedBoxId: clearSelectedBox
        ? null
        : (selectedBoxId ?? this.selectedBoxId),
    balance: balance ?? this.balance,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );
}

/// The petty cash box (§Kas kecil), client side.
///
/// Fed by WebSocket: a movement arrives as `{entry, boxId, balance}` and lands
/// at the head with **that box's** balance replaced. The balance rides the event
/// because it is derived server-side, so appending a row locally could never
/// produce it — and it is per box (ADR-0131), so the venue total is re-summed
/// here rather than trusted from a frame that only knows one tin.
///
/// Deliberately **not cached to prefs**, unlike the venue settings of ADR-0128:
/// `/kas` is tablet-only, admin, and has no offline path, and a derived balance
/// someone is about to count against must come from the host or not at all.
class CashRepository extends StateNotifier<CashState> {
  CashRepository(this._ref) : super(const CashState()) {
    // Loads itself, like the venue log: the hub tile shows the balance before
    // anyone opens the screen, so waiting for a mount would print Rp 0 on a
    // funded box.
    Future.microtask(refresh);
    _wireWs();
  }

  final Ref _ref;
  StreamSubscription? _wsSub;
  int _limit = _kCashPage;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_ref.read(apiConfigProvider) == null) return;
    _limit = _kCashPage;
    state = state.copyWith(loading: true, clearError: true);
    await _fetch();
  }

  /// Show one box, or every box when [boxId] is null ("Semua"). The ledger is
  /// re-read because the filter is server-side: a page of one box is not a
  /// subset of the page the client happens to hold.
  Future<void> selectBox(String? boxId) async {
    if (boxId == state.selectedBoxId) return;
    _limit = _kCashPage;
    state = state.copyWith(
      selectedBoxId: boxId,
      clearSelectedBox: boxId == null,
      loading: true,
      clearError: true,
    );
    await _fetch();
  }

  /// Next page — the limit grows and the whole window is re-read. A ledger this
  /// size does not earn cursor bookkeeping, and re-reading is what keeps a
  /// reversal stamped onto an older row visible without a second request.
  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    if (_limit >= kCashMaxLoaded) return;
    _limit += _kCashPage;
    state = state.copyWith(loadingMore: true);
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final raw =
          await _ref
                  .read(apiClientProvider)
                  .getJson(
                    '/cash',
                    query: {
                      'limit': '$_limit',
                      if (state.selectedBoxId != null)
                        'boxId': state.selectedBoxId!,
                    },
                  )
              as Map<String, dynamic>;
      final entries = [
        for (final e in (raw['entries'] as List? ?? const []))
          cashEntryFromJson((e as Map).cast<String, dynamic>()),
      ];
      final boxes = [
        for (final b in (raw['boxes'] as List? ?? const []))
          cashBoxFromJson((b as Map).cast<String, dynamic>()),
      ];
      state = state.copyWith(
        entries: entries,
        boxes: boxes,
        balance: (raw['balance'] as num?)?.toInt() ?? 0,
        loading: false,
        loadingMore: false,
        hasMore: entries.length >= _limit && _limit < kCashMaxLoaded,
      );
      SatLog.repo('cash.loaded n=${entries.length} balance=${state.balance}');
    } catch (e) {
      SatLog.repo('cash.fetch fail $e');
      state = state.copyWith(loading: false, loadingMore: false, error: e);
    }
  }

  Future<void> topUp({
    required String boxId,
    required int amount,
    String? note,
  }) => _post('/cash/topup', {
    'boxId': boxId,
    'amount': amount,
    'note': note,
  });

  Future<void> spend({
    required String boxId,
    required int amount,
    required CashCategory category,
    String? note,
    String? photoBase64,
  }) => _post('/cash/expense', {
    'boxId': boxId,
    'amount': amount,
    'category': category.name,
    'note': note,
    'photoBase64': photoBase64,
  });

  Future<void> count({
    required String boxId,
    required int counted,
    String? note,
  }) => _post('/cash/count', {
    'boxId': boxId,
    'counted': counted,
    'note': note,
  });

  /// Move money between two boxes. Two rows land, so the response is applied and
  /// the window re-read — the caller's own device must see both legs even if it
  /// is looking at the destination.
  Future<void> transfer({
    required String fromId,
    required String toId,
    required int amount,
    String? note,
  }) async {
    await _post('/cash/transfer', {
      'fromId': fromId,
      'toId': toId,
      'amount': amount,
      'note': note,
    });
    await _fetch();
  }

  Future<void> createBox(String name) async {
    final raw =
        await _ref.read(apiClientProvider).postJson('/cash/boxes', {
              'name': name,
            })
            as Map<String, dynamic>;
    _applyBoxes(raw);
  }

  /// Rename a box, retire it, or bring it back. Retiring is refused server-side
  /// while the box still holds money.
  Future<void> updateBox({
    required String id,
    String? name,
    bool? active,
  }) async {
    final raw =
        await _ref.read(apiClientProvider).patchJson('/cash/boxes/$id', {
              'name': name,
              'active': active,
            })
            as Map<String, dynamic>;
    _applyBoxes(raw);
  }

  Future<void> reverse({required String id, required String note}) =>
      _post('/cash/$id/reverse', {'note': note});

  /// Posts and applies the response directly rather than waiting for the socket
  /// to loop back: the acting device must see its own movement land even if the
  /// WS frame is late or lost. The `id` check in [_wireWs] makes the duplicate
  /// harmless when the frame does arrive.
  Future<void> _post(String path, Map<String, dynamic> body) async {
    final raw =
        await _ref.read(apiClientProvider).postJson(path, body)
            as Map<String, dynamic>;
    _apply(raw);
  }

  /// A photo lives behind its own route, fetched on tap. The bytes never ride
  /// the ledger.
  String photoPath(String id) => '/cash/$id/photo';

  void _wireWs() {
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.connected) {
        // Full resync on reconnect (ADR-0021): a movement posted while the
        // socket was down would otherwise leave the balance stale forever.
        refresh();
        return;
      }
      if (ev.type == WsEventTypes.cashBoxesUpdated) {
        _applyBoxes(ev.payload);
        return;
      }
      if (ev.type != WsEventTypes.cashEntryCreated) return;
      _apply(ev.payload);
    });
  }

  /// Replace the boxes wholesale — the server sends the whole list because it
  /// is a handful of rows and any change can reorder them.
  void _applyBoxes(Map<String, dynamic> payload) {
    final raw = payload['boxes'];
    if (raw is! List) return;
    final boxes = [
      for (final b in raw) cashBoxFromJson((b as Map).cast<String, dynamic>()),
    ];
    state = state.copyWith(
      boxes: boxes,
      balance: boxes.fold<int>(0, (a, b) => a + b.balance),
      // A box the reader was looking at may have just been retired; the ledger
      // for it is still valid, so the selection stands and `pickableBoxes`
      // keeps showing it.
      clearError: true,
    );
  }

  void _apply(Map<String, dynamic> payload) {
    final rawEntry = payload['entry'];
    if (rawEntry is! Map) return;
    final entry = cashEntryFromJson(rawEntry.cast<String, dynamic>());
    // The frame carries **one box's** balance, so the venue total is re-summed
    // from the boxes rather than taken from the payload. That is what makes a
    // transfer's two frames correct after either one — each replaces its own
    // tin and the total follows.
    final boxes = [
      for (final b in state.boxes)
        if (b.id == entry.boxId)
          CashBox(
            id: b.id,
            name: b.name,
            active: b.active,
            sortOrder: b.sortOrder,
            balance: (payload['balance'] as num?)?.toInt() ?? b.balance,
          )
        else
          b,
    ];
    final balance = boxes.isEmpty
        ? ((payload['balance'] as num?)?.toInt() ?? state.balance)
        : boxes.fold<int>(0, (a, b) => a + b.balance);
    if (state.entries.any((e) => e.id == entry.id)) {
      // Already have the row — still take the balance, which is the one part of
      // the payload that can be newer than what is on screen.
      state = state.copyWith(boxes: boxes, balance: balance);
      return;
    }
    // A row for a box the reader is not looking at moves the balance and
    // nothing else: dropping it into a filtered ledger would show a movement
    // that does not belong to the box named at the top of the screen.
    final mine =
        state.selectedBoxId == null || state.selectedBoxId == entry.boxId;
    // Head insert. Safe under a growing limit: nothing is indexed by offset, and
    // the next refresh re-derives the window from scratch.
    state = state.copyWith(
      entries: mine ? [entry, ...state.entries] : state.entries,
      boxes: boxes,
      balance: balance,
      // A reversal stamps `reversedById` onto the row it undoes, which this
      // event cannot carry. Re-read so the ledger stops offering to reverse a
      // row that is already reversed.
      clearError: true,
    );
    if (entry.kind == CashEntryKind.reversal) _fetch();
  }
}

CashBox cashBoxFromJson(Map<String, dynamic> j) => CashBox(
  id: j['id'] as String,
  name: j['name'] as String? ?? '',
  active: j['active'] != false,
  sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
  balance: (j['balance'] as num?)?.toInt() ?? 0,
);

CashEntry cashEntryFromJson(Map<String, dynamic> j) => CashEntry(
  id: j['id'] as String,
  boxId: j['boxId'] as String? ?? 'box-main',
  kind: cashEntryKindFromName(j['kind'] as String?) ?? CashEntryKind.expense,
  delta: (j['delta'] as num?)?.toInt() ?? 0,
  category: cashCategoryFromName(j['category'] as String?),
  note: j['note'] as String?,
  reversesId: j['reversesId'] as String?,
  reversedById: j['reversedById'] as String?,
  transferPeerId: j['transferPeerId'] as String?,
  countedAmount: (j['countedAmount'] as num?)?.toInt(),
  hasPhoto: j['hasPhoto'] == true,
  actorUserId: j['actorUserId'] as String?,
  actorName: j['actorName'] as String?,
  at: DateTime.tryParse(j['at'] as String? ?? '')?.toLocal() ?? SatClock.now(),
);

/// A refusal, as the sheets need it: the server's code plus — on
/// `insufficient_cash` — how much is actually in the box, so the message can say
/// so instead of sending the supervisor to go and look.
({String code, int? balance})? cashErrorOf(Object error) {
  if (error is! ApiException) return null;
  final code = error.code;
  if (code == null) return null;
  int? balance;
  try {
    balance = ((jsonDecode(error.body) as Map)['balance'] as num?)?.toInt();
  } catch (_) {
    // Body was not the JSON we expected; the code alone still says enough.
  }
  return (code: code, balance: balance);
}

final cashProvider = StateNotifierProvider<CashRepository, CashState>(
  (ref) => CashRepository(ref),
);
