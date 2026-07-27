import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/admin_grace.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Shell-level warning shown on a Server-mode device that has gone
/// offline-stale: it counts down the [AdminGrace] before the embedded server
/// would refuse to start on the next restart, so the admin reconnects in time.
/// Renders nothing when online / in range. See CONTEXT.md "Offline grace
/// period".
class AdminGraceBanner extends ConsumerWidget {
  const AdminGraceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grace = ref.watch(adminOfflineGraceProvider).valueOrNull;
    if (grace == null) return const SizedBox.shrink();

    final sc = context.sat;
    final critical = grace.critical;
    final fg = critical ? sc.urgent : sc.warn;
    final bg = critical ? sc.urgentSoft : sc.warnSoft;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: bg,
        borderRadius: SatR.a(12),
        border: SatB.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            critical ? Icons.lock_clock_rounded : Icons.wifi_off_rounded,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              _message(grace.remaining),
              style: SatType.sans(size: 12, weight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  String _message(Duration rem) {
    if (rem <= Duration.zero) {
      return 'Server akan terkunci saat aplikasi dimulai ulang — '
          'sambungkan internet sekarang untuk verifikasi admin.';
    }
    if (rem <= const Duration(hours: 24)) {
      return 'Tanpa internet, server terkunci dalam ${rem.inHours} jam. '
          'Segera sambungkan.';
    }
    return 'Tanpa internet, server terkunci dalam ${rem.inDays} hari. '
        'Sambungkan untuk verifikasi admin.';
  }
}
