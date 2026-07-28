@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/_book/book_entries.dart';

/// Pixel lock on the shared control vocabulary (ADR-0055).
///
/// `widget_book_test.dart` proves every state still *builds*; this proves it
/// still *looks* the same. The two are separate on purpose — a constructor
/// change should fail loudly everywhere, a pixel change only here.
///
/// Scope is the Controls group and nothing else. Goldens over whole screens
/// churn on every copy edit and get regenerated without being read, which is
/// how a golden suite stops meaning anything.
///
/// Every widget is rendered in **both** themes: "both themes, both real" is a
/// design principle, and a regression that only shows on the light palette is
/// exactly the one nobody catches by hand.
///
/// Tagged `golden` and excluded from the default run — goldens are
/// font-renderer specific, so they are a local and single-CI-image check, not
/// something to fail a contributor's machine. Run explicitly:
///
///     flutter test --tags golden --run-skipped
///     flutter test --tags golden --run-skipped --update-goldens
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  final controls = bookEntries().where((e) => e.group == 'Controls').toList();

  test('the Controls group is not empty', () {
    expect(controls, isNotEmpty);
  });

  for (final theme in [SatTheme.amberGelap, SatTheme.amberTerang]) {
    for (final entry in controls) {
      for (var i = 0; i < entry.states.length; i++) {
        final state = entry.states[i];
        testWidgets('${entry.name} [$i] — ${theme.name}', (tester) async {
          tester.view.physicalSize = const Size(1200, 2000);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: satTheme(theme),
                home: Builder(
                  builder: (context) => Scaffold(
                    backgroundColor: context.sat.bg0,
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Sp.s5),
                        child: Consumer(
                          builder: (c, r, _) => state.build(c, r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          // Drains Reveal's stagger and every AnimatedContainer; not
          // pumpAndSettle, which never returns while a Shimmer repeats.
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/${_slug(entry.name)}_${i}_${theme.name}.png',
            ),
          );
        });
      }
    }
  }
}

String _slug(String name) =>
    name.replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) {
      return '${m[1]}_${m[2]}';
    }).toLowerCase();
