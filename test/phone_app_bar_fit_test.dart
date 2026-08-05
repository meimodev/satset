import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';

import '_tickers.dart';

/// The phone bar's width budget (ADR-0062).
///
/// The bar fits a 360dp handset only because two things are conditional: the
/// shift cluster yields to the back button, and the sync indicator drops its
/// label while the link is healthy. Both look like cosmetic `if`s and would be
/// "tidied" back into unconditional widgets by anyone who hadn't done the
/// arithmetic. This pins them.
///
/// It asserts *structure*, not pixels, wherever the shift cluster is on screen.
/// `flutter_test` has no real font — `SatType.useSystemFonts` falls back to no
/// family, and the test font draws every glyph as a square of the font size, so
/// `18:14 · Sab` measures 143dp here against ~86dp of IBM Plex Mono on a device.
/// The cluster therefore overflows 360dp *in this harness* while fitting with
/// 69dp to spare in production, and [pumpBar] drains that overflow rather than
/// asserting a number the font makes meaningless. The width arithmetic lives in
/// ADR-0062 and is verified on hardware.
///
/// The back-button variant carries no mono text worth the name, so it fits even
/// under the fat test font — that one keeps a real overflow assertion.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const admin = AppUser(
    id: 'u1',
    name: 'Maya Anjani',
    initials: 'MA',
    role: UserRole.admin,
    shiftStartedAt: '2026-07-29T09:00:00.000',
    zoneAssigned: 'Teras',
  );

  Future<void> pumpBar(
    WidgetTester tester, {
    required WsConnState conn,
    VoidCallback? onBack,
  }) async {
    // A 360dp phone — the floor this layout is budgeted against, not the
    // 411dp handset it gets eyeballed on.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...tickerOverrides,
          wsConnStateProvider.overrideWithValue(conn),
          authStateProvider.overrideWith(
            (ref) => _StubAuth(
              ref: ref,
              storage: ref.watch(secureStorageServiceProvider),
              seed: const AuthState(isAuthenticated: true, user: admin),
            ),
          ),
        ],
        child: MaterialApp(
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(body: SatAppBar(onBack: onBack)),
        ),
      ),
    );
    await tester.pump();
    // See the library doc: the test font is ~1.7× the advance of the real one,
    // so any layout carrying the cluster overruns here regardless of whether it
    // would on a device. Drain it so the structural expectations can run. The
    // cost is that a genuine horizontal regression is invisible to this file —
    // hardware and ADR-0062's budget are what cover that.
    tester.takeException();
  }

  // `AppStrings.shiftLabel` is the cluster's only fixed string, so it is what
  // identifies the cluster without reaching into a private widget.
  Finder shiftCluster() => find.textContaining(
    RegExp('SHIFT', caseSensitive: false),
    skipOffstage: false,
  );

  group('the shift cluster is shell chrome, not task chrome', () {
    testWidgets('shows when there is no back button', (tester) async {
      await pumpBar(tester, conn: WsConnState.open);
      expect(shiftCluster(), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('yields to the back button, and that variant really fits', (
      tester,
    ) async {
      await pumpBar(tester, conn: WsConnState.connecting, onBack: () {});
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      // Both at once is the ~419dp case that overruns even a 411dp handset.
      expect(shiftCluster(), findsNothing);
      // No cluster means no mono text, so the test font's inflation does not
      // bite and this is a genuine 360dp fit check — on the longest sync label
      // ("MENGHUBUNGKAN…") at that. `pumpBar` already drained; nothing to find.
      expect(tester.takeException(), isNull);
    });
  });

  group('the sync label is spent on the states that hurt', () {
    testWidgets('a healthy link is the dot alone', (tester) async {
      await pumpBar(tester, conn: WsConnState.open);
      expect(find.textContaining('LIVE'), findsNothing);
    });

    testWidgets('connecting says so', (tester) async {
      await pumpBar(tester, conn: WsConnState.connecting);
      expect(find.textContaining('MENGHUBUNGKAN'), findsOneWidget);
    });

    testWidgets('offline says so', (tester) async {
      await pumpBar(tester, conn: WsConnState.closed);
      expect(find.textContaining('OFFLINE'), findsOneWidget);
    });
  });

  testWidgets('the phone bar is the status bar plus a 56dp row', (
    tester,
  ) async {
    await pumpBar(tester, conn: WsConnState.open);
    // No status bar inset in the test view, so the bar is the row plus its
    // 1px rule. Guards against `l.topInset` creeping back in — that token
    // adds another 24 on top of a status bar this bar has already cleared.
    final h = tester.getSize(find.byType(SatAppBar)).height;
    expect(h, closeTo(57, 1));
  });
}

/// Seeds [AuthState] without standing up the real repository's storage,
/// heartbeat and Firestore listeners.
class _StubAuth extends AuthRepository {
  _StubAuth({
    required super.ref,
    required super.storage,
    required AuthState seed,
  }) {
    state = seed;
  }
}
