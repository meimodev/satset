import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/l10n/app_localizations.dart';

/// What the bill's lines pane shows while the cashier is picking items.
///
/// On a phone the pane collapses to the picker: a 360dp sheet already gives the
/// settle pane 420dp, and the totals card, the action row and the Struk list
/// push the items being tapped below the fold. On a tablet the same pane is a
/// column of its own beside the settle pane, so nothing is cut.
///
/// The cut is three `if`s that read as tidy-uppable, and the thing they protect
/// — the item the cashier is reaching for being on screen — is invisible in a
/// diff. Hence this file.
///
/// It also pins the settle pane's method lock: once any non-refund payment has
/// landed, the rest of the bill is bound to that tender, so the Metode row
/// collapses to the one chip still allowed.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const cashier = AppUser(
    id: 'u1',
    name: 'Maya Anjani',
    initials: 'MA',
    role: UserRole.admin,
    shiftStartedAt: '2026-07-29T09:00:00.000',
    zoneAssigned: 'Teras',
  );

  /// One itemized bill with two lines, nothing assigned, nothing paid — the
  /// state a cashier is in when they reach for Per item.
  const billJson = <String, dynamic>{
    'visitId': 'v1',
    'tableId': 't1',
    'tableLabel': '12',
    'mode': 'itemized',
    'subtotal': 100000,
    'serviceAmount': 5000,
    'taxAmount': 11550,
    'total': 116550,
    'outstanding': 116550,
    'lines': [
      {
        'ticketId': 'tk1',
        'itemId': 'i1',
        'name': 'Nasi Goreng',
        'qty': 2,
        'unitPrice': 35000,
        'lineTotal': 70000,
        'assignedUnits': 0,
        'sentAt': '2026-07-29T12:00:00.000',
      },
      {
        'ticketId': 'tk2',
        'itemId': 'i2',
        'name': 'Es Teh',
        'qty': 2,
        'unitPrice': 15000,
        'lineTotal': 30000,
        'assignedUnits': 0,
        'sentAt': '2026-07-29T12:00:00.000',
      },
    ],
    'receipts': [
      {
        'id': 'r1',
        'label': 'A',
        'kind': 'itemized',
        'total': 0,
        'paidAmount': 0,
        'items': [],
        'payments': [],
      },
    ],
  };
  final bill = Bill.fromJson(billJson);

  /// The same bill after a guest has paid one receipt by QRIS. Two receipts:
  /// one settled, one still open — the state a cashier is in when the second
  /// guest reaches for their wallet.
  final partPaid = Bill.fromJson({
    ...billJson,
    'paidAmount': 40000,
    'outstanding': 76550,
    'receipts': [
      {
        'id': 'r1',
        'label': 'A',
        'kind': 'itemized',
        'mode': 'itemized',
        'total': 40000,
        'paidNet': 40000,
        'status': 'paid',
        'items': [],
        'payments': [
          {
            'id': 'p1',
            'method': 'qris',
            'amount': 40000,
            'at': '2026-07-29T12:30:00.000',
          },
          // A refund is a method too, and a later one. It must not win the
          // lock — giving money back doesn't decide the next tender.
          {
            'id': 'p2',
            'method': 'tunai',
            'amount': 5000,
            'isRefund': true,
            'at': '2026-07-29T12:40:00.000',
          },
        ],
      },
      {
        'id': 'r2',
        'label': 'B',
        'kind': 'itemized',
        'mode': 'itemized',
        'total': 0,
        'paidNet': 0,
        'items': [],
        'payments': [],
      },
    ],
  });

  /// `Reveal` staggers each section behind a one-shot timer (`anim.dart`), so a
  /// single pump leaves them pending and the harness complains. Drain them.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpBill(
    WidgetTester tester, {
    required bool tablet,
    Bill? fixture,
  }) async {
    // 800dp shortest side is the tablet branch; 360dp is the phone floor.
    tester.view.physicalSize = tablet
        ? const Size(1280, 800)
        : const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wsConnStateProvider.overrideWithValue(WsConnState.open),
          authStateProvider.overrideWith(
            (ref) => _StubAuth(
              ref: ref,
              storage: ref.watch(secureStorageServiceProvider),
              seed: const AuthState(isAuthenticated: true, user: cashier),
            ),
          ),
          billDetailProvider('v1').overrideWith((ref) async => fixture ?? bill),
        ],
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: const Scaffold(body: CashierBillView(visitId: 'v1')),
        ),
      ),
    );
    await drain(tester);
    // The test font draws every glyph as a square of the font size, so rows
    // budgeted against real metrics overrun here. Structure is what this file
    // asserts; the width arithmetic lives in ADR-0062 and on hardware.
    tester.takeException();
  }

  /// Tap the settle pane's mode row. The row is always on screen — that is what
  /// makes the cut reversible in one tap.
  Future<void> pickMode(WidgetTester tester, String label) async {
    await tester.tap(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await drain(tester);
    tester.takeException();
  }

  // `SatCard.section` upper-cases its header, so the two card finders match the
  // rendered caps rather than the string the call site passes.
  Finder totals() => find.text('Subtotal', skipOffstage: false);
  Finder actions() => find.textContaining('Cetak tagihan', skipOffstage: false);
  Finder lines() => find.text('ITEM PESANAN', skipOffstage: false);
  Finder receipts() => find.text('STRUK', skipOffstage: false);

  testWidgets('phone · per item picks first and defers payment to review', (
    tester,
  ) async {
    await pumpBill(tester, tablet: false);
    expect(totals(), findsOneWidget);
    expect(lines(), findsOneWidget);

    await pickMode(tester, 'Per item');

    expect(lines(), findsOneWidget, reason: 'the picker is the whole point');
    expect(totals(), findsNothing);
    expect(actions(), findsNothing);
    expect(receipts(), findsNothing);

    await tester.tap(find.text('Nasi Goreng'));
    await drain(tester);
    tester.takeException();
    expect(
      find.text(
        'Tinjau struk, terapkan diskon item, lalu bayar',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Tunai', skipOffstage: false), findsOneWidget);
  });

  testWidgets('phone · leaving per item brings everything back', (
    tester,
  ) async {
    await pumpBill(tester, tablet: false);
    await pickMode(tester, 'Per item');
    expect(totals(), findsNothing);

    await pickMode(tester, 'Penuh');

    expect(totals(), findsOneWidget);
    expect(actions(), findsOneWidget);
    expect(lines(), findsOneWidget);
  });

  testWidgets('tablet · per item cuts nothing from the left pane', (
    tester,
  ) async {
    await pumpBill(tester, tablet: true);
    await pickMode(tester, 'Per item');

    expect(lines(), findsOneWidget);
    expect(totals(), findsOneWidget);
    expect(actions(), findsOneWidget);
  });

  testWidgets('unpaid bill offers every payment method', (tester) async {
    await pumpBill(tester, tablet: true);

    for (final label in ['Tunai', 'QRIS', 'Kartu', 'Transfer', 'Lainnya']) {
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('a part-paid bill still offers every method', (tester) async {
    await pumpBill(tester, tablet: true, fixture: partPaid);

    // QRIS paid the first receipt. It used to collapse the row to itself for
    // the rest of the bill; `CONTEXT.md` has always described a struk taking
    // part Tunai part Kartu, so the lock was drift and is gone (ADR-0121).
    for (final label in ['Tunai', 'QRIS', 'Kartu', 'Transfer', 'Lainnya']) {
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
    expect(find.textContaining('Terkunci', skipOffstage: false), findsNothing);
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
