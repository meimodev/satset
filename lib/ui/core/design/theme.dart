import 'package:flutter/material.dart';
import 'colors.dart';
import 'sat_theme.dart';
import 'skin.dart';
import 'typography.dart';

/// M3 defaults every button to a stadium pill. Under `lembut` that is the
/// shipped look, so this stays null and Flutter's default wins; under `brutal`
/// a pill in a square-corner skin is the one shape the eye catches first. Glow
/// wants the pill and gets it from the same default.
/// Only bare Material buttons see this — the app's own buttons are hand-built.
OutlinedBorder? get _buttonShape => switch (SatShape.skin) {
  SatSkin.brutal => const RoundedRectangleBorder(),
  SatSkin.lembut || SatSkin.glow => null,
};

/// Material spreads one `elevation` number over three shadow layers, so it can
/// only approximate Glow's single `0 20px 50px`. 12 is the step whose combined
/// spread reads closest; the exact colour still comes from [SatShape.liftLg].
const double _glowSheetElevation = 12;

ThemeData _build(SatColors sc, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: sc.accent,
    onPrimary: sc.accentInk,
    secondary: sc.accent,
    onSecondary: sc.accentInk,
    error: sc.urgent,
    onError: Colors.white,
    surface: sc.bg0,
    onSurface: sc.textHi,
    surfaceContainerHighest: sc.bg3,
    surfaceContainerHigh: sc.bg2,
    surfaceContainer: sc.bg2,
    surfaceContainerLow: sc.bg1,
    surfaceContainerLowest: sc.bg0,
    outline: sc.border2,
    outlineVariant: sc.border1,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: sc.bg0,
    canvasColor: sc.bg0,
    splashColor: Colors.transparent,
    highlightColor: sc.bg3,
    textTheme: SatType.buildTextTheme(sc.textHi, sc.textMd),
    extensions: [sc],
    iconTheme: IconThemeData(color: sc.textMd, size: 18),
    dividerColor: sc.border0,
    appBarTheme: AppBarTheme(
      backgroundColor: sc.bg0,
      foregroundColor: sc.textHi,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sc.bg1,
      surfaceTintColor: Colors.transparent,
      // Glow floats sheets and dialogs clear of the page on its large ambient
      // shadow. Material's `elevation` is the only way in — `SatBox.d` never
      // sees these, their decoration comes from the theme (ADR-0047).
      elevation: SatShape.glow ? _glowSheetElevation : null,
      shadowColor: SatShape.glow ? SatShape.liftLg.first.color : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SatR.c(28)),
      ),
    ),
    // M3 spends `colorScheme.primary` on both roles: the filled button's
    // surface and the text button's label. The palette splits them, so the
    // foreground-only defaults are repointed here — otherwise a dialog's
    // "Batal" is siren yellow on a white sheet.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: sc.accentText,
        shape: _buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: sc.accentText,
        shape: _buttonShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: _buttonShape),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: _buttonShape),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: sc.bg2,
      surfaceTintColor: Colors.transparent,
      elevation: SatShape.glow ? _glowSheetElevation : null,
      shadowColor: SatShape.glow ? SatShape.liftLg.first.color : null,
      shape: RoundedRectangleBorder(
        borderRadius: SatR.a(28),
        // SatBox.d never sees a dialog — the shape comes from the theme, so the
        // brutal rule is drawn here instead. Glow draws no rule at all.
        side: SatShape.brutal
            ? BorderSide(color: sc.border0, width: SatShape.brutalBorder)
            : BorderSide.none,
      ),
    ),
  );
}

ThemeData satTheme(SatTheme t) {
  // Must run before `_build`: the type ramp below already branches on the skin.
  t.adopt();
  return _build(t.colors, t.brightness);
}
