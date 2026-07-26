import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Horizontal strip of active takeaway (Bawa pulang) visits, rendered under the
/// Reservasi strip on the Floor. Tap a chip → the takeaway detail. Only shown
/// when there is at least one active takeaway. See ADR-0026.
class TakeawayStrip extends ConsumerWidget {
  final bool tablet;
  const TakeawayStrip({super.key, required this.tablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final visits = ref.watch(takeawayVisitsProvider);
    if (visits.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tablet ? 32 : 16, vertical: tablet ? 12 : 8),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 14, color: sc.textLo),
              const SizedBox(width: 6),
              Text('BAWA PULANG',
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: sc.textLo,
                  )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: SatBox.d(
                  color: sc.accent.withValues(alpha: 0.15),
                  borderRadius: SatR.a(4),
                ),
                child: Text('${visits.length} aktif',
                    style: SatType.mono(
                        size: 9,
                        weight: FontWeight.w600,
                        color: sc.accentText,
                        letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visits.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _TakeawayChip(
                visit: visits[i],
                onTap: () => context.push('/takeaway/${visits[i].id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TakeawayChip extends ConsumerWidget {
  final TakeawayVisit visit;
  final VoidCallback onTap;
  const _TakeawayChip({required this.visit, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tickets = ref.watch(ticketsProvider)[visit.id] ?? const [];
    final active =
        tickets.where((t) => t.status != TicketStatus.voided).toList();
    final ready = tickets.any((t) => t.status == TicketStatus.ready);
    final live = tickets.any((t) =>
        t.status != TicketStatus.served && t.status != TicketStatus.voided);

    final (statusLabel, statusColor) = visit.handedOver
        ? ('Diserahkan', sc.textMd)
        : ready
            ? ('Siap', sc.success)
            : live
                ? ('Diproses', sc.warn)
                : ('Selesai', sc.info);

    final bg = ready ? sc.success.withValues(alpha: 0.1) : sc.bg2;
    final border = ready ? sc.success.withValues(alpha: 0.4) : sc.border1;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: SatBox.d(
          color: bg,
          border: SatB.all(color: border),
          borderRadius: SatR.a(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(visit.label,
                    style: SatType.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: sc.textHi,
                        letterSpacing: 0.2)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: SatBox.d(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: SatR.a(3),
                  ),
                  child: Text(statusLabel,
                      style: SatType.mono(
                          size: 9,
                          weight: FontWeight.w600,
                          color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
                [
                  if (visit.guestName != null && visit.guestName!.isNotEmpty)
                    visit.guestName!,
                  '${active.length} item',
                ].join(' · '),
                style: SatType.sans(
                    size: 12, weight: FontWeight.w500, color: sc.textMd)),
          ],
        ),
      ),
    );
  }
}
