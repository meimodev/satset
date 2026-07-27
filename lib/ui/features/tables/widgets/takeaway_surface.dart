import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Active Bawa pulang visits (ADR-0026), behind the floor head's second
/// trigger. A sheet on both form factors — unlike the booking book there is
/// nothing here to compare against the floor grid, so it does not earn a
/// drawer that keeps the grid visible.
Future<void> openTakeawaySurface(BuildContext context) {
  final sc = context.sat;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: sc.bg1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
    ),
    builder: (ctx) => const SafeArea(child: _TakeawayList()),
  );
}

class _TakeawayList extends ConsumerWidget {
  const _TakeawayList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final visits = ref.watch(takeawayVisitsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: SatBox.d(color: sc.border1, borderRadius: SatR.a(2)),
            ),
          ),
          const SizedBox(height: Sp.s3h),
          Text(
            SatShape.caps(AppStrings.floorTakeaway),
            style: SatType.display(
              size: 18,
              weight: FontWeight.w700,
              color: sc.textHi,
            ),
          ),
          const SizedBox(height: Sp.s3),
          if (visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s5),
              child: Text(
                AppStrings.takeawayEmpty,
                style: SatType.sans(size: 13, color: sc.textMd),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visits.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                itemBuilder: (_, i) => _TakeawayRow(
                  visit: visits[i],
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/takeaway/${visits[i].id}');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TakeawayRow extends ConsumerWidget {
  final TakeawayVisit visit;
  final VoidCallback onTap;
  const _TakeawayRow({required this.visit, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tickets = ref.watch(ticketsProvider)[visit.id] ?? const <Ticket>[];
    final active = tickets
        .where((t) => t.status != TicketStatus.voided)
        .toList();
    final ready = tickets.any((t) => t.status == TicketStatus.ready);
    final live = tickets.any(
      (t) => t.status != TicketStatus.served && t.status != TicketStatus.voided,
    );

    final (statusLabel, statusColor) = visit.handedOver
        ? ('Diserahkan', sc.textMd)
        : ready
        ? ('Siap', sc.success)
        : live
        ? ('Diproses', sc.warn)
        : ('Selesai', sc.info);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: SatBox.d(
          color: ready ? sc.successSoft : sc.bg2,
          border: SatB.all(color: sc.border0),
          borderRadius: SatR.a(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(visit.label, style: SatType.monoM(color: sc.textHi)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (visit.guestName != null &&
                          visit.guestName!.isNotEmpty)
                        visit.guestName!,
                      '${active.length} item',
                    ].join(' · '),
                    style: SatType.sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: sc.textMd,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s1h,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: SatShape.brutal
                    ? statusColor
                    : statusColor.withValues(alpha: 0.15),
                borderRadius: SatR.a(6),
                border: SatShape.brutal
                    ? Border.all(color: SatShape.ink, width: 2)
                    : null,
              ),
              child: Text(
                SatShape.caps(statusLabel),
                style: SatType.sans(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: SatShape.brutal ? onFill(statusColor) : statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
