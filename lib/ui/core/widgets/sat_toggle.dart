import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/motion.dart';
import '../design/skin.dart';
import '../design/spacing.dart';

/// An on/off switch (ADR-0055).
///
/// The app had two of these — a Material `Switch` on four settings rows and a
/// hand-drawn `adminToggle` on twenty more — which looked nothing alike and
/// sat in the same screens.
///
/// Owns its own tap target and its own `Semantics`. The previous hand-drawn
/// one was a bare `Container` that call sites wrapped in a `GestureDetector`,
/// which announced no role at all: TalkBack read the row's label and gave the
/// user nothing to act on.
class SatToggle extends StatelessWidget {
  final bool value;

  /// Null disables the switch. It still announces its state — a setting you
  /// cannot change is not a setting you cannot read.
  final ValueChanged<bool>? onChanged;

  /// Names the setting for screen readers. The visible label is usually the
  /// row's, which sits outside this widget.
  final String? semanticLabel;

  const SatToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = onChanged != null;
    final track = value ? (on ? sc.success : sc.bg4) : sc.bg3;

    return Semantics(
      toggled: value,
      enabled: on,
      label: semanticLabel,
      child: GestureDetector(
        onTap: on ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        // The switch itself is 36×20 — too small for a moving thumb, so the
        // padding buys back a 44px target without moving the graphic.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s1,
            vertical: Sp.s3,
          ),
          child: Container(
            width: 36,
            height: 20,
            decoration: SatBox.d(
              color: track,
              border: SatB.all(color: value && on ? sc.success : sc.border1),
              borderRadius: SatR.pill,
            ),
            child: AnimatedAlign(
              duration: satMotion(context, 180),
              curve: satEaseOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: Sp.sHair),
                width: 14,
                height: 14,
                decoration: SatBox.d(
                  color: value && on ? sc.successInk : sc.textLo,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
