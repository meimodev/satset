import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/motion.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// Size steps from the design sheet: small `h32 · r10 · 12pt`, default
/// `h44 · r14 · 13pt`, large CTA `h52 · r16 · 15pt`.
///
/// This is the one open axis on [SatButton]. A KDS action and an order-line
/// confirm are the same *intent* at different reading distances — the design
/// context asks for 2 m legibility on the line and thumb density on a phone,
/// and that is a size decision, not a new variant.
enum SatButtonSize { sm, md, lg }

/// The app's only button (ADR-0055).
///
/// Named constructors, not visual props: the call site states intent and the
/// widget owns every pixel. Adding a look means adding a constructor here —
/// a deliberate act, visible in review — rather than passing a colour from a
/// screen, which is how nine local button classes and 94 raw Material buttons
/// happened.
///
/// Raw `FilledButton` / `TextButton` / `OutlinedButton` / `ElevatedButton`
/// outside `core/widgets/` is banned by `test/design_tokens_test.dart`.
class SatButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool busy;
  final SatButtonSize size;
  final VoidCallback? onTap;

  /// A number carried on the right of the label — the cart total on "Kirim ke
  /// Dapur", the amount on "Bayar". Set in mono at reduced alpha so it reads
  /// as a value the action applies to rather than part of the action's name.
  ///
  /// A fourth axis, added deliberately: this is the order flow's main button
  /// and the pattern recurs, so the alternative was a file exemption from the
  /// raw-button ban, which is worse (ADR-0055).
  final String? trailingValue;
  final _SatButtonKind _kind;

  /// The affirmative action on a screen. Accent fill. One per view.
  const SatButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.primary;

  /// A real action that is not *the* action. Filled from the neutral ramp.
  const SatButton.neutral({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.neutral;

  /// Bordered secondary. Use where a neutral fill would compete with a card
  /// surface it sits on.
  const SatButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.outline;

  /// Dismiss, cancel, back out. No fill, no border.
  const SatButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.ghost;

  /// Completion — ready, served, settled. Green fill.
  const SatButton.success({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.success;

  /// Void, delete, end shift. Scarce by design — see the `urgent` token rule.
  const SatButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.size = SatButtonSize.md,
    this.trailingValue,
    required this.onTap,
  }) : _kind = _SatButtonKind.danger;

  bool get _enabled => onTap != null && !busy;

  double get _height => switch (size) {
    SatButtonSize.sm => 32,
    SatButtonSize.md => 44,
    SatButtonSize.lg => 52,
  };

  double get _padX => switch (size) {
    SatButtonSize.sm => Sp.s3,
    SatButtonSize.md => Sp.s4h,
    SatButtonSize.lg => Sp.s6 - 2,
  };

  /// Glow sets every control as a pill (ADR-0050) — the send button most of
  /// all, since it is the one action on the screen. Held here rather than at
  /// the call site, where it was a per-screen `SatShape.glow ? 999 : 14`.
  BorderRadius get _radius => SatShape.glow
      ? SatR.pill
      : switch (size) {
          SatButtonSize.sm => SatR.sm,
          SatButtonSize.md => SatR.lg,
          SatButtonSize.lg => SatR.xl,
        };

  double get _iconSize => switch (size) {
    SatButtonSize.sm => 14,
    SatButtonSize.md => 18,
    SatButtonSize.lg => 20,
  };

  TextStyle _labelStyle(Color color) => switch (size) {
    SatButtonSize.sm => SatType.labelS(color: color),
    SatButtonSize.md => SatType.labelM(color: color),
    SatButtonSize.lg => SatType.labelL(color: color),
  };

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final palette = _palette(sc);

    // Disabled reads from the neutral ramp on every variant. A dimmed accent
    // still looks like an accent, and "is this tappable?" must never be a
    // colour-discrimination task on a phone held at arm's length.
    final fill = _enabled
        ? palette.fill
        : (palette.fill == null ? null : sc.bg3);
    final ink = _enabled ? palette.ink : sc.textLo;
    final borderColor = palette.border == null
        ? null
        : (_enabled ? palette.border : sc.border0);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: ink),
          ),
          SizedBox(width: Sp.s2),
        ] else if (icon != null) ...[
          Icon(icon, size: _iconSize, color: ink),
          SizedBox(width: Sp.s2),
        ],
        Flexible(
          child: Text(
            SatShape.caps(label),
            style: _labelStyle(ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingValue != null) ...[
          SizedBox(width: Sp.s2h),
          Text(
            trailingValue!,
            style: SatType.monoM(color: ink.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );

    return AnimatedContainer(
      duration: satMotion(context, 120),
      curve: satEaseOut,
      height: _height,
      decoration: SatBox.d(
        color: fill,
        border: borderColor == null ? null : SatB.all(color: borderColor),
        borderRadius: _radius,
      ),
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: _radius,
          child: InkWell(
            onTap: _enabled ? onTap : null,
            borderRadius: _radius,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _padX),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }

  _SatButtonPalette _palette(SatColors sc) => switch (_kind) {
    // The ring is `accentText`, not decoration: on Neon Terang the lime fill
    // (#E1FF0F) sits at 1.03:1 against the bone ground and 1.09:1 against a
    // white card — the label is crisp and the *button* has no edge, which is
    // WCAG 1.4.11 (3:1 for a control's boundary) failed outright. `accentText`
    // is the token that already means "this accent, made legible on this
    // ground": it rings at 6.3–7.4:1 on every Glow surface, and on the dark
    // palettes it *is* `accent`, so those buttons are unchanged. The other
    // filled kinds need no ring — `success` and `urgent` clear 5.7:1+ on their
    // own in both directions.
    _SatButtonKind.primary => _SatButtonPalette(
      fill: sc.accent,
      ink: sc.accentInk,
      border: sc.accentText,
    ),
    _SatButtonKind.neutral => _SatButtonPalette(fill: sc.bg3, ink: sc.textHi),
    _SatButtonKind.outline => _SatButtonPalette(
      fill: null,
      ink: sc.textHi,
      border: sc.border1,
    ),
    _SatButtonKind.ghost => _SatButtonPalette(fill: null, ink: sc.textMd),
    _SatButtonKind.success => _SatButtonPalette(
      fill: sc.success,
      ink: onFill(sc.success),
    ),
    _SatButtonKind.danger => _SatButtonPalette(
      fill: sc.urgent,
      ink: onFill(sc.urgent),
    ),
  };
}

enum _SatButtonKind { primary, neutral, outline, ghost, success, danger }

class _SatButtonPalette {
  final Color? fill;
  final Color ink;
  final Color? border;
  const _SatButtonPalette({required this.fill, required this.ink, this.border});
}
