import 'dart:async';
import 'package:satset/ui/core/widgets/pulse_dot.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
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

  /// The distinct courses in this group, in station order. Usually one — the
  /// source's ticket *is* a course — but the app groups by send, and a waiter
  /// who fires drinks and mains together makes one card carry both. Naming them
  /// is information the cook does not get today.
  List<Course> get courses {
    final seen = tickets.map((t) => t.course).toSet();
    return [
      for (final c in Courses.all)
        if (seen.contains(c.id)) c,
    ];
  }
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
  // Oldest fire first — most urgent at the top of the queue. Sorted on the
  // full timestamp, not the HH:mm grouping key: a service running past midnight
  // would otherwise sort 00:15 ahead of 23:50 and bury the oldest ticket.
  out.sort((a, b) => a.sentAtTime.compareTo(b.sentAtTime));
  return out;
}

bool _isDone(TicketStatus s) =>
    s == TicketStatus.cooked ||
    s == TicketStatus.ready ||
    s == TicketStatus.served;

Duration _age(DateTime sentAtTime) {
  final d = SatClock.now().difference(sentAtTime);
  return d.isNegative ? Duration.zero : d;
}

/// When a ticket counts as late. One constant so the header's TELAT tally, the
/// card border, the age pill's colour and its pulse cannot drift apart and tell
/// the line two different stories.
const int kKitchenLateMins = 10;

/// The tier below late. The source derives it as `0.7 ×` the late threshold —
/// far enough out that a cook can still save the ticket, close enough that the
/// warning means something.
const int _kKitchenWarnMins = 7;

/// The timer's ink. Neutral until the ticket is worth worrying about: a ticket
/// two minutes old is not news, and spending a colour on the good case is how
/// `urgent` stops being read. Glow paints the calm case lime instead, because
/// the head it sits in is an obsidian slab and `textMd` there is a mutter.
Color _ageColor(SatColors sc, int min) {
  if (min >= kKitchenLateMins) return sc.urgent;
  if (min >= _kKitchenWarnMins) return sc.warn;
  return SatShape.glow ? sc.accent : sc.textMd;
}

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
    // Each card already turns urgent on its own, but a cook working the top of
    // a scrolled queue cannot see how many are red below the fold. The tally is
    // the one number that says whether the line is behind.
    final lateCount = orders
        .where((o) => _age(o.sentAtTime).inMinutes >= kKitchenLateMins)
        .length;
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
    final headTrailing = lateCount == 0
        ? filter
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LateTally(count: lateCount),
              const SizedBox(width: Sp.s2),
              filter,
            ],
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
                style: SatType.h2(color: sc.textHi),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${orders.length} ORDER · $itemCount ITEM DI ANTRIAN PERSIAPAN',
                style: SatType.monoS(color: sc.textLo),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: headTrailing,
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
      topTrailing: headTrailing,
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
                style: SatType.labelM(color: value ? sc.textHi : sc.textMd),
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
    final late = age >= kKitchenLateMins;
    final warn = !late && age >= _kKitchenWarnMins;
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

    final ring = SatShape.glow ? (late ? 3.0 : (warn ? 2.0 : 0.0)) : 0.0;

    final card = AnimatedContainer(
      duration: satMotion(context, 300),
      curve: satEaseOut,
      decoration: SatBox.d(
        // Late tints the whole card, not just its edge — a ticket that has
        // blown its window has to be findable in peripheral vision from the
        // other end of the line. Flattened onto `bg2` rather than laid over it:
        // the soft tokens are ~11% alpha and a `BoxShadow` paints *behind* the
        // box, so the solid ring below would otherwise read straight through
        // the fill and flood the whole card.
        color: late ? Color.alphaBlend(sc.urgentSoft, sc.bg2) : sc.bg2,
        border: SatB.all(
          color: late
              ? sc.urgent.withValues(alpha: 0.5)
              : (warn ? sc.warn.withValues(alpha: 0.5) : sc.border0),
          width: late ? 1.5 : 1,
        ),
        borderRadius: SatR.card,
        // The lift lives on the ring wrapper when there is one, so the band
        // does not get shadowed by the card sitting inside it.
        boxShadow: SatShape.glow && ring == 0 ? SatShape.lift : null,
      ),
      // The head is a full-bleed slab and the foot a full-bleed rule; neither
      // knows the card's corner radius, so both painted square over the top
      // and bottom of the rounded border until this clip.
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHead(
            table: tableLabel,
            courses: order.courses,
            age: ageDur,
            sentAt: order.sentAt,
            late: late,
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
                  _KdsItemRow(
                    ticket: order.tickets[i],
                    last: i == order.tickets.length - 1,
                    onTap: () => onToggle(order.tableId, order.tickets[i].id),
                  ),
              ],
            ),
          ),
          // The bar above says how far along at a glance from across the room;
          // this says it in words for the cook standing at the card. The source
          // has only the words, at 11px — unreadable at the distance this
          // screen is actually mounted.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: SatBox.d(
              border: Border(top: SatB.side(color: sc.border0)),
            ),
            child: Text(
              order.done == order.total
                  ? 'Semua siap'
                  : '${order.done} / ${order.total} siap',
              style: SatType.labelM(color: sc.textMd),
            ),
          ),
        ],
      ),
    );

    if (ring == 0) return card;

    // The tier band, drawn as a padded box behind the card rather than a
    // `BoxShadow` with `spreadRadius`. A spread shadow inflates the rect but
    // keeps the decoration's radius, so the band's outer corner stayed at 26
    // while its outer edge moved 3px out — the card's own corner then cut
    // across it and the ring looked pinched at all four corners. An outer box
    // one ring-width larger in both padding and radius is concentric by
    // construction. Hard-edged on purpose: a blurred red glow would read as a
    // light source, not a state.
    return Container(
      padding: EdgeInsets.all(ring),
      decoration: SatBox.d(
        color: late ? sc.urgent : sc.warn,
        borderRadius: BorderRadius.circular(SatR.card.topLeft.x + ring),
        boxShadow: late ? SatShape.liftLg : SatShape.lift,
      ),
      child: card,
    );
  }
}

/// The ticket head. Under Glow this is a full-bleed obsidian slab and every
/// hue inside it is re-read from `sc.slab` — the light palette's `urgent` and
/// `warn` are tuned as ink on bone and go muddy on obsidian (ADR-0051). The
/// other skins get the base design's darker band off the neutral ramp.
class _CardHead extends StatelessWidget {
  final String table;
  final List<Course> courses;
  final Duration age;
  final String sentAt;
  final bool late;
  const _CardHead({
    required this.table,
    required this.courses,
    required this.age,
    required this.sentAt,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    final page = context.sat;
    final sc = SatShape.glow ? page.slab : page;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: SatBox.d(
        color: SatShape.glow ? sc.bg0 : page.bg3,
        border: SatShape.glow
            ? null
            : Border(bottom: SatB.side(color: page.border0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: Sp.s2,
              runSpacing: Sp.s1h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(table, style: SatType.h3(color: sc.textHi)),
                // Flat accent, never the per-course hue: the course colours are
                // tuned as ink on the page and five of them stacked on obsidian
                // is a paint chart, not a signal.
                for (final c in courses)
                  SatChip.tag(
                    label: c.name,
                    size: SatChipSize.sm,
                    hue: SatChipHue.accent,
                    filled: true,
                  ),
                if (late)
                  SatChip.tag(
                    label: 'Telat',
                    size: SatChipSize.sm,
                    hue: SatChipHue.urgent,
                    filled: true,
                  ),
              ],
            ),
          ),
          const SizedBox(width: Sp.s2),
          _Timer(age: age, sentAt: sentAt, sc: sc),
        ],
      ),
    );
  }
}

/// Elapsed over arrival, right-aligned. Bare numerals rather than a pill: the
/// slab already separates the head, and a tinted capsule inside a tinted slab
/// is two containers saying one thing.
class _Timer extends StatefulWidget {
  final Duration age;
  final String sentAt;
  final SatColors sc;
  const _Timer({required this.age, required this.sentAt, required this.sc});

  @override
  State<_Timer> createState() => _TimerState();
}

class _TimerState extends State<_Timer> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _late => widget.age.inMinutes >= kKitchenLateMins;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Timer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Reduced motion collapses to the final state — full opacity, still red.
  // The colour is the signal; the pulse only makes it findable.
  void _sync() {
    final on = _late && !MediaQuery.of(context).disableAnimations;
    if (on && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!on && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = widget.sc;
    final color = _ageColor(sc, widget.age.inMinutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) =>
              Opacity(opacity: 1 - 0.4 * _pulse.value, child: child),
          child: Text(
            formatStationTimer(widget.age),
            style: SatType.monoL(color: color),
          ),
        ),
        Text('masuk ${widget.sentAt}', style: SatType.monoS(color: sc.textMd)),
      ],
    );
  }
}

/// Status dot that gently pulses while an order is overdue (≥10m), drawing the
/// cook's eye to the most urgent ticket. Static (no repaint) otherwise.
class _KdsItemRow extends StatefulWidget {
  final Ticket ticket;
  final bool last;
  final VoidCallback onTap;
  const _KdsItemRow({
    required this.ticket,
    required this.last,
    required this.onTap,
  });

  @override
  State<_KdsItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_KdsItemRow>
    with SingleTickerProviderStateMixin {
  // A brief green wash when an item is marked done — acknowledges the tap and
  // softens the row's jump to the bottom of the card (done items sink). Rests
  // at 1, not 0: the wash is `1 - value`, so a controller left at its default
  // lower bound paints every untouched row green and never stops.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _KdsItemRow old) {
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
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          decoration: SatBox.d(
            border: Border(top: SatB.side(color: sc.border0)),
          ),
          // Stack, not IntrinsicHeight: the bar has to run whatever height the
          // row turned out to be, and an intrinsic pass would ask the modifier
          // Wrap below for a height it answers badly.
          child: Stack(
            children: [
              // The bar is the row's state at the coarsest possible resolution
              // — accent while it is work, `success` once it is not — readable
              // from further away than the tick, the strike or the text. It
              // spans the full content box, so a dish that wraps onto three
              // lines of options and notes still reads as one item rather than
              // as an item followed by loose text.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: SatBox.d(
                    color: cooked ? sc.success : sc.accent,
                    borderRadius: SatR.a(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gutter the bar sits in. The row's own minHeight floors the
                  // content box at 40, so the bar keeps its old short-row
                  // length without asking for it.
                  const SizedBox(width: 3 + Sp.s3),
                  _Tick(cooked: cooked),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          duration: satMotion(context, 160),
                          opacity: cooked ? 0.55 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '×${ticket.qty}  ',
                                      style: SatType.monoM(color: sc.textMd),
                                    ),
                                    TextSpan(
                                      text:
                                          ticket.name +
                                          (ticket.variantName.isEmpty
                                              ? ''
                                              : ' · ${ticket.variantName}'),
                                      style: SatType.labelL(color: sc.textHi),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  decoration: cooked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              // Chosen options and paid add-ons are two
                              // different jobs for the cook: one changes how
                              // the dish is made, the other adds something
                              // extra to the plate. Run together in one grey
                              // line they were the same sentence, and the
                              // extra is the one that gets forgotten.
                              if (ticket.modifiers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: Sp.s1),
                                  child: Wrap(
                                    spacing: Sp.s1h,
                                    runSpacing: Sp.s1,
                                    children: [
                                      // `display` already prefixes the sign, so
                                      // the chip only picks a tone. The add-on
                                      // takes a solid accent as the source does
                                      // — a tint of it sat at the same volume
                                      // as the option beside it.
                                      for (final m in ticket.modifiers)
                                        SatChip.tag(
                                          label: m.display,
                                          size: SatChipSize.sm,
                                          hue: m.priceDelta > 0
                                              ? SatChipHue.accent
                                              : SatChipHue.neutral,
                                          filled: m.priceDelta > 0,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Never dimmed with the rest. "Tanpa telur" is the
                        // reason the plate goes out or into the bin, and it
                        // stays true after the cook has ticked the item off.
                        if (ticket.note != null &&
                            ticket.note!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Sp.s1h),
                            child: NoteLine(
                              label: 'Instruksi khusus',
                              text: ticket.note!,
                              alert: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "TELAT 3" beside the completed filter. Only rendered when the count is
/// non-zero — a permanent "TELAT 0" is a word the line stops reading, and
/// `urgent` is too scarce a colour to spend on the good case.
class _LateTally extends StatelessWidget {
  final int count;
  const _LateTally({required this.count});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ink = sc.inkOn(sc.urgent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: Sp.s1h),
      decoration: SatBox.d(color: sc.urgent, borderRadius: SatR.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(color: ink),
          const SizedBox(width: Sp.s1h),
          Text(SatShape.caps('Telat'), style: SatType.labelS(color: ink)),
          const SizedBox(width: Sp.s1h),
          Text('$count', style: SatType.monoM(color: ink)),
        ],
      ),
    );
  }
}

/// The done marker. An indicator, not a button — the whole row takes the
/// long-press. Empty ring until the cook commits, then a filled `success` disc.
class _Tick extends StatefulWidget {
  final bool cooked;
  const _Tick({required this.cooked});

  @override
  State<_Tick> createState() => _TickState();
}

class _TickState extends State<_Tick> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant _Tick old) {
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
        margin: const EdgeInsets.only(top: Sp.sHair),
        width: 26,
        height: 26,
        decoration: SatBox.d(
          color: widget.cooked ? sc.success : Colors.transparent,
          shape: BoxShape.circle,
          border: SatB.all(
            color: widget.cooked ? sc.success : sc.border2,
            width: 1.5,
          ),
        ),
        // Empty until committed — the source draws no glyph in the open state,
        // and a grey tick reads as "already done" from two metres away.
        child: widget.cooked
            ? Icon(Icons.check_rounded, size: 16, color: sc.inkOn(sc.success))
            : null,
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
          Text('Antrian masak kosong', style: SatType.labelL(color: sc.textMd)),
          const SizedBox(height: Sp.s1h),
          Text(
            'Semua pesanan dapur sudah selesai dimasak.',
            style: SatType.bodyM(color: sc.textLo),
          ),
        ],
      ),
    );
  }
}
