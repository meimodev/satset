/// The [[Cashier]]'s discount picker (ADR-0037). Cashiers **pick a preset** —
/// there is no free-entry field anywhere in this file, by design.
///
/// Scope filtering is what stops a fixed whole-bill amount landing on one cheap
/// line, so the sheet only ever offers presets matching what was tapped.
///
/// Authority: `applyDiscount` gates the act. A cashier without it is prompted
/// for a manager PIN, which is verified **server-side** — this sheet never
/// decides whether the step-up was valid, it only collects the PIN.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// What the caller wants to discount: the whole [[Bill (tab)]], a receipt, or
/// one of a receipt's lines — the three scopes ADR-0070 settled.
class DiscountTarget {
  /// Null ⇒ a **bill**-scope discount, which belongs to the visit rather than
  /// to any receipt. That is the common case now: receipts are minted per
  /// payment (ADR-0067), so at the moment the cashier reaches for a table-wide
  /// promo there is usually no receipt to attach it to.
  final BillReceipt? receipt;

  /// Null ⇒ whole-order (or bill) discount.
  final String? ticketId;

  /// Base the discount will be resolved against — the bill or receipt subtotal,
  /// or the value of the units this receipt owns of that line. Used only to
  /// preview the amount; the server re-resolves it authoritatively.
  final int base;
  final String title;

  const DiscountTarget({
    required this.receipt,
    required this.ticketId,
    required this.base,
    required this.title,
  });

  /// The whole bill — a table-wide promo. ADR-0070.
  const DiscountTarget.bill({required this.base, required this.title})
    : receipt = null,
      ticketId = null;

  /// One line, before any receipt claims it (ADR-0126). Scope is `line`
  /// despite the null receipt: the picker offers presets for what was *tapped*,
  /// and what was tapped is a dish.
  const DiscountTarget.line({
    required this.base,
    required this.title,
    required String this.ticketId,
  }) : receipt = null;

  bool get isLine => ticketId != null;
  String get scope => isLine
      ? 'line'
      : receipt == null
      ? 'bill'
      : 'order';
}

/// Returns the chosen [[Preset diskon]] and the approver PIN, or null if
/// dismissed. The preset rides back whole so a caller that cannot write yet —
/// a pending line discount (ADR-0126) — can render what it promised without
/// looking the preset up a second time.
Future<({String presetId, DiscountPresetDto preset, String? approverPin})?>
showDiscountSheet(
  BuildContext context,
  WidgetRef ref,
  DiscountTarget target,
) async {
  final sc = context.sat;
  final presets = ref
      .read(discountPresetsRepositoryProvider.notifier)
      .forScope(target.scope);
  final canApply = ref.read(authStateProvider).has(Capability.applyDiscount);

  if (presets.isEmpty) {
    await showSatDialog<void>(
      context,
      builder: (c) => AlertDialog(
        title: Text(c.l10n.dscNoPresetsTitle),
        content: Text(switch (target.scope) {
          'line' => c.l10n.dscNoPresetsLine,
          'bill' => c.l10n.dscNoPresetsBill,
          _ => c.l10n.dscNoPresetsReceipt,
        }),
        actions: [
          SatButton.ghost(
            label: context.l10n.close,
            onTap: () => Navigator.pop(c),
          ),
        ],
      ),
    );
    return null;
  }

  DiscountPresetDto? chosen;
  final picked = await showSatSheet<DiscountPresetDto>(
    context,
    dragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.l10n.dscSheetTitle(target.title),
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.sHair),
            Text(switch (target.scope) {
              'line' => c.l10n.dscAppliesLine,
              'bill' => c.l10n.dscAppliesBill,
              _ => c.l10n.dscAppliesReceipt,
            }, style: SatType.bodyS(color: sc.textLo)),
            const SizedBox(height: Sp.s3),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: presets.length,
                separatorBuilder: (_, _) =>
                    Divider(color: sc.border0, height: 1),
                itemBuilder: (_, i) {
                  final p = presets[i];
                  // Preview only — the server re-resolves against the live base.
                  final preview = resolveDiscountAmount(
                    kind: p.kind,
                    value: p.value,
                    base: target.base,
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.name,
                      style: SatType.labelM(color: sc.textHi),
                    ),
                    subtitle: Text(
                      p.isPercent
                          ? '${(p.value / 100).toStringAsFixed(0)}%'
                          : formatIDR(p.value),
                      style: SatType.bodyS(color: sc.textLo),
                    ),
                    trailing: Text(
                      '-${formatIDR(preview)}',
                      style: SatType.monoM(color: sc.warn),
                    ),
                    onTap: () => Navigator.pop(c, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  chosen = picked;
  if (chosen == null) return null;
  if (!context.mounted) return null;

  // Step-up only when the signed-in user lacks the capability. The PIN is
  // passed straight through; the server decides whether it authorises.
  String? pin;
  if (!canApply) {
    pin = await _askApproverPin(context);
    if (pin == null || pin.isEmpty) return null;
  }
  return (presetId: chosen.id, preset: chosen, approverPin: pin);
}

Future<String?> _askApproverPin(BuildContext context) async {
  final ctrl = TextEditingController();
  final sc = context.sat;
  return showSatDialog<String>(
    context,
    builder: (c) => AlertDialog(
      title: Text(c.l10n.dscApproverTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.l10n.dscApproverBody, style: SatType.bodyM(color: sc.textLo)),
          const SizedBox(height: Sp.s3),
          SatField.pin(
            controller: ctrl,
            label: c.l10n.dscManagerPin,
            hint: '',
            autofocus: true,
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.cancel,
          onTap: () => Navigator.pop(c),
        ),
        SatButton.primary(
          label: c.l10n.dscApprove,
          onTap: () => Navigator.pop(c, ctrl.text.trim()),
        ),
      ],
    ),
  );
}
