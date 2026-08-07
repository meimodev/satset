import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'anim.dart';
import 'package:satset/core/localization/locale_view_model.dart';

enum SatStepperSize { sm, md, lg }

/// The app's quantity control (ADR-0055).
///
/// Replaces three separate implementations — `_Stepper` in the zone admin,
/// `_StepperBtn` in the modifier sheet, and `GuestStepper` on the table
/// detail. All three did the same thing: clamp, disable at the bounds, and
/// animate the count.
///
/// Two shapes, because the app genuinely uses two. [SatStepper.new] is the
/// boxed one that sits in a form. [SatStepper.pill] is the one that rides a
/// crowded row — the seat count on a table card, where it has to read as a
/// single object rather than three controls.
///
/// The count slides in the direction of travel, which is the spatial cue that
/// tells a waiter their tap landed without them having to read the number.
/// Under reduced motion it snaps, via [AnimatedCount].
class SatStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final SatStepperSize size;

  /// Pill only. Sits before the count — a person glyph on the seat stepper.
  final IconData? icon;

  /// Pill only. Renders `3/6` rather than `3`. A seat count means nothing
  /// without the capacity it is filling.
  final bool showMax;

  /// Names the quantity for screen readers — 'Tamu', 'Jumlah'. The +/- buttons
  /// name themselves.
  final String? semanticLabel;

  final bool _pill;

  const SatStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.enabled = true,
    this.size = SatStepperSize.md,
    this.semanticLabel,
  }) : icon = null,
       showMax = false,
       _pill = false;

  const SatStepper.pill({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.enabled = true,
    this.size = SatStepperSize.md,
    this.icon,
    this.showMax = false,
    this.semanticLabel,
  }) : _pill = true;

  double get _h => switch (size) {
    SatStepperSize.sm => 32,
    SatStepperSize.md => 36,
    SatStepperSize.lg => 44,
  };

  double get _btnW => _pill ? _h : _h + 4;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // A max of zero would disable the plus button forever; a table with no
    // stated capacity still seats someone.
    final ceiling = _pill && max < 1 ? 1 : max;
    final canDec = enabled && value > min;
    final canInc = enabled && value < ceiling;

    return Semantics(
      label: semanticLabel,
      value: showMax ? '$value/$ceiling' : '$value',
      child: Container(
        height: _pill ? _h : null,
        decoration: SatBox.d(
          color: _pill ? sc.bg3 : sc.bg2,
          border: SatB.all(color: _pill ? sc.border0 : sc.border1),
          borderRadius: _pill ? SatR.pill : SatR.md,
        ),
        padding: _pill ? EdgeInsets.zero : const EdgeInsets.all(Sp.s1h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: _pill ? Icons.remove_rounded : Icons.remove,
              semanticLabel: context.l10n.stepperDecrease,
              width: _btnW,
              height: _h,
              round: _pill,
              onTap: canDec ? () => onChanged(value - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: sc.textMd),
                    const SizedBox(width: Sp.s1),
                  ],
                  AnimatedCount(
                    value: value,
                    builder: (context, v) => Text(
                      showMax ? '$v/$ceiling' : '$v',
                      textAlign: TextAlign.center,
                      style: SatType.monoL(
                        color: enabled ? sc.textHi : sc.textLo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _StepButton(
              icon: _pill ? Icons.add_rounded : Icons.add,
              semanticLabel: context.l10n.stepperIncrease,
              width: _btnW,
              height: _h,
              round: _pill,
              onTap: canInc ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final double width;
  final double height;
  final bool round;
  final VoidCallback? onTap;
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.width,
    required this.height,
    required this.round,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: semanticLabel,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: SatBox.d(
              // The pill's buttons are its own end caps — a filled square
              // inside a pill reads as a button glued onto a track.
              color: round ? null : (on ? sc.bg4 : sc.bg3),
              borderRadius: round ? null : SatR.sm,
              shape: round ? BoxShape.circle : BoxShape.rectangle,
            ),
            child: Icon(icon, size: 18, color: on ? sc.textHi : sc.textDim),
          ),
        ),
      ),
    );
  }
}
