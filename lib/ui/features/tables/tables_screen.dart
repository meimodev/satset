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
    final zone = zones.firstWhere(
      (z) => z.id == _activeZone,
      orElse: () => zones.isEmpty
          ? const Zone(id: '', name: '', short: '')
          : zones.first,
    );
    final zoneTables = tables.where((t) => t.zoneId == _activeZone).toList();
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
              _ZoneRow(tables: tables, zones: zones, active: _activeZone, onChange: (id) => setState(() => _activeZone = id), tablet: true),
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
                            for (final t in zoneTables)
                              _TableCard(
                                table: t,
                                tablet: true,
                                onTap: () => context.push('/table/${t.id}'),
                                onLongPress: () => showGuestStepperSheet(
                                  context: context,
                                  tableId: t.id,
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
        _ZoneRow(
          tables: tables,
          zones: zones,
          active: _activeZone,
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
                          for (final t in zoneTables)
                            _TableCard(
                              table: t,
                              tablet: false,
                              onTap: () => context.push('/table/${t.id}'),
                              onLongPress: () => showGuestStepperSheet(
                                context: context,
                                tableId: t.id,
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
            return GestureDetector(
              onTap: () => onChange(z.id),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: tablet ? 16 : 14, vertical: tablet ? 10 : 9),
                decoration: BoxDecoration(
                  color: isActive ? sc.textHi : sc.bg2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isActive ? sc.textHi : sc.border0),
                ),
                child: Row(
                  children: [
                    Text(z.name,
                        style: SatType.sans(
                          size: 13,
                          weight: FontWeight.w500,
                          color: isActive ? sc.bg0 : sc.textMd,
                        )),
                    const SizedBox(width: 10),
                    Text(countLabel,
                        style: SatType.mono(
                          size: 11,
                          color: isActive ? sc.bg0.withValues(alpha: 0.6) : sc.textLo,
                          letterSpacing: 0,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TableCard extends ConsumerWidget {
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

  String _statusLabel() => switch (table.status) {
        TableStatus.available => 'Kosong',
        TableStatus.occupied => 'Terisi',
        TableStatus.pending => 'Pesanan masuk',
        TableStatus.ready => 'Siap ×${table.readyCount > 0 ? table.readyCount : 1}',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(table.id,
                          style: SatType.mono(
                            size: tnumSize,
                            weight: FontWeight.w500,
                            letterSpacing: -tnumSize * 0.02,
                            color: numColor,
                          )),
                      const Spacer(),
                      Text(tablet ? '${table.pax} tamu' : '${table.pax}p',
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
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusDot),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusLabel(),
                          maxLines: isPending ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.sans(
                            size: tablet ? 13 : 12,
                            weight: isReady ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: -0.12,
                            height: isPending ? 1.15 : 1.0,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (table.elapsed != null) ...[
                        const SizedBox(width: 8),
                        Text(table.elapsed!,
                            style: SatType.mono(
                              size: tablet ? 12 : 11,
                              color: sc.textLo,
                              letterSpacing: 0.44,
                            )),
                      ],
                      if (actor != null) ...[
                        const SizedBox(width: 8),
                        _ActorAvatar(actor: actor, size: avatarSize, mine: isMine),
                      ],
                    ],
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

class _EmptyZone extends StatelessWidget {
  final String zoneName;
  final bool tablet;
  const _EmptyZone({required this.zoneName, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final pad = tablet ? 48.0 : 24.0;
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tablet ? 72 : 56,
              height: tablet ? 72 : 56,
              decoration: BoxDecoration(
                color: sc.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: sc.border0),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.grid_view_rounded, size: tablet ? 32 : 26, color: sc.textLo),
            ),
            SizedBox(height: tablet ? 18 : 14),
            Text(
              'Belum ada meja di $zoneName',
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
