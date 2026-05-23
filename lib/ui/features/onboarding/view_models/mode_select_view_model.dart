import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/server/server.dart';

/// App-level handle to the in-process server. Mode-select boots it for
/// AppMode.server; main() reuses an existing runtime on cold start.
final serverRuntimeProvider = StateProvider<ServerRuntime?>((_) => null);

class ModeSelectState {
  final AppMode current;
  final bool busy;
  final String? error;
  const ModeSelectState({
    required this.current,
    this.busy = false,
    this.error,
  });

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

  Future<void> choose(AppMode mode) async {
    state = state.copyWith(busy: true, error: null);
    try {
      await _prefs.setAppMode(mode);
      if (mode == AppMode.server && Platform.isAndroid) {
        var rt = _ref.read(serverRuntimeProvider);
        rt ??= await ServerRuntime.boot();
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

final modeSelectViewModelProvider = StateNotifierProvider.autoDispose<
    ModeSelectViewModel, ModeSelectState>((ref) {
  final prefs = ref.watch(prefsServiceProvider).requireValue;
  return ModeSelectViewModel(ref, prefs);
});
