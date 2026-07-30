import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';

/// ADR-0043 reaches the waiter's board too: a line escalates at *its own*
/// resolved target, not at one number shared by every dish. The pill takes both
/// the anchor and the target from the caller, so the two things worth pinning
/// are that it honours the target it is handed and that it measures from the
/// kitchen clock start it is handed (a held course must not arrive red).
void main() {
  Future<void> pumpPill(
    WidgetTester tester, {
    required Duration age,
    required int targetMins,
    bool terminal = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        // The live 30s heartbeat would outlive the widget tree and trip the
        // pending-timer check; the pill reads the clock on build regardless.
        overrides: [
          elapsedTickerProvider.overrideWith(
            (ref) => const Stream<DateTime>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: ElapsedPill(
              clockStart: SatClock.now().subtract(age),
              sentAtClock: '19:04',
              terminal: terminal,
              targetMins: targetMins,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The pill swaps its icon on overdue — the one signal readable without
  /// resolving a colour against the palette.
  bool isOverdue(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon)).icon == Icons.timer_outlined;

  testWidgets('a fast item is overdue before the venue default would be', (
    tester,
  ) async {
    await pumpPill(tester, age: const Duration(minutes: 6), targetMins: 5);
    expect(isOverdue(tester), isTrue);
    expect(find.text('6m'), findsOneWidget);
  });

  testWidgets('the same age is calm on a slower item', (tester) async {
    await pumpPill(tester, age: const Duration(minutes: 6), targetMins: 15);
    expect(isOverdue(tester), isFalse);
  });

  testWidgets('escalates exactly at the target, not a minute before', (
    tester,
  ) async {
    await pumpPill(tester, age: const Duration(minutes: 14), targetMins: 15);
    expect(isOverdue(tester), isFalse);

    await pumpPill(tester, age: const Duration(minutes: 15), targetMins: 15);
    expect(isOverdue(tester), isTrue);
  });

  testWidgets('a course fired 20m after the order counts from the fire', (
    tester,
  ) async {
    // The bug this replaced: anchored to sentAtTime, this line rendered red
    // the moment it reached the board, having been ordered 20 minutes before
    // the kitchen was given it.
    await pumpPill(tester, age: const Duration(minutes: 2), targetMins: 15);
    expect(isOverdue(tester), isFalse);
    expect(find.text('2m'), findsOneWidget);
  });

  testWidgets('a terminal line freezes to its clock and never escalates', (
    tester,
  ) async {
    await pumpPill(
      tester,
      age: const Duration(minutes: 90),
      targetMins: 15,
      terminal: true,
    );
    expect(isOverdue(tester), isFalse);
    expect(find.text('19:04'), findsOneWidget);
  });
}
