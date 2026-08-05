/// The app's two clock heartbeats.
///
/// Every live time display in SatSet falls into exactly one of two kinds, and
/// conflating them is what had five ad-hoc timers rebuilding whole screens for
/// a digit nobody acts on:
///
/// - **Readout** — a number on screen that moves every second and that nothing
///   branches on. The KDS station timer ("8:42"), the seated counter
///   ("12m 20d"), the shift counter. Watch [secondTickerProvider], and watch it
///   from the smallest widget that renders the digits.
/// - **Threshold** — state that *changes* when the clock crosses a boundary:
///   a table going [[Basi]], a batch turning late, an overdue tint, a progress
///   ring. Every one of these compares `.inMinutes` against a venue setting, so
///   its value can only change when the wall clock flips a minute. Watch
///   [minuteTickerProvider].
///
/// **The rule: if you branch on it, watch the minute ticker.** A body that
/// watches [secondTickerProvider] to keep a threshold fresh does 59 rebuilds a
/// minute for one that mattered.
///
/// See docs/adr/0081-two-tickers-readout-and-threshold.md.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/time/sat_clock.dart';

/// Emits on each wall-clock second boundary.
///
/// For readouts only — see the library doc. autoDispose, so no timer runs when
/// nothing is on screen that shows seconds.
final secondTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => _alignedTicks(const Duration(seconds: 1)),
);

/// Emits at :00 of each wall-clock minute.
///
/// Aligned rather than periodic, which is the whole point: a plain
/// `Stream.periodic(60s)` starts its period when the first widget subscribes,
/// so a threshold crossing at 12:05:00 surfaces at some arbitrary offset into
/// the minute — up to 59s late, and a different amount late on every device.
/// Aligning means a `.inMinutes` comparison is re-evaluated exactly when its
/// answer can change: never late, never redundant.
final minuteTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => _alignedTicks(const Duration(minutes: 1)),
);

/// How long from [now] until the next boundary of [period].
///
/// Always in `(0, period]` — on an exact boundary the answer is a full period,
/// never zero, so nothing built on this can spin.
@visibleForTesting
Duration alignmentDelay(DateTime now, Duration period) {
  final past = now.microsecondsSinceEpoch % period.inMicroseconds;
  return period - Duration(microseconds: past);
}

/// Ticks on each boundary of [period], measured against [SatClock].
///
/// Waits out the first partial period, then runs on a plain periodic timer.
///
/// ponytail: aligning once rather than re-deriving the delay every tick. The
/// re-deriving version resynchronises after a device sleeps or a clock jumps,
/// which sounds strictly better and is not: it assumes the wall clock and the
/// timer advance together, and under `tester.pump` they do not — timers move,
/// `DateTime.now()` does not, and the stream spins. That divergence would make
/// every rebuild-count test in the app unwritable. The ceiling here is timer
/// drift over a long uptime; if a shift ever shows a visibly late threshold,
/// re-align periodically against [alignmentDelay] instead of going back to the
/// per-tick derivation.
Stream<DateTime> _alignedTicks(Duration period) async* {
  await Future<void>.delayed(alignmentDelay(SatClock.now(), period));
  yield SatClock.now();
  yield* Stream<DateTime>.periodic(period, (_) => SatClock.now());
}
