import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

import '_tickers.dart';

/// The guest queue is a nav destination now (ADR-0106), which means it can be
/// *absent* — and an absent destination is the half nothing else in the app
/// tests, because every other slot but Kasir is unconditional.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  test('the destination needs both the feature and the authority', () {
    expect(
      showGuestQueue(guestOrderingEnabled: true, canTakeOrder: true),
      isTrue,
    );
    // Off means the guest socket is not even bound — there is nothing to watch.
    expect(
      showGuestQueue(guestOrderingEnabled: false, canTakeOrder: true),
      isFalse,
    );
    // A kitchen or cashier login cannot accept a guest order, so the tab it
    // could not act on would be a tap that teaches nothing.
    expect(
      showGuestQueue(guestOrderingEnabled: true, canTakeOrder: false),
      isFalse,
    );
  });

  Future<void> pumpRail(WidgetTester tester, {required bool showTamu}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...tickerOverrides],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: TabletSideRail(
              active: 'tables',
              readyCount: 0,
              kitchenCount: 0,
              showTamu: showTamu,
              guestPending: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
  }

  testWidgets('the rail carries the slot when the venue takes guest orders', (
    tester,
  ) async {
    await pumpRail(tester, showTamu: true);
    expect(find.text(lookupAppL10n(const Locale('id')).tabTamu), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('and drops it entirely when it does not', (tester) async {
    await pumpRail(tester, showTamu: false);
    expect(find.text(lookupAppL10n(const Locale('id')).tabTamu), findsNothing);
  });
}
