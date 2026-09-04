import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/app_version.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'package:satset/server/server.dart';

/// Owns this device's view of the [[Release gate]] (ADR-0130), from whichever
/// of the two sources it has.
///
/// **The host reads the cloud; everyone else reads the host.** Clients never
/// touch Firebase, so the gate reaches them over the LAN — once from `/healthz`
/// at bootstrap, then live on the `release.gate` broadcast. Both paths land
/// here so the comparison that decides whether a device stops is written once.
///
/// Every gate that arrives is cached to `SharedPreferences`, and the cache is
/// what the notifier starts from. A blocked device therefore stays blocked
/// across a restart and across losing its host — force-quitting the app is not
/// a way out of a floor.
class ReleaseGateRepository extends StateNotifier<ReleaseGate> {
  /// [listen] off gives an inert notifier parked on [seed] — the widget book
  /// and the tests, where a live cloud/WS wire would be the thing under test
  /// rather than the widget.
  ReleaseGateRepository({
    required this.ref,
    required ReleaseGate seed,
    bool listen = true,
  }) : super(seed) {
    // Wired synchronously, not off a microtask: the provider watches prefs, so
    // a deferred `_start` could land after SharedPreferences resolved and
    // marked this notifier for rebuild — which is the `!_didChangeDependency`
    // assert every cold boot used to raise. Reads during create are fine; the
    // only awaits are past the network call.
    if (listen) unawaited(_start());
  }

  final Ref ref;
  StreamSubscription<ReleaseGate>? _cloudSub;
  StreamSubscription<WsEventDto>? _wsSub;

  @override
  void dispose() {
    _cloudSub?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final mode = ref.read(prefsServiceProvider).valueOrNull?.appMode();
    if (mode == AppMode.server) {
      _watchCloud();
      return;
    }
    // Unpaired: no host to read, no socket to wire — and `wsClientProvider`
    // throws rather than returning null, so reaching it here is how every cold
    // boot on the sign-in screen used to raise `ApiConfig not initialised`.
    // The provider rebuilds when prefs land a paired host, re-entering here.
    if (ref.read(apiConfigProvider) == null) return;
    _wireWs();
    await _fetchFromHost();
  }

  /// Host only. Sits beside the eligibility listener in `auth_repository`
  /// rather than inside it because the gate is not about this venue — it
  /// outlives any one admin session and must keep relaying while the venue's
  /// own billing is in trouble.
  void _watchCloud() {
    if (_cloudSub != null) return;
    final fb = ref.read(firebaseAdminServiceProvider);
    if (fb.currentUser == null) return; // no session, no read; retried on login
    _cloudSub = fb.watchReleaseGate().listen(
      _apply,
      onError: (Object e, StackTrace st) => SatLog.err('release gate watch', e, st),
    );
  }

  /// Client only. `/healthz` is unauthenticated, so this works at the PIN
  /// screen — which is the point: the block has to bite before login.
  Future<void> _fetchFromHost() async {
    if (ref.read(apiConfigProvider) == null) return;
    try {
      final raw = await ref.read(apiClientProvider).getJson('/healthz');
      final j = (raw as Map?)?['releaseGate'];
      if (j is Map) _apply(ReleaseGate.fromJson(j.cast<String, dynamic>()));
    } catch (e) {
      // A host that cannot be reached says nothing about the floor. Keep the
      // cached gate and try again on the next socket connect.
      SatLog.err('release gate fetch', e);
    }
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        // ADR-0021: the socket dropping is the one moment a client can have
        // missed a floor moving, so re-read rather than wait for a push.
        case WsEventTypes.connected:
          unawaited(_fetchFromHost());
        case WsEventTypes.releaseGate:
          _apply(ReleaseGate.fromJson(ev.payload));
      }
    });
  }

  void _apply(ReleaseGate next) {
    // The provider watches prefs and `apiConfig`, so this notifier is rebuilt
    // mid-boot — and an in-flight `/healthz` from the disposed instance lands
    // afterwards. Writing `state` then throws, which on a client means the one
    // gate read that happens before login is swallowed by a stack trace.
    if (!mounted) return;
    // Relay to the LAN *before* the equality check, and unconditionally. Only
    // the host has a runtime; on a client this is null and the write is
    // skipped. It cannot sit below the early return: this notifier restarts
    // from the prefs cache while `ServerRuntime.releaseGate` restarts at
    // `unknown`, so on the common boot — cloud agrees with the cache — the
    // runtime would never learn the gate at all. `/healthz` would omit it, no
    // `releaseGate` broadcast would fire, and the [[Salinan APK]] would never
    // prefetch. `publishReleaseGate` is itself idempotent, so relaying every
    // time costs nothing.
    ref.read(serverRuntimeProvider)?.publishReleaseGate(next);
    if (next == state) return;
    state = next;
    SatLog.repo('release gate = $next (installed ${AppVersion.value})');
    unawaited(ref.read(prefsServiceProvider).valueOrNull?.setReleaseGate(next) ??
        Future<void>.value());
  }

  /// Re-arms the cloud listener after a sign-in. Called by the auth flow, for
  /// the same reason the eligibility watch is: at construction there may be no
  /// Firebase session yet.
  void refreshCloudWatch() {
    if (ref.read(prefsServiceProvider).valueOrNull?.appMode() !=
        AppMode.server) {
      return;
    }
    _watchCloud();
  }
}

final releaseGateProvider =
    StateNotifierProvider<ReleaseGateRepository, ReleaseGate>((ref) {
      // Seeded from the cache so the first frame after a cold boot already
      // carries the floor. Watching prefs (not reading) means the seed lands as
      // soon as SharedPreferences resolves.
      final prefs = ref.watch(prefsServiceProvider).valueOrNull;
      // And watched, not read, for the same reason ADR-0128 gives for the
      // venue settings: `_start` gives up when there is no paired address, so a
      // device that pairs *after* launch would never re-enter it and would sit
      // with no gate — no `/healthz` read, no socket wired — until the next
      // cold boot. A `min` floor that waits for a restart is not the immediate
      // block ADR-0130 specifies.
      ref.watch(apiConfigProvider);
      return ReleaseGateRepository(
        ref: ref,
        seed: prefs?.releaseGate() ?? ReleaseGate.unknown,
      );
    });

/// What the gate says about *this* build. The single input to both the banner
/// and the block.
///
/// `dependencies` is what lets a nested `ProviderScope` override the gate under
/// it — the widget book puts two states of the same banner side by side, and
/// without it Riverpod refuses to read a derived provider whose input was
/// overridden in an inner scope.
final updateVerdictProvider = Provider<UpdateVerdict>(
  (ref) => ref.watch(releaseGateProvider).verdictFor(AppVersion.value),
  dependencies: [releaseGateProvider],
);

/// True on the Main Device. Not a capability — the question the update UI asks
/// is "can this device install the APK", and only the one running the server
/// can (ADR-0130). Its own provider so the book can answer it without a
/// [ServerRuntime].
final isHostDeviceProvider = Provider<bool>(
  (ref) => ref.watch(serverRuntimeProvider) != null,
);
