import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/visit_expense_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';
import 'package:satset/ui/features/cashier/visit_expense_panel.dart';

class _Venue extends VenueSettingsRepository {
  _Venue({required super.ref, required bool enabled}) {
    state = VenueSettingsDto(
      tableExpenseEnabled: enabled,
      modules: [modeTableExpense],
    );
  }
}

class _Auth extends AuthRepository {
  _Auth({required super.ref, required super.storage, required bool canRecord}) {
    state = AuthState(
      isAuthenticated: true,
      capabilities: {if (canRecord) Capability.recordTableExpense},
    );
  }
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  Future<void> pumpPanel(
    WidgetTester tester, {
    FutureOr<VisitExpenseSummaryDto> Function()? load,
    bool canRecord = false,
    bool enabled = true,
    bool billOpen = true,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          venueSettingsProvider.overrideWith(
            (ref) => _Venue(ref: ref, enabled: enabled),
          ),
          authStateProvider.overrideWith(
            (ref) => _Auth(
              ref: ref,
              storage: ref.read(secureStorageServiceProvider),
              canRecord: canRecord,
            ),
          ),
          visitExpensesProvider('visit').overrideWith(
            (ref) => load?.call() ?? const VisitExpenseSummaryDto(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: VisitExpensePanel(
              visitId: 'visit',
              tableId: 'table',
              billOpen: billOpen,
              showEmpty: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final width in [390.0, 1000.0]) {
    testWidgets('viewer sees expense entries at width $width', (tester) async {
      await pumpPanel(
        tester,
        width: width,
        load: () => const VisitExpenseSummaryDto(
          total: 12000,
          expenses: [
            VisitExpenseDto(
              id: 'e1',
              amount: 12000,
              categoryName: 'Tissues',
              note: 'For guests',
            ),
          ],
        ),
      );
      expect(find.text('Table expense'), findsOneWidget);
      expect(find.text('Tissues · For guests'), findsOneWidget);
      expect(find.text('Record expense'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty state is visible without recording permission', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Record expense'), findsNothing);
  });

  testWidgets('record action requires permission and an open bill', (
    tester,
  ) async {
    await pumpPanel(tester, canRecord: true);
    expect(find.text('Record expense'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpPanel(tester, canRecord: true, billOpen: false);
    expect(find.text('Record expense'), findsNothing);
  });

  testWidgets('disabled feature is hidden', (tester) async {
    await pumpPanel(tester, enabled: false);
    expect(find.text('Table expense'), findsNothing);
  });

  testWidgets('loading and failure never claim no expenses', (tester) async {
    final result = Completer<VisitExpenseSummaryDto>();
    await pumpPanel(tester, load: () => result.future);
    expect(find.byType(SatSpinner), findsOneWidget);
    expect(find.text('No expenses yet'), findsNothing);
    result.completeError(const NoCachedBill());
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No expenses yet'), findsNothing);
  });
}
