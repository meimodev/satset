import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/self_order_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/ws_client.dart';

class SelfOrderState {
  final List<GuestOrderDto> orders;
  final GuestStatsDto stats;
  final List<GuestTableDto> tables;

  /// Only the items a guest may currently see. An item hidden from the guest
  /// page is absent here, which is why the tab needs [hiddenIds] to draw the
  /// rest — see [SelfOrderRepository.refresh].
  final List<GuestMenuItemDto> menu;

  /// The menu's categories, in the venue's own order, each carrying its
  /// [[Jam tayang]]. Only categories that hold an item are emitted.
  final List<GuestCategoryDto> categories;

  /// The LAN address a guest phone can reach this venue on, as reported by the
  /// server itself, and the port its cleartext plane listens on. Null until the
  /// first load, or when the server has no LAN address — a QR is not drawn then.
  final String? host;
  final int guestPort;

  /// The venue's own guest code — the QR on the counter rather than on a table
  /// (ADR-0109). Empty when the `counterQr` switch is off, which is also how
  /// the QR tab decides whether to draw the card at all.
  final String counterCode;
  final bool loading;
  final Object? error;

  const SelfOrderState({
    this.orders = const [],
    this.stats = const GuestStatsDto(),
    this.tables = const [],
    this.menu = const [],
    this.categories = const [],
    this.host,
    this.guestPort = 8080,
    this.counterCode = '',
    this.loading = false,
    this.error,
  });

  /// What the hub badge counts and what the queue tab opens on.
  List<GuestOrderDto> get pending => [
    for (final o in orders)
      if (o.status == 'pending') o,
  ];

  SelfOrderState copyWith({
    List<GuestOrderDto>? orders,
    GuestStatsDto? stats,
    List<GuestTableDto>? tables,
    List<GuestMenuItemDto>? menu,
    List<GuestCategoryDto>? categories,
    String? host,
    int? guestPort,
    String? counterCode,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) => SelfOrderState(
    orders: orders ?? this.orders,
    stats: stats ?? this.stats,
    tables: tables ?? this.tables,
    menu: menu ?? this.menu,
    categories: categories ?? this.categories,
    host: host ?? this.host,
    guestPort: guestPort ?? this.guestPort,
    counterCode: counterCode ?? this.counterCode,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

/// [[Pesan mandiri]] (ADR-0105), client side.
///
/// Loads itself and stays fed by WebSocket, like [[Kas kecil]]: a guest order
/// arriving while nobody is looking at the screen must still light the hub
/// badge and fire the alert sound.
class SelfOrderRepository extends StateNotifier<SelfOrderState> {
  SelfOrderRepository(this._ref) : super(const SelfOrderState()) {
    Future.microtask(refresh);
    _wireWs();
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_ref.read(apiConfigProvider) == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw =
          await _ref.read(apiClientProvider).getJson('/selforder')
              as Map<String, dynamic>;
      state = state.copyWith(
        orders: [
          for (final o in (raw['orders'] as List? ?? const []))
            GuestOrderDto.fromJson((o as Map).cast<String, dynamic>()),
        ],
        stats: GuestStatsDto.fromJson(
          ((raw['stats'] as Map?) ?? const {}).cast<String, dynamic>(),
        ),
        tables: [
          for (final t in (raw['tables'] as List? ?? const []))
            GuestTableDto.fromJson((t as Map).cast<String, dynamic>()),
        ],
        menu: [
          for (final i
              in ((raw['menu'] as Map?)?['items'] as List? ?? const []))
            GuestMenuItemDto.fromJson((i as Map).cast<String, dynamic>()),
        ],
        categories: [
          for (final c
              in ((raw['menu'] as Map?)?['categories'] as List? ?? const []))
            GuestCategoryDto.fromJson((c as Map).cast<String, dynamic>()),
        ],
        host: raw['host'] as String?,
        guestPort: (raw['guestPort'] as num?)?.toInt(),
        counterCode: (raw['counterCode'] as String?) ?? '',
        loading: false,
      );
      SatLog.repo('selforder.loaded n=${state.orders.length}');
    } catch (e) {
      SatLog.repo('selforder.fetch fail $e');
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Accepting runs the ordinary order path server-side, which can partially
  /// fail on stock — so the whole snapshot is re-read rather than patched in
  /// place. A queue of a few rows does not earn optimistic bookkeeping.
  Future<void> accept(String id) => _act(
    () => _ref
        .read(apiClientProvider)
        .postJson('/selforder/orders/$id/accept', const <String, dynamic>{}),
  );

  Future<void> reject(String id, String reasonCode) => _act(
    () => _ref.read(apiClientProvider).postJson(
      '/selforder/orders/$id/reject',
      {'reasonCode': reasonCode},
    ),
  );

  Future<void> acceptAll() => _act(
    () => _ref
        .read(apiClientProvider)
        .postJson('/selforder/orders/accept-all', const <String, dynamic>{}),
  );

  /// Kills every printed QR in the venue. The confirm lives on the screen; by
  /// the time this runs the owner has already said yes.
  Future<void> rotateCodes() => _act(
    () => _ref
        .read(apiClientProvider)
        .postJson('/selforder/codes/rotate', const <String, dynamic>{}),
  );

  Future<void> setItemGuest(
    String id, {
    bool? visible,
    bool? featured,
    bool? alcohol,
    String? stockOverride,
  }) => _act(
    () => _ref.read(apiClientProvider).patchJson('/selforder/items/$id', {
      'guestVisible': ?visible,
      'guestFeatured': ?featured,
      'alcohol': ?alcohol,
      'guestStockOverride': ?stockOverride,
    }),
  );

  /// Set or clear a category's [[Jam tayang]]. Both null clears it; the server
  /// refuses a half-window, so the pair travels together.
  Future<void> setCategoryWindow(String id, {int? fromMin, int? toMin}) => _act(
    () => _ref.read(apiClientProvider).patchJson('/selforder/categories/$id', {
      'fromMin': fromMin,
      'toMin': toMin,
    }),
  );

  Future<void> setTableEnabled(String id, bool enabled) => _act(
    () => _ref.read(apiClientProvider).patchJson('/selforder/tables/$id', {
      'enabled': enabled,
    }),
  );

  /// Every write on this screen, and the one place they are allowed to fail.
  ///
  /// Nothing here used to catch, so a refused accept became an unhandled async
  /// error: no snackbar, no log, and `refresh()` never ran — the row stayed
  /// drawn as pending and the only evidence was that pressing the button did
  /// nothing. Now the code is resolved to a sentence and pushed to the error
  /// bus (ADR-0103), and the reload happens either way, because after a
  /// failure the local snapshot is the thing least worth trusting.
  Future<void> _act(Future<dynamic> Function() call) async {
    try {
      await call();
    } on ApiException catch (e) {
      SatLog.repo('selforder.act fail ${e.statusCode} ${e.code}');
      _ref
          .read(errorBusServiceProvider)
          .push(
            guestDecisionFailureText(_ref.read(l10nProvider), e.code),
            code: e.code,
          );
    }
    await refresh();
  }

  void _wireWs() {
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      // Full resync on reconnect (ADR-0021), and on either guest event: the
      // stats are derived server-side and a locally patched list could not
      // produce them.
      if (ev.type == WsEventTypes.connected ||
          ev.type == WsEventTypes.guestOrderSubmitted ||
          ev.type == WsEventTypes.guestOrderDecided) {
        refresh();
      }
    });
  }
}

final selfOrderProvider =
    StateNotifierProvider<SelfOrderRepository, SelfOrderState>(
      (ref) => SelfOrderRepository(ref),
    );
