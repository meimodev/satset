import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'anim.dart';

/// One tab. Kept as a value rather than a widget so a screen cannot smuggle
/// arbitrary decoration into a tab strip.
class SatTab {
  final String label;
  final IconData? icon;

  /// Optional count shown after the label — open tickets, unread alerts.
  final int? badge;
  const SatTab({required this.label, this.icon, this.badge});
}

/// Segmented tab strip (ADR-0055).
///
/// Replaces `_TabSwitcher`/`_TabFade` in the menu admin and the two raw
/// `TabBar`s. Deliberately not Material's `TabBar`: that widget wants a
/// `TabController` and an indicator theme, and every screen here is already
/// holding the selected index in a view-model.
class SatTabs extends StatelessWidget {
  final List<SatTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Fills the available width, dividing it evenly. Off by default — a strip
  /// of two short tabs stretched across a tablet reads as two buttons that
  /// happen to touch.
  final bool expand;

  const SatTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final children = [
      for (var i = 0; i < tabs.length; i++)
        if (expand)
          Expanded(
            child: _SatTabItem(
              tab: tabs[i],
              on: i == selected,
              onTap: () => onSelected(i),
            ),
          )
        else
          _SatTabItem(
            tab: tabs[i],
            on: i == selected,
            onTap: () => onSelected(i),
          ),
    ];

    return Container(
      padding: const EdgeInsets.all(Sp.s1),
      decoration: SatBox.d(
        color: sc.bg1,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.md,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SatTabItem extends StatelessWidget {
  final SatTab tab;
  final bool on;
  final VoidCallback onTap;
  const _SatTabItem({required this.tab, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;

    // Selected reads as a fill, never a tint — same rule as SatChip
    // (ADR-0051). The slab keeps it legible under Glow's bone ground.
    final glow = SatShape.glow;
    final onPal = glow && on ? sc.slab : sc;
    final ink = on ? onPal.textHi : sc.textMd;

    return Semantics(
      button: true,
      selected: on,
      label: tab.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 140),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3h,
            vertical: Sp.s2h,
          ),
          decoration: SatBox.d(
            color: on ? (glow ? onPal.bg0 : sc.bg3) : null,
            borderRadius: SatR.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tab.icon != null) ...[
                Icon(tab.icon, size: 16, color: ink),
                const SizedBox(width: Sp.s1h),
              ],
              Text(
                SatShape.caps(tab.label),
                style: SatType.labelM(color: ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (tab.badge != null) ...[
                const SizedBox(width: Sp.s1h),
                Text('${tab.badge}', style: SatType.caption(color: sc.textLo)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
