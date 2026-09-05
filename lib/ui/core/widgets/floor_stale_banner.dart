import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/floor_cache.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Says, once per screen, that the floor on it is a **[[Salinan lantai]]** and
/// not the venue (ADR-0133).
///
/// One banner, not a stamp per tile: it is a single fact about the whole
/// screen, and twenty timestamps on twenty table tiles is noise on the surface
/// that has to survive a half-second glance.
///
/// Renders nothing unless both halves are true — the paint came from the copy
/// *and* the host is away. A handset that was running when the host died holds
/// live state and must not be told it is stale.
///
/// It is deliberately absent from the menu, whose staleness is the frozen
/// sold-out flag: a banner over a menu that is 99% right teaches the waiter to
/// dismiss the banner on the two screens where it means something.
class FloorStaleBanner extends ConsumerWidget {
  const FloorStaleBanner({super.key, this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(wsConnStateProvider) == WsConnState.open;
    if (online) return const SizedBox.shrink();

    return ValueListenableBuilder<DateTime?>(
      valueListenable: ref.read(floorCacheProvider).restoredAt,
      builder: (context, syncedAt, _) =>
          syncedAt == null ? const SizedBox.shrink() : _banner(context, syncedAt),
    );
  }

  Widget _banner(BuildContext context, DateTime syncedAt) {
    final sc = context.sat;
    return Container(
      margin:
          margin ??
          const EdgeInsets.only(left: Sp.s5, right: Sp.s5, bottom: Sp.s3),
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.warnSoft,
        borderRadius: SatR.a(12),
        border: SatB.all(color: sc.warn.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 14, color: sc.warn),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              context.l10n.floorStaleBanner(formatStampShort(syncedAt)),
              style: SatType.bodyS(color: sc.warn),
            ),
          ),
        ],
      ),
    );
  }
}
