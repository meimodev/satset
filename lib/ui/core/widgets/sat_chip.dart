import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'anim.dart';

/// The semantic hues a [SatChip.tag] may carry. Closed on purpose — these are
/// the six the design sheet publishes, and they alias the same vocabulary the
/// course/role/zone visuals use. A chip that needs a seventh hue is a chip
/// that means something new, and that is a conversation, not a parameter.
enum SatChipHue { neutral, accent, success, warn, urgent, info, violet }

enum SatChipSize { sm, md }

/// Chips, pills and badges (ADR-0055).
///
/// Two shapes, because there are only two jobs: [SatChip.tag] states a fact,
/// [SatChip.select] takes a tap and holds a selection. Before this the app had
/// thirteen private variations of these two — `_FilterChip` twice, `_ZoneChip`
/// twice, `_AgePill`, `_LockedPill`, `_StatBadge`, `_RoleBadge` and the rest.
///
/// Not to be confused with `StatusChip`, which stays: a ticket's lifecycle
/// state is domain vocabulary with its own fixed set, not a free-form hue.
class SatChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// A coloured dot before the label — course markers, zone identity.
  /// Independent of [hue] because a course chip is a neutral chip that names
  /// a course, not a chip painted in the course colour.
  final Color? dot;
  final SatChipHue hue;
  final SatChipSize size;
  final bool selected;
  final VoidCallback? onTap;
  final bool _selectable;

  /// A statement of fact — an allergen, a role, a count, an elapsed band.
  const SatChip.tag({
    super.key,
    required this.label,
    this.icon,
    this.dot,
    this.hue = SatChipHue.neutral,
    this.size = SatChipSize.md,
  }) : selected = false,
       onTap = null,
       _selectable = false;

  /// A filter or a choice. Covers both — a filter row and a single-select row
  /// differ in how the parent interprets taps, never in how the chip looks.
  const SatChip.select({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dot,
    this.size = SatChipSize.md,
  }) : hue = SatChipHue.neutral,
       _selectable = true;

  EdgeInsets get _padding => switch (size) {
    SatChipSize.sm => const EdgeInsets.symmetric(
      horizontal: Sp.s2h,
      vertical: Sp.s1h,
    ),
    SatChipSize.md => const EdgeInsets.symmetric(
      horizontal: Sp.s3,
      vertical: 9,
    ),
  };

  TextStyle _labelStyle(Color color) => switch (size) {
    SatChipSize.sm => SatType.labelS(color: color),
    SatChipSize.md => SatType.labelM(color: color),
  };

  double get _iconSize => size == SatChipSize.sm ? 12 : 14;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;

    // Glow marks a selection with a solid slab rather than one step up the
    // neutral ramp (ADR-0051) — a tint of a fluorescent accent on a bone
    // ground reads as a highlighter smear, and "is this on?" must never be a
    // difference you have to look for.
    final glow = SatShape.glow;
    final on = glow && selected ? sc.slab : sc;

    final Color fill;
    final Color border;
    final Color ink;
    if (_selectable) {
      fill = selected ? (glow ? on.bg0 : sc.bg4) : sc.bg2;
      border = selected ? sc.border2 : sc.border0;
      ink = selected ? on.textHi : sc.textMd;
    } else {
      final tone = _tone(sc);
      fill = tone.fill;
      border = tone.border;
      ink = tone.ink;
    }

    final body = AnimatedContainer(
      duration: satMotion(context, 120),
      curve: satEaseOut,
      padding: _padding,
      decoration: SatBox.d(
        color: fill,
        borderRadius: SatR.pill,
        border: SatB.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: SatBox.d(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: Sp.s2),
          ] else if (icon != null) ...[
            Icon(icon, size: _iconSize, color: ink),
            const SizedBox(width: Sp.s1h),
          ],
          Text(
            SatShape.caps(label),
            style: _labelStyle(ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!_selectable) return body;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        child: GestureDetector(onTap: onTap, child: body),
      ),
    );
  }

  ({Color fill, Color border, Color ink}) _tone(SatColors sc) => switch (hue) {
    SatChipHue.neutral => (fill: sc.bg3, border: sc.border0, ink: sc.textMd),
    SatChipHue.accent => (
      fill: sc.accentSoft,
      border: sc.accentBorder,
      ink: sc.accentText,
    ),
    SatChipHue.success => (
      fill: sc.successSoft,
      border: sc.success,
      ink: sc.success,
    ),
    SatChipHue.warn => (fill: sc.warnSoft, border: sc.warn, ink: sc.warn),
    SatChipHue.urgent => (
      fill: sc.urgentSoft,
      border: sc.urgent,
      ink: sc.urgent,
    ),
    SatChipHue.info => (fill: sc.infoSoft, border: sc.info, ink: sc.info),
    SatChipHue.violet => (
      fill: sc.violetSoft,
      border: sc.violet,
      ink: sc.violet,
    ),
  };
}
