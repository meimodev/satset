import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../models/venue_table.dart';
import 'table_tile.dart';

class ZoneSection extends StatelessWidget {
  const ZoneSection({
    super.key,
    required this.zone,
    required this.tables,
    required this.capacityPct,
    required this.onTableTap,
  });

  final dynamic zone;
  final List<VenueTable> tables;
  final int capacityPct;
  final ValueChanged<VenueTable> onTableTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          border: Border.all(color: AppColors.secondaryOverride, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: AppColors.onBackground,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: capacityPct > 50 ? AppColors.primaryFixed : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$capacityPct% KAPASITAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: capacityPct > 50 ? AppColors.onPrimaryFixed : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: AppColors.secondaryOverride),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final crossCount = availableWidth < 300
                      ? 3
                      : availableWidth < 500
                          ? 4
                          : availableWidth < 700
                              ? 6
                              : 8;
                  final spacing = AppSpacing.sm;
                  final itemWidth = (availableWidth - (crossCount - 1) * spacing) / crossCount;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: tables.map((table) {
                      return SizedBox(
                        width: table.isBooth ? itemWidth * 2 + spacing : itemWidth,
                        height: table.isBooth ? itemWidth : itemWidth,
                        child: TableTile(
                          table: table,
                          onTap: () => onTableTap(table),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
