import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_count.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/features/admin/stock_screen.dart';

/// The stock screen on both form factors (ADR-0134 put `/stock` on the phone
/// tab bar, which is what made a phone layout owed rather than optional).
///
/// Everything asserted here is geometry or presence, never a pixel width:
/// `flutter_test` draws every glyph as a square of the font size, so a width
/// number asserted in this file would be a number about the test font.
void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const phone = Size(360, 800);
  const bigPhone = Size(411, 915);
  const tablet = Size(1280, 800);

  // A worst case on purpose: a long name, two badges, a par that puts it on
  // the shopping list, a threshold that draws the meter, and enough recipe
  // links to make the chip row overflow if nothing clamps it.
  final ingredients = <Ingredient>[
    Ingredient(
      id: 'i1',
      name: 'Bawang Merah Goreng Kemasan Premium',
      unit: StockUnit.g,
      stockOnHand: 4200,
      lowStockAt: 5000,
      parLevel: 20000,
      costMicro: 42000,
      usedBy: const [
        'Nasi Goreng Kampung Spesial',
        'Mie Goreng Jawa',
        'Sate Ayam Madura',
      ],
      lastReceivedAt: DateTime(2026, 9, 1),
    ),
    Ingredient(
      id: 'i2',
      name: 'Sambal Bawang',
      unit: StockUnit.ml,
      stockOnHand: -1500,
      lowStockAt: 2000,
      costMicro: 90000,
      batchYield: 5000,
      madeFrom: const ['Cabai Rawit Merah', 'Bawang Putih Kupas'],
      usedBy: const ['Ayam Penyet Sambal Bawang'],
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    bool opname = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _StubAuth(
              ref: ref,
              storage: ref.watch(secureStorageServiceProvider),
              seed: const AuthState(
                isAuthenticated: true,
                capabilities: {
                  Capability.adjustStock,
                  Capability.manageIngredients,
                },
              ),
            ),
          ),
          ingredientsProvider.overrideWith((ref) async => ingredients),
          if (opname) stockApiProvider.overrideWith(_OpenWalkApi.new),
        ],
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          // copyWith, never a fresh MediaQueryData: a bare one carries
          // Size.zero and every form-factor branch below then reads "phone".
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(body: StockScreen()),
        ),
      ),
    );
    // Two pumps plus a settle: the ingredient future, the post-frame resume of
    // an open walk, and the cross-fade the banner rides in on.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('lays out without overflow', () {
    for (final (name, size) in [
      ('phone 360', phone),
      ('phone 411', bigPhone),
      ('tablet', tablet),
    ]) {
      testWidgets(name, (tester) async {
        await pump(tester, size: size);
        expect(tester.takeException(), isNull);
      });

      // The meter's label and the recipe chips are both venue-authored text at
      // whatever size the OS asks for — the two places a fixed-width Row broke.
      testWidgets('$name at 1.6 text scale', (tester) async {
        await pump(tester, size: size, textScale: 1.6);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name mid-opname', (tester) async {
        await pump(tester, size: size, opname: true);
        expect(tester.takeException(), isNull);
        // The walk really is open, or the assertion above proves nothing about
        // the shape this test exists for.
        expect(find.byType(SatField), findsWidgets);
      });
    }
  });

  testWidgets('phone drops the KPI cards; the tablet keeps them', (
    tester,
  ) async {
    // The chips below carry the same four counts and the same four taps, so on
    // a phone the cards are a third of the fold spent saying it twice.
    await pump(tester, size: phone);
    expect(find.text('Perlu reorder'), findsNothing);

    await pump(tester, size: tablet);
    expect(find.text('Perlu reorder'), findsOneWidget);
  });

  testWidgets('phone puts the acts on a sheet, the tablet inline', (
    tester,
  ) async {
    await pump(tester, size: tablet);
    // "Terima" as a labelled button is the tablet's one-tap receive.
    expect(find.byType(SatButton), findsWidgets);
    final tabletReceive = find.text('Terima');
    expect(tabletReceive, findsWidgets);

    await pump(tester, size: phone);
    // On the phone it is a glyph, and the rest of the menu is one tap behind
    // an overflow control rather than an 18dp popup.
    expect(find.text('Terima'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Terima barang'), findsOneWidget);
    expect(find.text('Riwayat mutasi'), findsOneWidget);
  });

  testWidgets('opname header is glyphs on a phone, labels on a tablet', (
    tester,
  ) async {
    await pump(tester, size: tablet, opname: true);
    expect(find.text('Batal'), findsOneWidget);

    await pump(tester, size: phone, opname: true);
    // Labels would leave the title nothing; they survive as tooltips.
    expect(find.text('Batal'), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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

/// A walk somebody left open, which is what `_resumeOpname` adopts on the
/// first frame — the cheapest way into opname mode without driving the
/// start sheet.
class _OpenWalkApi extends StockApi {
  _OpenWalkApi(super.ref);

  @override
  Future<({List<StockCount> counts, StockCount? open})> counts({
    DateTime? from,
    DateTime? to,
  }) async => (
    counts: const <StockCount>[],
    open: StockCount(
      id: 'c1',
      scope: StockCountScopeKind.partial,
      blind: false,
      startedAt: DateTime(2026, 9, 5),
    ),
  );
}
