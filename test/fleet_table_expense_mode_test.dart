import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/features/fleet/venue_edit_screen.dart';

/// Regression coverage for ADR-0130's Fleet half of the visit-expense gate.
/// The mode key already travelled through the callable and mirror, but the
/// venue editor once rendered no switch for it, making the feature impossible
/// to activate end-to-end without editing Firestore by hand.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  Venue venue({required bool tableExpense}) => Venue(
    id: 'venue-1',
    status: AdminStatus.active,
    name: 'Warung Uji',
    address: '',
    plan: venuePlanTrial,
    trialStartAt: DateTime(2026),
    paidUntil: DateTime(2026, 12, 31),
    priceMonthly: null,
    billingCycle: venueCycleMonthly,
    addOns: {if (tableExpense) modeTableExpense},
    lastSeenAt: DateTime(2026),
    fromCache: false,
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required bool tableExpense,
  }) async {
    final v = venue(tableExpense: tableExpense);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fleetVenuesProvider.overrideWith((_) => Stream.value([v])),
          fleetAdminsProvider.overrideWith(
            (_) => Stream.value(const <AdminProfile>[]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: VenueEditScreen(venue: v),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Pengeluaran meja'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  SatToggle expenseToggle(WidgetTester tester) => tester.widget<SatToggle>(
    find.byWidgetPredicate(
      (w) => w is SatToggle && w.semanticLabel == 'Pengeluaran meja',
    ),
  );

  testWidgets('can stage table-expense mode on from Fleet', (tester) async {
    await pumpEditor(tester, tableExpense: false);

    expect(expenseToggle(tester).value, isFalse);
    await tester.tap(find.bySemanticsLabel('Pengeluaran meja'));
    await tester.pumpAndSettle();

    expect(expenseToggle(tester).value, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('confirms before staging table-expense mode off', (tester) async {
    await pumpEditor(tester, tableExpense: true);

    expect(expenseToggle(tester).value, isTrue);
    await tester.tap(find.bySemanticsLabel('Pengeluaran meja'));
    await tester.pumpAndSettle();

    expect(
      find.text('Matikan pengeluaran meja untuk Warung Uji?'),
      findsOneWidget,
    );
    expect(expenseToggle(tester).value, isTrue);

    await tester.tap(find.text('Matikan'));
    await tester.pumpAndSettle();

    expect(expenseToggle(tester).value, isFalse);
  });
}
