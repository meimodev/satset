import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/tables/tables_screen.dart';

import '_tickers.dart';

/// The zone strip's escalation badge told a waiter which tier a zone was in by
/// **fill colour alone** — red for crit, amber for warn. At 20px, across a dim
/// room, on a strip that is already moving, that is not a distinction anyone
/// makes in the half-second they give it, and to a red-green colourblind
/// reader it is not a distinction at all. Design principle 3: never inferable
/// only from subtle colour.
///
/// So what is pinned is that the tier survives losing the colour — a glyph a
/// sighted reader can tell apart by shape, and a sentence a screen reader gets
/// instead of a bare number.
void main() {
  Future<void> pump(WidgetTester tester, {int crit = 0, int warn = 0}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: tickerOverrides,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(body: ZoneAlarmBadge(crit: crit, warn: warn)),
        ),
      ),
    );
    await tester.pump();
  }

  IconData glyph(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon)).icon!;

  testWidgets('the two tiers are different shapes, not just different reds', (
    tester,
  ) async {
    await pump(tester, crit: 2);
    final critGlyph = glyph(tester);

    await pump(tester, warn: 2);
    final warnGlyph = glyph(tester);

    expect(
      critGlyph,
      isNot(warnGlyph),
      reason: 'the tier has to be readable without resolving a hue',
    );
  });

  testWidgets('crit outranks warn, and the badge counts the tier it shows', (
    tester,
  ) async {
    // Both tiers present. The badge is one number, and it must be the one
    // that names the thing to go do.
    await pump(tester, crit: 2, warn: 5);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('a screen reader gets the sentence, not the digit', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pump(tester, crit: 3);
    expect(
      find.bySemanticsLabel('3 meja kritis'),
      findsOneWidget,
      reason: 'a bare "3" says nothing about which tier or what it counts',
    );

    await pump(tester, warn: 4);
    expect(find.bySemanticsLabel('4 meja perlu perhatian'), findsOneWidget);

    handle.dispose();
  });
}
