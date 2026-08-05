// The two heartbeats behind every live time display (ADR-0081).
//
// The minute ticker's whole reason for existing is that it fires *on* the
// boundary rather than one period after whoever subscribed first. A
// Stream.periodic(60s) would pass a naive "does it emit" test and still report
// every threshold in the app up to 59s late, on a different offset per device.
//
// That "when" lives in `alignmentDelay`, a pure function, and is tested as one
// — a widget test cannot check it, because `tester.pump` advances timers while
// `DateTime.now()` stands still.
//
// Nothing here re-tests that `Stream.periodic` emits once per period, or that
// autoDispose cancels a timer: the first is Dart's contract and the second is
// enforced for free by the framework's pending-timer assertion in every widget
// test that mounts a ticker. tables_rebuild_test.dart exercises the real
// stream against a real widget.
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/core/state/tickers.dart';

void main() {
  group('alignmentDelay', () {
    final boundary = DateTime(2026, 8, 5, 18, 39);

    test('waits out only the remainder of the current minute', () {
      expect(
        alignmentDelay(
          boundary.add(const Duration(seconds: 45)),
          const Duration(minutes: 1),
        ),
        const Duration(seconds: 15),
      );
      expect(
        alignmentDelay(
          boundary.add(const Duration(seconds: 59, milliseconds: 900)),
          const Duration(minutes: 1),
        ),
        const Duration(milliseconds: 100),
      );
    });

    test('a full period on an exact boundary, never zero', () {
      // Zero would spin the stream. Every offset must land in (0, period].
      for (final ms in [0, 1, 250, 999, 1000, 59999, 60000]) {
        final d = alignmentDelay(
          boundary.add(Duration(milliseconds: ms)),
          const Duration(minutes: 1),
        );
        expect(d, greaterThan(Duration.zero), reason: 'at +${ms}ms');
        expect(d, lessThanOrEqualTo(const Duration(minutes: 1)));
      }
      expect(
        alignmentDelay(boundary, const Duration(minutes: 1)),
        const Duration(minutes: 1),
      );
    });

    test('seconds align to the second, not the minute', () {
      expect(
        alignmentDelay(
          boundary.add(const Duration(seconds: 45, milliseconds: 700)),
          const Duration(seconds: 1),
        ),
        const Duration(milliseconds: 300),
      );
    });
  });
}
