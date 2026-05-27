import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/domain/models/app_mode.dart';

/// Non-sensitive preferences: app mode, paired host/port, last selected mode.
class PrefsService {
  PrefsService(this._p);
  final SharedPreferences _p;

  static const _kMode = 'satset.app_mode';
  static const _kPairedHost = 'satset.paired.host';
  static const _kPairedPort = 'satset.paired.port';
  static const _kAudioAlert = 'satset.audio_alert';

  AppMode appMode() => appModeFromKey(_p.getString(_kMode));
  Future<void> setAppMode(AppMode m) async {
    final ok = await _p.setString(_kMode, appModeKey(m));
    if (!ok) {
      throw StateError('Failed to persist app mode ${appModeKey(m)}');
    }
  }

  String? pairedHost() => _p.getString(_kPairedHost);
  Future<void> setPairedHost(String? v) async {
    if (v == null) {
      await _p.remove(_kPairedHost);
    } else {
      await _p.setString(_kPairedHost, v);
    }
  }

  int? pairedPort() => _p.getInt(_kPairedPort);
  Future<void> setPairedPort(int? v) async {
    if (v == null) {
      await _p.remove(_kPairedPort);
    } else {
      await _p.setInt(_kPairedPort, v);
    }
  }

  bool audioAlertEnabled() => _p.getBool(_kAudioAlert) ?? true;
  Future<void> setAudioAlertEnabled(bool v) async {
    await _p.setBool(_kAudioAlert, v);
  }
}

/// Live read of the audio-alert flag. Returns true while prefs are loading.
final audioAlertEnabledProvider = Provider<bool>((ref) {
  final p = ref.watch(prefsServiceProvider).valueOrNull;
  return p?.audioAlertEnabled() ?? true;
});

final prefsServiceProvider = FutureProvider<PrefsService>((ref) async {
  final p = await SharedPreferences.getInstance();
  return PrefsService(p);
});
