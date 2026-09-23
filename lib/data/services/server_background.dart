import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android owns the foreground notification and CPU lock; Dart owns the server.
abstract final class ServerBackground {
  static const _channel = MethodChannel('satset/host');

  static Future<void> _send(String method) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>(method);
    }
  }

  static Future<void> start() => _send('start');
  static Future<void> ready() => _send('ready');
  static Future<void> stop() => _send('stop');
}
