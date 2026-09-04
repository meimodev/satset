// A venue's handsets all lose the socket at the same instant — the server is a
// tablet, and it rebooted. An undithered exponential backoff then brings every
// one of them back on the same tick, forever, hammering the one device that
// also has to serve the floor.
//
// The fix is jitter, and the thing worth pinning is that jitter did not quietly
// break the two properties the backoff already promised: it still grows, and it
// still has a ceiling.
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/services/ws_client.dart';

void main() {
  group('backoffFor', () {
    test('grows with the attempt', () {
      // At a fixed roll the jitter is a constant factor, so the shape of the
      // curve is what is being compared here, not the dither.
      var last = Duration.zero;
      for (var i = 0; i <= 6; i++) {
        final d = WsClient.backoffFor(i, roll: 1);
        expect(d, greaterThan(last), reason: 'attempt $i did not grow');
        last = d;
      }
    });

    test('never exceeds the 10s ceiling, however long the outage runs', () {
      for (var i = 0; i <= 40; i++) {
        expect(
          WsClient.backoffFor(i, roll: 1),
          lessThanOrEqualTo(const Duration(seconds: 10)),
        );
      }
    });

    test('never drops below a floor worth waiting for', () {
      // The 200ms minimum exists so the top bar does not flicker between
      // reconnecting and offline. Halving it at roll 0 would put it at 100ms,
      // which is why the floor is asserted at the jittered value.
      for (var i = 0; i <= 40; i++) {
        expect(
          WsClient.backoffFor(i, roll: 0).inMilliseconds,
          greaterThanOrEqualTo(100),
        );
      }
    });

    test('jitter only ever pulls a retry earlier', () {
      // Subtractive on purpose: the ceiling and the `relocateAfter` timing
      // claim in the doc both stay true only if nothing waits *longer*.
      const attempt = 6;
      final ceiling = WsClient.backoffFor(attempt, roll: 1);
      expect(ceiling, const Duration(seconds: 10));
      expect(WsClient.backoffFor(attempt, roll: 0), const Duration(seconds: 5));
    });

    test('two handsets on the same attempt do not land on the same tick', () {
      // The whole point. Fifty devices, same outage, same attempt number.
      final spread = {
        for (var i = 0; i < 50; i++) WsClient.backoffFor(6).inMilliseconds,
      };
      expect(
        spread.length,
        greaterThan(1),
        reason: 'undithered backoff is the thundering herd this prevents',
      );
    });
  });

  test('the handshake budget sits between the keepalive and the kernel', () {
    // The bug this pins: `channel.ready` had no timeout, so a connect started
    // while the interface was half-up blocked on the OS connect timeout
    // (~110s) instead of failing. Nothing schedules a reconnect while that
    // attempt hangs, so the 10s backoff ceiling is not what the user waits —
    // two stalled handshakes was four minutes of OFFLINE on a LAN that came
    // back at second one.
    expect(
      WsClient.handshakeTimeout,
      greaterThan(const Duration(seconds: 5)),
      reason:
          'a budget at or under the keepalive would cut short a handshake that '
          'is merely slow, on the congested Wi-Fi where it is most needed',
    );
    expect(
      WsClient.handshakeTimeout,
      lessThan(const Duration(seconds: 30)),
      reason: 'the whole point is to give up long before the kernel does',
    );
  });
}
