// After an order is sent, Review/Sent `go` to `/table/:id`, which leaves the
// table page alone on the stack and outside the shell's ExitGuard. A single
// system back there used to close the app mid-shift.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/widgets/exit_guard.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';

void main() {
  late GoRouter router;
  late int exits;

  Future<void> boot(WidgetTester tester) async {
    exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    // The shape of app_router.dart: a shell guarded by ExitGuard, and the
    // table flow outside it.
    router = GoRouter(
      initialLocation: '/tables',
      routes: [
        ShellRoute(
          builder: (_, _, child) => ExitGuard(child: Scaffold(body: child)),
          routes: [
            GoRoute(path: '/tables', builder: (_, _) => const Text('tables')),
          ],
        ),
        GoRoute(
          path: '/table/:id',
          builder: (_, _) =>
              const SafePopScope(child: Scaffold(body: Text('detail'))),
          routes: [
            GoRoute(path: 'sent', builder: (_, _) => const Text('sent')),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('back on a table left alone by go lands on tables', (
    tester,
  ) async {
    await boot(tester);
    router.push('/table/1');
    await tester.pumpAndSettle();
    router.go('/table/1/sent'); // review_screen.dart, after send
    await tester.pumpAndSettle();
    router.pop(); // sent_screen.dart auto-return
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(find.text('tables'), findsOneWidget);
  });

  testWidgets('back on a pushed table still pops to tables', (tester) async {
    await boot(tester);
    router.push('/table/1');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(find.text('tables'), findsOneWidget);
  });
}
