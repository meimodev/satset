import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'anim.dart';

enum SatStepperSize { sm, md }

/// The app's quantity control (ADR-0055).
///
/// Replaces three separate implementations — `_Stepper` in the zone admin,
/// `_StepperBtn` in the modifier sheet, and `GuestStepper` on the table
/// detail. All three did the same thing: clamp, disable at the bounds, and
/// animate the count.
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

  const SatStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.enabled = true,
    this.size = SatStepperSize.md,
  });

  double get _btn => size == SatStepperSize.sm ? 30 : 36;
  double get _btnW => size == SatStepperSize.sm ? 34 : 40;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final canDec = enabled && value > min;
    final canInc = enabled && value < max;

    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.md,
      ),
      padding: const EdgeInsets.all(Sp.s1h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            semanticLabel: AppStrings.stepperDecrease,
            width: _btnW,
            height: _btn,
            onTap: canDec ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.s2),
            child: AnimatedCount(
              value: value,
              builder: (context, v) => Text(
                '$v',
                textAlign: TextAlign.center,
                style: SatType.monoL(color: enabled ? sc.textHi : sc.textLo),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            semanticLabel: AppStrings.stepperIncrease,
            width: _btnW,
            height: _btn,
            onTap: canInc ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final double width;
  final double height;
  final VoidCallback? onTap;
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.width,
    required this.height,
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
              color: on ? sc.bg4 : sc.bg3,
              borderRadius: SatR.sm,
            ),
            child: Icon(icon, size: 18, color: on ? sc.textHi : sc.textDim),
          ),
        ),
      ),
    );
  }
}
