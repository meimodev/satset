import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';
import 'package:satset/l10n/app_localizations.dart';

/// The fleet console's two layout rules, pinned.
///
/// The header used to park its actions inside the *kicker's* row — an
/// unwrapped `Row` holding a caption and a button — so at a large system text
/// scale it overflowed rather than reflowing, on the one screen whose operator
/// is as likely to be presbyopic as not. It now drops the actions below the
/// title past [FleetHeader]'s threshold, and this asserts the geometry of that
/// rather than the pixel widths: `flutter_test` draws every glyph as a square
/// of the font size (see `phone_app_bar_fit_test.dart`), so any width number
/// asserted here is a number about the test font, not about the layout.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
    double width = 360,
  }) async {
    // A 360dp handset — the floor, not the 411dp device it gets eyeballed on.
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Widget header() => const FleetHeader(
    kicker: '8 DARI 12 ONLINE',
    title: 'Fleet',
    trailing: SizedBox(width: 150, height: 32),
  );

  group('FleetHeader', () {
    testWidgets('sits the actions beside the title at normal type', (
      tester,
    ) async {
      await pump(tester, header());
      expect(tester.takeException(), isNull);

      final actions = tester.getRect(find.byType(SizedBox).last);
      final title = tester.getRect(find.text('Fleet'));
      // Side by side: the actions start to the right of where the title ends.
      expect(actions.left, greaterThan(title.right));
      // Bottoms aligned — the actions ride the title's line, not the kicker's.
      // This is the whole point of the rework; if the trailing widget creeps
      // back up into the kicker row, this is what catches it.
      expect(actions.bottom, closeTo(title.bottom, 2));
    });

    testWidgets('drops the actions below the title at 2.0 text scale', (
      tester,
    ) async {
      await pump(tester, header(), textScale: 2.0);
      // The failure this file exists for: the old Row threw here.
      expect(tester.takeException(), isNull);

      final actions = tester.getRect(find.byType(SizedBox).last);
      final title = tester.getRect(find.text('Fleet'));
      expect(actions.top, greaterThanOrEqualTo(title.bottom));
    });

    testWidgets('is the title block alone when there is nothing to trail', (
      tester,
    ) async {
      await pump(
        tester,
        const FleetHeader(kicker: 'FLEET', title: 'Fleet'),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Fleet'), findsOneWidget);
    });
  });

  group('FleetTile', () {
    Widget tile({
      bool big = true,
      String? meta,
      List<Widget> pills = const [],
    }) {
      // A name long enough to want more than two lines, which is the case the
      // `maxLines` cap exists for.
      return Builder(
        builder: (context) => FleetTile(
          icon: Icons.storefront_outlined,
          tint: context.sat.success,
          title: 'Warung Nasi Padang Sederhana Bahari Cabang Kelapa Gading',
          sub: 'Jl. Boulevard Raya Blok QJ1 No. 27, Kelapa Gading, Jakarta',
          meta: meta,
          pills: pills,
          big: big,
          trailing: const SizedBox(width: 40, height: 40),
          onTap: () {},
        ),
      );
    }

    testWidgets('a fully loaded tile fits 360dp at 2.0 text scale', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => tile(
            meta: 'Pro  ·  s/d 12 Agu  ·  Offline 3j',
            pills: [
              fleetPill(
                context.sat,
                'Lewat batas offline — akan terkunci saat restart',
                context.sat.urgent,
                context.sat.urgentSoft,
              ),
            ],
          ),
        ),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the compact variant fits too — it is the same widget', (
      tester,
    ) async {
      await pump(tester, tile(big: false), textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a runaway name is capped, not left to push the pills off', (
      tester,
    ) async {
      await pump(tester, tile());
      final title = tester.widget<Text>(
        find.textContaining('Warung Nasi Padang'),
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });
}
