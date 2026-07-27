import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';

export 'package:satset/ui/core/widgets/tablet_chrome.dart'
    show TabletCard, TabletStatTile;

class AdminEmbeddedStrip extends StatelessWidget {
  final String title;
  final String sub;
  final Widget? trailing;

  /// Optional indicator rendered before the [sub] line (e.g. a freshness dot).
  final Widget? subLeading;
  const AdminEmbeddedStrip({
    super.key,
    required this.title,
    required this.sub,
    this.trailing,
    this.subLeading,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SatType.sans(
                    size: 20,
                    weight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s1),
                Row(
                  children: [
                    if (subLeading != null) ...[
                      subLeading!,
                      const SizedBox(width: Sp.s1h),
                    ],
                    Flexible(
                      child: Text(
                        sub.toUpperCase(),
                        style: SatType.monoS(color: sc.textLo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  final String title;
  final String sub;
  final Widget? topTrailing;

  /// Optional indicator rendered before the [sub] line.
  final Widget? subLeading;
  final List<Widget> children;
  final EdgeInsets padding;
  const AdminPage({
    super.key,
    required this.title,
    required this.sub,
    this.topTrailing,
    this.subLeading,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(28, 24, 28, 28),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: title,
          sub: sub,
          trailing: topTrailing,
          subLeading: subLeading,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class SetTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  const SetTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(14),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: SatType.caption(color: sc.textLo)),
          const SizedBox(height: Sp.s2h),
          Text(value, style: SatType.monoL(color: sc.textHi)),
          if (sub != null) ...[
            const SizedBox(height: Sp.s1h),
            Text(
              sub!,
              style: SatType.sans(size: 11, color: sc.textMd, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class SetHero extends StatelessWidget {
  final String label;
  final String value;
  final String desc;
  final bool warn;
  final List<bool> meter;
  const SetHero({
    super.key,
    required this.label,
    required this.value,
    required this.desc,
    this.warn = false,
    this.meter = const [],
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final accent = warn ? sc.warn : sc.success;
    final soft = warn ? sc.warnSoft : sc.successSoft;
    return Container(
      decoration: SatBox.d(
        color: soft,
        border: SatB.all(color: accent, width: 1.5),
        borderRadius: SatR.a(18),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: SatType.caption(color: accent)),
          const SizedBox(height: Sp.s1),
          Text(
            value,
            style: SatType.sans(
              size: 36,
              weight: FontWeight.w600,
              letterSpacing: -0.9,
              height: 1.05,
              color: accent,
            ),
          ),
          const SizedBox(height: Sp.s2),
          Text(
            desc,
            style: SatType.sans(size: 13, color: sc.textMd, height: 1.5),
          ),
          if (meter.isNotEmpty) ...[
            const SizedBox(height: Sp.s4),
            Row(
              children: [
                for (final on in meter) ...[
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: SatBox.d(
                        color: on ? accent.withValues(alpha: 0.5) : sc.bg3,
                        borderRadius: SatR.a(3),
                      ),
                    ),
                  ),
                  if (on != meter.last) const SizedBox(width: Sp.s1),
                ],
              ],
            ),
            const SizedBox(height: Sp.s2),
            Text('STATIONS · LIVE', style: SatType.monoS(color: sc.textLo)),
          ],
        ],
      ),
    );
  }
}

class AdminRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool last;
  const AdminRow({
    super.key,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
      decoration: SatBox.d(
        border: Border(
          bottom: last ? BorderSide.none : SatB.side(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: SatType.sans(size: 13, color: sc.textMd)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

Widget adminPill(
  BuildContext context,
  String text, {
  bool on = false,
  bool danger = false,
}) {
  final sc = context.sat;
  Color bg = sc.bg3;
  Color border = sc.border1;
  Color fg = sc.textMd;
  if (on) {
    bg = sc.accentSoft;
    border = sc.accentBorder;
    fg = sc.accentText;
  }
  if (danger) {
    bg = sc.urgentSoft;
    border = sc.urgent;
    fg = sc.urgent;
  }
  return Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
    alignment: Alignment.center,
    decoration: SatBox.d(
      color: bg,
      border: SatB.all(color: border),
      borderRadius: SatR.a(999),
    ),
    child: Text(
      text,
      style: SatType.sans(size: 11, weight: FontWeight.w500, color: fg),
    ),
  );
}

Widget adminToggle(BuildContext context, {required bool on}) {
  final sc = context.sat;
  return Container(
    width: 36,
    height: 20,
    decoration: SatBox.d(
      color: on ? sc.success : sc.bg3,
      border: SatB.all(color: on ? sc.success : sc.border1),
      borderRadius: SatR.a(999),
    ),
    child: AnimatedAlign(
      duration: satMotion(context, 180),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Sp.sHair),
        width: 14,
        height: 14,
        decoration: SatBox.d(
          color: on ? sc.successInk : sc.textLo,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
