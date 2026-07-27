import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';

/// Remaining offline-grace before the Server-mode device's *next cold boot* is
/// blocked by the staleness guard. A live server already running is never
/// killed — the lock only bites on restart — so this drives a proactive in-app
/// warning while the device can still get online. See ADR-0015 and CONTEXT.md
/// "Offline grace period".
class AdminGrace {
  /// `staleAfter - (now - adminConfirmedAt)`. May be negative once the device
  /// has been offline past the limit while still running.
  final Duration remaining;
  const AdminGrace(this.remaining);

  /// Final-stretch escalation: under a day (or already past) a restart is
  /// genuinely fatal, so the banner turns red.
  bool get critical => remaining <= const Duration(hours: 24);
}

/// Below this much time-since-confirmation we treat the device as online (a
/// transient Wi-Fi blip swallows a few missed 60s heartbeats), so the banner
/// stays hidden. Above it, the device is genuinely offline-stale.
const _graceFloor = Duration(minutes: 3);

/// Emits an [AdminGrace] while the Server-mode device is offline-stale (the
/// live listener hasn't confirmed `active` from the server within [_graceFloor]),
/// else null. Server mode only, gated on a live Firebase admin session — Client
/// devices never touch Firebase and a super admin runs no local server. Reuses
/// the single [FirebaseAdminService.staleAfter] constant the boot gate enforces,
/// so the countdown can never disagree with the lock.
final adminOfflineGraceProvider = StreamProvider<AdminGrace?>((ref) async* {
  final mode = ref.watch(prefsServiceProvider).valueOrNull?.appMode();
  final fb = ref.read(firebaseAdminServiceProvider);
  final storage = ref.read(secureStorageServiceProvider);

  if (mode != AppMode.server || fb.currentUser == null) {
    yield null;
    return;
  }

  Future<AdminGrace?> probe() async {
    if (fb.currentUser == null) return null;
    final at = await storage.readAdminConfirmedAt();
    if (at == null) return null; // never confirmed → the boot gate handles it
    final offlineFor = SatClock.now().difference(at);
    if (offlineFor <= _graceFloor) return null; // online / transient blip
    return AdminGrace(FirebaseAdminService.staleAfter - offlineFor);
  }

  yield await probe();
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 30))) {
    yield await probe();
  }
});
