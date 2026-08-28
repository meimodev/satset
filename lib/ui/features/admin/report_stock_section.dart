import 'package:flutter/material.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// The report's ingredient view: what was used, what was thrown away, what the
/// pantry is worth, and how far the counts drifted.
///
/// Variance rows come from `adjust` movements — the difference between what
/// recipes said should be on the shelf and what an opname actually found. They
/// are therefore **opname-anchored**: a row appears only where someone counted
/// inside this window (ADR-0041).
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
      loading: () =>
          const SizedBox(height: 90, child: Center(child: SatSpinner())),
      error: (e, _) => Text(
        context.l10n.rptStockFailed('$e'),
        style: SatType.bodyS(color: sc.warn),
      ),
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
          return Text(
            context.l10n.rptStockEmpty,
            style: SatType.bodyS(color: sc.textLo),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpi(
                  sc,
                  context.l10n.rptStockValue,
                  formatIDR(_int(r['totalStockValue'])),
                  sc.textHi,
                ),
                _kpi(
                  sc,
                  context.l10n.rptStockWaste,
                  formatIDR(_int(r['totalWasteValue'])),
                  _int(r['totalWasteValue']) > 0 ? sc.urgent : sc.textLo,
                ),
                _kpi(
                  sc,
                  context.l10n.rptStockVariance,
                  formatIDR(_int(r['totalVarianceValue'])),
                  _int(r['totalVarianceValue']) < 0 ? sc.warn : sc.textLo,
                ),
              ],
            ),
            const SizedBox(height: Sp.s3h),
            if (waste.isNotEmpty)
              _table(
                sc,
                context.l10n.rptStockWaste,
                waste,
                valueColor: sc.urgent,
              ),
            if (variance.isNotEmpty)
              _table(
                sc,
                context.l10n.rptStockVariance,
                variance,
                valueColor: sc.warn,
                empty: context.l10n.rptNoStocktake,
              ),
            if (usage.isNotEmpty) _table(sc, context.l10n.rptStockUsage, usage),
            if (valuation.isNotEmpty)
              _table(
                sc,
                context.l10n.rptStockValueNow,
                valuation.take(8).toList(),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2),
        decoration: SatBox.d(
          color: sc.bg2,
          borderRadius: SatR.a(10),
          border: SatB.all(color: sc.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
            const SizedBox(height: Sp.sHair),
            Text(value, style: SatType.labelM(color: color)),
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
      padding: const EdgeInsets.only(bottom: Sp.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
          const SizedBox(height: Sp.s1h),
          if (rows.isEmpty)
            Text(empty ?? '—', style: SatType.bodyS(color: sc.textLo))
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.s1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row['name'] as String? ?? '—',
                        style: SatType.bodyM(color: sc.textHi),
                      ),
                    ),
                    Text(
                      formatQty(
                        _int(row['qty']),
                        stockUnitFromKey(row['unit'] as String? ?? 'pcs'),
                      ),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                    const SizedBox(width: Sp.s3),
                    SizedBox(
                      width: 92,
                      child: Text(
                        formatIDR(_int(row['value'])),
                        textAlign: TextAlign.right,
                        style: SatType.caption(color: valueColor ?? sc.textMd),
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
      return ref
          .read(stockApiProvider)
          .report(
            from: DateTime.tryParse(range.$1),
            to: DateTime.tryParse(range.$2),
          );
    });
