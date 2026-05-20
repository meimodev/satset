import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/format.dart';
import '../../design/typography.dart';
import '../../models/course.dart';
import '../../models/dummy_data.dart';
import '../../models/ticket.dart';
import '../../models/venue_table.dart';
import '../../models/zone.dart';
import '../../state/tables_provider.dart';
import '../../state/tickets_provider.dart';
import '../../widgets/satset_top_bar.dart';
import '../void_flow/line_item_action_sheet.dart';

class TableDetailScreen extends ConsumerWidget {
  final String tableId;
  const TableDetailScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final tickets = ref.watch(ticketsProvider)[tableId] ?? const [];
    final table = tables.firstWhere(
      (t) => t.id == tableId,
      orElse: () => VenueTable(id: tableId, zoneId: 'terrace'),
    );
    final zone = DummyData.zones.firstWhere(
      (z) => z.id == table.zoneId,
      orElse: () => const Zone(id: '', name: '', short: ''),
    );

    final grouped = <CourseId, List<Ticket>>{};
    for (final t in tickets) {
      grouped.putIfAbsent(t.course, () => []).add(t);
    }
    final total = tickets.fold<int>(0, (s, t) => s + t.price * t.qty);
    final readyAny = tickets.any((t) => t.status == TicketStatus.ready);

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(table: table, onBack: () => context.pop()),
              _Header(table: table, zoneName: zone.name, total: total),
              if (readyAny) _ReadyBanner(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 180),
                  children: [
                    for (final cid in Courses.stationOrder.map((c) => c.id))
                      if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                        _CourseBlock(
                          course: Courses.byId(cid),
                          items: grouped[cid]!,
                          onMarkServed: (id) {
                            ref.read(ticketsProvider.notifier).markServed(tableId, id);
                            ref.read(tablesProvider.notifier).decrementReady(tableId);
                          },
                          onFireCourse: () =>
                              ref.read(ticketsProvider.notifier).fireCourse(tableId, cid),
                          onTicketTap: (t) => _openAction(context, ref, t),
                        ),
                    if (tickets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Text(
                          'Belum ada item — ketuk "Tambah ke pesanan" untuk mulai.',
                          textAlign: TextAlign.center,
                          style: SatType.sans(size: 13, color: sc.textLo),
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
            child: _PrimaryButton(
              label: tickets.isEmpty ? 'Bangun pesanan' : 'Tambah ke pesanan',
              icon: Icons.add,
              onTap: () => context.push('/table/$tableId/menu'),
            ),
          ),
        ],
      ),
    );
  }

  void _openAction(BuildContext context, WidgetRef ref, Ticket ticket) {
    showLineItemActionSheet(context: context, ref: ref, tableId: tableId, ticket: ticket);
  }
}

class _TopBar extends StatelessWidget {
  final VenueTable table;
  final VoidCallback onBack;
  const _TopBar({required this.table, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 10),
      child: Row(
        children: [
          SatBackButton(onTap: onBack),
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
              Text('T+${table.elapsed ?? '—'}',
                  style: SatType.mono(size: 10, color: sc.textMd, letterSpacing: 0.6)),
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
                style: SatType.sans(size: 12, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VenueTable table;
  final String zoneName;
  final int total;
  const _Header({required this.table, required this.zoneName, required this.total});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(table.id,
              style: SatType.mono(
                size: 44,
                weight: FontWeight.w500,
                letterSpacing: -1.32,
                height: 1.0,
                color: sc.textHi,
              )),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$zoneName · ${table.pax} tamu',
                    style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textMd)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _HPill(
                      icon: Icons.access_time,
                      label: 'duduk ${table.elapsed ?? '0:00'}',
                    ),
                    _HPill(label: formatIDR(total)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _HPill({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sc.bg3,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: sc.textMd),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: SatType.sans(
                size: 11,
                weight: FontWeight.w500,
                color: sc.textMd,
              )),
        ],
      ),
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sc.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sc.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 14, color: sc.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Item siap diambil di pass — tandai disajikan di bawah',
              style: SatType.sans(size: 12, weight: FontWeight.w500, color: sc.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseBlock extends StatelessWidget {
  final Course course;
  final List<Ticket> items;
  final void Function(String) onMarkServed;
  final VoidCallback onFireCourse;
  final void Function(Ticket) onTicketTap;

  const _CourseBlock({
    required this.course,
    required this.items,
    required this.onMarkServed,
    required this.onFireCourse,
    required this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final allHeld = items.every((it) => it.status == TicketStatus.held);
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: course.color(sc)),
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
                Text(
                  '${items.length} item${allHeld ? ' · ditahan' : ''}',
                  style: SatType.mono(size: 11, color: sc.textLo, letterSpacing: 0),
                ),
              ],
            ),
          ),
          for (final it in items)
            _LineItem(ticket: it, onTap: () => onTicketTap(it), onMarkServed: onMarkServed),
          if (allHeld)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _FireButton(label: 'Bakar ${course.name}', onTap: onFireCourse),
            ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final void Function(String) onMarkServed;
  const _LineItem({required this.ticket, required this.onTap, required this.onMarkServed});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isReady = ticket.status == TicketStatus.ready;
    final isVoided = ticket.status == TicketStatus.voided;
    final bg = isReady ? sc.successSoft : (isVoided ? sc.bg1 : sc.bg2);
    final border = isReady ? sc.success.withValues(alpha: 0.3) : sc.border0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: isVoided ? 0.5 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text('×${ticket.qty}',
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
                          ticket.name +
                              (ticket.variantName.isEmpty ? '' : ' · ${ticket.variantName}'),
                          style: SatType.sans(
                            size: 14,
                            weight: FontWeight.w500,
                            letterSpacing: -0.14,
                            height: 1.25,
                            color: isVoided ? sc.textLo : sc.textHi,
                          ).copyWith(
                              decoration: isVoided ? TextDecoration.lineThrough : null),
                        ),
                        if (ticket.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(ticket.modifiers.join(' · '),
                                style: SatType.sans(size: 12, color: sc.textMd, height: 1.4)),
                          ),
                        if (ticket.specialInstructions != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('⚠ ${ticket.specialInstructions!}',
                                style: SatType.sans(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: sc.urgent,
                                )),
                          ),
                        if (ticket.voidReason != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'Dibatalkan · ${ticket.voidReason} · disetujui oleh ${ticket.voidApprovedBy ?? ''}',
                              style: SatType.sans(size: 12, color: sc.urgent, height: 1.4),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatusChip(status: ticket.status),
                            const SizedBox(width: 8),
                            Text(
                              '${ticket.station.name == 'kitchen' ? 'DPR' : 'BAR'} · ${ticket.sentAt}',
                              style: SatType.mono(
                                size: 10,
                                color: sc.textLo,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            Text(formatIDR(ticket.price * ticket.qty),
                                style: SatType.mono(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: sc.textMd,
                                  letterSpacing: 0,
                                )),
                          ],
                        ),
                        if (isReady)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _SmallSuccessButton(
                              label: 'Tandai disajikan',
                              icon: Icons.check,
                              onTap: () => onMarkServed(ticket.id),
                            ),
                          ),
                      ],
                    ),
                  ),
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

class _FireButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FireButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: sc.accentSoft,
          foregroundColor: sc.accent,
          side: BorderSide(color: sc.accentBorder, style: BorderStyle.solid),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(Icons.local_fire_department, size: 14, color: sc.accent),
        label: Text(label.toUpperCase(),
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 0.48,
              color: sc.accent,
            )),
      ),
    );
  }
}

class _SmallSuccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SmallSuccessButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: sc.successSoft,
          foregroundColor: sc.success,
          side: BorderSide(color: sc.success.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 14, color: sc.success),
        label: Text(label.toUpperCase(),
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 0.48,
              color: sc.success,
            )),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: sc.accentInk),
        label: Text(label,
            style: SatType.sans(
              size: 15,
              weight: FontWeight.w600,
              letterSpacing: -0.15,
              color: sc.accentInk,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: sc.accent,
          foregroundColor: sc.accentInk,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}
