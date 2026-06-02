import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
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

  const GenericSeedState({
    this.needsSeed = false,
    this.dismissed = false,
    this.loading = false,
  });

  /// Whether the Venue Hub should surface the prompt right now.
  bool get showPrompt => needsSeed && !dismissed && !loading;

  GenericSeedState copyWith({bool? needsSeed, bool? dismissed, bool? loading}) =>
      GenericSeedState(
        needsSeed: needsSeed ?? this.needsSeed,
        dismissed: dismissed ?? this.dismissed,
        loading: loading ?? this.loading,
      );
}

final genericSeedProvider =
    StateNotifierProvider<GenericSeedController, GenericSeedState>(
        (ref) => GenericSeedController(ref));

class GenericSeedController extends StateNotifier<GenericSeedState> {
  GenericSeedController(this._ref) : super(const GenericSeedState()) {
    Future.microtask(refresh);
  }

  final Ref _ref;

  /// Ask the host whether it still needs the generic seed. A non-admin caller
  /// (or a client device) gets 403 and is treated as "no prompt"; only an
  /// admin on the host ever sees it.
  Future<void> refresh() async {
    final cfg = _ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final res =
          await _ref.read(apiClientProvider).getJson('/seed/state') as Map;
      state = state.copyWith(needsSeed: res['needsGenericSeed'] == true);
    } catch (_) {
      // 403 (not an admin) / offline: leave the prompt hidden.
      state = state.copyWith(needsSeed: false);
    }
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
