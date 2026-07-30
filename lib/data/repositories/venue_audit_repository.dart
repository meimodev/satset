import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/audit_repository.dart'
    show auditEntryFromJson;
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/audit_entry.dart';

/// How far back the venue log reaches. The default is deliberately narrow:
/// opening on "everything" makes the first paint a full-history scan, and the
/// question a manager actually arrives with is about this service.
enum AuditWindow { today, yesterday, week, all }

/// The tiles the venue log leads with. Each is one audit type, and each sums a
/// magnitude within that type — see [AuditEntry.amountCents].
const auditSummaryTypes = <AuditType>[
  AuditType.voidItem,
  AuditType.comp,
  AuditType.discountApplied,
  AuditType.refund,
  AuditType.menuKilled,
  AuditType.modify,
];

typedef AuditTally = ({int count, int amount});

class VenueAuditFilters {
  final AuditWindow window;

  /// Empty ⇒ every type. Never a "hidden types" list: the server decides what
  /// this caller may see, and the client must not be able to widen it.
  final Set<AuditType> types;

  const VenueAuditFilters({
    this.window = AuditWindow.today,
    this.types = const {},
  });

  VenueAuditFilters copyWith({AuditWindow? window, Set<AuditType>? types}) =>
      VenueAuditFilters(
        window: window ?? this.window,
        types: types ?? this.types,
      );

  /// Start of the window in local time, or null for [AuditWindow.all].
  DateTime? get from {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return switch (window) {
      AuditWindow.today => midnight,
      AuditWindow.yesterday => midnight.subtract(const Duration(days: 1)),
      AuditWindow.week => midnight.subtract(const Duration(days: 6)),
      AuditWindow.all => null,
    };
  }

  Map<String, String> get query => {
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (types.isNotEmpty) 'type': types.map((t) => t.name).join(','),
  };

  @override
  bool operator ==(Object other) =>
      other is VenueAuditFilters &&
      other.window == window &&
      other.types.length == types.length &&
      other.types.containsAll(types);

  @override
  int get hashCode => Object.hash(window, types.length);
}

class VenueAuditState {
  final List<AuditEntry> items;

  /// Rows that arrived over the WebSocket while the reader was scrolled away
  /// from the head. Held back rather than spliced in, so the row under a
  /// manager's finger does not move mid-read.
  final List<AuditEntry> pending;
  final Map<AuditType, AuditTally> summary;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;
  final Object? error;
  final VenueAuditFilters filters;

  const VenueAuditState({
    this.items = const [],
    this.pending = const [],
    this.summary = const {},
    this.nextCursor,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.filters = const VenueAuditFilters(),
  });

  bool get hasMore => nextCursor != null;

  VenueAuditState copyWith({
    List<AuditEntry>? items,
    List<AuditEntry>? pending,
    Map<AuditType, AuditTally>? summary,
    String? nextCursor,
    bool clearCursor = false,
    bool? loading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
    VenueAuditFilters? filters,
  }) => VenueAuditState(
    items: items ?? this.items,
    pending: pending ?? this.pending,
    summary: summary ?? this.summary,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    filters: filters ?? this.filters,
  );
}

/// The venue-wide integrity log (ADR-0067) — every actor, paged back through
/// history, behind `viewReports`.
///
/// Separate from [AuditRepository], which is one user's own shift and caches a
/// whole list. This one holds a *window*: rows are paged in by cursor, the
/// tiles come from a server-side summary over the entire filtered set, and the
/// two must never be derived from one another. Counting loaded rows would
/// print "3 pembatalan" on a venue with forty.
class VenueAuditRepository extends StateNotifier<VenueAuditState> {
  VenueAuditRepository(this._ref) : super(const VenueAuditState()) {
    Future.microtask(refresh);
    _wireWs();
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  /// Whether the reader is at the head of the list. Set by the screen; decides
  /// whether an incoming row lands directly or waits behind the "baru" pill.
  bool _atHead = true;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void setAtHead(bool value) {
    if (_atHead == value) return;
    _atHead = value;
    if (value) flushPending();
  }

  Future<void> setFilters(VenueAuditFilters filters) async {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters);
    await refresh();
  }

  /// Page one: rows + a fresh summary. Drops any pending rows — they either
  /// belong to the new window (and come back in the page) or they do not.
  Future<void> refresh() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    state = state.copyWith(loading: true, clearError: true, pending: const []);
    try {
      final raw =
          await _ref
                  .read(apiClientProvider)
                  .getJson('/audit/venue', query: state.filters.query)
              as Map<String, dynamic>;
      state = state.copyWith(
        items: _decode(raw['items']),
        summary: _decodeSummary(raw['summary']),
        nextCursor: raw['nextCursor'] as String?,
        clearCursor: raw['nextCursor'] == null,
        loading: false,
      );
      SatLog.repo('audit.venue.loaded n=${state.items.length}');
    } catch (e) {
      SatLog.repo('audit.venue.refresh fail $e');
      state = state.copyWith(loading: false, error: e);
      _ref.read(errorBusServiceProvider).push('Gagal memuat audit');
    }
  }

  /// Next page. The summary is not re-requested — it already covers the whole
  /// window, so paging deeper must not change a single tile.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final raw =
          await _ref
                  .read(apiClientProvider)
                  .getJson(
                    '/audit/venue',
                    query: {...state.filters.query, 'before': cursor},
                  )
              as Map<String, dynamic>;
      final more = _decode(raw['items']);
      final seen = {for (final e in state.items) e.id};
      state = state.copyWith(
        items: [
          ...state.items,
          for (final e in more)
            if (!seen.contains(e.id)) e,
        ],
        nextCursor: raw['nextCursor'] as String?,
        clearCursor: raw['nextCursor'] == null,
        loadingMore: false,
      );
    } catch (e) {
      SatLog.repo('audit.venue.loadMore fail $e');
      state = state.copyWith(loadingMore: false, error: e);
      _ref.read(errorBusServiceProvider).push('Gagal memuat audit');
    }
  }

  void flushPending() {
    if (state.pending.isEmpty) return;
    state = state.copyWith(
      items: [...state.pending, ...state.items],
      pending: const [],
    );
  }

  /// The absolute URL an export hits — same filters, unpaged, rendered by the
  /// server. Built here so the screen cannot accidentally export a different
  /// window from the one on display.
  String csvPath() {
    final q = state.filters.query;
    if (q.isEmpty) return '/audit/venue.csv';
    final encoded = q.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '/audit/venue.csv?$encoded';
  }

  void _wireWs() {
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.auditCreated) return;
      final e = auditEntryFromJson(ev.payload);
      // The fan-out is venue-wide and unfiltered, so the active window has to
      // be applied here — otherwise a row the table is filtering out would
      // still bump the "baru" count and the tiles.
      if (!_matchesFilters(e)) return;
      if (state.items.any((x) => x.id == e.id)) return;
      if (state.pending.any((x) => x.id == e.id)) return;

      // Keep the tiles honest as rows land. They came from a server-side sum
      // over the window, and this row is inside it.
      final summary = {...state.summary};
      final prev = summary[e.type] ?? (count: 0, amount: 0);
      summary[e.type] = (
        count: prev.count + 1,
        amount: prev.amount + (e.amountCents ?? 0),
      );

      state = _atHead
          ? state.copyWith(items: [e, ...state.items], summary: summary)
          : state.copyWith(pending: [e, ...state.pending], summary: summary);
    });
  }

  bool _matchesFilters(AuditEntry e) {
    final f = state.filters;
    if (f.types.isNotEmpty && !f.types.contains(e.type)) return false;
    final from = f.from;
    if (from == null) return true;
    final at = DateTime.tryParse(e.when);
    // An unparseable timestamp is shown rather than hidden — dropping a row
    // from an integrity log to tidy a filter is the wrong failure.
    if (at == null) return true;
    return !at.toLocal().isBefore(from);
  }

  List<AuditEntry> _decode(Object? raw) => [
    for (final e in (raw as List? ?? const []))
      auditEntryFromJson((e as Map).cast<String, dynamic>()),
  ];

  Map<AuditType, AuditTally> _decodeSummary(Object? raw) {
    final map = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    final out = <AuditType, AuditTally>{};
    for (final entry in map.entries) {
      final type = AuditType.values.where((t) => t.name == entry.key);
      if (type.isEmpty) continue;
      final v = (entry.value as Map).cast<String, dynamic>();
      out[type.first] = (
        count: (v['count'] as num?)?.toInt() ?? 0,
        amount: (v['amount'] as num?)?.toInt() ?? 0,
      );
    }
    return out;
  }
}

final venueAuditProvider =
    StateNotifierProvider<VenueAuditRepository, VenueAuditState>(
      (ref) => VenueAuditRepository(ref),
    );
