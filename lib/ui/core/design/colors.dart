import 'package:flutter/material.dart';

class SatColors extends ThemeExtension<SatColors> {
  const SatColors({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.border0,
    required this.border1,
    required this.border2,
    required this.textHi,
    required this.textMd,
    required this.textLo,
    required this.textDim,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.accentBorder,
    required this.accentInk,
    required this.success,
    required this.successSoft,
    required this.successInk,
    required this.warn,
    required this.warnSoft,
    required this.urgent,
    required this.urgentSoft,
    required this.info,
    required this.infoSoft,
    required this.violet,
    required this.violetSoft,
    required this.scrim,
    required this.cDrinks,
    required this.cStarters,
    required this.cMains,
    required this.cDesserts,
    required this.cFire,
    this.onHue,
    SatColors? slab,
  }) : _slab = slab;

  final Color bg0;
  final Color bg1;
  final Color bg2;
  final Color bg3;
  final Color bg4;
  final Color border0;
  final Color border1;
  final Color border2;
  final Color textHi;
  final Color textMd;
  final Color textLo;
  final Color textDim;
  final Color accent;

  /// The accent role drawn *as* text or an icon — a selected tab label, an
  /// active chip, a link-ish button. Mirrors [accent] in every palette whose
  /// accent is mid-luminance, and darkens where it is not: Neo Kertas' siren
  /// yellow is 1.3:1 on white, unreadable as a foreground while still being
  /// the right colour to *fill* with. Pair fills with [accentInk] instead.
  final Color accentText;
  final Color accentSoft;
  final Color accentBorder;
  final Color accentInk;
  final Color success;
  final Color successSoft;

  /// Ink for text/icons sitting *on* a filled [success] surface (badges,
  /// toggles, check pips). Declared per palette because a theme is free to
  /// darken [success] — see `glow`, whose forest green takes white.
  final Color successInk;
  final Color warn;
  final Color warnSoft;
  final Color urgent;
  final Color urgentSoft;
  final Color info;
  final Color infoSoft;
  final Color violet;
  final Color violetSoft;

  /// Opaque base for translucent overlays (floating bars, sheets scrims).
  /// Call sites apply their own alpha — this token only fixes *which* surface
  /// the overlay is tinted from, which differs per palette.
  final Color scrim;
  final Color cDrinks;
  final Color cStarters;
  final Color cMains;
  final Color cDesserts;
  final Color cFire;

  /// Fixed ink for text/icons on *any* solid semantic fill in this palette —
  /// a status pill, a role avatar, a badge. Null means "work it out from the
  /// fill's luminance", which is what [onFill] does and what every palette
  /// shipped before Glow: it is right whenever a palette's hues span both ends
  /// of the luminance range, as the Neo palettes' do.
  ///
  /// Glow declares it because its hues are deliberately uniform — all dark on
  /// the light palette, all bright on the dark one — and two of Glow Noir's
  /// (`urgent` #FF7A68, `info` #8E86FF) land just under the luminance cut and
  /// would take white ink against the design's obsidian. Read through [inkOn],
  /// never directly.
  final Color? onHue;

  /// The palette that content sitting on an obsidian/ink *slab* is drawn with.
  ///
  /// Glow's first grammar rule is slab stacking — a KDS ticket head, the ready
  /// toast, the sent overlay and the active category tab are full-bleed dark
  /// blocks on a light screen. CSS re-declares the hues inside that block with
  /// one scoped rule; Flutter has no cascade, so the inverted palette is named
  /// here instead. Every dark palette is its own slab palette, so call sites
  /// can read [slab] unconditionally.
  final SatColors? _slab;

  /// See [_slab]. Returns `this` unless the palette named an inverse.
  SatColors get slab => _slab ?? this;

  /// Ink for text or an icon sitting on a solid [fill] from this palette.
  /// Honours [onHue] when the palette declares one, else falls back to the
  /// luminance rule in [onFill].
  Color inkOn(Color fill) => onHue ?? onFill(fill);

  static const _accent = Color(0xFFFF9233);
  static const _accentInk = Color(0xFF160D04);

  /// Amber reads at 8:1 on charcoal and 2.2:1 on paper — the same hue cannot be
  /// a foreground in both. `light` burns it down until it clears AA on its own
  /// grounds; `dark` keeps the bright one. Fills use `_accent` in both.
  static const _accentTextOnPaper = Color(0xFFA34B00);
  static const _success = Color(0xFF4DD487);
  static const _warn = Color(0xFFFFC04D);
  static const _urgent = Color(0xFFFF5C5C);
  static const _info = Color(0xFF6DB5FF);
  static const _violet = Color(0xFFC08AFF);

  /// Near-black ink for palettes whose `success` is light enough to carry it.
  /// Not universal: `glow`'s forest green is dark and declares white instead,
  /// which is exactly why this is a per-palette token rather than a constant —
  /// the alternative is silently shipping unreadable badges.
  static const _onSuccessInk = Color(0xFF0A0A0A);

  static const dark = SatColors(
    bg0: Color(0xFF0D0E10),
    bg1: Color(0xFF15171A),
    bg2: Color(0xFF1C1F23),
    bg3: Color(0xFF24282D),
    bg4: Color(0xFF2E333A),
    border0: Color(0x0FFFFFFF),
    border1: Color(0x1AFFFFFF),
    border2: Color(0x29FFFFFF),
    textHi: Color(0xFFF4F3EE),
    textMd: Color(0xFFB6B2A6),
    textLo: Color(0xFF7E7A70),
    textDim: Color(0xFF565249),
    accent: _accent,
    accentText: _accent,
    accentSoft: Color(0x24FF9233),
    accentBorder: Color(0x59FF9233),
    accentInk: _accentInk,
    success: _success,
    successSoft: Color(0x244DD487),
    successInk: _onSuccessInk,
    warn: _warn,
    warnSoft: Color(0x24FFC04D),
    urgent: _urgent,
    urgentSoft: Color(0x24FF5C5C),
    info: _info,
    infoSoft: Color(0x246DB5FF),
    violet: _violet,
    violetSoft: Color(0x24C08AFF),
    scrim: Color(0xFF1C1F23),
    cDrinks: _info,
    cStarters: _warn,
    cMains: _success,
    cDesserts: _violet,
    cFire: _accent,
  );

  static const light = SatColors(
    bg0: Color(0xFFF6F4EF),
    bg1: Color(0xFFFFFFFF),
    bg2: Color(0xFFFAF8F3),
    bg3: Color(0xFFEFECE4),
    bg4: Color(0xFFE3DFD4),
    border0: Color(0x0D000000),
    border1: Color(0x17000000),
    border2: Color(0x29000000),
    textHi: Color(0xFF1A1A18),
    textMd: Color(0xFF55514A),
    textLo: Color(0xFF87837A),
    textDim: Color(0xFFB6B2A6),
    accent: _accent,
    accentText: _accentTextOnPaper,
    accentSoft: Color(0x24FF9233),
    accentBorder: Color(0x59FF9233),
    accentInk: _accentInk,
    success: _success,
    successSoft: Color(0x244DD487),
    successInk: _onSuccessInk,
    warn: _warn,
    warnSoft: Color(0x24FFC04D),
    urgent: _urgent,
    urgentSoft: Color(0x24FF5C5C),
    info: _info,
    infoSoft: Color(0x246DB5FF),
    violet: _violet,
    violetSoft: Color(0x24C08AFF),
    scrim: Color(0xFFFFFFFF),
    cDrinks: _info,
    cStarters: _warn,
    cMains: _success,
    cDesserts: _violet,
    cFire: _accent,
  );

  // ── Indigo Terang ─────────────────────────────────────────────────────────
  // Cool paper rather than the warm cream of `light`, so the two light themes
  // are told apart at a glance. `info` shifts to cyan (ADR-0045) so the indigo
  // accent is the only blue that means "primary".
  static const _indigoAccent = Color(0xFF3538CD);
  static const _indigoInfo = Color(0xFF0891B2);

  static const indigoTerang = SatColors(
    bg0: Color(0xFFF4F5F8),
    bg1: Color(0xFFFFFFFF),
    bg2: Color(0xFFFAFBFD),
    bg3: Color(0xFFE9EBF1),
    bg4: Color(0xFFDCDFE8),
    border0: Color(0x0D000000),
    border1: Color(0x17000000),
    border2: Color(0x29000000),
    textHi: Color(0xFF16181D),
    textMd: Color(0xFF4B4F5A),
    textLo: Color(0xFF7C818E),
    textDim: Color(0xFFAAAEB9),
    accent: _indigoAccent,
    accentText: _indigoAccent,
    accentSoft: Color(0x1A3538CD),
    accentBorder: Color(0x593538CD),
    accentInk: Color(0xFFFFFFFF),
    success: _success,
    successSoft: Color(0x244DD487),
    successInk: _onSuccessInk,
    warn: _warn,
    warnSoft: Color(0x24FFC04D),
    urgent: _urgent,
    urgentSoft: Color(0x24FF5C5C),
    info: _indigoInfo,
    infoSoft: Color(0x240891B2),
    violet: _violet,
    violetSoft: Color(0x24C08AFF),
    scrim: Color(0xFFFFFFFF),
    cDrinks: _indigoInfo,
    cStarters: _warn,
    cMains: _success,
    cDesserts: _violet,
    cFire: _indigoAccent,
  );

  // ── Neo Kertas ────────────────────────────────────────────────────────────
  // Neo-brutalist paper. Cream ground, siren yellow, and every rule a solid
  // black line — the ramp carries no translucency at all, because the skin
  // draws structure with 3px ink instead of tonal steps (see SatSkin).
  // Semantic hues are pushed to full saturation and used as *fills*, not 14%
  // tints, so a status block reads as a poster panel from across the room.
  static const _neoInk = Color(0xFF000000);
  static const _neoAccent = Color(0xFFFFE600);
  // Siren yellow is a fill colour only — 1.3:1 on white. This is the same
  // hue dragged down until it clears AA on bg0, bg1, bg2 and accentSoft.
  static const _neoAccentText = Color(0xFF6B5A00);

  static const neoKertas = SatColors(
    bg0: Color(0xFFE9E2CE),
    bg1: Color(0xFFFFFCF2),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFF1EADA),
    bg4: Color(0xFFE2D9C0),
    border0: _neoInk,
    border1: _neoInk,
    border2: _neoInk,
    textHi: _neoInk,
    textMd: Color(0xFF2E2C27),
    textLo: Color(0xFF5F5B51),
    textDim: Color(0xFF8E897C),
    accent: _neoAccent,
    accentText: _neoAccentText,
    accentSoft: Color(0xFFFFF27A),
    accentBorder: _neoInk,
    accentInk: _neoInk,
    success: Color(0xFF00B84A),
    successSoft: Color(0xFF7DFFAE),
    // The source design puts white on this green; at 2.6:1 it fails AA, so the
    // ramp's near-black ink stands in (7.9:1). Caught by
    // sat_theme_contrast_test — a "ready" badge is exactly the thing a waiter
    // reads at a glance and cannot afford to squint at.
    successInk: _onSuccessInk,
    warn: Color(0xFFFF8A00),
    warnSoft: Color(0xFFFFD24D),
    urgent: Color(0xFFFF1E0D),
    urgentSoft: Color(0xFFFFAEA6),
    info: Color(0xFF0B3BFF),
    infoSoft: Color(0xFFA8C0FF),
    violet: Color(0xFF8A1FFF),
    violetSoft: Color(0xFFD6B3FF),
    scrim: Color(0xFFFFFCF2),
    cDrinks: Color(0xFF0B3BFF),
    cStarters: Color(0xFFFF8A00),
    cMains: Color(0xFF00B84A),
    cDesserts: Color(0xFF8A1FFF),
    // Fire is the one course that borrows `urgent` rather than `accent` here:
    // siren yellow is the skin's default surface colour, so it can no longer
    // carry "fire this now" on its own.
    cFire: Color(0xFFFF1E0D),
  );

  // ── Neo Tengah Malam ──────────────────────────────────────────────────────
  // The same skin after dark: bone rules on near-black slabs. `border*` flips
  // from black to bone, so `SatShape.ink` — and every hard shadow with it —
  // inverts for free. Soft tints go *darker* than their base rather than
  // lighter, which is how a 14%-on-black tint would have read anyway.
  static const _neoBone = Color(0xFFF2ECD8);

  static const neoMidnight = SatColors(
    bg0: Color(0xFF121118),
    bg1: Color(0xFF1A1922),
    bg2: Color(0xFF22212C),
    bg3: Color(0xFF2E2D3A),
    bg4: Color(0xFF3C3B4B),
    border0: _neoBone,
    border1: _neoBone,
    border2: _neoBone,
    textHi: Color(0xFFFFFDF2),
    textMd: Color(0xFFCDC7B6),
    textLo: Color(0xFF9B9584),
    textDim: Color(0xFF6C6759),
    accent: _neoAccent,
    accentText: _neoAccent,
    accentSoft: Color(0xFF4A4200),
    accentBorder: _neoBone,
    accentInk: Color(0xFF0B0B0F),
    success: Color(0xFF00E85C),
    successSoft: Color(0xFF0B4F27),
    successInk: Color(0xFF0B0B0F),
    warn: Color(0xFFFFA51F),
    warnSoft: Color(0xFF4E3200),
    urgent: Color(0xFFFF3B29),
    urgentSoft: Color(0xFF5A0F09),
    info: Color(0xFF4C7BFF),
    infoSoft: Color(0xFF14235E),
    violet: Color(0xFFA85CFF),
    violetSoft: Color(0xFF33115E),
    scrim: Color(0xFF1A1922),
    // Course hues track this palette's own semantics rather than Neo Kertas's
    // — the paper blues and greens are far too dark to survive on bg0.
    cDrinks: Color(0xFF4C7BFF),
    cStarters: Color(0xFFFFA51F),
    cMains: Color(0xFF00E85C),
    cDesserts: Color(0xFFA85CFF),
    cFire: Color(0xFFFF3B29),
  );

  // ── Neon Gelap ────────────────────────────────────────────────────────────
  // The Glow skin after dark, and the palette Neon Hijau became: obsidian
  // ground, fluorescent lime, lavender secondary. Declared *before* `glow`
  // because the light palette points at this one as its slab palette, and a
  // `const` may only reference a `const` already in scope.
  //
  // Every hue here is bright — that uniformity is the point, and it is why the
  // palette can name a single `onHue` where the Neo palettes cannot. Two of
  // them (`urgent`, `info`) sit just under `onFill`'s luminance cut and would
  // otherwise take white ink where the design asks for obsidian.
  static const _glowLime = Color(0xFFE1FF0F);
  static const _glowObsidian = Color(0xFF08080A);
  static const _glowLavender = Color(0xFFCEC7FE);

  static const glowNoir = SatColors(
    bg0: _glowObsidian,
    bg1: Color(0xFF101013),
    bg2: Color(0xFF17171A),
    bg3: Color(0xFF202024),
    bg4: Color(0xFF2A2A2F),
    border0: Color(0x0FFFFFFF),
    border1: Color(0x1AFFFFFF),
    border2: Color(0x29FFFFFF),
    textHi: Color(0xFFFFFFFF),
    textMd: Color(0xFFB0B0AC),
    textLo: Color(0xFF9A9A93),
    textDim: Color(0xFF82827B),
    accent: _glowLime,
    accentText: _glowLime,
    accentSoft: Color(0x21E1FF0F),
    accentBorder: Color(0x59E1FF0F),
    accentInk: Color(0xFF0F1400),
    success: Color(0xFF3FD07C),
    successSoft: Color(0x293FD07C),
    successInk: _glowObsidian,
    warn: Color(0xFFF0A317),
    warnSoft: Color(0x29F0A317),
    urgent: Color(0xFFFF7A68),
    urgentSoft: Color(0x29FF7A68),
    info: Color(0xFF8E86FF),
    infoSoft: Color(0x29CEC7FE),
    violet: _glowLavender,
    violetSoft: Color(0x2ECEC7FE),
    scrim: Color(0xFF17171A),
    cDrinks: Color(0xFF8E86FF),
    cStarters: Color(0xFFF0A317),
    cMains: Color(0xFF3FD07C),
    cDesserts: _glowLavender,
    cFire: Color(0xFFFF7A68),
    onHue: _glowObsidian,
  );

  // ── Neon Terang ───────────────────────────────────────────────────────────
  // Glow on a light ground: bone-white base, the same fluorescent lime, and
  // hues tuned as *ink on white* rather than as glowing foregrounds. That
  // retune is why the palette needs `slab` — inside an obsidian block those
  // dark hues go muddy, so slab content re-reads them from `glowNoir`.
  //
  // The border ramp is deliberately near-invisible (α 0.05/0.09/0.14). The skin
  // separates with slab colour and a soft ambient lift, not with rules, so the
  // palette carries "no borders" rather than every call site asking for it.
  //
  // Lime is a fill colour only — 1.1:1 on white. `accentText` is the same hue
  // dragged to a dark olive that clears AA on bg0/bg1/bg2.
  static const glow = SatColors(
    bg0: Color(0xFFEEEFE0),
    bg1: Color(0xFFFFFFFF),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFF3F4EA),
    bg4: Color(0xFFE7E8DA),
    border0: Color(0x0D08080A),
    border1: Color(0x1708080A),
    border2: Color(0x2408080A),
    textHi: _glowObsidian,
    textMd: Color(0xFF56565E),
    textLo: Color(0xFF5F5F67),
    textDim: Color(0xFF74747C),
    accent: _glowLime,
    accentText: Color(0xFF4E5C00),
    accentSoft: Color(0x57E1FF0F),
    accentBorder: Color(0x1F08080A),
    accentInk: _glowObsidian,
    success: Color(0xFF146B33),
    successSoft: Color(0x1F146B33),
    successInk: Color(0xFFFFFFFF),
    warn: Color(0xFF8A5A00),
    warnSoft: Color(0x218A5A00),
    urgent: Color(0xFFA31D0C),
    urgentSoft: Color(0x1CA31D0C),
    info: Color(0xFF4F46E5),
    infoSoft: Color(0x1F4F46E5),
    violet: Color(0xFF5B45C7),
    violetSoft: Color(0x1F5B45C7),
    scrim: Color(0xFFFFFFFF),
    cDrinks: Color(0xFF4F46E5),
    cStarters: Color(0xFF8A5A00),
    cMains: Color(0xFF146B33),
    cDesserts: Color(0xFF5B45C7),
    cFire: Color(0xFFA31D0C),
    onHue: Color(0xFFFFFFFF),
    slab: glowNoir,
  );

  @override
  SatColors copyWith({
    Color? bg0,
    Color? bg1,
    Color? bg2,
    Color? bg3,
    Color? bg4,
    Color? border0,
    Color? border1,
    Color? border2,
    Color? textHi,
    Color? textMd,
    Color? textLo,
    Color? textDim,
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? accentBorder,
    Color? accentInk,
    Color? success,
    Color? successSoft,
    Color? successInk,
    Color? warn,
    Color? warnSoft,
    Color? urgent,
    Color? urgentSoft,
    Color? info,
    Color? infoSoft,
    Color? violet,
    Color? violetSoft,
    Color? scrim,
    Color? cDrinks,
    Color? cStarters,
    Color? cMains,
    Color? cDesserts,
    Color? cFire,
    Color? onHue,
    SatColors? slab,
  }) {
    return SatColors(
      bg0: bg0 ?? this.bg0,
      bg1: bg1 ?? this.bg1,
      bg2: bg2 ?? this.bg2,
      bg3: bg3 ?? this.bg3,
      bg4: bg4 ?? this.bg4,
      border0: border0 ?? this.border0,
      border1: border1 ?? this.border1,
      border2: border2 ?? this.border2,
      textHi: textHi ?? this.textHi,
      textMd: textMd ?? this.textMd,
      textLo: textLo ?? this.textLo,
      textDim: textDim ?? this.textDim,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      accentBorder: accentBorder ?? this.accentBorder,
      accentInk: accentInk ?? this.accentInk,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      successInk: successInk ?? this.successInk,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      urgent: urgent ?? this.urgent,
      urgentSoft: urgentSoft ?? this.urgentSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      violet: violet ?? this.violet,
      violetSoft: violetSoft ?? this.violetSoft,
      scrim: scrim ?? this.scrim,
      cDrinks: cDrinks ?? this.cDrinks,
      cStarters: cStarters ?? this.cStarters,
      cMains: cMains ?? this.cMains,
      cDesserts: cDesserts ?? this.cDesserts,
      cFire: cFire ?? this.cFire,
      onHue: onHue ?? this.onHue,
      slab: slab ?? _slab,
    );
  }

  @override
  SatColors lerp(ThemeExtension<SatColors>? other, double t) {
    if (other is! SatColors) return this;
    return SatColors(
      bg0: Color.lerp(bg0, other.bg0, t)!,
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      bg4: Color.lerp(bg4, other.bg4, t)!,
      border0: Color.lerp(border0, other.border0, t)!,
      border1: Color.lerp(border1, other.border1, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      textHi: Color.lerp(textHi, other.textHi, t)!,
      textMd: Color.lerp(textMd, other.textMd, t)!,
      textLo: Color.lerp(textLo, other.textLo, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successInk: Color.lerp(successInk, other.successInk, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentSoft: Color.lerp(urgentSoft, other.urgentSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      violetSoft: Color.lerp(violetSoft, other.violetSoft, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      cDrinks: Color.lerp(cDrinks, other.cDrinks, t)!,
      cStarters: Color.lerp(cStarters, other.cStarters, t)!,
      cMains: Color.lerp(cMains, other.cMains, t)!,
      cDesserts: Color.lerp(cDesserts, other.cDesserts, t)!,
      cFire: Color.lerp(cFire, other.cFire, t)!,
      // Neither of these interpolates. `onHue` is a binary choice of ink and a
      // half-blended grey is unreadable on both ends; `slab` is a whole palette.
      // Both snap at the midpoint, which is what `SatTheme` already does with
      // brightness for the same reason.
      onHue: t < 0.5 ? onHue : other.onHue,
      slab: t < 0.5 ? _slab : other._slab,
    );
  }
}

extension SatColorsX on BuildContext {
  SatColors get sat => Theme.of(this).extension<SatColors>()!;
}

/// Near-black used as ink on a light fill. Not part of the neutral ramp: the
/// ramp's `bg0` follows the active theme, and this must stay dark even when the
/// theme is light, because the *fill* underneath is what it has to contrast
/// with — not the page.
const Color _inkOnLight = Color(0xFF0B0B0F);

/// Foreground for text sitting on a saturated fill (status pill, owner chip,
/// brutal-skin badge).
// ponytail: computed rather than a token per semantic colour — six palettes ×
// four fills is 24 tokens to hand-tune, and luminance gets all of them right.
// Add an explicit `*Ink` token the day one of them looks wrong.
Color onFill(Color c) =>
    c.computeLuminance() > 0.45 ? _inkOnLight : const Color(0xFFFFFFFF);

/// A darker sibling of [c], for the far end of an avatar/badge gradient.
/// Blends toward black rather than reducing lightness so a saturated hue keeps
/// its identity instead of going muddy.
Color darken(Color c, [double amount = 0.36]) =>
    Color.alphaBlend(_inkOnLight.withValues(alpha: amount), c);

/// Dimming for a modal barrier. Deliberately not `scrim` — that token is an
/// *opaque* base for translucent surfaces to blend against, so using it here
/// paints the layer underneath out entirely. This one dims, and it dims dark on
/// every palette: a barrier that lightened on the light theme would stop
/// reading as "the thing behind is out of reach".
const Color satBarrier = Color(0x80000000);

/// Dimming laid over photography so a label stays legible whatever the image
/// does. Heavier than [satBarrier] — it competes with detail, not flat colour.
const Color satMediaScrim = Color(0xB3000000);

/// Chrome for a lightbox — the payment-proof viewer. Black, on every palette
/// and every skin, because the room's lighting and the app's own accent must
/// not tint a photo the cashier is reading an amount off. Paired with
/// [satMediaInk] for anything drawn on top of it.
const Color satMediaChrome = Color(0xFF000000);

/// Ink on [satMediaChrome].
const Color satMediaInk = Color(0xFFFFFFFF);

/// The quiet zone a QR code is printed on, and the ink of its modules. Not
/// themed and never themed: at charcoal the code stops scanning, and the
/// camera reading it belongs to a guest, not to this app.
const Color satQrQuiet = Color(0xFFFFFFFF);

/// Ambient shadow colour for lifted surfaces on the soft skin. The brutal skin
/// uses `SatShape.hardShadow` instead. Opacity belongs to the caller: a floating
/// tab bar sits higher than a chip and casts accordingly.
const Color satShadowInk = Color(0xFF000000);
