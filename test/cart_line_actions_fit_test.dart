import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/menu/cart_line_actions.dart';

class _StubVenueSettings extends StateNotifier<VenueSettingsDto>
    implements VenueSettingsRepository {
  _StubVenueSettings(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  const sampleItem = MenuItem(
    id: 'item-1',
    name: 'Nasi Goreng Spesial',
    basePrice: 35000,
    categoryId: 'mains',
    description: '',
    variants: [],
  );

  const sampleLine = CartItem(
    id: 'c1',
    itemId: 'item-1',
    name: 'Nasi Goreng Spesial',
    course: CourseId.mains,
    unitPrice: 35000,
    variantId: 'v1',
    variantName: '',
    qty: 2,
    memberId: 'mem-1',
    memberName: 'Budi Santoso Long Name',
  );

  testWidgets('CartLineActions fits in narrow cart panel card width without overflow', (tester) async {
    tester.view.physicalSize = const Size(312, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuItemsProvider.overrideWith((ref) => [sampleItem]),
          venueSettingsProvider.overrideWith(
            (ref) => _StubVenueSettings(
              const VenueSettingsDto(
                membersEnabled: true,
                modules: [modeMemberSplit, moduleMembers],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 312,
                child: CartLineActions(
                  tableId: 't1',
                  line: sampleLine,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CartLineActions), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
