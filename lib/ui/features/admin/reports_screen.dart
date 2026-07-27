import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart' show customRangeLabel;
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/widgets/custom_range_sheet.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/export_sheet.dart';
import 'package:satset/ui/core/widgets/skeleton_card.dart';
import 'package:satset/ui/features/admin/report_sections_view.dart';
import '_common.dart';

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
  static const _rangeLabel = {
    ReportRange.today: 'Hari ini',
    ReportRange.yesterday: 'Kemarin',
    ReportRange.d7: '7 hari',
    ReportRange.d30: '30 hari',
    ReportRange.month: 'Bulan ini',
    ReportRange.custom: 'Custom',
  };

  /// Chip text: fixed presets read the static map; a committed custom window
  /// shows its span ("12 Jun – 15 Jun"), an uncommitted one stays "Custom".
  String _chipLabel(ReportRange r, ReportsQuery q) {
    if (r == ReportRange.custom && q.customFrom != null && q.customTo != null) {
      return customRangeLabel(q.customFrom!, q.customTo!);
    }
    return _rangeLabel[r]!;
  }

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
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Laporan',
                      style: SatType.sans(
                        size: 30,
                        weight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: sc.textHi,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showExportSheet(
                      context,
                      ref,
                      snapshot: snapshot,
                      query: query,
                    ),
                    child: adminPill(context, 'Ekspor', on: false),
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
      title: 'Laporan',
      sub: _rangeSub(snapshot, query),
      subLeading: snapshot == null ? null : _freshnessDot(context, query),
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () =>
                showExportSheet(context, ref, snapshot: snapshot, query: query),
            child: adminPill(context, 'Ekspor', on: false),
          ),
          const SizedBox(width: 8),
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
      tooltip: 'Muat ulang',
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(sc.accentText),
              ),
            )
          : Icon(Icons.refresh, color: sc.textMd),
    );
  }

  String _rangeSub(ReportsSnapshotDto? snapshot, ReportsQuery query) {
    if (snapshot == null) return 'Memuat laporan…';
    final fresh = query.range == ReportRange.today ? 'Live' : 'Snapshot';
    return '$fresh · ${_humanRange(query)} · ${_fmtRange(snapshot.rangeFrom, snapshot.rangeTo)}';
  }

  String _humanRange(ReportsQuery q) =>
      q.range == ReportRange.custom ? 'Custom' : _rangeLabel[q.range]!;

  String _fmtRange(String fromIso, String toIso) {
    final from = DateTime.parse(fromIso).toLocal();
    final to = DateTime.parse(toIso).toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    String d(DateTime t) => '${t.day} ${months[t.month - 1]}';
    return '${d(from)} — ${d(to.subtract(const Duration(seconds: 1)))}';
  }

  List<Widget> _body(
    BuildContext context,
    bool isTab,
    ReportsSnapshotDto? snapshot,
    AsyncValue<void> status,
    ReportsQuery query,
  ) {
    return [
      if (status.hasError) ...[
        _errorBanner(context, status),
        const SizedBox(height: 12),
      ],
      _rangeRow(context, query),
      const SizedBox(height: 12),
      _filterRow(context, snapshot, query),
      const SizedBox(height: 12),
      if (snapshot == null)
        const ReportsSkeleton()
      else
        ReportSectionsView(
          snapshot: snapshot,
          isTab: isTab,
          loading: status.isLoading,
        ),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gagal memuat laporan',
              style: SatType.sans(
                size: 13,
                weight: FontWeight.w500,
                color: sc.textHi,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(reportsRepositoryProvider.notifier).refresh(),
            child: adminPill(context, 'Coba lagi'),
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
            GestureDetector(
              onTap: r == ReportRange.custom
                  ? _openCustomSheet
                  : () => _setRange(r),
              child: adminPill(
                context,
                _chipLabel(r, query),
                on: query.range == r,
              ),
            ),
            const SizedBox(width: 8),
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
    final servers = snapshot?.filterOptions.servers ?? const <NamedIdDto>[];
    final zones = snapshot?.filterOptions.zones ?? const <NamedIdDto>[];
    final categories =
        snapshot?.filterOptions.categories ?? const <NamedIdDto>[];
    final serverName = servers
        .firstWhere(
          (s) => s.id == query.serverId,
          orElse: () => const NamedIdDto(id: '', name: 'Semua pelayan'),
        )
        .name;
    final zoneName = zones
        .firstWhere(
          (z) => z.id == query.zoneId,
          orElse: () => const NamedIdDto(id: '', name: 'Semua zona'),
        )
        .name;
    final categoryName = categories
        .firstWhere(
          (c) => c.id == query.categoryId,
          orElse: () => const NamedIdDto(id: '', name: 'Semua kategori'),
        )
        .name;

    return Row(
      children: [
        Expanded(
          child: _filterChip(
            context,
            'Pelayan',
            serverName,
            [const NamedIdDto(id: '', name: 'Semua pelayan'), ...servers],
            (n) => _setServer(n.id.isEmpty ? null : n.id),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(context, 'Zona', zoneName, [
            const NamedIdDto(id: '', name: 'Semua zona'),
            ...zones,
          ], (n) => _setZone(n.id.isEmpty ? null : n.id)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(
            context,
            'Kategori',
            categoryName,
            [const NamedIdDto(id: '', name: 'Semua kategori'), ...categories],
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
    List<NamedIdDto> options,
    ValueChanged<NamedIdDto> onPick,
  ) {
    final sc = context.sat;
    final active = !value.toLowerCase().startsWith('semua');
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<NamedIdDto>(
          context: context,
          useRootNavigator: true,
          backgroundColor: sc.bg1,
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
                      style: SatType.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: sc.textLo,
                      ),
                    ),
                  ),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(
                      o.name,
                      style: SatType.sans(size: 14, color: sc.textHi),
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    style: SatType.mono(
                      size: 9,
                      weight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: sc.textLo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.sans(
                      size: 13,
                      weight: FontWeight.w500,
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
