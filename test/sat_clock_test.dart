// The clock seam's contract: it shifts domain time, it keeps running, and it
// never touches the real clock the security paths read.
//
// See docs/adr/0053-organic-demo-data-and-the-demo-clock.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/time/sat_clock.dart';

void main() {
  tearDown(SatClock.clear);

  test('is real time until a demo offset is adopted', () {
    expect(SatClock.isShifted, isFalse);
    final drift = SatClock.now().difference(DateTime.now()).abs();
    expect(drift.inSeconds, lessThan(2));
  });

  test('anchoring pins now to the anchor, then runs forward', () async {
    final anchor = DateTime.now().subtract(const Duration(days: 3));
    SatClock.anchorTo(anchor);

    expect(SatClock.now().difference(anchor).abs().inSeconds, lessThan(2));

    // Re-anchor-then-run, not frozen: time still advances (ADR-0053 §1).
    // A frozen clock would make every counter in the app visibly dead.
    final first = SatClock.now();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(SatClock.now().isAfter(first), isTrue);
  });

  test('realNow ignores the offset — the security carve-out', () {
    SatClock.anchorTo(DateTime.now().subtract(const Duration(days: 30)));
    // Auth, pairing and TLS read realNow. If the offset leaked into it, a
    // token minted during a demo would outlive its stated expiry.
    final skew = SatClock.realNow().difference(DateTime.now()).abs();
    expect(skew.inSeconds, lessThan(2));
    expect(
      SatClock.realNow().difference(SatClock.now()).inDays,
      greaterThanOrEqualTo(29),
    );
  });

  test('clear returns to real time', () {
    SatClock.anchorTo(DateTime.now().subtract(const Duration(days: 5)));
    expect(SatClock.isShifted, isTrue);
    SatClock.clear();
    expect(SatClock.isShifted, isFalse);
    expect(SatClock.offset, Duration.zero);
  });
}
