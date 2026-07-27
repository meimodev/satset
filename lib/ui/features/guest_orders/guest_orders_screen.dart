import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/guest_orders_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Staff review queue for guest self-orders (ADR-0028). Each pending batch
/// shows the table + lines with one-tap Approve (→ kitchen) / Reject (→ void).
class GuestOrdersScreen extends ConsumerWidget {
  const GuestOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final batches = ref.watch(guestOrdersProvider);
    return Scaffold(
      backgroundColor: sc.bg1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Pesanan Mandiri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: sc.textHi,
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  if (batches.isNotEmpty)
                    _Badge(count: batches.length, color: sc.urgent),
                  const Spacer(),
                  IconButton(
                    tooltip: AppStrings.a11yRefresh,
                    icon: Icon(Icons.refresh, color: sc.textMd),
                    onPressed: () =>
                        ref.read(guestOrdersProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: batches.isEmpty
                  ? _empty(sc)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: batches.length,
                      itemBuilder: (_, i) => _BatchCard(batch: batches[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(SatColors sc) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_2, size: 48, color: sc.textDim),
        const SizedBox(height: Sp.s3),
        Text(
          'Belum ada pesanan mandiri',
          style: TextStyle(color: sc.textLo, fontSize: 15),
        ),
      ],
    ),
  );
}

class _BatchCard extends ConsumerWidget {
  const _BatchCard({required this.batch});
  final GuestOrderBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s3h),
      decoration: SatBox.d(
        color: sc.bg0,
        borderRadius: SatR.a(14),
        border: SatB.all(color: sc.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(Icons.table_restaurant, size: 18, color: sc.accentText),
                const SizedBox(width: Sp.s2),
                Text(
                  'Meja ${batch.tableLabel}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: sc.textHi,
                  ),
                ),
                const Spacer(),
                Text(
                  _ago(batch.submittedAt),
                  style: TextStyle(color: sc.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          ...batch.lines.map(
            (l) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${l.qty}×',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sc.textMd,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.variantName.isEmpty
                              ? l.name
                              : '${l.name} · ${l.variantName}',
                          style: TextStyle(color: sc.textHi, fontSize: 14.5),
                        ),
                        if (l.modifierLabels.isNotEmpty)
                          Text(
                            l.modifierLabels.join(', '),
                            style: TextStyle(color: sc.textLo, fontSize: 12.5),
                          ),
                        if (l.note.isNotEmpty)
                          Text(
                            '“${l.note}”',
                            style: TextStyle(
                              color: sc.warn,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Sp.s2),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: SatButton.danger(
                    label: 'Tolak',
                    onTap: () => ref
                        .read(guestOrdersProvider.notifier)
                        .reject(batch.visitId),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Expanded(
                  flex: 2,
                  child: SatButton.success(
                    label: 'Setujui & Kirim ke Dapur',
                    onTap: () => ref
                        .read(guestOrdersProvider.notifier)
                        .approve(batch.visitId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = SatClock.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
    return '${d.inHours} jam lalu';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: Sp.sHair),
    decoration: SatBox.d(color: color, borderRadius: SatR.a(10)),
    child: Text(
      '$count',
      style: SatType.sans(
        size: 13,
        weight: FontWeight.w700,
        color: onFill(color),
      ),
    ),
  );
}
