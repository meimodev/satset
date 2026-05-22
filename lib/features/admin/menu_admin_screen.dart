import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
import '../../design/format.dart';
import '../../models/dummy_data.dart';
import '../../models/menu_item.dart';
import '_common.dart';

class MenuAdminScreen extends StatelessWidget {
  const MenuAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final items = DummyData.items;
    final isTab = context.layout.useTabletShell;
    final table = Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _headRow(context, sc),
          for (final it in items) _itemRow(context, sc, it),
        ],
      ),
    );
    if (!isTab) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Menu admin',
                  style: SatType.sans(
                    size: 30,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: sc.textHi,
                  )),
            ),
            table,
          ],
        ),
      );
    }
    return AdminPage(
      title: 'Menu admin',
      sub: '${items.length} item · 9 kategori · 1 86\'d',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, 'Filter kategori'),
          const SizedBox(width: 8),
          adminPill(context, 'Tambah item', on: true),
        ],
      ),
      children: [table],
    );
  }

  Widget _headRow(BuildContext context, SatColors sc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(flex: 16, child: _h(context, 'Item')),
          Expanded(flex: 8, child: _h(context, 'Kategori')),
          Expanded(flex: 6, child: _h(context, 'Stasiun')),
          SizedBox(width: 110, child: _h(context, 'Harga')),
          SizedBox(width: 80, child: _h(context, 'Prep')),
          SizedBox(width: 130, child: _h(context, 'Status')),
        ],
      ),
    );
  }

  Widget _h(BuildContext context, String t) {
    final sc = context.sat;
    return Text(t.toUpperCase(),
        style: SatType.mono(
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 1.2,
          color: sc.textLo,
        ));
  }

  Widget _itemRow(BuildContext context, SatColors sc, MenuItem it) {
    final isLast = DummyData.items.indexOf(it) == DummyData.items.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name,
                    style: SatType.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: sc.textHi,
                      letterSpacing: -0.14,
                    )),
                if (it.allergens.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final a in it.allergens)
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: sc.bg4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(allergenCodes[a] ?? '',
                              style: SatType.mono(
                                size: 8,
                                weight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: sc.textLo,
                              )),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(flex: 8, child: Text(it.categoryId, style: SatType.sans(size: 13, color: sc.textMd))),
          Expanded(flex: 6, child: Text(it.station == Station.kitchen ? 'Dapur' : 'Bar', style: SatType.sans(size: 13, color: sc.textMd))),
          SizedBox(width: 110, child: Text(formatIDR(it.basePrice), style: SatType.mono(size: 12, color: sc.textHi))),
          SizedBox(width: 80, child: Text('${it.prepTime} mnt', style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.4))),
          SizedBox(
            width: 130,
            child: it.unavailable
                ? adminPill(context, '86\'D', danger: true)
                : adminPill(context, 'Aktif', on: true),
          ),
        ],
      ),
    );
  }
}
