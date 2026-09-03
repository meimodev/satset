import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/member_report_dto.dart';
import 'package:satset/data/services/api_client.dart';

/// The windows the member report offers.
///
/// Deliberately **not** `ReportRange` from `reports_repository.dart`. That enum
/// is rendered by `/reports` straight from `.values`, so an `all` arm there
/// would offer the accounting report an unbounded, per-bill window — the exact
/// fetch its 92-day cap exists to prevent. This payload is aggregated to a
/// capped list plus a rollup and does not grow with the span, so it can carry
/// the arm the other cannot.
enum MemberRange { today, yesterday, d7, d30, month, custom, all }

String memberRangeKey(MemberRange r) => switch (r) {
  MemberRange.today => 'today',
  MemberRange.yesterday => 'yesterday',
  MemberRange.d7 => 'd7',
  MemberRange.d30 => 'd30',
  MemberRange.month => 'month',
  MemberRange.custom => 'custom',
  MemberRange.all => 'all',
};

/// `yyyy-MM-dd` for a custom bound. Date-only — the server snaps it to the
/// business-day boundary, so the client never has to know the venue's rollover.
String _ymd(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// How the ranked list is ordered. Applied **client-side** to rows already
/// held: a sort that cost a round trip on a LAN tablet would be slower for no
/// gain, and the server already capped the list.
enum MemberSort { spend, visits, points, recent, name }

class MemberReportState {
  final MemberRange range;
  final DateTime? customFrom;
  final DateTime? customTo;

  final MemberReportDto? report;
  final bool loading;
  final Object? error;

  /// False when the venue runs no membership program — every member route
  /// answers 404 then (ADR-0091), which is a switched-off feature and not an
  /// error to show the owner.
  final bool enabled;

  const MemberReportState({
    this.range = MemberRange.d30,
    this.customFrom,
    this.customTo,
    this.report,
    this.loading = false,
    this.error,
    this.enabled = true,
  });

  MemberReportState copyWith({
    MemberRange? range,
    DateTime? customFrom,
    DateTime? customTo,
    MemberReportDto? report,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? enabled,
  }) => MemberReportState(
    range: range ?? this.range,
    customFrom: customFrom ?? this.customFrom,
    customTo: customTo ?? this.customTo,
    report: report ?? this.report,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    enabled: enabled ?? this.enabled,
  );
}

/// The member report (§Laporan pelanggan), client side.
///
/// A snapshot, not a live view: it does not subscribe to the WS hub, because a
/// report answering a window is read and acted on, not watched. It refetches
/// when the window changes and when the reader asks it to.
class MemberReportRepository extends StateNotifier<MemberReportState> {
  MemberReportRepository(this._ref) : super(const MemberReportState());

  final Ref _ref;

  Map<String, String> get _query => {
    'range': memberRangeKey(state.range),
    if (state.range == MemberRange.custom && state.customFrom != null)
      'from': _ymd(state.customFrom!),
    if (state.range == MemberRange.custom && state.customTo != null)
      'to': _ymd(state.customTo!),
  };

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw =
          await _ref
                  .read(apiClientProvider)
                  .getJson('/members/report', query: _query)
              as Map<String, dynamic>;
      final report = MemberReportDto.fromJson(raw);
      state = state.copyWith(
        report: report,
        loading: false,
        enabled: report.enabled,
      );
    } on ApiException catch (e) {
      // A 404 is the program switched off, not a failure — same reading
      // `MembersRepository` gives it (ADR-0091).
      if (e.statusCode == 404) {
        state = state.copyWith(loading: false, enabled: false);
        return;
      }
      SatLog.repo('member report failed: $e');
      state = state.copyWith(loading: false, error: e);
    } catch (e) {
      SatLog.repo('member report failed: $e');
      state = state.copyWith(loading: false, error: e);
    }
  }

  void setRange(MemberRange r, {DateTime? from, DateTime? to}) {
    state = state.copyWith(range: r, customFrom: from, customTo: to);
    load();
  }

  /// One member's bills and product rollup for the window currently shown.
  ///
  /// Opens for a member with no directory row too — a delete leaves the trade
  /// behind (ADR-0092), and this route is the one place that reads it back.
  Future<MemberHistoryDto> history(String memberId) async {
    final raw =
        await _ref
                .read(apiClientProvider)
                .getJson('/members/$memberId/report', query: _query)
            as Map<String, dynamic>;
    return MemberHistoryDto.fromJson(raw);
  }
}

final memberReportProvider =
    StateNotifierProvider<MemberReportRepository, MemberReportState>(
      MemberReportRepository.new,
    );
