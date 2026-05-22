import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/layout.dart';
import '_common.dart';

enum _Range { today, yesterday, d7, d30, month }

enum _Section { sales, staff, menu, ops }

enum _StaffSort { net, covers, voidPct, avgTicket }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Range _range = _Range.today;
  final Set<_Section> _on = {_Section.sales, _Section.staff, _Section.menu, _Section.ops};
  String _server = 'Semua pelayan';
  String _zone = 'Semua zona';
  String _category = 'Semua kategori';
  _StaffSort _staffSort = _StaffSort.net;

  static const _rangeLabel = {
    _Range.today: 'Hari ini',
    _Range.yesterday: 'Kemarin',
    _Range.d7: '7 hari',
    _Range.d30: '30 hari',
    _Range.month: 'Bulan ini',
  };

  static const _rangeSub = {
    _Range.today: 'Sab 21 Mei · 17:30 — sekarang · live',
    _Range.yesterday: 'Jum 20 Mei · 11:00 — 23:30',
    _Range.d7: '15 — 21 Mei · 7 shift',
    _Range.d30: '22 Apr — 21 Mei · 30 hari',
    _Range.month: 'Mei 2026 · 1 — 21',
  };

  static const _sectionLabel = {
    _Section.sales: 'Penjualan',
    _Section.staff: 'Staf',
    _Section.menu: 'Menu',
    _Section.ops: 'Operasi',
  };

  @override
  Widget build(BuildContext context) {
    final isTab = context.layout.useTabletShell;
    final body = _body(context, isTab);
    if (!isTab) {
      final sc = context.sat;
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Laporan',
                  style: SatType.sans(
                    size: 30,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: sc.textHi,
                  )),
            ),
            ...body,
          ],
        ),
      );
    }
    return AdminPage(
      title: 'Laporan',
      sub: _rangeSub[_range]!,
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, _range == _Range.today ? 'Live' : 'Snapshot',
              on: _range == _Range.today),
        ],
      ),
      children: body,
    );
  }

  List<Widget> _body(BuildContext context, bool isTab) {
    return [
      _rangeRow(context),
      const SizedBox(height: 12),
      _filterRow(context),
      const SizedBox(height: 12),
      _sectionTabs(context),
      const SizedBox(height: 14),
      if (_on.contains(_Section.sales)) ...[_salesSection(context, isTab), const SizedBox(height: 14)],
      if (_on.contains(_Section.staff)) ...[_staffSection(context), const SizedBox(height: 14)],
      if (_on.contains(_Section.menu)) ...[_menuSection(context, isTab), const SizedBox(height: 14)],
      if (_on.contains(_Section.ops)) ...[_opsSection(context, isTab), const SizedBox(height: 14)],
      if (_on.isEmpty) _emptyState(context),
    ];
  }

  Widget _rangeRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in _Range.values) ...[
            GestureDetector(
              onTap: () => setState(() => _range = r),
              child: adminPill(context, _rangeLabel[r]!, on: _range == r),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _filterRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _filterChip(context, 'Pelayan', _server, ['Semua pelayan', 'Maya Anjani', 'Dewi Wira', 'Komang T.', 'Reno P.'], (v) => setState(() => _server = v))),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(context, 'Zona', _zone, ['Semua zona', 'Indoor', 'Teras', 'VIP', 'Bar'], (v) => setState(() => _zone = v))),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(context, 'Kategori', _category, ['Semua kategori', 'Mains', 'Starters', 'Drinks', 'Desserts'], (v) => setState(() => _category = v))),
      ],
    );
  }

  Widget _filterChip(BuildContext context, String label, String value, List<String> options, ValueChanged<String> onPick) {
    final sc = context.sat;
    final active = !value.toLowerCase().startsWith('semua');
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
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
                        style: SatType.mono(size: 11, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo)),
                  ),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(o, style: SatType.sans(size: 14, color: sc.textHi)),
                    trailing: o == value ? Icon(Icons.check, color: sc.accent, size: 18) : null,
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
                      style: SatType.mono(size: 9, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo)),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.sans(size: 13, weight: FontWeight.w500, color: active ? sc.accent : sc.textHi)),
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

  Widget _card(BuildContext context, String title, {String? sub, required Widget child, Widget? trailing}) {
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
                        style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.textHi)),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(),
                          style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.8)),
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

  // ──────────── SALES ────────────
  Widget _salesSection(BuildContext context, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _salesKpis(context),
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _paymentMix(context)),
              const SizedBox(width: 14),
              Expanded(child: _hourlyRevenue(context)),
            ],
          )
        else ...[
          _paymentMix(context),
          const SizedBox(height: 14),
          _hourlyRevenue(context),
        ],
      ],
    );
  }

  Widget _salesKpis(BuildContext context) {
    final tiles = const [
      ('Net', 'Rp 14,3jt', '+8% vs rata-rata'),
      ('Gross', 'Rp 16,8jt', '128 tamu · 47 meja'),
      ('Pajak + Service', 'Rp 2,5jt', 'PB1 11% · Svc 7%'),
      ('Diskon + Void', 'Rp 480rb', '6 diskon · 3 void'),
    ];
    return LayoutBuilder(builder: (c, cons) {
      final narrow = cons.maxWidth < 520;
      if (narrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: SetTile(label: tiles[0].$1, value: tiles[0].$2, sub: tiles[0].$3)),
              const SizedBox(width: 12),
              Expanded(child: SetTile(label: tiles[1].$1, value: tiles[1].$2, sub: tiles[1].$3)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SetTile(label: tiles[2].$1, value: tiles[2].$2, sub: tiles[2].$3)),
              const SizedBox(width: 12),
              Expanded(child: SetTile(label: tiles[3].$1, value: tiles[3].$2, sub: tiles[3].$3)),
            ]),
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            Expanded(child: SetTile(label: tiles[i].$1, value: tiles[i].$2, sub: tiles[i].$3)),
            if (i != tiles.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    });
  }

  Widget _paymentMix(BuildContext context) {
    final sc = context.sat;
    final segs = [
      ('Tunai', 0.18, sc.warn),
      ('QRIS', 0.46, sc.success),
      ('Kartu', 0.24, sc.info),
      ('E-wallet', 0.12, sc.violet),
    ];
    return _card(
      context,
      'Bauran pembayaran',
      sub: '${segs.length} kanal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                for (final s in segs)
                  Expanded(
                    flex: (s.$2 * 1000).round(),
                    child: Container(height: 14, color: s.$3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < segs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: segs[i].$3, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(segs[i].$1, style: SatType.sans(size: 13, color: sc.textHi))),
                  Text('${(segs[i].$2 * 100).round()}%',
                      style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.4)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hourlyRevenue(BuildContext context) {
    final sc = context.sat;
    final bars = const [0.10, 0.14, 0.22, 0.55, 0.78, 0.92, 1.00, 0.88, 0.64, 0.42, 0.26, 0.18];
    const labels = ['11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22'];
    return _card(
      context,
      'Pendapatan per jam',
      sub: 'Puncak 17:00 — 18:00',
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < bars.length; i++) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 100 * bars[i],
                      decoration: BoxDecoration(
                        color: bars[i] >= 0.9 ? sc.accent : sc.bg4,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i],
                        style: SatType.mono(size: 9, color: sc.textLo, letterSpacing: 0.4)),
                  ],
                ),
              ),
              if (i != bars.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────── STAFF ────────────
  Widget _staffSection(BuildContext context) {
    final sc = context.sat;
    final rows = [
      ('Maya Anjani', 6, 28, 'Rp 150rb', 0.6, 4200000.0),
      ('Dewi Wira', 5, 22, 'Rp 141rb', 1.1, 3100000.0),
      ('Reno P.', 4, 19, 'Rp 132rb', 0.0, 2510000.0),
      ('Komang T.', 0, 0, 'expo', 0.0, 0.0),
      ('Putri H.', 3, 14, 'Rp 118rb', 2.3, 1650000.0),
    ];
    int Function((String, int, int, String, double, double)) keyer;
    switch (_staffSort) {
      case _StaffSort.net:
        keyer = (r) => -(r.$6.round());
        break;
      case _StaffSort.covers:
        keyer = (r) => -r.$2;
        break;
      case _StaffSort.voidPct:
        keyer = (r) => -(r.$5 * 100).round();
        break;
      case _StaffSort.avgTicket:
        keyer = (r) => r.$4.startsWith('Rp')
            ? -int.parse(r.$4.replaceAll(RegExp(r'[^0-9]'), ''))
            : 0;
        break;
    }
    final sorted = [...rows]..sort((a, b) => keyer(a).compareTo(keyer(b)));
    return _card(
      context,
      'Performa pelayan',
      sub: '${rows.length} staf · sortir aktif',
      trailing: _sortMenu(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _staffHead(context),
          const SizedBox(height: 6),
          Divider(color: sc.border0, height: 1),
          for (var i = 0; i < sorted.length; i++) ...[
            _staffRow(context, sorted[i], i),
            if (i != sorted.length - 1) Divider(color: sc.border0, height: 1),
          ],
        ],
      ),
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
          PopupMenuItem(value: s, child: Text({
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
            Text(label, style: SatType.sans(size: 11, weight: FontWeight.w500, color: sc.textHi)),
          ],
        ),
      ),
    );
  }

  Widget _staffHead(BuildContext context) {
    final sc = context.sat;
    TextStyle s() => SatType.mono(size: 10, weight: FontWeight.w600, letterSpacing: 1.0, color: sc.textLo);
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

  Widget _staffRow(BuildContext context, (String, int, int, String, double, double) r, int idx) {
    final sc = context.sat;
    final netStr = r.$6 == 0 ? '—' : 'Rp ${(r.$6 / 1000000).toStringAsFixed(1)}jt';
    final voidStr = r.$1.contains('Komang') ? '—' : '${r.$5.toStringAsFixed(1)}%';
    final voidColor = r.$5 > 2.0 ? sc.warn : (r.$5 > 1.0 ? sc.textMd : sc.textLo);
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
                    border: Border.all(color: idx == 0 ? sc.accentBorder : sc.border0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${idx + 1}',
                      style: SatType.mono(size: 10, weight: FontWeight.w600, color: idx == 0 ? sc.accent : sc.textMd)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.$1,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('${r.$2}', textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textHi))),
          Expanded(flex: 2, child: Text('${r.$3}', textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textHi))),
          Expanded(flex: 3, child: Text(r.$4, textAlign: TextAlign.right, style: SatType.mono(size: 12, color: sc.textMd))),
          Expanded(flex: 2, child: Text(voidStr, textAlign: TextAlign.right, style: SatType.mono(size: 12, color: voidColor))),
          Expanded(flex: 3, child: Text(netStr, textAlign: TextAlign.right, style: SatType.mono(size: 13, weight: FontWeight.w600, color: sc.textHi))),
        ],
      ),
    );
  }

  // ──────────── MENU ────────────
  Widget _menuSection(BuildContext context, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _menuList(context, 'Top sellers', _menuTop, top: true)),
              const SizedBox(width: 14),
              Expanded(child: _menuList(context, 'Slow movers', _menuSlow, top: false)),
            ],
          )
        else ...[
          _menuList(context, 'Top sellers', _menuTop, top: true),
          const SizedBox(height: 14),
          _menuList(context, 'Slow movers', _menuSlow, top: false),
        ],
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _modifierAttach(context)),
              const SizedBox(width: 14),
              Expanded(child: _eightySixed(context)),
            ],
          )
        else ...[
          _modifierAttach(context),
          const SizedBox(height: 14),
          _eightySixed(context),
        ],
      ],
    );
  }

  Widget _menuList(BuildContext context, String title, List<(String, String, String, String, double)> rows, {required bool top}) {
    final sc = context.sat;
    return _card(
      context,
      title,
      sub: top ? '${rows.length} item · margin tinggi' : '${rows.length} item · stok mengendap',
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
                        Text(rows[i].$1,
                            style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi)),
                        const SizedBox(height: 2),
                        Text('${rows[i].$2} · margin ${rows[i].$4}',
                            style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(rows[i].$3,
                      style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.4)),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(2)),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: rows[i].$5,
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

  Widget _modifierAttach(BuildContext context) {
    final sc = context.sat;
    final mods = const [
      ('Tambah keju', 0.62),
      ('Level pedas', 0.48),
      ('Tanpa MSG', 0.21),
      ('Es / no-es', 0.71),
      ('Take away', 0.14),
    ];
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
                      Expanded(child: Text(m.$1, style: SatType.sans(size: 13, color: sc.textHi))),
                      Text('${(m.$2 * 100).round()}%',
                          style: SatType.mono(size: 12, weight: FontWeight.w600, color: sc.textHi)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(children: [
                    Container(height: 5, decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(
                      widthFactor: m.$2,
                      child: Container(height: 5, decoration: BoxDecoration(color: sc.info, borderRadius: BorderRadius.circular(3))),
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _eightySixed(BuildContext context) {
    final sc = context.sat;
    final items = const [
      ('Rendang Sapi', 'habis 19:12'),
      ('Margarita Pedas', 'habis 20:40'),
      ('Es Doger', 'habis 21:05'),
    ];
    return _card(
      context,
      "86'd hari ini",
      sub: '${items.length} item dimatikan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: sc.urgent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(items[i].$1, style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi))),
                  Text(items[i].$2.toUpperCase(),
                      style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.8)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────── OPS ────────────
  Widget _opsSection(BuildContext context, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _opsKpis(context),
        const SizedBox(height: 14),
        if (isTab)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stationsCard(context)),
              const SizedBox(width: 14),
              Expanded(child: _heatmap(context)),
            ],
          )
        else ...[
          _stationsCard(context),
          const SizedBox(height: 14),
          _heatmap(context),
        ],
      ],
    );
  }

  Widget _opsKpis(BuildContext context) {
    return LayoutBuilder(builder: (c, cons) {
      final narrow = cons.maxWidth < 520;
      final tiles = const [
        ('Avg turn time', '38 min', 'Target 45 min'),
        ('Time to ready', '11 min', 'Median order → pass'),
        ('Ready alerts', '14', '2 lewat 5 min'),
        ('Reservasi', '8 / 12', 'Slot terisi'),
      ];
      if (narrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: SetTile(label: tiles[0].$1, value: tiles[0].$2, sub: tiles[0].$3)),
              const SizedBox(width: 12),
              Expanded(child: SetTile(label: tiles[1].$1, value: tiles[1].$2, sub: tiles[1].$3)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SetTile(label: tiles[2].$1, value: tiles[2].$2, sub: tiles[2].$3)),
              const SizedBox(width: 12),
              Expanded(child: SetTile(label: tiles[3].$1, value: tiles[3].$2, sub: tiles[3].$3)),
            ]),
          ],
        );
      }
      return Row(children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: SetTile(label: tiles[i].$1, value: tiles[i].$2, sub: tiles[i].$3)),
          if (i != tiles.length - 1) const SizedBox(width: 12),
        ],
      ]);
    });
  }

  Widget _stationsCard(BuildContext context) {
    final sc = context.sat;
    return _card(
      context,
      'Throughput stasiun',
      sub: 'Beban vs kapasitas',
      child: Column(
        children: [
          _stationBar(context, 'Dapur Utama', 0.78, '78 / 100 cap', sc.success),
          _stationBar(context, 'Bar', 0.42, '42 / 100 cap', sc.info),
          _stationBar(context, 'Pass / Expo', 0.61, '61 / 100 cap', sc.accent),
          _stationBar(context, 'Pastry', 0.34, '34 / 100 cap', sc.violet),
        ],
      ),
    );
  }

  Widget _stationBar(BuildContext context, String label, double pct, String count, Color tone) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi))),
            Text(count, style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44)),
          ]),
          const SizedBox(height: 6),
          Stack(children: [
            Container(height: 6, decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 6, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(3))),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _heatmap(BuildContext context) {
    final sc = context.sat;
    // 7 days × 12 hours (11..22), 0..1 intensity
    final grid = [
      [.05, .08, .12, .30, .55, .70, .82, .68, .50, .30, .15, .08],
      [.06, .10, .15, .32, .58, .74, .85, .72, .55, .35, .20, .10],
      [.08, .12, .18, .35, .60, .78, .88, .76, .60, .42, .26, .14],
      [.10, .15, .22, .42, .68, .84, .92, .82, .65, .48, .30, .18],
      [.15, .22, .35, .58, .80, .96, 1.0, .92, .78, .62, .44, .28],
      [.20, .30, .48, .70, .88, 1.0, .98, .90, .80, .68, .52, .36],
      [.12, .18, .28, .45, .65, .80, .85, .76, .60, .45, .30, .18],
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const hours = ['11', '', '13', '', '15', '', '17', '', '19', '', '21', ''];
    return _card(
      context,
      'Peak-hour heatmap',
      sub: '7 hari terakhir · jam 11—22',
      child: LayoutBuilder(builder: (c, cons) {
        final cellW = (cons.maxWidth - 32) / 12;
        final cell = cellW.clamp(14.0, 28.0);
        return Column(
          children: [
            Row(
              children: [
                SizedBox(width: 32),
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
            for (var r = 0; r < grid.length; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(days[r], style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6)),
                    ),
                    for (var col = 0; col < grid[r].length; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: cell - 2,
                          height: cell - 2,
                          decoration: BoxDecoration(
                            color: Color.lerp(sc.bg3, sc.accent, grid[r][col]),
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
                    width: 12, height: 12,
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
}

// Menu seed data: name, count, revenue, margin label, bar fill 0..1
const _menuTop = <(String, String, String, String, double)>[
  ('Nasi Goreng Kambing', '×24', 'Rp 2,2jt', '58%', 1.0),
  ('Sate Ayam Madura', '×18', 'Rp 1,4jt', '52%', 0.74),
  ('Bir Bintang', '×42', 'Rp 1,9jt', '64%', 0.92),
  ('Rendang Sapi', '×12', 'Rp 1,7jt', '47%', 0.82),
  ('Margarita Pedas', '×9', 'Rp 990rb', '69%', 0.48),
];
const _menuSlow = <(String, String, String, String, double)>[
  ('Salad Quinoa', '×1', 'Rp 78rb', '38%', 0.08),
  ('Soup Tom Yum', '×2', 'Rp 120rb', '44%', 0.12),
  ('Mocktail Lychee', '×2', 'Rp 90rb', '60%', 0.10),
  ('Pasta Carbonara', '×3', 'Rp 240rb', '42%', 0.18),
  ('Es Cendol', '×3', 'Rp 105rb', '55%', 0.16),
];
