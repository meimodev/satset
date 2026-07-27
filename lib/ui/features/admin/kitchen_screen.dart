import 'dart:async';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_view_model.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';

/// One kitchen order card: the kitchen-station tickets a table sent together.
class _KOrder {
  final String tableId;
  final String sentAt;
  // Full-precision fire time of the earliest ticket in the group — drives the
  // live age counter. `sentAt` (HH:mm) stays the grouping key. See ADR-0008.
  final DateTime sentAtTime;
  final List<Ticket> tickets;
  const _KOrder(this.tableId, this.sentAt, this.sentAtTime, this.tickets);

  int get total => tickets.length;
  int get done => tickets.where((t) => _isDone(t.status)).length;
}

// `ready` stays in the active set so a just-cooked item (now servable)
// remains struck-through on the card instead of vanishing one-by-one. A
// fully-ready order still clears the default view via the `done == total`
// guard in `_buildOrders`.
const _kitchenInProgress = {
  TicketStatus.sent,
  TicketStatus.prep,
  TicketStatus.cooked,
  TicketStatus.ready,
};

// Served items only show under the "show completed" filter — once handed to
// the table they're done with the kitchen.
const _kitchenCompleted = {TicketStatus.ready, TicketStatus.served};

List<_KOrder> _buildOrders(
  Map<String, List<Ticket>> byTable, {
  required bool showCompleted,
}) {
  final visible = showCompleted
      ? {..._kitchenInProgress, ..._kitchenCompleted}
      : _kitchenInProgress;
  final out = <_KOrder>[];
  byTable.forEach((tableId, list) {
    final groups = <String, List<Ticket>>{};
    for (final t in list) {
      if (!visible.contains(t.status)) continue;
      groups.putIfAbsent(t.sentAt, () => []).add(t);
    }
    groups.forEach((sentAt, tickets) {
      // Unfinished items rise to the top so the cook always sees what's left.
      tickets.sort((a, b) {
        final ac = _isDone(a.status) ? 1 : 0;
        final bc = _isDone(b.status) ? 1 : 0;
        return ac.compareTo(bc);
      });
      final earliest = tickets
          .map((t) => t.sentAtTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      // `byTable` is keyed by visitId (ADR-0034); use the ticket's real
      // tableId so the card resolves a table name, not the raw visit id.
      // Falls back to the key for takeaway (no table).
      final resolvedId = tickets.first.tableId.isNotEmpty
          ? tickets.first.tableId
          : tableId;
      final order = _KOrder(resolvedId, sentAt, earliest, tickets);
      if (!showCompleted && order.done == order.total) return;
      out.add(order);
    });
  });
  // Oldest fire first — most urgent at the top of the queue.
  out.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  return out;
}

bool _isDone(TicketStatus s) =>
    s == TicketStatus.cooked ||
    s == TicketStatus.ready ||
    s == TicketStatus.served;

Duration _age(DateTime sentAtTime) {
  final d = DateTime.now().difference(sentAtTime);
  return d.isNegative ? Duration.zero : d;
}

Color _ageColor(SatColors sc, int min) =>
    min >= 10 ? sc.urgent : (min >= 5 ? sc.warn : sc.success);

// Refined deceleration — no bounce/elastic (kitchen-floor tone is calm).
const _kEaseOutQuart = Cubic(0.25, 1, 0.5, 1);

/// Fade + slide a card in once when it first appears. Keyed by order identity
/// so re-sorting or ticket updates reuse the State and don't replay the entry.
class _CardEntrance extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _CardEntrance({super.key, required this.child, required this.animate});

  @override
  State<_CardEntrance> createState() => _CardEntranceState();
}

class _CardEntranceState extends State<_CardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _kEaseOutQuart.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  bool _showCompleted = false;
  // Drives the live age counters (and their color/pulse thresholds) so cards
  // tick between ticket events, matching the other elapsed counters.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final orders = _buildOrders(
      ref.watch(ticketsProvider),
      showCompleted: _showCompleted,
    );
    final itemCount = orders.fold<int>(0, (n, o) => n + o.total);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // All status changes round-trip through the server via the KDS
    // view model + AdvanceTicketStatusUseCase so other clients see them.
    void toggle(String tableId, String ticketId) {
      ref
          .read(kitchenViewModelProvider.notifier)
          .toggleCooked(tableId, ticketId);
    }

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
              child: Text(
                'Antrian Persiapan',
                style: SatType.sans(
                  size: 26,
                  weight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: sc.textHi,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${orders.length} ORDER · $itemCount ITEM DI ANTRIAN PERSIAPAN',
                style: SatType.mono(
                  size: 11,
                  color: sc.textLo,
                  letterSpacing: 0.66,
                ),
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
                      separatorBuilder: (_, _) => const SizedBox(height: Sp.s3),
                      itemBuilder: (_, i) => _CardEntrance(
                        key: ValueKey(
                          '${orders[i].tableId}|${orders[i].sentAt}',
                        ),
                        animate: !reduceMotion,
                        child: _OrderCard(order: orders[i], onToggle: toggle),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return AdminPage(
      title: 'Antrian Persiapan',
      sub:
          '${orders.length} order aktif · $itemCount item · tahan untuk tandai selesai',
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
                  child: _CardEntrance(
                    key: ValueKey('${o.tableId}|${o.sentAt}'),
                    animate: !reduceMotion,
                    child: _OrderCard(order: o, onToggle: toggle),
                  ),
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
        borderRadius: SatR.a(999),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: satMotion(context, 160),
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3,
            vertical: Sp.s2,
          ),
          decoration: SatBox.d(
            color: value ? sc.success.withValues(alpha: 0.14) : sc.bg2,
            border: SatB.all(
              color: value ? sc.success.withValues(alpha: 0.5) : sc.border0,
            ),
            borderRadius: SatR.a(999),
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
              const SizedBox(width: Sp.s2),
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

class _OrderCard extends ConsumerWidget {
  final _KOrder order;
  final void Function(String tableId, String ticketId) onToggle;
  const _OrderCard({required this.order, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final ageDur = _age(order.sentAtTime);
    final age = ageDur.inMinutes;
    final ageColor = _ageColor(sc, age);
    final progress = order.total == 0 ? 0.0 : order.done / order.total;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final tables = ref.watch(tablesProvider);
    final table = tables.where((t) => t.id == order.tableId).firstOrNull;
    // Resolve a table-less (takeaway) order's label via the visit instead of
    // showing the raw visit id. See ADR-0026.
    final tableLabel =
        table?.displayName ??
        ref
            .watch(takeawayVisitsProvider)
            .where((v) => v.id == order.tableId)
            .map((v) => v.label)
            .firstOrNull ??
        order.tableId;

    return AnimatedContainer(
      duration: satMotion(context, 300),
      curve: satEaseOut,
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(
          color: age >= 10 ? ageColor.withValues(alpha: 0.5) : sc.border0,
          width: age >= 10 ? 1.5 : 1,
        ),
        borderRadius: SatR.a(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: Sp.s1h,
                  ),
                  decoration: SatBox.d(color: sc.bg3, borderRadius: SatR.a(9)),
                  child: Text(
                    tableLabel,
                    style: SatType.mono(
                      size: 15,
                      weight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: sc.textHi,
                    ),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Text(
                  '${order.done}/${order.total} selesai',
                  style: SatType.sans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: sc.textMd,
                  ),
                ),
                const Spacer(),
                _AgePill(age: ageDur, sentAt: order.sentAt, color: ageColor),
              ],
            ),
          ),
          ClipRRect(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: _kEaseOutQuart,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 3,
                backgroundColor: sc.bg3,
                valueColor: AlwaysStoppedAnimation(sc.success),
              ),
            ),
          ),
          AnimatedSize(
            duration: satMotion(context, 200),
            curve: satEaseOut,
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
  final Duration age;
  final String sentAt;
  final Color color;
  const _AgePill({
    required this.age,
    required this.sentAt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: SatBox.d(
        color: color.withValues(alpha: 0.14),
        borderRadius: SatR.a(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, pulse: age.inMinutes >= 10),
          const SizedBox(width: Sp.s1h),
          Text(
            formatElapsedId(age),
            style: SatType.mono(
              size: 12,
              weight: FontWeight.w700,
              letterSpacing: 0,
              color: color,
            ),
          ),
          const SizedBox(width: Sp.s1h),
          Text(
            sentAt,
            style: SatType.mono(size: 10, color: sc.textLo, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

/// Status dot that gently pulses while an order is overdue (≥10m), drawing the
/// cook's eye to the most urgent ticket. Static (no repaint) otherwise.
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, required this.pulse});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse != old.pulse) _sync();
  }

  void _sync() {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (widget.pulse && !reduce) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: SatBox.d(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulse) return dot;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(scale: 1 + t * 0.45, child: child);
      },
      child: dot,
    );
  }
}

class _ItemRow extends StatefulWidget {
  final Ticket ticket;
  final bool last;
  final VoidCallback onTap;
  const _ItemRow({
    required this.ticket,
    required this.last,
    required this.onTap,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow>
    with SingleTickerProviderStateMixin {
  // A brief green wash when an item is marked done — acknowledges the tap and
  // softens the row's jump to the bottom of the card (done items sink).
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _ItemRow old) {
    super.didUpdateWidget(old);
    final cooked = _isDone(widget.ticket.status);
    final wasCooked = _isDone(old.ticket.status);
    if (cooked && !wasCooked && !MediaQuery.of(context).disableAnimations) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  // Tap is a no-commit gesture now: it only nudges the cook toward the
  // long-press that actually marks the item done, so an accidental brush
  // can't advance a ticket. See ADR / kitchen long-press decision.
  void _hint() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tahan untuk tandai selesai'),
          duration: Duration(milliseconds: 1500),
        ),
      );
  }

  void _commit() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ticket = widget.ticket;
    final cooked = _isDone(ticket.status);
    final base = cooked ? sc.successSoft : Colors.transparent;

    return AnimatedBuilder(
      animation: _flash,
      builder: (_, child) {
        final t = 1 - satEaseOut.transform(_flash.value);
        return Material(
          color: Color.alphaBlend(sc.success.withValues(alpha: 0.35 * t), base),
          child: child,
        );
      },
      child: InkWell(
        onTap: cooked ? null : _hint,
        onLongPress: cooked ? null : _commit,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: SatBox.d(
            border: Border(top: SatB.side(color: sc.border0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: SatBox.d(color: sc.bg3, borderRadius: SatR.a(6)),
                child: Text(
                  '×${ticket.qty}',
                  style: SatType.mono(
                    size: 13,
                    weight: FontWeight.w700,
                    letterSpacing: 0,
                    color: cooked ? sc.textLo : sc.textHi,
                  ),
                ),
              ),
              const SizedBox(width: Sp.s3),
              Expanded(
                child: AnimatedOpacity(
                  duration: satMotion(context, 160),
                  opacity: cooked ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.name +
                            (ticket.variantName.isEmpty
                                ? ''
                                : ' · ${ticket.variantName}'),
                        style:
                            SatType.sans(
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
                          child: Text(
                            ticket.modifiers.map((m) => m.display).join(' · '),
                            style: SatType.sans(
                              size: 13,
                              color: sc.textMd,
                              height: 1.4,
                            ),
                          ),
                        ),
                      if (ticket.note != null && ticket.note!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: NoteLine(
                            label: 'Instruksi khusus',
                            text: ticket.note!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Sp.s3),
              _CheckButton(cooked: cooked),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatefulWidget {
  final bool cooked;
  const _CheckButton({required this.cooked});

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  // A confident pop (no elastic overshoot) when the cook marks an item done.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: satEaseOut)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: satEaseOut)),
      weight: 55,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(covariant _CheckButton old) {
    super.didUpdateWidget(old);
    if (widget.cooked &&
        !old.cooked &&
        !MediaQuery.of(context).disableAnimations) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: satMotion(context, 180),
        curve: satEaseOut,
        width: 34,
        height: 34,
        decoration: SatBox.d(
          color: widget.cooked ? sc.success : Colors.transparent,
          shape: BoxShape.circle,
          border: SatB.all(
            color: widget.cooked ? sc.success : sc.border2,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 20,
          color: widget.cooked ? sc.accentInk : sc.textDim,
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatefulWidget {
  const _EmptyQueue();

  @override
  State<_EmptyQueue> createState() => _EmptyQueueState();
}

class _EmptyQueueState extends State<_EmptyQueue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_c.value);
              return Transform.translate(
                offset: Offset(0, -3 * t),
                child: child,
              );
            },
            child: Icon(Icons.restaurant_rounded, size: 40, color: sc.textDim),
          ),
          const SizedBox(height: Sp.s3h),
          Text(
            'Antrian masak kosong',
            style: SatType.sans(
              size: 16,
              weight: FontWeight.w600,
              color: sc.textMd,
            ),
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            'Semua pesanan dapur sudah selesai dimasak.',
            style: SatType.sans(size: 13, color: sc.textLo),
          ),
        ],
      ),
    );
  }
}
