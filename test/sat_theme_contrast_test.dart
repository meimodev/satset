import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/core/design/sat_theme.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Text-bearing pairs only (ADR-0045). The semantic hues were tuned for a
  // charcoal ground and are reused verbatim in the light themes, where they are
  // decorative rather than accessible — asserting them here would fail against
  // already-shipped colours. Fixing that is its own change.
  group('every SatTheme keeps text legible', () {
    for (final t in SatTheme.values) {
      test('${t.name} clears WCAG AA on text pairs', () {
        final c = t.colors;
        expect(_contrast(c.textHi, c.bg0), greaterThanOrEqualTo(4.5),
            reason: '${t.name}: textHi on bg0');
        expect(_contrast(c.textMd, c.bg1), greaterThanOrEqualTo(4.5),
            reason: '${t.name}: textMd on bg1');
        expect(_contrast(c.accentInk, c.accent), greaterThanOrEqualTo(4.5),
            reason: '${t.name}: accentInk on accent');
        expect(_contrast(c.successInk, c.success), greaterThanOrEqualTo(4.5),
            reason: '${t.name}: successInk on success');
      });
    }
  });

  test('theme keys round-trip and unknown keys fall back', () {
    for (final t in SatTheme.values) {
      expect(SatTheme.fromKey(t.name), t);
    }
    expect(SatTheme.fromKey(null), SatTheme.fallback);
    expect(SatTheme.fromKey('satset.no_such_theme'), SatTheme.fallback);
  });
}
