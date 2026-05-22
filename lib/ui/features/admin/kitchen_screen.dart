import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import '_common.dart';

/// One kitchen order card: the kitchen-station tickets a table sent together.
class _KOrder {
  final String tableId;
  final String sentAt;
  final List<Ticket> tickets;
  const _KOrder(this.tableId, this.sentAt, this.tickets);

  int get total => tickets.length;
  int get done => tickets.where((t) => t.status == TicketStatus.cooked).length;
}

const _kitchenActive = {
  TicketStatus.sent,
  TicketStatus.prep,
  TicketStatus.cooked,
};

List<_KOrder> _buildOrders(
  Map<String, List<Ticket>> byTable, {
  required bool showCompleted,
}) {
  final out = <_KOrder>[];
  byTable.forEach((tableId, list) {
    final groups = <String, List<Ticket>>{};
    for (final t in list) {
      if (t.station != Station.kitchen) continue;
      if (!_kitchenActive.contains(t.status)) continue;
      groups.putIfAbsent(t.sentAt, () => []).add(t);
    }
    groups.forEach((sentAt, tickets) {
      // Unfinished items rise to the top so the cook always sees what's left.
      tickets.sort((a, b) {
        final ac = a.status == TicketStatus.cooked ? 1 : 0;
        final bc = b.status == TicketStatus.cooked ? 1 : 0;
        return ac.compareTo(bc);
      });
      final order = _KOrder(tableId, sentAt, tickets);
      if (!showCompleted && order.done == order.total) return;
      out.add(order);
    });
  });
  // Oldest fire first — most urgent at the top of the queue.
  out.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  return out;
}

int _ageMinutes(String hhmm) {
  final p = hhmm.split(':');
  if (p.length != 2) return 0;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return 0;
  final now = DateTime.now();
  final diff = now.difference(DateTime(now.year, now.month, now.day, h, m));
  return diff.inMinutes < 0 ? 0 : diff.inMinutes;
}

Color _ageColor(SatColors sc, int min) =>
    min >= 10 ? sc.urgent : (min >= 5 ? sc.warn : sc.success);

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final orders = _buildOrders(
      ref.watch(ticketsProvider),
      showCompleted: _showCompleted,
    );
    final itemCount = orders.fold<int>(0, (n, o) => n + o.total);

    void toggle(String tableId, String ticketId) =>
        ref.read(ticketsProvider.notifier).toggleCooked(tableId, ticketId);

    final filter = _CompletedFilter(
      value: _showCompleted,
      onChanged: (v) => setState(() => _showCompleted = v),
    );

    if (!context.layout.useTabletShell) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text('Dapur',
                  style: SatType.sans(
                    size: 26,
                    weight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: sc.textHi,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${orders.length} ORDER · $itemCount ITEM DI ANTRIAN MASAK',
                style: SatType.mono(
                    size: 11, color: sc.textLo, letterSpacing: 0.66),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: filter,
            ),
            Expanded(
              child: orders.isEmpty
                  ? const _EmptyQueue()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _OrderCard(order: orders[i], onToggle: toggle),
                    ),
            ),
          ],
        ),
      );
    }

    return AdminPage(
      title: 'Dapur · Antrian Masak',
      sub: '${orders.length} order aktif · $itemCount item · tap untuk tandai selesai',
      topTrailing: filter,
      children: [
        if (orders.isEmpty)
          const SizedBox(height: 360, child: _EmptyQueue())
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final o in orders)
                SizedBox(
                  width: 360,
                  child: _OrderCard(order: o, onToggle: toggle),
                ),
            ],
          ),
      ],
    );
  }
}

class _CompletedFilter extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CompletedFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: value ? sc.success.withValues(alpha: 0.14) : sc.bg2,
            border: Border.all(
              color: value ? sc.success.withValues(alpha: 0.5) : sc.border0,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: value ? sc.success : sc.textMd,
              ),
              const SizedBox(width: 8),
              Text(
                'Tampilkan order selesai',
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: value ? sc.textHi : sc.textMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _KOrder order;
  final void Function(String tableId, String ticketId) onToggle;
  const _OrderCard({required this.order, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final age = _ageMinutes(order.sentAt);
    final ageColor = _ageColor(sc, age);
    final progress = order.total == 0 ? 0.0 : order.done / order.total;

    return Container(
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(
          color: age >= 10 ? ageColor.withValues(alpha: 0.5) : sc.border0,
          width: age >= 10 ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: sc.bg3,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(order.tableId,
                      style: SatType.mono(
                        size: 15,
                        weight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: sc.textHi,
                      )),
                ),
                const SizedBox(width: 10),
                Text('${order.done}/${order.total} selesai',
                    style: SatType.sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: sc.textMd,
                    )),
                const Spacer(),
                _AgePill(age: age, sentAt: order.sentAt, color: ageColor),
              ],
            ),
          ),
          ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: sc.bg3,
              valueColor: AlwaysStoppedAnimation(sc.success),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < order.tickets.length; i++)
                  _ItemRow(
                    ticket: order.tickets[i],
                    last: i == order.tickets.length - 1,
                    onTap: () => onToggle(order.tableId, order.tickets[i].id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgePill extends StatelessWidget {
  final int age;
  final String sentAt;
  final Color color;
  const _AgePill(
      {required this.age, required this.sentAt, required this.color});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('${age}m',
              style: SatType.mono(
                size: 12,
                weight: FontWeight.w700,
                letterSpacing: 0,
                color: color,
              )),
          const SizedBox(width: 6),
          Text(sentAt,
              style: SatType.mono(
                size: 10,
                color: sc.textLo,
                letterSpacing: 0.4,
              )),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Ticket ticket;
  final bool last;
  final VoidCallback onTap;
  const _ItemRow(
      {required this.ticket, required this.last, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final cooked = ticket.status == TicketStatus.cooked;

    return Material(
      color: cooked ? sc.successSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: sc.border0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.bg3,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('×${ticket.qty}',
                    style: SatType.mono(
                      size: 13,
                      weight: FontWeight.w700,
                      letterSpacing: 0,
                      color: cooked ? sc.textLo : sc.textHi,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: cooked ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.name +
                            (ticket.variantName.isEmpty
                                ? ''
                                : ' · ${ticket.variantName}'),
                        style: SatType.sans(
                          size: 16,
                          weight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.25,
                          color: sc.textHi,
                        ).copyWith(
                          decoration: cooked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (ticket.modifiers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(ticket.modifiers.join(' · '),
                              style: SatType.sans(
                                size: 13,
                                color: sc.textMd,
                                height: 1.4,
                              )),
                        ),
                      if (ticket.specialInstructions != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('⚠ ${ticket.specialInstructions!}',
                              style: SatType.sans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: sc.urgent,
                                height: 1.35,
                              )),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _CheckButton(cooked: cooked),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool cooked;
  const _CheckButton({required this.cooked});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: cooked ? sc.success : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: cooked ? sc.success : sc.border2,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check_rounded,
        size: 20,
        color: cooked ? sc.accentInk : sc.textDim,
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_rounded, size: 40, color: sc.textDim),
          const SizedBox(height: 14),
          Text('Antrian masak kosong',
              style: SatType.sans(
                size: 16,
                weight: FontWeight.w600,
                color: sc.textMd,
              )),
          const SizedBox(height: 6),
          Text('Semua pesanan dapur sudah selesai dimasak.',
              style: SatType.sans(size: 13, color: sc.textLo)),
        ],
      ),
    );
  }
}
