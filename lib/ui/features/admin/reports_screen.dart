import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart' show customRangeLabel;
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/widgets/custom_range_sheet.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart'
    show PaymentProofThumb;
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/export_sheet.dart';
import 'package:satset/ui/core/widgets/skeleton_card.dart';
import '_common.dart';

enum _Section { sales, staff, menu, ops, payments }

enum _StaffSort { net, covers, voidPct, avgTicket }

class _BucketSpec {
  const _BucketSpec(this.key, this.label, this.action, this.color);
  final String key;
  final String label;
  final String action;
  final Color color;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final Set<_Section> _on = {
    _Section.sales,
    _Section.staff,
    _Section.menu,
    _Section.ops,
    _Section.payments,
  };
  _StaffSort _staffSort = _StaffSort.net;

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
    if (r == ReportRange.custom &&
        q.customFrom != null &&
        q.customTo != null) {
      return customRangeLabel(q.customFrom!, q.customTo!);
    }
    return _rangeLabel[r]!;
  }

  static const _sectionLabel = {
    _Section.sales: 'Penjualan',
    _Section.staff: 'Staf',
    _Section.menu: 'Menu',
    _Section.ops: 'Operasi',
    _Section.payments: 'Pembayaran',
  };

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
                    child: Text('Laporan',
                        style: SatType.sans(
                          size: 30,
                          weight: FontWeight.w600,
                          letterSpacing: -0.6,
                          color: sc.textHi,
                        )),
                  ),
                  GestureDetector(
                    onTap: () => showExportSheet(context, ref,
                        snapshot: snapshot, query: query),
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
            onTap: () => showExportSheet(context, ref,
                snapshot: snapshot, query: query),
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
      decoration: BoxDecoration(
        color: live ? sc.success : sc.textLo,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Icon-only manual resync. Swaps to a spinner while loading and is inert
  /// during the fetch.
  Widget _refreshButton(BuildContext context, bool loading, VoidCallback onTap) {
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
                valueColor: AlwaysStoppedAnimation<Color>(sc.accent),
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
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
      _sectionTabs(context),
      const SizedBox(height: 14),
      if (snapshot == null)
        const ReportsSkeleton()
      else
        _sections(context, isTab, snapshot, status.isLoading),
    ];
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
            child: _salesSection(context, isTab, snapshot.sales)),
      if (_on.contains(_Section.staff))
        Reveal(
            key: const ValueKey('staff'),
            index: 1,
            child: _staffSection(context, snapshot.staff)),
      if (_on.contains(_Section.menu))
        Reveal(
            key: const ValueKey('menu'),
            index: 2,
            child: _menuSection(context, isTab, snapshot.menu)),
      if (_on.contains(_Section.ops))
        Reveal(
            key: const ValueKey('ops'),
            index: 3,
            child: _opsSection(context, isTab, snapshot.ops)),
      if (_on.contains(_Section.payments))
        Reveal(
            key: const ValueKey('payments'),
            index: 4,
            child: _paymentsSection(context, snapshot.payments)),
    ];
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var k = 0; k < blocks.length; k++) ...[
          blocks[k],
          if (k != blocks.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: kSatEase,
          opacity: loading ? 0.45 : 1,
          child: IgnorePointer(ignoring: loading, child: col),
        ),
        if (loading)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation(sc.accent),
            ),
          ),
          const SizedBox(width: 9),
          Text('Memperbarui…',
              style: SatType.sans(
                  size: 12, weight: FontWeight.w500, color: sc.textHi)),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, AsyncValue<void> status) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: sc.warn.withValues(alpha: 0.08),
        border: Border.all(color: sc.warn.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: sc.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Gagal memuat laporan',
                style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(reportsRepositoryProvider.notifier).refresh(),
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
              child: adminPill(context, _chipLabel(r, query),
                  on: query.range == r),
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
    final categories = snapshot?.filterOptions.categories ?? const <NamedIdDto>[];
    final serverName =
        servers.firstWhere((s) => s.id == query.serverId,
                orElse: () => const NamedIdDto(id: '', name: 'Semua pelayan'))
            .name;
    final zoneName =
        zones.firstWhere((z) => z.id == query.zoneId,
                orElse: () => const NamedIdDto(id: '', name: 'Semua zona'))
            .name;
    final categoryName = categories
        .firstWhere((c) => c.id == query.categoryId,
            orElse: () => const NamedIdDto(id: '', name: 'Semua kategori'))
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
          child: _filterChip(
            context,
            'Zona',
            zoneName,
            [const NamedIdDto(id: '', name: 'Semua zona'), ...zones],
            (n) => _setZone(n.id.isEmpty ? null : n.id),
          ),
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
                    child: Text(label.toUpperCase(),
                        style: SatType.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: sc.textLo,
                        )),
                  ),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(o.name, style: SatType.sans(size: 14, color: sc.textHi)),
                    trailing: o.name == value
                        ? Icon(Icons.check, color: sc.accent, size: 18)
                        : null,
                    onTap: () => Navigator.pop(c, o),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? sc.accentSoft : sc.bg2,
          border: Border.all(color: active ? sc.accentBorder : sc.border0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: SatType.mono(
                        size: 9,
                        weight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: sc.textLo,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.sans(
                        size: 13,
                        weight: FontWeight.w500,
                        color: active ? sc.accent : sc.textHi,
                      )),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: sc.textLo),
          ],
        ),
      ),
    );
  }

  Widget _sectionTabs(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(12),
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
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _on.contains(s) ? sc.bg4 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(_sectionLabel[s]!,
                      style: SatType.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: _on.contains(s) ? sc.textHi : sc.textLo,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title,
      {String? sub, required Widget child, Widget? trailing}) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
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
                    Text(title,
                        style: SatType.sans(
                            size: 15,
                            weight: FontWeight.w600,
                            color: sc.textHi)),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(),
                          style: SatType.mono(
                              size: 10, color: sc.textLo, letterSpacing: 0.8)),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ──────────── PAYMENTS (non-cash proof, ADR-0025) ────────────
  static const _payMethodLabel = {
    'kartu': 'Kartu',
    'qris': 'QRIS',
    'transfer': 'Transfer',
    'lainnya': 'Lainnya',
  };

  String _payTime(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _paymentsSection(BuildContext context, PaymentsSectionDto p) {
    final sc = context.sat;
    if (p.rows.isEmpty) {
      return _card(context, 'Pembayaran non-tunai',
          sub: 'bukti foto wajib',
          child: Text('Tidak ada pembayaran non-tunai pada rentang ini.',
              style: SatType.sans(size: 13, color: sc.textLo)));
    }
    return _card(
      context,
      'Pembayaran non-tunai',
      sub: 'total ${formatIDR(p.nonCashTotal)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in p.methodTotals)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sc.bg1,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: sc.border0),
                  ),
                  child: Text(
                      '${_payMethodLabel[m.method] ?? m.method} · '
                      '${m.count}× · ${formatIDR(m.amount)}',
                      style: SatType.sans(size: 11.5, color: sc.textHi)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final r in p.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  if (r.hasPhoto)
                    PaymentProofThumb(
                        paymentId: r.paymentId, history: true, size: 44)
                  else
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sc.bg1,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.image_not_supported_rounded,
                          size: 18, color: sc.textLo),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${_payMethodLabel[r.method] ?? r.method} · '
                            'Meja ${r.tableLabel ?? '-'}',
                            style: SatType.sans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: sc.textHi)),
                        const SizedBox(height: 2),
                        Text('${_payTime(r.at)} · ${r.cashierName ?? '-'}',
                            style: SatType.sans(size: 11, color: sc.textLo)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatIDR(r.amount),
                      style: SatType.mono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: sc.textHi)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────── SALES ────────────
  Widget _salesSection(BuildContext context, bool isTab, SalesSectionDto sales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _salesKpis(context, sales.kpis),
        if (sales.takeaway != null &&
            (sales.takeaway!.count > 0 || sales.takeaway!.dineInCount > 0)) ...[
          const SizedBox(height: 14),
          _takeawaySplit(context, sales.takeaway!),
        ],
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _coverTrend(context, sales.coverTrend)),
              const SizedBox(width: 14),
              Expanded(child: _hourlyRevenue(context, sales.hourly)),
            ],
          )
        else ...[
          _coverTrend(context, sales.coverTrend),
          const SizedBox(height: 14),
          _hourlyRevenue(context, sales.hourly),
        ],
      ],
    );
  }

  Widget _takeawaySplit(BuildContext context, TakeawaySplitDto t) {
    return _card(
      context,
      'Dine-in vs Bawa pulang',
      child: Row(
        children: [
          Expanded(
            child: SetTile(
              label: 'Dine-in',
              value: formatIDR(t.dineInNet),
              sub: '${t.dineInCount} transaksi',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SetTile(
              label: 'Bawa pulang',
              value: formatIDR(t.net),
              sub: '${t.count} transaksi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _salesKpis(BuildContext context, List<KpiTileDto> kpis) {
    final tiles = kpis.isEmpty
        ? const [
            KpiTileDto(label: 'Net', value: '—', sub: 'belum ada data'),
            KpiTileDto(label: 'Gross', value: '—', sub: '—'),
            KpiTileDto(label: 'Pajak + Service', value: '—', sub: '—'),
            KpiTileDto(label: 'Void', value: '—', sub: '—'),
          ]
        : kpis;
    return LayoutBuilder(builder: (c, cons) {
      final narrow = cons.maxWidth < 520;
      if (narrow) {
        return Column(
          children: [
            Row(children: [
              for (var i = 0; i < 2 && i < tiles.length; i++) ...[
                Expanded(
                    child: SetTile(
                        label: tiles[i].label,
                        value: tiles[i].value,
                        sub: tiles[i].sub)),
                if (i == 0) const SizedBox(width: 12),
              ],
            ]),
            if (tiles.length > 2) ...[
              const SizedBox(height: 12),
              Row(children: [
                for (var i = 2; i < 4 && i < tiles.length; i++) ...[
                  Expanded(
                      child: SetTile(
                          label: tiles[i].label,
                          value: tiles[i].value,
                          sub: tiles[i].sub)),
                  if (i == 2) const SizedBox(width: 12),
                ],
              ]),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            Expanded(
                child: SetTile(
                    label: tiles[i].label,
                    value: tiles[i].value,
                    sub: tiles[i].sub)),
            if (i != tiles.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    });
  }

  Widget _coverTrend(BuildContext context, List<CoverDayDto> pairs) {
    final sc = context.sat;
    if (pairs.isEmpty) {
      return _card(context, 'Tren tamu vs minggu lalu',
          sub: 'Belum ada data', child: const SizedBox(height: 40));
    }
    final maxVal = pairs
        .expand((p) => [p.thisWeek, p.lastWeek])
        .fold<int>(1, (a, b) => b > a ? b : a);
    final thisWk = pairs.fold<int>(0, (s, p) => s + p.thisWeek);
    final lastWk = pairs.fold<int>(0, (s, p) => s + p.lastWeek);
    final delta = lastWk == 0 ? 0 : ((thisWk - lastWk) / lastWk * 100).round();
    return _card(
      context,
      'Tren tamu vs minggu lalu',
      sub: '$thisWk tamu · ${delta >= 0 ? '+' : ''}$delta% WoW',
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
                              radius: const BorderRadius.vertical(
                                  top: Radius.circular(2)),
                            ),
                            const SizedBox(width: 3),
                            GrowBarV(
                              width: 9,
                              height: 100 * pairs[i].thisWeek / maxVal,
                              color: sc.accent,
                              radius: const BorderRadius.vertical(
                                  top: Radius.circular(2)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(pairs[i].day,
                            style: SatType.mono(
                                size: 9, color: sc.textLo, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  if (i != pairs.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: sc.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('Minggu ini', style: SatType.sans(size: 11, color: sc.textMd)),
              const SizedBox(width: 14),
              Container(width: 9, height: 9, decoration: BoxDecoration(color: sc.bg4, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('Minggu lalu', style: SatType.sans(size: 11, color: sc.textMd)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hourlyRevenue(BuildContext context, List<double> bars) {
    final sc = context.sat;
    final hours = ['11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22'];
    final safe = bars.length == 12 ? bars : List.filled(12, 0.0);
    final peakIdx = safe.indexed.fold<int>(0, (best, e) => e.$2 > safe[best] ? e.$1 : best);
    return _card(
      context,
      'Pendapatan per jam',
      sub: 'Puncak ${hours[peakIdx]}:00 — ${(int.parse(hours[peakIdx]) + 1).toString().padLeft(2, '0')}:00',
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
                      radius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    const SizedBox(height: 6),
                    Text(hours[i],
                        style: SatType.mono(size: 9, color: sc.textLo, letterSpacing: 0.4)),
                  ],
                ),
              ),
              if (i != safe.length - 1) const SizedBox(width: 4),
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
          'Performa pelayan',
          sub: '${rows.length} staf · sortir aktif',
          trailing: _sortMenu(context),
          child: rows.isEmpty
              ? _emptyChunk(context, 'Belum ada sesi tutup di rentang ini.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _staffHead(context),
                    const SizedBox(height: 6),
                    Divider(color: sc.border0, height: 1),
                    for (var i = 0; i < rows.length; i++) ...[
                      _staffRow(context, rows[i], i),
                      if (i != rows.length - 1)
                        Divider(color: sc.border0, height: 1),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _upsellIndex(context, staff.upsell),
      ],
    );
  }

  Widget _sortMenu(BuildContext context) {
    final sc = context.sat;
    final label = {
      _StaffSort.net: 'Net',
      _StaffSort.covers: 'Meja',
      _StaffSort.voidPct: 'Void %',
      _StaffSort.avgTicket: 'Avg',
    }[_staffSort]!;
    return PopupMenuButton<_StaffSort>(
      tooltip: 'Sortir',
      color: sc.bg1,
      onSelected: (v) => setState(() => _staffSort = v),
      itemBuilder: (c) => [
        for (final s in _StaffSort.values)
          PopupMenuItem(
              value: s,
              child: Text({
                _StaffSort.net: 'Net tertinggi',
                _StaffSort.covers: 'Paling banyak meja',
                _StaffSort.voidPct: 'Void terbanyak',
                _StaffSort.avgTicket: 'Avg ticket',
              }[s]!, style: SatType.sans(size: 13, color: sc.textHi))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sc.bg3,
          border: Border.all(color: sc.border1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 14, color: sc.textMd),
            const SizedBox(width: 6),
            Text(label,
                style: SatType.sans(
                    size: 11, weight: FontWeight.w500, color: sc.textHi)),
          ],
        ),
      ),
    );
  }

  Widget _staffHead(BuildContext context) {
    final sc = context.sat;
    TextStyle s() => SatType.mono(
        size: 10, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PELAYAN', style: s())),
          Expanded(flex: 2, child: Text('MEJA', textAlign: TextAlign.right, style: s())),
          Expanded(flex: 2, child: Text('ITEM', textAlign: TextAlign.right, style: s())),
          Expanded(flex: 3, child: Text('AVG TICKET', textAlign: TextAlign.right, style: s())),
          Expanded(flex: 2, child: Text('VOID%', textAlign: TextAlign.right, style: s())),
          Expanded(flex: 3, child: Text('NET', textAlign: TextAlign.right, style: s())),
        ],
      ),
    );
  }

  Widget _staffRow(BuildContext context, StaffRowDto r, int idx) {
    final sc = context.sat;
    final netStr = r.net == 0 ? '—' : 'Rp ${(r.net / 1000000).toStringAsFixed(1)}jt';
    final voidStr = r.voidPct == 0 ? '—' : '${r.voidPct.toStringAsFixed(1)}%';
    final voidColor = r.voidPct > 2.0 ? sc.warn : (r.voidPct > 1.0 ? sc.textMd : sc.textLo);
    final avgStr = r.avgTicket == 0 ? '—' : 'Rp ${(r.avgTicket / 1000).round()}rb';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                  decoration: BoxDecoration(
                    color: idx == 0 ? sc.accentSoft : sc.bg3,
                    border: Border.all(
                        color: idx == 0 ? sc.accentBorder : sc.border0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${idx + 1}',
                      style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          color: idx == 0 ? sc.accent : sc.textMd)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.sans(
                          size: 13, weight: FontWeight.w500, color: sc.textHi)),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('${r.covers}', textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textHi))),
          Expanded(flex: 2, child: Text('${r.items}', textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textHi))),
          Expanded(flex: 3, child: Text(avgStr, textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textMd))),
          Expanded(flex: 2, child: Text(voidStr, textAlign: TextAlign.right, style: SatType.mono(size: 12, color: voidColor))),
          Expanded(flex: 3, child: Text(netStr, textAlign: TextAlign.right, style: SatType.mono(size: 13, weight: FontWeight.w600, color: sc.textHi))),
        ],
      ),
    );
  }

  Widget _upsellIndex(BuildContext context, List<StaffUpsellDto> rows) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(context, 'Indeks upsell pelayan',
          sub: 'Belum ada data', child: const SizedBox(height: 30));
    }
    final positive = rows.where((r) => r.rate > 0).toList();
    final avg = positive.isEmpty
        ? 0.0
        : positive.fold<double>(0, (a, r) => a + r.rate) / positive.length;
    return _card(
      context,
      'Indeks upsell pelayan',
      sub: '% sesi dgn starter & main · avg ${(avg * 100).round()}%',
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(r.name, style: SatType.sans(size: 13, color: sc.textHi))),
                      Text(r.rate == 0 ? '—' : '${(r.rate * 100).round()}%',
                          style: SatType.mono(
                              size: 12,
                              weight: FontWeight.w600,
                              color: r.rate >= avg ? sc.success : sc.textMd)),
                    ],
                  ),
                  const SizedBox(height: 6),
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
              Expanded(child: _menuList(context, 'Top sellers', menu.top, top: true)),
              const SizedBox(width: 14),
              Expanded(child: _menuList(context, 'Slow movers', menu.slow, top: false)),
            ],
          )
        else ...[
          _menuList(context, 'Top sellers', menu.top, top: true),
          const SizedBox(height: 14),
          _menuList(context, 'Slow movers', menu.slow, top: false),
        ],
        const SizedBox(height: 14),
        _modifierAttach(context, menu.modifierAttach),
        const SizedBox(height: 14),
        _menuMatrix(context, menu.matrix),
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _categoryMix(context, menu.categoryMix)),
              const SizedBox(width: 14),
              Expanded(child: _basketPairs(context, menu.basketPairs)),
            ],
          )
        else ...[
          _categoryMix(context, menu.categoryMix),
          const SizedBox(height: 14),
          _basketPairs(context, menu.basketPairs),
        ],
      ],
    );
  }

  Widget _menuList(BuildContext context, String title, List<MenuItemRowDto> rows,
      {required bool top}) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(context, title,
          sub: 'Belum ada data', child: const SizedBox(height: 40));
    }
    return _card(
      context,
      title,
      sub: top
          ? '${rows.length} item · margin tinggi'
          : '${rows.length} item · stok mengendap',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].name,
                            style: SatType.sans(
                                size: 13,
                                weight: FontWeight.w500,
                                color: sc.textHi)),
                        const SizedBox(height: 2),
                        Text('×${rows[i].qty} · margin ${rows[i].marginPct}%',
                            style: SatType.mono(
                                size: 10, color: sc.textLo, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(_compactRp(rows[i].revenue),
                      style: SatType.mono(
                          size: 12, color: sc.textMd, letterSpacing: 0.4)),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: sc.bg3, borderRadius: BorderRadius.circular(2)),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: rows[i].fill.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: top ? sc.success : sc.warn,
                          borderRadius: BorderRadius.circular(2),
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
      return _card(context, 'Attach rate modifier',
          sub: '% order pakai modifier', child: const SizedBox(height: 30));
    }
    return _card(
      context,
      'Attach rate modifier',
      sub: '% order pakai modifier',
      child: Column(
        children: [
          for (final m in mods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(m.group, style: SatType.sans(size: 13, color: sc.textHi))),
                      Text('${(m.rate * 100).round()}%',
                          style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textHi)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBarFill(
                      factor: m.rate, color: sc.info, track: sc.bg3),
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
      _BucketSpec('star', 'LAKU & UNTUNG', 'jaga & sorot', sc.success),
      _BucketSpec('plow', 'LAKU TAPI TIPIS', 'reprice / kurangi porsi', sc.warn),
      _BucketSpec('puzzle', 'UNTUNG TAPI SEPI', 'promosikan', sc.info),
      _BucketSpec('dog', 'SEPI & TIPIS', 'kandidat dipangkas', sc.textLo),
    ];
    return _card(
      context,
      'Klasifikasi menu',
      sub: 'Populer × margin',
      child: items.isEmpty
          ? _emptyChunk(context, 'Belum ada data.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
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
      BuildContext context, _BucketSpec spec, List<MatrixItemDto> rows) {
    final sc = context.sat;
    const cap = 5;
    final shown = rows.take(cap).toList();
    final extra = rows.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(spec.label,
                style: SatType.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: spec.color)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('· ${spec.action}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.sans(size: 11, color: sc.textLo)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('tidak ada item',
                style: SatType.sans(size: 12, color: sc.textLo)),
          )
        else ...[
          for (final it in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration:
                        BoxDecoration(color: spec.color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.sans(
                            size: 13,
                            weight: FontWeight.w500,
                            color: sc.textHi)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                      'pop ${(it.popularity * 100).round()} · margin ${(it.margin * 100).round()}%',
                      style: SatType.mono(
                          size: 10, color: sc.textMd, letterSpacing: 0.4)),
                ],
              ),
            ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 14),
              child: Text('+$extra lainnya',
                  style: SatType.mono(
                      size: 10, color: sc.textLo, letterSpacing: 0.4)),
            ),
        ],
      ],
    );
  }

  Widget _categoryMix(BuildContext context, List<CategoryShareDto> cats) {
    final sc = context.sat;
    if (cats.isEmpty) {
      return _card(context, 'Bauran kategori (WoW)',
          sub: 'Belum ada data', child: const SizedBox(height: 30));
    }
    final palette = [sc.accent, sc.info, sc.success, sc.violet, sc.warn];
    return _card(
      context,
      'Bauran kategori (WoW)',
      sub: 'Bagian pendapatan vs minggu lalu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MINGGU INI', style: SatType.mono(size: 9, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [
              for (var i = 0; i < cats.length; i++)
                Expanded(
                    flex: (cats[i].shareThisWeek * 1000).round().clamp(1, 10000),
                    child: Container(height: 12, color: palette[i % palette.length])),
            ]),
          ),
          const SizedBox(height: 10),
          Text('MINGGU LALU', style: SatType.mono(size: 9, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [
              for (var i = 0; i < cats.length; i++)
                Expanded(
                    flex: (cats[i].shareLastWeek * 1000).round().clamp(1, 10000),
                    child: Container(
                        height: 8,
                        color: palette[i % palette.length].withValues(alpha: 0.45))),
            ]),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < cats.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cats[i].name, style: SatType.sans(size: 13, color: sc.textHi))),
                  Text('${(cats[i].shareThisWeek * 100).round()}%',
                      style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textHi)),
                  const SizedBox(width: 8),
                  _deltaPill(context,
                      cats[i].shareThisWeek - cats[i].shareLastWeek),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(txt,
          style: SatType.mono(
              size: 10, weight: FontWeight.w600, color: color, letterSpacing: 0.4)),
    );
  }

  Widget _basketPairs(BuildContext context, List<BasketPairDto> pairs) {
    final sc = context.sat;
    if (pairs.isEmpty) {
      return _card(context, 'Pasangan keranjang',
          sub: 'Item paling sering dipesan bersama',
          child: const SizedBox(height: 30));
    }
    return _card(
      context,
      'Pasangan keranjang',
      sub: 'Item paling sering dipesan bersama',
      child: Column(
        children: [
          for (var i = 0; i < pairs.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(pairs[i].itemA,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.sans(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: sc.textHi)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.add, size: 12, color: sc.textLo),
                          ),
                          Flexible(
                            child: Text(pairs[i].itemB,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.sans(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: sc.textHi)),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text('${pairs[i].count}× di rentang ini',
                            style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${(pairs[i].rate * 100).round()}%',
                      style: SatType.mono(
                          size: 12,
                          weight: FontWeight.w600,
                          color: sc.info,
                          letterSpacing: 0.4)),
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
        const SizedBox(height: 14),
        _speedOfService(context, ops.speed),
        const SizedBox(height: 14),
        _heatmap(context, ops.heatmap),
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _reservationConv(context, ops.reservations)),
              const SizedBox(width: 14),
              Expanded(child: _voidReasons(context, ops.voidReasons)),
            ],
          )
        else ...[
          _reservationConv(context, ops.reservations),
          const SizedBox(height: 14),
          _voidReasons(context, ops.voidReasons),
        ],
        const SizedBox(height: 14),
        _voidByStaff(context, ops.voidByStaff),
      ],
    );
  }

  Widget _opsKpis(BuildContext context, List<KpiTileDto> kpis) {
    final tiles = kpis.isEmpty
        ? const [
            KpiTileDto(label: 'Avg turn time', value: '—', sub: 'belum ada data'),
            KpiTileDto(label: 'Prep dapur', value: '—', sub: '—'),
            KpiTileDto(label: 'Tunggu antar', value: '—', sub: '—'),
            KpiTileDto(label: 'Reservasi', value: '—', sub: '—'),
          ]
        : kpis;
    return LayoutBuilder(builder: (c, cons) {
      final narrow = cons.maxWidth < 520;
      if (narrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: SetTile(label: tiles[0].label, value: tiles[0].value, sub: tiles[0].sub)),
              const SizedBox(width: 12),
              if (tiles.length > 1)
                Expanded(child: SetTile(label: tiles[1].label, value: tiles[1].value, sub: tiles[1].sub)),
            ]),
            if (tiles.length > 2) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SetTile(label: tiles[2].label, value: tiles[2].value, sub: tiles[2].sub)),
                const SizedBox(width: 12),
                if (tiles.length > 3)
                  Expanded(child: SetTile(label: tiles[3].label, value: tiles[3].value, sub: tiles[3].sub)),
              ]),
            ],
          ],
        );
      }
      return Row(children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: SetTile(label: tiles[i].label, value: tiles[i].value, sub: tiles[i].sub)),
          if (i != tiles.length - 1) const SizedBox(width: 12),
        ],
      ]);
    });
  }

  Widget _speedOfService(BuildContext context, SpeedSectionDto s) {
    final sc = context.sat;
    if (s.sampleSize == 0) {
      return _card(context, 'Kecepatan layanan',
          sub: 'Belum ada item siap/disajikan',
          child: const SizedBox(height: 30));
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
      'Kecepatan layanan',
      sub: 'Median prep ${s.prepMedianMin}m · antar ${s.pickupMedianMin}m · '
          '${s.sampleSize} item',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SLA hit-rate against the configurable target.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${s.slaPct.round()}%',
                  style: SatType.mono(
                      size: 26, weight: FontWeight.w700, color: slaColor)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'siap di bawah target ${s.prepTargetMins} menit',
                    style: SatType.sans(size: 12, color: sc.textMd)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBarFill(
              factor: s.slaPct / 100,
              color: slaColor,
              track: sc.bg3,
              height: 6),
          if (s.slowItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Menu paling lambat (rata-rata prep)',
                style: SatType.sans(
                    size: 11,
                    weight: FontWeight.w600,
                    color: sc.textLo,
                    letterSpacing: 0.4)),
            const SizedBox(height: 8),
            for (final it in s.slowItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(it.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.sans(
                                    size: 13, color: sc.textHi))),
                        Text('${it.avgPrepMin.toStringAsFixed(1)}m',
                            style: SatType.mono(
                                size: 12,
                                weight: FontWeight.w600,
                                color: it.avgPrepMin > s.prepTargetMins
                                    ? sc.urgent
                                    : sc.textHi,
                                letterSpacing: 0.4)),
                        const SizedBox(width: 8),
                        Text('×${it.count}',
                            style: SatType.mono(
                                size: 11, color: sc.textLo, letterSpacing: 0.4)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    AnimatedBarFill(
                      factor: it.avgPrepMin / maxAvg,
                      color:
                          it.avgPrepMin > s.prepTargetMins ? sc.urgent : sc.info,
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
      return _card(context, 'Peak-hour heatmap',
          sub: '7 hari · jam 11—22', child: const SizedBox(height: 30));
    }
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const hours = ['11', '', '13', '', '15', '', '17', '', '19', '', '21', ''];
    return _card(
      context,
      'Peak-hour heatmap',
      sub: '7 hari · jam 11—22',
      child: LayoutBuilder(builder: (c, cons) {
        final cellW = (cons.maxWidth - 32) / 12;
        final cell = cellW.clamp(14.0, 28.0);
        return Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 32),
                for (var i = 0; i < hours.length; i++)
                  SizedBox(
                    width: cell,
                    child: Text(hours[i],
                        textAlign: TextAlign.center,
                        style: SatType.mono(size: 9, color: sc.textLo, letterSpacing: 0.4)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var r = 0; r < grid.length && r < days.length; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(days[r],
                          style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6)),
                    ),
                    for (var col = 0; col < grid[r].length && col < 12; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: cell - 2,
                          height: cell - 2,
                          decoration: BoxDecoration(
                            color: Color.lerp(sc.bg3, sc.accent, grid[r][col].clamp(0.0, 1.0)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('SEPI', style: SatType.mono(size: 9, color: sc.textLo, letterSpacing: 1.0)),
                const SizedBox(width: 6),
                for (var i = 0; i < 5; i++) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color.lerp(sc.bg3, sc.accent, i / 4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                const SizedBox(width: 4),
                Text('PADAT', style: SatType.mono(size: 9, color: sc.textLo, letterSpacing: 1.0)),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _reservationConv(BuildContext context, ReservationStatsDto r) {
    final sc = context.sat;
    final booked = r.booked;
    if (booked == 0) {
      return _card(
        context,
        'Konversi reservasi',
        sub: 'Belum ada modul reservasi',
        child: _emptyChunk(context, 'Aktifkan modul reservasi (P3) untuk melihat konversi.'),
      );
    }
    final seatedPct = r.seated / booked;
    final noShowPct = r.noShow / booked;
    final cancelPct = r.cancelled / booked;
    return _card(
      context,
      'Konversi reservasi',
      sub: '$booked dipesan · ${r.seated} duduk · ${r.noShow} no-show',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(children: [
              Expanded(flex: (seatedPct * 1000).round().clamp(1, 10000), child: Container(height: 14, color: sc.success)),
              Expanded(flex: (noShowPct * 1000).round().clamp(1, 10000), child: Container(height: 14, color: sc.warn)),
              Expanded(flex: (cancelPct * 1000).round().clamp(1, 10000), child: Container(height: 14, color: sc.textLo)),
            ]),
          ),
          const SizedBox(height: 14),
          _resvRow(context, sc.success, 'Duduk', r.seated, seatedPct),
          _resvRow(context, sc.warn, 'No-show', r.noShow, noShowPct),
          _resvRow(context, sc.textLo, 'Batal', r.cancelled, cancelPct),
        ],
      ),
    );
  }

  Widget _resvRow(BuildContext context, Color color, String label, int n, double pct) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: SatType.sans(size: 13, color: sc.textHi))),
        Text('$n', style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.4)),
        const SizedBox(width: 10),
        Text('${(pct * 100).round()}%',
            style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textHi, letterSpacing: 0.4)),
      ]),
    );
  }

  Widget _voidReasons(BuildContext context, List<VoidReasonDto> rows) {
    final sc = context.sat;
    if (rows.isEmpty) {
      return _card(context, 'Alasan void & comp',
          sub: 'Belum ada void', child: const SizedBox(height: 30));
    }
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    final totalRp = rows.fold<int>(0, (s, r) => s + r.lostRupiah);
    final maxN = rows.map((r) => r.count).fold<int>(1, (a, b) => b > a ? b : a);
    final palette = [sc.warn, sc.info, sc.violet, sc.textLo, sc.urgent, sc.success];
    return _card(
      context,
      'Alasan void & comp',
      sub: '$total kejadian · ${_compactRp(totalRp)} hilang',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(rows[i].label, style: SatType.sans(size: 13, color: sc.textHi))),
                      Text('${rows[i].count}×',
                          style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textHi, letterSpacing: 0.4)),
                      const SizedBox(width: 10),
                      Text(_compactRp(rows[i].lostRupiah),
                          style: SatType.mono(size: 11, color: sc.textMd, letterSpacing: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 6),
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
      return _card(context, 'Void per pelayan',
          sub: 'Belum ada void', child: const SizedBox(height: 30));
    }
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    final totalRp = rows.fold<int>(0, (s, r) => s + r.lostRupiah);
    final maxN = rows.map((r) => r.count).fold<int>(1, (a, b) => b > a ? b : a);
    return _card(
      context,
      'Void per pelayan',
      sub: '$total kejadian · ${_compactRp(totalRp)} hilang',
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(r.name,
                              style: SatType.sans(size: 13, color: sc.textHi))),
                      Text('${r.count}×',
                          style: SatType.mono(
                              size: 12,
                              weight: FontWeight.w600,
                              color: sc.textHi,
                              letterSpacing: 0.4)),
                      const SizedBox(width: 10),
                      Text(_compactRp(r.lostRupiah),
                          style: SatType.mono(
                              size: 11, color: sc.textMd, letterSpacing: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedBarFill(
                            factor: r.count / maxN,
                            color: sc.warn,
                            track: sc.bg3),
                      ),
                      const SizedBox(width: 10),
                      Text('alasan: ${r.topReasonLabel}',
                          style: SatType.sans(size: 10, color: sc.textLo)),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, color: sc.textLo, size: 28),
          const SizedBox(height: 10),
          Text('Tidak ada bagian aktif',
              style: SatType.sans(size: 14, weight: FontWeight.w600, color: sc.textHi)),
          const SizedBox(height: 4),
          Text('Aktifkan minimal satu tab di atas',
              style: SatType.sans(size: 12, color: sc.textMd)),
        ],
      ),
    );
  }

  Widget _emptyChunk(BuildContext context, String text) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: SatType.sans(size: 12, color: sc.textMd)),
    );
  }

  String _compactRp(int v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).round()}rb';
    return 'Rp $v';
  }
}
