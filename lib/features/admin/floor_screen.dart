import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/layout.dart';
import '../../design/format.dart';
import '../../models/dummy_data.dart';
import '../../models/venue_table.dart';
import '../../state/tables_provider.dart';
import '_common.dart';

class FloorScreen extends ConsumerWidget {
  const FloorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tables = ref.watch(tablesProvider);
    final byZone = {for (final z in DummyData.zones) z.id: tables.where((t) => t.zoneId == z.id).toList()};

    if (!context.layout.useTabletShell) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
          children: [
            Text('Live floor',
                style: SatType.sans(
                  size: 30,
                  weight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: sc.textHi,
                )),
            const SizedBox(height: 16),
            for (final z in DummyData.zones) _zoneBlock(context, sc, z.name, byZone[z.id] ?? const []),
          ],
        ),
      );
    }
    final ready = tables.where((t) => t.status == TableStatus.ready).length;
    final occupied = tables.where((t) => t.status != TableStatus.available).length;

    return AdminPage(
      title: 'Live floor',
      sub: '$occupied / ${tables.length} terisi · $ready siap diambil · 4 zona',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminPill(context, 'Tampilkan amount', on: true),
          const SizedBox(width: 8),
          adminPill(context, 'Cetak peta'),
        ],
      ),
      children: [
        for (final z in DummyData.zones) ...[
          _zoneBlock(context, sc, z.name, byZone[z.id] ?? const []),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _zoneBlock(BuildContext context, SatColors sc, String zoneName, List<VenueTable> tables) {
    final ready = tables.where((t) => t.status == TableStatus.ready).length;
    final occupied = tables.where((t) => t.status != TableStatus.available).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(zoneName,
                style: SatType.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: sc.textMd,
                )),
            const SizedBox(width: 10),
            Text('$occupied/${tables.length} TERISI · $ready SIAP',
                style: SatType.mono(
                  size: 10,
                  letterSpacing: 0.8,
                  color: sc.textLo,
                )),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (ctx, c) {
          final isTab = context.layout.useTabletShell;
          final cols = isTab ? 6 : 3;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: tables.length,
            itemBuilder: (ctx, i) => _miniCard(context, sc, tables[i]),
          );
        }),
      ],
    );
  }

  Widget _miniCard(BuildContext context, SatColors sc, VenueTable t) {
    Color bg = sc.bg2;
    Color border = sc.border0;
    Color dot = sc.textDim;
    Color label = sc.textMd;
    String status = 'Kosong';
    if (t.status == TableStatus.occupied) {
      bg = sc.bg3; dot = sc.info; label = sc.info; status = 'Aktif';
    } else if (t.status == TableStatus.pending) {
      bg = sc.bg3; border = sc.warnSoft; dot = sc.warn; label = sc.warn; status = 'Kirim';
    } else if (t.status == TableStatus.ready) {
      bg = sc.successSoft; border = sc.success.withValues(alpha: 0.4); dot = sc.success; label = sc.success; status = 'Siap';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(t.id,
                  style: SatType.mono(
                    size: 22,
                    weight: FontWeight.w500,
                    letterSpacing: -0.44,
                    color: t.status == TableStatus.ready ? sc.success : sc.textHi,
                  )),
              const Spacer(),
              Text('${t.pax}p',
                  style: SatType.mono(
                    size: 11,
                    color: sc.textMd,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          if (t.openAmount > 0) Text(formatIDR(t.openAmount),
              style: SatType.mono(
                size: 10,
                color: sc.textMd,
                letterSpacing: 0.3,
              )),
          const Spacer(),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(status,
                  style: SatType.sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: label,
                  )),
              const Spacer(),
              if (t.elapsed != null)
                Text(t.elapsed!,
                    style: SatType.mono(
                      size: 10,
                      color: sc.textLo,
                      letterSpacing: 0.4,
                    )),
            ],
          ),
        ],
      ),
    );
  }
}
