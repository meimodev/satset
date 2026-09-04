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
  static const _kSendQueueQuarantine = 'satset.send_queue.quarantine';

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

  /// The venue's settings as last mirrored, **whole** (ADR-0128).
  ///
  /// Supersedes the two-field shape cache of ADR-0115. Every switch on the DTO
  /// fails *closed* through its freezed default, so a client that cold-boots
  /// away from its host does not merely render the wrong shape — it renders a
  /// venue with membership off, guest ordering off and every threshold at the
  /// factory number. The venue's own answer, once heard, outlives the
  /// connection that carried it; stale beats absent, because absent is a lie
  /// the operator cannot see.
  ///
  /// Stored as the wire JSON, for the reason [_kSendQueue] is: the DTO owns
  /// its own shape and prefs is only the shelf it sits on. `modules: null`
  /// ("never mirrored", reads as entitled) and `modules: []` ("holds no
  /// module") stay different answers through it.
  static const _kVenueSettings = 'satset.venue_settings';

  /// The pre-ADR-0128 shape cache. **Read once, never written.** A device that
  /// upgrades and cold-boots before it next reaches its host would otherwise
  /// find [_kVenueSettings] empty and re-acquire the exact flicker ADR-0115
  /// was written to remove.
  static const _kVenueShape = 'satset.venue_shape';

  /// The server fingerprint the venue cache below was mirrored from
  /// (ADR-0128, corrected).
  ///
  /// **The certificate is the venue's identity, not the address** (ADR-0080).
  /// `relocateServer` rewrites the paired host whenever a DHCP lease turns
  /// over, so keying the cache on host:port threw a venue's own settings away
  /// on a router reboot — at the exact moment the device could not reach its
  /// host and the cache was the only thing it had.
  ///
  /// Lives in prefs rather than beside the fingerprint in secure storage
  /// because it is not a secret: it is a *label* saying which server these
  /// blobs came from, and it has to be readable in the same breath as them.
  static const _kVenueCacheFp = 'satset.venue_cache_fp';

  /// The [[Preset diskon]] catalogue as last mirrored (ADR-0128). Cached for
  /// the same reason the settings above are: the picker opens mid-transaction,
  /// and a cashier settling on a dark handset needs the venue's own promos,
  /// not an empty sheet.
  static const _kDiscountPresets = 'satset.discount_presets';

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

  /// The last backlog that would not parse, kept verbatim.
  ///
  /// A queue that cannot be decoded still *is* the orders a handset took while
  /// it was cut off. Deleting it makes the app boot; it also makes those
  /// orders unrecoverable and unexaminable, and nobody ever finds out what
  /// shape they were in. So the blob moves aside instead of going away — one
  /// slot, overwritten by the next corruption, because the interesting one is
  /// the one that just happened.
  String? sendQueueQuarantineJson() => _p.getString(_kSendQueueQuarantine);

  Future<void> setSendQueueQuarantineJson(String? v) async {
    v == null
        ? await _p.remove(_kSendQueueQuarantine)
        : await _p.setString(_kSendQueueQuarantine, v);
  }

  /// Device-local look (ADR-0045). Deliberately not per-user and not per-venue:
  /// staff pick by the light in the room they are standing in, and shared
  /// hardware must not re-theme on every shift change.
  ///
  /// Stored as an opaque key — resolving it to a palette is the UI layer's job,
  /// since `data/` must not import `ui/`.
  /// The cached venue settings JSON, or null when this device has never heard
  /// any. Kept opaque — `VenueSettingsDto` owns the parse.
  String? venueSettingsJson() => _p.getString(_kVenueSettings);

  Future<void> setVenueSettingsJson(String v, {String? fingerprint}) async {
    await _p.setString(_kVenueSettings, v);
    await _stampVenueCache(fingerprint);
  }

  /// The pre-ADR-0128 shape cache, for the one boot after an upgrade where
  /// [venueSettingsJson] is still empty. See [_kVenueShape].
  ({List<String>? modules, List<String>? counterConfig})? legacyVenueShape() {
    final raw = _p.getString(_kVenueShape);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      List<String>? list(String k) => m[k] == null
          ? null
          : [for (final e in m[k] as List) e.toString()];
      return (modules: list('modules'), counterConfig: list('counterConfig'));
    } catch (_) {
      return null;
    }
  }

  /// Raw JSON array of discount presets. Opaque here, like the send queue.
  String? discountPresetsJson() => _p.getString(_kDiscountPresets);

  Future<void> setDiscountPresetsJson(String v, {String? fingerprint}) async {
    await _p.setString(_kDiscountPresets, v);
    await _stampVenueCache(fingerprint);
  }

  /// The [[Pengeluaran kunjungan]] category catalogue (ADR-0130), cached for
  /// the same reason the presets are: the picker opens on a floor that may have
  /// no host, and "the venue authored no categories" must not be what a dark
  /// handset renders.
  static const _kExpenseCategories = 'satset.expense_categories';

  String? expenseCategoriesJson() => _p.getString(_kExpenseCategories);

  Future<void> setExpenseCategoriesJson(String v, {String? fingerprint}) async {
    await _p.setString(_kExpenseCategories, v);
    await _stampVenueCache(fingerprint);
  }

  /// Where the [[Salinan pelanggan]] resumes its sync, and which server it came
  /// from (ADR-0129).
  ///
  /// The mirror's rows live in the client database, not here — these are its
  /// two labels, kept beside the venue cache's own label because they answer
  /// the same question about the same device.
  static const _kMemberMirrorCursor = 'satset.member_mirror_cursor';
  static const _kMemberMirrorFp = 'satset.member_mirror_fp';

  /// Opaque: minted by the host and never parsed here. A cursor a client can
  /// build is a cursor it can build wrong.
  String? memberMirrorCursor() => _p.getString(_kMemberMirrorCursor);
  Future<void> setMemberMirrorCursor(String? v) async {
    if (v == null || v.isEmpty) {
      await _p.remove(_kMemberMirrorCursor);
      return;
    }
    await _p.setString(_kMemberMirrorCursor, v);
  }

  String? memberMirrorFingerprint() => _p.getString(_kMemberMirrorFp);
  Future<void> setMemberMirrorFingerprint(String v) =>
      _p.setString(_kMemberMirrorFp, v);

  /// Forget where the mirror was and whose it was. The rows themselves are
  /// dropped by `MemberMirror.wipe`, which calls this.
  Future<void> clearMemberMirrorMeta() async {
    await _p.remove(_kMemberMirrorCursor);
    await _p.remove(_kMemberMirrorFp);
  }

  /// Which server the cached blobs came from, or null on a device that cached
  /// before this label existed — read as "unknown", never as "foreign", so an
  /// upgrade does not throw away a cache it cannot vouch for.
  String? venueCacheFingerprint() => _p.getString(_kVenueCacheFp);

  Future<void> _stampVenueCache(String? fingerprint) async {
    if (fingerprint == null || fingerprint.isEmpty) return;
    await _p.setString(_kVenueCacheFp, fingerprint);
  }

  /// Forget everything this device mirrored from a venue.
  ///
  /// Called when the paired **certificate** changes, never when its address
  /// does: venue A's `membersEnabled`, earn rate, debt limit and promos must
  /// never paint venue B's first offline frame, while venue A's own server
  /// moving to a new DHCP address is still venue A (ADR-0080, ADR-0128).
  Future<void> clearVenueCache() async {
    await _p.remove(_kVenueSettings);
    await _p.remove(_kVenueShape);
    await _p.remove(_kDiscountPresets);
    await _p.remove(_kExpenseCategories);
    await _p.remove(_kVenueCacheFp);
  }

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
