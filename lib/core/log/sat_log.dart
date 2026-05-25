import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Brief, category-tagged logger for SatSet.
///
/// All emit paths short-circuit when [kDebugMode] is false so release builds
/// strip the bodies. The string interpolation at the call site survives
/// (acceptable for the readability win); for per-frame hot paths, prefer the
/// `*Lazy` variants that defer message construction.
final class SatLog {
  SatLog._();

  static const _http = 'HTTP';
  static const _ws = 'WS';
  static const _repo = 'REPO';
  static const _vm = 'VM';
  static const _nav = 'NAV';
  static const _err = 'ERR';
  static const _srv = 'SRV';
  static const _boot = 'BOOT';

  static bool _initialised = false;

  static void init() {
    if (!kDebugMode || _initialised) return;
    _initialised = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((r) {
      final ts = _ts(r.time);
      final line = '[$ts][${r.loggerName}] ${r.message}';
      developer.log(
        line,
        time: r.time,
        name: r.loggerName,
        level: r.level.value,
        error: r.error,
        stackTrace: r.stackTrace,
      );
      // ignore: avoid_print
      if (kDebugMode) print(line);
      if (r.error != null) {
        // ignore: avoid_print
        print(r.error);
        if (r.stackTrace != null) {
          // ignore: avoid_print
          print(r.stackTrace);
        }
      }
    });
  }

  static void http(String line) => _emit(_http, line);
  static void httpLazy(String Function() build) => _emitLazy(_http, build);
  static void ws(String line) => _emit(_ws, line);
  static void wsLazy(String Function() build) => _emitLazy(_ws, build);
  static void repo(String line) => _emit(_repo, line);
  static void vm(String line) => _emit(_vm, line);
  static void vmLazy(String Function() build) => _emitLazy(_vm, build);
  static void nav(String line) => _emit(_nav, line);
  static void srv(String line) => _emit(_srv, line);
  static void srvLazy(String Function() build) => _emitLazy(_srv, build);
  static void boot(String line) => _emit(_boot, line);

  static void err(String line, [Object? error, StackTrace? st]) {
    if (!kDebugMode) return;
    Logger(_err).severe(line, error, st);
  }

  static void _emit(String tag, String line) {
    if (!kDebugMode) return;
    Logger(tag).info(line);
  }

  static void _emitLazy(String tag, String Function() build) {
    if (!kDebugMode) return;
    Logger(tag).info(build());
  }

  static String _ts(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
  }
}
