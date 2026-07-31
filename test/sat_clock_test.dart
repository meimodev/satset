// The clock seam's contract: it shifts domain time, it keeps running, and it
// never touches the real clock the security paths read.
//
// The shipped offset is always zero (ADR-0073 removed the demo clock), so what
// is pinned here is the seam's behaviour under a test that travels in time —
// which is the only caller left, and the reason the seam survives.
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/time/sat_clock.dart';

void main() {
  tearDown(SatClock.clear);

  test('is real time until an offset is adopted', () {
    expect(SatClock.offset, Duration.zero);
    final drift = SatClock.now().difference(DateTime.now()).abs();
    expect(drift.inSeconds, lessThan(2));
  });

  test('an adopted offset shifts now, and time keeps running', () async {
    SatClock.adopt(const Duration(days: -3));

    final anchor = DateTime.now().subtract(const Duration(days: 3));
    expect(SatClock.now().difference(anchor).abs().inSeconds, lessThan(2));

    // Shifted, not frozen: time still advances. A frozen clock would make
    // every counter in the app visibly dead.
    final first = SatClock.now();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(SatClock.now().isAfter(first), isTrue);
  });

  test('realNow ignores the offset — the security carve-out', () {
    SatClock.adopt(const Duration(days: -30));
    // Auth, pairing and TLS read realNow. If the offset leaked into it, a
    // token minted under a shifted clock would outlive its stated expiry.
    final skew = SatClock.realNow().difference(DateTime.now()).abs();
    expect(skew.inSeconds, lessThan(2));
    expect(
      SatClock.realNow().difference(SatClock.now()).inDays,
      greaterThanOrEqualTo(29),
    );
  });

  test('clear returns to real time', () {
    SatClock.adopt(const Duration(days: -5));
    expect(SatClock.offset, isNot(Duration.zero));
    SatClock.clear();
    expect(SatClock.offset, Duration.zero);
  });
}
