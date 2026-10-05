import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/features/menu/modifier_sheet.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/ui/features/menu/view_models/cart_availability.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/features/cashier/member_panel.dart';

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
    final memberSplit = ref.watch(venueSettingsProvider).memberSplitOn;
    final availability = ref
        .watch(cartAvailabilityProvider(tableId))
        .valueOrNull;
    final stock = availability?.lines[line.id];
    final soldOut = stock?.reason == 'sold_out';
    final configurationChanged = stock?.reason == 'configuration_changed';
    final short =
        stock != null &&
        line.qty > stock.maxQty &&
        !soldOut &&
        !configurationChanged;
    final maxQty = stock == null || availability?.stale == true
        ? kCartLineMaxQty
        : (stock.maxQty > line.qty ? stock.maxQty : line.qty);
    final canOverride = ref
        .watch(authStateProvider)
        .has(Capability.overrideStock);

    // The dish can be retired from the menu while the line sits in the cart.
    // Without it there are no modifier groups to prefill the sheet with, so
    // the line stays removable but not editable rather than offering a tap
    // that cannot resolve.
    final items = ref.watch(menuItemsProvider);
    final i = items.indexWhere((it) => it.id == line.itemId);
    final item = i < 0 ? null : items[i];

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Sp.s3,
        runSpacing: Sp.s2,
        children: [
          SatStepper(
            value: line.qty,
            min: 1,
            max: maxQty,
            size: SatStepperSize.sm,
            semanticLabel: context.l10n.quantity,
            onChanged: (v) => cart.setQty(line.id, v),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Sp.s3,
            runSpacing: Sp.s1h,
            children: [
              if (memberSplit) ...[
                _LineAction(
                  icon: Icons.badge_outlined,
                  label: line.memberName ?? context.l10n.cshMemberFind,
                  color: line.memberId == null ? sc.textMd : sc.accentText,
                  onTap: () async {
                    final picked = await showSatSheet<MemberDto>(
                      context,
                      builder: (_) => const MemberLookupSheet(lookupOnly: true),
                    );
                    if (picked != null) {
                      cart.setMember(line.id, picked.id, picked.name);
                    }
                  },
                ),
                if (line.memberId != null)
                  _LineAction(
                    icon: Icons.person_off_outlined,
                    label: context.l10n.cshMemberDetach,
                    color: sc.textLo,
                    onTap: () => cart.setMember(line.id, null, null),
                  ),
              ],
              if (item != null)
                _LineAction(
                  icon: Icons.tune,
                  label: context.l10n.edit,
                  color: sc.textMd,
                  onTap: () => showModifierSheet(
                    context: context,
                    item: item,
                    tableId: tableId,
                    editing: line,
                    onAdd: (updated) => cart.replace(line.id, updated),
                  ),
                ),
              if (short && canOverride)
                _LineAction(
                  icon: Icons.warning_amber_rounded,
                  label: context.l10n.mnuOverrideStock,
                  color: sc.urgent,
                  onTap: () async {
                    final reason = await _askOverrideReason(context);
                    if (reason != null && reason.isNotEmpty) {
                      cart.setStockOverrideReason(line.id, reason);
                    }
                  },
                ),
              _LineAction(
                icon: Icons.delete_outline,
                label: context.l10n.delete,
                color: sc.urgent,
                onTap: () => cart.remove(line.id),
              ),
            ],
          ),
          if (soldOut || short || configurationChanged)
            Text(
              configurationChanged
                  ? context.l10n.mnuMenuChanged
                  : soldOut
                  ? context.l10n.mnuSoldOutNow
                  : context.l10n.mnuStockShort(stock!.ingredients.join(', ')),
              style: SatType.bodyS(color: sc.urgent),
            ),
          if (short && line.stockOverrideReason.isNotEmpty)
            Text(
              '${context.l10n.mnuOverrideStock}: ${line.stockOverrideReason}',
              style: SatType.bodyS(color: sc.textMd),
            ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(vertical: Sp.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: Sp.s1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  style: SatType.bodyS(color: color),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _askOverrideReason(BuildContext context) async {
  final controller = TextEditingController();
  final reason = await showSatDialog<String>(
    context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(context.l10n.mnuOverrideStock),
        content: SatField.text(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          hint: context.l10n.mnuOverrideReason,
          label: context.l10n.mnuOverrideReason,
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          SatButton.ghost(
            onTap: () => Navigator.of(dialogContext).pop(),
            label: context.l10n.cancel,
          ),
          SatButton.primary(
            onTap: controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(controller.text.trim()),
            label: context.l10n.mnuOverrideStock,
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return reason;
}
