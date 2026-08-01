import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/features/auth/views/pin_screen.dart';

/// The PIN screen's Admin/Staff switcher sizes its sliding pill from the
/// `LayoutBuilder` width, and that width is `0` on the frame before the parent
/// has been laid out — which made the raw `(maxWidth - 4) / 2` negative and
/// threw `BoxConstraints has a negative minimum width` on every debug boot.
void main() {
  test('an unlaid-out parent yields zero, not a negative width', () {
    // The reported crash exactly: (0 - 4) / 2 == -2.0.
    expect(modeSwitcherPillWidth(0), 0);
    // Anything narrower than the gutter is still a real constraint.
    expect(modeSwitcherPillWidth(4), 0);
    expect(modeSwitcherPillWidth(2), 0);
  });

  test('a laid-out parent still splits the width in half, less the gutter', () {
    expect(modeSwitcherPillWidth(404), 200);
    expect(modeSwitcherPillWidth(360), 178);
  });

  test('the two pills plus the gutter never exceed the track', () {
    for (final w in [0.0, 4.0, 100.0, 360.0, 720.0, 1920.0]) {
      expect(modeSwitcherPillWidth(w) * 2 + 4, lessThanOrEqualTo(w + 4));
    }
  });
}
