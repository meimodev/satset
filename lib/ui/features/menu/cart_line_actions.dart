import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/features/menu/modifier_sheet.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// The control row under a cart line: quantity, re-configure, remove.
///
/// Shared by the review screen and the tablet cart pane so the two cannot
/// drift — they showed the same line and offered different powers before.
/// The stepper doubles as the quantity readout, so the line above no longer
/// prints `×N`.
class CartLineActions extends ConsumerWidget {
  final String tableId;
  final CartItem line;

  const CartLineActions({super.key, required this.tableId, required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cart = ref.read(cartProvider(tableId).notifier);

    // The dish can be retired from the menu while the line sits in the cart.
    // Without it there are no modifier groups to prefill the sheet with, so
    // the line stays removable but not editable rather than offering a tap
    // that cannot resolve.
    final items = ref.watch(menuItemsProvider);
    final i = items.indexWhere((it) => it.id == line.itemId);
    final item = i < 0 ? null : items[i];

    return Row(
      children: [
        SatStepper(
          value: line.qty,
          min: 1,
          max: kCartLineMaxQty,
          size: SatStepperSize.sm,
          semanticLabel: context.l10n.quantity,
          onChanged: (v) => cart.setQty(line.id, v),
        ),
        const Spacer(),
        if (item != null) ...[
          _LineAction(
            icon: Icons.tune,
            label: context.l10n.edit,
            color: sc.textMd,
            onTap: () => showModifierSheet(
              context: context,
              item: item,
              editing: line,
              onAdd: (updated) => cart.replace(line.id, updated),
            ),
          ),
          const SizedBox(width: Sp.s4),
        ],
        _LineAction(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          color: sc.urgent,
          onTap: () => cart.remove(line.id),
        ),
      ],
    );
  }
}

class _LineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LineAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // ponytail: padding, not a SizedBox — the row is already 32 tall
          // from the stepper, so this only has to widen the target.
          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: Sp.s1),
              Text(label, style: SatType.bodyS(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
