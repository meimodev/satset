import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart' show customRangeLabel;
import 'package:satset/ui/features/admin/widgets/member_export_sheet.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/member_report_dto.dart';
import 'package:satset/data/repositories/member_report_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/custom_range_sheet.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';
import 'package:satset/ui/core/widgets/sat_tabs.dart';
import '_common.dart';

/// The member report (§Laporan pelanggan).
///
/// Answers, over a window the reader picks: **who came, what they spent, and
/// what they actually ate.** The Keanggotaan block on `/reports` answers the
/// first two for the venue as a whole and is left alone — a closed month must
/// keep printing what it printed. This screen is the one that goes per person
/// and per dish.
///
/// Two panes, because that is the shape of the question: the ranked list on the
/// left is browsed and sorted, and the pane on the right is one member read
/// against their own history. Sorting and searching happen on rows already
/// held — the server capped the list, and a sort that cost a LAN round trip
/// would be slower for nothing.
///
/// Tablet only, like the venue log, the cash box and the opname archive, for
/// the reason those are: the value here is reading rows against each other, and
/// a phone shows one at a time.
class MemberReportScreen extends ConsumerStatefulWidget {
  const MemberReportScreen({super.key});

  @override
  ConsumerState<MemberReportScreen> createState() => _MemberReportScreenState();
}

class _MemberReportScreenState extends ConsumerState<MemberReportScreen> {
  final _search = TextEditingController();
  String _query = '';
  MemberSort _sort = MemberSort.spend;
  String? _selectedId;
  bool _detail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(memberReportProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickCustom() async {
    final s = ref.read(memberReportProvider);
    final picked = await showCustomRangeSheet(
      context,
      initialFrom: s.customFrom,
      initialTo: s.customTo,
    );
    if (picked == null) return;
    ref
        .read(memberReportProvider.notifier)
        .setRange(MemberRange.custom, from: picked.$1, to: picked.$2);
  }

  String _rangeLabel(MemberReportState s) {
    final l = context.l10n;
    return switch (s.range) {
      MemberRange.today => l.rangeToday,
      MemberRange.yesterday => l.rangeYesterday,
      MemberRange.d7 => l.rangeD7,
      MemberRange.d30 => l.rangeD30,
      MemberRange.month => l.rangeMonth,
      MemberRange.all => l.mrpRangeAll,
      MemberRange.custom => (s.customFrom != null && s.customTo != null)
          ? customRangeLabel(s.customFrom!, s.customTo!)
          : l.rangeCustom,
    };
  }

  /// The rows as the list shows them. The filter-then-sort itself lives in
  /// `rankedMemberRows` so the export renders from the same one (ADR-0137).
  List<MemberTradeDto> _rows(MemberReportDto report) =>
      rankedMemberRows(report, query: _query, sort: _sort);

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return const _MemberReportPhoneNotice();

    final l10n = context.l10n;
    final sc = context.sat;
    final state = ref.watch(memberReportProvider);

    if (!state.enabled) {
      return Padding(
        padding: const EdgeInsets.all(Sp.s5),
        child: Center(
          child: SatEmpty(
            icon: Icons.badge_outlined,
            title: l10n.memOffTitle,
            body: l10n.memOffBody,
          ),
        ),
      );
    }

    final report = state.report;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: l10n.mrpTitle,
          sub: report == null
              ? l10n.mrpSub
              : l10n.mrpActiveOf(report.activeMembers, report.enrolledTotal),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final r in MemberRange.values)
                        Padding(
                          padding: const EdgeInsets.only(left: Sp.s1h),
                          child: SatChip.select(
                            // The selected chip carries the window it resolved
                            // to — a custom range shows its dates rather than
                            // the word "Khusus", which is the only way to see
                            // what is on screen without reopening the picker.
                            label: _rangeLabelFor(r, state),
                            selected: state.range == r,
                            onTap: r == MemberRange.custom
                                ? _pickCustom
                                : () => ref
                                      .read(memberReportProvider.notifier)
                                      .setRange(r),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Sp.s3),
              // Outside the scroller on purpose: the chips can run off the edge
              // of a narrow strip, and an action that scrolls away is one a
              // reader has to go looking for.
              SatButton.outline(
                label: l10n.memExpAction,
                icon: Icons.download_rounded,
                size: SatButtonSize.sm,
                onTap: report == null ? null : () => _export(state, report),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.loading && report == null
              ? const Center(child: SatSpinner(size: SatSpinnerSize.md))
              : state.error != null && report == null
              ? Center(
                  child: SatEmpty(
                    icon: Icons.error_outline,
                    title: l10n.mrpTitle,
                    body: '${state.error}',
                  ),
                )
              : report == null
              ? const SizedBox.shrink()
              : _body(context, sc, report, state),
        ),
      ],
    );
  }

  /// Whoever the right-hand pane is **showing**, which is not the same as
  /// `_selectedId`: with nothing picked the pane falls back to the first ranked
  /// row, so reading the field alone tells the export sheet "no member" while a
  /// member's history is plainly on screen beside it.
  String? _shownMemberId(MemberReportDto report) {
    final rows = _rows(report);
    return (rows.where((m) => m.memberId == _selectedId).firstOrNull ??
            rows.firstOrNull)
        ?.memberId;
  }

  /// Hands the sheet the window, the sort and the search box as the list has
  /// them, plus whichever member the right pane is showing. The sheet re-fetches
  /// uncapped and re-applies those, so the file is the screen (ADR-0137).
  Future<void> _export(MemberReportState state, MemberReportDto report) =>
      showMemberExportSheet(
        context,
        windowLabel: _rangeLabel(state),
        sortLabel: _sortLabel(_sort),
        query: _query,
        sort: _sort,
        memberId: _shownMemberId(report),
      );

  String _sortLabel(MemberSort s) {
    final l = context.l10n;
    return switch (s) {
      MemberSort.spend => l.mrpSortSpend,
      MemberSort.visits => l.mrpSortVisits,
      MemberSort.points => l.mrpSortPoints,
      MemberSort.recent => l.mrpSortRecent,
      MemberSort.name => l.mrpSortName,
    };
  }

  String _rangeLabelFor(MemberRange r, MemberReportState s) =>
      r == s.range ? _rangeLabel(s) : _bareLabel(r);

  String _bareLabel(MemberRange r) {
    final l = context.l10n;
    return switch (r) {
      MemberRange.today => l.rangeToday,
      MemberRange.yesterday => l.rangeYesterday,
      MemberRange.d7 => l.rangeD7,
      MemberRange.d30 => l.rangeD30,
      MemberRange.month => l.rangeMonth,
      MemberRange.custom => l.rangeCustom,
      MemberRange.all => l.mrpRangeAll,
    };
  }

  Widget _body(
    BuildContext context,
    SatColors sc,
    MemberReportDto report,
    MemberReportState state,
  ) {
    final l10n = context.l10n;
    final rows = _rows(report);
    final shown = _shownMemberId(report);
    final selected = rows.where((m) => m.memberId == shown).firstOrNull;

    // Height, not keyboard state: a docked tablet IME halves the viewport, and
    // the ranked pane's own header (search box + sort chips) has no smaller
    // size to shrink to — so below this floor the glance card stands down and
    // gives the list what is left. Asked as a layout question because that is
    // the one the shell answers honestly: its Scaffold resizes the body and
    // zeroes `viewInsets` on the way past, and a keyboard dismissed by its own
    // chevron leaves the field focused, so neither of those reads the room.
    const glanceFloor = 320.0;

    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (box.maxHeight >= glanceFloor)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s4, Sp.s4, Sp.s3),
              child: _Overview(
                report: report,
                expanded: _detail,
                onToggle: () => setState(() => _detail = !_detail),
                since: state.range == MemberRange.all
                    ? report.earliestClosedAt
                    : null,
              ),
            ),
          Expanded(
            child: report.members.isEmpty
                ? Center(
                    child: SatEmpty(
                      icon: Icons.people_outline,
                      title: l10n.mrpEmptyTitle,
                      body: l10n.mrpEmptyBody,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _RankedList(
                          rows: rows,
                          report: report,
                          controller: _search,
                          sort: _sort,
                          selectedId: selected?.memberId,
                          onQuery: (q) => setState(() => _query = q),
                          onSort: (s) => setState(() => _sort = s),
                          onPick: (id) => setState(() => _selectedId = id),
                        ),
                      ),
                      Container(width: 1, color: sc.border1),
                      Expanded(
                        child: selected == null
                            ? Center(
                                child: SatEmpty(
                                  icon: Icons.person_search_outlined,
                                  title: l10n.mrpPickTitle,
                                  body: l10n.mrpPickBody,
                                ),
                              )
                            : _Drill(
                                // Keyed on the member *and* the window, so
                                // changing either refetches instead of showing
                                // the previous answer under the new heading.
                                key: ValueKey(
                                  '${selected.memberId}·'
                                  '${memberRangeKey(state.range)}·'
                                  '${state.customFrom}·${state.customTo}',
                                ),
                                row: selected,
                                pointsEnabled: report.pointsEnabled,
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

/// The glance row, and the expander behind it.
///
/// Six tiles carry the whole program: who came, who is new, what they spent,
/// what a visit is worth, who came back, and what the venue still owes them.
/// Everything else is real but secondary, so it sits one tap away rather than
/// competing — "at a glance and in detail if needed" is two states, not one
/// dense wall.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.report,
    required this.expanded,
    required this.onToggle,
    required this.since,
  });

  final MemberReportDto report;
  final bool expanded;
  final VoidCallback onToggle;

  /// The venue's first trading day, shown only on the open-ended window — it is
  /// what "Semua" actually means, and a range with no start reads as a bug
  /// without it.
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    final share = report.venueNet == 0
        ? 0
        : (report.memberNet * 100 / report.venueNet).round();

    return SatCard.plain(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Tile(
                label: l.mrpKpiActive,
                value: '${report.activeMembers}',
                foot: l.mrpOfEnrolled(report.enrolledTotal),
                color: sc.accent,
              ),
              _Tile(
                label: l.mrpKpiNew,
                value: '${report.enrolled}',
                foot: l.mrpIdle(report.idleMembers),
                color: sc.info,
              ),
              _Tile(
                label: l.mrpKpiSpend,
                value: formatCompactIDR(l, report.memberNet),
                foot: l.mrpShareOfNet(share),
                color: sc.success,
              ),
              _Tile(
                label: l.mrpKpiAvg,
                value: formatCompactIDR(l, report.avgMemberBill),
                foot: l.mrpVsGuest(formatCompactIDR(l, report.avgGuestBill)),
                color: sc.textHi,
              ),
              _Tile(
                label: l.mrpKpiReturn,
                value: '${report.returningMembers}',
                foot: l.mrpOnceOnly(report.onceOnly),
                color: sc.violet,
              ),
              if (report.pointsEnabled)
                _Tile(
                  label: l.mrpKpiPoints,
                  value: groupRupiah(report.pointsOutstanding),
                  foot: l.mrpLiability(
                    formatCompactIDR(l, report.liabilityEstimate),
                  ),
                  color: sc.warn,
                ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: Sp.s3),
            Container(height: 1, color: sc.border1),
            const SizedBox(height: Sp.s3),
            Wrap(
              spacing: Sp.s6,
              runSpacing: Sp.s2,
              children: [
                _Fact(l.mrpMemberBills, '${report.memberBills}'),
                _Fact(l.mrpGuestBills, '${report.guestBills}'),
                _Fact(l.mrpGuestNet, formatIDR(report.guestNet)),
                if (report.splitEnabled)
                  _Fact(l.mrpSplitBills, '${report.splitBills}'),
                if (report.pointsEnabled) ...[
                  _Fact(l.mrpPointsEarned, groupRupiah(report.pointsEarned)),
                  _Fact(
                    l.mrpPointsRedeemed,
                    groupRupiah(report.pointsRedeemed),
                  ),
                  _Fact(
                    l.mrpPointsAdjusted,
                    groupRupiah(report.pointsAdjusted),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: Sp.s2),
          Row(
            children: [
              if (since != null)
                Expanded(
                  child: Text(
                    l.mrpSince(formatShortDateId(since!)),
                    style: SatType.caption(color: sc.textLo),
                  ),
                )
              else
                const Spacer(),
              SatButton.ghost(
                label: expanded ? l.mrpHideDetail : l.mrpDetail,
                size: SatButtonSize.sm,
                onTap: onToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.foot,
    required this.color,
  });
  final String label;
  final String value;
  final String foot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: Sp.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: SatType.caption(color: sc.textLo)),
            const SizedBox(height: Sp.sHair),
            Text(value, style: SatType.h3(color: color)),
            const SizedBox(height: Sp.sHair),
            Text(foot, style: SatType.caption(color: sc.textDim)),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: SatType.caption(color: sc.textLo)),
        const SizedBox(width: Sp.s1h),
        Text(value, style: SatType.labelS(color: sc.textHi)),
      ],
    );
  }
}

class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.rows,
    required this.report,
    required this.controller,
    required this.sort,
    required this.selectedId,
    required this.onQuery,
    required this.onSort,
    required this.onPick,
  });

  final List<MemberTradeDto> rows;
  final MemberReportDto report;
  final TextEditingController controller;
  final MemberSort sort;
  final String? selectedId;
  final ValueChanged<String> onQuery;
  final ValueChanged<MemberSort> onSort;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    final sorts = <(MemberSort, String)>[
      (MemberSort.spend, l.mrpSortSpend),
      (MemberSort.visits, l.mrpSortVisits),
      if (report.pointsEnabled) (MemberSort.points, l.mrpSortPoints),
      (MemberSort.recent, l.mrpSortRecent),
      (MemberSort.name, l.mrpSortName),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Sp.s4,
            right: Sp.s4,
            bottom: Sp.s2,
          ),
          child: SatField.search(
            controller: controller,
            hint: l.mrpSearchHint,
            onChanged: onQuery,
          ),
        ),
        SizedBox(
          height: Sp.s9,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
            children: [
              for (final (s, label) in sorts)
                Padding(
                  padding: const EdgeInsets.only(right: Sp.s1h),
                  child: SatChip.select(
                    label: label,
                    selected: sort == s,
                    onTap: () => onSort(s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    l.mrpNoMatch,
                    style: SatType.bodyS(color: sc.textLo),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    Sp.s4,
                    Sp.s2,
                    Sp.s4,
                    Sp.s4 + context.shellInset,
                  ),
                  children: [
                    for (final m in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Sp.s2),
                        child: _MemberTile(
                          row: m,
                          pointsEnabled: report.pointsEnabled,
                          selected: m.memberId == selectedId,
                          onTap: () => onPick(m.memberId),
                        ),
                      ),
                    if (report.membersTruncated > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: Sp.s2),
                        child: Text(
                          l.mrpTruncated(report.membersTruncated),
                          style: SatType.caption(color: sc.textDim),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.row,
    required this.pointsEnabled,
    required this.selected,
    required this.onTap,
  });

  final MemberTradeDto row;
  final bool pointsEnabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    return SatCard.tappable(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // A member deleted since (ADR-0092) keeps their trade and
                  // loses their name. The row stays — the venue's record of
                  // what it sold does not depend on the person still being on
                  // the books.
                  row.name ?? l.mrpDeleted,
                  style: SatType.labelM(
                    color: row.deleted ? sc.textLo : sc.textHi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Sp.s2),
              Text(
                formatIDR(row.spend),
                style: SatType.labelM(color: sc.success),
              ),
            ],
          ),
          const SizedBox(height: Sp.sHair),
          Row(
            children: [
              Expanded(
                child: Text(
                  row.phone ?? '—',
                  style: SatType.caption(color: sc.textDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l.mrpVisitsN(row.visits),
                style: SatType.caption(color: sc.textLo),
              ),
              if (pointsEnabled && row.points != 0) ...[
                const SizedBox(width: Sp.s2),
                Text(
                  l.mrpPointsN(row.points),
                  style: SatType.caption(color: sc.warn),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One member, read against their own history.
///
/// Fetches on build and is keyed on member + window by its parent, so it cannot
/// show the previous person's answer under the new name.
class _Drill extends ConsumerStatefulWidget {
  const _Drill({super.key, required this.row, required this.pointsEnabled});

  final MemberTradeDto row;
  final bool pointsEnabled;

  @override
  ConsumerState<_Drill> createState() => _DrillState();
}

class _DrillState extends ConsumerState<_Drill> {
  late Future<MemberHistoryDto> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(memberReportProvider.notifier)
        .history(widget.row.memberId);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    return FutureBuilder<MemberHistoryDto>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: SatSpinner(size: SatSpinnerSize.md));
        }
        if (snap.hasError) {
          return Center(
            child: SatEmpty(
              icon: Icons.error_outline,
              title: l.mrpTitle,
              body: '${snap.error}',
            ),
          );
        }
        final h = snap.data!;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            Sp.s5,
            Sp.s4,
            Sp.s5,
            Sp.s5 + context.shellInset,
          ),
          children: [
            Text(
              h.name ?? widget.row.name ?? l.mrpDeleted,
              style: SatType.h2(color: sc.textHi),
            ),
            const SizedBox(height: Sp.sHair),
            Text(
              h.phone ?? widget.row.phone ?? '—',
              style: SatType.bodyS(color: sc.textDim),
            ),
            const SizedBox(height: Sp.s4),
            _DrillStats(history: h, pointsEnabled: widget.pointsEnabled),
            if (h.untrackedSpend > 0) ...[
              const SizedBox(height: Sp.s3),
              _UntrackedNote(amount: h.untrackedSpend),
            ],
            const SizedBox(height: Sp.s4),
            SatTabs(
              tabs: [
                SatTab(label: l.mrpTabProducts),
                SatTab(label: l.mrpTabVisits),
              ],
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: Sp.s3),
            if (_tab == 0) _Products(history: h) else _Bills(history: h),
          ],
        );
      },
    );
  }
}

/// Window figures on top, lifetime underneath.
///
/// Both, always: the window is what the reader picked and the lifetime is what
/// the directory shows, and a screen that offered only one leaves them guessing
/// which of the two they are looking at.
class _DrillStats extends StatelessWidget {
  const _DrillStats({required this.history, required this.pointsEnabled});

  final MemberHistoryDto history;
  final bool pointsEnabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    return SatCard.plain(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.mrpInWindow.toUpperCase(),
            style: SatType.caption(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s2),
          Row(
            children: [
              _Tile(
                label: l.mrpStatVisits,
                value: '${history.visits}',
                foot: l.mrpStatBills(history.billsTotal),
                color: sc.accent,
              ),
              _Tile(
                label: l.mrpStatSpend,
                value: formatCompactIDR(l, history.spend),
                foot: l.mrpStatAvg(formatCompactIDR(l, history.avgBill)),
                color: sc.success,
              ),
              _Tile(
                label: l.mrpStatItems,
                value: '${history.units}',
                foot: l.mrpStatDistinct(history.distinctProducts),
                color: sc.info,
              ),
              if (pointsEnabled)
                _Tile(
                  label: l.mrpStatPoints,
                  value: groupRupiah(history.pointsBalance),
                  foot: l.mrpStatBalance,
                  color: sc.warn,
                ),
            ],
          ),
          if (!history.deleted) ...[
            const SizedBox(height: Sp.s3),
            Container(height: 1, color: sc.border1),
            const SizedBox(height: Sp.s3),
            Wrap(
              spacing: Sp.s6,
              runSpacing: Sp.s2,
              children: [
                _Fact(l.mrpLifetimeVisits, '${history.lifetimeVisits}'),
                _Fact(l.mrpLifetimeSpend, formatIDR(history.lifetimeSpend)),
                if (history.joinedAt != null)
                  _Fact(l.mrpJoined, formatShortDateId(history.joinedAt!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Says why the spend total and the product rollup do not add up.
///
/// An [[Amount receipt]] claims money and owns no lines (ADR-0068), so a member
/// who settled an even split has spend and no items. That gap is correct, and
/// silence about it reads as a bug.
class _UntrackedNote extends StatelessWidget {
  const _UntrackedNote({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.card,
        border: SatB.all(color: sc.border1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: sc.textLo),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              l.mrpUntracked(formatIDR(amount)),
              style: SatType.caption(color: sc.textLo),
            ),
          ),
        ],
      ),
    );
  }
}

class _Products extends StatelessWidget {
  const _Products({required this.history});
  final MemberHistoryDto history;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    if (history.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.s6),
        child: SatEmpty(
          icon: Icons.restaurant_outlined,
          title: l.mrpNoProductsTitle,
          body: l.mrpNoProductsBody,
        ),
      );
    }
    final top = history.products.first.qty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          left: l.mrpColItem,
          mid: l.mrpColQty,
          right: l.mrpColValue,
          tail: l.mrpColLast,
        ),
        for (final p in history.products)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.s1),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: SatType.bodyS(color: sc.textHi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Sp.sHair),
                      // A bar rather than a number nobody reads twice: the
                      // question this tab answers is "what do they always
                      // order", and rank is easier to see than to compute.
                      ClipRRect(
                        // `SatR.a` under 8 is a deliberate passthrough — this
                        // is a meter bar, not a corner, and rounding it up
                        // rounds the shape away.
                        borderRadius: SatR.a(2),
                        child: LinearProgressIndicator(
                          value: top == 0 ? 0 : p.qty / top,
                          minHeight: 3,
                          backgroundColor: sc.bg3,
                          valueColor: AlwaysStoppedAnimation(sc.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${p.qty}',
                    style: SatType.labelS(color: sc.textHi),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    formatIDR(p.spend),
                    style: SatType.bodyS(color: sc.textLo),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    formatShortDateId(p.lastAt),
                    style: SatType.caption(color: sc.textDim),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bills extends StatelessWidget {
  const _Bills({required this.history});
  final MemberHistoryDto history;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sc = context.sat;
    if (history.bills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.s6),
        child: SatEmpty(
          icon: Icons.receipt_long_outlined,
          title: l.mrpNoBillsTitle,
          body: l.mrpNoBillsBody,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          left: l.mrpColWhen,
          mid: l.mrpColTable,
          right: l.mrpColShare,
          tail: l.mrpColQty,
        ),
        for (final b in history.bills)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.s1),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    '${formatShortDateId(b.closedAt)} · '
                    '${formatClockId(b.closedAt.toIso8601String())}',
                    style: SatType.bodyS(color: sc.textHi),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          b.tableLabel ?? '—',
                          style: SatType.bodyS(color: sc.textLo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Only worth saying when it is true: on a bill they held
                      // alone, "pemilik tagihan" is noise.
                      if (b.shared) ...[
                        const SizedBox(width: Sp.s1h),
                        Text(
                          b.owner ? l.mrpBillOwner : l.mrpBillGuestOf,
                          style: SatType.caption(color: sc.violet),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatIDR(b.share),
                        style: SatType.labelS(color: sc.success),
                      ),
                      if (b.shared)
                        Text(
                          l.mrpOfBill(formatIDR(b.billTotal)),
                          style: SatType.caption(color: sc.textDim),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${b.units}',
                    style: SatType.bodyS(color: sc.textLo),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        if (history.billsTotal > history.bills.length)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s3),
            child: Text(
              l.mrpBillsMore(history.billsTotal - history.bills.length),
              style: SatType.caption(color: sc.textDim),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.left,
    required this.mid,
    required this.right,
    required this.tail,
  });
  final String left;
  final String mid;
  final String right;
  final String tail;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    TextStyle s() => SatType.caption(color: sc.textDim);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(left.toUpperCase(), style: s())),
          Expanded(
            flex: 2,
            child: Text(
              mid.toUpperCase(),
              style: s(),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              right.toUpperCase(),
              style: s(),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tail.toUpperCase(),
              style: s(),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberReportPhoneNotice extends StatelessWidget {
  const _MemberReportPhoneNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Sp.s5),
    child: Center(
      child: SatEmpty(
        icon: Icons.tablet_mac_outlined,
        title: context.l10n.mrpTitle,
        body: context.l10n.mrpPhoneOnly,
      ),
    ),
  );
}
