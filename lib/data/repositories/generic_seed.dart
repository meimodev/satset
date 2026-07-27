import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'dart:async';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';

/// First-run generic-seed state for the [[Main Device]] host. Drives the
/// Venue Hub prompt that offers to load the generic restaurant dataset
/// (2 zones x 2 tables, generic menu, 1 waiter + 1 kitchen). See ADR-0017.
class GenericSeedState {
  /// Host DB still has no sample restaurant data.
  final bool needsSeed;

  /// Admin dismissed the prompt for this session ("Nanti"). Re-evaluated on
  /// the next cold boot while [needsSeed] is still true.
  final bool dismissed;

  /// A seed request is in flight.
  final bool loading;

  /// Host has not traded, so the demo seed may run (ADR-0052 §3).
  final bool canSeedDemo;

  /// Host currently holds demo data — enables reset.
  final bool hasDemo;

  /// A seed job started and never finished: only Hapus is offered.
  final bool demoIncomplete;

  /// Days generated so far, and the total, while a seed job runs.
  final int demoDaysDone;
  final int demoDaysTotal;

  const GenericSeedState({
    this.needsSeed = false,
    this.dismissed = false,
    this.loading = false,
    this.canSeedDemo = false,
    this.hasDemo = false,
    this.demoIncomplete = false,
    this.demoDaysDone = 0,
    this.demoDaysTotal = 0,
  });

  /// A seed job is generating right now.
  bool get demoSeeding => demoDaysTotal > 0 && demoDaysDone < demoDaysTotal;

  /// Whether the Venue Hub should surface the prompt right now.
  bool get showPrompt => needsSeed && !dismissed && !loading;

  GenericSeedState copyWith({
    bool? needsSeed,
    bool? dismissed,
    bool? loading,
    bool? canSeedDemo,
    bool? hasDemo,
    bool? demoIncomplete,
    int? demoDaysDone,
    int? demoDaysTotal,
  }) => GenericSeedState(
    needsSeed: needsSeed ?? this.needsSeed,
    dismissed: dismissed ?? this.dismissed,
    loading: loading ?? this.loading,
    canSeedDemo: canSeedDemo ?? this.canSeedDemo,
    hasDemo: hasDemo ?? this.hasDemo,
    demoIncomplete: demoIncomplete ?? this.demoIncomplete,
    demoDaysDone: demoDaysDone ?? this.demoDaysDone,
    demoDaysTotal: demoDaysTotal ?? this.demoDaysTotal,
  );
}

final genericSeedProvider =
    StateNotifierProvider<GenericSeedController, GenericSeedState>(
      (ref) => GenericSeedController(ref),
    );

class GenericSeedController extends StateNotifier<GenericSeedState> {
  GenericSeedController(this._ref) : super(const GenericSeedState()) {
    Future.microtask(refresh);
    _wsSub = _ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.demoProgress) onProgress(ev.payload);
    });
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  /// Ask the host whether it still needs the generic seed. A non-admin caller
  /// (or a client device) gets 403 and is treated as "no prompt"; only an
  /// admin on the host ever sees it.
  Future<void> refresh() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final res =
          await _ref.read(apiClientProvider).getJson('/seed/state') as Map;
      state = state.copyWith(
        needsSeed: res['needsGenericSeed'] == true,
        canSeedDemo: res['canSeedDemo'] == true,
        hasDemo: res['hasDemo'] == true,
        demoIncomplete: res['demoIncomplete'] == true,
      );
    } catch (_) {
      // 403 (not an admin) / offline: leave the prompt hidden.
      state = state.copyWith(needsSeed: false, canSeedDemo: false);
    }
  }

  /// Start the demo seed. Returns as soon as the host accepts the job
  /// (202) — generation takes minutes and reports over `demo.progress`
  /// (ADR-0053 §8). A 409 means the venue has traded and is expected.
  Future<void> seedDemo() => _demoCall('/seed/demo');

  /// Apply a `demo.progress` broadcast.
  void onProgress(Map<String, dynamic> payload) {
    if (payload['done'] == true || payload['failed'] == true) {
      state = state.copyWith(demoDaysDone: 0, demoDaysTotal: 0);
      refresh();
      return;
    }
    state = state.copyWith(
      demoDaysDone: (payload['daysDone'] as num?)?.toInt() ?? 0,
      demoDaysTotal: (payload['daysTotal'] as num?)?.toInt() ?? 0,
    );
  }

  /// Regenerate the live half only. The month of history does not decay; the
  /// mid-service snapshot reads stale within minutes (ADR-0052 §5).
  Future<void> refreshDemo() => _demoCall('/seed/demo/refresh');

  /// Remove every demo row, returning the venue to its generically-seeded
  /// state.
  Future<void> resetDemo() => _demoCall('/seed/demo/reset');

  Future<void> _demoCall(String path) async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      // Seeding a month of service is tens of seconds on device — far past
      // the default 8s request timeout, which would abandon a call the server
      // goes on to complete successfully.
      await _ref
          .read(apiClientProvider)
          .postJson(path, {}, timeout: const Duration(minutes: 5));
      SatLog.repo('demoSeed.$path');
      _invalidateAll();
      state = state.copyWith(loading: false);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  void _invalidateAll() {
    _ref.invalidate(menuRepositoryProvider);
    _ref.invalidate(rolesRepositoryProvider);
    _ref.invalidate(staffRepositoryProvider);
    _ref.invalidate(zonesProvider);
    _ref.invalidate(tablesProvider);
    // The demo moves stock through a month of sales and restocks, and reset
    // recomputes every balance — without this the hub keeps showing the
    // pre-seed low-stock count.
    _ref.invalidate(ingredientsProvider);
    _ref.invalidate(stockMovementsProvider);
  }

  /// Load the generic dataset on the host, then refresh dependent repos so the
  /// admin sees zones/menu/staff immediately (WS broadcasts also nudge any
  /// paired clients).
  Future<void> seed() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final res =
          await _ref.read(apiClientProvider).postJson('/seed/generic', {})
              as Map;
      SatLog.repo('genericSeed.loaded');
      _ref.invalidate(menuRepositoryProvider);
      _ref.invalidate(rolesRepositoryProvider);
      _ref.invalidate(staffRepositoryProvider);
      _ref.invalidate(zonesProvider);
      _ref.invalidate(tablesProvider);
      state = state.copyWith(
        needsSeed: res['needsGenericSeed'] == true,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  /// Hide the prompt for this session without seeding ("Nanti").
  void dismiss() => state = state.copyWith(dismissed: true);
}
