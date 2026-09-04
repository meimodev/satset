import 'dart:async';
import 'dart:math';
import 'package:satset/core/time/sat_clock.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/server_relocator.dart';

/// Lifecycle stages reported by [WsClient.connState]. The UI top bar reads
/// this; repositories use [WsClient.events] instead.
enum WsConnState { connecting, open, closed }

/// Authenticated WS client with exponential backoff reconnect.
///
/// Repositories subscribe to [events] for server-pushed updates.
class WsClient {
  WsClient({
    required this.config,
    required SecureStorageService storage,
    this.onProbablyMoved,
  }) : _storage = storage;

  /// Consecutive failed connects before the host is presumed to have *moved*
  /// rather than to be down. With the capped backoff that is roughly half a
  /// minute of silence — long enough that a real reboot has usually finished,
  /// short enough that a DHCP lease change does not end the shift.
  static const relocateAfter = 5;

  /// Called every [relocateAfter] failures. Wired to the mDNS re-discovery in
  /// [wsClientProvider]; null in tests and anywhere the address is fixed.
  final Future<void> Function()? onProbablyMoved;

  /// Whether this many consecutive failures is enough to go looking. Every
  /// [relocateAfter]th, not just the first: the host may not have finished
  /// re-advertising the first time we asked.
  static bool shouldRelocate(int attempt) =>
      attempt > 0 && attempt % relocateAfter == 0;

  /// How long to wait before retry number [attempt], jittered.
  ///
  /// The base is the usual doubling, 200ms to a 10s ceiling. The jitter is
  /// what stops a venue reconnecting in lockstep: the server here is a tablet,
  /// every handset lost the socket at the same instant when it rebooted, and
  /// an undithered backoff means all of them come back on the same tick
  /// forever — a thundering herd against the one device that also has to serve
  /// the floor. Spreading the retries costs nothing and removes the spike.
  ///
  /// Jitter is **subtractive** (0.5x to 1.0x of the base) so it can only make
  /// a retry sooner, never later. That keeps the documented ceiling true and
  /// keeps `relocateAfter` attempts inside the half-minute its doc claims.
  ///
  /// [roll] is the injection seam: a test pins the ends of the range instead
  /// of asserting about a random number.
  static Duration backoffFor(int attempt, {double? roll}) {
    final base = (200 * (1 << attempt.clamp(0, 6))).clamp(200, 10000);
    final r = roll ?? _rng.nextDouble();
    return Duration(milliseconds: (base * (0.5 + 0.5 * r)).round());
  }

  /// Ceiling on the WebSocket handshake.
  ///
  /// `channel.ready` has no timeout of its own, so a connect that starts while
  /// the interface is half-up does not fail — it blocks on the OS connect
  /// timeout (~110s, errno 110), the same trap [ApiClient.requestTimeout]
  /// exists to avoid. Nothing schedules a reconnect while that attempt hangs,
  /// so the backoff's 10s ceiling is not what the user waits: two stalled
  /// handshakes is four minutes of OFFLINE on a LAN that came back at second
  /// one. Matches the HTTP budget — far above any LAN handshake, far below the
  /// kernel's.
  static const handshakeTimeout = Duration(seconds: 8);

  static final _rng = Random();

  final ApiConfig config;
  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  bool _disposed = false;
  int _attempt = 0;

  /// Surfaces the connection lifecycle to the UI. ValueNotifier (not Stream)
  /// so widgets can read the current value synchronously on first build.
  final ValueNotifier<WsConnState> connState = ValueNotifier(
    WsConnState.connecting,
  );

  final _controller = StreamController<WsEventDto>.broadcast();
  Stream<WsEventDto> get events => _controller.stream;

  Future<void> start() async {
    if (_disposed) return;
    _attempt += 1;
    connState.value = WsConnState.connecting;
    try {
      final token = await _storage.readToken();
      final deviceId = await _storage.readDeviceId();
      final wsScheme = config.baseUri.scheme == 'https' ? 'wss' : 'ws';
      final qp = <String, String>{};
      if (token != null) qp['token'] = token;
      if (deviceId != null) qp['deviceId'] = deviceId;
      final uri = config.baseUri
          .replace(scheme: wsScheme, path: '/ws')
          .replace(queryParameters: qp);
      SatLog.ws('connect attempt=$_attempt host=${uri.host}:${uri.port}');
      final channel = _pinnedConnect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (e, st) {
          SatLog.err('ws stream', e, st);
          _handleDrop();
        },
        onDone: () {
          SatLog.ws('closed');
          _handleDrop();
        },
        cancelOnError: true,
      );
      // Wait for handshake to actually complete before flipping the UI to
      // OPEN and resetting backoff. Otherwise a failed connect (cert/auth)
      // briefly shows LIVE then immediately ricochets to OFFLINE at the
      // 200ms minimum backoff — sub-second flicker on the top bar.
      try {
        await channel.ready.timeout(handshakeTimeout);
      } on TimeoutException {
        // Abandon the half-open socket rather than leaking one per attempt —
        // the retry builds a fresh channel.
        unawaited(channel.sink.close());
        rethrow;
      }
      if (_disposed || _channel != channel) return;
      SatLog.ws('open');
      connState.value = WsConnState.open;
      _attempt = 0;
      // Tell repositories the socket is live. They full-resync on this so a
      // lossy gap (empty/401 bootstrap, or events missed while down) heals on
      // every (re)connect. See ADR-0021.
      _controller.add(
        WsEventDto(type: WsEventTypes.connected, ts: SatClock.now()),
      );
    } catch (e, st) {
      SatLog.err('ws start', e, st);
      _handleDrop();
    }
  }

  void _handleDrop() {
    if (_disposed) return;
    if (connState.value != WsConnState.closed) {
      connState.value = WsConnState.closed;
    }
    _scheduleReconnect();
  }

  /// A dead Wi-Fi does not close a TCP socket — the interface goes away with no
  /// FIN and no RST, so a handset that walks out of range keeps reporting LIVE
  /// for as long as nothing is written. That stale `open` is not cosmetic: it
  /// is the signal `submitOrder` and the table screen read to decide whether to
  /// queue (ADR-0090, ADR-0116), so without a keepalive the waiter in the dead
  /// corner is told everything is fine. The ping is what makes the badge honest.
  static const _keepAlive = Duration(seconds: 5);

  WebSocketChannel _pinnedConnect(Uri uri) {
    if (uri.scheme != 'wss') {
      return IOWebSocketChannel.connect(uri, pingInterval: _keepAlive);
    }
    final pinned = config.trustedFingerprint.toLowerCase();
    final loopback = ApiClient.isLoopbackHost(uri.host);
    if (!loopback && pinned.isEmpty) {
      throw StateError(
        'wss requires trustedFingerprint on non-loopback host ${uri.host}',
      );
    }
    final httpClient = ApiClient.buildPinnedHttpClient(
      pinned,
      isLoopback: loopback,
    );
    return IOWebSocketChannel.connect(
      uri,
      customClient: httpClient,
      pingInterval: _keepAlive,
    );
  }

  void _onMessage(dynamic raw) {
    try {
      final j = jsonDecode(raw as String) as Map<String, dynamic>;
      final ev = WsEventDto.fromJson(j);
      SatLog.wsLazy(() => 'rx ${j['type'] ?? "?"}');
      _controller.add(ev);
    } catch (e, st) {
      SatLog.err('ws decode', e, st);
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _sub?.cancel();
    _channel?.sink.close();
    final delay = backoffFor(_attempt);
    SatLog.ws('reconnect in ${delay.inMilliseconds}ms attempt=$_attempt');
    // Retrying the same address forever is only right while the address is
    // still right. A server that took a new DHCP lease is up, reachable and
    // invisible to this loop, so every N failures the handset asks the LAN
    // where the certificate it trusts is now living.
    if (shouldRelocate(_attempt)) unawaited(onProbablyMoved?.call());
    _reconnect?.cancel();
    _reconnect = Timer(delay, start);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnect?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _controller.close();
    connState.value = WsConnState.closed;
    connState.dispose();
  }
}

final wsClientProvider = Provider<WsClient>((ref) {
  final cfg = ref.watch(apiConfigProvider);
  if (cfg == null) {
    throw StateError('ApiConfig not initialised.');
  }
  final storage = ref.watch(secureStorageServiceProvider);
  final c = WsClient(
    config: cfg,
    storage: storage,
    onProbablyMoved: () => relocateServer(ref),
  );
  c.start();
  ref.onDispose(c.dispose);
  return c;
});

/// Live WS connection lifecycle. UI top bar reads this to render the
/// network indicator. Returns [WsConnState.closed] before pairing AND before
/// login — without a valid bearer token the server 403s every WS upgrade,
/// which under exponential backoff would flicker the indicator between
/// `open` and `closed`.
final wsConnStateProvider = Provider<WsConnState>((ref) {
  final cfg = ref.watch(apiConfigProvider);
  final authed = ref.watch(authStateProvider.select((s) => s.isAuthenticated));
  if (cfg == null || !authed) return WsConnState.closed;
  // Mirror WsClient's connState WITHOUT owning it — a ChangeNotifierProvider
  // would dispose this borrowed notifier on recompute (logout/re-login),
  // leaving WsClient holding a disposed ValueNotifier.
  final notifier = ref.watch(wsClientProvider).connState;
  void onChange() => ref.invalidateSelf();
  notifier.addListener(onChange);
  ref.onDispose(() => notifier.removeListener(onChange));
  return notifier.value;
});
