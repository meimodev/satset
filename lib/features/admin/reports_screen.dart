import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
import '_common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isTab = context.layout.useTabletShell;
    final children = <Widget>[
      Row(
        children: [
          Expanded(child: SetTile(label: 'Net', value: 'Rp 14,3jt', sub: 'Service 7% · Tax 11%')),
          const SizedBox(width: 12),
          Expanded(child: SetTile(label: 'Tamu', value: '128', sub: 'Cover · 47 meja')),
          const SizedBox(width: 12),
          Expanded(child: SetTile(label: 'Avg / cover', value: 'Rp 112rb', sub: 'Naik 8% dari rata-rata')),
          const SizedBox(width: 12),
          Expanded(child: SetTile(label: 'Void', value: '3', sub: 'Rp 215rb · 1.5%')),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _bigCard(context, sc, 'Top items shift ini', _topItems)),
          const SizedBox(width: 14),
          Expanded(child: _bigCard(context, sc, 'Performa per pelayan', _byServer)),
        ],
      ),
      const SizedBox(height: 14),
      _stationsCard(context, sc),
    ];
    if (!isTab) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Laporan shift',
                  style: SatType.sans(
                    size: 30,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: sc.textHi,
                  )),
            ),
            ...children,
          ],
        ),
      );
    }
    return AdminPage(
      title: 'Laporan shift',
      sub: 'Sabtu 21 Mei · 17:30 — sekarang · live',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, 'Live', on: true),
          const SizedBox(width: 8),
          adminPill(context, 'Ekspor PDF'),
        ],
      ),
      children: children,
    );
  }

  Widget _bigCard(BuildContext context, SatColors sc, String title, List<List<String>> rows) {
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
          Text(title,
              style: SatType.sans(
                size: 15,
                weight: FontWeight.w600,
                color: sc.textHi,
              )),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: sc.border0, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(rows[i][0], style: SatType.sans(size: 14, weight: FontWeight.w500, color: sc.textHi))),
                  const SizedBox(width: 12),
                  Text(rows[i][1], style: SatType.mono(size: 12, color: sc.textMd, letterSpacing: 0.4)),
                  const SizedBox(width: 12),
                  Text(rows[i][2], style: SatType.mono(size: 13, weight: FontWeight.w600, color: sc.textHi)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationsCard(BuildContext context, SatColors sc) {
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
          Text('Throughput stasiun',
              style: SatType.sans(size: 15, weight: FontWeight.w600, color: sc.textHi)),
          const SizedBox(height: 12),
          _stationBar(context, sc, 'Dapur Utama', 0.78, '78 / 100 cap', sc.success),
          _stationBar(context, sc, 'Bar', 0.42, '42 / 100 cap', sc.info),
          _stationBar(context, sc, 'Pass / Expo', 0.61, '61 / 100 cap', sc.accent),
        ],
      ),
    );
  }

  Widget _stationBar(BuildContext context, SatColors sc, String label, double pct, String count, Color tone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textHi))),
              Text(count, style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0.44)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: sc.bg3, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 6, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _topItems = [
  ['Nasi Goreng', '×24', 'Rp 2,2jt'],
  ['Sate Ayam', '×18', 'Rp 1,4jt'],
  ['Bir Bintang', '×42', 'Rp 1,9jt'],
  ['Rendang Sapi', '×12', 'Rp 1,7jt'],
  ['Margarita Pedas', '×9', 'Rp 990rb'],
];
const _byServer = [
  ['Maya Anjani', '6 meja · 28 item', 'Rp 4,2jt'],
  ['Dewi Wira', '5 meja · 22 item', 'Rp 3,1jt'],
  ['Komang T.', 'expo', '—'],
];
