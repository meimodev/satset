import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../models/dummy_data.dart';
import '../../models/venue_table.dart';
import '../../state/tables_provider.dart';
import '../../widgets/satset_top_bar.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  String _activeZone = 'terrace';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final zone = DummyData.zones.firstWhere((z) => z.id == _activeZone);
    final zoneTables = tables.where((t) => t.zoneId == _activeZone).toList();
    final occupied = zoneTables.where((t) => t.status != TableStatus.available).length;
    final ready = zoneTables.where((t) => t.status == TableStatus.ready).length;

    return Column(
      children: [
        SatsetTopBar(zone: zone),
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
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '$occupied dari ${zoneTables.length} terisi · $ready siap',
                      style: SatType.mono(
                        size: 11,
                        color: sc.textLo,
                        letterSpacing: 0.44,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ZoneTabs(
          tables: tables,
          active: _activeZone,
          onChange: (id) => setState(() => _activeZone = id),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.45,
              children: [
                for (final t in zoneTables)
                  _TableCard(
                    table: t,
                    onTap: () => context.push('/table/${t.id}'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneTabs extends StatelessWidget {
  final List<VenueTable> tables;
  final String active;
  final ValueChanged<String> onChange;
  const _ZoneTabs({required this.tables, required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: DummyData.zones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final z = DummyData.zones[i];
          final isActive = active == z.id;
          final zoneTables = tables.where((t) => t.zoneId == z.id).toList();
          final ready = zoneTables.where((t) => t.status == TableStatus.ready).length;
          final countLabel = ready > 0 ? '$ready·sp' : '${zoneTables.length}';
          return GestureDetector(
            onTap: () => onChange(z.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  const SizedBox(width: 8),
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
    );
  }
}

class _TableCard extends StatelessWidget {
  final VenueTable table;
  final VoidCallback onTap;
  const _TableCard({required this.table, required this.onTap});

  String _statusLabel() => switch (table.status) {
        TableStatus.available => 'Kosong',
        TableStatus.occupied => 'Duduk',
        TableStatus.pending => 'Pesanan masuk',
        TableStatus.ready => 'Siap ×${table.readyCount > 0 ? table.readyCount : 1}',
      };

  @override
  Widget build(BuildContext context) {
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
    if (table.mine) {
      border = sc.accentBorder;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                            size: 26,
                            weight: FontWeight.w500,
                            letterSpacing: -0.52,
                            color: numColor,
                          )),
                      const Spacer(),
                      Text('${table.pax}p',
                          style: SatType.mono(
                            size: 11,
                            color: sc.textMd,
                            letterSpacing: 0.44,
                          )),
                    ],
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
                          overflow: TextOverflow.ellipsis,
                          style: SatType.sans(
                            size: 12,
                            weight: isReady ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: -0.12,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (table.elapsed != null) ...[
                        const SizedBox(width: 8),
                        Text(table.elapsed!,
                            style: SatType.mono(
                              size: 11,
                              color: sc.textLo,
                              letterSpacing: 0.44,
                            )),
                      ],
                    ],
                  ),
                ],
              ),
              if (table.mine)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    'PUNYAMU',
                    style: SatType.mono(
                      size: 9,
                      weight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: sc.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
