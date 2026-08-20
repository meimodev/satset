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
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/ui/core/state/tickers.dart';
import 'package:satset/ui/features/admin/kitchen/kitchen_order.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_orders.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_view_model.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// The timer's ink. Neutral until the ticket is worth worrying about: a ticket
/// two minutes old is not news, and spending a colour on the good case is how
/// `urgent` stops being read. Glow paints the calm case lime instead, because
/// the head it sits in is an obsidian slab and `textMd` there is a mutter.
///
/// A frozen clock is `success` regardless of the number it stopped on — the
/// card already reads "Semua siap" in the same green, and a red 25:00 on a
/// finished batch contradicts the missing Telat chip beside it.
Color _ageColor(
  SatColors sc,
  int min, {
  required bool complete,
  required int targetMins,
}) {
  if (complete) return sc.success;
  if (min >= targetMins) return sc.urgent;
  if (min >= (targetMins * kKitchenWarnFraction).round()) return sc.warn;
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

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    // "Late" on this board is the venue's configured target resolved per line
    // (ADR-0043) — the same number the overdue cue and the report SLA use, so
    // the pass, the phone and the report cannot tell the cook three stories.
    //
    // The queue is grouped in a provider and recomputed on ticket events and
    // once a minute, not in this build behind a 1s timer. Station timers tick
    // on their own inside _Timer. See ADR-0081.
    final orders = ref.watch(kitchenOrdersProvider);
    final showCompleted = ref.watch(kitchenShowCompletedProvider);
    final itemCount = orders.fold<int>(0, (n, o) => n + o.total);
    // Each card already turns urgent on its own, but a cook working the top of
    // a scrolled queue cannot see how many are red below the fold. The tally is
    // the one number that says whether the line is behind — so a finished batch
    // is not in it, however long it took.
    final lateCount = orders.where((o) => o.late).length;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // All status changes round-trip through the server via the KDS
    // view model + AdvanceTicketStatusUseCase so other clients see them.
    void toggle(String tableId, String ticketId) {
      ref
          .read(kitchenViewModelProvider.notifier)
          .toggleCooked(tableId, ticketId);
    }

    final filter = _CompletedFilter(
      value: showCompleted,
      onChanged: (v) =>
          ref.read(kitchenShowCompletedProvider.notifier).state = v,
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
                context.l10n.kitchenQueueTitle,
                style: SatType.h2(color: sc.textHi),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                context.l10n.kitQueueSub(orders.length, itemCount),
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
      title: context.l10n.kitchenQueueTitle,
      sub: context.l10n.kitchenQueueSub(orders.length, itemCount),
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
                context.l10n.kitShowDone,
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
  final KitchenOrder order;
  final void Function(String tableId, String ticketId) onToggle;
  const _OrderCard({required this.order, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final ageDur = order.age;
    final late = order.late;
    final warn = order.warn;
    final progress = order.total == 0 ? 0.0 : order.done / order.total;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final simpleKds = ref.watch(
      venueSettingsProvider.select((v) => v.counterOn(counterSimpleKds)),
    );
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
            // Empty under `simpleKds` (ADR-0109): with one pace the caption
            // is the same word on every card, which is a word the eye stops
            // reading. Emptied at the source rather than branched inside the
            // head — the head renders the courses it is given, and "which
            // courses does this venue show" is not a painting decision.
            courses: simpleKds ? const <Course>[] : order.courses,
            age: ageDur,
            clockStart: order.clockStart,
            sentAt: order.sentAt,
            late: late,
            targetMins: order.targetMins,
            complete: order.complete,
            done: order.done,
            total: order.total,
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
                    onTap: () => onToggle(order.tableId, order.tickets[i].id),
                  ),
              ],
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

  /// Where the prep clock started, so the station timer can run live off it
  /// rather than off a figure baked in at group time. See _Timer.
  final DateTime clockStart;
  final String sentAt;
  final bool late;
  final int targetMins;
  final bool complete;
  final int done;
  final int total;
  const _CardHead({
    required this.table,
    required this.courses,
    required this.age,
    required this.clockStart,
    required this.sentAt,
    required this.late,
    required this.targetMins,
    required this.complete,
    required this.done,
    required this.total,
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
                // A caption, not a chip. The course never changes and never
                // acts, so a filled accent capsule was spending a signal colour
                // and a container's worth of affordance on a static label —
                // and the per-course hues are worse still, five of them stacked
                // on obsidian being a paint chart rather than a signal.
                for (final c in courses)
                  Text(
                    SatShape.caps(courseLabel(context.l10n, c.serialId)),
                    style: SatType.caption(color: sc.textMd),
                  ),
                if (late)
                  SatChip.tag(
                    label: context.l10n.reservationActionLate,
                    size: SatChipSize.sm,
                    hue: SatChipHue.urgent,
                    filled: true,
                  ),
              ],
            ),
          ),
          const SizedBox(width: Sp.s2),
          _Timer(
            age: age,
            clockStart: clockStart,
            sentAt: sentAt,
            sc: sc,
            complete: complete,
            late: late,
            targetMins: targetMins,
            done: done,
            total: total,
          ),
        ],
      ),
    );
  }
}

/// Elapsed over arrival, right-aligned. Bare numerals rather than a pill: the
/// slab already separates the head, and a tinted capsule inside a tinted slab
/// is two containers saying one thing.
/// The station clock: "8:42", read from 1–2 m across a hot line.
///
/// The only thing on this board that moves every second, so it is the only
/// thing that watches the seconds ticker — the queue around it is grouped in a
/// provider that recomputes on ticket events and once a minute (ADR-0081).
///
/// [age] is the provider's minute-fresh figure and decides the colour tier and
/// the pulse; the digits are read live off [clockStart] so they advance between
/// those recomputes. A complete batch has no live clock at all — it froze at
/// its real time-to-pass — so it renders [age] directly.
class _Timer extends ConsumerStatefulWidget {
  final Duration age;
  final DateTime clockStart;
  final String sentAt;
  final SatColors sc;
  final bool complete;
  final bool late;
  final int targetMins;
  final int done;
  final int total;
  const _Timer({
    required this.age,
    required this.clockStart,
    required this.sentAt,
    required this.sc,
    required this.complete,
    required this.late,
    required this.targetMins,
    required this.done,
    required this.total,
  });

  @override
  ConsumerState<_Timer> createState() => _TimerState();
}

class _TimerState extends ConsumerState<_Timer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _late => widget.late;

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
    // Colour and pulse follow the provider's minute-fresh age; only the digits
    // are live, so a card cannot flicker between tiers mid-minute.
    final color = _ageColor(
      sc,
      widget.age.inMinutes,
      complete: widget.complete,
      targetMins: widget.targetMins,
    );
    final Duration shown;
    if (widget.complete) {
      shown = widget.age;
    } else {
      ref.watch(secondTickerProvider);
      final live = SatClock.now().difference(widget.clockStart);
      shown = live.isNegative ? Duration.zero : live;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) =>
              Opacity(opacity: 1 - 0.4 * _pulse.value, child: child),
          child: Text(
            formatStationTimer(shown),
            style: SatType.monoL(color: color),
          ),
        ),
        Text(
          context.l10n.kitSentAt(widget.sentAt),
          style: SatType.monoS(color: sc.textMd),
        ),
        const SizedBox(height: Sp.s1),
        Text(
          widget.done == widget.total
              ? context.l10n.kitAllReady
              : context.l10n.kitReadyOf(widget.done, widget.total),
          style: SatType.monoS(
            color: widget.done == widget.total ? sc.success : sc.textMd,
          ),
        ),
      ],
    );
  }
}

/// Status dot that gently pulses while an order is overdue (≥10m), drawing the
/// cook's eye to the most urgent ticket. Static (no repaint) otherwise.
class _KdsItemRow extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _KdsItemRow({required this.ticket, required this.onTap});

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
    final cooked = kitchenLineDone(widget.ticket.status);
    final wasCooked = kitchenLineDone(old.ticket.status);
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
        SnackBar(
          content: Text(context.l10n.kitHoldToFinish),
          duration: const Duration(milliseconds: 1500),
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
    final cooked = kitchenLineDone(ticket.status);
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
          // No rule between rows: the 3px spine, the strike-through and the
          // dimming already separate one item from the next, and on a card of
          // five items the hairlines cost height the KDS would rather spend on
          // the dish names. `minHeight` holds at 40 — the row commits on
          // long-press and this is a hot line, so the target does not shrink;
          // the padding is what inflated the multi-line rows anyway.
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.fromLTRB(14, Sp.s2, 12, Sp.s2),
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
                              label: context.l10n.tblSpecialInstruction,
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
            context.l10n.kitEmptyTitle,
            style: SatType.labelL(color: sc.textMd),
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            context.l10n.kitEmptyBody,
            style: SatType.bodyM(color: sc.textLo),
          ),
        ],
      ),
    );
  }
}
