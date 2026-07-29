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
import 'package:satset/core/localization/app_strings.dart';
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

/// What the caller wants to discount: a whole receipt, or one of its lines.
class DiscountTarget {
  final BillReceipt receipt;

  /// Null ⇒ whole-order discount.
  final String? ticketId;

  /// Base the discount will be resolved against — the receipt subtotal, or the
  /// value of the units this receipt owns of that line. Used only to preview
  /// the amount; the server re-resolves it authoritatively.
  final int base;
  final String title;

  const DiscountTarget({
    required this.receipt,
    required this.ticketId,
    required this.base,
    required this.title,
  });

  bool get isLine => ticketId != null;
  String get scope => isLine ? 'line' : 'order';
}

/// Returns `(presetId, approverPin)` to apply, or null if dismissed.
Future<({String presetId, String? approverPin})?> showDiscountSheet(
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
        title: const Text('Belum ada preset diskon'),
        content: Text(
          target.isLine
              ? 'Belum ada preset diskon per item. Tambahkan di '
                    'Pengaturan venue › Diskon.'
              : 'Belum ada preset diskon per pesanan. Tambahkan di '
                    'Pengaturan venue › Diskon.',
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.close,
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
              'Diskon · ${target.title}',
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.sHair),
            Text(
              target.isLine
                  ? 'Berlaku untuk item ini'
                  : 'Berlaku seluruh struk',
              style: SatType.bodyS(color: sc.textLo),
            ),
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
  return (presetId: chosen.id, approverPin: pin);
}

Future<String?> _askApproverPin(BuildContext context) async {
  final ctrl = TextEditingController();
  final sc = context.sat;
  return showSatDialog<String>(
    context,
    builder: (c) => AlertDialog(
      title: const Text('Persetujuan manajer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diskon perlu disetujui manajer. Minta manajer memasukkan PIN.',
            style: SatType.bodyM(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s3),
          SatField.pin(
            controller: ctrl,
            label: 'PIN manajer',
            hint: '',
            autofocus: true,
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: AppStrings.cancel,
          onTap: () => Navigator.pop(c),
        ),
        SatButton.primary(
          label: 'Setujui',
          onTap: () => Navigator.pop(c, ctrl.text.trim()),
        ),
      ],
    ),
  );
}
