import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/reservations_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/ui/features/tables/widgets/guest_stepper_sheet.dart';
import 'package:satset/ui/features/tables/widgets/reservations_surface.dart';
import 'package:satset/ui/features/tables/widgets/table_card.dart';
import 'package:satset/ui/features/tables/widgets/takeaway_surface.dart';
import 'package:satset/ui/core/design/spacing.dart';

// Animation tuning. Lively but professional. easeOutQuart per design tokens.
const Duration _kChipMorph = Duration(milliseconds: 240);
const Duration _kCardEnter = Duration(milliseconds: 380);
const int _kStaggerStepMs = 26;

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  String _activeZone = 'terrace';

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    final tables = ref.watch(tablesProvider);
    final zones = ref.watch(zonesProvider);

    // Filter active tables for the waiters' floor map
    final activeTables = tables.where((t) => t.active).toList();

    // Dynamically resolve activeZoneId if _activeZone is not in the zones list
    final activeZoneId = zones.any((z) => z.id == _activeZone)
        ? _activeZone
        : (zones.isNotEmpty ? zones.first.id : _activeZone);

    final zone = zones.firstWhere(
      (z) => z.id == activeZoneId,
      orElse: () =>
          zones.isEmpty ? const Zone(id: '', name: '', short: '') : zones.first,
    );

    final zoneTables = activeTables
        .where((t) => t.zoneId == activeZoneId)
        .toList();
    final occupied = zoneTables
        .where((t) => t.status != TableStatus.available)
        .length;
    final ready = zoneTables.where((t) => t.status == TableStatus.ready).length;
    final openTotal = zoneTables.fold<int>(0, (s, t) => s + t.openAmount);
    final subParts = <String>[
      '$occupied dari ${zoneTables.length} terisi',
      if (ready > 0) '$ready siap diambil',
      if (openTotal > 0) 'tab ${formatIDR(openTotal)}',
    ];
    final subLine = subParts.join(' · ');

    final tablet = l.useTabletShell;

    final head = _FloorHead(tablet: tablet, title: zone.name, sub: subLine);
    final zoneRow = _ZoneRow(
      tables: activeTables,
      zones: zones,
      active: activeZoneId,
      onChange: (id) => setState(() => _activeZone = id),
      tablet: tablet,
    );

    if (tablet) {
      return Column(
        children: [
          head,
          zoneRow,
          Expanded(
            child: zoneTables.isEmpty
                ? _EmptyZone(zoneName: zone.name, tablet: true)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 96),
                    child: _FloorGrid(
                      tables: zoneTables,
                      zoneId: activeZoneId,
                      cols: 4,
                      gap: 12,
                      tablet: true,
                    ),
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        head,
        zoneRow,
        Expanded(
          child: zoneTables.isEmpty
              ? _EmptyZone(zoneName: zone.name, tablet: false)
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, l.bottomInset),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                      child: _FloorGrid(
                        tables: zoneTables,
                        zoneId: activeZoneId,
                        cols: l.gridCount(minTileWidth: 180),
                        gap: 8,
                        tablet: false,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Zone title + counts, and the three floor entry points.
///
/// Reservations and takeaway used to live here as always-on horizontal strips
/// that cost ~140px of grid before a waiter had looked at a single table
/// (ADR-0048). They are now counted triggers: the number is the whole point,
/// and the list is one tap away.
class _FloorHead extends ConsumerWidget {
  final bool tablet;
  final String title;
  final String sub;
  const _FloorHead({
    required this.tablet,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = SatClock.now();
    final grace = ref.watch(venueSettingsProvider).reservationGraceMins;
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final today = ref
        .watch(reservationsRepositoryProvider)
        .where(
          (r) =>
              r.expectedAt.isAfter(
                start.subtract(const Duration(minutes: 1)),
              ) &&
              r.expectedAt.isBefore(end),
        );
    final waiting = today
        .where((r) => r.status == ReservationStatus.pending)
        .length;
    final late = today
        .where(
          (r) =>
              r.status == ReservationStatus.pending &&
              now.difference(r.expectedAt) > Duration(minutes: grace),
        )
        .length;
    final takeaway = ref.watch(takeawayVisitsProvider).length;

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      // Tablet hangs these off the right of the section head; on a phone they
      // are their own row, so they start at the margin like everything else
      // rather than floating against the right edge.
      alignment: tablet ? WrapAlignment.end : WrapAlignment.start,
      children: [
        _FloorAction(
          icon: Icons.event_outlined,
          label: AppStrings.floorReservations,
          count: waiting,
          alert: late > 0
              ? '$late ${AppStrings.floorReservationsLateCount}'
              : null,
          compact: !tablet,
          onTap: () => openReservationsSurface(context, tablet: tablet),
        ),
        _FloorAction(
          icon: Icons.shopping_bag_outlined,
          label: AppStrings.floorTakeaway,
          count: takeaway,
          compact: !tablet,
          onTap: () => openTakeawaySurface(context),
        ),
        _NewOrderButton(tablet: tablet),
      ],
    );

    if (tablet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 32, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TabletSectionHead(title: title, sub: sub),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s3h),
              child: actions,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            SatShape.caps(title),
            style: SatType.h1(color: context.sat.textHi),
          ),
          const SizedBox(height: Sp.s1),
          Text(
            SatShape.caps(sub),
            style: SatType.monoS(color: context.sat.textLo),
          ),
          const SizedBox(height: Sp.s3),
          actions,
        ],
      ),
    );
  }
}

/// A counted trigger. The count is the reason the button exists; `alert` is the
/// subset that needs someone now and takes the urgent fill.
class _FloorAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String? alert;
  final bool compact;
  final VoidCallback onTap;
  const _FloorAction({
    required this.icon,
    required this.label,
    required this.count,
    required this.compact,
    required this.onTap,
    this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 9 : 11,
        ),
        decoration: SatBox.d(
          color: sc.bg2,
          borderRadius: SatR.a(12),
          border: SatB.all(color: alert != null ? sc.urgent : sc.border0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: sc.textMd),
            if (!compact) ...[
              const SizedBox(width: Sp.s2),
              Text(
                SatShape.caps(label),
                style: (brutal
                    ? SatType.labelS(color: sc.textHi)
                    : SatType.bodyS(color: sc.textHi)),
              ),
            ],
            const SizedBox(width: Sp.s2),
            Text('$count', style: SatType.monoM(color: sc.textMd)),
            if (alert != null) ...[
              const SizedBox(width: Sp.s2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s1h,
                  vertical: Sp.sHair,
                ),
                decoration: BoxDecoration(
                  color: sc.urgent,
                  borderRadius: SatR.a(5),
                  border: brutal
                      ? Border.all(color: SatShape.ink, width: 2)
                      : null,
                ),
                child: Text(
                  SatShape.caps(alert!),
                  style: SatType.labelS(color: onFill(sc.urgent)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rows of [cols] cards, each row as tall as its tallest card.
///
/// A `GridView` cannot do that — one `childAspectRatio` sizes every cell on the
/// screen — and the card's height is now genuinely variable: pills and the
/// stale banner both come and go. Chunked rows under `IntrinsicHeight` give the
/// CSS-grid behaviour the design assumes. It costs the grid's laziness, which
/// is affordable: one zone is a dozen or two cards, all of them already built.
class _FloorGrid extends StatelessWidget {
  final List<VenueTable> tables;
  final String zoneId;
  final int cols;
  final double gap;
  final bool tablet;
  const _FloorGrid({
    required this.tables,
    required this.zoneId,
    required this.cols,
    required this.gap,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < tables.length; start += cols) {
      final slice = tables.sublist(
        start,
        (start + cols).clamp(0, tables.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cols; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: i < slice.length
                      ? _CardFadeIn(
                          key: ValueKey('$zoneId-${slice[i].id}'),
                          index: start + i,
                          child: TableCard(
                            table: slice[i],
                            tablet: tablet,
                            onTap: () => context.push('/table/${slice[i].id}'),
                            onLongPress: () => showGuestStepperSheet(
                              context: context,
                              tableId: slice[i].id,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (start + cols < tables.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

/// Floor entry into the table-less menu-first draft flow (ADR-0026). Mints a
/// fresh draft cart then pushes the order menu; the table is chosen at commit.
class _NewOrderButton extends ConsumerWidget {
  final bool tablet;
  const _NewOrderButton({required this.tablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SatButton.primary(
      label: 'Pesanan baru',
      icon: Icons.add_rounded,
      size: tablet ? SatButtonSize.lg : SatButtonSize.md,
      onTap: () {
        startNewDraft(ref);
        context.push('/order/new');
      },
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final List<VenueTable> tables;
  final List<Zone> zones;
  final String active;
  final ValueChanged<String> onChange;
  final bool tablet;
  const _ZoneRow({
    required this.tables,
    required this.zones,
    required this.active,
    required this.onChange,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brutal = SatShape.brutal;
    final padH = tablet ? 32.0 : 16.0;
    final padV = tablet ? 12.0 : 10.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 0, padH, padV),
      child: SizedBox(
        height: tablet ? 42 : 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: zones.length,
          separatorBuilder: (_, _) => const SizedBox(width: Sp.s2),
          itemBuilder: (_, i) {
            final z = zones[i];
            final isActive = active == z.id;
            final zoneTables = tables.where((t) => t.zoneId == z.id).toList();
            final ready = zoneTables
                .where((t) => t.status == TableStatus.ready)
                .length;
            final countLabel = ready > 0
                ? '$ready siap'
                : '${zoneTables.length}';
            final dur = motionEnabled(context) ? _kChipMorph : Duration.zero;
            // Both poster skins fill the selected chip with the accent and keep
            // ink on it — Glow's zone tabs are solid lime pills. Lembut inverts
            // to the text ramp as before.
            final fill = isActive
                ? (SatShape.lembut ? sc.textHi : sc.accent)
                : sc.bg2;
            final fg = isActive
                ? (SatShape.lembut ? sc.bg0 : sc.accentInk)
                : sc.textMd;
            return GestureDetector(
              onTap: () => onChange(z.id),
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.97,
                duration: dur,
                curve: satEaseOut,
                child: AnimatedContainer(
                  duration: dur,
                  curve: satEaseOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: tablet ? 16 : 14,
                    vertical: tablet ? 10 : 9,
                  ),
                  decoration: SatBox.d(
                    color: fill,
                    borderRadius: SatR.a(999),
                    border: SatB.all(
                      color: isActive && !brutal ? sc.textHi : sc.border0,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        curve: satEaseOut,
                        style: (brutal
                            ? SatType.labelM(color: fg)
                            : SatType.bodyM(color: fg)),
                        child: Text(SatShape.caps(z.name)),
                      ),
                      const SizedBox(width: Sp.s2h),
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        curve: satEaseOut,
                        style: SatType.monoS(
                          color: isActive
                              ? fg.withValues(alpha: brutal ? 1 : 0.6)
                              : sc.textLo,
                        ),
                        child: Text(countLabel),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fades + rises each grid card in with a per-index stagger.
/// Re-runs whenever the key changes (e.g. switching zones).
class _CardFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _CardFadeIn({super.key, required this.index, required this.child});

  @override
  State<_CardFadeIn> createState() => _CardFadeInState();
}

class _CardFadeInState extends State<_CardFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _kCardEnter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (!motionEnabled(context)) {
      _c.value = 1;
      return;
    }
    final delay = Duration(milliseconds: _kStaggerStepMs * widget.index);
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
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
        final t = satEaseOut.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _EmptyZone extends StatefulWidget {
  final String zoneName;
  final bool tablet;
  const _EmptyZone({required this.zoneName, required this.tablet});

  @override
  State<_EmptyZone> createState() => _EmptyZoneState();
}

class _EmptyZoneState extends State<_EmptyZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablet = widget.tablet;
    final sc = context.sat;
    final pad = tablet ? 48.0 : 24.0;
    final reduced = !motionEnabled(context);
    final iconBubble = Container(
      width: tablet ? 72 : 56,
      height: tablet ? 72 : 56,
      decoration: SatBox.d(
        color: sc.bg2,
        shape: BoxShape.circle,
        border: SatB.all(color: sc.border0),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.grid_view_rounded,
        size: tablet ? 32 : 26,
        color: sc.textLo,
      ),
    );
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reduced)
              iconBubble
            else
              AnimatedBuilder(
                animation: _float,
                builder: (_, child) {
                  final t = Curves.easeInOut.transform(_float.value);
                  return Transform.translate(
                    offset: Offset(0, -4 * t),
                    child: child,
                  );
                },
                child: iconBubble,
              ),
            SizedBox(height: tablet ? 18 : 14),
            Text(
              'Belum ada meja di ${widget.zoneName}',
              textAlign: TextAlign.center,
              style: (tablet
                  ? SatType.h3(color: sc.textHi)
                  : SatType.labelL(color: sc.textHi)),
            ),
            const SizedBox(height: Sp.s1h),
            Text(
              AppStrings.tablesEmptyZoneAddTableHint,
              textAlign: TextAlign.center,
              style: SatType.monoS(color: sc.textLo),
            ),
          ],
        ),
      ),
    );
  }
}
