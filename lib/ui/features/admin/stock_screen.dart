import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/admin/_common.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

enum _StockFilter { all, low, negative, produced }

/// "Stok" — Heritage Hospitality Pantry & Stock Ledger Management.
///
/// Handles ingredient lists, receiving inventory, batch production, opname audits,
/// and append-only stock movement history (ADR-0040, ADR-0041).
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _counts = <String, int>{};
  final _searchCtrl = TextEditingController();

  /// Ingredient ids whose recipe chips the user unclipped past the 2-line cap.
  final _expandedLinks = <String>{};

  bool _opname = false;
  _StockFilter _activeFilter = _StockFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final async = ref.watch(ingredientsProvider);

    return Column(
      children: [
        AdminEmbeddedStrip(
          title: 'Stok',
          sub: _opname
              ? 'Stok opname physical audit'
              : 'Bahan, penerimaan & mutasi',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_opname) ...[
                PressScale(
                  child: IconButton(
                    tooltip: 'Tambah bahan',
                    icon: Container(
                      padding: const EdgeInsets.all(Sp.s1h),
                      decoration: SatBox.d(
                        color: sc.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, size: 18, color: sc.accentText),
                    ),
                    onPressed: () => _editIngredient(null),
                  ),
                ),
                const SizedBox(width: Sp.s2),
              ],
              PressScale(
                child: _opname
                    ? SatButton.danger(
                        label: AppStrings.cancel,
                        icon: Icons.close,
                        onTap: () => setState(() {
                          _opname = false;
                          _counts.clear();
                        }),
                      )
                    : SatButton.outline(
                        label: 'Opname',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => setState(() {
                          _opname = true;
                          _counts.clear();
                        }),
                      ),
              ),
              if (_opname) ...[
                const SizedBox(width: Sp.s2),
                PressScale(
                  child: SatButton.primary(
                    label: 'Simpan (${_counts.length})',
                    icon: Icons.check_circle_outline,
                    onTap: _counts.isEmpty ? null : _submitOpname,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              'Gagal memuat stok: $e',
              color: sc.urgent,
              icon: Icons.error_outline,
            ),
            data: (list) {
              if (list.isEmpty) {
                return _EmptyState(
                  title: 'Belum Ada Bahan',
                  message:
                      'Tambahkan bahan pertama Anda, lalu susun resepnya di editor menu '
                      'agar stok berkurang otomatis saat pesanan dikirim.',
                  onAction: () => _editIngredient(null),
                );
              }

              // Apply Search & Filter
              final q = _searchQuery.toLowerCase();
              final filtered = list.where((i) {
                // Recipe names match too, so "nasi goreng" lists everything
                // that dish consumes.
                final matchesSearch =
                    q.isEmpty ||
                    i.name.toLowerCase().contains(q) ||
                    i.usedBy.any((n) => n.toLowerCase().contains(q)) ||
                    i.madeFrom.any((n) => n.toLowerCase().contains(q));
                final matchesFilter = switch (_activeFilter) {
                  _StockFilter.all => true,
                  _StockFilter.low => i.isLow || i.stockOnHand < 0,
                  _StockFilter.negative => i.stockOnHand < 0,
                  _StockFilter.produced => i.isProduced,
                };
                return matchesSearch && matchesFilter;
              }).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ingredientsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Smooth Animated CrossFade between KPI Summary and Opname Banner
                    AnimatedCrossFade(
                      firstChild: _summaryGrid(sc, list),
                      secondChild: _opnameBanner(sc),
                      crossFadeState: _opname
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: satMotion(context, 240),
                      firstCurve: satEaseOut,
                      secondCurve: satEaseOut,
                    ),
                    const SizedBox(height: Sp.s4),
                    _searchAndFilterBar(sc, list),
                    const SizedBox(height: Sp.s4),
                    if (filtered.isEmpty)
                      _Message(
                        'Tidak ada bahan yang cocok dengan pencarian / filter.',
                        icon: Icons.search_off,
                      )
                    else
                      for (int idx = 0; idx < filtered.length; idx++)
                        Reveal(index: idx, child: _row(sc, filtered[idx])),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- KPI Summary
  Widget _summaryGrid(SatColors sc, List<Ingredient> list) {
    final low = list.where((i) => i.isLow).length;
    final negative = list.where((i) => i.stockOnHand < 0).length;
    final produced = list.where((i) => i.isProduced).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;
        final cards = [
          _statCard(
            sc,
            index: 0,
            label: 'MENIPIS',
            value: '$low Bahan',
            sub: low > 0 ? 'Perlu reorder' : 'Stok aman',
            icon: Icons.warning_amber_rounded,
            color: low > 0 ? sc.warn : sc.textLo,
            bg: low > 0 ? sc.warnSoft : sc.bg2,
            borderColor: low > 0 ? sc.warn : null,
            active: _activeFilter == _StockFilter.low,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _StockFilter.low
                  ? _StockFilter.all
                  : _StockFilter.low;
            }),
          ),
          if (negative > 0)
            _statCard(
              sc,
              index: 1,
              label: 'STOK MINUS',
              value: '$negative Bahan',
              sub: 'Perlu opname segera',
              icon: Icons.remove_circle_outline,
              color: sc.urgent,
              bg: sc.urgentSoft,
              borderColor: sc.urgent,
              active: _activeFilter == _StockFilter.negative,
              onTap: () => setState(() {
                _activeFilter = _activeFilter == _StockFilter.negative
                    ? _StockFilter.all
                    : _StockFilter.negative;
              }),
            ),
          _statCard(
            sc,
            index: 2,
            label: 'PRODUKSI MANDIRI',
            value: '$produced Bahan',
            sub: 'dari ${list.length} bahan terdaftar',
            icon: Icons.blender_outlined,
            color: sc.info,
            bg: sc.bg2,
            active: _activeFilter == _StockFilter.produced,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _StockFilter.produced
                  ? _StockFilter.all
                  : _StockFilter.produced;
            }),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: Sp.s2h),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: card),
          ],
        );
      },
    );
  }

  Widget _statCard(
    SatColors sc, {
    required int index,
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bg,
    Color? borderColor,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Reveal(
      index: index,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: SatR.a(14),
          child: AnimatedContainer(
            duration: satMotion(context, 180),
            curve: satEaseOut,
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3h,
              vertical: Sp.s3,
            ),
            decoration: SatBox.d(
              color: active ? sc.bg3 : bg,
              borderRadius: SatR.a(14),
              border: SatB.all(
                color: active ? color : (borderColor ?? sc.border1),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.caption(color: sc.textLo),
                      ),
                    ),
                    Icon(icon, size: 16, color: color),
                  ],
                ),
                const SizedBox(height: Sp.s1h),
                Text(value, style: SatType.labelL(color: color)),
                const SizedBox(height: Sp.sHair),
                Text(sub, style: SatType.bodyS(color: sc.textLo)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Opname Banner
  Widget _opnameBanner(SatColors sc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: Sp.s3),
      decoration: SatBox.d(
        color: sc.accentSoft,
        borderRadius: SatR.a(14),
        border: SatB.all(color: sc.accentBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.s2),
            decoration: SatBox.d(
              color: sc.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: sc.accentText,
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODE STOK OPNAME',
                  style: SatType.caption(color: sc.accentText),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  'Ketik jumlah fisik di gudang saat ini. Selisih akan otomatis dihitung sebagai penyesuaian mutasi.',
                  style: SatType.bodyS(color: sc.textMd),
                ),
              ],
            ),
          ),
          if (_counts.isNotEmpty) ...[
            const SizedBox(width: Sp.s2),
            AnimatedSwitcher(
              duration: satMotion(context, 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(_counts.length),
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s2h,
                  vertical: Sp.s1,
                ),
                decoration: SatBox.d(
                  color: sc.accent,
                  borderRadius: SatR.a(999),
                ),
                child: Text(
                  '${_counts.length} diisi',
                  style: SatType.caption(color: sc.accentInk),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Search & Filter
  Widget _searchAndFilterBar(SatColors sc, List<Ingredient> list) {
    final lowCount = list.where((i) => i.isLow || i.stockOnHand < 0).length;
    final negCount = list.where((i) => i.stockOnHand < 0).length;
    final prodCount = list.where((i) => i.isProduced).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SatField.search(
                controller: _searchCtrl,
                hint: 'Cari nama bahan...',
                suffix: _searchQuery.isEmpty
                    ? null
                    : SatIconButton.plain(
                        icon: Icons.clear,
                        tooltip: AppStrings.a11yClear,
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.s2h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(sc, _StockFilter.all, 'Semua (${list.length})'),
              const SizedBox(width: Sp.s1h),
              _filterChip(
                sc,
                _StockFilter.low,
                'Menipis ($lowCount)',
                highlightColor: lowCount > 0 ? sc.warn : null,
              ),
              if (negCount > 0) ...[
                const SizedBox(width: Sp.s1h),
                _filterChip(
                  sc,
                  _StockFilter.negative,
                  'Minus ($negCount)',
                  highlightColor: sc.urgent,
                ),
              ],
              const SizedBox(width: Sp.s1h),
              _filterChip(
                sc,
                _StockFilter.produced,
                'Produksi ($prodCount)',
                highlightColor: sc.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    SatColors sc,
    _StockFilter filter,
    String label, {
    Color? highlightColor,
  }) {
    final active = _activeFilter == filter;
    final color = active ? (highlightColor ?? sc.accentText) : sc.textMd;

    return PressScale(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filter),
        borderRadius: SatR.a(999),
        child: AnimatedContainer(
          duration: satMotion(context, 150),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3,
            vertical: Sp.s1h,
          ),
          decoration: SatBox.d(
            color: active
                ? (highlightColor?.withValues(alpha: 0.15) ?? sc.accentSoft)
                : sc.bg2,
            border: SatB.all(color: active ? color : sc.border1),
            borderRadius: SatR.a(999),
          ),
          child: Text(
            label,
            style: (active
                ? SatType.labelS(color: color)
                : SatType.bodyS(color: color)),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Ingredient Row Card
  Widget _row(SatColors sc, Ingredient i) {
    final negative = i.stockOnHand < 0;
    final statusColor = negative
        ? sc.urgent
        : i.isLow
        ? sc.warn
        : sc.success;

    // Physical count entered in opname mode
    final physicalCount = _counts[i.id];

    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(14),
        border: SatB.all(color: physicalCount != null ? sc.accent : sc.border1),
      ),
      child: ClipRRect(
        borderRadius: SatR.a(14),
        // Stack, not IntrinsicHeight: the strip only needs to stretch to the
        // row's height, and an intrinsic pass would ask the chip LayoutBuilder
        // below for a width it cannot answer.
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              // Health status accent strip on left
              child: AnimatedContainer(
                duration: satMotion(context, 200),
                width: 4,
                color: statusColor,
              ),
            ),
            Row(
              children: [
                const SizedBox(width: Sp.s1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header line: Name + Badges
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                i.name,
                                style: SatType.labelL(color: sc.textHi),
                              ),
                            ),
                            if (i.isProduced) ...[
                              const SizedBox(width: Sp.s1h),
                              _badge(
                                sc,
                                label: 'PRODUKSI',
                                color: sc.info,
                                icon: Icons.blender_outlined,
                              ),
                            ],
                            if (i.isLow && !negative) ...[
                              const SizedBox(width: Sp.s1h),
                              _badge(
                                sc,
                                label: 'MENIPIS',
                                color: sc.warn,
                                icon: Icons.warning_amber_rounded,
                              ),
                            ],
                            if (negative) ...[
                              const SizedBox(width: Sp.s1h),
                              _badge(
                                sc,
                                label: 'MINUS',
                                color: sc.urgent,
                                icon: Icons.remove_circle_outline,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: Sp.s2),

                        // Metrics Grid
                        Row(
                          children: [
                            // Stock On Hand
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STOK SAAT INI',
                                    style: SatType.monoS(color: sc.textLo),
                                  ),
                                  const SizedBox(height: Sp.sHair),
                                  Text(
                                    i.onHandLabel,
                                    style: SatType.monoM(color: statusColor),
                                  ),
                                ],
                              ),
                            ),

                            // Price / Base Unit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HARGA / ${i.unit.label.toUpperCase()}',
                                    style: SatType.monoS(color: sc.textLo),
                                  ),
                                  const SizedBox(height: Sp.sHair),
                                  Text(
                                    i.costMicro > 0
                                        ? formatIDR(
                                            unitPriceFromCostMicro(
                                              i.costMicro,
                                              i.unit,
                                            ),
                                          )
                                        : '—',
                                    style: SatType.monoM(color: sc.textMd),
                                  ),
                                ],
                              ),
                            ),

                            // Last receive — freshness, not valuation
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TERAKHIR TERIMA',
                                    style: SatType.monoS(color: sc.textLo),
                                  ),
                                  const SizedBox(height: Sp.sHair),
                                  Text(
                                    i.lastReceivedAt == null
                                        ? '—'
                                        : formatElapsedId(
                                            SatClock.now().difference(
                                              i.lastReceivedAt!,
                                            ),
                                          ),
                                    style: SatType.monoM(color: sc.textMd),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Low stock threshold progress line
                        if (i.lowStockAt != null && i.lowStockAt! > 0) ...[
                          const SizedBox(height: Sp.s2),
                          _stockLevelMeter(sc, i),
                        ],

                        // Recipe links — counting doesn't need them, and the row
                        // already grows a count field in opname mode.
                        if (!_opname) ...[
                          const SizedBox(height: Sp.s2),
                          _RecipeLinkChips(
                            sc: sc,
                            madeFrom: i.madeFrom,
                            usedBy: i.usedBy,
                            expanded: _expandedLinks.contains(i.id),
                            onExpand: () =>
                                setState(() => _expandedLinks.add(i.id)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Right Actions / Opname Input
                Padding(
                  padding: const EdgeInsets.only(right: Sp.s3),
                  child: _opname
                      ? SizedBox(
                          width: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SatField.decimal(
                                hint: i.unit.label,
                                textAlign: TextAlign.right,
                                onChanged: (t) {
                                  final v = double.tryParse(
                                    t.replaceAll(',', '.'),
                                  );
                                  setState(() {
                                    if (v == null) {
                                      _counts.remove(i.id);
                                    } else {
                                      _counts[i.id] = i.unit.toBase(v);
                                    }
                                  });
                                },
                              ),
                              if (physicalCount != null) ...[
                                const SizedBox(height: Sp.s1),
                                _varianceDeltaBadge(sc, i, physicalCount),
                              ],
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PressScale(
                              child: SatButton.outline(
                                label: 'Terima',
                                icon: Icons.add_shopping_cart,
                                onTap: () => _receive(i),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: sc.textLo,
                              ),
                              onSelected: (v) => switch (v) {
                                'receive' => _receive(i),
                                'produce' => _produce(i),
                                'ledger' => _ledger(i),
                                'edit' => _editIngredient(i),
                                'archive' => _archive(i),
                                _ => null,
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'receive',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_shopping_cart, size: 16),
                                      SizedBox(width: Sp.s2h),
                                      Text('Terima barang'),
                                    ],
                                  ),
                                ),
                                if (i.isProduced)
                                  const PopupMenuItem(
                                    value: 'produce',
                                    child: Row(
                                      children: [
                                        Icon(Icons.blender_outlined, size: 16),
                                        SizedBox(width: Sp.s2h),
                                        Text('Produksi batch'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'ledger',
                                  child: Row(
                                    children: [
                                      Icon(Icons.history, size: 16),
                                      SizedBox(width: Sp.s2h),
                                      Text('Riwayat mutasi'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: Sp.s2h),
                                      Text('Ubah bahan'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.archive_outlined,
                                        size: 16,
                                        color: sc.urgent,
                                      ),
                                      const SizedBox(width: Sp.s2h),
                                      Text(
                                        'Arsipkan',
                                        style: TextStyle(color: sc.urgent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(
    SatColors sc, {
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(
        color: color.withValues(alpha: 0.12),
        borderRadius: SatR.a(6),
        border: SatB.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: Sp.s1),
          ],
          Text(label, style: SatType.caption(color: color)),
        ],
      ),
    );
  }

  Widget _stockLevelMeter(SatColors sc, Ingredient i) {
    final threshold = i.lowStockAt!;
    final ratio = (i.stockOnHand / threshold).clamp(0.0, 1.5);
    final color = i.stockOnHand <= 0
        ? sc.urgent
        : i.isLow
        ? sc.warn
        : sc.success;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: SatR.a(2),
            child: LinearProgressIndicator(
              value: (ratio / 1.5).clamp(0.0, 1.0),
              backgroundColor: sc.bg3,
              color: color,
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: Sp.s2),
        Text(
          'Batas min: ${formatQty(threshold, i.unit)}',
          style: SatType.monoS(color: sc.textLo),
        ),
      ],
    );
  }

  Widget _varianceDeltaBadge(SatColors sc, Ingredient i, int physicalCount) {
    final delta = physicalCount - i.stockOnHand;
    final positive = delta > 0;
    final color = delta == 0
        ? sc.success
        : positive
        ? sc.success
        : sc.warn;
    final sign = positive ? '+' : '';
    final text = delta == 0 ? 'Pas' : '$sign${formatQty(delta, i.unit)}';

    return AnimatedSwitcher(
      duration: satMotion(context, 180),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Text(
        text,
        key: ValueKey(text),
        style: SatType.caption(color: color),
      ),
    );
  }

  // ---------------------------------------------------------------- Actions
  Future<void> _submitOpname() async {
    final api = ref.read(stockApiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deltas = await api.recordCounts(Map.of(_counts));
      final changed = deltas.values.where((d) => d != 0).length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? 'Opname selesai — tidak ada selisih'
                : 'Opname selesai — $changed bahan disesuaikan',
          ),
        ),
      );
      setState(() {
        _opname = false;
        _counts.clear();
      });
      ref.invalidate(ingredientsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _receive(Ingredient i) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: i.costMicro > 0
          ? unitPriceFromCostMicro(i.costMicro, i.unit).toString()
          : '',
    );
    final supplierCtrl = TextEditingController();
    var unit = i.unit;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: 'Terima ${i.name}',
        subtitle: 'Catat penambahan stok dan harga beli terbaru.',
        children: [
          StatefulBuilder(
            builder: (_, setSheet) => Row(
              children: [
                Expanded(
                  child: SatField.decimal(
                    controller: qtyCtrl,
                    label: 'Jumlah',
                    hint: '',
                    autofocus: true,
                    prefixIcon: Icons.numbers_outlined,
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                SizedBox(
                  width: 110,
                  child: SatDropdown<StockUnit>(
                    value: unit,
                    options: [
                      for (final u in entryUnitsFor(i.unit))
                        SatOption(u, u.label),
                    ],
                    onChanged: (u) => setSheet(() => unit = u ?? unit),
                  ),
                ),
              ],
            ),
          ),
          SatField.number(
            controller: priceCtrl,
            label: 'Harga per ${i.unit.label} (opsional)',
            hint: '',
            helperText: 'Kosongkan jika tidak mengubah harga rata-rata',
            prefixIcon: Icons.payments_outlined,
          ),
          SatField.text(
            controller: supplierCtrl,
            label: 'Pemasok (opsional)',
            hint: '',
            prefixIcon: Icons.storefront_outlined,
          ),
        ],
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(stockApiProvider)
          .receive(
            ingredientId: i.id,
            qty: unit.toBase(amount),
            unitPrice: int.tryParse(priceCtrl.text),
            supplier: supplierCtrl.text.trim().isEmpty
                ? null
                : supplierCtrl.text.trim(),
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Stok berhasil ditambahkan')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _produce(Ingredient i) async {
    final ctrl = TextEditingController(text: '1');
    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => _Sheet(
        title: 'Produksi ${i.name}',
        subtitle: i.batchYield == null
            ? null
            : '1 batch = ${formatQty(i.batchYield!, i.unit)}. '
                  'Bahan baku penyusun akan berkurang otomatis.',
        children: [
          SatField.number(
            controller: ctrl,
            label: 'Jumlah batch',
            hint: '',
            autofocus: true,
            prefixIcon: Icons.blender_outlined,
          ),
        ],
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (ok != true) return;
    final n = int.tryParse(ctrl.text) ?? 0;
    if (n <= 0) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).produce(i.id, n);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Produksi berhasil dicatat')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _ledger(Ingredient i) async {
    await showSatSheet<void>(
      context,
      bare: true,
      builder: (_) => _LedgerSheet(ingredient: i),
    );
  }

  Future<void> _archive(Ingredient i) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).archive(i.id);
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(SnackBar(content: Text('${i.name} diarsipkan')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _editIngredient(Ingredient? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final openingCtrl = TextEditingController();
    final lowCtrl = TextEditingController(
      text: existing?.lowStockAt == null
          ? ''
          : _trim(existing!.unit.fromBase(existing.lowStockAt!)),
    );
    final yieldCtrl = TextEditingController(
      text: existing?.batchYield == null
          ? ''
          : _trim(existing!.unit.fromBase(existing.batchYield!)),
    );
    var unit = existing?.unit ?? StockUnit.pcs;

    final ok = await showSatSheet<bool>(
      context,
      bare: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => _Sheet(
          title: existing == null ? 'Bahan Baru' : 'Ubah ${existing.name}',
          subtitle: 'Atur nama, satuan unit, dan batas reorder.',
          children: [
            SatField.text(
              controller: nameCtrl,
              label: 'Nama bahan',
              hint: '',
              autofocus: existing == null,
              prefixIcon: Icons.inventory_outlined,
            ),
            SatDropdown<StockUnit>(
              value: unit,
              label: 'Satuan',
              prefixIcon: Icons.straighten_outlined,
              options: [
                for (final u in StockUnit.values)
                  SatOption(
                    u,
                    '${u.label} · ${stockDimensionLabel(u.dimension)}',
                  ),
              ],
              onChanged: (u) => setSheet(() => unit = u ?? unit),
            ),
            if (existing == null)
              SatField.decimal(
                controller: openingCtrl,
                label: 'Stok awal (${unit.label})',
                hint: '',
                helperText: 'Dicatat sebagai mutasi awal',
                prefixIcon: Icons.assessment_outlined,
              ),
            SatField.decimal(
              controller: lowCtrl,
              label: 'Batas menipis (${unit.label}, opsional)',
              hint: '',
              helperText: 'Munculkan peringatan saat stok di bawah angka ini',
              prefixIcon: Icons.warning_amber_rounded,
            ),
            SatField.decimal(
              controller: yieldCtrl,
              label: 'Hasil 1 batch (${unit.label}, opsional)',
              hint: '',
              helperText:
                  'Isi bila bahan ini hasil racikan internal, lalu susun resepnya',
              prefixIcon: Icons.blender_outlined,
            ),
          ],
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    double? parse(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.'));
    final low = parse(lowCtrl);
    final batch = parse(yieldCtrl);
    final opening = parse(openingCtrl);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(stockApiProvider)
          .save(
            Ingredient(
              id: existing?.id ?? const Uuid().v4(),
              name: name,
              unit: unit,
              lowStockAt: low == null ? null : unit.toBase(low),
              batchYield: batch == null ? null : unit.toBase(batch),
            ),
            openingStock: existing == null && opening != null
                ? unit.toBase(opening)
                : 0,
          );
      ref.invalidate(ingredientsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Bahan berhasil disimpan')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  static String _trim(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}

// ---------------------------------------------------------------- Sheet Container
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.children,
    required this.onConfirm,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(20)),
        border: SatB.all(color: sc.border1),
      ),
      padding: EdgeInsets.only(
        left: Sp.s6,
        right: Sp.s6,
        top: Sp.s3,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SatType.h3(color: sc.textHi)),
                      if (subtitle != null) ...[
                        const SizedBox(height: Sp.sHair),
                        Text(subtitle!, style: SatType.bodyS(color: sc.textLo)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.close,
                  icon: Icon(Icons.close, size: 20, color: sc.textLo),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Sp.s4),

            // Children
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s3),
                child: c,
              ),
            const SizedBox(height: Sp.s2),

            // Primary Action Button
            PressScale(
              child: SatButton.primary(
                label: AppStrings.save,
                onTap: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Ledger Sheet
class _LedgerSheet extends ConsumerWidget {
  const _LedgerSheet({required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final async = ref.watch(stockMovementsProvider(ingredient.id));

    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(20)),
        border: SatB.all(color: sc.border1),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: SatBox.d(
                    color: sc.border1,
                    borderRadius: SatR.a(2),
                  ),
                ),
              ),
              const SizedBox(height: Sp.s4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Mutasi',
                        style: SatType.h3(color: sc.textHi),
                      ),
                      Text(
                        ingredient.name.toUpperCase(),
                        style: SatType.monoS(color: sc.accentText),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: AppStrings.close,
                    icon: Icon(Icons.close, size: 20, color: sc.textLo),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s3h),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(Sp.s6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) =>
                      _Message('Gagal memuat: $e', color: sc.urgent),
                  data: (rows) => rows.isEmpty
                      ? const _Message(
                          'Belum ada riwayat mutasi untuk bahan ini.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: rows.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: sc.border0, height: 1),
                          itemBuilder: (_, i) {
                            final m = rows[i];
                            final positive = m.delta > 0;
                            return Reveal(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Sp.s2h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(Sp.s2),
                                      decoration: SatBox.d(
                                        color: positive
                                            ? sc.success.withValues(alpha: 0.1)
                                            : sc.bg3,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        positive
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color: positive
                                            ? sc.success
                                            : sc.textLo,
                                      ),
                                    ),
                                    const SizedBox(width: Sp.s3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.reason.label,
                                            style: SatType.labelM(
                                              color: sc.textHi,
                                            ),
                                          ),
                                          const SizedBox(height: Sp.sHair),
                                          Text(
                                            [
                                              if (m.sourceLabel.isNotEmpty)
                                                m.sourceLabel,
                                              _stamp(m.at),
                                              if (m.note != null) m.note!,
                                            ].join(' · '),
                                            style: SatType.monoS(
                                              color: sc.textLo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${positive ? '+' : ''}'
                                      '${formatQty(m.delta, ingredient.unit)}',
                                      style: SatType.monoM(
                                        color: positive
                                            ? sc.success
                                            : sc.textMd,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _stamp(DateTime at) {
  final l = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.onAction,
  });

  final String title;
  final String message;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Sp.s5),
              decoration: SatBox.d(
                color: sc.bg2,
                shape: BoxShape.circle,
                border: SatB.all(color: sc.border1),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: sc.textLo,
              ),
            ),
            const SizedBox(height: Sp.s4),
            Text(title, style: SatType.h3(color: sc.textHi)),
            const SizedBox(height: Sp.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: SatType.bodyM(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s5),
            PressScale(
              child: SatButton.primary(
                label: 'Tambah Bahan Pertama',
                icon: Icons.add,
                onTap: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.all(Sp.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28, color: color ?? sc.textLo),
              const SizedBox(height: Sp.s2h),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: SatType.bodyM(color: color ?? sc.textLo),
            ),
          ],
        ),
      ),
    );
  }
}

/// The recipe links on a stock card: what this ingredient is made from, then
/// what consumes it. Direction is carried by icon + color rather than group
/// labels, so both sets flow through one wrap.
///
/// Capped at two lines so one onion used in a dozen dishes can't make its card
/// five times taller than its neighbours; the overflow chip unclips it.
class _RecipeLinkChips extends StatelessWidget {
  const _RecipeLinkChips({
    required this.sc,
    required this.madeFrom,
    required this.usedBy,
    required this.expanded,
    required this.onExpand,
  });

  final SatColors sc;
  final List<String> madeFrom;
  final List<String> usedBy;
  final bool expanded;
  final VoidCallback onExpand;

  static const _maxLines = 2;
  static const _gap = 6.0;
  static const _padH = 6.0;
  static const _iconSize = 11.0;
  static const _iconGap = 3.0;
  static const _border = 1.0;

  @override
  Widget build(BuildContext context) {
    if (madeFrom.isEmpty && usedBy.isEmpty) {
      return _chip(context, 'belum dipakai', null, sc.textLo);
    }

    // Made-from first: it is the rarer, more explanatory direction, and
    // ordering it first keeps it visible when the cap bites.
    final chips = <(String, IconData, Color)>[
      for (final n in madeFrom) (n, Icons.blender_outlined, sc.info),
      for (final n in usedBy) (n, Icons.restaurant_outlined, sc.textMd),
    ];

    if (expanded) {
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final c in chips) _chip(context, c.$1, c.$2, c.$3)],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final widths = [for (final c in chips) _chipWidth(c.$1, scaler)];
        // Upper-bound the overflow chip: "+N" can only shrink as N drops, so
        // reserving the worst case never overflows the line.
        final overflowWidth = _chipWidth('+${chips.length}', scaler);

        final shown = fitChipCount(
          widths,
          maxWidth: constraints.maxWidth,
          overflowWidth: overflowWidth,
          gap: _gap,
          maxLines: _maxLines,
        );
        final hidden = chips.length - shown;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final c in chips.take(shown)) _chip(context, c.$1, c.$2, c.$3),
            if (hidden > 0)
              Semantics(
                button: true,
                label: '+$hidden',
                child: GestureDetector(
                  onTap: onExpand,
                  child: _chip(context, '+$hidden', null, sc.textLo),
                ),
              ),
          ],
        );
      },
    );
  }

  double _chipWidth(String label, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: SatType.bodyS()),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return tp.width + _padH * 2 + _border * 2 + _iconSize + _iconGap;
  }

  Widget _chip(
    BuildContext context,
    String label,
    IconData? icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: Sp.s1),
      decoration: SatBox.d(
        color: sc.bg3,
        borderRadius: SatR.a(6),
        border: SatB.all(color: sc.border1, width: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kept even when iconless so measured and rendered widths agree.
          SizedBox(
            width: _iconSize,
            child: icon == null
                ? null
                : Icon(icon, size: _iconSize, color: color),
          ),
          const SizedBox(width: _iconGap),
          Text(label, style: SatType.bodyS(color: color)),
        ],
      ),
    );
  }
}

/// How many chips of the given [widths] fit within [maxLines] rows of
/// [maxWidth], laid out the way `Wrap` does (greedy, [gap] between chips).
///
/// Returns `widths.length` when everything fits — only then is no overflow
/// chip needed, so [overflowWidth] is reserved on the last line otherwise, and
/// the result is capped below `widths.length` so a "+N" always has an N.
@visibleForTesting
int fitChipCount(
  List<double> widths, {
  required double maxWidth,
  required double overflowWidth,
  required double gap,
  required int maxLines,
}) {
  int pack(double reserve) {
    var line = 1;
    var used = 0.0;
    for (var i = 0; i < widths.length; i++) {
      // The last line must leave room for the overflow chip.
      final limit = line == maxLines ? maxWidth - reserve - gap : maxWidth;
      final w = widths[i];
      final needed = used == 0 ? w : used + gap + w;
      // An over-wide chip still gets its own line rather than vanishing.
      if (needed <= limit || used == 0) {
        used = needed;
        continue;
      }
      if (line == maxLines) return i;
      line++;
      used = w;
    }
    return widths.length;
  }

  if (pack(0) == widths.length) return widths.length;
  return pack(overflowWidth).clamp(0, widths.length - 1);
}
