import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/services/api_client.dart';

/// Read-only feed behind the accounting export (ADR-0032). One-shot fetch of a
/// bookkeeping view for a chosen window: revenue summary on real settled
/// figures, payment-method breakdown, void/refund write-offs, and a per-day
/// breakdown. Plain hand-rolled models, like the other export feeds.

class AccountingRevenue {
  final int gross;
  final int voidAmount;
  final int service;
  final int tax;

  /// Deliberate revenue give-back — kept beside gross/void rather than folded
  /// into gross, so the cost of promos stays visible (ADR-0039).
  final int discount;
  final int net;
  final int collected;
  final int refunded;
  final int sessionCount;

  const AccountingRevenue({
    required this.gross,
    required this.voidAmount,
    required this.service,
    required this.tax,
    required this.discount,
    required this.net,
    required this.collected,
    required this.refunded,
    required this.sessionCount,
  });

  static AccountingRevenue fromJson(Map<String, dynamic> j) =>
      AccountingRevenue(
        gross: (j['gross'] as num?)?.toInt() ?? 0,
        voidAmount: (j['voidAmount'] as num?)?.toInt() ?? 0,
        service: (j['service'] as num?)?.toInt() ?? 0,
        tax: (j['tax'] as num?)?.toInt() ?? 0,
        discount: (j['discount'] as num?)?.toInt() ?? 0,
        net: (j['net'] as num?)?.toInt() ?? 0,
        collected: (j['collected'] as num?)?.toInt() ?? 0,
        refunded: (j['refunded'] as num?)?.toInt() ?? 0,
        sessionCount: (j['sessionCount'] as num?)?.toInt() ?? 0,
      );
}

class AccountingMethodRow {
  final String method;
  final int charged;
  final int chargedCount;
  final int refunded;
  final int refundedCount;
  final int net;

  const AccountingMethodRow({
    required this.method,
    required this.charged,
    required this.chargedCount,
    required this.refunded,
    required this.refundedCount,
    required this.net,
  });

  static AccountingMethodRow fromJson(Map<String, dynamic> j) =>
      AccountingMethodRow(
        method: j['method'] as String? ?? 'lainnya',
        charged: (j['charged'] as num?)?.toInt() ?? 0,
        chargedCount: (j['chargedCount'] as num?)?.toInt() ?? 0,
        refunded: (j['refunded'] as num?)?.toInt() ?? 0,
        refundedCount: (j['refundedCount'] as num?)?.toInt() ?? 0,
        net: (j['net'] as num?)?.toInt() ?? 0,
      );
}

class AccountingVoidRow {
  final String label;
  final int count;
  final int lostRupiah;

  const AccountingVoidRow({
    required this.label,
    required this.count,
    required this.lostRupiah,
  });

  static AccountingVoidRow fromJson(Map<String, dynamic> j) =>
      AccountingVoidRow(
        label: j['label'] as String? ?? '—',
        count: (j['count'] as num?)?.toInt() ?? 0,
        lostRupiah: (j['lostRupiah'] as num?)?.toInt() ?? 0,
      );
}

class AccountingDayRow {
  final String date; // yyyy-MM-dd
  final int gross;
  final int voidAmount;
  final int service;
  final int tax;
  final int discount;
  final int net;
  final int collected;
  final int refunded;

  const AccountingDayRow({
    required this.date,
    required this.gross,
    required this.voidAmount,
    required this.service,
    required this.tax,
    required this.discount,
    required this.net,
    required this.collected,
    required this.refunded,
  });

  static AccountingDayRow fromJson(Map<String, dynamic> j) => AccountingDayRow(
    date: j['date'] as String? ?? '',
    gross: (j['gross'] as num?)?.toInt() ?? 0,
    voidAmount: (j['voidAmount'] as num?)?.toInt() ?? 0,
    service: (j['service'] as num?)?.toInt() ?? 0,
    tax: (j['tax'] as num?)?.toInt() ?? 0,
    discount: (j['discount'] as num?)?.toInt() ?? 0,
    net: (j['net'] as num?)?.toInt() ?? 0,
    collected: (j['collected'] as num?)?.toInt() ?? 0,
    refunded: (j['refunded'] as num?)?.toInt() ?? 0,
  );
}

/// One row of the per-preset discount rollup — "which promo cost what".
/// Labelled from the applied snapshot, so a preset edited or deleted since
/// still reports under the name it carried when applied (ADR-0037/0039).
class AccountingDiscountRow {
  final String? presetId;
  final String name;
  final String kind; // percent | fixed
  final int value;
  final String scope; // order | line
  final int amount;
  final int count;

  const AccountingDiscountRow({
    required this.presetId,
    required this.name,
    required this.kind,
    required this.value,
    required this.scope,
    required this.amount,
    required this.count,
  });

  /// "Member 10%" / "Potongan tetap".
  String get label =>
      kind == 'percent' ? '$name ${(value / 100).toStringAsFixed(0)}%' : name;

  static AccountingDiscountRow fromJson(Map<String, dynamic> j) =>
      AccountingDiscountRow(
        presetId: j['presetId'] as String?,
        name: j['name'] as String? ?? 'Diskon',
        kind: j['kind'] as String? ?? 'percent',
        value: (j['value'] as num?)?.toInt() ?? 0,
        scope: j['scope'] as String? ?? 'order',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class AccountingReport {
  final DateTime generatedAt;
  final DateTime rangeFrom;
  final DateTime rangeTo;
  final ReportRange range;
  final AccountingRevenue revenue;
  final List<AccountingMethodRow> methods;
  final List<AccountingVoidRow> voids;
  final List<AccountingDiscountRow> discounts;
  final List<AccountingDayRow> daily;

  const AccountingReport({
    required this.generatedAt,
    required this.rangeFrom,
    required this.rangeTo,
    required this.range,
    required this.revenue,
    required this.methods,
    required this.voids,
    required this.discounts,
    required this.daily,
  });

  static AccountingReport fromJson(Map<String, dynamic> j, ReportRange range) =>
      AccountingReport(
        generatedAt: DateTime.parse(j['generatedAt'] as String),
        rangeFrom: DateTime.parse(j['rangeFrom'] as String),
        rangeTo: DateTime.parse(j['rangeTo'] as String),
        range: range,
        revenue: AccountingRevenue.fromJson(
          (j['revenue'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        methods: [
          for (final m in (j['methods'] as List? ?? const []))
            AccountingMethodRow.fromJson((m as Map).cast<String, dynamic>()),
        ],
        voids: [
          for (final v in (j['voids'] as List? ?? const []))
            AccountingVoidRow.fromJson((v as Map).cast<String, dynamic>()),
        ],
        discounts: [
          for (final d in (j['discounts'] as List? ?? const []))
            AccountingDiscountRow.fromJson((d as Map).cast<String, dynamic>()),
        ],
        daily: [
          for (final d in (j['daily'] as List? ?? const []))
            AccountingDayRow.fromJson((d as Map).cast<String, dynamic>()),
        ],
      );
}

/// One-shot fetcher for the export sheet. Reuses the report query's range
/// encoding so the accounting export matches the active timeline chip (ADR-0032).
final accountingReportFetcherProvider =
    Provider<Future<AccountingReport> Function(ReportsQuery)>(
      (ref) => (ReportsQuery query) async {
        final api = ref.read(apiClientProvider);
        final raw = await api.getJson(
          '/reports/accounting',
          query: query.toQueryParams(),
        );
        return AccountingReport.fromJson(
          (raw as Map).cast<String, dynamic>(),
          query.range,
        );
      },
    );
