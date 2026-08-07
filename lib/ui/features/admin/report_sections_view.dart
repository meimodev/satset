import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/payment_proof_thumb.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import '_common.dart';
import 'report_stock_section.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// The full reports rendering — five sections (sales / staff / menu / ops /
/// payments) with their section-toggle tabs and staff sort. Extracted from
/// `ReportsScreen` so the off-site owner view (ADR-0036) renders identical
/// content from a cloud snapshot, while the admin screen keeps its own chrome
/// (range pills, filters, export, freshness) above it.
///
/// [showProofPhotos] gates the payments proof thumbnails, which fetch pinned
/// bytes from the local server: the owner has no LAN server, so it passes
/// `false` and gets a placeholder instead of a broken fetch.
class ReportSectionsView extends StatefulWidget {
  const ReportSectionsView({
    super.key,
    required this.snapshot,
    required this.isTab,
    this.loading = false,
    this.showProofPhotos = true,
    this.showStock = true,
  });

  final ReportsSnapshotDto snapshot;
  final bool isTab;
  final bool loading;
  final bool showProofPhotos;

  /// The Bahan section reads the **local** server's stock endpoints, which the
  /// off-site owner (ADR-0036) has no route to — their view renders from a
  /// cloud snapshot only, so it passes `false`. Same reasoning as
  /// [showProofPhotos].
  final bool showStock;

  @override
  State<ReportSectionsView> createState() => _ReportSectionsViewState();
}

enum _Section { sales, staff, menu, bahan, ops, payments }

enum _StaffSort { net, covers, voidPct, avgTicket }

class _BucketSpec {
  const _BucketSpec(this.key, this.label, this.action, this.color);
  final String key;
  final String label;
  final String action;
  final Color color;
}

class _ReportSectionsViewState extends State<ReportSectionsView> {
  final Set<_Section> _on = {
    _Section.sales,
    _Section.staff,
    _Section.menu,
    _Section.bahan,
    _Section.ops,
    _Section.payments,
  };
  _StaffSort _staffSort = _StaffSort.net;

  String _sectionLabel(AppL10n l10n, _Section s) => switch (s) {
    _Section.sales => l10n.rptSecSales,
    _Section.staff => l10n.rptSecStaff,
    _Section.menu => l10n.rptSecMenu,
    _Section.bahan => l10n.rptSecBahan,
    _Section.ops => l10n.rptSecOps,
    _Section.payments => l10n.rptSecPayments,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTabs(context),
        const SizedBox(height: Sp.s3h),
        _sections(context, widget.isTab, widget.snapshot, widget.loading),
      ],
    );
  }

  Widget _sectionTabs(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1, vertical: Sp.s1),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          for (final s in _Section.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  if (_on.contains(s)) {
                    _on.remove(s);
                  } else {
                    _on.add(s);
                  }
                }),
                child: AnimatedContainer(
                  duration: satMotion(context, 160),
                  padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
                  margin: const EdgeInsets.symmetric(horizontal: Sp.sHair),
                  decoration: SatBox.d(
                    color: _on.contains(s) ? sc.bg4 : Colors.transparent,
                    borderRadius: SatR.a(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _sectionLabel(context.l10n, s),
                    style: SatType.bodyS(
                      color: _on.contains(s) ? sc.textHi : sc.textLo,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sections(
    BuildContext context,
    bool isTab,
    ReportsSnapshotDto snapshot,
    bool loading,
  ) {
    if (_on.isEmpty) return _emptyState(context);
    final blocks = <Widget>[
      if (_on.contains(_Section.sales))
        Reveal(
          key: const ValueKey('sales'),
          index: 0,
          child: _salesSection(context, isTab, snapshot.sales),
        ),
      if (_on.contains(_Section.staff))
        Reveal(
          key: const ValueKey('staff'),
          index: 1,
          child: _staffSection(context, snapshot.staff),
        ),
      if (_on.contains(_Section.menu))
        Reveal(
          key: const ValueKey('menu'),
          index: 2,
          child: _menuSection(context, isTab, snapshot.menu),
        ),
      if (_on.contains(_Section.bahan) && widget.showStock)
        Reveal(
          key: const ValueKey('bahan'),
          index: 3,
          child: _card(
            context,
            context.l10n.rptStockTitle,
            sub: context.l10n.rptStockSub,
            child: ReportStockSection(
              rangeFrom: snapshot.rangeFrom,
              rangeTo: snapshot.rangeTo,
            ),
          ),
        ),
      if (_on.contains(_Section.ops))
        Reveal(
          key: const ValueKey('ops'),
          index: 4,
          child: _opsSection(context, isTab, snapshot.ops),
        ),
      if (_on.contains(_Section.payments))
        Reveal(
          key: const ValueKey('payments'),
          index: 5,
          child: _paymentsSection(context, snapshot.payments),
        ),
    ];
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var k = 0; k < blocks.length; k++) ...[
          blocks[k],
          if (k != blocks.length - 1) const SizedBox(height: Sp.s3h),
        ],
      ],
    );
    return Stack(
      children: [
        AnimatedOpacity(
          duration: satMotion(context, 220),
          curve: satEaseOut,
          opacity: loading ? 0.45 : 1,
          child: IgnorePointer(ignoring: loading, child: col),
        ),
        if (loading)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: Sp.s12),
                child: _loadingChip(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _loadingChip(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(999),
        boxShadow: [
          BoxShadow(
            color: satShadowInk.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: Sp.s3h,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation(sc.accentText),
            ),
          ),
          const SizedBox(width: Sp.s2h),
          Text(
            context.l10n.rptUpdating,
            style: SatType.bodyS(color: sc.textHi),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title, {
    String? sub,
    required Widget child,
    Widget? trailing,
  }) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s4h),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SatType.labelL(color: sc.textHi)),
                    if (sub != null) ...[
                      const SizedBox(height: Sp.sHair),
                      Text(
                        sub.toUpperCase(),
                        style: SatType.monoS(color: sc.textLo),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Sp.s3h),
          child,
        ],
      ),
    );
  }

  // ──────────── PAYMENTS (non-cash proof, ADR-0025) ────────────
  String _payTime(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _paymentsSection(BuildContext context, PaymentsSectionDto p) {
    final sc = context.sat;
    if (p.rows.isEmpty) {
      return _card(
        context,
        context.l10n.rptNonCash,
        sub: context.l10n.rptNonCashSub,
        child: Text(
          context.l10n.rptNonCashEmpty,
          style: SatType.bodyM(color: sc.textLo),
        ),
      );
    }
    return _card(
      context,
      context.l10n.rptNonCash,
      sub: context.l10n.rptTotalOf(formatIDR(p.nonCashTotal)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showProofPhotos && p.rows.any((r) => r.hasPhoto)) ...[
            Text(
              context.l10n.rptProofOnVenue,
              style: SatType.bodyS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s2h),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in p.methodTotals)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.s2h,
                    vertical: Sp.s1h,
                  ),
                  decoration: SatBox.d(
                    color: sc.bg1,
                    borderRadius: SatR.a(999),
                    border: SatB.all(color: sc.border0),
                  ),
                  child: Text(
                    context.l10n.rptMethodCount(
                      paymentMethodLabel(context.l10n, m.method),
                      m.count,
                      formatIDR(m.amount),
                    ),
                    style: SatType.bodyS(color: sc.textHi),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          for (final r in p.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
              child: Row(
                children: [
                  // Bytes live only on the LAN server, so off-site (owner) the
                  // proof exists but is unfetchable — the widget says so, in a
                  // box the same size as a slip, and distinct from a genuinely
                  // photo-less (cash/legacy) row. ADR-0036, ADR-0082.
                  PaymentProofThumb(
                    paymentId: r.paymentId,
                    history: true,
                    hasPhoto: r.hasPhoto,
                    fetchable: widget.showProofPhotos,
                  ),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.rptMethodTable(
                            paymentMethodLabel(context.l10n, r.method),
                            r.tableLabel ?? '-',
                          ),
                          style: SatType.labelM(color: sc.textHi),
                        ),
                        const SizedBox(height: Sp.sHair),
                        Text(
                          '${_payTime(r.at)} · ${r.cashierName ?? '-'}',
                          style: SatType.bodyS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.s2),
                  Text(
                    formatIDR(r.amount),
                    style: SatType.monoM(color: sc.textHi),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────── SALES ────────────
  Widget _salesSection(
    BuildContext context,
    bool isTab,
    SalesSectionDto sales,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _salesKpis(context, sales.kpis),
        if (sales.takeaway != null &&
            (sales.takeaway!.count > 0 || sales.takeaway!.dineInCount > 0)) ...[
          const SizedBox(height: Sp.s3h),
          _takeawaySplit(context, sales.takeaway!),
        ],
        const SizedBox(height: Sp.s3h),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _coverTrend(context, sales.coverTrend)),
              const SizedBox(width: Sp.s3h),
              Expanded(child: _hourlyRevenue(context, sales.hourly)),
            ],
          )
        else ...[
          _coverTrend(context, sales.coverTrend),
          const SizedBox(height: Sp.s3h),
          _hourlyRevenue(context, sales.hourly),
        ],
      ],
    );
  }

  Widget _takeawaySplit(BuildContext context, TakeawaySplitDto t) {
    return _card(
      context,
      context.l10n.rptDineVsTakeaway,
      child: Row(
        children: [
          Expanded(
            child: SetTile(
              label: context.l10n.rptDineIn,
              value: formatIDR(t.dineInNet),
              sub: context.l10n.rptTxCount(t.dineInCount),
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: SetTile(
              label: context.l10n.rptTakeaway,
              value: formatIDR(t.net),
              sub: context.l10n.rptTxCount(t.count),
            ),
          ),
        ],
      ),
    );
  }

  Widget _salesKpis(BuildContext context, List<KpiTileDto> kpis) {
    final tiles = kpis.isEmpty
        ? [
            KpiTileDto(
              label: context.l10n.rptKpiNet,
              value: '—',
              sub: context.l10n.rptNoDataLower,
            ),
            KpiTileDto(label: context.l10n.rptKpiGross, value: '—', sub: '—'),
            KpiTileDto(
              label: context.l10n.rptKpiTaxService,
              value: '—',
              sub: '—',
            ),
            KpiTileDto(label: context.l10n.rptKpiVoid, value: '—', sub: '—'),
          ]
        : kpis;
    return LayoutBuilder(
      builder: (c, cons) {
        final narrow = cons.maxWidth < 520;
        if (narrow) {
          return Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 2 && i < tiles.length; i++) ...[
                    Expanded(
                      child: SetTile(
                        label: kpiLabel(context.l10n, tiles[i]),
                        value: tiles[i].value,
                        sub: kpiSub(context.l10n, tiles[i]),
                      ),
                    ),
                    if (i == 0) const SizedBox(width: Sp.s3),
                  ],
                ],
              ),
              if (tiles.length > 2) ...[
                const SizedBox(height: Sp.s3),
                Row(
                  children: [
                    for (var i = 2; i < 4 && i < tiles.length; i++) ...[
                      Expanded(
                        child: SetTile(
                          label: kpiLabel(context.l10n, tiles[i]),
                          value: tiles[i].value,
                          sub: kpiSub(context.l10n, tiles[i]),
                        ),
                      ),
                      if (i == 2) const SizedBox(width: Sp.s3),
                    ],
                  ],
                ),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(
                child: SetTile(
                  label: kpiLabel(context.l10n, tiles[i]),
                  value: tiles[i].value,
                  sub: kpiSub(context.l10n, tiles[i]),
                ),
              ),
              if (i != tiles.length - 1) const SizedBox(width: Sp.s3),
            ],
          ],
        );
      },
    );
  }

  Widget _coverTrend(BuildContext context, List<CoverDayDto> pairs) {
    final sc = context.sat;
    if (pairs.isEmpty) {
      return _card(
        context,
        context.l10n.rptGuestTrend,
        sub: context.l10n.rptNoData,
        child: const SizedBox(height: Sp.s10),
      );
    }
    final maxVal = pairs
        .expand((p) => [p.thisWeek, p.lastWeek])
        .fold<int>(1, (a, b) => b > a ? b : a);
    final thisWk = pairs.fold<int>(0, (s, p) => s + p.thisWeek);
    final lastWk = pairs.fold<int>(0, (s, p) => s + p.lastWeek);
    final delta = lastWk == 0 ? 0 : ((thisWk - lastWk) / lastWk * 100).round();
    return _card(
      context,
      context.l10n.rptGuestTrend,
      sub: context.l10n.rptGuestTrendSub(
        thisWk,
        '${delta >= 0 ? '+' : ''}$delta',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < pairs.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GrowBarV(
                              width: 9,
                              height: 100 * pairs[i].lastWeek / maxVal,
                              color: sc.bg4,
                              radius: BorderRadius.vertical(top: SatR.c(2)),
                            ),
                            const SizedBox(width: Sp.s1),
                            GrowBarV(
                              width: 9,
                              height: 100 * pairs[i].thisWeek / maxVal,
                              color: sc.accent,
                              radius: BorderRadius.vertical(top: SatR.c(2)),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.s1h),
                        Text(
                          pairs[i].day,
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  if (i != pairs.length - 1) const SizedBox(width: Sp.s1),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sp.s3),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: SatBox.d(color: sc.accent, borderRadius: SatR.a(2)),
              ),
              const SizedBox(width: Sp.s1h),
              Text(
                context.l10n.rptThisWeek,
                style: SatType.bodyS(color: sc.textMd),
              ),
              const SizedBox(width: Sp.s3h),
              Container(
                width: 9,
                height: 9,
                decoration: SatBox.d(color: sc.bg4, borderRadius: SatR.a(2)),
              ),
              const SizedBox(width: Sp.s1h),
              Text(
                context.l10n.rptLastWeek,
                style: SatType.bodyS(color: sc.textMd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hourlyRevenue(BuildContext context, List<double> bars) {
    final sc = context.sat;
    final hours = [
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
    ];
    final safe = bars.length == 12 ? bars : List.filled(12, 0.0);
    final peakIdx = safe.indexed.fold<int>(
      0,
      (best, e) => e.$2 > safe[best] ? e.$1 : best,
    );
    return _card(
      context,
      context.l10n.rptRevenuePerHour,
      sub: context.l10n.rptPeakHour(
        hours[peakIdx],
        (int.parse(hours[peakIdx]) + 1).toString().padLeft(2, '0'),
      ),
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < safe.length; i++) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GrowBarV(
                      height: 100 * safe[i],
                      color: safe[i] >= 0.9 ? sc.accent : sc.bg4,
                      radius: BorderRadius.vertical(top: SatR.c(3)),
                    ),
                    const SizedBox(height: Sp.s1h),
                    Text(hours[i], style: SatType.monoS(color: sc.textLo)),
                  ],
                ),
              ),
              if (i != safe.length - 1) const SizedBox(width: Sp.s1),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────── STAFF ────────────
  Widget _staffSection(BuildContext context, StaffSectionDto staff) {
    final sc = context.sat;
    final rows = [...staff.rows];
    int Function(StaffRowDto) keyer;
    switch (_staffSort) {
      case _StaffSort.net:
        keyer = (r) => -r.net;
        break;
      case _StaffSort.covers:
        keyer = (r) => -r.covers;
        break;
      case _StaffSort.voidPct:
        keyer = (r) => -(r.voidPct * 100).round();
        break;
      case _StaffSort.avgTicket:
        keyer = (r) => -r.avgTicket;
        break;
    }
    rows.sort((a, b) => keyer(a).compareTo(keyer(b)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          context,
          context.l10n.rptWaiterPerf,
          sub: context.l10n.rptWaiterPerfSub(rows.length),
          trailing: _sortMenu(context),
          child: rows.isEmpty
              ? _emptyChunk(context, context.l10n.rptNoClosedSessions)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _staffHead(context),
                    const SizedBox(height: Sp.s1h),
                    Divider(color: sc.border0, height: 1),
                    for (var i = 0; i < rows.length; i++) ...[
                      _staffRow(context, rows[i], i),
                      if (i != rows.length - 1)
                        Divider(color: sc.border0, height: 1),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: Sp.s3h),
        _upsellIndex(context, staff.upsell),
      ],
    );
  }

  Widget _sortMenu(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final label = switch (_staffSort) {
      _StaffSort.net => l10n.rptKpiNet,
      _StaffSort.covers => l10n.rptSortCovers,
      _StaffSort.voidPct => l10n.rptSortVoidPct,
      _StaffSort.avgTicket => l10n.rptSortAvg,
    };
    return PopupMenuButton<_StaffSort>(
      tooltip: l10n.rptSort,
      color: sc.bg1,
      onSelected: (v) => setState(() => _staffSort = v),
      itemBuilder: (c) => [
        for (final s in _StaffSort.values)
          PopupMenuItem(
            value: s,
            child: Text(switch (s) {
              _StaffSort.net => l10n.rptSortNetDesc,
              _StaffSort.covers => l10n.rptSortMostTables,
              _StaffSort.voidPct => l10n.rptSortMostVoids,
              _StaffSort.avgTicket => l10n.rptSortAvgTicket,
            }, style: SatType.bodyM(color: sc.textHi)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s2h,
          vertical: Sp.s1h,
        ),
        decoration: SatBox.d(
          color: sc.bg3,
          border: SatB.all(color: sc.border1),
          borderRadius: SatR.a(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 14, color: sc.textMd),
            const SizedBox(width: Sp.s1h),
            Text(label, style: SatType.bodyS(color: sc.textHi)),
          ],
        ),
      ),
    );
  }

  Widget _staffHead(BuildContext context) {
    final sc = context.sat;
    TextStyle s() => SatType.caption(color: sc.textLo);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(context.l10n.rptColWaiter, style: s())),
          Expanded(
            flex: 2,
            child: Text(
              context.l10n.rptColTables,
              textAlign: TextAlign.right,
              style: s(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              context.l10n.rptColItems,
              textAlign: TextAlign.right,
              style: s(),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.l10n.rptColAvgTicket,
              textAlign: TextAlign.right,
              style: s(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              context.l10n.rptColVoidPct,
              textAlign: TextAlign.right,
              style: s(),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.l10n.rptColNet,
              textAlign: TextAlign.right,
              style: s(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffRow(BuildContext context, StaffRowDto r, int idx) {
    final sc = context.sat;
    final netStr = r.net == 0
        ? '—'
        : 'Rp ${(r.net / 1000000).toStringAsFixed(1)}jt';
    final voidStr = r.voidPct == 0 ? '—' : '${r.voidPct.toStringAsFixed(1)}%';
    final voidColor = r.voidPct > 2.0
        ? sc.warn
        : (r.voidPct > 1.0 ? sc.textMd : sc.textLo);
    final avgStr = r.avgTicket == 0
        ? '—'
        : 'Rp ${(r.avgTicket / 1000).round()}rb';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: SatBox.d(
                    color: idx == 0 ? sc.accentSoft : sc.bg3,
                    border: SatB.all(
                      color: idx == 0 ? sc.accentBorder : sc.border0,
                    ),
                    borderRadius: SatR.a(6),
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: SatType.caption(
                      color: idx == 0 ? sc.accentText : sc.textMd,
                    ),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Expanded(
                  child: Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${r.covers}',
              textAlign: TextAlign.right,
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${r.items}',
              textAlign: TextAlign.right,
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              avgStr,
              textAlign: TextAlign.right,
              style: SatType.monoM(color: sc.textMd),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              voidStr,
              textAlign: TextAlign.right,
              style: SatType.monoM(color: voidColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              netStr,
              textAlign: TextAlign.right,
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upsellIndex(BuildContext context, List<StaffUpsellDto> rows) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(
        context,
        context.l10n.rptUpsell,
        sub: context.l10n.rptNoData,
        child: const SizedBox(height: Sp.s8),
      );
    }
    final positive = rows.where((r) => r.rate > 0).toList();
    final avg = positive.isEmpty
        ? 0.0
        : positive.fold<double>(0, (a, r) => a + r.rate) / positive.length;
    return _card(
      context,
      context.l10n.rptUpsell,
      sub: context.l10n.rptUpsellSub((avg * 100).round()),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                      ),
                      Text(
                        r.rate == 0 ? '—' : '${(r.rate * 100).round()}%',
                        style: SatType.monoM(
                          color: r.rate >= avg ? sc.success : sc.textMd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s1h),
                  AnimatedBarFill(
                    factor: r.rate,
                    color: r.rate >= avg ? sc.success : sc.accent,
                    track: sc.bg3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────── MENU ────────────
  Widget _menuSection(BuildContext context, bool isTab, MenuSectionDto menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _menuList(
                  context,
                  context.l10n.rptTopSellers,
                  menu.top,
                  top: true,
                ),
              ),
              const SizedBox(width: Sp.s3h),
              Expanded(
                child: _menuList(
                  context,
                  context.l10n.rptSlowMovers,
                  menu.slow,
                  top: false,
                ),
              ),
            ],
          )
        else ...[
          _menuList(context, context.l10n.rptTopSellers, menu.top, top: true),
          const SizedBox(height: Sp.s3h),
          _menuList(context, context.l10n.rptSlowMovers, menu.slow, top: false),
        ],
        const SizedBox(height: Sp.s3h),
        _modifierAttach(context, menu.modifierAttach),
        const SizedBox(height: Sp.s3h),
        _menuMatrix(context, menu.matrix),
        const SizedBox(height: Sp.s3h),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _categoryMix(context, menu.categoryMix)),
              const SizedBox(width: Sp.s3h),
              Expanded(child: _basketPairs(context, menu.basketPairs)),
            ],
          )
        else ...[
          _categoryMix(context, menu.categoryMix),
          const SizedBox(height: Sp.s3h),
          _basketPairs(context, menu.basketPairs),
        ],
      ],
    );
  }

  Widget _menuList(
    BuildContext context,
    String title,
    List<MenuItemRowDto> rows, {
    required bool top,
  }) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(
        context,
        title,
        sub: context.l10n.rptNoData,
        child: const SizedBox(height: Sp.s10),
      );
    }
    return _card(
      context,
      title,
      sub: top
          ? context.l10n.rptMenuHighMargin(rows.length)
          : context.l10n.rptMenuSlowStock(rows.length),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].name,
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        const SizedBox(height: Sp.sHair),
                        Text(
                          context.l10n.rptQtyMargin(
                            rows[i].qty,
                            rows[i].marginPct,
                          ),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    _compactRp(rows[i].revenue),
                    style: SatType.monoM(color: sc.textMd),
                  ),
                  const SizedBox(width: Sp.s3),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: SatBox.d(
                      color: sc.bg3,
                      borderRadius: SatR.a(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: rows[i].fill.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: Container(
                        decoration: SatBox.d(
                          color: top ? sc.success : sc.warn,
                          borderRadius: SatR.a(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modifierAttach(BuildContext context, List<ModifierAttachDto> mods) {
    final sc = context.sat;
    if (mods.isEmpty) {
      return _card(
        context,
        context.l10n.rptAttachRate,
        sub: context.l10n.rptAttachRateSub,
        child: const SizedBox(height: Sp.s8),
      );
    }
    return _card(
      context,
      context.l10n.rptAttachRate,
      sub: context.l10n.rptAttachRateSub,
      child: Column(
        children: [
          for (final m in mods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          modifierGroupLabel(context.l10n, m.group),
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                      ),
                      Text(
                        '${(m.rate * 100).round()}%',
                        style: SatType.monoM(color: sc.textHi),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s1h),
                  AnimatedBarFill(
                    factor: m.rate,
                    color: sc.info,
                    track: sc.bg3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Menu classification ("Klasifikasi menu") — four popularity×margin buckets,
  // action-priority order, top items per bucket. Replaces the old scatter matrix.
  Widget _menuMatrix(BuildContext context, List<MatrixItemDto> items) {
    final sc = context.sat;
    final buckets = <_BucketSpec>[
      _BucketSpec(
        'star',
        context.l10n.rptBucketStar,
        context.l10n.rptBucketStarAction,
        sc.success,
      ),
      _BucketSpec(
        'plow',
        context.l10n.rptBucketPlow,
        context.l10n.rptBucketPlowAction,
        sc.warn,
      ),
      _BucketSpec(
        'puzzle',
        context.l10n.rptBucketPuzzle,
        context.l10n.rptBucketPuzzleAction,
        sc.info,
      ),
      _BucketSpec(
        'dog',
        context.l10n.rptBucketDog,
        context.l10n.rptBucketDogAction,
        sc.textLo,
      ),
    ];
    return _card(
      context,
      context.l10n.rptMenuClass,
      sub: context.l10n.rptMenuClassSub,
      child: items.isEmpty
          ? _emptyChunk(context, context.l10n.rptNoDataDot)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(height: Sp.s4),
                  _bucketBlock(
                    context,
                    buckets[i],
                    items.where((it) => it.quadrant == buckets[i].key).toList()
                      ..sort((a, b) => b.popularity.compareTo(a.popularity)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _bucketBlock(
    BuildContext context,
    _BucketSpec spec,
    List<MatrixItemDto> rows,
  ) {
    final sc = context.sat;
    const cap = 5;
    final shown = rows.take(cap).toList();
    final extra = rows.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(spec.label, style: SatType.caption(color: spec.color)),
            const SizedBox(width: Sp.s2),
            Expanded(
              child: Text(
                context.l10n.rptBucketAction(spec.action),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SatType.bodyS(color: sc.textLo),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.s1h),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.s1),
            child: Text(
              context.l10n.rptNoItems,
              style: SatType.bodyS(color: sc.textLo),
            ),
          )
        else ...[
          for (final it in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: Sp.s2),
                    decoration: SatBox.d(
                      color: spec.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.bodyM(color: sc.textHi),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    context.l10n.rptPopMargin(
                      (it.popularity * 100).round(),
                      (it.margin * 100).round(),
                    ),
                    style: SatType.monoS(color: sc.textMd),
                  ),
                ],
              ),
            ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1, left: Sp.s3h),
              child: Text(
                context.l10n.rptMoreItems(extra),
                style: SatType.monoS(color: sc.textLo),
              ),
            ),
        ],
      ],
    );
  }

  Widget _categoryMix(BuildContext context, List<CategoryShareDto> cats) {
    final sc = context.sat;
    if (cats.isEmpty) {
      return _card(
        context,
        context.l10n.rptCategoryMix,
        sub: context.l10n.rptNoData,
        child: const SizedBox(height: Sp.s8),
      );
    }
    final palette = [sc.accent, sc.info, sc.success, sc.violet, sc.warn];
    return _card(
      context,
      context.l10n.rptCategoryMix,
      sub: context.l10n.rptCategoryMixSub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.rptColThisWeek,
            style: SatType.caption(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s1h),
          ClipRRect(
            borderRadius: SatR.a(4),
            child: Row(
              children: [
                for (var i = 0; i < cats.length; i++)
                  Expanded(
                    flex: (cats[i].shareThisWeek * 1000).round().clamp(
                      1,
                      10000,
                    ),
                    child: Container(
                      height: 12,
                      color: palette[i % palette.length],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Sp.s2h),
          Text(
            context.l10n.rptColLastWeek,
            style: SatType.caption(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s1h),
          ClipRRect(
            borderRadius: SatR.a(4),
            child: Row(
              children: [
                for (var i = 0; i < cats.length; i++)
                  Expanded(
                    flex: (cats[i].shareLastWeek * 1000).round().clamp(
                      1,
                      10000,
                    ),
                    child: Container(
                      height: 8,
                      color: palette[i % palette.length].withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Sp.s3h),
          for (var i = 0; i < cats.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: SatBox.d(
                      color: palette[i % palette.length],
                      borderRadius: SatR.a(2),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: Text(
                      cats[i].name,
                      style: SatType.bodyM(color: sc.textHi),
                    ),
                  ),
                  Text(
                    '${(cats[i].shareThisWeek * 100).round()}%',
                    style: SatType.monoM(color: sc.textHi),
                  ),
                  const SizedBox(width: Sp.s2),
                  _deltaPill(
                    context,
                    cats[i].shareThisWeek - cats[i].shareLastWeek,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _deltaPill(BuildContext context, double d) {
    final sc = context.sat;
    final pct = d * 100;
    final up = pct >= 0;
    final color = up ? sc.success : sc.warn;
    final txt = '${up ? '+' : ''}${pct.toStringAsFixed(1)}pp';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(
        color: color.withValues(alpha: 0.12),
        borderRadius: SatR.a(4),
      ),
      child: Text(txt, style: SatType.caption(color: color)),
    );
  }

  Widget _basketPairs(BuildContext context, List<BasketPairDto> pairs) {
    final sc = context.sat;
    if (pairs.isEmpty) {
      return _card(
        context,
        context.l10n.rptBasketPairs,
        sub: context.l10n.rptBasketPairsSub,
        child: const SizedBox(height: Sp.s8),
      );
    }
    return _card(
      context,
      context.l10n.rptBasketPairs,
      sub: context.l10n.rptBasketPairsSub,
      child: Column(
        children: [
          for (var i = 0; i < pairs.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pairs[i].itemA,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.bodyM(color: sc.textHi),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Sp.s1h,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 12,
                                color: sc.textLo,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                pairs[i].itemB,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.bodyM(color: sc.textHi),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.sHair),
                        Text(
                          context.l10n.rptPairCount(pairs[i].count),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    '${(pairs[i].rate * 100).round()}%',
                    style: SatType.monoM(color: sc.info),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────── OPS ────────────
  Widget _opsSection(BuildContext context, bool isTab, OpsSectionDto ops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _opsKpis(context, ops.kpis),
        const SizedBox(height: Sp.s3h),
        _speedOfService(context, ops.speed),
        const SizedBox(height: Sp.s3h),
        _heatmap(context, ops.heatmap),
        const SizedBox(height: Sp.s3h),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _reservationConv(context, ops.reservations)),
              const SizedBox(width: Sp.s3h),
              Expanded(child: _voidReasons(context, ops.voidReasons)),
            ],
          )
        else ...[
          _reservationConv(context, ops.reservations),
          const SizedBox(height: Sp.s3h),
          _voidReasons(context, ops.voidReasons),
        ],
        const SizedBox(height: Sp.s3h),
        _voidByStaff(context, ops.voidByStaff),
      ],
    );
  }

  Widget _opsKpis(BuildContext context, List<KpiTileDto> kpis) {
    final tiles = kpis.isEmpty
        ? [
            KpiTileDto(
              label: context.l10n.rptKpiTurnTime,
              value: '—',
              sub: context.l10n.rptNoDataLower,
            ),
            KpiTileDto(label: context.l10n.rptKpiPrep, value: '—', sub: '—'),
            KpiTileDto(label: context.l10n.rptKpiPickup, value: '—', sub: '—'),
            KpiTileDto(
              label: context.l10n.rptKpiReservations,
              value: '—',
              sub: '—',
            ),
          ]
        : kpis;
    return LayoutBuilder(
      builder: (c, cons) {
        final narrow = cons.maxWidth < 520;
        if (narrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SetTile(
                      label: kpiLabel(context.l10n, tiles[0]),
                      value: tiles[0].value,
                      sub: kpiSub(context.l10n, tiles[0]),
                    ),
                  ),
                  const SizedBox(width: Sp.s3),
                  if (tiles.length > 1)
                    Expanded(
                      child: SetTile(
                        label: kpiLabel(context.l10n, tiles[1]),
                        value: tiles[1].value,
                        sub: kpiSub(context.l10n, tiles[1]),
                      ),
                    ),
                ],
              ),
              if (tiles.length > 2) ...[
                const SizedBox(height: Sp.s3),
                Row(
                  children: [
                    Expanded(
                      child: SetTile(
                        label: kpiLabel(context.l10n, tiles[2]),
                        value: tiles[2].value,
                        sub: kpiSub(context.l10n, tiles[2]),
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    if (tiles.length > 3)
                      Expanded(
                        child: SetTile(
                          label: kpiLabel(context.l10n, tiles[3]),
                          value: tiles[3].value,
                          sub: kpiSub(context.l10n, tiles[3]),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(
                child: SetTile(
                  label: kpiLabel(context.l10n, tiles[i]),
                  value: tiles[i].value,
                  sub: kpiSub(context.l10n, tiles[i]),
                ),
              ),
              if (i != tiles.length - 1) const SizedBox(width: Sp.s3),
            ],
          ],
        );
      },
    );
  }

  Widget _speedOfService(BuildContext context, SpeedSectionDto s) {
    final sc = context.sat;
    if (s.sampleSize == 0) {
      return _card(
        context,
        context.l10n.rptServiceSpeed,
        sub: context.l10n.rptServiceSpeedEmpty,
        child: const SizedBox(height: Sp.s8),
      );
    }
    // SLA color: green when most plates beat the target, amber mid, red poor.
    final slaColor = s.slaPct >= 80
        ? sc.success
        : (s.slaPct >= 60 ? sc.warn : sc.urgent);
    final maxAvg = s.slowItems.isEmpty
        ? 1.0
        : s.slowItems
              .map((i) => i.avgPrepMin)
              .fold<double>(0.1, (a, b) => b > a ? b : a);
    return _card(
      context,
      context.l10n.rptServiceSpeed,
      sub: context.l10n.rptServiceSpeedSub(
        s.prepMedianMin,
        s.pickupMedianMin,
        s.sampleSize,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SLA hit-rate against the configurable target.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${s.slaPct.round()}%',
                style: SatType.monoL(color: slaColor),
              ),
              const SizedBox(width: Sp.s2),
              Expanded(
                // Targets resolve per item now, so the headline cannot name a
                // single number — the percentage is still one honest figure
                // ("% of courses that hit their own target"). ADR-0043.
                child: Text(
                  context.l10n.rptSlaCourses,
                  style: SatType.bodyS(color: sc.textMd),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          AnimatedBarFill(
            factor: s.slaPct / 100,
            color: slaColor,
            track: sc.bg3,
            height: 6,
          ),
          // The two thresholds added by ADR-0044, each reported against the
          // number that actually drives its cue.
          if (s.pickupSlaPct > 0 || s.pickupMedianMin > 0)
            _MiniStatRow(
              label: context.l10n.rptPickupSla(s.pickupTargetMins),
              value: '${s.pickupSlaPct.round()}%',
              sub: context.l10n.rptMedianMins(s.pickupMedianMin),
            ),
          if (s.greetSampleSize > 0)
            _MiniStatRow(
              label: context.l10n.rptGreetBreach(s.ungreetedMins),
              value: '${s.greetBreachPct.round()}%',
              sub: context.l10n.rptGreetSub(
                s.greetMedianMin,
                s.greetSampleSize,
              ),
            ),
          if (s.slowItems.isNotEmpty) ...[
            const SizedBox(height: Sp.s4),
            // Neutral ranked list, no pass/fail verdict: once coursing governs
            // lateness, an item's own target is not what it was judged on, and
            // a "sides" item would red permanently for correctly waiting on
            // its mains. ADR-0043.
            Text(
              context.l10n.rptSlowestMenu,
              style: SatType.labelS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s2),
            for (final it in s.slowItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SatType.bodyM(color: sc.textHi),
                          ),
                        ),
                        Text(
                          '${it.avgPrepMin.toStringAsFixed(1)}m',
                          style: SatType.monoM(color: sc.textHi),
                        ),
                        const SizedBox(width: Sp.s2),
                        Text(
                          '×${it.count}',
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.s1h),
                    AnimatedBarFill(
                      factor: it.avgPrepMin / maxAvg,
                      color: sc.info,
                      track: sc.bg3,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _heatmap(BuildContext context, List<List<double>> grid) {
    final sc = context.sat;
    if (grid.isEmpty || grid.first.isEmpty) {
      return _card(
        context,
        context.l10n.rptHeatmap,
        sub: context.l10n.rptHeatmapSub,
        child: const SizedBox(height: Sp.s8),
      );
    }
    // Weekday names are a date, and dates follow the language (ADR-0084).
    // 2024-01-01 was a Monday, so this walks Mon→Sun in whichever locale.
    final dow = DateFormat.E(context.l10n.localeName);
    final days = [
      for (var i = 0; i < 7; i++) dow.format(DateTime(2024, 1, 1 + i)),
    ];
    const hours = ['11', '', '13', '', '15', '', '17', '', '19', '', '21', ''];
    return _card(
      context,
      context.l10n.rptHeatmap,
      sub: context.l10n.rptHeatmapSub,
      child: LayoutBuilder(
        builder: (c, cons) {
          final cellW = (cons.maxWidth - 32) / 12;
          final cell = cellW.clamp(14.0, 28.0);
          return Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: Sp.s8),
                  for (var i = 0; i < hours.length; i++)
                    SizedBox(
                      width: cell,
                      child: Text(
                        hours[i],
                        textAlign: TextAlign.center,
                        style: SatType.monoS(color: sc.textLo),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Sp.s1),
              for (var r = 0; r < grid.length && r < days.length; r++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.sHair),
                  child: Row(
                    children: [
                      SizedBox(
                        width: Sp.s8,
                        child: Text(
                          days[r],
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ),
                      for (var col = 0; col < grid[r].length && col < 12; col++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.sHair,
                          ),
                          child: Container(
                            width: cell - 2,
                            height: cell - 2,
                            decoration: SatBox.d(
                              color: Color.lerp(
                                sc.bg3,
                                sc.accent,
                                grid[r][col].clamp(0.0, 1.0),
                              ),
                              borderRadius: SatR.a(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: Sp.s2h),
              Row(
                children: [
                  Text(
                    context.l10n.rptHeatQuiet,
                    style: SatType.monoS(color: sc.textLo),
                  ),
                  const SizedBox(width: Sp.s1h),
                  for (var i = 0; i < 5; i++) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: SatBox.d(
                        color: Color.lerp(sc.bg3, sc.accent, i / 4),
                        borderRadius: SatR.a(2),
                      ),
                    ),
                    const SizedBox(width: Sp.sHair),
                  ],
                  const SizedBox(width: Sp.s1),
                  Text(
                    context.l10n.rptHeatBusy,
                    style: SatType.monoS(color: sc.textLo),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reservationConv(BuildContext context, ReservationStatsDto r) {
    final sc = context.sat;
    final booked = r.booked;
    if (booked == 0) {
      return _card(
        context,
        context.l10n.rptReservationConv,
        sub: context.l10n.rptReservationNoModule,
        child: _emptyChunk(context, context.l10n.rptReservationNoModuleBody),
      );
    }
    final seatedPct = r.seated / booked;
    final noShowPct = r.noShow / booked;
    final cancelPct = r.cancelled / booked;
    return _card(
      context,
      context.l10n.rptReservationConv,
      sub: context.l10n.rptReservationSub(booked, r.seated, r.noShow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: SatR.a(6),
            child: Row(
              children: [
                Expanded(
                  flex: (seatedPct * 1000).round().clamp(1, 10000),
                  child: Container(height: 14, color: sc.success),
                ),
                Expanded(
                  flex: (noShowPct * 1000).round().clamp(1, 10000),
                  child: Container(height: 14, color: sc.warn),
                ),
                Expanded(
                  flex: (cancelPct * 1000).round().clamp(1, 10000),
                  child: Container(height: 14, color: sc.textLo),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.s3h),
          _resvRow(
            context,
            sc.success,
            context.l10n.rptSeated,
            r.seated,
            seatedPct,
          ),
          _resvRow(
            context,
            sc.warn,
            context.l10n.rptNoShow,
            r.noShow,
            noShowPct,
          ),
          _resvRow(
            context,
            sc.textLo,
            context.l10n.rptCancelled,
            r.cancelled,
            cancelPct,
          ),
        ],
      ),
    );
  }

  Widget _resvRow(
    BuildContext context,
    Color color,
    String label,
    int n,
    double pct,
  ) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: SatBox.d(color: color, borderRadius: SatR.a(2)),
          ),
          const SizedBox(width: Sp.s2h),
          Expanded(
            child: Text(label, style: SatType.bodyM(color: sc.textHi)),
          ),
          Text('$n', style: SatType.monoM(color: sc.textMd)),
          const SizedBox(width: Sp.s2h),
          Text(
            '${(pct * 100).round()}%',
            style: SatType.monoM(color: sc.textHi),
          ),
        ],
      ),
    );
  }

  Widget _voidReasons(BuildContext context, List<VoidReasonDto> rows) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(
        context,
        context.l10n.rptVoidReasons,
        sub: context.l10n.rptNoVoids,
        child: const SizedBox(height: Sp.s8),
      );
    }
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    final totalRp = rows.fold<int>(0, (s, r) => s + r.lostRupiah);
    final maxN = rows.map((r) => r.count).fold<int>(1, (a, b) => b > a ? b : a);
    final palette = [
      sc.warn,
      sc.info,
      sc.violet,
      sc.textLo,
      sc.urgent,
      sc.success,
    ];
    return _card(
      context,
      context.l10n.rptVoidReasons,
      sub: context.l10n.rptVoidSub(total, _compactRp(totalRp)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          voidReasonLabel(context.l10n, rows[i].code),
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                      ),
                      Text(
                        '${rows[i].count}×',
                        style: SatType.monoM(color: sc.textHi),
                      ),
                      const SizedBox(width: Sp.s2h),
                      Text(
                        _compactRp(rows[i].lostRupiah),
                        style: SatType.monoS(color: sc.textMd),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s1h),
                  AnimatedBarFill(
                    factor: rows[i].count / maxN,
                    color: palette[i % palette.length],
                    track: sc.bg3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _voidByStaff(BuildContext context, List<StaffVoidDto> rows) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(
        context,
        context.l10n.rptVoidPerWaiter,
        sub: context.l10n.rptNoVoids,
        child: const SizedBox(height: Sp.s8),
      );
    }
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    final totalRp = rows.fold<int>(0, (s, r) => s + r.lostRupiah);
    final maxN = rows.map((r) => r.count).fold<int>(1, (a, b) => b > a ? b : a);
    return _card(
      context,
      context.l10n.rptVoidPerWaiter,
      sub: context.l10n.rptVoidSub(total, _compactRp(totalRp)),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staffName(context.l10n, r.id, r.name),
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                      ),
                      Text(
                        '${r.count}×',
                        style: SatType.monoM(color: sc.textHi),
                      ),
                      const SizedBox(width: Sp.s2h),
                      Text(
                        _compactRp(r.lostRupiah),
                        style: SatType.monoS(color: sc.textMd),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.s1),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedBarFill(
                          factor: r.count / maxN,
                          color: sc.warn,
                          track: sc.bg3,
                        ),
                      ),
                      const SizedBox(width: Sp.s2h),
                      Text(
                        context.l10n.rptTopReason(
                          voidReasonLabel(context.l10n, r.topReasonCode),
                        ),
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s7),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0, style: BorderStyle.solid),
        borderRadius: SatR.a(16),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, color: sc.textLo, size: 28),
          const SizedBox(height: Sp.s2h),
          Text(
            context.l10n.rptNoSection,
            style: SatType.labelM(color: sc.textHi),
          ),
          const SizedBox(height: Sp.s1),
          Text(
            context.l10n.rptNoSectionBody,
            style: SatType.bodyS(color: sc.textMd),
          ),
        ],
      ),
    );
  }

  Widget _emptyChunk(BuildContext context, String text) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
      child: Text(text, style: SatType.bodyS(color: sc.textMd)),
    );
  }

  String _compactRp(int v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).round()}rb';
    return 'Rp $v';
  }
}

/// Compact secondary metric row: a label, its figure, and one line of context.
/// Deliberately verdict-free — these report against thresholds the owner set,
/// so the number is the point, not a colour telling them how to feel about it.
class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(top: Sp.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SatType.bodyS(color: sc.textMd)),
                const SizedBox(height: Sp.sHair),
                Text(sub, style: SatType.bodyS(color: sc.textLo)),
              ],
            ),
          ),
          Text(value, style: SatType.monoM(color: sc.textHi)),
        ],
      ),
    );
  }
}
