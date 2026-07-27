import 'package:flutter/material.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/tag_badge_row.dart';
import 'modifier_sheet.dart';
import 'package:satset/ui/core/design/spacing.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String tableId;

  /// When true this is a table-less draft ([tableId] is a draft id / visit id,
  /// not a real table). The table is chosen at review/commit time (menu-first)
  /// or there is none (takeaway).
  final bool tableless;

  /// Set when adding items to an existing takeaway (Bawa pulang) visit:
  /// [tableId] is the takeaway visit id and submit appends to it. See ADR-0026.
  final String? takeawayVisitId;
  const MenuScreen({
    super.key,
    required this.tableId,
    this.tableless = false,
    this.takeawayVisitId,
  });

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _cat = 'mains';

  bool get _isTakeaway => widget.takeawayVisitId != null;
  String get _backFallback => _isTakeaway
      ? '/takeaway/${widget.takeawayVisitId}'
      : widget.tableless
      ? '/tables'
      : '/table/${widget.tableId}';
  String get _reviewLoc => _isTakeaway
      ? '/takeaway/${widget.takeawayVisitId}/review'
      : widget.tableless
      ? '/order/new/review'
      : '/table/${widget.tableId}/review';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final cols = l.gridCount(minTileWidth: 170);
    final cart = ref.watch(cartProvider(widget.tableId));
    final tables = ref.watch(tablesProvider);
    final table = widget.tableless
        ? null
        : tables.firstWhere(
            (t) => t.id == widget.tableId,
            orElse: () => tables.isEmpty
                ? VenueTable(id: widget.tableId, zoneId: '')
                : tables.first,
          );

    final menuStatus = ref.watch(menuStatusProvider);
    final allItems = ref.watch(menuItemsProvider);
    final items = allItems
        .where((i) => _cat == 'all' || i.categoryId == _cat)
        .toList();

    if (menuStatus.isLoading) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Sp.s3),
              Text(
                'Memuat menu…',
                style: SatType.sans(size: 13, color: sc.textMd),
              ),
            ],
          ),
        ),
      );
    }
    if (menuStatus.hasError) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 36, color: sc.urgent),
                const SizedBox(height: Sp.s3),
                Text(
                  'Gagal memuat menu',
                  style: SatType.sans(
                    size: 16,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  '${menuStatus.error}',
                  textAlign: TextAlign.center,
                  style: SatType.sans(size: 12, color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3h),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(menuRepositoryProvider.notifier).refresh(),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final cartCount = cart.fold<int>(0, (s, c) => s + c.qty);
    final cartTotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final inCartQty = <String, int>{};
    for (final c in cart) {
      inCartQty[c.itemId] = (inCartQty[c.itemId] ?? 0) + c.qty;
    }

    if (l.useTabletShell) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
                    decoration: SatBox.d(
                      border: Border(bottom: SatB.side(color: sc.border0)),
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: AppStrings.back,
                          child: GestureDetector(
                            onTap: () =>
                                safePop(context, fallback: _backFallback),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: SatBox.d(
                                color: sc.bg2,
                                border: SatB.all(color: sc.border0),
                                borderRadius: SatR.a(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: sc.textMd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Sp.s3h),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tableless
                                    ? (_isTakeaway
                                          ? 'Tambah ke Bawa pulang'
                                          : 'Pesanan baru')
                                    : 'Tambah ke Meja ${table!.displayName}',
                                style: SatType.sans(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  letterSpacing: -0.18,
                                  color: sc.textHi,
                                ),
                              ),
                              const SizedBox(height: Sp.sHair),
                              Text(
                                widget.tableless
                                    ? (_isTakeaway
                                          ? 'BAWA PULANG · TANPA MEJA'
                                          : 'TANPA MEJA · PILIH MEJA SAAT KIRIM')
                                    : '${table!.zoneId.toUpperCase()} · ${table.pax} TAMU',
                                style: SatType.mono(
                                  size: 11,
                                  color: sc.textLo,
                                  letterSpacing: 0.44,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 36,
                          width: 200,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.s3,
                          ),
                          decoration: SatBox.d(
                            color: sc.bg2,
                            border: SatB.all(color: sc.border0),
                            borderRadius: SatR.a(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 14, color: sc.textLo),
                              const SizedBox(width: Sp.s2),
                              Text(
                                'Cari menu…',
                                style: SatType.sans(size: 13, color: sc.textLo),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    decoration: SatBox.d(
                      border: Border(bottom: SatB.side(color: sc.border0)),
                    ),
                    child: _CatTabs(
                      active: _cat,
                      onChange: (id) => setState(() => _cat = id),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dynamicCols = l.responsiveColumns(
                          constraints.maxWidth,
                          minTileWidth: 175,
                        );
                        return GridView.count(
                          crossAxisCount: dynamicCols,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.70,
                          padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
                          children: [
                            for (final it in items)
                              _ItemCard(
                                item: it,
                                inCart: inCartQty[it.id] ?? 0,
                                onTap: () => _openItem(it),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _TabletCartPane(
              tableId: widget.tableId,
              tableless: widget.tableless,
              takeaway: _isTakeaway,
              onReview: () => context.push(_reviewLoc),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              SatAppBar(
                onBack: () => safePop(context, fallback: _backFallback),
                title: widget.tableless
                    ? (_isTakeaway ? 'Bawa pulang' : 'Pesanan baru')
                    : 'Meja ${table!.displayName} · ${table.pax}p',
                crumbs: widget.tableless
                    ? (_isTakeaway
                          ? const ['Bawa pulang', 'Tambah item']
                          : const ['Pesanan baru', 'Tambah item'])
                    : ['Meja', table!.displayName, 'Tambah item'],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah item',
                      style: SatType.sans(
                        size: 30,
                        weight: FontWeight.w600,
                        letterSpacing: -0.6,
                        height: 1.05,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      'KETUK UNTUK ATUR · TEKAN LAMA UNTUK TAMBAH DEFAULT',
                      style: SatType.mono(
                        size: 11,
                        color: sc.textLo,
                        letterSpacing: 0.44,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
                  decoration: SatBox.d(
                    color: sc.bg2,
                    borderRadius: SatR.a(14),
                    border: SatB.all(color: sc.border0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: sc.textLo),
                      const SizedBox(width: Sp.s2h),
                      Text(
                        'Cari menu…',
                        style: SatType.sans(size: 14, color: sc.textLo),
                      ),
                    ],
                  ),
                ),
              ),
              _CatTabs(
                active: _cat,
                onChange: (id) => setState(() => _cat = id),
              ),
              const SizedBox(height: Sp.s2),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: GridView.count(
                      crossAxisCount: cols,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.74,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        l.bottomInset + 80,
                      ),
                      children: [
                        for (final it in items)
                          _ItemCard(
                            item: it,
                            inCart: inCartQty[it.id] ?? 0,
                            onTap: () => _openItem(it),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (cartCount > 0)
            Positioned(
              left: 8 + l.padding.left,
              right: 8 + l.padding.right,
              bottom: l.useSideRail
                  ? 16 + l.padding.bottom
                  : 92 + l.padding.bottom,
              child: _CartFooter(
                count: cartCount,
                total: cartTotal,
                onReview: () => context.push(_reviewLoc),
              ),
            ),
        ],
      ),
    );
  }

  void _openItem(MenuItem item) {
    if (item.unavailable) return;
    showModifierSheet(
      context: context,
      item: item,
      onAdd: (cartItem) {
        ref.read(cartProvider(widget.tableId).notifier).add(cartItem);
      },
    );
  }
}

class _CatTabs extends ConsumerWidget {
  final String active;
  final ValueChanged<String> onChange;
  const _CatTabs({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cats = ref.watch(menuCategoriesProvider);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: Sp.s1h),
        itemBuilder: (_, i) {
          final c = cats[i];
          final isActive = active == c.id;
          return GestureDetector(
            onTap: () => onChange(c.id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s3h,
                vertical: Sp.s2,
              ),
              decoration: SatBox.d(
                color: isActive ? sc.accentSoft : Colors.transparent,
                borderRadius: SatR.a(999),
              ),
              alignment: Alignment.center,
              child: Text(
                c.name,
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: isActive ? sc.accentText : sc.textMd,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final MenuItem item;
  final int inCart;
  final VoidCallback onTap;
  const _ItemCard({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tagsById = ref.watch(menuTagsByIdProvider);
    final disabled = item.unavailable;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: inCart > 0 ? sc.bg3 : sc.bg2,
        borderRadius: SatR.a(22),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: SatR.a(22),
          child: Container(
            decoration: SatBox.d(
              borderRadius: SatR.a(22),
              border: SatB.all(
                color: inCart > 0 ? sc.accentBorder : sc.border0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MenuPhoto(
                          itemId: item.id,
                          name: item.name,
                          photoRev: item.photoRev,
                          borderRadius: BorderRadius.vertical(top: SatR.c(21)),
                          initialsSize: 30,
                        ),
                      ),
                      if (item.unavailable)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.s2,
                              vertical: 3,
                            ),
                            decoration: SatBox.d(
                              color: satMediaScrim,
                              borderRadius: SatR.a(999),
                            ),
                            child: Text(
                              "HABIS",
                              style: SatType.mono(
                                size: 9,
                                color: sc.urgent,
                                letterSpacing: 0.72,
                              ),
                            ),
                          ),
                        ),
                      if (inCart > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.s2,
                            ),
                            decoration: SatBox.d(
                              color: sc.accent,
                              borderRadius: SatR.a(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '×$inCart',
                              style: SatType.mono(
                                size: 13,
                                weight: FontWeight.w600,
                                color: sc.accentInk,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.sans(
                            size: 14,
                            weight: FontWeight.w500,
                            letterSpacing: -0.14,
                            height: 1.2,
                            color: sc.textHi,
                          ),
                        ),
                        const SizedBox(height: Sp.s1h),
                        Text(
                          '${formatIDR(item.basePrice)}${item.variants.length > 1 ? '+' : ''}',
                          style: SatType.mono(
                            size: 12,
                            weight: FontWeight.w500,
                            color: sc.textMd,
                            letterSpacing: 0,
                          ),
                        ),
                        if (item.allergens.isNotEmpty) ...[
                          const SizedBox(height: Sp.s1),
                          TagBadgeRow(
                            ids: item.allergens,
                            tagsById: tagsById,
                            fg: sc.urgent,
                            bg: sc.urgentSoft,
                          ),
                        ],
                        if (item.dietary.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          TagBadgeRow(
                            ids: item.dietary,
                            tagsById: tagsById,
                            fg: sc.info,
                            bg: sc.infoSoft,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onReview;
  const _CartFooter({
    required this.count,
    required this.total,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      decoration: SatBox.d(
        color: SatShape.veil(sc.scrim, 0.94),
        borderRadius: SatR.a(22),
        border: SatB.all(color: sc.border1),
        boxShadow: switch (SatShape.skin) {
          SatSkin.brutal => SatShape.hardShadow(5),
          SatSkin.glow => SatShape.liftLg,
          SatSkin.lembut => [
            BoxShadow(color: satShadowInk.withValues(alpha: 0.4), blurRadius: 32),
          ],
        },
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count item pending',
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: sc.textHi,
                ),
              ),
              Text(
                formatIDR(total),
                style: SatType.mono(
                  size: 11,
                  color: sc.textMd,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: sc.accent,
              foregroundColor: sc.accentInk,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4h),
              shape: RoundedRectangleBorder(borderRadius: SatR.a(14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tinjau',
                  style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: sc.accentInk,
                  ),
                ),
                const SizedBox(width: Sp.s1h),
                Icon(Icons.chevron_right, size: 16, color: sc.accentInk),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletCartPane extends ConsumerWidget {
  final String tableId;
  final bool tableless;
  final bool takeaway;
  final VoidCallback onReview;
  const _TabletCartPane({
    required this.tableId,
    required this.onReview,
    this.tableless = false,
    this.takeaway = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cart = ref.watch(cartProvider(tableId));
    final count = cart.fold<int>(0, (s, c) => s + c.qty);
    final subtotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final kit = count;
    final bar = 0;
    final venue = ref.watch(venueSettingsProvider);
    final breakdown = computeBreakdown(subtotal, venue.toTaxServiceConfig());
    final serviceLabel = venue.serviceMode == 'fixed'
        ? 'Layanan'
        : 'Layanan · ${_fmtPct(venue.serviceRateBps)}';
    final taxLabel = 'Pajak · ${_fmtPct(venue.taxRateBps)}';
    final est = breakdown.total;

    final byCourse = <String, List<int>>{};
    for (var i = 0; i < cart.length; i++) {
      final cid = cart[i].course.toString().split('.').last;
      byCourse.putIfAbsent(cid, () => []).add(i);
    }

    return Container(
      width: 380,
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(left: SatB.side(color: sc.border0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            decoration: SatBox.d(
              border: Border(bottom: SatB.side(color: sc.border0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  takeaway
                      ? 'BAWA PULANG · TANPA MEJA'
                      : tableless
                      ? 'PESANAN BARU · TANPA MEJA'
                      : 'PESANAN BARU · MEJA $tableId',
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: sc.textLo,
                  ),
                ),
                const SizedBox(height: Sp.s1h),
                Text(
                  count == 0 ? 'Keranjang kosong' : '$count item siap kirim',
                  style: SatType.sans(
                    size: 18,
                    weight: FontWeight.w600,
                    letterSpacing: -0.18,
                    color: sc.textHi,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: Sp.s1),
                  Text(
                    [
                      if (kit > 0) 'Dapur × $kit',
                      if (bar > 0) 'Bar × $bar',
                    ].join('  ·  '),
                    style: SatType.mono(
                      size: 11,
                      color: sc.textLo,
                      letterSpacing: 0.44,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Belum ada item di keranjang. Pilih dari menu di kiri.',
                        textAlign: TextAlign.center,
                        style: SatType.sans(
                          size: 13,
                          color: sc.textLo,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    children: [
                      for (final entry in byCourse.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: SatType.mono(
                              size: 11,
                              weight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: sc.textMd,
                            ),
                          ),
                        ),
                        for (final i in entry.value)
                          Container(
                            margin: const EdgeInsets.only(bottom: Sp.s1h),
                            padding: const EdgeInsets.all(Sp.s3),
                            decoration: SatBox.d(
                              color: sc.bg2,
                              border: SatB.all(color: sc.border0),
                              borderRadius: SatR.a(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '×${cart[i].qty}',
                                      style: SatType.mono(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: sc.textMd,
                                      ),
                                    ),
                                    const SizedBox(width: Sp.s2),
                                    Expanded(
                                      child: Text(
                                        cart[i].variantName.isEmpty
                                            ? cart[i].name
                                            : '${cart[i].name} · ${cart[i].variantName}',
                                        style: SatType.sans(
                                          size: 13,
                                          weight: FontWeight.w500,
                                          color: sc.textHi,
                                          letterSpacing: -0.13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (cart[i].modifiers.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: Sp.s1,
                                      left: 22,
                                    ),
                                    child: Text(
                                      cart[i].modifiers.join(' · '),
                                      style: SatType.sans(
                                        size: 11,
                                        color: sc.textMd,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: Sp.s2),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => ref
                                          .read(cartProvider(tableId).notifier)
                                          .remove(cart[i].id),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 12,
                                            color: sc.urgent,
                                          ),
                                          const SizedBox(width: Sp.s1),
                                          Text(
                                            'Hapus',
                                            style: SatType.sans(
                                              size: 12,
                                              color: sc.urgent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      formatIDR(
                                        cart[i].unitPrice * cart[i].qty,
                                      ),
                                      style: SatType.mono(
                                        size: 12,
                                        weight: FontWeight.w500,
                                        color: sc.textMd,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: SatBox.d(
                border: Border(top: SatB.side(color: sc.border0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.s3),
                    child: Column(
                      children: [
                        _totalRow(context, sc, 'Subtotal', formatIDR(subtotal)),
                        if (venue.serviceEnabled)
                          _totalRow(
                            context,
                            sc,
                            serviceLabel,
                            formatIDR(breakdown.serviceAmount),
                          ),
                        if (venue.taxEnabled)
                          _totalRow(
                            context,
                            sc,
                            taxLabel,
                            formatIDR(breakdown.taxAmount),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: Sp.s2),
                          child: Container(
                            padding: const EdgeInsets.only(top: Sp.s2),
                            decoration: SatBox.d(
                              border: Border(top: SatB.side(color: sc.border0)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Estimasi',
                                  style: SatType.sans(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: sc.textHi,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatIDR(est),
                                  style: SatType.mono(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: sc.textHi,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: sc.accent,
                      borderRadius: SatR.a(16),
                      child: InkWell(
                        onTap: onReview,
                        borderRadius: SatR.a(16),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            'Tinjau & kirim ke ${kit > 0 && bar > 0
                                ? 'dapur + bar'
                                : kit > 0
                                ? 'dapur'
                                : 'bar'}',
                            style: SatType.sans(
                              size: 15,
                              weight: FontWeight.w600,
                              color: sc.accentInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    SatColors sc,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: SatType.mono(
              size: 12,
              color: sc.textMd,
              letterSpacing: 0.24,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: SatType.mono(
              size: 12,
              color: sc.textMd,
              letterSpacing: 0.24,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtPct(int bps) {
  final v = bps / 100.0;
  return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}%';
}
