import 'dart:async';
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

/// Lifecycle stages reported by [WsClient.connState]. The UI top bar reads
/// this; repositories use [WsClient.events] instead.
enum WsConnState { connecting, open, closed }

/// Authenticated WS client with exponential backoff reconnect.
///
/// Repositories subscribe to [events] for server-pushed updates.
class WsClient {
  WsClient({required this.config, required SecureStorageService storage})
      : _storage = storage;

  final ApiConfig config;
  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  bool _disposed = false;
  int _attempt = 0;

  /// Surfaces the connection lifecycle to the UI. ValueNotifier (not Stream)
  /// so widgets can read the current value synchronously on first build.
  final ValueNotifier<WsConnState> connState =
      ValueNotifier(WsConnState.connecting);

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
      await channel.ready;
      if (_disposed || _channel != channel) return;
      SatLog.ws('open');
      connState.value = WsConnState.open;
      _attempt = 0;
      // Tell repositories the socket is live. They full-resync on this so a
      // lossy gap (empty/401 bootstrap, or events missed while down) heals on
      // every (re)connect. See ADR-0021.
      _controller.add(WsEventDto(
        type: WsEventTypes.connected,
        ts: DateTime.now(),
      ));
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

  WebSocketChannel _pinnedConnect(Uri uri) {
    if (uri.scheme != 'wss') {
      return WebSocketChannel.connect(uri);
    }
    final pinned = config.trustedFingerprint.toLowerCase();
    final loopback = ApiClient.isLoopbackHost(uri.host);
    if (!loopback && pinned.isEmpty) {
      throw StateError(
          'wss requires trustedFingerprint on non-loopback host ${uri.host}');
    }
    final httpClient =
        ApiClient.buildPinnedHttpClient(pinned, isLoopback: loopback);
    return IOWebSocketChannel.connect(uri, customClient: httpClient);
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
    final delay = Duration(
        milliseconds: (200 * (1 << _attempt.clamp(0, 6))).clamp(200, 10000));
    SatLog.ws('reconnect in ${delay.inMilliseconds}ms attempt=$_attempt');
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
  final c = WsClient(config: cfg, storage: storage);
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
  final authed =
      ref.watch(authStateProvider.select((s) => s.isAuthenticated));
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
