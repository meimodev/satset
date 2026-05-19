import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme() {
    return GoogleFonts.beVietnamProTextTheme().copyWith(
      displayLarge: GoogleFonts.notoSerif(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.02,
      ),
      headlineLarge: GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.0,
      ),
    );
  }
}
