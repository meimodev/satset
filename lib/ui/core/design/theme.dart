import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

ThemeData satDarkTheme() => _build(SatColors.dark, Brightness.dark);
ThemeData satLightTheme() => _build(SatColors.light, Brightness.light);
