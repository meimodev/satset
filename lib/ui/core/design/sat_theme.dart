import 'package:flutter/material.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'colors.dart';
import 'skin.dart';

/// A whole look, picked as one unit — background ramp, accent, semantic hues,
/// and shape language together. Brightness is a property of the theme, so there
/// is no separate light/dark toggle and no OS-follow. See ADR-0045.
///
/// Identity lives here rather than on [SatColors] so the extension stays a pure
/// token bag: [Brightness] does not interpolate, and putting it inside a
/// `ThemeExtension` would force a snap in `lerp`. [SatSkin] rides along for the
/// same reason — and because a palette and its shape language are one decision,
/// not two (see ADR-0047).
enum SatTheme {
  amberGelap(AppStrings.themeAmberGelap, Brightness.dark, SatColors.dark),
  amberTerang(AppStrings.themeAmberTerang, Brightness.light, SatColors.light),
  neonGelap(
    AppStrings.themeNeonGelap,
    Brightness.dark,
    SatColors.glowNoir,
    SatSkin.glow,
  ),
  neonTerang(
    AppStrings.themeNeonTerang,
    Brightness.light,
    SatColors.glow,
    SatSkin.glow,
  ),
  indigoTerang(
    AppStrings.themeIndigoTerang,
    Brightness.light,
    SatColors.indigoTerang,
  ),
  neoKertas(
    AppStrings.themeNeoKertas,
    Brightness.light,
    SatColors.neoKertas,
    SatSkin.brutal,
  ),
  neoMidnight(
    AppStrings.themeNeoMidnight,
    Brightness.dark,
    SatColors.neoMidnight,
    SatSkin.brutal,
  );

  const SatTheme(
    this.label,
    this.brightness,
    this.colors, [
    this.skin = SatSkin.lembut,
  ]);

  final String label;
  final Brightness brightness;
  final SatColors colors;
  final SatSkin skin;

  /// Publishes this theme's shape language to [SatShape], where the `SatR` /
  /// `SatB` / `SatBox` helpers and the type ramp read it from. Called by
  /// `satTheme()` on every build, which runs in `SatSetApp.build` — ahead of
  /// any descendant that draws a decoration.
  void adopt() {
    SatShape.skin = skin;
    SatShape.ink = colors.border0;
    SatShape.brightness = brightness;
  }

  /// What a device gets before it has ever chosen. No longer the palette the
  /// app shipped with: ADR-0057 moved it from [amberGelap] to [neonTerang] and
  /// bumped the prefs key alongside, so the swap reaches devices that had
  /// already picked. An upgrade is deliberately *not* a visual no-op — see
  /// ADR-0057 for why that promise was withdrawn.
  static const fallback = SatTheme.neonTerang;

  /// Enum name round-trip for [PrefsService]. Unknown or absent keys fall back
  /// rather than throwing: a preference read must never block app start.
  ///
  /// `neonHijau` was renamed to [neonGelap] without an alias (ADR-0050), so a
  /// device that had picked it lands on [fallback] once. Deliberate: the
  /// palette underneath the name changed too, so there is no old choice left to
  /// honour — and the setting is device-local and cosmetic.
  static SatTheme fromKey(String? key) {
    for (final t in SatTheme.values) {
      if (t.name == key) return t;
    }
    return fallback;
  }
}
