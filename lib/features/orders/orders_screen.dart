import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/layout.dart';
import '../../design/typography.dart';
import '../../models/menu_item.dart';
import '../../models/ticket.dart';
import '../../state/tables_provider.dart';
import '../../state/tickets_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _seg = 'ready';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final tickets = ref.watch(ticketsProvider);
    final tables = ref.watch(tablesProvider);

    final all = <_Row>[];
    tickets.forEach((tableId, list) {
      final table = tables.where((t) => t.id == tableId).firstOrNull;
      if (table == null || !table.mine) return;
      for (final t in list) {
        all.add(_Row(ticket: t, tableId: tableId, zoneId: table.zoneId, pax: table.pax));
      }
    });

    final ready = all.where((r) => r.ticket.status == TicketStatus.ready).toList();
    final active = all
        .where((r) =>
            r.ticket.status == TicketStatus.sent ||
            r.ticket.status == TicketStatus.prep ||
            r.ticket.status == TicketStatus.cooked ||
            r.ticket.status == TicketStatus.held)
        .toList();
    final done = all
        .where((r) =>
            r.ticket.status == TicketStatus.served ||
            r.ticket.status == TicketStatus.voided)
        .toList();

    final list = _seg == 'ready' ? ready : (_seg == 'active' ? active : done);

    if (l.useTabletShell) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan saya',
                    style: SatType.sans(
                      size: 32,
                      weight: FontWeight.w600,
                      letterSpacing: -0.8,
                      height: 1.05,
                      color: sc.textHi,
                    )),
                const SizedBox(height: 6),
                Text('${active.length} BERJALAN · ${ready.length} SIAP DIAMBIL',
                    style: SatType.mono(
                      size: 11,
                      color: sc.textLo,
                      letterSpacing: 0.66,
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
            child: Row(
              children: [
                _TabletSeg(label: 'Siap diambil', count: ready.length, active: _seg == 'ready', onTap: () => setState(() => _seg = 'ready')),
                const SizedBox(width: 8),
                _TabletSeg(label: 'Disiapkan', count: active.length, active: _seg == 'active', onTap: () => setState(() => _seg = 'active')),
                const SizedBox(width: 8),
                _TabletSeg(label: 'Selesai', count: done.length, active: _seg == 'done', onTap: () => setState(() => _seg = 'done')),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Text(
                        _seg == 'ready'
                            ? 'Belum ada yang siap di pass.'
                            : _seg == 'active'
                                ? 'Tidak ada item yang sedang disiapkan.'
                                : 'Belum ada item yang selesai pada sesi ini.',
                        style: SatType.sans(size: 13, color: sc.textLo),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 120,
                    ),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final r = list[i];
                      return _OrderRow(row: r, onTap: () => context.push('/table/${r.tableId}'));
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sc.bg2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: sc.border1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 14, color: sc.textHi),
                    const SizedBox(width: 6),
                    Text('Semua pesananku',
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w500,
                          color: sc.textHi,
                        )),
                  ],
                ),
              ),
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
              _Avatar(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pesanan',
                  style: SatType.sans(
                    size: 30,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 4),
              Text(
                '${active.length} aktif · ${ready.length} siap diambil',
                style: SatType.mono(
                    size: 11, color: sc.textLo, letterSpacing: 0.44),
              ),
            ],
          ),
        ),
        _Segments(
          seg: _seg,
          ready: ready.length,
          active: active.length,
          done: done.length,
          onChange: (v) => setState(() => _seg = v),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _seg == 'ready'
                          ? 'Belum ada yang siap di pass.'
                          : _seg == 'active'
                              ? 'Tidak ada item sedang disiapkan.'
                              : 'Belum ada item selesai sesi ini.',
                      style: SatType.sans(size: 13, color: sc.textLo),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, l.bottomInset),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return _OrderRow(
                          row: r,
                          onTap: () => context.push('/table/${r.tableId}'),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Row {
  final Ticket ticket;
  final String tableId;
  final String zoneId;
  final int pax;
  _Row({required this.ticket, required this.tableId, required this.zoneId, required this.pax});
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFFF9233), Color(0xFFD96030)]),
      ),
      alignment: Alignment.center,
      child: Text('MA',
          style: SatType.sans(
            size: 12,
            weight: FontWeight.w600,
            color: Colors.white,
          )),
    );
  }
}

class _Segments extends StatelessWidget {
  final String seg;
  final int ready;
  final int active;
  final int done;
  final ValueChanged<String> onChange;
  const _Segments({
    required this.seg,
    required this.ready,
    required this.active,
    required this.done,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SegBtn(label: 'Siap', count: ready, active: seg == 'ready', onTap: () => onChange('ready')),
          const SizedBox(width: 6),
          _SegBtn(label: 'Disiapkan', count: active, active: seg == 'active', onTap: () => onChange('active')),
          const SizedBox(width: 6),
          _SegBtn(label: 'Selesai', count: done, active: seg == 'done', onTap: () => onChange('done')),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _SegBtn({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? sc.textHi : sc.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? sc.textHi : sc.border0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: active ? sc.bg0 : sc.textMd,
                )),
            const SizedBox(width: 8),
            Text('$count',
                style: SatType.mono(
                  size: 11,
                  color: active ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
                  letterSpacing: 0,
                )),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final _Row row;
  final VoidCallback onTap;
  const _OrderRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final t = row.ticket;
    final isReady = t.status == TicketStatus.ready;
    final isVoided = t.status == TicketStatus.voided;
    final bg = isReady ? sc.successSoft : sc.bg2;
    final border = isReady ? sc.success.withValues(alpha: 0.3) : sc.border0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: isVoided ? 0.55 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isReady
                          ? sc.success.withValues(alpha: 0.2)
                          : sc.bg3,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(row.tableId,
                        style: SatType.mono(
                          size: 16,
                          weight: FontWeight.w600,
                          letterSpacing: -0.16,
                          color: isReady ? sc.success : sc.textHi,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              if (t.qty > 1)
                                TextSpan(
                                  text: '×${t.qty} ',
                                  style: SatType.mono(
                                    size: 12,
                                    color: sc.textMd,
                                    letterSpacing: 0,
                                  ),
                                ),
                              TextSpan(
                                text: t.name,
                                style: SatType.sans(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: sc.textHi,
                                ),
                              ),
                              if (t.variantName.isNotEmpty)
                                TextSpan(
                                  text: ' · ${t.variantName}',
                                  style: SatType.sans(size: 14, color: sc.textMd),
                                ),
                            ],
                          ),
                        ),
                        if (t.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              t.modifiers.take(2).join(' · ') +
                                  (t.modifiers.length > 2 ? ' · …' : ''),
                              style: SatType.sans(
                                  size: 11, color: sc.textMd, height: 1.3),
                            ),
                          ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            _StatusChip(status: t.status),
                            const SizedBox(width: 8),
                            Text(
                              '${t.station == Station.kitchen ? 'DPR' : 'BAR'} · ${t.sentAt}',
                              style: SatType.mono(
                                size: 10,
                                color: sc.textLo,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: sc.textLo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color bg;
    Color fg;
    switch (status) {
      case TicketStatus.sent:
        bg = sc.infoSoft;
        fg = sc.info;
        break;
      case TicketStatus.prep:
        bg = sc.warnSoft;
        fg = sc.warn;
        break;
      case TicketStatus.cooked:
        bg = sc.accentSoft;
        fg = sc.accent;
        break;
      case TicketStatus.ready:
        bg = sc.successSoft;
        fg = sc.success;
        break;
      case TicketStatus.served:
        bg = sc.bg3;
        fg = sc.textLo;
        break;
      case TicketStatus.held:
        bg = sc.violetSoft;
        fg = sc.violet;
        break;
      case TicketStatus.voided:
        bg = sc.urgentSoft;
        fg = sc.urgent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        ticketStatusLabel(status).toUpperCase(),
        style: SatType.mono(
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 1.0,
          color: fg,
        ),
      ),
    );
  }
}

class _TabletSeg extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabletSeg({required this.label, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? sc.textHi : sc.bg2,
          border: Border.all(color: active ? sc.textHi : sc.border0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: active ? sc.bg0 : sc.textMd,
                )),
            const SizedBox(width: 10),
            Text('$count',
                style: SatType.mono(
                  size: 11,
                  color: active ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
                )),
          ],
        ),
      ),
    );
  }
}
