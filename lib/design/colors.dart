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
    required this.accentSoft,
    required this.accentBorder,
    required this.accentInk,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.warnSoft,
    required this.urgent,
    required this.urgentSoft,
    required this.info,
    required this.infoSoft,
    required this.violet,
    required this.violetSoft,
    required this.cDrinks,
    required this.cStarters,
    required this.cMains,
    required this.cDesserts,
    required this.cFire,
  });

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
  final Color accentSoft;
  final Color accentBorder;
  final Color accentInk;
  final Color success;
  final Color successSoft;
  final Color warn;
  final Color warnSoft;
  final Color urgent;
  final Color urgentSoft;
  final Color info;
  final Color infoSoft;
  final Color violet;
  final Color violetSoft;
  final Color cDrinks;
  final Color cStarters;
  final Color cMains;
  final Color cDesserts;
  final Color cFire;

  static const _accent = Color(0xFFFF9233);
  static const _accentInk = Color(0xFF160D04);
  static const _success = Color(0xFF4DD487);
  static const _warn = Color(0xFFFFC04D);
  static const _urgent = Color(0xFFFF5C5C);
  static const _info = Color(0xFF6DB5FF);
  static const _violet = Color(0xFFC08AFF);

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
    accentSoft: Color(0x24FF9233),
    accentBorder: Color(0x59FF9233),
    accentInk: _accentInk,
    success: _success,
    successSoft: Color(0x244DD487),
    warn: _warn,
    warnSoft: Color(0x24FFC04D),
    urgent: _urgent,
    urgentSoft: Color(0x24FF5C5C),
    info: _info,
    infoSoft: Color(0x246DB5FF),
    violet: _violet,
    violetSoft: Color(0x24C08AFF),
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
    accentSoft: Color(0x24FF9233),
    accentBorder: Color(0x59FF9233),
    accentInk: _accentInk,
    success: _success,
    successSoft: Color(0x244DD487),
    warn: _warn,
    warnSoft: Color(0x24FFC04D),
    urgent: _urgent,
    urgentSoft: Color(0x24FF5C5C),
    info: _info,
    infoSoft: Color(0x246DB5FF),
    violet: _violet,
    violetSoft: Color(0x24C08AFF),
    cDrinks: _info,
    cStarters: _warn,
    cMains: _success,
    cDesserts: _violet,
    cFire: _accent,
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
    Color? accentSoft,
    Color? accentBorder,
    Color? accentInk,
    Color? success,
    Color? successSoft,
    Color? warn,
    Color? warnSoft,
    Color? urgent,
    Color? urgentSoft,
    Color? info,
    Color? infoSoft,
    Color? violet,
    Color? violetSoft,
    Color? cDrinks,
    Color? cStarters,
    Color? cMains,
    Color? cDesserts,
    Color? cFire,
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
      accentSoft: accentSoft ?? this.accentSoft,
      accentBorder: accentBorder ?? this.accentBorder,
      accentInk: accentInk ?? this.accentInk,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      urgent: urgent ?? this.urgent,
      urgentSoft: urgentSoft ?? this.urgentSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      violet: violet ?? this.violet,
      violetSoft: violetSoft ?? this.violetSoft,
      cDrinks: cDrinks ?? this.cDrinks,
      cStarters: cStarters ?? this.cStarters,
      cMains: cMains ?? this.cMains,
      cDesserts: cDesserts ?? this.cDesserts,
      cFire: cFire ?? this.cFire,
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
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentSoft: Color.lerp(urgentSoft, other.urgentSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      violetSoft: Color.lerp(violetSoft, other.violetSoft, t)!,
      cDrinks: Color.lerp(cDrinks, other.cDrinks, t)!,
      cStarters: Color.lerp(cStarters, other.cStarters, t)!,
      cMains: Color.lerp(cMains, other.cMains, t)!,
      cDesserts: Color.lerp(cDesserts, other.cDesserts, t)!,
      cFire: Color.lerp(cFire, other.cFire, t)!,
    );
  }
}

extension SatColorsX on BuildContext {
  SatColors get sat => Theme.of(this).extension<SatColors>()!;
}
