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
import 'package:satset/l10n/app_localizations.dart';

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
/// Every widget is rendered under **one theme per skin**: `neonTerang` for
/// `glow`, `amberGelap` for `lembut`. Shape is a skin property (ADR-0047,
/// ADR-0050) — radii, borders, shadows and the type ramp all differ — so a
/// second theme on the same skin re-locks pixels the first one already holds,
/// while a skin with no coverage regresses silently. `neonTerang` leads
/// because it is the shipped default (ADR-0057). `brutal` is uncovered.
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

  for (final theme in [SatTheme.neonTerang, SatTheme.amberGelap]) {
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
                // Pinned, exactly as the app pins it (ADR-0083). Without this the
                // test resolves against the host's locale and reads English.
                locale: const Locale('id'),
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
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
