class Sp {
  Sp._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
}

// `Radii` lived here and had no callers — every corner in the app was a literal.
// Removed rather than left to rot: a shape token that ignores the active skin is
// worse than none. Use `SatR` in design/skin.dart (ADR-0047).
