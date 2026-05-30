import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/ui/core/state/view_mode_view_model.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/tables/widgets/guest_stepper_sheet.dart';
import 'package:satset/ui/features/tables/widgets/reservations_strip.dart';

/// Ticks once per second to drive live elapsed-time updates on table cards.
/// autoDispose so the stream stops when no card is watching it.
final _tableElapsedTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ),
);

// Animation tuning. Lively but professional. easeOutQuart per design tokens.
const Curve _kEase = Curves.easeOutQuart;
const Duration _kStatusXfade = Duration(milliseconds: 280);
const Duration _kChipMorph = Duration(milliseconds: 240);
const Duration _kCardEnter = Duration(milliseconds: 380);
const Duration _kPressIn = Duration(milliseconds: 90);
const int _kStaggerStepMs = 26;

// Elapsed-time heat: linear textLo→warn (0–30min) → urgent (30–60min), clamp red past the hour.
const Duration _kElapsedAlarm = Duration(hours: 1);

Color _elapsedHeatColor(Duration elapsed, SatColors sc) {
  final t = (elapsed.inSeconds / _kElapsedAlarm.inSeconds).clamp(0.0, 1.0);
  if (t < 0.5) return Color.lerp(sc.textLo, sc.warn, t / 0.5)!;
  return Color.lerp(sc.warn, sc.urgent, (t - 0.5) / 0.5)!;
}

bool _animationsDisabled(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
    final forcePhone = ref.watch(forcePhoneViewProvider);
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
      orElse: () => zones.isEmpty
          ? const Zone(id: '', name: '', short: '')
          : zones.first,
    );

    final zoneTables = activeTables.where((t) => t.zoneId == activeZoneId).toList();
    final occupied = zoneTables.where((t) => t.status != TableStatus.available).length;
    final ready = zoneTables.where((t) => t.status == TableStatus.ready).length;
    final openTotal = zoneTables.fold<int>(0, (s, t) => s + t.openAmount);
    final subParts = <String>[
      '$occupied dari ${zoneTables.length} terisi',
      if (ready > 0) '$ready siap diambil',
      if (openTotal > 0) 'tab ${formatIDR(openTotal)}',
    ];
    final subLine = subParts.join(' · ');

    if (l.useTabletShell && !forcePhone) {
      return Stack(
        children: [
          Column(
            children: [
              TabletSectionHead(
                title: zone.name,
                sub: subLine,
              ),
              const ReservationsStrip(tablet: true),
              _ZoneRow(
                tables: activeTables,
                zones: zones,
                active: activeZoneId,
                onChange: (id) => setState(() => _activeZone = id),
                tablet: true,
              ),
              Expanded(
                child: zoneTables.isEmpty
                    ? _EmptyZone(zoneName: zone.name, tablet: true)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 96),
                        child: GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            for (final entry in zoneTables.asMap().entries)
                              _CardFadeIn(
                                key: ValueKey('tab-$activeZoneId-${entry.value.id}'),
                                index: entry.key,
                                child: _TableCard(
                                  table: entry.value,
                                  tablet: true,
                                  onTap: () => context.push('/table/${entry.value.id}'),
                                  onLongPress: () => showGuestStepperSheet(
                                    context: context,
                                    tableId: entry.value.id,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: _PhoneViewToggle(
              onTap: () => ref.read(forcePhoneViewProvider.notifier).state = true,
            ),
          ),
        ],
      );
    }

    final cols = l.gridCount(minTileWidth: 180);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: SatType.sans(
                          size: 30,
                          weight: FontWeight.w600,
                          letterSpacing: -0.6,
                          height: 1.05,
                          color: context.sat.textHi,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      subLine,
                      style: SatType.mono(
                        size: 11,
                        color: context.sat.textLo,
                        letterSpacing: 0.44,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const ReservationsStrip(tablet: false),
        _ZoneRow(
          tables: activeTables,
          zones: zones,
          active: activeZoneId,
          onChange: (id) => setState(() => _activeZone = id),
          tablet: false,
        ),
        Expanded(
          child: zoneTables.isEmpty
              ? _EmptyZone(zoneName: zone.name, tablet: false)
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, l.bottomInset),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                      child: GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.45,
                        children: [
                          for (final entry in zoneTables.asMap().entries)
                            _CardFadeIn(
                              key: ValueKey('phn-$activeZoneId-${entry.value.id}'),
                              index: entry.key,
                              child: _TableCard(
                                table: entry.value,
                                tablet: false,
                                onTap: () => context.push('/table/${entry.value.id}'),
                                onLongPress: () => showGuestStepperSheet(
                                  context: context,
                                  tableId: entry.value.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (l.useTabletShell && forcePhone)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, l.bottomInset + 8),
            child: _BackToTabletPill(
              onTap: () => ref.read(forcePhoneViewProvider.notifier).state = false,
            ),
          ),
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final List<VenueTable> tables;
  final List<Zone> zones;
  final String active;
  final ValueChanged<String> onChange;
  final bool tablet;
  const _ZoneRow({required this.tables, required this.zones, required this.active, required this.onChange, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final padH = tablet ? 32.0 : 16.0;
    final padV = tablet ? 12.0 : 10.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 0, padH, padV),
      child: SizedBox(
        height: tablet ? 42 : 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: zones.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final z = zones[i];
            final isActive = active == z.id;
            final zoneTables = tables.where((t) => t.zoneId == z.id).toList();
            final ready = zoneTables.where((t) => t.status == TableStatus.ready).length;
            final countLabel = ready > 0 ? '$ready siap' : '${zoneTables.length}';
            final dur = _animationsDisabled(context) ? Duration.zero : _kChipMorph;
            return GestureDetector(
              onTap: () => onChange(z.id),
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.97,
                duration: dur,
                curve: _kEase,
                child: AnimatedContainer(
                  duration: dur,
                  curve: _kEase,
                  padding: EdgeInsets.symmetric(horizontal: tablet ? 16 : 14, vertical: tablet ? 10 : 9),
                  decoration: BoxDecoration(
                    color: isActive ? sc.textHi : sc.bg2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: isActive ? sc.textHi : sc.border0),
                  ),
                  child: Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        curve: _kEase,
                        style: SatType.sans(
                          size: 13,
                          weight: FontWeight.w500,
                          color: isActive ? sc.bg0 : sc.textMd,
                        ),
                        child: Text(z.name),
                      ),
                      const SizedBox(width: 10),
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        curve: _kEase,
                        style: SatType.mono(
                          size: 11,
                          color: isActive ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
                          letterSpacing: 0,
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

class _TableCard extends ConsumerStatefulWidget {
  final VenueTable table;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool tablet;
  const _TableCard({
    required this.table,
    required this.onTap,
    required this.tablet,
    this.onLongPress,
  });

  @override
  ConsumerState<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<_TableCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.table.status == TableStatus.ready) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.table.status == TableStatus.ready;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _statusLabel(VenueTable table) => switch (table.status) {
        TableStatus.available => 'Kosong',
        TableStatus.occupied => 'Terisi',
        TableStatus.pending => 'Pesanan masuk',
        TableStatus.ready => 'Siap ×${table.readyCount > 0 ? table.readyCount : 1}',
      };

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final tablet = widget.tablet;
    final sc = context.sat;
    final isReady = table.status == TableStatus.ready;
    final isOccupied = table.status == TableStatus.occupied;
    final isPending = table.status == TableStatus.pending;

    Color bg = sc.bg2;
    Color border = sc.border0;
    Color statusDot = sc.textDim;
    Color statusColor = sc.textMd;
    Color numColor = sc.textHi;

    if (isOccupied) {
      bg = sc.bg3;
      statusDot = sc.info;
      statusColor = sc.info;
    } else if (isPending) {
      bg = sc.bg3;
      border = sc.warnSoft;
      statusDot = sc.warn;
      statusColor = sc.warn;
    } else if (isReady) {
      bg = sc.successSoft;
      border = sc.success.withValues(alpha: 0.5);
      statusDot = sc.success;
      statusColor = sc.success;
      numColor = sc.success;
    }

    final currentUserId = ref.watch(authStateProvider).user?.id;
    final staff = ref.watch(staffRepositoryProvider);
    final actor = table.lastActorId == null
        ? null
        : staff.where((u) => u.id == table.lastActorId).firstOrNull;
    final isMine = actor != null && actor.id == currentUserId;
    if (isMine) {
      border = sc.accentBorder;
    }

    final tnumSize = tablet ? 36.0 : 26.0;
    final radius = tablet ? 20.0 : 22.0;
    final padding = tablet ? const EdgeInsets.fromLTRB(18, 18, 18, 16) : const EdgeInsets.fromLTRB(14, 16, 14, 14);
    final avatarSize = tablet ? 24.0 : 20.0;

    final reduced = _animationsDisabled(context);
    final xfade = reduced ? Duration.zero : _kStatusXfade;
    final pressDur = reduced ? Duration.zero : _kPressIn;

    final card = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: pressDur,
      curve: _kEase,
      child: AnimatedContainer(
        duration: xfade,
        curve: _kEase,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: (_) {
              if (!reduced) setState(() => _pressed = true);
            },
            onTapCancel: () {
              if (_pressed) setState(() => _pressed = false);
            },
            onTapUp: (_) {
              if (_pressed) setState(() => _pressed = false);
            },
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedDefaultTextStyle(
                            duration: xfade,
                            curve: _kEase,
                            style: SatType.mono(
                              size: tnumSize,
                              weight: FontWeight.w500,
                              letterSpacing: -tnumSize * 0.02,
                              color: numColor,
                            ),
                            child: Text(
                              table.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.person_outline,
                          size: tablet ? 16 : 13, color: sc.textMd),
                      const SizedBox(width: 3),
                      Text('${table.pax}/${table.capacity}',
                          style: SatType.mono(
                            size: tablet ? 13 : 11,
                            color: sc.textMd,
                            letterSpacing: 0.44,
                          )),
                    ],
                  ),
                  if (table.openAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(formatIDR(table.openAmount),
                          style: SatType.mono(
                            size: 12,
                            weight: FontWeight.w500,
                            color: sc.textMd,
                            letterSpacing: 0.24,
                          )),
                    ),
                  const Spacer(),
                  if (table.openedAt != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: tablet ? 4 : 3, left: 18),
                      child: Builder(builder: (ctx) {
                        ref.watch(_tableElapsedTickerProvider);
                        final elapsed = DateTime.now().difference(table.openedAt!);
                        return Text(
                          formatElapsedId(elapsed),
                          style: SatType.mono(
                            size: tablet ? 12 : 11,
                            color: _elapsedHeatColor(elapsed, sc),
                            letterSpacing: 0.44,
                          ),
                        );
                      }),
                    ),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: xfade,
                        curve: _kEase,
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusDot,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: xfade,
                          curve: _kEase,
                          style: SatType.sans(
                            size: tablet ? 13 : 12,
                            weight: isReady ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: -0.12,
                            height: isPending ? 1.15 : 1.0,
                            color: statusColor,
                          ),
                          child: Text(
                            _statusLabel(table),
                            maxLines: isPending ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (actor != null) ...[
                        const SizedBox(width: 8),
                        _ActorAvatar(actor: actor, size: avatarSize, mine: isMine),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!isReady || reduced) return card;

    // Ready: soft pulsing glow halo. Communicates "pick me up".
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: sc.success.withValues(alpha: 0.10 + 0.22 * t),
                blurRadius: 10 + 10 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: card,
    );
  }
}

class _ActorAvatar extends StatelessWidget {
  final AppUser actor;
  final double size;
  final bool mine;
  const _ActorAvatar({required this.actor, required this.size, required this.mine});

  static const _fallback = 0xFFFF9233;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final base = Color(actor.avatarColorHex ?? _fallback);
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.36), base);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, dark],
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: grad,
        shape: BoxShape.circle,
        border: Border.all(
          color: mine ? sc.accent : Colors.transparent,
          width: mine ? 2 : 0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        actor.initials,
        style: SatType.mono(
          size: size * 0.42,
          weight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
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
    if (_animationsDisabled(context)) {
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
        final t = _kEase.transform(_c.value);
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
    final reduced = _animationsDisabled(context);
    final iconBubble = Container(
      width: tablet ? 72 : 56,
      height: tablet ? 72 : 56,
      decoration: BoxDecoration(
        color: sc.bg2,
        shape: BoxShape.circle,
        border: Border.all(color: sc.border0),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.grid_view_rounded, size: tablet ? 32 : 26, color: sc.textLo),
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
              style: SatType.sans(
                size: tablet ? 18 : 15,
                weight: FontWeight.w600,
                letterSpacing: -0.2,
                color: sc.textHi,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tambahkan meja lewat Manajer › Lantai',
              textAlign: TextAlign.center,
              style: SatType.mono(
                size: 11,
                color: sc.textLo,
                letterSpacing: 0.44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneViewToggle extends StatelessWidget {
  final VoidCallback onTap;
  const _PhoneViewToggle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.bg2,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sc.border1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smartphone_outlined, size: 14, color: sc.textMd),
              const SizedBox(width: 8),
              Text(
                'PHONE VIEW',
                style: SatType.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 0.88,
                  color: sc.textMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToTabletPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackToTabletPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: sc.border1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tablet_mac_outlined, size: 14, color: sc.textMd),
                const SizedBox(width: 8),
                Text(
                  'TABLET VIEW',
                  style: SatType.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 0.88,
                    color: sc.textMd,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
