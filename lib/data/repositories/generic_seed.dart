import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

/// Which of the sample-data prompt's states to show. Derived on the host from
/// `/seed/state` (ADR-0073).
enum SeedPromptPhase {
  /// Nothing to offer: already answered, already loaded, or not the host.
  none,

  /// Empty venue, prompt never answered — the blocking dialog is due.
  offer,

  /// A job is generating right now.
  running,

  /// A job started and never finished. Only clear-and-retry is offered; the
  /// prompt counts as unanswered, so it returns until it is resolved.
  incomplete,

  /// The last job failed outright.
  failed,
}

/// Host-side state of the [[Generic seed (sample data)]] prompt and job.
class GenericSeedState {
  /// Host DB still has no restaurant data.
  final bool needsSeed;

  /// Host has not traded, so the sample month may be written (ADR-0052 §3).
  final bool canSeed;

  /// Host currently holds sample data — enables the clear action.
  final bool hasSampleData;

  /// A job started and never finished.
  final bool seedIncomplete;

  /// The admin answered the prompt (skipped, or completed a seed). Persisted
  /// server-side and venue-wide: "never again" is a property of the venue, not
  /// of the tablet that answered.
  final bool promptAnswered;

  /// The last job ended in an error rather than an interruption.
  final bool failed;

  /// A request is in flight.
  final bool loading;

  /// Days generated so far, and the total, while a job runs.
  final int daysDone;
  final int daysTotal;

  const GenericSeedState({
    this.needsSeed = false,
    this.canSeed = false,
    this.hasSampleData = false,
    this.seedIncomplete = false,
    this.promptAnswered = false,
    this.failed = false,
    this.loading = false,
    this.daysDone = 0,
    this.daysTotal = 0,
  });

  /// A job is generating right now.
  bool get seeding => daysTotal > 0 && daysDone < daysTotal;

  double get progress => daysTotal == 0 ? 0 : daysDone / daysTotal;

  SeedPromptPhase get phase {
    if (seeding) return SeedPromptPhase.running;
    if (seedIncomplete) return SeedPromptPhase.incomplete;
    if (failed) return SeedPromptPhase.failed;
    if (needsSeed && !promptAnswered && canSeed) return SeedPromptPhase.offer;
    return SeedPromptPhase.none;
  }

  /// Whether the Venue Hub must block on the dialog right now.
  bool get mustPrompt => phase != SeedPromptPhase.none;

  GenericSeedState copyWith({
    bool? needsSeed,
    bool? canSeed,
    bool? hasSampleData,
    bool? seedIncomplete,
    bool? promptAnswered,
    bool? failed,
    bool? loading,
    int? daysDone,
    int? daysTotal,
  }) => GenericSeedState(
    needsSeed: needsSeed ?? this.needsSeed,
    canSeed: canSeed ?? this.canSeed,
    hasSampleData: hasSampleData ?? this.hasSampleData,
    seedIncomplete: seedIncomplete ?? this.seedIncomplete,
    promptAnswered: promptAnswered ?? this.promptAnswered,
    failed: failed ?? this.failed,
    loading: loading ?? this.loading,
    daysDone: daysDone ?? this.daysDone,
    daysTotal: daysTotal ?? this.daysTotal,
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
      if (ev.type == WsEventTypes.seedProgress) onProgress(ev.payload);
    });
  }

  final Ref _ref;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  /// Ask the host where the seed stands. A non-admin caller (or a client
  /// device) gets 403 and is treated as "no prompt"; only an admin on the host
  /// ever sees it.
  Future<void> refresh() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final res =
          await _ref.read(apiClientProvider).getJson('/seed/state') as Map;
      state = state.copyWith(
        needsSeed: res['needsSeed'] == true,
        canSeed: res['canSeed'] == true,
        hasSampleData: res['hasSampleData'] == true,
        seedIncomplete: res['seedIncomplete'] == true,
        promptAnswered: res['promptAnswered'] == true,
        // Read from the host, not carried over from `onProgress`: the live
        // broadcast is gone after a restart, and a crashed job that reads as
        // merely interrupted is the wrong sentence on the right dialog.
        failed: res['failed'] == true,
        daysDone: (res['daysDone'] as num?)?.toInt() ?? 0,
        daysTotal: (res['daysTotal'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      // 403 (not an admin) / offline: leave the prompt hidden.
      state = state.copyWith(needsSeed: false, canSeed: false);
    }
  }

  /// Start the seed. Returns as soon as the host accepts the job (202) —
  /// generation takes minutes and reports over `seed.progress` (ADR-0053 §8).
  /// A 409 means the venue has traded and is expected.
  Future<void> seed() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, failed: false);
    try {
      await _ref.read(apiClientProvider).postJson('/seed/generic', {});
      SatLog.repo('sampleSeed.started');
      // Show the bar immediately rather than waiting for the first day to
      // land: the first broadcast is up to a few seconds out, and a dialog
      // that sits blank reads as wedged.
      state = state.copyWith(loading: false, daysDone: 0, daysTotal: 30);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  /// Apply a `seed.progress` broadcast.
  void onProgress(Map<String, dynamic> payload) {
    if (payload['done'] == true) {
      state = state.copyWith(daysDone: 0, daysTotal: 0, failed: false);
      _invalidateAll();
      refresh();
      return;
    }
    if (payload['failed'] == true) {
      state = state.copyWith(daysDone: 0, daysTotal: 0, failed: true);
      _invalidateAll();
      refresh();
      return;
    }
    state = state.copyWith(
      daysDone: (payload['daysDone'] as num?)?.toInt() ?? 0,
      daysTotal: (payload['daysTotal'] as num?)?.toInt() ?? 0,
    );
  }

  /// Remove every fabricated transactional row. Zones, tables, menu, staff and
  /// bahan stay (ADR-0073).
  Future<void> clear() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      // Clearing a month of rows is well past the default 8s request timeout,
      // which would abandon a call the server goes on to complete.
      await _ref
          .read(apiClientProvider)
          .postJson('/seed/clear', {}, timeout: const Duration(minutes: 5));
      SatLog.repo('sampleSeed.cleared');
      _invalidateAll();
      state = state.copyWith(loading: false, failed: false);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  /// The admin declined. Persisted server-side; the prompt never fires again
  /// and Admin → Settings is the way back in.
  Future<void> skip() async {
    state = state.copyWith(promptAnswered: true);
    try {
      await _ref.read(apiClientProvider).postJson('/seed/skip', {});
      SatLog.repo('sampleSeed.skipped');
    } catch (e) {
      // Optimistic: the dialog is already dismissed. A failed write means it
      // returns on the next boot, which is the safe direction.
      await refresh();
    }
  }

  void _invalidateAll() {
    _ref.invalidate(menuRepositoryProvider);
    _ref.invalidate(rolesRepositoryProvider);
    _ref.invalidate(staffRepositoryProvider);
    _ref.invalidate(zonesProvider);
    _ref.invalidate(tablesProvider);
    // The month moves stock through sales and restocks, and clearing recomputes
    // every balance — without this the hub keeps showing the pre-seed
    // low-stock count.
    _ref.invalidate(ingredientsProvider);
    _ref.invalidate(stockMovementsProvider);
  }
}
