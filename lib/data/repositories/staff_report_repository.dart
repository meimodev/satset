import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/services/api_client.dart';

/// Read-only feed behind the staff-focus export (ADR-0032). One-shot fetch of a
/// combined per-staff row set for a chosen window — productivity + sales +
/// integrity on one row. Plain hand-rolled models (no codegen): export-local
/// shapes, like the order-history feed.

class StaffReportRow {
  final String id;
  final String name;
  final int sessions;
  final int covers;
  final int items;
  final int net;
  final int avgTicket;
  final double upsellRate;
  final int voidCount;
  final double voidPct;
  final int lostRupiah;
  final String? topReasonCode;

  const StaffReportRow({
    required this.id,
    required this.name,
    required this.sessions,
    required this.covers,
    required this.items,
    required this.net,
    required this.avgTicket,
    required this.upsellRate,
    required this.voidCount,
    required this.voidPct,
    required this.lostRupiah,
    required this.topReasonCode,
  });

  static StaffReportRow fromJson(Map<String, dynamic> j) => StaffReportRow(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '—',
    sessions: (j['sessions'] as num?)?.toInt() ?? 0,
    covers: (j['covers'] as num?)?.toInt() ?? 0,
    items: (j['items'] as num?)?.toInt() ?? 0,
    net: (j['net'] as num?)?.toInt() ?? 0,
    avgTicket: (j['avgTicket'] as num?)?.toInt() ?? 0,
    upsellRate: (j['upsellRate'] as num?)?.toDouble() ?? 0.0,
    voidCount: (j['voidCount'] as num?)?.toInt() ?? 0,
    voidPct: (j['voidPct'] as num?)?.toDouble() ?? 0.0,
    lostRupiah: (j['lostRupiah'] as num?)?.toInt() ?? 0,
    topReasonCode: j['topReasonCode'] as String?,
  );
}

class StaffReport {
  final DateTime generatedAt;
  final DateTime rangeFrom;
  final DateTime rangeTo;
  final ReportRange range;
  final List<StaffReportRow> rows;
  final int net;
  final int voidCount;
  final int lostRupiah;

  const StaffReport({
    required this.generatedAt,
    required this.rangeFrom,
    required this.rangeTo,
    required this.range,
    required this.rows,
    required this.net,
    required this.voidCount,
    required this.lostRupiah,
  });

  bool get isEmpty => rows.isEmpty;

  static StaffReport fromJson(Map<String, dynamic> j, ReportRange range) {
    final totals = (j['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return StaffReport(
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      rangeFrom: DateTime.parse(j['rangeFrom'] as String),
      rangeTo: DateTime.parse(j['rangeTo'] as String),
      range: range,
      rows: [
        for (final r in (j['rows'] as List? ?? const []))
          StaffReportRow.fromJson((r as Map).cast<String, dynamic>()),
      ],
      net: (totals['net'] as num?)?.toInt() ?? 0,
      voidCount: (totals['voidCount'] as num?)?.toInt() ?? 0,
      lostRupiah: (totals['lostRupiah'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One-shot fetcher for the export sheet. Throws on transport/HTTP error so the
/// caller can surface it. Reuses the report query's range encoding so the
/// staff export always matches the active timeline chip (ADR-0032).
final staffReportFetcherProvider =
    Provider<Future<StaffReport> Function(ReportsQuery)>(
      (ref) => (ReportsQuery query) async {
        final api = ref.read(apiClientProvider);
        final raw = await api.getJson(
          '/reports/staff',
          query: query.toQueryParams(),
        );
        return StaffReport.fromJson(
          (raw as Map).cast<String, dynamic>(),
          query.range,
        );
      },
    );
