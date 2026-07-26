import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';

/// Device-local theme picker (ADR-0045). Lives on the Me screen rather than in
/// `/settings` on purpose: `/settings` is gated on `editSettings`, and every
/// waiter must be able to set the look of their own handset.
Future<void> showThemeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    // Sheet is opaque so the swatches are judged against their own palette,
    // not through a tint of the outgoing one.
    isScrollControlled: true,
    builder: (_) => const _ThemeSheet(),
  );
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = Theme.of(context).extension<SatColors>()!;
    final active = ref.watch(satThemeProvider);

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
            const SizedBox(height: 18),
            Text(
              AppStrings.themeSheetTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: sc.textHi),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.themeSheetSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: sc.textLo),
            ),
            const SizedBox(height: 14),
            for (final t in SatTheme.values)
              _ThemeRow(
                theme: t,
                selected: t == active,
                onTap: () {
                  ref.read(satThemeProvider.notifier).select(t);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final SatTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeRow({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = Theme.of(context).extension<SatColors>()!;
    final p = theme.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? sc.accentSoft : sc.bg2,
        borderRadius: SatR.a(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: SatBox.d(
              borderRadius: SatR.a(14),
              border: SatB.all(
                color: selected ? sc.accentBorder : sc.border1,
              ),
            ),
            child: Row(
              children: [
                _Swatch(bg: p.bg0, accent: p.accent, text: p.textHi),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    theme.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: sc.textHi),
                  ),
                ),
                // Selection is stated by the check, not by the tint alone —
                // the tint is unreadable against some palettes' swatches.
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
    );
  }
}

/// Three-band preview: ground, accent, ink. Enough to tell the four apart at a
/// glance without rendering a fake screen.
class _Swatch extends StatelessWidget {
  final Color bg;
  final Color accent;
  final Color text;
  const _Swatch({required this.bg, required this.accent, required this.text});

  @override
  Widget build(BuildContext context) {
    final sc = Theme.of(context).extension<SatColors>()!;
    return Container(
      width: 44,
      height: 30,
      decoration: SatBox.d(
        color: bg,
        borderRadius: SatR.a(8),
        border: SatB.all(color: sc.border2),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: SatBox.d(shape: BoxShape.circle, color: accent),
          ),
          const SizedBox(width: 5),
          Container(
            width: 12,
            height: 3,
            decoration: SatBox.d(
              color: text,
              borderRadius: SatR.a(2),
            ),
          ),
        ],
      ),
    );
  }
}
