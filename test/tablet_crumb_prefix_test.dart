import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';

import '_tickers.dart';

/// The venue name leads every trail, and `SatAppBar` is the one place it is
/// prepended (ADR-0058) — call sites pass venue-less trails. Two branches worth
/// pinning: the prefix lands, and an unnamed venue drops the segment rather than
/// printing a placeholder that would read as the Venue *hub*.
class _StubVenue extends VenueSettingsRepository {
  _StubVenue({required super.ref, required String name}) {
    state = VenueSettingsDto(displayName: name);
  }
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  Future<String> crumbLine(WidgetTester tester, String venueName) async {
    // Tablet: 800dp shortest side, the branch that renders crumbs at all.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...tickerOverrides,
          wsConnStateProvider.overrideWithValue(WsConnState.open),
          venueSettingsProvider.overrideWith(
            (ref) => _StubVenue(ref: ref, name: venueName),
          ),
        ],
        child: MaterialApp(
          theme: satTheme(SatTheme.neonTerang),
          home: const Scaffold(
            body: SatAppBar(crumbs: ['Meja 5', 'Teras'], showAvatar: false),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();

    final rich = tester.widget<Text>(
      find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
    );
    return rich.textSpan!.toPlainText();
  }

  testWidgets('the venue name leads the trail', (tester) async {
    expect(
      await crumbLine(tester, 'Warung Sebelah'),
      'Warung Sebelah  ›  Meja 5  ›  Teras',
    );
  });

  testWidgets('an unnamed venue drops the segment, never a placeholder', (
    tester,
  ) async {
    expect(await crumbLine(tester, ''), 'Meja 5  ›  Teras');
  });
}
