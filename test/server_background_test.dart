import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/server_background.dart';
import 'package:satset/server/server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('satset/host');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'rejected foreground start fails before opening the database and can retry',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'start') {
          throw PlatformException(code: 'foreground_start_denied');
        }
        return null;
      });
      final first = ServerRuntime.boot();
      expect(identical(first, ServerRuntime.boot()), isTrue);
      await expectLater(first, throwsA(isA<PlatformException>()));
      expect(calls, ['start', 'stop']);
      await expectLater(
        ServerRuntime.boot(),
        throwsA(isA<PlatformException>()),
      );
      expect(calls, ['start', 'stop', 'start', 'stop']);
    },
  );

  testWidgets(
    'timeout stops hosting and prevents a late start from opening sockets',
    (tester) async {
      // Widget tests already default to Android; leave framework debug globals
      // untouched when its invariant check runs, before the test tearDown.
      debugDefaultTargetPlatformOverride = null;
      final start = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'start') await start.future;
        return null;
      });
      final boot = ServerRuntime.boot();
      final failed = expectLater(boot, throwsA(isA<TimeoutException>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await failed;
      expect(calls, ['start', 'stop']);
      // A retry cannot race the abandoned database/TLS startup.
      expect(identical(boot, ServerRuntime.boot()), isTrue);
      start.complete();
      await tester.pump();
      expect(calls, ['start', 'stop', 'stop']);
      expect(calls, isNot(contains('ready')));
    },
  );

  test('non-Android platforms do not acquire a host service', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    await ServerBackground.start();
    await ServerBackground.ready();
    await ServerBackground.stop();
    expect(calls, isEmpty);
  });
}
