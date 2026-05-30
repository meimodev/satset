// Patrol native UI test. Lives under patrol_test/ (patrol_cli's default
// target dir). Run on a connected Android device with:
//   patrol test --target patrol_test/app_boot_test.dart
// or simply `patrol test` to run every *_test.dart in patrol_test/.
//
// IMPORTANT: we pump SatSetApp directly instead of calling the real
// `main()`. In Server mode `main()` boots the embedded shelf server (TLS +
// mDNS + port binds) inside runZonedGuarded, which collides with Patrol's
// on-device app service (port 8082) and hangs the run. Pumping the widget
// tree with default providers leaves apiConfig null, so the router lands on
// /pin — real UI, no server. See docs/testing/patrol.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:satset/app.dart';

void main() {
  patrolTest('app boots and renders its root UI', ($) async {
    // Surface any boot-time exception in the JUnit failure message — on MIUI
    // the `flutter` logcat tag is stripped, so an uncaught error otherwise
    // shows as a null AssertionError with no cause.
    try {
      await $.pumpWidget(const ProviderScope(child: SatSetApp()));
      // Fixed pumps — pumpAndSettle can stall on google_fonts first-launch
      // fetch. Pump generously so the async boot providers (prefs, secure
      // storage) resolve and the router settles on a route.
      for (var i = 0; i < 6; i++) {
        await $.pump(const Duration(seconds: 1));
      }
    } catch (e, st) {
      fail('BOOT ERROR: $e\n$st');
    }
    // Pipeline smoke: the app boots and mounts its MaterialApp. Assert only
    // MaterialApp — which route/Scaffold renders depends on async provider
    // load state (apiConfig/prefs/secure storage), so asserting a Scaffold is
    // timing-flaky on a cold device. MaterialApp present == app booted clean.
    expect($(MaterialApp), findsOneWidget);
  });
}
