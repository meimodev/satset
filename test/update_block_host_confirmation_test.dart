import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/services/app_update_service.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/update_block.dart';

class _RecordingUpdateService extends AppUpdateService {
  _RecordingUpdateService(super.ref);

  int calls = 0;

  @override
  Future<void> downloadAndInstall() async {
    calls++;
  }
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  testWidgets('host can reach confirmation from the mandatory update screen', (
    tester,
  ) async {
    late _RecordingUpdateService installer;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isHostDeviceProvider.overrideWithValue(true),
          releaseGateProvider.overrideWith(
            (ref) => ReleaseGateRepository(
              ref: ref,
              seed: const ReleaseGate(min: '9.9.9'),
              listen: false,
            ),
          ),
          updateVerdictProvider.overrideWithValue(UpdateVerdict.blocked),
          appUpdateServiceProvider.overrideWith(
            (ref) => installer = _RecordingUpdateService(ref),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          builder: (context, child) => UpdateBlock(child: child!),
          home: const Scaffold(body: Text('Behind the block')),
        ),
      ),
    );

    await tester.tap(find.byType(SatButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Perbarui perangkat utama?').hitTestable(),
      findsOneWidget,
    );
    expect(installer.calls, 0);

    await tester.tap(find.byType(SatButton).last);
    await tester.pump();
    expect(installer.calls, 1);
  });
}
