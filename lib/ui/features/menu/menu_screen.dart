import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/services/dummy_data_seed.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'modifier_sheet.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String tableId;
  const MenuScreen({super.key, required this.tableId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _cat = 'mains';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final cols = l.gridCount(minTileWidth: 170);
    final cart = ref.watch(cartProvider);
    final tables = ref.watch(tablesProvider);
    final table = tables.firstWhere(
      (t) => t.id == widget.tableId,
      orElse: () => tables.first,
    );

    final items =
        DummyData.items.where((i) => _cat == 'all' || i.categoryId == _cat).toList();
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
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: sc.border0)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => safePop(context, fallback: '/table/${widget.tableId}'),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: sc.bg2,
                              border: Border.all(color: sc.border0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.arrow_back, size: 18, color: sc.textMd),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tambah ke Meja ${widget.tableId}',
                                  style: SatType.sans(
                                    size: 18,
                                    weight: FontWeight.w600,
                                    letterSpacing: -0.18,
                                    color: sc.textHi,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                '${table.zoneId.toUpperCase()} · ${table.pax} TAMU',
                                style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 36,
                          width: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: sc.bg2,
                            border: Border.all(color: sc.border0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 14, color: sc.textLo),
                              const SizedBox(width: 8),
                              Text('Cari menu…',
                                  style: SatType.sans(size: 13, color: sc.textLo)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: sc.border0)),
                    ),
                    child: _CatTabs(active: _cat, onChange: (id) => setState(() => _cat = id)),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
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
                ],
              ),
            ),
            _TabletCartPane(
              tableId: widget.tableId,
              onReview: () => context.push('/table/${widget.tableId}/review'),
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
              Padding(
                padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
                child: Row(
                  children: [
                    SatBackButton(onTap: () => safePop(context, fallback: '/table/${widget.tableId}')),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sc.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: sc.accentBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place_outlined, size: 11, color: sc.accent),
                          const SizedBox(width: 6),
                          Text('Meja ${widget.tableId} · ${table.pax}p',
                              style: SatType.sans(
                                size: 11,
                                weight: FontWeight.w500,
                                color: sc.accent,
                              )),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SatBackButton(onTap: () {}, icon: Icons.search),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tambah item',
                        style: SatType.sans(
                          size: 30,
                          weight: FontWeight.w600,
                          letterSpacing: -0.6,
                          height: 1.05,
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      'KETUK UNTUK ATUR · TEKAN LAMA UNTUK TAMBAH DEFAULT',
                      style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sc.bg2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sc.border0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: sc.textLo),
                      const SizedBox(width: 10),
                      Text('Cari menu…',
                          style: SatType.sans(size: 14, color: sc.textLo)),
                    ],
                  ),
                ),
              ),
              _CatTabs(active: _cat, onChange: (id) => setState(() => _cat = id)),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: GridView.count(
                      crossAxisCount: cols,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.74,
                      padding: EdgeInsets.fromLTRB(16, 4, 16, l.bottomInset + 80),
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
              bottom: l.useSideRail ? 16 + l.padding.bottom : 92 + l.padding.bottom,
              child: _CartFooter(
                count: cartCount,
                total: cartTotal,
                onReview: () => context.push('/table/${widget.tableId}/review'),
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
        ref.read(cartProvider.notifier).add(cartItem);
      },
    );
  }
}

class _CatTabs extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  const _CatTabs({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: DummyData.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = DummyData.categories[i];
          final isActive = active == c.id;
          return GestureDetector(
            onTap: () => onChange(c.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? sc.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(c.name,
                  style: SatType.sans(
                    size: 13,
                    weight: FontWeight.w500,
                    color: isActive ? sc.accent : sc.textMd,
                  )),
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final MenuItem item;
  final int inCart;
  final VoidCallback onTap;
  const _ItemCard({required this.item, required this.inCart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final disabled = item.unavailable;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: inCart > 0 ? sc.bg3 : sc.bg2,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: inCart > 0 ? sc.accentBorder : sc.border0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                          gradient: LinearGradient(
                            colors: [sc.bg3, sc.bg4],
                            stops: const [0.5, 0.5],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Text('PHOTO',
                            style: SatType.mono(
                              size: 9,
                              color: sc.textDim,
                              letterSpacing: 0.72,
                            )),
                      ),
                      if (item.unavailable)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text("86'D",
                                style: SatType.mono(
                                  size: 9,
                                  color: sc.urgent,
                                  letterSpacing: 0.72,
                                )),
                          ),
                        ),
                      if (inCart > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: sc.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text('×$inCart',
                                style: SatType.mono(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: sc.accentInk,
                                  letterSpacing: 0,
                                )),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.sans(
                            size: 14,
                            weight: FontWeight.w500,
                            letterSpacing: -0.14,
                            height: 1.2,
                            color: sc.textHi,
                          )),
                      const SizedBox(height: 6),
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
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            for (final a in item.allergens)
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: sc.bg4,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(allergenCodes[a] ?? '?',
                                    style: SatType.mono(
                                      size: 8,
                                      weight: FontWeight.w600,
                                      color: sc.textLo,
                                      letterSpacing: 0,
                                    )),
                              ),
                          ],
                        ),
                      ],
                    ],
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
  const _CartFooter({required this.count, required this.total, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? const Color(0xF01C1F23)
        : const Color(0xF0FFFFFF);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: sc.border1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count item pending',
                  style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)),
              Text(formatIDR(total),
                  style: SatType.mono(size: 11, color: sc.textMd, letterSpacing: 0)),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tinjau',
                    style: SatType.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: sc.accentInk,
                    )),
                const SizedBox(width: 6),
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
  final VoidCallback onReview;
  const _TabletCartPane({required this.tableId, required this.onReview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cart = ref.watch(cartProvider);
    final count = cart.fold<int>(0, (s, c) => s + c.qty);
    final subtotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final kit = cart.where((c) => c.station == Station.kitchen).fold<int>(0, (s, c) => s + c.qty);
    final bar = cart.where((c) => c.station == Station.bar).fold<int>(0, (s, c) => s + c.qty);
    final taxService = (subtotal * 0.18).round();
    final est = subtotal + taxService;

    final byCourse = <String, List<int>>{};
    for (var i = 0; i < cart.length; i++) {
      final cid = cart[i].course.toString().split('.').last;
      byCourse.putIfAbsent(cid, () => []).add(i);
    }

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(left: BorderSide(color: sc.border0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sc.border0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PESANAN BARU · MEJA $tableId',
                    style: SatType.mono(size: 10, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo)),
                const SizedBox(height: 6),
                Text(count == 0 ? 'Keranjang kosong' : '$count item siap kirim',
                    style: SatType.sans(size: 18, weight: FontWeight.w600, letterSpacing: -0.18, color: sc.textHi)),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    [if (kit > 0) 'Dapur × $kit', if (bar > 0) 'Bar × $bar'].join('  ·  '),
                    style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44),
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
                      child: Text('Belum ada item di keranjang. Pilih dari menu di kiri.',
                          textAlign: TextAlign.center,
                          style: SatType.sans(size: 13, color: sc.textLo, height: 1.5)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    children: [
                      for (final entry in byCourse.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(entry.key.toUpperCase(),
                              style: SatType.mono(size: 11, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textMd)),
                        ),
                        for (final i in entry.value)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sc.bg2,
                              border: Border.all(color: sc.border0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('×${cart[i].qty}',
                                        style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textMd)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cart[i].variantName.isEmpty ? cart[i].name : '${cart[i].name} · ${cart[i].variantName}',
                                        style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi, letterSpacing: -0.13),
                                      ),
                                    ),
                                  ],
                                ),
                                if (cart[i].modifiers.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 22),
                                    child: Text(cart[i].modifiers.join(' · '),
                                        style: SatType.sans(size: 11, color: sc.textMd, height: 1.3)),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => ref.read(cartProvider.notifier).remove(cart[i].id),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 12, color: sc.urgent),
                                          const SizedBox(width: 4),
                                          Text('Hapus',
                                              style: SatType.sans(size: 12, color: sc.urgent)),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(formatIDR(cart[i].unitPrice * cart[i].qty),
                                        style: SatType.mono(size: 12, weight: FontWeight.w500, color: sc.textMd)),
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
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: sc.border0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        _totalRow(context, sc, 'Subtotal', formatIDR(subtotal)),
                        _totalRow(context, sc, 'Layanan 7% · Pajak 11%', formatIDR(taxService)),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: sc.border0)),
                            ),
                            child: Row(
                              children: [
                                Text('Estimasi',
                                    style: SatType.sans(size: 13, weight: FontWeight.w600, color: sc.textHi)),
                                const Spacer(),
                                Text(formatIDR(est),
                                    style: SatType.mono(size: 13, weight: FontWeight.w600, color: sc.textHi)),
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
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: onReview,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            'Tinjau & kirim ke ${kit > 0 && bar > 0 ? 'dapur + bar' : kit > 0 ? 'dapur' : 'bar'}',
                            style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.accentInk),
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

  Widget _totalRow(BuildContext context, SatColors sc, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.24)),
          const Spacer(),
          Text(value, style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.24)),
        ],
      ),
    );
  }
}
