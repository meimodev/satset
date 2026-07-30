import 'package:flutter/material.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/service_timing.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// One line's ready target: the item's own `Waktu siap` if it has one, else the
/// venue default. The single resolution every elapsed surface goes through, so
/// a pill, a KDS card and the audible cue cannot disagree (ADR-0043).
int lineTargetMins(WidgetRef ref, String itemId) => resolvePrepMins(
  ref.watch(prepTimeByItemProvider)[itemId],
  ref.watch(venueSettingsProvider).prepTargetMins,
);

/// Shared 30s heartbeat for live elapsed pills. autoDispose so the stream
/// stops whenever no pill is mounted. 30s keeps minute-granularity labels
/// fresh without rebuilding dense boards every second.
final elapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => SatClock.now(),
  ),
);

/// "How long the kitchen has owned this line." Ticks live while the line is
/// active; once it's terminal (served / voided) we have no end stamp on the
/// Ticket, so the pill freezes to the static sent clock instead of an
/// ever-growing number. Active pills escalate to the urgent color at the line's
/// own resolved target so the board agrees with the KDS, the audio cue and the
/// report. See docs/adr/0013 and ADR-0043.
class ElapsedPill extends ConsumerWidget {
  /// Where the kitchen clock starts: `firedAt ?? sentAt`. A held course counts
  /// from its fire, never from the guest's order — passing `sentAtTime` here
  /// would show a course as overdue before the kitchen was even given it.
  final DateTime clockStart;

  /// Pre-formatted clock string (e.g. "14:32") shown when frozen.
  final String sentAtClock;

  /// True for served / voided lines: stop ticking, show the sent clock.
  final bool terminal;

  /// This line's resolved ready target in minutes:
  /// `resolvePrepMins(item.prepTime, venue.prepTargetMins)`.
  final int targetMins;

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
    required this.clockStart,
    required this.sentAtClock,
    required this.terminal,
    required this.targetMins,
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
    final d = SatClock.now().difference(clockStart);
    final overdue = d.inMinutes >= targetMins;
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: Sp.s1),
      decoration: SatBox.d(color: bg, borderRadius: SatR.a(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: Sp.s1),
          Text(label, style: SatType.caption(color: fg)),
        ],
      ),
    );
  }
}
