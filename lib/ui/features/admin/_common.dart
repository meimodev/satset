import 'package:flutter/material.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

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
                Text(title, style: SatType.h2(color: sc.textHi)),
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
            Text(sub!, style: SatType.bodyS(color: sc.textMd)),
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
      padding: const EdgeInsets.all(Sp.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: SatType.caption(color: accent)),
          const SizedBox(height: Sp.s1),
          Text(value, style: SatType.h1(color: accent)),
          const SizedBox(height: Sp.s2),
          Text(desc, style: SatType.bodyM(color: sc.textMd)),
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
            Text(
              context.l10n.cmnStationsLive,
              style: SatType.monoS(color: sc.textLo),
            ),
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
            child: Text(label, style: SatType.bodyM(color: sc.textMd)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}
