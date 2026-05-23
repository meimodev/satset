import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:satset/data/models/ws_event_dto.dart';

class _WsConn {
  final WebSocketChannel ch;
  final String userId;
  final String deviceId;
  _WsConn(this.ch, this.userId, this.deviceId);
}

/// Authenticated WS connection registry. Routes call [broadcast] to push
/// events to every active client.
class WsHub {
  final List<_WsConn> _conns = [];

  void register(WebSocketChannel ch, String userId, String deviceId) {
    final c = _WsConn(ch, userId, deviceId);
    _conns.add(c);
    ch.stream.listen(
      (_) {},
      onDone: () => _conns.remove(c),
      onError: (_) => _conns.remove(c),
      cancelOnError: true,
    );
  }

  void broadcast(String type, Map<String, dynamic> payload) {
    final ev = WsEventDto(
      v: 1,
      type: type,
      payload: payload,
      ts: DateTime.now(),
    );
    final frame = jsonEncode(ev.toJson());
    for (final c in List.of(_conns)) {
      try {
        c.ch.sink.add(frame);
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final c in List.of(_conns)) {
      try {
        await c.ch.sink.close();
      } catch (_) {}
    }
    _conns.clear();
  }
}
