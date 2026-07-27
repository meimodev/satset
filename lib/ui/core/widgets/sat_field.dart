import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/colors.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// The app's text input (ADR-0055).
///
/// Named constructors carry the keyboard, the input formatters and the affix
/// that each kind of field needs, so a screen never assembles an
/// `InputDecoration` again. Sixty-four raw `TextField`s across twenty-one
/// files each picked their own padding, radius and hint colour.
class SatField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  /// Sits above the field. Omit for a field whose meaning is obvious from
  /// position — a search box, a single-field sheet.
  final String? label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final IconData? prefixIcon;

  /// Trailing unit or currency mark — `Rp`, `%`, `mnt`.
  final String? suffixText;
  final TextInputType? _keyboard;
  final List<TextInputFormatter>? _formatters;
  final TextCapitalization _capitalization;

  /// Free text — names, notes, descriptions.
  const SatField.text({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixText,
  }) : _keyboard = TextInputType.text,
       _formatters = null,
       _capitalization = TextCapitalization.sentences;

  /// Whole numbers — quantities, minutes, seats, prices in rupiah. Digits
  /// only, enforced by formatter rather than by validation after the fact: a
  /// waiter mid-rush should not be able to type a letter into a price.
  const SatField.number({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixText,
  }) : maxLines = 1,
       _keyboard = TextInputType.number,
       _formatters = const [],
       _capitalization = TextCapitalization.none;

  /// Filters a list as you type. Carries its own leading glass.
  const SatField.search({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  }) : label = null,
       maxLines = 1,
       prefixIcon = Icons.search,
       suffixText = null,
       _keyboard = TextInputType.text,
       _formatters = null,
       _capitalization = TextCapitalization.none;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ink = enabled ? sc.textHi : sc.textLo;

    final field = TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: _keyboard,
      textCapitalization: _capitalization,
      inputFormatters: _formatters == null
          ? null
          : [FilteringTextInputFormatter.digitsOnly, ..._formatters],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: SatType.bodyM(color: ink),
      cursorColor: sc.accentText,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: SatType.bodyM(color: sc.textDim),
        filled: true,
        fillColor: enabled ? sc.bg2 : sc.bg1,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: sc.textLo),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 20,
        ),
        suffixText: suffixText,
        suffixStyle: SatType.monoM(color: sc.textLo),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sp.s3h,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SatR.md,
          borderSide: SatB.side(color: sc.border1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SatR.md,
          borderSide: SatB.side(color: sc.accentBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: SatR.md,
          borderSide: SatB.side(color: sc.border0),
        ),
      ),
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
