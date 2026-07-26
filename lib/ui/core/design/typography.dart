import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'skin.dart';

class SatType {
  SatType._();

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    final f = SatShape.brutal ? GoogleFonts.archivo : GoogleFonts.ibmPlexSans;
    return f(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.04,
    double? height,
    Color? color,
  }) {
    final f = SatShape.brutal ? GoogleFonts.dmMono : GoogleFonts.ibmPlexMono;
    return f(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// Poster type for numerals and screen titles. Under the brutal skin this is
  /// Archivo Black — a single-weight face, so [weight] is ignored there rather
  /// than synthesised into a smear.
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
    return GoogleFonts.archivoBlack(
      fontSize: size,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextTheme buildTextTheme(Color textHi, Color textMd) =>
      SatShape.brutal ? _brutal(textHi, textMd) : _lembut(textHi, textMd);

  static TextTheme _lembut(Color textHi, Color textMd) {
    return TextTheme(
      displayLarge: sans(size: 38, weight: FontWeight.w600, letterSpacing: -0.76, height: 1.05, color: textHi),
      displayMedium: sans(size: 30, weight: FontWeight.w600, letterSpacing: -0.6, height: 1.05, color: textHi),
      displaySmall: sans(size: 22, weight: FontWeight.w600, letterSpacing: -0.22, color: textHi),
      headlineLarge: sans(size: 30, weight: FontWeight.w600, letterSpacing: -0.6, color: textHi),
      headlineMedium: sans(size: 22, weight: FontWeight.w600, letterSpacing: -0.22, color: textHi),
      headlineSmall: sans(size: 19, weight: FontWeight.w600, letterSpacing: -0.19, color: textHi),
      titleLarge: sans(size: 17, weight: FontWeight.w600, letterSpacing: -0.17, color: textHi),
      titleMedium: sans(size: 15, weight: FontWeight.w600, letterSpacing: -0.15, color: textHi),
      titleSmall: sans(size: 14, weight: FontWeight.w600, letterSpacing: -0.14, color: textHi),
      bodyLarge: sans(size: 15, weight: FontWeight.w400, color: textHi),
      bodyMedium: sans(size: 14, weight: FontWeight.w400, color: textHi),
      bodySmall: sans(size: 12, weight: FontWeight.w400, color: textMd),
      labelLarge: sans(size: 14, weight: FontWeight.w500, color: textHi),
      labelMedium: sans(size: 12, weight: FontWeight.w500, color: textMd),
      labelSmall: sans(size: 11, weight: FontWeight.w500, color: textLow(textMd)),
    );
  }

  /// Neo-brutalist ramp. Titles are Archivo Black set tight (-0.01em) and
  /// nearly leading-less (0.95) so they read as stacked slabs; labels go the
  /// other way — Archivo 700 at +0.14em, which is the source design's only
  /// small-text treatment. Body copy stays at normal tracking: a waiter reads
  /// item names, they do not scan them as headings.
  static TextTheme _brutal(Color textHi, Color textMd) {
    return TextTheme(
      displayLarge: display(size: 38, letterSpacing: -0.38, height: 0.95, color: textHi),
      displayMedium: display(size: 30, letterSpacing: -0.30, height: 0.95, color: textHi),
      displaySmall: display(size: 22, letterSpacing: -0.22, height: 0.95, color: textHi),
      headlineLarge: display(size: 30, letterSpacing: -0.30, height: 0.95, color: textHi),
      headlineMedium: display(size: 22, letterSpacing: -0.22, height: 0.95, color: textHi),
      headlineSmall: display(size: 19, letterSpacing: -0.19, height: 0.98, color: textHi),
      titleLarge: sans(size: 17, weight: FontWeight.w800, letterSpacing: -0.09, color: textHi),
      titleMedium: sans(size: 15, weight: FontWeight.w800, letterSpacing: -0.08, color: textHi),
      titleSmall: sans(size: 14, weight: FontWeight.w700, letterSpacing: -0.07, color: textHi),
      bodyLarge: sans(size: 15, weight: FontWeight.w500, color: textHi),
      bodyMedium: sans(size: 14, weight: FontWeight.w500, color: textHi),
      bodySmall: sans(size: 12, weight: FontWeight.w500, color: textMd),
      labelLarge: sans(size: 14, weight: FontWeight.w700, letterSpacing: 0.28, color: textHi),
      labelMedium: sans(size: 12, weight: FontWeight.w700, letterSpacing: 1.20, color: textMd),
      labelSmall: sans(size: 11, weight: FontWeight.w700, letterSpacing: 1.54, color: textLow(textMd)),
    );
  }

  static Color textLow(Color textMd) => textMd;
}
