// Silence the shared clock heartbeats in a widget test.
//
// The tickers are live periodic streams (ADR-0081). Harmless on a device; in a
// widget test they outlive the tree — an autoDispose provider tears down after
// the framework's pending-timer check, where the hand-rolled Timers they
// replaced cancelled during State.dispose. Any test that mounts a widget
// reading a clock (SatAppBar, ElapsedPill, TableCard, the KDS, MeScreen) needs
// these overrides.
//
// Widgets read the clock on build regardless, so overriding the stream costs a
// test nothing: pass a value with SatClock.adopt to control what it sees.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/state/tickers.dart';

/// Both heartbeats, stubbed to never fire.
List<Override> get tickerOverrides => [
  secondTickerProvider.overrideWith((ref) => const Stream<DateTime>.empty()),
  minuteTickerProvider.overrideWith((ref) => const Stream<DateTime>.empty()),
];
