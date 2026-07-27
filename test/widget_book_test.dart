import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/features/_book/book_entries.dart';

/// The widget book only earns its place if every state it advertises actually
/// builds. Pumping them here catches a stub that drifted from a constructor
/// long before someone opens `/book` on a device and finds a red screen.
void main() {
  final entries = bookEntries();

  testWidgets('the book has entries and none is silently empty', (
    tester,
  ) async {
    expect(entries, isNotEmpty);
    // AlertHost is deliberately note-only (ADR-0049). Everything else must
    // render something.
    final empty = entries
        .where((e) => e.states.isEmpty)
        .map((e) => e.name)
        .toList();
    expect(empty, ['AlertHost']);
  });

  for (final entry in entries) {
    for (final state in entry.states) {
      testWidgets('${entry.name} — ${state.label}', (tester) async {
        // Tablet-sized so the rail and shell entries have room; the narrow
        // states are covered by the app's own screens.
        tester.view.physicalSize = const Size(2400, 1600);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // ElapsedPill ticks every 30s off a periodic stream. Harmless on
              // a device, a pending-timer failure in a widget test.
              elapsedTickerProvider.overrideWith(
                (ref) => const Stream<DateTime>.empty(),
              ),
            ],
            child: MaterialApp(
              theme: satTheme(SatTheme.amberGelap),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(builder: (c, r, _) => state.build(c, r)),
                ),
              ),
            ),
          ),
        );
        // Long enough to drain Reveal's 55ms stagger timers. Not
        // pumpAndSettle: Shimmer repeats forever, so settling never returns.
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
