import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/app_mode.dart';

/// The four collections that make up the **[[Salinan lantai]]** (ADR-0133).
///
/// The slot name is the prefs suffix and is therefore **persisted** — never
/// rename one, same rule as `AuditKind`. A renamed slot does not fail; it
/// orphans a device's copy and cold-boots it to the empty floor this exists to
/// prevent.
enum FloorSlot {
  tables,
  zones,
  tickets,
  menu;

  String get slot => name;
}

/// Reader and debounced writer for the [[Salinan lantai]].
///
/// A copy and never a source: the host's answer replaces it wholesale, and
/// nothing here is ever the reason a write is allowed or refused.
class FloorCache {
  FloorCache(this.ref);

  final Ref ref;
  final _timers = <FloorSlot, Timer>{};

  /// When this device's copy was written, while that copy is what the screen
  /// is painted from. Null the moment any collection refetches — from then on
  /// the floor is live, not a copy.
  ///
  /// **One notifier, not one per repository.** The staleness banner is a
  /// single statement about the whole screen (ADR-0133 §Q7); ANDing four
  /// booleans would let it say two things about one floor.
  ///
  /// A plain [ValueNotifier] and deliberately not a `StateProvider`: the
  /// repositories set this from inside their own constructors, and Riverpod
  /// forbids a provider mutating another provider while it builds. Restoring
  /// *is* construction — ADR-0128's whole point is that the copy lands before
  /// the first frame — so the stamp cannot live in the provider graph.
  final restoredAt = ValueNotifier<DateTime?>(null);

  /// How long a burst of WS deltas is allowed to run before it costs a write.
  ///
  /// A busy floor is dozens of `tableUpdated` frames a minute and each one is
  /// a `state =`. Serialising per frame is the same answer as serialising per
  /// burst, for a fraction of the disk.
  static const _debounce = Duration(seconds: 2);

  PrefsService? get _prefs => ref.read(prefsServiceProvider).valueOrNull;

  /// The copy runs on a **client** only (ADR-0133 §Q15).
  ///
  /// The host tablet talks HTTP to a server inside its own process; a cache
  /// whose invalidation story is "the paired certificate changed" is nonsense
  /// on the device holding that certificate.
  bool get _enabled => _prefs?.appMode() == AppMode.client;

  /// The last copy of [slot] this device wrote, or null if it has none.
  String? read(FloorSlot slot) {
    if (!_enabled) return null;
    return _prefs?.floorJson(slot.slot);
  }

  /// When the copy was written. Read once, by whoever restores first.
  DateTime? syncedAt() => _enabled ? _prefs?.floorSyncedAt() : null;

  /// Note that [slot] changed. [encode] runs when the debounce fires, not now
  /// — a burst of deltas costs one serialisation, not one each.
  void remember(FloorSlot slot, String Function() encode) {
    if (!_enabled) return;
    _timers[slot]?.cancel();
    _timers[slot] = Timer(_debounce, () {
      final prefs = _prefs;
      if (prefs == null) return;
      try {
        unawaited(
          prefs.setFloorJson(
            slot.slot,
            encode(),
            fingerprint: ref.read(apiConfigProvider)?.trustedFingerprint,
          ),
        );
      } catch (e) {
        // A copy that cannot be written is a floor that cold-boots empty —
        // bad, but not a reason to take down the floor that is on screen.
        SatLog.repo('floorCache.write fail slot=${slot.slot} $e');
      }
    });
  }

  /// The floor is live again: whatever was painted from the copy has since
  /// been replaced by the host's own answer.
  void markLive() => restoredAt.value = null;

  /// The floor was painted from the copy. Idempotent — the first collection to
  /// restore sets the stamp and the rest agree with it.
  void markRestored() {
    final at = syncedAt();
    if (at == null) return;
    restoredAt.value ??= at;
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    restoredAt.dispose();
  }
}

final floorCacheProvider = Provider<FloorCache>((ref) {
  final c = FloorCache(ref);
  ref.onDispose(c.dispose);
  return c;
});
