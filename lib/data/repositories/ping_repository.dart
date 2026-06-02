import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/api_client.dart';

class PingState {
  /// Round-trip of the most recent successful probe.
  final Duration? latest;

  /// Median of the last 10 probes; null until at least one probe succeeded.
  final Duration? p50;

  /// True when the most recent probe completed within the timeout.
  final bool reachable;

  /// Number of consecutive failed probes (resets to 0 on a success).
  final int consecutiveFailures;

  const PingState({
    this.latest,
    this.p50,
    this.reachable = false,
    this.consecutiveFailures = 0,
  });

  PingState copyWith({
    Duration? latest,
    Duration? p50,
    bool? reachable,
    int? consecutiveFailures,
  }) =>
      PingState(
        latest: latest ?? this.latest,
        p50: p50 ?? this.p50,
        reachable: reachable ?? this.reachable,
        consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      );
}

class PingRepository extends StateNotifier<PingState> {
  PingRepository({required this.ref}) : super(const PingState()) {
    _start();
  }

  final Ref ref;
  final Queue<int> _samples = Queue<int>();
  Timer? _timer;
  static const _windowSize = 10;
  static const _interval = Duration(seconds: 5);
  static const _timeout = Duration(seconds: 3);

  void _start() {
    // Run an immediate probe so the UI doesn't sit at "--" for 5s on open.
    unawaited(_probe());
    _timer = Timer.periodic(_interval, (_) => unawaited(_probe()));
  }

  /// Forces an out-of-band probe right now instead of waiting for the next 5s
  /// tick. Used when the staff PIN sheet opens so the reachability pill reflects
  /// the current connection, not a heartbeat sample up to [_interval] stale.
  Future<void> recheck() => _probe();

  Future<void> _probe() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      state = state.copyWith(reachable: false);
      return;
    }
    final sw = Stopwatch()..start();
    try {
      await ref
          .read(apiClientProvider)
          .getJson('/healthz')
          .timeout(_timeout);
      if (!mounted) return;
      final ms = sw.elapsedMilliseconds;
      _samples.addLast(ms);
      while (_samples.length > _windowSize) {
        _samples.removeFirst();
      }
      final sorted = List<int>.from(_samples)..sort();
      final p50ms = sorted[(sorted.length * 0.5)
          .floor()
          .clamp(0, sorted.length - 1)];
      state = PingState(
        latest: Duration(milliseconds: ms),
        p50: Duration(milliseconds: p50ms),
        reachable: true,
        consecutiveFailures: 0,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        reachable: false,
        consecutiveFailures: state.consecutiveFailures + 1,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pingProvider =
    StateNotifierProvider.autoDispose<PingRepository, PingState>(
        (ref) => PingRepository(ref: ref));

/// One-shot derived providers used by the System screen tiles.
final kdsStationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final cfg = ref.watch(apiConfigProvider);
  if (cfg == null) return const [];
  final raw = await ref.read(apiClientProvider).getJson('/kds/stations') as List;
  return [
    for (final e in raw) (e as Map).cast<String, dynamic>(),
  ];
});

final queueDepthProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final cfg = ref.watch(apiConfigProvider);
  if (cfg == null) return const {'total': 0, 'byStation': <String, int>{}};
  final raw = await ref.read(apiClientProvider).getJson('/queue/depth');
  return (raw as Map).cast<String, dynamic>();
});
