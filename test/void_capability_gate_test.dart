import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/void_flow/line_item_action_sheet.dart';

/// The void row is pre-gated on capability, not on the server's 403.
///
/// A waiter holds `voidItem` but not `compItem`, so the same row is live on a
/// line the kitchen still owns and dead on one already in front of the guest —
/// and dead with the *reason* on it, because a row that is simply missing
/// teaches nobody why. The gate reads `capabilityForTransition` (ADR-0101), so
/// the transition table stays the one place that says what a move costs.
final l10n = lookupAppL10n(const Locale('id'));

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const waiter = AppUser(
    id: 'u-waiter',
    name: 'Rangga',
    initials: 'RA',
    role: UserRole.waiter,
    shiftStartedAt: '2026-08-28T09:00:00.000',
    zoneAssigned: 'Dalam',
  );

  Ticket lineIn(TicketStatus status) => Ticket(
    id: 't1',
    tableId: 'tbl-1',
    itemId: 'i1',
    name: 'Bali Hai',
    course: CourseId.drinksNow,
    price: 40000,
    status: status,
    sentAt: '19:46',
    sentAtTime: DateTime(2026, 8, 28, 19, 46),
  );

  /// Opens the sheet over a line in [status] for a role holding
  /// [capabilities], and settles on the action list.
  Future<void> openSheet(
    WidgetTester tester, {
    required TicketStatus status,
    required Set<Capability> capabilities,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ticket = lineIn(status);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketsForTableProvider('tbl-1').overrideWithValue([ticket]),
          authStateProvider.overrideWith(
            (ref) => _StubAuth(
              ref: ref,
              storage: ref.watch(secureStorageServiceProvider),
              seed: AuthState(
                isAuthenticated: true,
                user: waiter,
                capabilities: capabilities,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          // Pinned the way the app pins it (ADR-0083) — otherwise this reads
          // the host locale and asserts against English copy.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLineItemActionSheet(
                    context: context,
                    tableId: 'tbl-1',
                    ticket: ticket,
                    displayName: 'D1',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a waiter may void a line the kitchen still owns', (
    tester,
  ) async {
    await openSheet(
      tester,
      status: TicketStatus.sent,
      capabilities: {Capability.takeOrder, Capability.voidItem},
    );

    expect(find.text(l10n.liaVoidDesc), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('a served line tells the waiter it needs a manager', (
    tester,
  ) async {
    await openSheet(
      tester,
      status: TicketStatus.served,
      // A waiter, per seed_data.dart: voidItem, never compItem.
      capabilities: {Capability.takeOrder, Capability.voidItem},
    );

    // The refusal is on the row, not behind a tap that would have 403'd.
    expect(find.text(l10n.liaVoidNeedsManager), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // Tapping a dead row must not walk on to the reason list.
    await tester.tap(find.text(l10n.liaVoidNeedsManager));
    await tester.pumpAndSettle();
    expect(find.text(l10n.liaVoidNeedsManager), findsOneWidget);
  });

  testWidgets('a role without voidItem is told that, not "ask a manager"', (
    tester,
  ) async {
    await openSheet(
      tester,
      status: TicketStatus.sent,
      capabilities: {Capability.takeOrder},
    );

    expect(find.text(l10n.liaVoidNoCap), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('a manager sees the served line live', (tester) async {
    await openSheet(
      tester,
      status: TicketStatus.served,
      capabilities: {
        Capability.takeOrder,
        Capability.voidItem,
        Capability.compItem,
      },
    );

    expect(find.text(l10n.liaVoidDesc), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}

class _StubAuth extends AuthRepository {
  _StubAuth({
    required super.ref,
    required super.storage,
    required AuthState seed,
  }) {
    state = seed;
  }
}
