import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/ui/core/design/sat_theme.dart';

/// Device-local theme selection (ADR-0045).
///
/// Seeds from [PrefsService] and writes through on every change. While prefs
/// are still loading the fallback renders, so the first frame is never blocked
/// on disk — a device that has chosen a theme swaps to it as soon as prefs
/// resolve, which is a one-frame flicker at worst on cold start.
class SatThemeNotifier extends StateNotifier<SatTheme> {
  SatThemeNotifier(this._prefs) : super(SatTheme.fromKey(_prefs?.themeKey()));

  final PrefsService? _prefs;

  Future<void> select(SatTheme t) async {
    if (state == t) return;
    SatLog.vm('Theme select ${t.name}');
    state = t;
    await _prefs?.setThemeKey(t.name);
  }
}

final satThemeProvider = StateNotifierProvider<SatThemeNotifier, SatTheme>((
  ref,
) {
  final prefs = ref.watch(prefsServiceProvider).valueOrNull;
  return SatThemeNotifier(prefs);
});
