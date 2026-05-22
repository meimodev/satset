import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
import '_common.dart';

class _Ticket {
  final String table;
  final String time;
  final String elapsed;
  final List<String> items;
  final String status;
  const _Ticket({required this.table, required this.time, required this.elapsed, required this.items, required this.status});
}

const _newQ = [
  _Ticket(table: 'T4', time: '18:02', elapsed: '0:12', items: ['×6 Bir Bintang', '×2 Lumpia Renyah'], status: 'new'),
  _Ticket(table: 'I3', time: '18:09', elapsed: '0:05', items: ['×1 Sate Ayam', '×1 Es Teh Manis'], status: 'new'),
  _Ticket(table: 'B1', time: '18:11', elapsed: '0:03', items: ['×2 Margarita Pedas'], status: 'new'),
];
const _prepQ = [
  _Ticket(table: 'T1', time: '17:46', elapsed: '4:28', items: ['×1 Nasi Goreng (Ayam, Sedang)', '×1 Rendang (nasi putih, no garnish)'], status: 'prep'),
  _Ticket(table: 'G3', time: '17:48', elapsed: '2:14', items: ['×1 Mie Goreng', '×1 Tempe Sambal Bowl'], status: 'prep'),
  _Ticket(table: 'I2', time: '17:55', elapsed: '0:48', items: ['×2 Sate Ayam'], status: 'prep'),
];
const _readyQ = [
  _Ticket(table: 'T2', time: '17:48', elapsed: '0:38', items: ['×1 Tempe Sambal Bowl', '×1 Mie Goreng'], status: 'ready'),
  _Ticket(table: 'G4', time: '17:52', elapsed: '0:21', items: ['×1 Nasi Goreng'], status: 'ready'),
];

class KdsScreen extends StatelessWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    if (!context.layout.useTabletShell) {
      return _phone(context, sc);
    }
    return AdminPage(
      title: 'KDS · Dapur Utama',
      sub: '3 NEW · 4 PREP · 2 HELD · AVG 8:42 · 6 CLIENTS',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, 'SERVER OK', on: true),
          const SizedBox(width: 8),
          adminPill(context, 'Pair device'),
        ],
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _column(context, sc, 'NEW', _newQ, sc.accent)),
              const SizedBox(width: 12),
              Expanded(child: _column(context, sc, 'IN PREP', _prepQ, sc.warn)),
              const SizedBox(width: 12),
              Expanded(child: _column(context, sc, 'READY · CALL EXPO', _readyQ, sc.success)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _column(BuildContext context, SatColors sc, String label, List<_Ticket> tickets, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sc.border0)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label,
                    style: SatType.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: accent,
                    )),
                const Spacer(),
                Text('${tickets.length}',
                    style: SatType.mono(
                      size: 13,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                    )),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tickets.length,
              itemBuilder: (ctx, i) => _ticketCard(ctx, sc, tickets[i], accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(BuildContext context, SatColors sc, _Ticket t, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: t.status == 'ready' ? accent.withValues(alpha: 0.4) : sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sc.bg3,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.table,
                    style: SatType.mono(
                      size: 14,
                      weight: FontWeight.w600,
                      letterSpacing: -0.14,
                      color: sc.textHi,
                    )),
              ),
              const Spacer(),
              Text(t.elapsed,
                  style: SatType.mono(
                    size: 13,
                    weight: FontWeight.w600,
                    color: t.status == 'prep' ? sc.warn : (t.status == 'ready' ? sc.success : sc.textMd),
                  )),
              const SizedBox(width: 6),
              Text(t.time,
                  style: SatType.mono(
                    size: 10,
                    color: sc.textLo,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in t.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item,
                  style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w500,
                    color: sc.textHi,
                    height: 1.3,
                  )),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (t.status == 'new')
                adminPill(context, 'Mulai siapkan', on: true)
              else if (t.status == 'prep')
                adminPill(context, 'Tandai siap', on: true)
              else
                adminPill(context, 'Panggil expo', on: true),
              const Spacer(),
              adminPill(context, 'Tahan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phone(BuildContext context, SatColors sc) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text('KDS · Dapur Utama',
                style: SatType.sans(
                  size: 26,
                  weight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: sc.textHi,
                )),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                _phoneSection(context, sc, 'NEW · 3', _newQ, sc.accent),
                _phoneSection(context, sc, 'PREP · 3', _prepQ, sc.warn),
                _phoneSection(context, sc, 'READY · 2', _readyQ, sc.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneSection(BuildContext context, SatColors sc, String label, List<_Ticket> tickets, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: SatType.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: accent,
                  )),
            ],
          ),
        ),
        for (final t in tickets) _ticketCard(context, sc, t, accent),
        const SizedBox(height: 12),
      ],
    );
  }
}
