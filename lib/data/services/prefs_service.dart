import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/models/device_printer.dart';
import 'package:satset/domain/models/app_mode.dart';

/// Non-sensitive preferences: app mode, paired host/port, last selected mode.
class PrefsService {
  PrefsService(this._p);
  final SharedPreferences _p;

  static const _kMode = 'satset.app_mode';
  static const _kPairedHost = 'satset.paired.host';
  static const _kPairedPort = 'satset.paired.port';
  static const _kAudioAlert = 'satset.audio_alert';
  static const _kDevicePrinters = 'satset.device_printers';

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

  /// Device-local (per-phone) printers. Stored as a JSON array. See ADR-0020.
  List<DevicePrinter> devicePrinters() {
    final raw = _p.getString(_kDevicePrinters);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          DevicePrinter.fromJson((e as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> setDevicePrinters(List<DevicePrinter> printers) async {
    await _p.setString(
        _kDevicePrinters, jsonEncode([for (final p in printers) p.toJson()]));
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

/// Live list of this device's local printers, backed by [PrefsService].
class DevicePrintersNotifier extends StateNotifier<List<DevicePrinter>> {
  DevicePrintersNotifier(this._prefs) : super(_prefs?.devicePrinters() ?? const []);
  final PrefsService? _prefs;

  Future<void> add(DevicePrinter p) async {
    final next = [...state, p];
    state = next;
    await _prefs?.setDevicePrinters(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((p) => p.id != id).toList();
    state = next;
    await _prefs?.setDevicePrinters(next);
  }
}

final devicePrintersProvider =
    StateNotifierProvider<DevicePrintersNotifier, List<DevicePrinter>>((ref) {
  final prefs = ref.watch(prefsServiceProvider).valueOrNull;
  return DevicePrintersNotifier(prefs);
});
