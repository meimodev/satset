import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Shared 30s heartbeat for live elapsed pills. autoDispose so the stream
/// stops whenever no pill is mounted. 30s keeps minute-granularity labels
/// fresh without rebuilding dense boards every second.
final elapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  ),
);

/// "How long since this line was sent to the kitchen." Ticks live while the
/// line is active; once it's terminal (served / voided) we have no end stamp
/// on the Ticket, so the pill freezes to the static sent clock instead of an
/// ever-growing number. Active pills escalate to the urgent color at the
/// venue's 10-minute overdue line so the board agrees with the floor + audio.
class ElapsedPill extends ConsumerWidget {
  /// When the line was sent to the kitchen — the elapsed anchor.
  final DateTime sentAtTime;

  /// Pre-formatted clock string (e.g. "14:32") shown when frozen.
  final String sentAtClock;

  /// True for served / voided lines: stop ticking, show the sent clock.
  final bool terminal;

  /// Minutes since send at which the pill turns urgent.
  static const _overdueMinutes = 10;

  /// Minute-granularity label: "<1m", "8m", "1j 5m". No seconds — the 30s
  /// ticker would make a seconds field jitter.
  static String _short(Duration d) {
    if (d.isNegative || d.inMinutes < 1) return '<1m';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}j ${m}m' : '${m}m';
  }

  const ElapsedPill({
    super.key,
    required this.sentAtTime,
    required this.sentAtClock,
    required this.terminal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;

    if (terminal) {
      return _pill(
        context,
        icon: Icons.access_time,
        label: sentAtClock,
        fg: sc.textLo,
        bg: sc.bg3,
      );
    }

    // Live: rebuild on each heartbeat so the elapsed label stays current.
    ref.watch(elapsedTickerProvider);
    final d = DateTime.now().difference(sentAtTime);
    final overdue = d.inMinutes >= _overdueMinutes;
    return _pill(
      context,
      icon: overdue ? Icons.timer_outlined : Icons.access_time,
      label: _short(d),
      fg: overdue ? sc.urgent : sc.textLo,
      bg: overdue ? sc.urgentSoft : sc.bg3,
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: SatType.mono(
              size: 10,
              weight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
