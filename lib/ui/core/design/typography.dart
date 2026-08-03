import 'package:flutter/material.dart';

import 'skin.dart';

class SatType {
  SatType._();

  /// The bundled faces (`pubspec.yaml` → `flutter: fonts:`). Every skin resolves
  /// to one of these and nothing here touches the network: a venue installs the
  /// APK on a LAN with no WAN, picks any theme, and the first frame is correct.
  /// Archivo serves `glow` — the skin the default theme carries (ADR-0057) — and
  /// brutal's body copy; Archivo Black and DM Mono serve the rest of `brutal`;
  /// Plex serves the amber (`lembut`) themes.
  static const _archivo = 'Archivo';
  static const _archivoBlack = 'Archivo Black';
  static const _dmMono = 'DM Mono';
  static const _plexSans = 'IBM Plex Sans';
  static const _plexMono = 'IBM Plex Mono';

  /// Archivo ships as one variable file, so the weight has to be driven on the
  /// `wght` axis — a bare `fontWeight` against a single-instance family gets
  /// synthesised, which smears the heavy end the display roles rely on.
  static List<FontVariation> _wght(FontWeight w) => [
    FontVariation('wght', w.value.toDouble()),
  ];

  /// Resolves every role against the platform's default face instead of the
  /// bundled ones.
  ///
  /// Set by the golden suite only. It predates the bundled faces — it was there
  /// to stop `google_fonts` reaching for the network mid-test — but it stays for
  /// the second reason it always had: everything the roles decide (size, weight,
  /// tracking, height) still applies, only the face is swapped, so a golden
  /// still fails when a role changes while staying byte-identical across
  /// machines and Flutter's own font-resolution changes.
  ///
  /// Everything the roles decide — size, weight, tracking, height — still
  /// applies; only the face is swapped, so a golden still fails when a role
  /// changes. It also makes goldens deterministic across machines, which a
  /// downloaded font never is.
  @visibleForTesting
  static bool useSystemFonts = false;

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    if (useSystemFonts) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: SatShape.lembut ? _plexSans : _archivo,
      fontSize: size,
      fontWeight: weight,
      fontVariations: SatShape.lembut ? null : _wght(weight),
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// The ramp for anything that has to line up in a column — prices, KDS
  /// timers, table numbers, quantities.
  ///
  /// Glow has no monospace: the design sets everything in the grotesk and
  /// relies on `tabular-nums`. That is safe only because the feature is forced
  /// here rather than left to the face's default — without it, a running timer
  /// in a proportional font jitters on every digit change, which is the one
  /// thing a KDS at 1–2 m cannot have (ADR-0050).
  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.04,
    double? height,
    Color? color,
  }) {
    if (useSystemFonts) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: SatShape.glow ? 0 : letterSpacing,
        height: height,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }
    if (SatShape.glow) {
      return TextStyle(
        fontFamily: _archivo,
        fontSize: size,
        fontWeight: weight,
        fontVariations: _wght(weight),
        // Glow's grotesk is set without the mono ramp's tracking.
        letterSpacing: 0,
        height: height,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }
    if (SatShape.brutal) {
      return TextStyle(
        fontFamily: _dmMono,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: _plexMono,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// Poster type for numerals and screen titles. Under the brutal skin this is
  /// Archivo Black — a single-weight face, so [weight] is ignored there rather
  /// than synthesised into a smear. Glow uses the same grotesk as its body copy
  /// at w700/w800, so it falls through to [sans] and keeps its weight.
  static TextStyle display({
    double size = 30,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    if (!SatShape.brutal) {
      return sans(
        size: size,
        weight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    if (useSystemFonts) {
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: _archivoBlack,
      fontSize: size,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  // ---------------------------------------------------------------------
  // Named roles (ADR-0055).
  //
  // The closed set every screen writes against. Sizes and tracking come from
  // the design source's type sheet — Display 54 / H1 32 / H2 22 / H3 18,
  // Body L 15 / M 13 / S 12, Mono Display 36 / L 22 / M 13, Caption 10 — and
  // the per-skin adjustments below mirror what `_lembut` / `_brutal` / `_glow`
  // already do to the Material ramp: brutal shouts (Archivo Black titles,
  // letterspaced small copy), glow tightens and leans on weight.
  //
  // `color` stays a parameter on every role. Color is signal and varies per
  // call site; size and weight do not. A literal `size:` outside this file is
  // banned by `test/design_tokens_test.dart`.
  // ---------------------------------------------------------------------

  /// Title weight for the current skin. Brutal sets titles as slabs, glow
  /// carries its contrast on weight alone, lembut sits between.
  static FontWeight get _titleWeight => switch (SatShape.skin) {
    SatSkin.brutal => FontWeight.w800,
    SatSkin.glow => FontWeight.w700,
    SatSkin.lembut => FontWeight.w600,
  };

  /// Tracking multiplier for titles. Glow's grotesk needs roughly double the
  /// negative tracking of IBM Plex to read at the same density (ADR-0050).
  static double get _titleTrack => SatShape.glow ? 2.0 : 1.0;

  /// Poster numerals and the one-per-screen title. 54 · 600 · −0.025em.
  static TextStyle display54({Color? color}) => display(
    size: 54,
    weight: _titleWeight,
    letterSpacing: -1.35 * _titleTrack,
    height: 1.05,
    color: color,
  );

  /// Screen title. 32 · 600 · −0.025em.
  static TextStyle h1({Color? color}) => display(
    size: 32,
    weight: _titleWeight,
    letterSpacing: -0.8 * _titleTrack,
    height: 1.05,
    color: color,
  );

  /// Section heading inside a screen. 22 · 600 · −0.02em.
  static TextStyle h2({Color? color}) => display(
    size: 22,
    weight: _titleWeight,
    letterSpacing: -0.44 * _titleTrack,
    height: 1.1,
    color: color,
  );

  /// Card title, sheet header, primary action label. 18 · 600 · −0.01em.
  static TextStyle h3({Color? color}) => sans(
    size: 18,
    weight: _titleWeight,
    letterSpacing: -0.18 * _titleTrack,
    color: color,
  );

  /// Lead body — item descriptions, sheet copy. 15 · 500.
  static TextStyle bodyL({Color? color}) =>
      sans(size: 15, weight: FontWeight.w500, color: color);

  /// Default body — row labels, item names, meta lines. 13 · 500.
  static TextStyle bodyM({Color? color}) =>
      sans(size: 13, weight: FontWeight.w500, color: color);

  /// Fine print — disclaimers, secondary meta. 12 · 400.
  static TextStyle bodyS({Color? color}) => sans(
    size: 12,
    weight: SatShape.brutal ? FontWeight.w500 : FontWeight.w400,
    color: color,
  );

  // The design sheet specs its buttons and chips at w600 on the body sizes,
  // which `bodyL`/`bodyM`/`bodyS` (w500/w500/w400) cannot express. Three label
  // roles rather than a `weight:` escape hatch on the body roles — an open
  // weight parameter is how 5 weights across 827 sites happened (ADR-0055).

  /// Large CTA and sheet-action label. 15 · 600.
  static TextStyle labelL({Color? color}) => sans(
    size: 15,
    weight: SatShape.brutal ? FontWeight.w700 : FontWeight.w600,
    color: color,
  );

  /// Default control label — buttons, tabs, chips. 13 · 600.
  static TextStyle labelM({Color? color}) => sans(
    size: 13,
    weight: SatShape.brutal ? FontWeight.w700 : FontWeight.w600,
    color: color,
  );

  /// Compact control label — small buttons, dense chips. 12 · 600.
  static TextStyle labelS({Color? color}) => sans(
    size: 12,
    weight: SatShape.brutal ? FontWeight.w700 : FontWeight.w600,
    color: color,
  );

  /// The money number. Mono 36 · 600 · −0.025em.
  static TextStyle monoDisplay({Color? color}) => mono(
    size: 36,
    weight: FontWeight.w600,
    letterSpacing: -0.9,
    height: 1.05,
    color: color,
  );

  /// The one poster numeral on a screen — the table number on its own detail
  /// page. Mono 54 · 500 · −0.03em, the tabular twin of [display54].
  ///
  /// Both call sites sit inside a `FittedBox(scaleDown)`, so this is a ceiling
  /// rather than a chosen size: the phone's 96px slot scales it down, the
  /// tablet's lets it run.
  static TextStyle monoDisplay54({Color? color}) => mono(
    size: 54,
    weight: FontWeight.w500,
    letterSpacing: -1.62,
    height: 1.0,
    color: color,
  );

  /// KDS timers, table numbers — read at 1–2 m. Mono 22 · 500.
  static TextStyle monoL({Color? color}) =>
      mono(size: 22, weight: FontWeight.w500, color: color);

  /// Inline numerics, codes, technical strings. Mono 13 · 0.04em.
  static TextStyle monoM({Color? color}) =>
      mono(size: 13, weight: FontWeight.w500, color: color);

  /// The quiet numeric line — timestamps, order codes, unit counts, the
  /// "12 item · 3 kursi" strip under a title. Mono 11 · 400.
  ///
  /// Not in the design source's eleven, which jumps straight from Mono M to
  /// Caption. A hundred call sites were setting small mono at a regular
  /// weight, and folding them all into a w600 [caption] would have shouted
  /// every timestamp in the app. The gap was real (ADR-0055).
  static TextStyle monoS({Color? color}) =>
      mono(size: 11, weight: FontWeight.w400, color: color);

  /// Section caps and audit labels. Mono 10 · 600 · 0.12em. Uppercase the
  /// string at the call site — Flutter has no text-transform.
  static TextStyle caption({Color? color}) => mono(
    size: 10,
    weight: FontWeight.w600,
    letterSpacing: SatShape.glow ? 0.4 : 1.2,
    color: color,
  );

  static TextTheme buildTextTheme(Color textHi, Color textMd) =>
      switch (SatShape.skin) {
        SatSkin.brutal => _brutal(textHi, textMd),
        SatSkin.glow => _glow(textHi, textMd),
        SatSkin.lembut => _lembut(textHi, textMd),
      };

  static TextTheme _lembut(Color textHi, Color textMd) {
    return TextTheme(
      displayLarge: sans(
        size: 38,
        weight: FontWeight.w600,
        letterSpacing: -0.76,
        height: 1.05,
        color: textHi,
      ),
      displayMedium: sans(
        size: 30,
        weight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.05,
        color: textHi,
      ),
      displaySmall: sans(
        size: 22,
        weight: FontWeight.w600,
        letterSpacing: -0.22,
        color: textHi,
      ),
      headlineLarge: sans(
        size: 30,
        weight: FontWeight.w600,
        letterSpacing: -0.6,
        color: textHi,
      ),
      headlineMedium: sans(
        size: 22,
        weight: FontWeight.w600,
        letterSpacing: -0.22,
        color: textHi,
      ),
      headlineSmall: sans(
        size: 19,
        weight: FontWeight.w600,
        letterSpacing: -0.19,
        color: textHi,
      ),
      titleLarge: sans(
        size: 17,
        weight: FontWeight.w600,
        letterSpacing: -0.17,
        color: textHi,
      ),
      titleMedium: sans(
        size: 15,
        weight: FontWeight.w600,
        letterSpacing: -0.15,
        color: textHi,
      ),
      titleSmall: sans(
        size: 14,
        weight: FontWeight.w600,
        letterSpacing: -0.14,
        color: textHi,
      ),
      bodyLarge: sans(size: 15, weight: FontWeight.w400, color: textHi),
      bodyMedium: sans(size: 14, weight: FontWeight.w400, color: textHi),
      bodySmall: sans(size: 12, weight: FontWeight.w400, color: textMd),
      labelLarge: sans(size: 14, weight: FontWeight.w500, color: textHi),
      labelMedium: sans(size: 12, weight: FontWeight.w500, color: textMd),
      labelSmall: sans(
        size: 11,
        weight: FontWeight.w500,
        color: textLow(textMd),
      ),
    );
  }

  /// Neo-brutalist ramp. Titles are Archivo Black set tight (-0.01em) and
  /// nearly leading-less (0.95) so they read as stacked slabs; labels go the
  /// other way — Archivo 700 at +0.14em, which is the source design's only
  /// small-text treatment. Body copy stays at normal tracking: a waiter reads
  /// item names, they do not scan them as headings.
  static TextTheme _brutal(Color textHi, Color textMd) {
    return TextTheme(
      displayLarge: display(
        size: 38,
        letterSpacing: -0.38,
        height: 0.95,
        color: textHi,
      ),
      displayMedium: display(
        size: 30,
        letterSpacing: -0.30,
        height: 0.95,
        color: textHi,
      ),
      displaySmall: display(
        size: 22,
        letterSpacing: -0.22,
        height: 0.95,
        color: textHi,
      ),
      headlineLarge: display(
        size: 30,
        letterSpacing: -0.30,
        height: 0.95,
        color: textHi,
      ),
      headlineMedium: display(
        size: 22,
        letterSpacing: -0.22,
        height: 0.95,
        color: textHi,
      ),
      headlineSmall: display(
        size: 19,
        letterSpacing: -0.19,
        height: 0.98,
        color: textHi,
      ),
      titleLarge: sans(
        size: 17,
        weight: FontWeight.w800,
        letterSpacing: -0.09,
        color: textHi,
      ),
      titleMedium: sans(
        size: 15,
        weight: FontWeight.w800,
        letterSpacing: -0.08,
        color: textHi,
      ),
      titleSmall: sans(
        size: 14,
        weight: FontWeight.w700,
        letterSpacing: -0.07,
        color: textHi,
      ),
      bodyLarge: sans(size: 15, weight: FontWeight.w500, color: textHi),
      bodyMedium: sans(size: 14, weight: FontWeight.w500, color: textHi),
      bodySmall: sans(size: 12, weight: FontWeight.w500, color: textMd),
      labelLarge: sans(
        size: 14,
        weight: FontWeight.w700,
        letterSpacing: 0.28,
        color: textHi,
      ),
      labelMedium: sans(
        size: 12,
        weight: FontWeight.w700,
        letterSpacing: 1.20,
        color: textMd,
      ),
      labelSmall: sans(
        size: 11,
        weight: FontWeight.w700,
        letterSpacing: 1.54,
        color: textLow(textMd),
      ),
    );
  }

  /// Glow's ramp. Sentence case throughout — the design sheet's rule 4 is "no
  /// letterspaced uppercase walls" — with titles at w700 / -0.02em and a hard
  /// split between them and small copy, which goes to w500 at zero tracking and
  /// stays muted. The contrast that `_brutal` gets from shouting, this gets from
  /// weight and size alone.
  ///
  /// Where `_brutal` reaches for Archivo Black, this stays on the variable face
  /// at w800: Glow's numerals are heavy but not poster-weight, and one family
  /// across the whole ramp is the point.
  static TextTheme _glow(Color textHi, Color textMd) {
    return TextTheme(
      displayLarge: sans(
        size: 38,
        weight: FontWeight.w800,
        letterSpacing: -1.52,
        height: 1.02,
        color: textHi,
      ),
      displayMedium: sans(
        size: 30,
        weight: FontWeight.w800,
        letterSpacing: -1.20,
        height: 1.02,
        color: textHi,
      ),
      displaySmall: sans(
        size: 22,
        weight: FontWeight.w800,
        letterSpacing: -0.88,
        height: 1.05,
        color: textHi,
      ),
      headlineLarge: sans(
        size: 30,
        weight: FontWeight.w700,
        letterSpacing: -0.60,
        height: 1.05,
        color: textHi,
      ),
      headlineMedium: sans(
        size: 22,
        weight: FontWeight.w700,
        letterSpacing: -0.44,
        height: 1.05,
        color: textHi,
      ),
      headlineSmall: sans(
        size: 19,
        weight: FontWeight.w700,
        letterSpacing: -0.38,
        height: 1.05,
        color: textHi,
      ),
      titleLarge: sans(
        size: 17,
        weight: FontWeight.w700,
        letterSpacing: -0.34,
        color: textHi,
      ),
      titleMedium: sans(
        size: 15,
        weight: FontWeight.w700,
        letterSpacing: -0.30,
        color: textHi,
      ),
      titleSmall: sans(
        size: 14,
        weight: FontWeight.w600,
        letterSpacing: -0.28,
        color: textHi,
      ),
      bodyLarge: sans(size: 15, weight: FontWeight.w400, color: textHi),
      bodyMedium: sans(size: 14, weight: FontWeight.w400, color: textHi),
      bodySmall: sans(size: 12, weight: FontWeight.w400, color: textMd),
      labelLarge: sans(size: 14, weight: FontWeight.w600, color: textHi),
      labelMedium: sans(size: 12, weight: FontWeight.w500, color: textMd),
      labelSmall: sans(
        size: 11,
        weight: FontWeight.w500,
        color: textLow(textMd),
      ),
    );
  }

  static Color textLow(Color textMd) => textMd;
}
