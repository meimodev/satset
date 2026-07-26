// Patrol end-to-end test: the modifier sheet snapshots a *single-select*
// add-on onto the cart line — covering the submit-path drop that left the KDS
// blank (single-select selections were a bare String and got flattened away).
// See docs/adr/0011-ticket-modifier-snapshot.md. The KDS-render half is
// covered by modifier_snapshot_test.dart.
//
// One patrolTest per file by convention — multiple patrolTests in one file
// race the PatrolAppService request/execute handshake (500). We drive the real
// modifier sheet and capture the CartItem it emits; no server boot.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/features/menu/modifier_sheet.dart';

/// A button that opens the real modifier sheet for [item] and captures the
/// CartItem the sheet emits.
class _SheetHost extends StatelessWidget {
  final MenuItem item;
  final void Function(CartItem) onAdd;
  const _SheetHost({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              showModifierSheet(context: context, item: item, onAdd: onAdd),
          child: const Text('BUKA'),
        ),
      ),
    );
  }
}

void main() {
  patrolTest('modifier sheet snapshots a single-select add-on', ($) async {
    CartItem? captured;
    const item = MenuItem(
      id: 'i1',
      name: 'Nasi Goreng',
      categoryId: 'mains',
      description: '',
      basePrice: 25000,
      variants: [Variant(id: 'v1', name: 'Reguler', price: 25000)],
      modifierGroups: [
        ModifierGroup(
          id: 'spice',
          name: 'Tingkat pedas',
          required: false,
          multi: false, // single-select — the dropped case
          options: [
            ModifierOption(id: 'hot', name: 'Pedas'),
            ModifierOption(id: 'mild', name: 'Tidak pedas'),
          ],
        ),
      ],
    );

    await $.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: satTheme(SatTheme.amberTerang),
        home: _SheetHost(item: item, onAdd: (ci) => captured = ci),
      ),
    ));
    // Fixed pumps — pumpAndSettle can stall on google_fonts' first-launch
    // fetch (see app_boot_test.dart).
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await $.pump(const Duration(milliseconds: 400));
      }
    }

    await settle();
    await $('BUKA').tap();
    await settle();

    // Pick the single-select option, then add to cart.
    await $('Pedas').tap();
    await settle();
    await $(Icons.add).tap();
    await settle();

    expect(captured, isNotNull);
    expect(
      captured!.selectedModifiers.any((m) => m.optionId == 'hot'),
      isTrue,
      reason: 'single-select add-on must survive into the cart line',
    );
    expect(captured!.selectedModifiers.first.label, 'Pedas');
  });
}
