import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Shared visual language for the Fleet console + venue editor, so the two
/// surfaces read as one system. Venue tiles and admin rows are the same
/// [FleetTile]; status is always carried by the leading icon **tint**, never a
/// separate pill (see CONTEXT.md "Fleet console").

/// Status → (tint, soft bg, label). One source of truth for both venue tiles
/// (kill switch) and admin rows (per-operator ban).
({Color tint, Color soft, String label}) fleetStatusVisual(
  SatColors sc,
  AdminStatus s,
) {
  return switch (s) {
    AdminStatus.active => (
      tint: sc.success,
      soft: sc.successSoft,
      label: 'AKTIF',
    ),
    AdminStatus.suspended => (
      tint: sc.warn,
      soft: sc.warnSoft,
      label: 'TANGGUH',
    ),
    AdminStatus.banned => (
      tint: sc.urgent,
      soft: sc.urgentSoft,
      label: 'BLOKIR',
    ),
    AdminStatus.unknown => (tint: sc.textLo, soft: sc.bg3, label: '?'),
  };
}

/// A pill carrying one fleet signal (billing, offline, lockout-risk). Status is
/// deliberately *not* a pill — it lives in the tile's leading tint.
Widget fleetPill(SatColors sc, String text, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: 3),
  decoration: SatBox.d(color: bg, borderRadius: SatR.a(8)),
  child: Text(text, style: SatType.caption(color: fg)),
);

/// The shared tile: leading status-tint icon box, title + sub, an optional pill
/// wrap, and a trailing action (the `⋮` quick-action menu). Whole tile is
/// tappable when [onTap] is given. Used for both venue tiles and admin rows.
class FleetTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String? sub;
  final bool subMono;
  final List<Widget> pills;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool big;

  const FleetTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.sub,
    this.subMono = false,
    this.pills = const [],
    this.trailing,
    this.onTap,
    this.big = true,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final radius = big ? 16.0 : 14.0;
    final iconBox = big ? 48.0 : 40.0;
    final iconSize = big ? 22.0 : 18.0;
    final titleSize = big ? 16.0 : 15.0;

    final body = Container(
      padding: EdgeInsets.fromLTRB(
        big ? 16 : 14,
        14,
        trailing == null ? 16 : 6,
        14,
      ),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: SatBox.d(
              color: tint.withValues(alpha: 0.12),
              borderRadius: SatR.a(big ? 14 : 12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: tint),
          ),
          SizedBox(width: big ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: Sp.s1),
                  child: Text(
                    title,
                    style: SatType.sans(
                      size: titleSize,
                      weight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: sc.textHi,
                    ),
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: subMono
                        ? SatType.monoS(color: sc.textLo)
                        : SatType.sans(size: 12, color: sc.textLo, height: 1.3),
                  ),
                ],
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: Sp.s2h),
                  Wrap(spacing: 8, runSpacing: 8, children: pills),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Sp.s1), trailing!],
        ],
      ),
    );

    if (onTap == null) return body;
    return PressScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: SatR.a(radius),
        child: InkWell(onTap: onTap, borderRadius: SatR.a(radius), child: body),
      ),
    );
  }
}

/// `⋮` quick-action menu shared by venue tiles + admin rows. `danger` keys
/// render in `urgent`.
Widget fleetMenu(
  SatColors sc, {
  required bool enabled,
  required Map<String, String> items,
  required Set<String> dangerKeys,
  required ValueChanged<String> onSelected,
}) => PopupMenuButton<String>(
  enabled: enabled,
  icon: Icon(Icons.more_vert, color: sc.textLo),
  color: sc.bg2,
  onSelected: onSelected,
  itemBuilder: (_) => [
    for (final e in items.entries)
      PopupMenuItem(
        value: e.key,
        child: Text(
          e.value,
          style: SatType.sans(
            size: 13,
            color: dangerKeys.contains(e.key) ? sc.urgent : sc.textHi,
          ),
        ),
      ),
  ],
);

/// Themed snackbar used across both fleet screens.
void fleetToast(BuildContext context, String msg, {bool error = false}) {
  final sc = context.sat;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(msg, style: SatType.sans(size: 13, color: sc.textHi)),
        backgroundColor: error ? sc.urgentSoft : sc.bg3,
      ),
    );
}

/// Strips the `[code]` prefix Cloud Functions errors carry.
String fleetErrText(Object e) {
  final s = e.toString();
  return s.contains(']') ? s.split(']').last.trim() : s;
}

/// Hub-style header: small icon + kicker, then a big title. Matches the phone
/// Venue Hub. Used at the top of the Fleet console.
class FleetHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final IconData icon;
  final Widget? trailing;
  const FleetHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.icon = Icons.travel_explore_rounded,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: sc.accentText),
            const SizedBox(width: Sp.s1h),
            Expanded(
              child: Text(kicker, style: SatType.caption(color: sc.accentText)),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: Sp.s1),
        Text(
          title,
          style: SatType.sans(
            size: 22,
            weight: FontWeight.w600,
            letterSpacing: -0.44,
            height: 1.05,
            color: sc.textHi,
          ),
        ),
      ],
    );
  }
}

/// Full-width primary action button in the fleet theme (matches the hub seed
/// banner's filled button).
class FleetPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onTap;
  const FleetPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: onTap == null ? sc.bg3 : sc.accent,
      borderRadius: SatR.a(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: sc.bg0,
                  ),
                )
              else
                Icon(icon, size: 18, color: onTap == null ? sc.textLo : sc.bg0),
              const SizedBox(width: Sp.s2),
              Text(
                label,
                style: SatType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: onTap == null ? sc.textLo : sc.bg0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
