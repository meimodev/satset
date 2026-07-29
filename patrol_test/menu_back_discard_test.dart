// Patrol end-to-end test: backing out of the menu discards the cart, and asks
// first when there is something to lose. See ADR-0061.
//
// Driven with the *native* back gesture on purpose — that is the path a waiter
// on gesture navigation actually uses, and the one a plain widget test cannot
// reach. The app-bar button routes into the same `_handleBack`, so covering
// native back covers both.
//
// One patrolTest per file by convention — multiple patrolTests in one file
// race the PatrolAppService request/execute handshake (500). We host the real
// MenuScreen under a two-route GoRouter (safePop needs a router in context and
// something to pop to); no server boot.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/menu/menu_screen.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';

const _cartKey = 'draft-1';

const _item = MenuItem(
  id: 'nasgor',
  name: 'Nasi Goreng',
  categoryId: 'mains',
  description: '',
  basePrice: 85000,
  variants: [Variant(id: 'reguler', name: 'Reguler', price: 85000)],
  modifierGroups: [],
);

CartItem _line(String id) => CartItem(
  id: id,
  itemId: 'nasgor',
  name: 'Nasi Goreng',
  variantId: 'reguler',
  variantName: 'Reguler',
  modifiers: const [],
  selectedModifiers: const [],
  note: '',
  course: CourseId.mains,
  qty: 1,
  unitPrice: 85000,
);

/// Route `/`: seeds the cart and pushes the menu, and prints the live cart
/// count so the test can assert what survived a back press without reaching
/// into a container.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider(_cartKey));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CART ${cart.length}'),
            ElevatedButton(
              onPressed: () => ref
                  .read(cartProvider(_cartKey).notifier)
                  .add(_line('C${cart.length + 1}')),
              child: const Text('ISI'),
            ),
            ElevatedButton(
              onPressed: () => context.push('/menu'),
              child: const Text('BUKA'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  patrolTest('back out of the menu discards the cart, asking first', ($) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const _Host()),
        GoRoute(
          path: '/menu',
          builder: (_, _) =>
              const MenuScreen(tableId: _cartKey, tableless: true),
        ),
      ],
    );

    await $.pumpWidget(
      ProviderScope(
        overrides: [
          // MenuScreen renders straight from these; the repository behind them
          // would need a paired server.
          menuStatusProvider.overrideWith((_) => const AsyncValue.data(null)),
          menuItemsProvider.overrideWithValue(const [_item]),
          menuCategoriesProvider.overrideWithValue(const [
            MenuCategory(id: 'mains', name: 'Utama'),
          ]),
        ],
        child: MaterialApp.router(
          theme: satTheme(SatTheme.neonTerang),
          routerConfig: router,
        ),
      ),
    );

    // Fixed pumps — pumpAndSettle can stall on google_fonts' first-launch
    // fetch (see app_boot_test.dart).
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await $.pump(const Duration(milliseconds: 400));
      }
    }

    await settle();

    // 1. Empty cart — back pops straight through, no question asked.
    await $('BUKA').tap();
    await settle();
    expect($('Nasi Goreng'), findsWidgets, reason: 'menu should be up');

    await $.platformAutomator.android.pressBack();
    await settle();
    expect(
      $(AppStrings.discardCartTitle),
      findsNothing,
      reason: 'an empty cart has nothing to confirm',
    );
    expect($('CART 0'), findsOneWidget);

    // 2. Non-empty cart — back asks, and Batal keeps everything.
    await $('ISI').tap();
    await settle();
    await $('ISI').tap();
    await settle();
    expect($('CART 2'), findsOneWidget);

    await $('BUKA').tap();
    await settle();
    await $.platformAutomator.android.pressBack();
    await settle();
    expect(
      $(AppStrings.discardCartTitle),
      findsOneWidget,
      reason: 'leaving with items must be confirmed',
    );

    await $(AppStrings.cancel).tap();
    await settle();
    expect(
      $('Nasi Goreng'),
      findsWidgets,
      reason: 'Batal stays on the menu — nothing popped',
    );

    // 3. Confirming discards the cart and leaves.
    await $.platformAutomator.android.pressBack();
    await settle();
    await $(AppStrings.discardCartConfirm).tap();
    await settle();
    expect($('CART 0'), findsOneWidget, reason: 'cart cleared on the way out');
  });
}
