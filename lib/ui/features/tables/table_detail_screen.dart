import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/data/services/dummy_data_seed.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import '../void_flow/line_item_action_sheet.dart';
import 'package:satset/ui/features/tables/widgets/guest_stepper.dart';

class TableDetailScreen extends ConsumerWidget {
  final String tableId;
  const TableDetailScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l = context.layout;
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
    final user = ref.watch(authStateProvider).user;
    final actorId = user?.id;
    final canEditGuests = user?.role == UserRole.waiter;

    void onMinus() => ref
        .read(tablesProvider.notifier)
        .decrementPax(tableId, userId: actorId);
    void onPlus() => ref
        .read(tablesProvider.notifier)
        .incrementPax(tableId, userId: actorId);

    final grouped = <CourseId, List<Ticket>>{};
    for (final t in tickets) {
      grouped.putIfAbsent(t.course, () => []).add(t);
    }
    final total = tickets.fold<int>(0, (s, t) => s + t.price * t.qty);
    final readyAny = tickets.any((t) => t.status == TicketStatus.ready);

    if (l.useTabletShell) {
      return _TabletSplit(
        table: table,
        zone: zone,
        tickets: tickets,
        grouped: grouped,
        total: total,
        readyAny: readyAny,
        canEditGuests: canEditGuests,
        onMinusPax: onMinus,
        onPlusPax: onPlus,
        onMarkServed: (id) {
          ref.read(ticketsProvider.notifier).markServed(tableId, id);
          ref
              .read(tablesProvider.notifier)
              .decrementReady(tableId, userId: actorId);
        },
        onFireCourse: (cid) =>
            ref.read(ticketsProvider.notifier).fireCourse(tableId, cid),
        onTicketTap: (t) => _openAction(context, ref, t),
        onAdd: () => context.push('/table/$tableId/menu'),
        onBack: () => safePop(context),
      );
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(table: table, onBack: () => safePop(context)),
              _Header(
                table: table,
                zoneName: zone.name,
                total: total,
                canEditGuests: canEditGuests,
                onMinusPax: onMinus,
                onPlusPax: onPlus,
              ),
              if (readyAny) const ReadyBanner(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, l.bottomInset + 80),
                  children: [
                    for (final cid in Courses.stationOrder.map((c) => c.id))
                      if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                        _CourseBlock(
                          course: Courses.byId(cid),
                          items: grouped[cid]!,
                          onMarkServed: (id) {
                            ref.read(ticketsProvider.notifier).markServed(tableId, id);
                            ref
                                .read(tablesProvider.notifier)
                                .decrementReady(tableId, userId: actorId);
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
                ),
              ),
            ],
          ),
          Positioned(
            left: 16 + l.padding.left,
            right: 16 + l.padding.right,
            bottom: l.useSideRail ? 16 + l.padding.bottom : 92 + l.padding.bottom,
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
    final l = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, 10),
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
  final bool canEditGuests;
  final VoidCallback onMinusPax;
  final VoidCallback onPlusPax;
  const _Header({
    required this.table,
    required this.zoneName,
    required this.total,
    required this.canEditGuests,
    required this.onMinusPax,
    required this.onPlusPax,
  });

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
                Text(zoneName,
                    style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.textMd)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GuestStepper(
                      pax: table.pax,
                      enabled: canEditGuests,
                      onMinus: onMinusPax,
                      onPlus: onPlusPax,
                      size: 32,
                    ),
                  ],
                ),
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
    final isCooked = ticket.status == TicketStatus.cooked;
    final isVoided = ticket.status == TicketStatus.voided;
    final bg = isReady
        ? sc.successSoft
        : (isCooked ? sc.accentSoft : (isVoided ? sc.bg1 : sc.bg2));
    final border = isReady
        ? sc.success.withValues(alpha: 0.3)
        : (isCooked ? sc.accent.withValues(alpha: 0.3) : sc.border0);

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

class _TabletSplit extends StatelessWidget {
  final VenueTable table;
  final Zone zone;
  final List<Ticket> tickets;
  final Map<CourseId, List<Ticket>> grouped;
  final int total;
  final bool readyAny;
  final bool canEditGuests;
  final VoidCallback onMinusPax;
  final VoidCallback onPlusPax;
  final void Function(String) onMarkServed;
  final void Function(CourseId) onFireCourse;
  final void Function(Ticket) onTicketTap;
  final VoidCallback onAdd;
  final VoidCallback onBack;

  const _TabletSplit({
    required this.table,
    required this.zone,
    required this.tickets,
    required this.grouped,
    required this.total,
    required this.readyAny,
    required this.canEditGuests,
    required this.onMinusPax,
    required this.onPlusPax,
    required this.onMarkServed,
    required this.onFireCourse,
    required this.onTicketTap,
    required this.onAdd,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final readyN = tickets.where((t) => t.status == TicketStatus.ready).length;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 560,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: sc.border0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: onBack,
                            child: Container(
                              width: 38, height: 38,
                              margin: const EdgeInsets.only(right: 14, bottom: 6),
                              decoration: BoxDecoration(
                                color: sc.bg2,
                                border: Border.all(color: sc.border0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.arrow_back, size: 18, color: sc.textMd),
                            ),
                          ),
                          Text(table.id,
                              style: SatType.mono(
                                size: 56,
                                weight: FontWeight.w500,
                                letterSpacing: -1.68,
                                height: 1,
                                color: sc.textHi,
                              )),
                          const SizedBox(width: 14),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(zone.name,
                                    style: SatType.sans(size: 15, color: sc.textMd)),
                                const SizedBox(height: 6),
                                GuestStepper(
                                  pax: table.pax,
                                  enabled: canEditGuests,
                                  onMinus: onMinusPax,
                                  onPlus: onPlusPax,
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(context, sc, '⏱ duduk ${table.elapsed ?? '0:00'}'),
                          _pill(context, sc, formatIDR(total)),
                          if (readyN > 0) _pill(context, sc, '$readyN siap diambil', tone: 'success'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tickets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'Belum ada item — ketuk Tambah pesanan di kanan untuk mulai.',
                              textAlign: TextAlign.center,
                              style: SatType.sans(size: 14, color: sc.textLo, height: 1.5),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                          children: [
                            for (final cid in Courses.stationOrder.map((c) => c.id))
                              if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                                _CourseBlock(
                                  course: Courses.byId(cid),
                                  items: grouped[cid]!,
                                  onMarkServed: onMarkServed,
                                  onFireCourse: () => onFireCourse(cid),
                                  onTicketTap: onTicketTap,
                                ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: sc.border0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: sc.accent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onAdd,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 18, color: sc.accentInk),
                                  const SizedBox(width: 8),
                                  Text(
                                    tickets.isEmpty ? 'Buat pesanan' : 'Tambah pesanan',
                                    style: SatType.sans(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: sc.accentInk,
                                    ),
                                  ),
                                ],
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
          ),
          Container(width: 1, color: sc.border0),
          Expanded(
            child: _ContextPane(table: table, tickets: tickets),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, SatColors sc, String text, {String tone = 'normal'}) {
    Color bg = sc.bg3;
    Color fg = sc.textMd;
    Color border = sc.border1;
    if (tone == 'success') { bg = sc.successSoft; fg = sc.success; border = sc.success.withValues(alpha: 0.3); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: SatType.sans(
            size: 11,
            weight: FontWeight.w500,
            letterSpacing: 0.2,
            color: fg,
          )),
    );
  }
}

class _ContextPane extends StatelessWidget {
  final VenueTable table;
  final List<Ticket> tickets;
  const _ContextPane({required this.table, required this.tickets});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final sent = tickets.where((t) => t.status != TicketStatus.voided && t.status != TicketStatus.served).length;
    final served = tickets.where((t) => t.status == TicketStatus.served).length;
    final allergens = <String>{};
    for (final t in tickets) {
      final it = DummyData.items.where((i) => i.id == t.itemId).firstOrNull;
      if (it != null) allergens.addAll(it.allergens.map((a) => a.name));
    }
    final peanut = tickets.any((t) =>
        t.specialInstructions != null && t.specialInstructions!.toLowerCase().contains('kacang'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konteks meja',
                  style: SatType.sans(
                    size: 22,
                    weight: FontWeight.w600,
                    letterSpacing: -0.44,
                    color: sc.textHi,
                  )),
              const SizedBox(height: 4),
              Text('DUDUK ${table.elapsed ?? '0:00'} · ${table.pax} TAMU',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textLo,
                    letterSpacing: 0.44,
                  )),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _stat(context, sc, tickets.length.toString(), 'Total item')),
                    const SizedBox(width: 8),
                    Expanded(child: _stat(context, sc, sent.toString(), 'Dalam proses')),
                    const SizedBox(width: 8),
                    Expanded(child: _stat(context, sc, served.toString(), 'Disajikan')),
                  ],
                ),
                const SizedBox(height: 16),
                _card(context, sc, 'CATATAN TAMU',
                    peanut
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sc.urgentSoft,
                              border: Border.all(color: sc.urgent.withValues(alpha: 0.25)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: sc.urgent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('Tamu alergi kacang — hindari saus kacang & garnish sate.',
                                      style: SatType.sans(size: 13, weight: FontWeight.w500, color: sc.urgent)),
                                ),
                              ],
                            ),
                          )
                        : Text('Belum ada catatan khusus.',
                            style: SatType.sans(size: 13, color: sc.textLo))),
                const SizedBox(height: 14),
                _card(context, sc, 'ALERGEN DI PESANAN',
                    allergens.isEmpty
                        ? Text('Tidak ada.', style: SatType.sans(size: 13, color: sc.textLo))
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final a in allergens)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sc.urgentSoft,
                                    border: Border.all(color: sc.urgent.withValues(alpha: 0.35)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(a,
                                      style: SatType.sans(
                                        size: 12,
                                        weight: FontWeight.w500,
                                        color: sc.urgent,
                                      )),
                                ),
                            ],
                          )),
                const SizedBox(height: 14),
                _card(context, sc, 'AKSI CEPAT',
                    Column(
                      children: [
                        _quickAction(context, sc, Icons.receipt_long_rounded, 'Cetak struk meja', accent: true),
                        const SizedBox(height: 6),
                        _quickAction(context, sc, Icons.edit_outlined, 'Pindahkan meja'),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, SatColors sc, String v, String l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: SatType.mono(size: 22, weight: FontWeight.w600, letterSpacing: -0.44, height: 1, color: sc.textHi)),
          const SizedBox(height: 8),
          Text(l.toUpperCase(),
              style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.6)),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SatColors sc, String head, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(head,
              style: SatType.mono(size: 10, weight: FontWeight.w600, letterSpacing: 1.2, color: sc.textLo)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, SatColors sc, IconData icon, String label, {bool accent = false}) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: accent ? sc.accentSoft : sc.bg3,
        border: Border.all(
          color: accent ? sc.accentBorder : sc.border1,
          style: accent ? BorderStyle.solid : BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: accent ? sc.accent : sc.textMd),
          const SizedBox(width: 8),
          Text(label.toUpperCase(),
              style: SatType.sans(
                size: 12,
                weight: FontWeight.w600,
                letterSpacing: 0.48,
                color: accent ? sc.accent : sc.textMd,
              )),
        ],
      ),
    );
  }
}
