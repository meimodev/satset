import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/services/api_client.dart';

/// Range pills used by the reports screen. Matches server's `range` query
/// param: today | yesterday | d7 | d30 | month | custom. For `custom` the
/// window is carried separately as `from`/`to` (inclusive calendar dates).
enum ReportRange { today, yesterday, d7, d30, month, custom }

String reportRangeKey(ReportRange r) => switch (r) {
      ReportRange.today => 'today',
      ReportRange.yesterday => 'yesterday',
      ReportRange.d7 => 'd7',
      ReportRange.d30 => 'd30',
      ReportRange.month => 'month',
      ReportRange.custom => 'custom',
    };

/// Max span for a custom window (inclusive days). Guards a runaway LAN fetch /
/// giant PDF; the server enforces the same cap defensively.
const int kCustomRangeMaxDays = 92;

/// `yyyy-MM-dd` for a custom window bound on the wire — date-only, the server
/// snaps it to the business-day boundary.
String _ymd(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

class ReportsQuery {
  final ReportRange range;
  final String? serverId;
  final String? zoneId;
  final String? categoryId;

  /// Custom-window bounds (inclusive calendar dates), only meaningful when
  /// [range] is [ReportRange.custom].
  final DateTime? customFrom;
  final DateTime? customTo;

  const ReportsQuery({
    this.range = ReportRange.today,
    this.serverId,
    this.zoneId,
    this.categoryId,
    this.customFrom,
    this.customTo,
  });

  /// True when a custom range is selected but its bounds aren't set yet.
  bool get customIncomplete =>
      range == ReportRange.custom && (customFrom == null || customTo == null);

  ReportsQuery copyWith({
    ReportRange? range,
    Object? serverId = _sentinel,
    Object? zoneId = _sentinel,
    Object? categoryId = _sentinel,
    Object? customFrom = _sentinel,
    Object? customTo = _sentinel,
  }) {
    return ReportsQuery(
      range: range ?? this.range,
      serverId: serverId == _sentinel ? this.serverId : serverId as String?,
      zoneId: zoneId == _sentinel ? this.zoneId : zoneId as String?,
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as String?,
      customFrom:
          customFrom == _sentinel ? this.customFrom : customFrom as DateTime?,
      customTo: customTo == _sentinel ? this.customTo : customTo as DateTime?,
    );
  }

  Map<String, String> toQueryParams() => {
        'range': reportRangeKey(range),
        if (range == ReportRange.custom && customFrom != null)
          'from': _ymd(customFrom!),
        if (range == ReportRange.custom && customTo != null)
          'to': _ymd(customTo!),
        if (serverId != null && serverId!.isNotEmpty) 'server': serverId!,
        if (zoneId != null && zoneId!.isNotEmpty) 'zone': zoneId!,
        if (categoryId != null && categoryId!.isNotEmpty)
          'category': categoryId!,
      };
}

const _sentinel = Object();

/// Current report filter — separate from the snapshot so screens can update
/// it cheaply and the repository auto-refetches via ref.listen.
final reportsQueryProvider =
    StateProvider<ReportsQuery>((_) => const ReportsQuery());

/// Status of the latest fetch. UI uses this to pick skeleton/error states.
final reportsStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.loading());

class ReportsRepository extends StateNotifier<ReportsSnapshotDto?> {
  ReportsRepository({required this.ref}) : super(null) {
    // Re-fetch on every query change (range pill / filter dropdown).
    ref.listen<ReportsQuery>(reportsQueryProvider, (_, _) {
      _bootstrap();
    });
    Future.microtask(_bootstrap);
  }

  final Ref ref;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(reportsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    final query = ref.read(reportsQueryProvider);
    // Custom range picked but no dates committed yet — hold the current
    // snapshot, don't fire a half-formed window at the server.
    if (query.customIncomplete) {
      ref.read(reportsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(reportsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.getJson(
        '/reports/snapshot',
        query: query.toQueryParams(),
      );
      final dto = ReportsSnapshotDto.fromJson(
          (raw as Map).cast<String, dynamic>());
      state = dto;
      ref.read(reportsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      SatLog.repo(
          'reports.loaded range=${query.range.name} items=${dto.menu.top.length}+${dto.menu.slow.length} staff=${dto.staff.rows.length}');
    } catch (e, st) {
      SatLog.repo('reports.bootstrap fail $e');
      ref.read(reportsStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _bootstrap();
}

final reportsRepositoryProvider =
    StateNotifierProvider<ReportsRepository, ReportsSnapshotDto?>(
  (ref) => ReportsRepository(ref: ref),
);
