import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'sat_field.dart';

/// One choice from a closed list (ADR-0055).
///
/// Wears the same box as [SatField] — dropdowns and text fields sit in the
/// same rows and the same sheets, and a dropdown that is a different height or
/// radius from the field beside it reads as a different kind of thing.
///
/// For a handful of options that all fit on screen, prefer a row of
/// `SatChip.select`: a chip row shows every choice at once, where a dropdown
/// hides all but one behind a tap. This is for the long lists — roles, units,
/// billing states.
class SatDropdown<T> extends StatelessWidget {
  final T? value;
  final List<SatOption<T>> options;
  final ValueChanged<T?>? onChanged;

  /// Sits above the field, in caps — same treatment as [SatField]'s.
  final String? label;
  final String? hint;
  final IconData? prefixIcon;

  /// Lets a long option name ellipsize instead of overflowing the row.
  final bool expand;

  const SatDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = onChanged != null;

    final field = DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: expand,
      onChanged: onChanged,
      style: SatType.bodyM(color: on ? sc.textHi : sc.textLo),
      dropdownColor: sc.bg2,
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: sc.textLo),
      decoration: satInputDecoration(
        context,
        hint: hint,
        enabled: on,
        prefixIcon: prefixIcon,
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.value,
            child: Text(o.label, overflow: TextOverflow.ellipsis),
          ),
      ],
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!.toUpperCase(), style: SatType.caption(color: sc.textLo)),
        const SizedBox(height: Sp.s1h),
        field,
      ],
    );
  }
}

/// One line of a [SatDropdown]. A value type rather than a widget so a screen
/// cannot smuggle a differently-styled child into the list.
class SatOption<T> {
  final T value;
  final String label;
  const SatOption(this.value, this.label);
}
