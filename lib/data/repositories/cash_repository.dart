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

  /// Authoritative, from the server. Never summed from [entries] — a page is
  /// not the ledger, and adding up what happens to be loaded would print a
  /// confident wrong number.
  final int balance;

  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const CashState({
    this.entries = const [],
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
    int? balance,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => CashState(
    entries: entries ?? this.entries,
    balance: balance ?? this.balance,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );
}

/// The petty cash box (§Kas kecil), client side.
///
/// Fed by WebSocket: a movement arrives as `{entry, balance}` and lands at the
/// head with the balance replaced. The balance rides the event because it is
/// derived server-side, so appending a row locally could never produce it.
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
                  .getJson('/cash', query: {'limit': '$_limit'})
              as Map<String, dynamic>;
      final entries = [
        for (final e in (raw['entries'] as List? ?? const []))
          cashEntryFromJson((e as Map).cast<String, dynamic>()),
      ];
      state = state.copyWith(
        entries: entries,
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

  Future<void> topUp({required int amount, String? note}) =>
      _post('/cash/topup', {'amount': amount, 'note': note});

  Future<void> spend({
    required int amount,
    required CashCategory category,
    String? note,
    String? photoBase64,
  }) => _post('/cash/expense', {
    'amount': amount,
    'category': category.name,
    'note': note,
    'photoBase64': photoBase64,
  });

  Future<void> count({required int counted, String? note}) =>
      _post('/cash/count', {'counted': counted, 'note': note});

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
      if (ev.type != WsEventTypes.cashEntryCreated) return;
      _apply(ev.payload);
    });
  }

  void _apply(Map<String, dynamic> payload) {
    final rawEntry = payload['entry'];
    if (rawEntry is! Map) return;
    final entry = cashEntryFromJson(rawEntry.cast<String, dynamic>());
    final balance = (payload['balance'] as num?)?.toInt() ?? state.balance;
    if (state.entries.any((e) => e.id == entry.id)) {
      // Already have the row — still take the balance, which is the one part of
      // the payload that can be newer than what is on screen.
      state = state.copyWith(balance: balance);
      return;
    }
    // Head insert. Safe under a growing limit: nothing is indexed by offset, and
    // the next refresh re-derives the window from scratch.
    state = state.copyWith(
      entries: [entry, ...state.entries],
      balance: balance,
      // A reversal stamps `reversedById` onto the row it undoes, which this
      // event cannot carry. Re-read so the ledger stops offering to reverse a
      // row that is already reversed.
      clearError: true,
    );
    if (entry.kind == CashEntryKind.reversal) _fetch();
  }
}

CashEntry cashEntryFromJson(Map<String, dynamic> j) => CashEntry(
  id: j['id'] as String,
  kind: cashEntryKindFromName(j['kind'] as String?) ?? CashEntryKind.expense,
  delta: (j['delta'] as num?)?.toInt() ?? 0,
  category: cashCategoryFromName(j['category'] as String?),
  note: j['note'] as String?,
  reversesId: j['reversesId'] as String?,
  reversedById: j['reversedById'] as String?,
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
