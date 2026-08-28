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
        for (var i = 0; i < 50; i++)
          WsClient.backoffFor(6).inMilliseconds,
      };
      expect(
        spread.length,
        greaterThan(1),
        reason: 'undithered backoff is the thundering herd this prevents',
      );
    });
  });
}
