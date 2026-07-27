import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/skin.dart';

void main() {
  // The skin is a global read by ~800 migrated call sites; leaking `brutal`
  // into a later test would silently square every other widget test's corners.
  tearDown(() {
    SatShape.skin = SatSkin.lembut;
    SatShape.ink = const Color(0xFF000000);
    SatShape.brightness = Brightness.dark;
  });

  group('lembut (default)', () {
    test('shape helpers are pass-throughs', () {
      expect(SatR.a(14), BorderRadius.circular(14));
      expect(SatR.c(22), const Radius.circular(22));
      expect(SatB.all(color: const Color(0xFF112233)).top.width, 1.0);
      expect(SatB.side(width: 1.5).width, 1.5);
    });

    test('cards are not lifted', () {
      final d = SatBox.d(
        color: const Color(0xFF000000),
        border: SatB.all(),
        borderRadius: SatR.a(14),
      );
      expect(d.boxShadow, isNull);
    });

    test('caps leaves copy alone', () {
      expect(SatShape.caps('Kirim ke dapur'), 'Kirim ke dapur');
    });

    test('floating chrome stays translucent', () {
      expect(
        SatShape.veil(const Color(0xFF1C1F23), 0.92).a,
        closeTo(0.92, 0.01),
      );
    });
  });

  group('brutal', () {
    setUp(() {
      SatShape.skin = SatSkin.brutal;
      SatShape.ink = const Color(0xFF000000);
    });

    test('every corner squares', () {
      expect(SatR.a(14), BorderRadius.zero);
      expect(SatR.a(999), BorderRadius.zero);
      expect(SatR.c(28), Radius.zero);
    });

    test('every rule fattens to 3px, colour untouched', () {
      final b = SatB.all(color: const Color(0xFF112233), width: 0.5);
      expect(b.top.width, SatShape.brutalBorder);
      expect(b.top.color, const Color(0xFF112233));
      expect(SatB.side(width: 1.5).width, SatShape.brutalBorder);
    });

    test('a zero width stays off, not fattened', () {
      // `width: mine ? 2 : 0` is a switch. Fattening the off state would draw
      // nothing (the colour is transparent) but still inset the child.
      expect(SatB.all(width: 0).top.width, 0);
      expect(SatB.side(width: 0).width, 0);
    });

    test('a filled, bordered, rounded rectangle is a card and gets lifted', () {
      final d = SatBox.d(
        color: const Color(0xFFFFFFFF),
        border: SatB.all(),
        borderRadius: SatR.a(14),
      );
      expect(d.boxShadow, hasLength(1));
      expect(d.boxShadow!.single.color, const Color(0xFF000000));
      expect(d.boxShadow!.single.offset, const Offset(3, 3));
      expect(d.boxShadow!.single.blurRadius, 0);
    });

    test('the lift heuristic leaves everything else flat', () {
      const white = Color(0xFFFFFFFF);
      // Round status dot — the source design explicitly kills its shadow.
      expect(
        SatBox.d(
          color: white,
          border: SatB.all(),
          borderRadius: SatR.a(99),
          shape: BoxShape.circle,
        ).boxShadow,
        isNull,
      );
      // Full-bleed chrome: a rule, no corner radius, so no shadow.
      expect(SatBox.d(color: white, border: SatB.all()).boxShadow, isNull);
      // Plain fill, no border.
      expect(
        SatBox.d(color: white, borderRadius: SatR.a(14)).boxShadow,
        isNull,
      );
      // An explicit shadow always wins.
      const own = [BoxShadow(color: Color(0xFFFF0000))];
      expect(
        SatBox.d(
          color: white,
          border: SatB.all(),
          borderRadius: SatR.a(14),
          boxShadow: own,
        ).boxShadow,
        own,
      );
    });

    test('a decoration with no fill of its own is never lifted', () {
      // Regression: `_HubCard` takes its surface from an ancestor Material and
      // passes border + radius only. Lifting it painted a solid ink slab over
      // the whole card — the shadow is drawn under a fill that never came.
      expect(
        SatBox.d(border: SatB.all(), borderRadius: SatR.a(16)).boxShadow,
        isNull,
      );
      // A gradient counts as a fill.
      expect(
        SatBox.d(
          gradient: const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFFFFFFFF)],
          ),
          border: SatB.all(),
          borderRadius: SatR.a(16),
        ).boxShadow,
        hasLength(1),
      );
    });

    test('ink drives the shadow, so midnight inverts for free', () {
      SatShape.ink = const Color(0xFFF2ECD8);
      final d = SatBox.d(
        color: const Color(0xFF22212C),
        border: SatB.all(),
        borderRadius: SatR.a(14),
      );
      expect(d.boxShadow!.single.color, const Color(0xFFF2ECD8));
    });

    test('caps shouts', () {
      expect(SatShape.caps('Kirim ke dapur'), 'KIRIM KE DAPUR');
    });

    test('floating chrome goes fully opaque — no frosted glass', () {
      const scrim = Color(0xFF1A1922);
      expect(SatShape.veil(scrim, 0.92), scrim);
    });
  });

  group('SatTheme.adopt publishes the skin', () {
    test('neo palettes go brutal and hand their ink to the shadow', () {
      SatTheme.neoKertas.adopt();
      expect(SatShape.brutal, isTrue);
      expect(SatShape.ink, SatColors.neoKertas.border0);
      expect(SatShape.ink, const Color(0xFF000000));

      SatTheme.neoMidnight.adopt();
      expect(SatShape.brutal, isTrue);
      expect(SatShape.ink, const Color(0xFFF2ECD8));
    });

    test('only the paper neo palette fills chrome with the accent', () {
      // The rail, the logo block and the active nav tab all invert across
      // these two — see neo.css §7 and its `[data-neo="midnight"]` block.
      SatTheme.neoKertas.adopt();
      expect(SatShape.brightness, Brightness.light);
      expect(SatShape.brutalPaper, isTrue);

      SatTheme.neoMidnight.adopt();
      expect(SatShape.brightness, Brightness.dark);
      expect(SatShape.brutalPaper, isFalse);

      // A soft light palette is not "paper" — brutalPaper gates shape, not hue.
      SatTheme.indigoTerang.adopt();
      expect(SatShape.brightness, Brightness.light);
      expect(SatShape.brutalPaper, isFalse);
    });

    test('switching back to a soft palette restores round corners', () {
      SatTheme.neoKertas.adopt();
      SatTheme.amberGelap.adopt();
      expect(SatShape.brutal, isFalse);
      expect(SatR.a(14), BorderRadius.circular(14));
    });

    test('every palette declares the skin its colours were drawn for', () {
      const expected = {
        SatTheme.amberGelap: SatSkin.lembut,
        SatTheme.amberTerang: SatSkin.lembut,
        SatTheme.indigoTerang: SatSkin.lembut,
        SatTheme.neoKertas: SatSkin.brutal,
        SatTheme.neoMidnight: SatSkin.brutal,
        SatTheme.neonGelap: SatSkin.glow,
        SatTheme.neonTerang: SatSkin.glow,
      };
      // Exhaustive by construction: a new theme that forgets to pick a side
      // fails here rather than silently inheriting `lembut`.
      expect(expected.keys, unorderedEquals(SatTheme.values));
      for (final t in SatTheme.values) {
        expect(t.skin, expected[t], reason: t.name);
      }
    });
  });

  test('neo borders are fully opaque — the ramp draws with ink, not tint', () {
    for (final sc in [SatColors.neoKertas, SatColors.neoMidnight]) {
      for (final c in [sc.border0, sc.border1, sc.border2]) {
        expect(c.a, 1.0);
      }
      expect(sc.border0, sc.border1);
      expect(sc.border1, sc.border2);
    }
  });
}
