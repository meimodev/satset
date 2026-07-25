import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';

/// The report's ingredient view: what was used, what was thrown away, what the
/// pantry is worth, and how far the counts drifted.
///
/// Variance rows come from `adjust` movements — the difference between what
/// recipes said should be on the shelf and what an opname actually found. They
/// are therefore **opname-anchored**: a row appears only where someone counted
/// inside this window (ADR-0038).
class ReportStockSection extends ConsumerWidget {
  const ReportStockSection({
    super.key,
    required this.rangeFrom,
    required this.rangeTo,
  });

  final String rangeFrom;
  final String rangeTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final async = ref.watch(stockReportProvider((rangeFrom, rangeTo)));
    return async.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Gagal memuat laporan bahan: $e',
          style: SatType.sans(size: 12, color: sc.warn)),
      data: (r) {
        if (r.isEmpty) return const SizedBox.shrink();
        final usage = _rows(r['usage']);
        final waste = _rows(r['waste']);
        final variance = _rows(r['variance']);
        final valuation = _rows(r['valuation']);
        if (usage.isEmpty &&
            waste.isEmpty &&
            variance.isEmpty &&
            valuation.isEmpty) {
          return Text('Belum ada aktivitas bahan pada rentang ini.',
              style: SatType.sans(size: 12, color: sc.textLo));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpi(sc, 'Nilai stok', formatIDR(_int(r['totalStockValue'])),
                    sc.textHi),
                _kpi(sc, 'Terbuang', formatIDR(_int(r['totalWasteValue'])),
                    _int(r['totalWasteValue']) > 0 ? sc.urgent : sc.textLo),
                _kpi(
                  sc,
                  'Selisih opname',
                  formatIDR(_int(r['totalVarianceValue'])),
                  _int(r['totalVarianceValue']) < 0 ? sc.warn : sc.textLo,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (waste.isNotEmpty)
              _table(sc, 'Terbuang', waste, valueColor: sc.urgent),
            if (variance.isNotEmpty)
              _table(sc, 'Selisih opname', variance,
                  valueColor: sc.warn,
                  empty: 'Belum ada opname pada rentang ini.'),
            if (usage.isNotEmpty) _table(sc, 'Pemakaian', usage),
            if (valuation.isNotEmpty)
              _table(sc, 'Nilai stok saat ini', valuation.take(8).toList()),
          ],
        );
      },
    );
  }

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  static List<Map<String, dynamic>> _rows(Object? raw) => [
        for (final r in (raw as List? ?? const []))
          (r as Map).cast<String, dynamic>(),
      ];

  Widget _kpi(SatColors sc, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sc.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sc.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: SatType.mono(
                    size: 9, color: sc.textLo, letterSpacing: 0.6)),
            const SizedBox(height: 2),
            Text(value,
                style: SatType.sans(
                    size: 14, weight: FontWeight.w600, color: color)),
          ],
        ),
      );

  Widget _table(
    SatColors sc,
    String title,
    List<Map<String, dynamic>> rows, {
    Color? valueColor,
    String? empty,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(),
              style: SatType.mono(
                  size: 10, color: sc.textLo, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(empty ?? '—',
                style: SatType.sans(size: 12, color: sc.textLo))
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(row['name'] as String? ?? '—',
                          style: SatType.sans(size: 13, color: sc.textHi)),
                    ),
                    Text(
                      formatQty(_int(row['qty']),
                          stockUnitFromKey(row['unit'] as String? ?? 'pcs')),
                      style: SatType.mono(size: 11, color: sc.textLo),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 92,
                      child: Text(
                        formatIDR(_int(row['value'])),
                        textAlign: TextAlign.right,
                        style: SatType.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          color: valueColor ?? sc.textMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Keyed by the report's own ISO range so it re-fetches with the timeline chip
/// rather than carrying a second, drifting range picker.
final stockReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, (String, String)>((ref, range) {
  return ref.read(stockApiProvider).report(
        from: DateTime.tryParse(range.$1),
        to: DateTime.tryParse(range.$2),
      );
});
