import 'package:flutter/material.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';

/// **Laporan ringkas** — the one-page close (ADR-0109, switch `ringkasReport`).
///
/// Nine sections is restaurant-grade. The person closing a counter shop at
/// 22:15 wants the handful of numbers that decide whether they can go home:
/// what came in, how many bills, what the average was, what sold, and whether
/// the cash box agrees with the ledger.
///
/// A **layout**, not a computation. Every number here is already in
/// [ReportsSnapshotDto] — nothing new is asked of the server, and the two
/// derived figures (the average bill, the variance sign) are arithmetic on
/// numbers the full sections already show. That is deliberate: a compact view
/// that computed its own totals would be a second place for the report to
/// disagree with itself.
///
/// It does not *replace* the sections — it leads them. The tab strip below is
/// untouched and every full section is one tap away, because "ringkas" is a
/// default, not a permission.
class ReportRingkas extends StatelessWidget {
  const ReportRingkas({super.key, required this.snapshot});

  final ReportsSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sc = context.sat;

    // The `net` tile is the report's own headline and carries its counts in
    // `args` (sessions, covers) — read from there rather than recounted, so
    // this card cannot drift from the section under it.
    final net = snapshot.sales.kpis
        .where((k) => k.key == 'net')
        .firstOrNull;
    final revenue = net?.rupiah ?? 0;
    final sessions = (net?.args.isNotEmpty ?? false) ? net!.args[0] : 0;
    final covers = (net?.args.length ?? 0) > 1 ? net!.args[1] : 0;
    final avg = sessions == 0 ? 0 : revenue ~/ sessions;

    final kas = snapshot.kas;
    final top = snapshot.menu.top.take(5).toList();

    return SatCard.titled(
      title: l10n.rptRingkasTitle,
      tag: l10n.rptRingkasTag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sp.s5,
            runSpacing: Sp.s3,
            children: [
              _Num(label: l10n.rptRingkasRevenue, value: formatIDR(revenue)),
              _Num(label: l10n.rptRingkasBills, value: '$sessions'),
              _Num(label: l10n.rptRingkasCovers, value: '$covers'),
              _Num(label: l10n.rptRingkasAvg, value: formatIDR(avg)),
            ],
          ),
          const SizedBox(height: Sp.s4),
          // The cash line, with its own colour. A variance is the one number on
          // this card that is a *question* rather than a result, so it reads as
          // one — neutral when the box agrees, warn when it does not.
          Row(
            children: [
              Icon(
                Icons.savings_outlined,
                size: 16,
                color: kas.variance == 0 ? sc.textLo : sc.warn,
              ),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: Text(
                  kas.variance == 0
                      ? l10n.rptRingkasKasOk(formatIDR(kas.closing))
                      : l10n.rptRingkasKasOff(
                          formatIDR(kas.closing),
                          formatIDR(kas.variance.abs()),
                        ),
                  style: SatType.bodyS(
                    color: kas.variance == 0 ? sc.textLo : sc.warn,
                  ),
                ),
              ),
            ],
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: Sp.s4),
            Text(
              l10n.rptRingkasTop.toUpperCase(),
              style: SatType.monoS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s2),
            for (final r in top)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s1),
                child: Row(
                  children: [
                    SizedBox(
                      width: Sp.s9,
                      child: Text(
                        '${r.qty}×',
                        style: SatType.monoS(color: sc.accent),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.name,
                        style: SatType.bodyS(color: sc.textHi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatIDR(r.revenue),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
        const SizedBox(height: Sp.sHair),
        Text(value, style: SatType.monoL(color: sc.textHi)),
      ],
    );
  }
}
