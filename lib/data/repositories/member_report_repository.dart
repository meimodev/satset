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

/// The window as the server wants it. Hoisted off the notifier so the export
/// fetchers — which are plain one-shot providers holding no state (ADR-0137) —
/// encode the window exactly as the on-screen read does. Two encodings would
/// let a file quietly answer a different window than the screen it came from.
Map<String, String> memberRangeQuery(
  MemberRange range, {
  DateTime? from,
  DateTime? to,
}) => {
  'range': memberRangeKey(range),
  if (range == MemberRange.custom && from != null) 'from': _ymd(from),
  if (range == MemberRange.custom && to != null) 'to': _ymd(to),
};

/// Filename span for a member export. `Semua` gets no span at all — the file is
/// everything, and a slug saying so would be the only word in the name that is
/// not a date.
String memberRangeSlug(MemberRange r, {DateTime? from, DateTime? to}) {
  String two(int n) => n.toString().padLeft(2, '0');
  String stamp(DateTime t) => '${t.year}${two(t.month)}${two(t.day)}';
  return switch (r) {
    MemberRange.today => 'hari-ini',
    MemberRange.yesterday => 'kemarin',
    MemberRange.d7 => '7-hari',
    MemberRange.d30 => '30-hari',
    MemberRange.month => 'bulan-ini',
    MemberRange.all => 'semua',
    MemberRange.custom =>
      (from != null && to != null)
          ? 'khusus-${stamp(from)}-${stamp(to)}'
          : 'khusus',
  };
}

/// How the ranked list is ordered. Applied **client-side** to rows already
/// held: a sort that cost a round trip on a LAN tablet would be slower for no
/// gain, and the server already capped the list.
enum MemberSort { spend, visits, points, recent, name }

/// The ranked rows as the list shows them: filtered by the search box, then
/// ordered by the active [MemberSort]. Both struck client-side on rows already
/// held — a sort that cost a LAN round trip would be slower for no gain.
///
/// Lives here, not on the screen, because the **export renders from it too**
/// (ADR-0137). The file is supposed to be what the reader is looking at, and
/// two copies of this filter-then-sort is how a file quietly stops being that.
List<MemberTradeDto> rankedMemberRows(
  MemberReportDto report, {
  String query = '',
  MemberSort sort = MemberSort.spend,
}) {
  final q = query.trim().toLowerCase();
  final rows = [
    for (final m in report.members)
      if (q.isEmpty ||
          (m.name ?? '').toLowerCase().contains(q) ||
          (m.phone ?? '').contains(q))
        m,
  ];
  rows.sort(switch (sort) {
    MemberSort.spend => (a, b) => b.spend.compareTo(a.spend),
    MemberSort.visits => (a, b) => b.visits.compareTo(a.visits),
    MemberSort.points => (a, b) => b.points.compareTo(a.points),
    MemberSort.recent => (a, b) =>
        (b.lastVisitAt ?? DateTime(0)).compareTo(a.lastVisitAt ?? DateTime(0)),
    MemberSort.name => (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  });
  return rows;
}

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

  Map<String, String> get _query => memberRangeQuery(
    state.range,
    from: state.customFrom,
    to: state.customTo,
  );

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

/// One-shot fetchers for the member exports (ADR-0137).
///
/// Plain providers rather than methods on [MemberReportRepository], for the
/// reason the staff export is one: an export is fetched, rendered and dropped,
/// and nothing watches it. Hanging it off the notifier invites a future reader
/// to cache the result into `state` — where `report` already means the capped
/// on-screen snapshot, and would then sometimes mean the uncapped one.
///
/// Both throw on transport or HTTP error so the sheet can name what happened:
/// a 413 `export_too_large` is the ceiling, and a dark host is the refusal that
/// must never quietly become an export of the [[Salinan pelanggan]].
final memberReportExportFetcherProvider =
    Provider<Future<MemberReportDto> Function(MemberReportState)>(
      (ref) => (MemberReportState s) async {
        final raw =
            await ref
                    .read(apiClientProvider)
                    .getJson(
                      '/members/report/export',
                      query: memberRangeQuery(
                        s.range,
                        from: s.customFrom,
                        to: s.customTo,
                      ),
                    )
                as Map<String, dynamic>;
        return MemberReportDto.fromJson(raw);
      },
    );

final memberHistoryExportFetcherProvider =
    Provider<Future<MemberHistoryDto> Function(MemberReportState, String)>(
      (ref) => (MemberReportState s, String memberId) async {
        final raw =
            await ref
                    .read(apiClientProvider)
                    .getJson(
                      '/members/$memberId/report/export',
                      query: memberRangeQuery(
                        s.range,
                        from: s.customFrom,
                        to: s.customTo,
                      ),
                    )
                as Map<String, dynamic>;
        return MemberHistoryDto.fromJson(raw);
      },
    );
