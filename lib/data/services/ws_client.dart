import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';

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

  final _controller = StreamController<WsEventDto>.broadcast();
  Stream<WsEventDto> get events => _controller.stream;

  Future<void> start() async {
    if (_disposed) return;
    _attempt += 1;
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
      _channel = _pinnedConnect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _attempt = 0;
    } catch (_) {
      _scheduleReconnect();
    }
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
      _controller.add(WsEventDto.fromJson(j));
    } catch (_) {
      // ignore malformed frames
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _sub?.cancel();
    _channel?.sink.close();
    final delay = Duration(
        milliseconds: (200 * (1 << _attempt.clamp(0, 6))).clamp(200, 10000));
    _reconnect?.cancel();
    _reconnect = Timer(delay, start);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnect?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _controller.close();
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
