import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// Device-local language picker (ADR-0083).
///
/// Deliberately built as a twin of `theme_sheet.dart`: same home on the Me
/// screen, same device-local scope, same reason for both. `/settings` is gated
/// on `editSettings`, and a waiter has to be able to set the language of the
/// handset in their own hand without an admin.
Future<void> showLocaleSheet(BuildContext context, WidgetRef ref) {
  return showSatSheet<void>(context, builder: (_) => const _LocaleSheet());
}

class _LocaleSheet extends ConsumerWidget {
  const _LocaleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = Theme.of(context).extension<SatColors>()!;
    final active = ref.watch(satLocaleProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border2,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4h),
            Text(
              context.l10n.localeSheetTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1),
            Text(
              context.l10n.localeSheetSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s3h),
            for (final l in satSupportedLocales)
              _LocaleRow(
                // Each language is named **in itself**, never translated: a
                // reader who cannot read the current language still has to find
                // their own. This is why "English" stays English in the
                // Indonesian build and "Bahasa Indonesia" stays Indonesian in
                // the English one.
                label: switch (l.languageCode) {
                  'en' => context.l10n.localeEnglish,
                  _ => context.l10n.localeIndonesian,
                },
                code: l.languageCode.toUpperCase(),
                selected: l == active,
                onTap: () {
                  ref.read(satLocaleProvider.notifier).select(l);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LocaleRow extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;
  const _LocaleRow({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = Theme.of(context).extension<SatColors>()!;

    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Sp.s2),
        child: Material(
          color: selected ? sc.accentSoft : sc.bg2,
          borderRadius: SatR.a(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s3h,
                vertical: Sp.s3h,
              ),
              decoration: SatBox.d(
                borderRadius: SatR.a(14),
                border: SatB.all(
                  color: selected ? sc.accentBorder : sc.border1,
                ),
              ),
              child: Row(
                children: [
                  // The tag stands in for the theme sheet's swatch: something
                  // recognisable before the label is read.
                  Container(
                    width: 44,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: SatBox.d(
                      color: sc.bg1,
                      borderRadius: SatR.a(8),
                      border: SatB.all(color: sc.border2),
                    ),
                    child: Text(
                      code,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: sc.textMd),
                    ),
                  ),
                  const SizedBox(width: Sp.s3h),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: sc.textHi),
                    ),
                  ),
                  // Stated by the check, not the tint alone — same rule the
                  // theme sheet follows.
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? sc.accentText : sc.textDim,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
