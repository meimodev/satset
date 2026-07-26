import 'package:flutter/material.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'colors.dart';

/// A whole look, picked as one unit — background ramp, accent, and semantic
/// hues together. Brightness is a property of the theme, so there is no
/// separate light/dark toggle and no OS-follow. See ADR-0045.
///
/// Identity lives here rather than on [SatColors] so the extension stays a pure
/// token bag: [Brightness] does not interpolate, and putting it inside a
/// `ThemeExtension` would force a snap in `lerp`.
enum SatTheme {
  amberGelap(AppStrings.themeAmberGelap, Brightness.dark, SatColors.dark),
  amberTerang(AppStrings.themeAmberTerang, Brightness.light, SatColors.light),
  neonHijau(AppStrings.themeNeonHijau, Brightness.dark, SatColors.neonHijau),
  indigoTerang(
      AppStrings.themeIndigoTerang, Brightness.light, SatColors.indigoTerang);

  const SatTheme(this.label, this.brightness, this.colors);

  final String label;
  final Brightness brightness;
  final SatColors colors;

  /// What a device gets before it has ever chosen — the palette the app
  /// shipped with, so an upgrade is visually a no-op.
  static const fallback = SatTheme.amberGelap;

  /// Enum name round-trip for [PrefsService]. Unknown or absent keys fall back
  /// rather than throwing: a preference read must never block app start.
  static SatTheme fromKey(String? key) {
    for (final t in SatTheme.values) {
      if (t.name == key) return t;
    }
    return fallback;
  }
}
