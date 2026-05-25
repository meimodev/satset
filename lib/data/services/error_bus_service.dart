import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';

/// Severity of a transport/retry user-facing error.
enum AppErrorLevel { info, warning, error }

class AppError {
  final String message;
  final AppErrorLevel level;
  final DateTime at;
  final String? code;
  const AppError({
    required this.message,
    required this.level,
    required this.at,
    this.code,
  });
}

/// Centralised, app-wide error stream for transport / retry surfaces.
///
/// Repositories push here; UI listens to show snack bars / banners.
class ErrorBusService {
  final _c = StreamController<AppError>.broadcast();
  Stream<AppError> get stream => _c.stream;

  void push(String message,
      {AppErrorLevel level = AppErrorLevel.error, String? code}) {
    SatLog.err('bus ${level.name}${code != null ? " $code" : ""}: $message');
    _c.add(AppError(
      message: message,
      level: level,
      at: DateTime.now(),
      code: code,
    ));
  }

  Future<void> dispose() => _c.close();
}

final errorBusServiceProvider = Provider<ErrorBusService>((ref) {
  final bus = ErrorBusService();
  ref.onDispose(bus.dispose);
  return bus;
});
