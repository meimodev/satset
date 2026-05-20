import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/format.dart';
import '../../design/typography.dart';
import '../../models/dummy_data.dart';
import '../../models/menu_item.dart';
import '../../state/cart_provider.dart';
import '../../state/tables_provider.dart';
import '../../widgets/satset_top_bar.dart';
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

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 10),
                child: Row(
                  children: [
                    SatBackButton(onTap: () => context.pop()),
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
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.74,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 200),
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
          if (cartCount > 0)
            Positioned(
              left: 8,
              right: 8,
              bottom: 20,
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
