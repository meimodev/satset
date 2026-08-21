// The [[Kedai]] floor switches (ADR-0109), where they change a screen.
//
// `test/counter_mode_gate_test.dart` pins the *resolver* — which null means
// yes, which means no. This file pins the other half: what each switch
// actually does once the resolver has said yes, which is the part a refactor
// can quietly undo while every gate test still passes.
//
// All four floor switches are held here:
//
//   - `menuHome` — where a signed-in counter cashier lands. The predicate is
//     shared by the router's redirect and the tablet rail, so both follow it.
//   - `simpleKds` — a counter has one pace, "now". The course is forced at the
//     *source*, in the sheet that types the line, rather than filtered at the
//     KDS: a line that was never paced is a line nobody has to un-pace. And an
//     **edited** line keeps the course it already carries — the switch changes
//     what gets typed next, never what is already in the cart.
//   - `settleAfterSend` — a counter takes the money as part of ordering, so
//     committing opens the bill. Three things must all be true first, and the
//     capability is one of them: a waiter who cannot settle must not be handed
//     a pane whose every button would 403.
//   - `anonTakeaway` — a counter calls a number, not a name. It **relaxes** the
//     gate rather than hiding the field: the same venue takes aggregator orders
//     across the same shift, and those turn up with a name worth typing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/menu/modifier_sheet.dart';
import 'package:satset/ui/features/review/review_screen.dart';
import 'package:satset/ui/features/shell/app_shell.dart';

/// A venue whose mode key is mirrored on, holding exactly [on].
class _StubVenue extends VenueSettingsRepository {
  _StubVenue({required super.ref, required List<String> on}) {
    state = VenueSettingsDto(
      modules: const [modeCounterService],
      counterConfig: on,
    );
  }
}

void main() {
  setUpAll(() => SatType.useSystemFonts = true);
  tearDownAll(() => SatType.useSystemFonts = false);

  group('menuHome — where a counter lands', () {
    test('a counter cashier lands on the menu', () {
      expect(showCounterHome(menuHomeEnabled: true, canTakeOrder: true), true);
    });

    test('someone who cannot take an order keeps the floor', () {
      // A KDS tablet signed in on a counter venue: `/counter` would be a
      // screen it may not write from, so the switch does not reach it.
      expect(
        showCounterHome(menuHomeEnabled: true, canTakeOrder: false),
        false,
      );
    });

    test('without the switch a restaurant keeps its floor', () {
      expect(
        showCounterHome(menuHomeEnabled: false, canTakeOrder: true),
        false,
      );
    });
  });

  group('simpleKds — one pace, forced at the source', () {
    const mains = MenuItem(
      id: 'm1',
      name: 'Nasi Goreng',
      categoryId: 'mains',
      description: '',
      basePrice: 25000,
      variants: [Variant(id: 'v1', name: 'Reguler', price: 25000)],
    );

    /// Opens the sheet over [editing] (or a fresh line) on a venue holding
    /// [on]. The returned list collects whatever the foot button adds.
    Future<List<CartItem>> open(
      WidgetTester tester, {
      required List<String> on,
      CartItem? editing,
    }) async {
      // Tablet: the dialog branch of the sheet, no drag-to-size involved.
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final added = <CartItem>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueSettingsProvider.overrideWith(
              (ref) => _StubVenue(ref: ref, on: on),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            theme: satTheme(SatTheme.neonTerang),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showModifierSheet(
                    context: ctx,
                    item: mains,
                    editing: editing,
                    onAdd: added.add,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return added;
    }

    Future<void> tapFoot(
      WidgetTester tester,
      AppL10n l10n,
      bool editing,
    ) async {
      await tester.tap(find.text(editing ? l10n.save : l10n.add));
      await tester.pumpAndSettle();
    }

    late AppL10n l10n;
    setUpAll(
      () async => l10n = await AppL10n.delegate.load(const Locale('id')),
    );

    testWidgets('a new line is fired now, whatever its category', (
      tester,
    ) async {
      final added = await open(tester, on: const [counterSimpleKds]);
      await tapFoot(tester, l10n, false);
      expect(
        added.single.course,
        CourseId.fireNow,
        reason: 'a mains on a counter is still made now',
      );
    });

    testWidgets('and the course picker is not drawn at all', (tester) async {
      await open(tester, on: const [counterSimpleKds]);
      expect(
        find.text(l10n.expColCourse),
        findsNothing,
        reason: 'a pace nobody can set is a pace nobody has to un-set',
      );
    });

    testWidgets('an edited line keeps the course it already carries', (
      tester,
    ) async {
      final added = await open(
        tester,
        on: const [counterSimpleKds],
        editing: const CartItem(
          id: 'c1',
          itemId: 'm1',
          name: 'Nasi Goreng',
          variantId: 'v1',
          variantName: 'Reguler',
          course: CourseId.desserts,
          unitPrice: 25000,
        ),
      );
      await tapFoot(tester, l10n, true);
      expect(
        added.single.course,
        CourseId.desserts,
        reason:
            'the switch changes what is typed next, not what is in the cart',
      );
    });

    testWidgets('without the switch the category still paces the line', (
      tester,
    ) async {
      final added = await open(tester, on: const []);
      expect(find.text(l10n.expColCourse), findsOneWidget);
      await tapFoot(tester, l10n, false);
      expect(added.single.course, CourseId.mains);
    });
  });

  group('settleAfterSend — the bill opens, if all three agree', () {
    test('a counter cashier is handed the bill', () {
      expect(
        shouldSettleAfterSend(visitId: 'v1', settleOn: true, canSettle: true),
        true,
      );
    });

    test('a waiter who cannot settle is not handed a 403', () {
      expect(
        shouldSettleAfterSend(visitId: 'v1', settleOn: true, canSettle: false),
        false,
      );
    });

    test('without the switch the send ends at the confirmation', () {
      expect(
        shouldSettleAfterSend(visitId: 'v1', settleOn: false, canSettle: true),
        false,
      );
    });

    test(
      'a visit the floor cache has not seen yet is skipped, not blocked',
      () {
        // The order is already written; a missing visit is a reason to skip the
        // pane, never to hold up the line.
        for (final id in [null, '']) {
          expect(
            shouldSettleAfterSend(visitId: id, settleOn: true, canSettle: true),
            false,
            reason: 'visitId ${id == null ? 'null' : 'empty'}',
          );
        }
      },
    );
  });

  group('anonTakeaway — a number, not a name', () {
    late AppL10n l10n;
    setUpAll(
      () async => l10n = await AppL10n.delegate.load(const Locale('id')),
    );

    /// Opens the takeaway prompt and returns whatever it pops.
    Future<List<TakeawayDetails?>> ask(
      WidgetTester tester, {
      required bool nameOptional,
      String type = '',
    }) async {
      final out = <TakeawayDetails?>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async => out.add(
                  await askTakeawayDetails(ctx, nameOptional: nameOptional),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      if (type.isNotEmpty) {
        await tester.enterText(find.byType(TextField), type);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(l10n.revContinue));
      await tester.pumpAndSettle();
      return out;
    }

    testWidgets('a restaurant still wants the name', (tester) async {
      final out = await ask(tester, nameOptional: false);
      expect(out, isEmpty, reason: 'the prompt stays open rather than popping');
      expect(find.text(l10n.revCommitTakeaway), findsOneWidget);
    });

    testWidgets('a counter takes the order without one', (tester) async {
      final out = await ask(tester, nameOptional: true);
      expect(out.single?.guestName, '');
      expect(find.text(l10n.revCommitTakeaway), findsNothing);
    });

    testWidgets('the field is relaxed, not removed', (tester) async {
      // The same counter shop takes an aggregator order an hour later, and
      // that one arrives with a courier worth naming.
      final out = await ask(tester, nameOptional: true, type: 'Budi');
      expect(out.single?.guestName, 'Budi');
    });
  });
}
