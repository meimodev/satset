import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/format.dart';
import '../../design/typography.dart';
import '../../models/cart_item.dart';
import '../../models/course.dart';
import '../../models/menu_item.dart';
import '../../state/cart_provider.dart';
import '../../state/tables_provider.dart';
import '../../state/tickets_provider.dart';
import '../../widgets/satset_top_bar.dart';

class ReviewScreen extends ConsumerWidget {
  final String tableId;
  const ReviewScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final cart = ref.watch(cartProvider);
    final tables = ref.watch(tablesProvider);
    final table = tables.firstWhere((t) => t.id == tableId, orElse: () => tables.first);

    final grouped = <CourseId, List<CartItem>>{};
    for (final c in cart) {
      grouped.putIfAbsent(c.course, () => []).add(c);
    }
    final subtotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final allergens = <Allergen>{};
    for (final c in cart) {
      allergens.addAll(c.allergens);
    }
    final kitchenCt = cart
        .where((c) => c.station == Station.kitchen)
        .fold<int>(0, (s, c) => s + c.qty);
    final barCt =
        cart.where((c) => c.station == Station.bar).fold<int>(0, (s, c) => s + c.qty);

    String sendTarget;
    if (kitchenCt > 0 && barCt > 0) {
      sendTarget = 'dapur + bar';
    } else if (kitchenCt > 0) {
      sendTarget = 'dapur';
    } else {
      sendTarget = 'bar';
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
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sc.success,
                            boxShadow: [BoxShadow(color: sc.successSoft, spreadRadius: 3)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('LIVE · LAN',
                            style: SatType.mono(
                                size: 10, color: sc.textMd, letterSpacing: 0.6)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF9233), Color(0xFFD96030)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text('MA',
                          style: SatType.sans(
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tinjau pesanan',
                        style: SatType.sans(
                          size: 30,
                          weight: FontWeight.w600,
                          letterSpacing: -0.6,
                          height: 1.05,
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      'MEJA $tableId · ${table.pax} TAMU · ${cart.fold<int>(0, (s, c) => s + c.qty)} ITEM',
                      style: SatType.mono(
                          size: 11, color: sc.textLo, letterSpacing: 0.44),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (kitchenCt > 0)
                      _Pill(
                        icon: Icons.local_fire_department,
                        label: 'Dapur × $kitchenCt',
                      ),
                    if (barCt > 0)
                      _Pill(icon: Icons.local_bar, label: 'Bar × $barCt'),
                    if (allergens.isNotEmpty)
                      _Pill(
                        icon: Icons.warning_amber_rounded,
                        label: allergens
                            .map((a) => allergenNames[a] ?? '')
                            .join(' · '),
                        tone: _Tone.urgent,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 200),
                  children: [
                    for (final cid in [
                      CourseId.drinksNow,
                      CourseId.starters,
                      CourseId.mains,
                      CourseId.sides,
                      CourseId.desserts,
                      CourseId.fireNow,
                    ])
                      if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                        _CourseBlock(
                          course: Courses.byId(cid),
                          items: grouped[cid]!,
                          onRemove: (id) =>
                              ref.read(cartProvider.notifier).remove(id),
                        ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: sc.bg2,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: sc.border0),
                        ),
                        child: Column(
                          children: [
                            _TotalsRow(label: 'Subtotal', value: formatIDR(subtotal)),
                            _TotalsRow(
                              label: 'Layanan · 7%',
                              value: formatIDR((subtotal * 0.07).round()),
                            ),
                            _TotalsRow(
                              label: 'Pajak · 11%',
                              value: formatIDR((subtotal * 0.11).round()),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border(top: BorderSide(color: sc.border0)),
                              ),
                              child: _TotalsRow(
                                label: 'Total perkiraan',
                                value: formatIDR((subtotal * 1.18).round()),
                                isTotal: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Text(
                        'PEMBAYARAN DITANGANI DI LUAR SATSET · BILL DICETAK DARI POS SAAT DISAJIKAN',
                        style: SatType.mono(
                          size: 11,
                          color: sc.textLo,
                          letterSpacing: 0.44,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        ref
                            .read(ticketsProvider.notifier)
                            .sendOrder(tableId, cart);
                        ref.read(tablesProvider.notifier).markPending(tableId);
                        final stations = <String>{
                          if (kitchenCt > 0) 'Dapur',
                          if (barCt > 0) 'Bar',
                        }.join(',');
                        ref.read(cartProvider.notifier).clear();
                        context.go('/table/$tableId/sent?stations=$stations');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: sc.accent,
                  foregroundColor: sc.accentInk,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: sc.accentInk),
                    const SizedBox(width: 10),
                    Text('Kirim ke $sendTarget',
                        style: SatType.sans(
                          size: 15,
                          weight: FontWeight.w600,
                          color: sc.accentInk,
                        )),
                    const SizedBox(width: 10),
                    Text(formatIDR(subtotal),
                        style: SatType.mono(
                          size: 14,
                          weight: FontWeight.w500,
                          color: sc.accentInk.withValues(alpha: 0.7),
                          letterSpacing: 0,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { normal, urgent }

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final _Tone tone;
  const _Pill({required this.icon, required this.label, this.tone = _Tone.normal});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg;
    Color fg;
    switch (tone) {
      case _Tone.urgent:
        bg = sc.urgentSoft;
        fg = sc.urgent;
        break;
      case _Tone.normal:
        bg = sc.bg3;
        fg = sc.textMd;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: SatType.sans(size: 11, weight: FontWeight.w500, color: fg)),
          ),
        ],
      ),
    );
  }
}

class _CourseBlock extends StatelessWidget {
  final Course course;
  final List<CartItem> items;
  final void Function(String) onRemove;
  const _CourseBlock({
    required this.course,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final auto = course.id == CourseId.fireNow || course.id == CourseId.drinksNow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: course.color(sc)),
                ),
                const SizedBox(width: 10),
                Text(course.name.toUpperCase(),
                    style: SatType.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      letterSpacing: 1.32,
                      color: sc.textMd,
                    )),
                const Spacer(),
                Text(auto ? 'auto-bakar' : 'ditahan sampai dibakar',
                    style: SatType.mono(
                        size: 11, color: sc.textLo, letterSpacing: 0)),
              ],
            ),
          ),
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sc.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sc.border0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('×${c.qty}',
                          style: SatType.mono(
                            size: 13,
                            weight: FontWeight.w600,
                            color: sc.textMd,
                            letterSpacing: 0,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name + (c.variantName.isEmpty ? '' : ' · ${c.variantName}'),
                            style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w500,
                              letterSpacing: -0.14,
                              color: sc.textHi,
                            ),
                          ),
                          if (c.modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(c.modifiers.join(' · '),
                                  style: SatType.sans(
                                      size: 12, color: sc.textMd, height: 1.4)),
                            ),
                          if (c.special.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('⚠ ${c.special}',
                                  style: SatType.sans(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: sc.urgent,
                                  )),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => onRemove(c.id),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 12, color: sc.urgent),
                                    const SizedBox(width: 4),
                                    Text('Hapus',
                                        style: SatType.sans(
                                          size: 12,
                                          color: sc.urgent,
                                        )),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(formatIDR(c.unitPrice * c.qty),
                                  style: SatType.mono(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: sc.textMd,
                                    letterSpacing: 0,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _TotalsRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: SatType.sans(
                  size: isTotal ? 16 : 13,
                  weight: isTotal ? FontWeight.w600 : FontWeight.w400,
                  color: isTotal ? sc.textHi : sc.textMd,
                )),
          ),
          Text(value,
              style: SatType.mono(
                size: isTotal ? 18 : 13,
                weight: FontWeight.w500,
                color: sc.textHi,
                letterSpacing: 0,
              )),
        ],
      ),
    );
  }
}
