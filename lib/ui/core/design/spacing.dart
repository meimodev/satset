/// The spacing scale.
///
/// A 4px grid with half-steps below 20. The half-steps are not a compromise —
/// they were already in the code 428 times before they had names. A chip with
/// 10px type does not have room for an 8px inset without the glyphs touching
/// the border, and 12 makes it read as a button. The grid is right for layout;
/// small components need the finer notch.
///
/// Above 20 the grid is pure: at that size a 2px difference is not a decision
/// anyone is making on purpose, so there is nothing to name.
///
/// The scale stops at 48. A number larger than that is a dimension — a panel
/// width, a sheet height, a tile — not spacing, and naming it here would only
/// invite the wrong ones to be reached for. The guard test draws the same
/// line.
class Sp {
  Sp._();

  /// Hair gap. Between two stacked lines of text that belong together — a name
  /// over its role, a value over its label. Not for layout.
  static const double sHair = 2;

  static const double s1 = 4;
  static const double s1h = 6;
  static const double s2 = 8;
  static const double s2h = 10;
  static const double s3 = 12;
  static const double s3h = 14;
  static const double s4 = 16;
  static const double s4h = 18;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s9 = 36;
  static const double s10 = 40;
  static const double s12 = 48;
}

// `Radii` lived here and had no callers — every corner in the app was a literal.
// Removed rather than left to rot: a shape token that ignores the active skin is
// worse than none. Use `SatR` in design/skin.dart (ADR-0047).
