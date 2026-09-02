import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/admin/discount_presets_screen.dart';

import '_tickers.dart';

final _cfg = ApiConfig(
  baseUri: Uri.parse('https://127.0.0.1:45678/'),
  trustedFingerprint: '',
);

class _PresetRepo extends DiscountPresetsRepository {
  _PresetRepo(Ref ref) : super(ref: ref) {
    state = const [
      DiscountPresetDto(
        id: 'bill-10',
        name: 'Meja 10%',
        scope: 'bill',
        value: 1000,
      ),
    ];
  }
}

void main() {
  testWidgets('Venue Settings offers bill scope and defaults to it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final ws = WsClient(config: _cfg, storage: SecureStorageService());
    addTearDown(ws.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...tickerOverrides,
          wsClientProvider.overrideWithValue(ws),
          discountPresetsRepositoryProvider.overrideWith(_PresetRepo.new),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: const DiscountPresetsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SELURUH TAGIHAN'), findsOneWidget);
    await tester.tap(find.text('Preset baru'));
    await tester.pumpAndSettle();

    final scopeControl = find.byWidgetPredicate(
      (widget) =>
          widget is SegmentedButton<String> &&
          widget.segments.any((segment) => segment.value == 'bill'),
    );
    final segmented = tester.widget<SegmentedButton<String>>(scopeControl);
    expect(segmented.segments.map((segment) => segment.value), [
      'bill',
      'order',
      'line',
    ]);
    expect(segmented.selected, {'bill'});
  });
}
