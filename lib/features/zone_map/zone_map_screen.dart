import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../models/venue_table.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import 'widgets/status_legend.dart';
import 'widgets/zone_section.dart';
import '../table_detail/table_detail_screen.dart';

final zoneMapProvider = StateProvider((ref) => DummyData.zones);
final tablesProvider = StateProvider((ref) => DummyData.tables);

class ZoneMapScreen extends ConsumerWidget {
  const ZoneMapScreen({super.key});

  void _onTableTap(BuildContext context, VenueTable table) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableDetailScreen(table: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zoneMapProvider);
    final tables = ref.watch(tablesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final hPadding = screenWidth < 600 ? AppSpacing.containerMargin : 40.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPadding, AppSpacing.md, hPadding, AppSpacing.xl + 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peta Zona', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.02, color: AppColors.onBackground)),
                    SizedBox(height: AppSpacing.sm),
                    Text('Status lantai dan kapasitas terkini.', style: TextStyle(fontSize: 18, height: 1.6, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const StatusLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...zones.map((zone) {
            final zoneTables = tables.where((t) => t.zoneId == zone.id).toList();
            final occupied = zoneTables.where((t) => t.status != TableStatus.empty).length;
            final pct = zoneTables.isEmpty ? 0 : (occupied / zoneTables.length * 100).round();

            return ZoneSection(
              zone: zone,
              tables: zoneTables,
              capacityPct: pct,
              onTableTap: (table) => _onTableTap(context, table),
            );
          }),
        ],
      ),
    );
  }
}
