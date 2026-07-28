import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/models/device_printer.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/app_mode.dart';

/// Non-sensitive preferences: app mode, paired host/port, last selected mode.
class PrefsService {
  PrefsService(this._p);
  final SharedPreferences _p;

  static const _kMode = 'satset.app_mode';
  static const _kPairedHost = 'satset.paired.host';
  static const _kPairedPort = 'satset.paired.port';
  static const _kAudioAlert = 'satset.audio_alert';
  static const _kMutedAlerts = 'satset.muted_alerts';
  static const _kDevicePrinters = 'satset.device_printers';

  /// Bumped from `satset.theme` when Neon Terang became the shipped default
  /// (ADR-0057). A device carrying the old key finds nothing under the new one,
  /// so `SatTheme.fromKey(null)` hands it the fallback exactly once. Another
  /// forced re-theme is another bump; the orphaned value costs nothing.
  static const _kTheme = 'satset.theme.v2';

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

  /// Device-local per-event mute (ADR-0044). Orthogonal to the venue-wide
  /// sound choice (which clip) and to the venue-wide `*AlertEnabled` flags
  /// (venue policy) — this is one operator silencing one cue on their own
  /// handset. Stored as preset-stable enum names so adding an event never
  /// invalidates a stored set.
  Set<AlertEvent> mutedAlerts() {
    final raw = _p.getStringList(_kMutedAlerts);
    if (raw == null || raw.isEmpty) return const {};
    return {
      for (final e in AlertEvent.values)
        if (raw.contains(e.name)) e,
    };
  }

  Future<void> setAlertMuted(AlertEvent event, bool muted) async {
    final next = mutedAlerts().toSet();
    if (muted) {
      next.add(event);
    } else {
      next.remove(event);
    }
    await _p.setStringList(_kMutedAlerts, [for (final e in next) e.name]);
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
      _kDevicePrinters,
      jsonEncode([for (final p in printers) p.toJson()]),
    );
  }

  /// Device-local look (ADR-0045). Deliberately not per-user and not per-venue:
  /// staff pick by the light in the room they are standing in, and shared
  /// hardware must not re-theme on every shift change.
  ///
  /// Stored as an opaque key — resolving it to a palette is the UI layer's job,
  /// since `data/` must not import `ui/`.
  String? themeKey() => _p.getString(_kTheme);
  Future<void> setThemeKey(String key) async {
    await _p.setString(_kTheme, key);
  }
}

/// Live read of the audio-alert flag. Returns true while prefs are loading.
final audioAlertEnabledProvider = Provider<bool>((ref) {
  final p = ref.watch(prefsServiceProvider).valueOrNull;
  return p?.audioAlertEnabled() ?? true;
});

/// Device-local muted cues. Empty = every cue this device's role receives
/// will play. See ADR-0044.
final mutedAlertsProvider = Provider<Set<AlertEvent>>((ref) {
  final p = ref.watch(prefsServiceProvider).valueOrNull;
  return p?.mutedAlerts() ?? const {};
});

final prefsServiceProvider = FutureProvider<PrefsService>((ref) async {
  final p = await SharedPreferences.getInstance();
  return PrefsService(p);
});

/// Live list of this device's local printers, backed by [PrefsService].
class DevicePrintersNotifier extends StateNotifier<List<DevicePrinter>> {
  DevicePrintersNotifier(this._prefs)
    : super(_prefs?.devicePrinters() ?? const []);
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
