import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satset/data/models/device_printer.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/release_gate.dart';

/// Non-sensitive preferences: app mode, paired host/port, last selected mode.
class PrefsService {
  PrefsService(this._p);
  final SharedPreferences _p;

  static const _kMode = 'satset.app_mode';
  static const _kPairedHost = 'satset.paired.host';
  static const _kPairedPort = 'satset.paired.port';
  static const _kMutedAlerts = 'satset.muted_alerts';
  static const _kDevicePrinters = 'satset.device_printers';

  /// The **Antrean kirim** — orders a terputus handset captured and has not
  /// delivered (ADR-0090). Device-scoped like the printers above and for the
  /// same reason: handsets are shared, and a backlog must outlive the session
  /// that captured it. Survives a restart on purpose — a dead battery must not
  /// cost the venue a bill.
  static const _kSendQueue = 'satset.send_queue';

  /// Bumped from `satset.theme` when Neon Terang became the shipped default
  /// (ADR-0057). A device carrying the old key finds nothing under the new one,
  /// so `SatTheme.fromKey(null)` hands it the fallback exactly once. Another
  /// forced re-theme is another bump; the orphaned value costs nothing.
  static const _kTheme = 'satset.theme.v2';

  /// Device-local language (ADR-0083). Sits beside [_kTheme] on purpose: same
  /// scope, same reasoning, same sheet on `/me`. Absent means Indonesian — the
  /// default is hard, never resolved from the system locale, because the cheap
  /// tablets a venue actually buys ship `en_US` and never have it changed.
  static const _kLocale = 'satset.locale';

  /// Last-known release gate (ADR-0087). Device-local like everything else
  /// here, and deliberately survives a restart: the block it drives must not be
  /// clearable by force-quitting the app.
  static const _kReleaseGate = 'satset.release_gate';

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

  /// Device-local per-event mute — the *only* device-level audio axis
  /// (ADR-0044). Orthogonal to the venue-wide sound choice (which clip) and to
  /// the venue-wide `*AlertEnabled` flags (whether the cue sounds at all) —
  /// this is one operator silencing one cue on their own handset. Stored as
  /// preset-stable enum names so adding an event never invalidates a stored set.
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

  /// Raw JSON array of undelivered intents. Kept opaque here — the queue owns
  /// its own shape, and prefs is only the shelf it sits on. See ADR-0090.
  String? sendQueueJson() => _p.getString(_kSendQueue);

  Future<void> setSendQueueJson(String? v) async {
    v == null
        ? await _p.remove(_kSendQueue)
        : await _p.setString(_kSendQueue, v);
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

  /// Device-local language tag (`id` / `en`). See [_kLocale] and ADR-0083.
  /// Stored as an opaque tag — resolving it to a `Locale` is the UI layer's
  /// job, for the same reason [themeKey] stays a string here.
  String? localeTag() => _p.getString(_kLocale);
  Future<void> setLocaleTag(String tag) async {
    await _p.setString(_kLocale, tag);
  }

  /// The last release gate this device heard, cached so a client stays gated
  /// with its host down (ADR-0087).
  ///
  /// Without it a blocked waiter phone would unblock itself by losing the
  /// wifi — the floor exists precisely for builds that must stop running, and
  /// "the host is unreachable" is not evidence the build became acceptable. An
  /// *unpaired* device never has one, so it is never blocked.
  ReleaseGate releaseGate() {
    final raw = _p.getString(_kReleaseGate);
    if (raw == null || raw.isEmpty) return ReleaseGate.unknown;
    try {
      return ReleaseGate.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return ReleaseGate.unknown;
    }
  }

  Future<void> setReleaseGate(ReleaseGate g) async {
    if (g.isEmpty) {
      await _p.remove(_kReleaseGate);
      return;
    }
    await _p.setString(_kReleaseGate, jsonEncode(g.toJson()));
  }
}

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
