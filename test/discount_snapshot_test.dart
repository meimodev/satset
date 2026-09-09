// A queued discount must carry what the preset said, not just its id.
//
// The host prices a discount from `presetId`; the offline projection cannot —
// it has no catalogue — so a payload holding only the id projects `value: 0`.
// Observed on device: an offline 10% bill promo left Total unchanged at
// Rp 330.000, so the cashier would have collected in full off a bill the drain
// then discounted by Rp 33.000.
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/repositories/settlement_repository.dart';

void main() {
  const presets = [
    DiscountPresetDto(
      id: 'p10',
      name: 'QA10',
      scope: 'bill',
      kind: 'percent',
      value: 1000,
    ),
    DiscountPresetDto(
      id: 'p5k',
      name: 'QA5K',
      scope: 'line',
      kind: 'fixed',
      value: 5000,
    ),
  ];

  test('a snapshot carries the fields the projection prices from', () {
    expect(discountSnapshot('p10', presets), {
      'name': 'QA10',
      'kind': 'percent',
      'value': 1000,
    });
    expect(discountSnapshot('p5k', presets), {
      'name': 'QA5K',
      'kind': 'fixed',
      'value': 5000,
    });
  });

  test('an unknown preset snapshots nothing rather than guessing', () {
    expect(discountSnapshot('gone', presets), isEmpty);
    expect(discountSnapshot('p10', const []), isEmpty);
  });
}
