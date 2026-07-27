import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/server/server.dart';

// `serverRuntimeProvider` now lives in server.dart (the runtime's own home) so
// the data-layer admin auth flow can reach it. Re-exported here for the
// existing importers (pin_view_model, main).
export 'package:satset/server/server.dart' show serverRuntimeProvider;

class ModeSelectState {
  final AppMode current;
  final bool busy;
  final String? error;
  const ModeSelectState({required this.current, this.busy = false, this.error});

  ModeSelectState copyWith({AppMode? current, bool? busy, String? error}) =>
      ModeSelectState(
        current: current ?? this.current,
        busy: busy ?? this.busy,
        error: error,
      );
}

class ModeSelectViewModel extends StateNotifier<ModeSelectState> {
  ModeSelectViewModel(this._ref, this._prefs)
    : super(ModeSelectState(current: _prefs.appMode()));

  final Ref _ref;
  final PrefsService _prefs;

  Future<void> choose(AppMode mode, {String venueId = ''}) async {
    SatLog.vm('ModeVM choose ${mode.name}');
    state = state.copyWith(busy: true, error: null);
    try {
      await _prefs.setAppMode(mode);
      if (mode == AppMode.server && Platform.isAndroid) {
        // The Main-Device decision (host vs. join-as-admin-client) is made in
        // AuthRepository.signInAsAdmin before this runs, so reaching here means
        // we are becoming the venue host. The `venueId` is advertised in the
        // mDNS TXT so other admins discover us. See ADR-0017.
        var rt = _ref.read(serverRuntimeProvider);
        rt ??= await ServerRuntime.boot(venueId: venueId);
        _ref.read(serverRuntimeProvider.notifier).state = rt;
        _ref.read(apiConfigProvider.notifier).state = ApiConfig(
          baseUri: Uri.parse('https://127.0.0.1:${rt.port}'),
          trustedFingerprint: rt.tls.fingerprint,
        );
      }
      state = state.copyWith(current: mode, busy: false);
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }
}

// NOTE: not autoDispose — PinViewModel reads this notifier without watching
// and awaits long-running ServerRuntime.boot(). An autoDispose provider would
// risk being torn down mid-boot and dropping its error state.
final modeSelectViewModelProvider =
    StateNotifierProvider<ModeSelectViewModel, ModeSelectState>((ref) {
      final prefs = ref.watch(prefsServiceProvider).requireValue;
      return ModeSelectViewModel(ref, prefs);
    });
