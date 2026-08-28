import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import 'package:satset/core/export/export_share.dart' show rangeLabel;
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/widgets/custom_range_sheet.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/export_sheet.dart';
import 'package:satset/ui/core/widgets/skeleton_card.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/ui/features/admin/report_ringkas.dart';
import 'package:satset/ui/features/admin/report_sections_view.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Admin → Reports. Owns the report **chrome** — range pills, server/zone/
/// category filters, export, freshness — and delegates the five-section
/// rendering to [ReportSectionsView] (shared with the off-site owner view,
/// ADR-0036).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// Chip text: a committed custom window shows its span ("12 Jun – 15 Jun"),
  /// an uncommitted one stays "Khusus". Shares [rangeLabel] with the export
  /// sheet and the exporters — the screen used to carry its own copy of the
  /// same six-entry table, which is how a chip and the PDF it produces end up
  /// disagreeing about what "this month" is called.
  String _chipLabel(ReportRange r, ReportsQuery q) =>
      rangeLabel(context.l10n, r, from: q.customFrom, to: q.customTo);

  void _setRange(ReportRange r) {
    final q = ref.read(reportsQueryProvider);
    ref.read(reportsQueryProvider.notifier).state = q.copyWith(range: r);
  }

  /// Tap on the Custom chip: open the date sheet, commit only on "Terapkan".
  /// Dismissing leaves the active range untouched.
  Future<void> _openCustomSheet() async {
    final q = ref.read(reportsQueryProvider);
    final picked = await showCustomRangeSheet(
      context,
      initialFrom: q.customFrom,
      initialTo: q.customTo,
    );
    if (picked == null) return;
    ref.read(reportsQueryProvider.notifier).state = q.copyWith(
      range: ReportRange.custom,
      customFrom: picked.$1,
      customTo: picked.$2,
    );
  }

  void _setServer(String? id) {
    final q = ref.read(reportsQueryProvider);
    ref.read(reportsQueryProvider.notifier).state = q.copyWith(serverId: id);
  }

  void _setZone(String? id) {
    final q = ref.read(reportsQueryProvider);
    ref.read(reportsQueryProvider.notifier).state = q.copyWith(zoneId: id);
  }

  void _setCategory(String? id) {
    final q = ref.read(reportsQueryProvider);
    ref.read(reportsQueryProvider.notifier).state = q.copyWith(categoryId: id);
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.layout.useTabletShell;
    final snapshot = ref.watch(reportsRepositoryProvider);
    final status = ref.watch(reportsStatusProvider);
    final query = ref.watch(reportsQueryProvider);
    final body = _body(context, isTab, snapshot, status, query);
    if (!isTab) {
      final sc = context.sat;
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.venueHubSectionReports,
                      style: SatType.h1(color: sc.textHi),
                    ),
                  ),
                  SatButton.outline(
                    label: context.l10n.auditExport,
                    size: SatButtonSize.sm,
                    onTap: () => showExportSheet(
                      context,
                      ref,
                      snapshot: snapshot,
                      query: query,
                    ),
                  ),
                ],
              ),
            ),
            ...body,
          ],
        ),
      );
    }
    return AdminPage(
      title: context.l10n.venueHubSectionReports,
      sub: _rangeSub(context, snapshot, query),
      subLeading: snapshot == null ? null : _freshnessDot(context, query),
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SatButton.outline(
            label: context.l10n.auditExport,
            size: SatButtonSize.sm,
            onTap: () =>
                showExportSheet(context, ref, snapshot: snapshot, query: query),
          ),
          const SizedBox(width: Sp.s2),
          _refreshButton(
            context,
            status.isLoading,
            () => ref.read(reportsRepositoryProvider.notifier).refresh(),
          ),
        ],
      ),
      children: body,
    );
  }

  /// Freshness indicator for the subtitle: green when the report is [Live]
  /// (range includes today), muted when it is a frozen Snapshot.
  Widget _freshnessDot(BuildContext context, ReportsQuery query) {
    final sc = context.sat;
    final live = query.range == ReportRange.today;
    return Container(
      width: 7,
      height: 7,
      decoration: SatBox.d(
        color: live ? sc.success : sc.textLo,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Icon-only manual resync. Swaps to a spinner while loading and is inert
  /// during the fetch.
  Widget _refreshButton(
    BuildContext context,
    bool loading,
    VoidCallback onTap,
  ) {
    final sc = context.sat;
    return IconButton(
      onPressed: loading ? null : onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      tooltip: context.l10n.a11yRefresh,
      icon: loading
          ? SatSpinner(size: SatSpinnerSize.xs)
          : Icon(Icons.refresh, color: sc.textMd),
    );
  }

  String _rangeSub(
    BuildContext context,
    ReportsSnapshotDto? snapshot,
    ReportsQuery query,
  ) {
    if (snapshot == null) return context.l10n.rptLoading;
    final fresh = query.range == ReportRange.today
        ? context.l10n.rptFreshLive
        : context.l10n.rptFreshSnapshot;
    return '$fresh · ${_humanRange(query)} · ${_fmtRange(snapshot.rangeFrom, snapshot.rangeTo)}';
  }

  String _humanRange(ReportsQuery q) => rangeLabel(context.l10n, q.range);

  String _fmtRange(String fromIso, String toIso) {
    final from = DateTime.parse(fromIso).toLocal();
    final to = DateTime.parse(toIso).toLocal();
    // Dates localise (ADR-0084), so the hand-rolled Indonesian month array
    // that used to sit here is gone — it printed `Agu` inside an English shell.
    final d = DateFormat('d MMM');
    return '${d.format(from)} — '
        '${d.format(to.subtract(const Duration(seconds: 1)))}';
  }

  List<Widget> _body(
    BuildContext context,
    bool isTab,
    ReportsSnapshotDto? snapshot,
    AsyncValue<void> status,
    ReportsQuery query,
  ) {
    final ringkas = ref
        .watch(venueSettingsProvider)
        .counterOn(counterRingkasReport);
    return [
      if (status.hasError) ...[
        _errorBanner(context, status),
        const SizedBox(height: Sp.s3),
      ],
      _rangeRow(context, query),
      const SizedBox(height: Sp.s3),
      _filterRow(context, snapshot, query),
      const SizedBox(height: Sp.s3),
      if (snapshot == null)
        const ReportsSkeleton()
      else ...[
        if (ringkas) ...[
          ReportRingkas(snapshot: snapshot),
          const SizedBox(height: Sp.s3),
        ],
        ReportSectionsView(
          snapshot: snapshot,
          isTab: isTab,
          loading: status.isLoading,
          compact: ringkas,
        ),
      ],
    ];
  }

  Widget _errorBanner(BuildContext context, AsyncValue<void> status) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: SatBox.d(
        color: sc.warn.withValues(alpha: 0.08),
        border: SatB.all(color: sc.warn.withValues(alpha: 0.25)),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: sc.warn, size: 18),
          const SizedBox(width: Sp.s2h),
          Expanded(
            child: Text(
              context.l10n.rptLoadFailed,
              style: SatType.bodyM(color: sc.textHi),
            ),
          ),
          SatButton.outline(
            label: context.l10n.retry,
            size: SatButtonSize.sm,
            onTap: () => ref.read(reportsRepositoryProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _rangeRow(BuildContext context, ReportsQuery query) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in ReportRange.values) ...[
            SatButton.outline(
              label: _chipLabel(r, query),
              size: SatButtonSize.sm,
              onTap: r == ReportRange.custom
                  ? _openCustomSheet
                  : () => _setRange(r),
            ),
            const SizedBox(width: Sp.s2),
          ],
        ],
      ),
    );
  }

  Widget _filterRow(
    BuildContext context,
    ReportsSnapshotDto? snapshot,
    ReportsQuery query,
  ) {
    final l = context.l10n;
    final servers = snapshot?.filterOptions.servers ?? const <NamedIdDto>[];
    final zones = snapshot?.filterOptions.zones ?? const <NamedIdDto>[];
    final categories =
        snapshot?.filterOptions.categories ?? const <NamedIdDto>[];
    final serverName = servers
        .firstWhere(
          (s) => s.id == query.serverId,
          orElse: () => NamedIdDto(id: '', name: l.rptAllWaiters),
        )
        .name;
    final zoneName = zones
        .firstWhere(
          (z) => z.id == query.zoneId,
          orElse: () => NamedIdDto(id: '', name: l.rptAllZones),
        )
        .name;
    final categoryName = categories
        .firstWhere(
          (c) => c.id == query.categoryId,
          orElse: () => NamedIdDto(id: '', name: l.rptAllCategories),
        )
        .name;

    return Row(
      children: [
        Expanded(
          child: _filterChip(
            context,
            l.expColWaiter,
            serverName,
            query.serverId != null,
            [NamedIdDto(id: '', name: l.rptAllWaiters), ...servers],
            (n) => _setServer(n.id.isEmpty ? null : n.id),
          ),
        ),
        const SizedBox(width: Sp.s2),
        Expanded(
          child: _filterChip(
            context,
            l.venueHubSectionZona,
            zoneName,
            query.zoneId != null,
            [NamedIdDto(id: '', name: l.rptAllZones), ...zones],
            (n) => _setZone(n.id.isEmpty ? null : n.id),
          ),
        ),
        const SizedBox(width: Sp.s2),
        Expanded(
          child: _filterChip(
            context,
            l.mnaTabCategories,
            categoryName,
            query.categoryId != null,
            [NamedIdDto(id: '', name: l.rptAllCategories), ...categories],
            (n) => _setCategory(n.id.isEmpty ? null : n.id),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String value,
    // Whether a filter is actually set. Read off the query, never off the
    // rendered value: "Semua zona" is copy, and matching on it broke the
    // moment the same chip could read "All zones".
    bool active,
    List<NamedIdDto> options,
    ValueChanged<NamedIdDto> onPick,
  ) {
    final sc = context.sat;
    return InkWell(
      onTap: () async {
        final picked = await showSatSheet<NamedIdDto>(
          context,
          builder: (c) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label.toUpperCase(),
                      style: SatType.caption(color: sc.textLo),
                    ),
                  ),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(o.name, style: SatType.bodyM(color: sc.textHi)),
                    trailing: o.name == value
                        ? Icon(Icons.check, color: sc.accentText, size: 18)
                        : null,
                    onTap: () => Navigator.pop(c, o),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: SatR.a(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s3,
          vertical: Sp.s2h,
        ),
        decoration: SatBox.d(
          color: active ? sc.accentSoft : sc.bg2,
          border: SatB.all(color: active ? sc.accentBorder : sc.border0),
          borderRadius: SatR.a(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: SatType.caption(color: sc.textLo),
                  ),
                  const SizedBox(height: Sp.sHair),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.bodyM(
                      color: active ? sc.accentText : sc.textHi,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: sc.textLo),
          ],
        ),
      ),
    );
  }
}
