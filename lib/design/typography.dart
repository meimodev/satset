import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SatType {
  SatType._();

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextTheme buildTextTheme(Color textHi, Color textMd) {
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

  static Color textLow(Color textMd) => textMd;
}
