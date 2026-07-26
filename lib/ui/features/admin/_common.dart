import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

export 'package:satset/ui/core/widgets/tablet_chrome.dart' show TabletCard, TabletStatTile;

class AdminEmbeddedStrip extends StatelessWidget {
  final String title;
  final String sub;
  final Widget? trailing;

  /// Optional indicator rendered before the [sub] line (e.g. a freshness dot).
  final Widget? subLeading;
  const AdminEmbeddedStrip(
      {super.key,
      required this.title,
      required this.sub,
      this.trailing,
      this.subLeading});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: SatType.sans(
                      size: 20,
                      weight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: sc.textHi,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (subLeading != null) ...[
                      subLeading!,
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(sub.toUpperCase(),
                          style: SatType.mono(
                            size: 11,
                            color: sc.textLo,
                            letterSpacing: 0.66,
                          )),
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
            title: title, sub: sub, trailing: topTrailing, subLeading: subLeading),
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
  const SetTile({super.key, required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: sc.textLo,
              )),
          const SizedBox(height: 10),
          Text(value,
              style: SatType.mono(
                size: 24,
                weight: FontWeight.w600,
                letterSpacing: -0.48,
                height: 1,
                color: sc.textHi,
              )),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!,
                style: SatType.sans(
                  size: 11,
                  color: sc.textMd,
                  height: 1.4,
                )),
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
  const SetHero({super.key, required this.label, required this.value, required this.desc, this.warn = false, this.meter = const []});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final accent = warn ? sc.warn : sc.success;
    final soft = warn ? sc.warnSoft : sc.successSoft;
    return Container(
      decoration: BoxDecoration(
        color: soft,
        border: Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.2,
                color: accent,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: SatType.sans(
                size: 36,
                weight: FontWeight.w600,
                letterSpacing: -0.9,
                height: 1.05,
                color: accent,
              )),
          const SizedBox(height: 8),
          Text(desc,
              style: SatType.sans(
                size: 13,
                color: sc.textMd,
                height: 1.5,
              )),
          if (meter.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (final on in meter) ...[
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: on ? accent.withValues(alpha: 0.5) : sc.bg3,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (on != meter.last) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text('STATIONS · LIVE',
                style: SatType.mono(
                  size: 10,
                  color: sc.textLo,
                  letterSpacing: 1.0,
                )),
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
  const AdminRow({super.key, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: SatType.sans(
                  size: 13,
                  color: sc.textMd,
                )),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

Widget adminPill(BuildContext context, String text, {bool on = false, bool danger = false}) {
  final sc = context.sat;
  Color bg = sc.bg3;
  Color border = sc.border1;
  Color fg = sc.textMd;
  if (on) {
    bg = sc.accentSoft;
    border = sc.accentBorder;
    fg = sc.accent;
  }
  if (danger) {
    bg = sc.urgentSoft;
    border = sc.urgent;
    fg = sc.urgent;
  }
  return Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text,
        style: SatType.sans(
          size: 11,
          weight: FontWeight.w500,
          color: fg,
        )),
  );
}

Widget adminToggle(BuildContext context, {required bool on}) {
  final sc = context.sat;
  return Container(
    width: 36,
    height: 20,
    decoration: BoxDecoration(
      color: on ? sc.success : sc.bg3,
      border: Border.all(color: on ? sc.success : sc.border1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 180),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: on ? sc.successInk : sc.textLo,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
