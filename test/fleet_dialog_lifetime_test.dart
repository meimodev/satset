import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/features/fleet/fleet_console_screen.dart';
import 'package:satset/ui/features/fleet/venue_edit_screen.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Both fleet forms used to keep their [TextEditingController]s at the *call
/// site* and dispose them in a `finally` once `showSatDialog` returned. That
/// future completes when the route is popped, not when it has finished
/// animating out, and the dialog's fields go on rebuilding through the
/// transition — so the `finally` handed a disposed controller to a live
/// `TextField`. On the tablet, cancelling the create-venue dialog logged "A
/// TextEditingController was used after being disposed" and then put a red
/// screen over the whole console.
///
/// The fix is that each form is now a widget that owns its controllers, so
/// their lifetime is the route's. These tests pump the real dialogs and open
/// and close them the way the crash did: the point is that they are widgets
/// with their own `dispose` at all, and that they still return their draft.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  /// Opens [dialog] the way the console does and records what it popped with.
  Future<List<Object?>> pumpDialog(WidgetTester tester, Widget dialog) async {
    final popped = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        // Pinned, exactly as the app pins it (ADR-0083). Without this the
        // test resolves against the host's locale and reads English.
        locale: const Locale('id'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: satTheme(SatTheme.neonTerang),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => popped.add(
                  await showSatDialog<Object?>(context, builder: (_) => dialog),
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
    return popped;
  }

  group('NewVenueDialog', () {
    testWidgets('cancelling after typing does not throw', (tester) async {
      final popped = await pumpDialog(tester, const NewVenueDialog());

      await tester.enterText(find.byType(TextField).first, 'Warung Uji');
      await tester.pump();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // The crash landed here: the controller was dead but the field was not.
      expect(tester.takeException(), isNull);
      expect(popped, [null]);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('saving pops the draft the console needs', (tester) async {
      final popped = await pumpDialog(tester, const NewVenueDialog());

      await tester.enterText(find.byType(TextField).first, 'Warung Uji');
      await tester.enterText(find.byType(TextField).at(1), 'Jl. Melati 3');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final draft = popped.single! as VenueDraft;
      expect(draft.name, 'Warung Uji');
      expect(draft.address, 'Jl. Melati 3');
      expect(draft.plan, isNotEmpty);
    });

    testWidgets('an empty name leaves Simpan dead', (tester) async {
      final popped = await pumpDialog(tester, const NewVenueDialog());

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Validation is inside the dialog, so a blank name must not close it —
      // the old version popped and created nothing, silently.
      expect(popped, isEmpty);
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('NewPrincipalDialog', () {
    testWidgets('cancelling after typing does not throw', (tester) async {
      final popped = await pumpDialog(
        tester,
        const NewPrincipalDialog(roleLabel: 'admin', venueName: 'Warung Uji'),
      );

      await tester.enterText(find.byType(TextField).first, 'Sari');
      await tester.pump();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(popped, [null]);
    });

    testWidgets('a short password leaves Simpan dead', (tester) async {
      final popped = await pumpDialog(
        tester,
        const NewPrincipalDialog(roleLabel: 'admin', venueName: 'Warung Uji'),
      );

      await tester.enterText(find.byType(TextField).first, 'Sari');
      await tester.enterText(find.byType(TextField).at(1), 'sari@warung.id');
      await tester.enterText(find.byType(TextField).at(2), 'abc');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(popped, isEmpty);
      expect(find.text('Minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('saving pops the draft createAdmin needs', (tester) async {
      final popped = await pumpDialog(
        tester,
        const NewPrincipalDialog(roleLabel: 'admin', venueName: 'Warung Uji'),
      );

      await tester.enterText(find.byType(TextField).first, 'Sari');
      await tester.enterText(find.byType(TextField).at(1), 'sari@warung.id');
      await tester.enterText(find.byType(TextField).at(2), 'rahasia123');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final draft = popped.single! as PrincipalDraft;
      expect(draft.name, 'Sari');
      expect(draft.email, 'sari@warung.id');
      expect(draft.password, 'rahasia123');
    });
  });
}
