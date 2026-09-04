// The compact rupiah a report tile carries.
//
// Pinned because ADR-0130 introduced the first KPI that can go negative
// (`netAfterExpense`, a venue that spent on a party before its bill closed) and
// every threshold in the formatter is `>=` — a negative fell through to the
// plain arm and printed an ungrouped `Rp -70000` beside a row of `Rp 70rb`
// tiles. Found on a device.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

void main() {
  late AppL10n id;
  late AppL10n en;

  setUpAll(() async {
    id = await AppL10n.delegate.load(const Locale('id'));
    en = await AppL10n.delegate.load(const Locale('en'));
  });

  test('the compact arms are unchanged', () {
    expect(formatCompactIDR(id, 0), formatCompactIDR(id, 0));
    expect(formatCompactIDR(id, 70000), contains('70'));
    expect(formatCompactIDR(id, 2500000), contains('2.5'));
  });

  test('a negative is the positive with a sign, not a raw number', () {
    for (final l in [id, en]) {
      for (final v in [70000, 999, 2500000]) {
        expect(
          formatCompactIDR(l, -v),
          '-${formatCompactIDR(l, v)}',
          reason: 'a negative tile must render in the same shape as a positive',
        );
      }
      // The specific regression: never the ungrouped integer.
      expect(formatCompactIDR(l, -70000), isNot(contains('70000')));
    }
  });
}
