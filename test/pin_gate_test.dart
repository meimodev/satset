import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:satset/data/repositories/ping_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/pin_sheet.dart';
import 'package:satset/ui/features/auth/views/pin_screen.dart';

void main() {
  group('pingOffline', () {
    test('a reachable host is never offline, whatever the failure count', () {
      expect(
        pingOffline(const PingState(reachable: true, consecutiveFailures: 9)),
        isFalse,
      );
    });

    test('one failed probe is a blip, not a verdict', () {
      // The debounce is the whole reason the pad does not die on a Wi-Fi
      // stutter. Drop it and every cold boot disables its own keypad.
      expect(
        pingOffline(const PingState(reachable: false, consecutiveFailures: 1)),
        isFalse,
      );
    });

    test('two failed probes are out of reach', () {
      expect(
        pingOffline(const PingState(reachable: false, consecutiveFailures: 2)),
        isTrue,
      );
    });
  });

  testWidgets('a blocked pad is dead and says why', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final blocked = ValueNotifier<String?>(null);
    addTearDown(blocked.dispose);
    var submits = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showPinSheet(
                  c,
                  title: 'Masuk',
                  subtitle: 'Tersambung',
                  blockedReason: blocked,
                  onSubmit: (_) async {
                    submits++;
                    return null;
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Live: the keys work.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6 digit'), findsOneWidget);

    // Blocked: the reason replaces the helper line and the keys go dead, so a
    // PIN the host cannot possibly verify is refused before the first digit
    // rather than eight seconds after the sixth.
    blocked.value = 'Server tidak terjangkau.';
    await tester.pumpAndSettle();
    expect(find.text('Server tidak terjangkau.'), findsOneWidget);
    for (final d in ['2', '3', '4', '5', '6']) {
      await tester.tap(find.text(d));
      await tester.pumpAndSettle();
    }
    expect(submits, 0, reason: 'a dead pad must not reach onSubmit');

    // And it un-deadens itself when the probe recovers — there is no retry
    // control because PingRepository re-probes on its own every 5s.
    blocked.value = null;
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 6 digit'), findsOneWidget);
  });

  group('the admitted fingerprint', () {
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    test(
      'survives a sign-out, because a shift handover is not an eviction',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final s = SecureStorageService();
        await s.writeToken('jwt');
        await s.writeMe('{"userId":"u1"}');
        await s.writeAdmittedFingerprint('FP-A');

        await s.clearSession();

        // The bug this guards: `clearSession` drops the cached `/auth/me`, so
        // reading admission off that cache told the next waiter on a dark LAN
        // that the device had never signed in here — on the handover where the
        // advice most needs to be right.
        expect(await s.readMe(), isNull);
        expect(await s.readToken(), isNull);
        expect(await s.readAdmittedFingerprint(), 'FP-A');
      },
    );

    test(
      'dies with the pairing, so another venue is honestly un-admitted',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final s = SecureStorageService();
        await s.writeAdmittedFingerprint('FP-A');

        await s.clearPairing();

        expect(await s.readAdmittedFingerprint(), isNull);
      },
    );
  });
}
