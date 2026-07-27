import 'package:flutter/material.dart';

/// The shape language a palette speaks.
///
/// `lembut` is the original soft look: rounded corners, hairline translucent
/// rules, no drop shadows. `brutal` is the neo-brutalist skin: every corner
/// square, every rule a fat solid ink line, every card lifted on a hard
/// un-blurred offset shadow. `glow` is the third: generous radii, no rules at
/// all, cards floating on a soft ambient lift, and full-bleed obsidian slabs
/// stacked against a bone ground (ADR-0050).
///
/// Shape is picked by the palette rather than toggled separately — the neo
/// colours (siren yellow on cream, solid-ink borders) only read correctly with
/// square corners and fat rules, and the reverse holds too. One choice in the
/// existing theme picker, no second setting to explain.
enum SatSkin { lembut, brutal, glow }

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

  static bool get glow => skin == SatSkin.glow;

  static bool get lembut => skin == SatSkin.lembut;

  /// Brutal on a light ground — the palette that fills chrome with the accent
  /// itself rather than a surface from the ramp.
  static bool get brutalPaper => brutal && brightness == Brightness.light;

  /// Glow on a dark ground. The mirror of [brutalPaper], and needed in the same
  /// places: the brand mark, rail avatars and the active category tab all fill
  /// with lime on obsidian here and invert on the light palette (ADR-0050).
  static bool get glowNoir => glow && brightness == Brightness.dark;

  /// Fat rule width. Neo draws every border at 3px regardless of what the
  /// call site asked for; hairlines and 1.5px check pips both flatten to it.
  static const double brutalBorder = 3;

  /// The lifting shadow for a card, per skin.
  ///
  /// Brutal: a hard offset slab. No blur, no spread — a solid ink rect shifted
  /// down and right, which is the whole trick. Glow: a soft ambient shadow,
  /// which under a skin that draws no rules is the *only* thing separating a
  /// card from its ground. Lembut: nothing, as before.
  ///
  /// Named `hardShadow` still because ten call sites reach it directly and the
  /// brutal reading is the one they were written for; renaming it would churn
  /// them for no gain.
  static List<BoxShadow> hardShadow([double offset = 3]) {
    switch (skin) {
      case SatSkin.brutal:
        return [
          BoxShadow(color: ink, offset: Offset(offset, offset), blurRadius: 0),
        ];
      case SatSkin.glow:
        return lift;
      case SatSkin.lembut:
        return const [];
    }
  }

  /// Glow's resting card shadow. Darker and heavier on the obsidian palette —
  /// a 7% ink shadow that reads on bone is invisible on near-black.
  static List<BoxShadow> get lift => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x1208080A)
          : const Color(0x73000000),
      offset: const Offset(0, 6),
      blurRadius: 18,
    ),
  ];

  /// Glow's shadow for something floating clear of the page — a modal, a sheet,
  /// a drawer, the action panel.
  static List<BoxShadow> get liftLg => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x2908080A)
          : const Color(0x99000000),
      offset: Offset(0, brightness == Brightness.light ? 20 : 24),
      blurRadius: brightness == Brightness.light ? 50 : 60,
    ),
  ];

  /// Tint for floating chrome that sits over scrolling content — the tab bar,
  /// the cart footer. The soft skin lets the content ghost through; neither the
  /// brutal nor the glow skin does frosted glass, so the surface goes fully
  /// opaque and the caller drops its blur. Glow separates it with [liftLg]
  /// instead, which has to fall outside the clip a blur would need anyway.
  static Color veil(Color c, double alpha) =>
      brutal || glow ? c : c.withValues(alpha: alpha);

  /// Uppercases display and label copy under the brutal skin. Indonesian has
  /// no casing rules this breaks, and the neo type ramp is uppercase-only.
  static String caps(String s) => brutal ? s.toUpperCase() : s;
}

/// Skin-aware corner radii. Every radius collapses to zero under
/// [SatSkin.brutal] and steps up onto Glow's coarser ramp under [SatSkin.glow];
/// under `lembut` these are pass-throughs.
class SatR {
  SatR._();

  /// Glow's ramp is `12 / 16 / 20 / 26 / 32 / pill` — coarser than the app's,
  /// and starting higher. This maps onto it, total and monotone, so every
  /// output is a real token: a flat multiplier would land on 19.6.
  ///
  /// The `< 8` passthrough is load-bearing. Those call sites are status pips,
  /// check marks and meter bars rather than corners — inflating them rounds
  /// away the shapes they exist to draw.
  static double _glow(double r) {
    if (r >= 999) return r;
    if (r >= 28) return 32;
    if (r >= 20) return 26;
    if (r >= 14) return 20;
    if (r >= 8) return 16;
    return r;
  }

  static double _r(double r) => switch (SatShape.skin) {
    SatSkin.brutal => 0,
    SatSkin.glow => _glow(r),
    SatSkin.lembut => r,
  };

  static BorderRadius a(double r) => BorderRadius.circular(_r(r));

  static Radius c(double r) => Radius.circular(_r(r));
}

/// Skin-aware borders. Under [SatSkin.brutal] every side snaps to
/// [SatShape.brutalBorder]; the colour still comes from the palette, whose
/// `border*` tokens are already solid ink in the neo palettes.
///
/// Under [SatSkin.glow] this is a pure passthrough, and deliberately so. Glow
/// draws no rules — but its own border ramp is already α 0.05/0.09/0.14, the
/// same range as the hairline it *does* keep on chrome. So the palette carries
/// "no borders" and 268 call sites stay untouched. Border colour is a palette
/// decision; border width is a skin decision (ADR-0050).
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
    //
    // Glow lifts the same set, with a soft ambient shadow instead of the ink
    // slab. The fill check matters less there — a blurred 7% shadow under a
    // borrowed surface is merely wrong, not opaque — but the heuristic is kept
    // identical so both skins lift exactly the same widgets.
    final lift =
        (SatShape.brutal || SatShape.glow) &&
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
