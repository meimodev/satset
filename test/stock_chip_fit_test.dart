import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/features/admin/stock_screen.dart';

/// The 2-line cap on recipe-link chips in the stock card. Chips are 100 wide
/// with a 10 gap here, so a 340-wide row holds exactly 3 per line.
void main() {
  int fit(int count, {double maxWidth = 340, double overflowWidth = 60}) =>
      fitChipCount(
        List.filled(count, 100),
        maxWidth: maxWidth,
        overflowWidth: overflowWidth,
        gap: 10,
        maxLines: 2,
      );

  test('everything fitting in two lines shows every chip', () {
    expect(fit(6), 6);
    expect(fit(1), 1);
    expect(fit(0), 0);
  });

  test('overflow reserves room for the +N chip on the last line', () {
    // Without the reserve line 2 would hold 3; the 60-wide "+N" costs one slot.
    expect(fit(7), 5);
  });

  test('always leaves at least one chip hidden when it truncates', () {
    expect(fit(7), lessThan(7));
  });

  test('a chip wider than the row still occupies its own line', () {
    expect(
      fitChipCount(
        [500, 500, 500],
        maxWidth: 340,
        overflowWidth: 60,
        gap: 10,
        maxLines: 2,
      ),
      2,
    );
  });
}
