import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/colors.dart';
import '../design/format.dart';
import '../design/skin.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'sat_icon_button.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// What a field accepts. Private — the named constructors are the API.
enum _Kind { text, number, money, decimal, search, pin, inline, password }

/// The app's one input skin, shared by [SatField] and by anything else Material
/// dresses with an `InputDecoration` — the recipe editor's ingredient dropdown
/// sits in a row with two text fields and has to match them exactly.
///
/// Public only so those neighbours can reach it. A screen that wants a text
/// input reaches for [SatField], not for this.
InputDecoration satInputDecoration(
  BuildContext context, {
  String? hint,
  bool enabled = true,
  String? errorText,
  String? helperText,
  bool hasError = false,
  IconData? prefixIcon,
  String? prefixText,
  String? suffixText,
  Widget? suffix,
}) {
  final sc = context.sat;
  final bad = hasError || errorText != null;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: SatR.md,
    borderSide: SatB.side(color: c),
  );

  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: SatType.bodyM(color: sc.textDim),
    // Never the Material counter: it reserves a line under every capped field
    // and no screen here asked for one.
    counterText: '',
    errorText: errorText,
    errorStyle: SatType.bodyS(color: sc.urgent),
    helperText: helperText,
    helperStyle: SatType.bodyS(color: sc.textLo),
    helperMaxLines: 2,
    filled: true,
    fillColor: enabled ? sc.bg2 : sc.bg1,
    prefixText: prefixText,
    prefixStyle: SatType.monoM(color: sc.textLo),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 18, color: sc.textLo),
    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
    suffixIcon: suffix,
    suffixText: suffixText,
    suffixStyle: SatType.monoM(color: sc.textLo),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Sp.s3h,
      vertical: Sp.s3h,
    ),
    enabledBorder: border(bad ? sc.urgent : sc.border1),
    focusedBorder: border(bad ? sc.urgent : sc.accentBorder),
    errorBorder: border(sc.urgent),
    focusedErrorBorder: border(sc.urgent),
    disabledBorder: border(sc.border0),
  );
}

/// The app's text input (ADR-0055).
///
/// Named constructors carry the keyboard, the input formatters and the affix
/// that each kind of field needs, so a screen never assembles an
/// `InputDecoration` again. Sixty-four raw `TextField`s across twenty-one
/// files each picked their own padding, radius and hint colour.
///
/// The parameter list is long because a form field genuinely has this many
/// knobs — but every one of them is behaviour (what the keyboard does, what
/// the validator says), never appearance. Nothing here lets a call site pick a
/// colour, a radius or a padding.
class SatField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;

  /// Sits above the field, in caps. Omit for a field whose meaning is obvious
  /// from position — a search box, a single-field sheet.
  final String? label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Shows the value but refuses the keyboard — the menu editor in view-only
  /// mode. Distinct from [enabled], which also greys the field out.
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final int maxLines;
  final int? minLines;

  /// Hard cap on length. The character counter is always suppressed — it is
  /// chrome that pushes the next field down and no screen here wanted it.
  final int? maxLength;
  final IconData? prefixIcon;

  /// Trailing unit or currency mark — `Rp`, `%`, `mnt`.
  final String? suffixText;

  /// Trailing control — the password eye. A widget rather than an icon
  /// because it is a button, not a decoration.
  final Widget? suffix;

  /// Validation message under the field. Also reddens the border.
  final String? errorText;
  final String? helperText;

  /// Reddens the border without printing a message — for screens that render
  /// their own error line elsewhere (the pin screen does).
  final bool hasError;
  final TextAlign textAlign;
  final TextCapitalization capitalization;

  /// Text and inline only. A phone, URL or email keyboard where the field asks
  /// for one — the other kinds derive their keyboard from what they accept, and
  /// free text cannot. The sign-in screen's email field went years on the plain
  /// text keyboard because this was reachable from `.inline` alone.
  final TextInputType? keyboard;

  /// Inline only. Receipt lines are set in mono so what the owner types lines
  /// up with what the printer will emit.
  final bool mono;

  /// Money only. Lets a leading `-` through — a modifier can knock money off
  /// the line as well as add to it.
  final bool signed;

  /// Password only. Whether the characters are shown. The parent owns this bit
  /// rather than the field: the pin screen already holds it, and a field that
  /// hid its own reveal state could not be driven from a "show password"
  /// setting elsewhere.
  final bool visible;

  /// Password only. Fires when the eye is tapped.
  final VoidCallback? onToggle;
  final _Kind _kind;

  /// Free text — names, notes, descriptions.
  const SatField.text({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixText,
    this.suffix,
    this.errorText,
    this.helperText,
    this.hasError = false,
    this.textAlign = TextAlign.start,
    this.capitalization = TextCapitalization.sentences,
    this.keyboard,
  }) : signed = false,
       mono = false,
       visible = false,
       onToggle = null,
       _kind = _Kind.text;

  /// Whole numbers — quantities, minutes, seats. Digits only, enforced by
  /// formatter rather than by validation after the fact: a waiter mid-rush
  /// should not be able to type a letter into a count.
  const SatField.number({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLength,
    this.prefixIcon,
    this.suffixText,
    this.errorText,
    this.helperText,
    this.hasError = false,
    this.textAlign = TextAlign.start,
  }) : maxLines = 1,
       minLines = null,
       suffix = null,
       capitalization = TextCapitalization.none,
       signed = false,
       mono = false,
       keyboard = null,
       visible = false,
       onToggle = null,
       _kind = _Kind.number;

  /// Rupiah. Groups thousands as you type and carries the `Rp` mark, so the
  /// cashier reads the same shape they are about to key into the drawer.
  const SatField.money({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.hasError = false,
    this.textAlign = TextAlign.start,
    this.signed = false,
  }) : maxLines = 1,
       minLines = null,
       maxLength = null,
       prefixIcon = null,
       suffixText = null,
       suffix = null,
       capitalization = TextCapitalization.none,
       mono = false,
       keyboard = null,
       visible = false,
       onToggle = null,
       _kind = _Kind.money;

  /// Fractional amounts — stock in kg or litres. Accepts a comma as well as a
  /// dot; Indonesian keyboards offer the comma.
  const SatField.decimal({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.prefixIcon,
    this.suffixText,
    this.errorText,
    this.helperText,
    this.hasError = false,
    this.textAlign = TextAlign.start,
  }) : maxLines = 1,
       minLines = null,
       maxLength = null,
       suffix = null,
       capitalization = TextCapitalization.none,
       signed = false,
       mono = false,
       keyboard = null,
       visible = false,
       onToggle = null,
       _kind = _Kind.decimal;

  /// Filters a list as you type. Carries its own leading glass.
  const SatField.search({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.suffix,
  }) : label = null,
       readOnly = false,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       prefixIcon = Icons.search,
       suffixText = null,
       errorText = null,
       helperText = null,
       hasError = false,
       textAlign = TextAlign.start,
       capitalization = TextCapitalization.none,
       signed = false,
       mono = false,
       keyboard = null,
       visible = false,
       onToggle = null,
       _kind = _Kind.search;

  /// A value edited in place at the right of a settings row. No box, no
  /// border, no fill — the row is the container, and a boxed field inside a
  /// boxed row reads as two nested things. The only field kind that is not a
  /// rectangle you can see.
  const SatField.inline({
    super.key,
    this.controller,
    required this.hint,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    bool multiline = false,
    this.mono = false,
    this.keyboard,
  }) : label = null,
       readOnly = false,
       autofocus = false,
       maxLines = multiline ? 4 : 1,
       minLines = 1,
       maxLength = multiline ? null : 120,
       prefixIcon = null,
       suffixText = null,
       suffix = null,
       onChanged = null,
       errorText = null,
       helperText = null,
       hasError = false,
       textAlign = TextAlign.end,
       capitalization = TextCapitalization.sentences,
       signed = false,
       visible = false,
       onToggle = null,
       _kind = _Kind.inline;

  /// A staff PIN. Obscured, digits only, capped at six — the shape the auth
  /// route accepts, held here so no screen re-derives it.
  const SatField.pin({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.suffix,
    this.errorText,
    this.hasError = false,
  }) : readOnly = false,
       maxLines = 1,
       minLines = null,
       maxLength = 6,
       prefixIcon = null,
       suffixText = null,
       helperText = null,
       textAlign = TextAlign.start,
       capitalization = TextCapitalization.none,
       signed = false,
       mono = false,
       keyboard = null,
       visible = false,
       onToggle = null,
       _kind = _Kind.pin;

  /// An account password. Obscured unless [visible], with the reveal eye built
  /// in — every screen that rolled its own suffix got the icon right and the
  /// masking wrong, so the toggle and the thing it toggles now ship together.
  ///
  /// Unlike [SatField.pin] this takes any character: a PIN is the six digits
  /// the auth route accepts, a password is whatever Firebase holds.
  const SatField.password({
    super.key,
    this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
    this.hasError = false,
  }) : readOnly = false,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       prefixIcon = null,
       suffixText = null,
       suffix = null,
       helperText = null,
       textAlign = TextAlign.start,
       capitalization = TextCapitalization.none,
       signed = false,
       mono = false,
       keyboard = null,
       _kind = _Kind.password;

  TextInputType get _keyboard =>
      keyboard ??
      switch (_kind) {
        _Kind.number || _Kind.pin => TextInputType.number,
        _Kind.money => TextInputType.numberWithOptions(signed: signed),
        _Kind.decimal => const TextInputType.numberWithOptions(decimal: true),
        _Kind.text || _Kind.inline =>
          maxLines == 1 ? TextInputType.text : TextInputType.multiline,
        _Kind.search => TextInputType.text,
        _Kind.password => TextInputType.visiblePassword,
      };

  List<TextInputFormatter>? get _formatters => switch (_kind) {
    _Kind.number || _Kind.pin => [FilteringTextInputFormatter.digitsOnly],
    _Kind.money => [RupiahInputFormatter(allowNegative: signed)],
    _Kind.decimal => null,
    _Kind.text || _Kind.search || _Kind.inline || _Kind.password => null,
  };

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ink = enabled ? sc.textHi : sc.textLo;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: _kind == _Kind.pin || (_kind == _Kind.password && !visible),
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textAlign: textAlign,
      keyboardType: _keyboard,
      textCapitalization: capitalization,
      inputFormatters: _formatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: maxLines == 1
          ? TextInputAction.done
          : TextInputAction.newline,
      onTapOutside: (_) => focusNode?.unfocus(),
      style: mono ? SatType.monoM(color: ink) : SatType.bodyM(color: ink),
      cursorColor: sc.accentText,
      decoration: _kind == _Kind.inline
          ? InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: SatType.bodyM(color: sc.textLo),
            )
          : satInputDecoration(
              context,
              hint: hint,
              enabled: enabled,
              errorText: errorText,
              helperText: helperText,
              hasError: hasError,
              prefixIcon: prefixIcon,
              prefixText: _kind == _Kind.money ? 'Rp ' : null,
              suffixText: suffixText,
              suffix: _kind == _Kind.password
                  ? SatIconButton.plain(
                      icon: visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      tooltip: visible
                          ? context.l10n.a11yHidePassword
                          : context.l10n.a11yShowPassword,
                      onTap: onToggle,
                    )
                  : suffix,
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
