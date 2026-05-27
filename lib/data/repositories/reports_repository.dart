import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/services/api_client.dart';

/// Range pills used by the reports screen. Matches server's `range` query
/// param: today | yesterday | d7 | d30 | month.
enum ReportRange { today, yesterday, d7, d30, month }

String reportRangeKey(ReportRange r) => switch (r) {
      ReportRange.today => 'today',
      ReportRange.yesterday => 'yesterday',
      ReportRange.d7 => 'd7',
      ReportRange.d30 => 'd30',
      ReportRange.month => 'month',
    };

class ReportsQuery {
  final ReportRange range;
  final String? serverId;
  final String? zoneId;
  final String? categoryId;

  const ReportsQuery({
    this.range = ReportRange.today,
    this.serverId,
    this.zoneId,
    this.categoryId,
  });

  ReportsQuery copyWith({
    ReportRange? range,
    Object? serverId = _sentinel,
    Object? zoneId = _sentinel,
    Object? categoryId = _sentinel,
  }) {
    return ReportsQuery(
      range: range ?? this.range,
      serverId: serverId == _sentinel ? this.serverId : serverId as String?,
      zoneId: zoneId == _sentinel ? this.zoneId : zoneId as String?,
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as String?,
    );
  }

  Map<String, String> toQueryParams() => {
        'range': reportRangeKey(range),
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
