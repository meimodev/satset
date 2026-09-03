// **Cari pelanggan** at the till, with the keyboard up — which is the only
// state this sheet is ever in, since the search field autofocuses.
//
// The sheet already takes `viewInsets.bottom`, so the bug was never the
// keyboard inset: the results list asked for a fixed 280 and the Daftar button
// asked for its own height, and on the half screen a raised keyboard leaves,
// the column could not pay both. What overflowed off the bottom was the enrol
// button — the one thing the sheet offers a cashier whose guest is not in the
// list yet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/cashier/member_panel.dart';

final _config = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:8443'),
  trustedFingerprint: '',
);

/// Enough of the directory to fill the list past its ceiling.
class _FakeApi extends ApiClient {
  _FakeApi() : super(config: _config, storage: SecureStorageService());

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async => [
    for (var i = 0; i < 20; i++)
      {'id': 'm$i', 'name': 'Pelanggan $i', 'phone': '08120000${i + 1000}'},
  ];
}

void main() {
  /// A phone with the soft keyboard up: roughly half the screen left, which is
  /// what `viewInsets` reports to the sheet.
  Future<void> pump(
    WidgetTester tester, {
    WsConnState conn = WsConnState.open,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 1100);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWith((_) => _FakeApi()),
          wsClientProvider.overrideWith(
            (_) => WsClient(config: _config, storage: SecureStorageService()),
          ),
          // The directory is read from the host, so the sheet asks whether it
          // has one before it renders a list (ADR-0128). A till has.
          wsConnStateProvider.overrideWith((_) => conn),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: const Scaffold(
            // The sheet as `showSatSheet` gives it: pinned to the bottom, sized
            // to its own content.
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MemberLookupSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the enrol button survives a raised keyboard', (tester) async {
    await pump(tester);

    // A full directory behind the search — the case that used to push the
    // button off the bottom.
    expect(find.text('Pelanggan 0 · 081200001000'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final l10n = await AppL10n.delegate.load(const Locale('id'));
    final enrol = find.text(l10n.cshMemberEnrol);
    expect(enrol, findsOneWidget);

    // Not merely built — inside the visible area above the keyboard.
    final box = tester.getRect(enrol);
    final safeBottom =
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
        tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    expect(box.bottom, lessThanOrEqualTo(safeBottom));
  });

  testWidgets('offline, the sheet says so instead of showing nobody', (
    tester,
  ) async {
    await pump(tester, conn: WsConnState.closed);

    final l10n = await AppL10n.delegate.load(const Locale('id'));
    expect(find.text(l10n.memLookupOfflineTitle), findsOneWidget);
    expect(
      find.text('Pelanggan 0 · 081200001000'),
      findsNothing,
      reason: 'a directory read needs the host; a stale list is a lie',
    );
    expect(
      find.text(l10n.cshMemberEnrol),
      findsNothing,
      reason: 'enrolling is a write, and it has nowhere to land',
    );
    expect(tester.takeException(), isNull);
  });
}
