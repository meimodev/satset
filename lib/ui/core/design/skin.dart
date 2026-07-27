import 'package:flutter/material.dart';

/// The shape language a palette speaks.
///
/// `lembut` is the original soft look: rounded corners, hairline translucent
/// rules, no drop shadows. `brutal` is the neo-brutalist skin: every corner
/// square, every rule a fat solid ink line, every card lifted on a hard
/// un-blurred offset shadow.
///
/// Shape is picked by the palette rather than toggled separately — the neo
/// colours (siren yellow on cream, solid-ink borders) only read correctly with
/// square corners and fat rules, and the reverse holds too. One choice in the
/// existing theme picker, no second setting to explain.
enum SatSkin { lembut, brutal }

/// Live shape tokens for the selected skin.
///
/// Read as plain statics rather than through a `ThemeExtension` because the
/// call sites are ~800 `BorderRadius` / `Border` / `BoxDecoration` literals,
/// many of them inside static widget helpers with no `BuildContext` in scope.
/// Threading a context into all of them buys nothing this app can use.
class SatShape {
  SatShape._();

  // ponytail: one mutable global, written once per theme build by `satTheme()`
  // before any descendant builds. The skin is device-local and only changes
  // through the theme picker, so there is no second writer. If two skins ever
  // need to render side by side (a theme preview grid), promote this to an
  // InheritedWidget and thread context through the helpers below.
  static SatSkin skin = SatSkin.lembut;

  /// The colour of rules and hard shadows in [SatSkin.brutal] — near-black on
  /// the paper palette, bone on midnight. Mirrors the palette's `border0`,
  /// which the neo palettes define as fully opaque ink.
  static Color ink = const Color(0xFF000000);

  /// Brightness of the adopted palette. Brutal chrome inverts across it and
  /// the neutral ramp cannot express the swap: the paper rail is a siren slab
  /// carrying an ink logo, midnight's is a dark slab carrying a siren one
  /// (neo.css §7 and its `[data-neo="midnight"]` overrides).
  static Brightness brightness = Brightness.dark;

  static bool get brutal => skin == SatSkin.brutal;

  /// Brutal on a light ground — the palette that fills chrome with the accent
  /// itself rather than a surface from the ramp.
  static bool get brutalPaper => brutal && brightness == Brightness.light;

  /// Fat rule width. Neo draws every border at 3px regardless of what the
  /// call site asked for; hairlines and 1.5px check pips both flatten to it.
  static const double brutalBorder = 3;

  /// Hard offset shadow. No blur, no spread — a solid ink slab shifted down
  /// and right, which is the whole trick.
  static List<BoxShadow> hardShadow([double offset = 3]) => [
    BoxShadow(color: ink, offset: Offset(offset, offset), blurRadius: 0),
  ];

  /// Tint for floating chrome that sits over scrolling content — the tab bar,
  /// the cart footer. The soft skin lets the content ghost through; the brutal
  /// one does not do frosted glass, so the surface goes fully opaque and the
  /// caller drops its blur.
  static Color veil(Color c, double alpha) =>
      brutal ? c : c.withValues(alpha: alpha);

  /// Uppercases display and label copy under the brutal skin. Indonesian has
  /// no casing rules this breaks, and the neo type ramp is uppercase-only.
  static String caps(String s) => brutal ? s.toUpperCase() : s;
}

/// Skin-aware corner radii. Every radius collapses to zero under
/// [SatSkin.brutal]; under `lembut` these are pass-throughs.
class SatR {
  SatR._();

  static BorderRadius a(double r) =>
      BorderRadius.circular(SatShape.brutal ? 0 : r);

  static Radius c(double r) => Radius.circular(SatShape.brutal ? 0 : r);
}

/// Skin-aware borders. Under [SatSkin.brutal] every side snaps to
/// [SatShape.brutalBorder]; the colour still comes from the palette, whose
/// `border*` tokens are already solid ink in the neo palettes.
class SatB {
  SatB._();

  /// A zero width is a call site switching the border *off* (`width: mine ? 2 :
  /// 0`), not asking for a thin one — fattening it to 3px would draw nothing
  /// visible while still insetting the child. Everything else snaps to the fat
  /// rule.
  static double _w(double width) =>
      SatShape.brutal && width > 0 ? SatShape.brutalBorder : width;

  static Border all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    double strokeAlign = BorderSide.strokeAlignInside,
  }) {
    return Border.all(
      color: color,
      width: _w(width),
      style: style,
      strokeAlign: strokeAlign,
    );
  }

  static BorderSide side({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    double strokeAlign = BorderSide.strokeAlignInside,
  }) {
    return BorderSide(
      color: color,
      width: _w(width),
      style: style,
      strokeAlign: strokeAlign,
    );
  }
}

/// Skin-aware [BoxDecoration]. Identical to the constructor under `lembut`;
/// under `brutal` it lifts bordered cards onto a hard shadow.
class SatBox {
  SatBox._();

  static BoxDecoration d({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape shape = BoxShape.rectangle,
  }) {
    // ponytail: heuristic, not a per-widget decision — a decoration that paints
    // its own fill and draws a border *and* a corner radius on a rectangle is a
    // card, and cards are what the neo skin lifts. Full-bleed chrome (border, no
    // radius) keeps its rule with no shadow, and round status dots stay flat,
    // which is exactly what the source design does. A call site that wants
    // something else passes its own boxShadow and this leaves it alone.
    //
    // The fill check is not cosmetic. A hard shadow is an unblurred solid rect
    // offset by (3,3), painted *under* the fill — so a decoration that borrows
    // its surface from an ancestor Material (border and radius only, no colour)
    // would render as a solid ink slab with the real content nowhere in sight.
    // Those cards stay flat; wrong beats invisible.
    final lift =
        SatShape.brutal &&
        boxShadow == null &&
        (color != null || gradient != null) &&
        border != null &&
        borderRadius != null &&
        shape == BoxShape.rectangle;
    return BoxDecoration(
      color: color,
      image: image,
      border: border,
      borderRadius: borderRadius,
      boxShadow: lift ? SatShape.hardShadow() : boxShadow,
      gradient: gradient,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
    );
  }
}
