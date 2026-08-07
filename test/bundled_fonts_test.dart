import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:yaml/yaml.dart';

/// The default skin has to render with no network — a venue installs the APK
/// on a LAN with no WAN and the first launch must not fall back to Roboto.
/// This fails if the faces stop being bundled, or if a role starts resolving
/// through `google_fonts` again.
void main() {
  tearDown(() => SatTheme.fallback.adopt());

  test('the fresh-device default still carries the bundled skin', () {
    // If this moves, the family assertions below are guarding the wrong skin.
    expect(SatTheme.fallback.skin, SatSkin.glow);
  });

  test('the default skin resolves to the bundled Archivo', () {
    SatTheme.fallback.adopt();
    expect(SatType.sans().fontFamily, 'Archivo');
    expect(SatType.mono().fontFamily, 'Archivo');
    // display() falls through to sans() off the brutal skin.
    expect(SatType.display().fontFamily, 'Archivo');
    // One variable file, so the weight rides the wght axis, not a static cut.
    expect(
      SatType.sans(weight: FontWeight.w800).fontVariations,
      contains(const FontVariation('wght', 800)),
    );
  });

  test('the amber themes resolve to the bundled Plex', () {
    SatShape.skin = SatSkin.lembut;
    expect(SatType.sans().fontFamily, 'IBM Plex Sans');
    expect(SatType.mono().fontFamily, 'IBM Plex Mono');
  });

  test('the brutal skin resolves to its bundled faces', () {
    SatShape.skin = SatSkin.brutal;
    expect(SatType.sans().fontFamily, 'Archivo');
    expect(SatType.mono().fontFamily, 'DM Mono');
    expect(SatType.display().fontFamily, 'Archivo Black');
    // Single-weight face: passing a weight through would ask Flutter to
    // synthesise one, which is the smear the display ramp cannot have.
    expect(SatType.display(weight: FontWeight.w400).fontWeight, isNull);
  });

  test('no role reaches for the network', () {
    final src = File('lib/ui/core/design/typography.dart').readAsStringSync();
    expect(src, isNot(contains('GoogleFonts')));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains(RegExp(r'^\s+google_fonts:', multiLine: true))),
    );
  });

  test('every declared font asset is on disk', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final families = (pubspec['flutter']['fonts'] as YamlList)
        .map((f) => f['family'] as String)
        .toSet();
    expect(families, containsAll(['IBM Plex Sans', 'IBM Plex Mono']));

    final assets = (pubspec['flutter']['fonts'] as YamlList).expand(
      (f) => (f['fonts'] as YamlList).map((v) => v['asset'] as String),
    );
    expect(assets, isNotEmpty);
    for (final a in assets) {
      expect(
        File(a).existsSync(),
        isTrue,
        reason: '$a is declared but missing',
      );
    }
  });
}
