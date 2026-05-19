import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../models/venue_table.dart';
import '../../models/order.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/components/sat_button.dart';
import '../order_taking/order_screen.dart';

class TableDetailScreen extends ConsumerWidget {
  const TableDetailScreen({super.key, required this.table});

  final VenueTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableOrders = DummyData.orders.where((o) => o.tableId == table.id).toList();

    Color getStatusColor() {
      switch (table.status) {
        case TableStatus.empty:
          return AppColors.outlineVariant;
        case TableStatus.ordering:
          return AppColors.primary;
        case TableStatus.waiting:
          return AppColors.primaryContainer;
        case TableStatus.ready:
          return AppColors.secondaryFixed;
      }
    }

    String getStatusLabel() {
      switch (table.status) {
        case TableStatus.empty:
          return 'Kosong';
        case TableStatus.ordering:
          return 'Pesanan Diproses';
        case TableStatus.waiting:
          return 'Menunggu Makanan';
        case TableStatus.ready:
          return 'Siap Diantar';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Meja ${table.label}'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                border: Border.all(color: AppColors.secondaryOverride, width: 1),
                borderRadius: BorderRadius.circular(AppShapes.sm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(AppShapes.sm),
                    ),
                    child: Center(
                      child: Text(
                        table.label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: table.status == TableStatus.empty ? AppColors.onSurfaceVariant : AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meja ${table.label}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${getStatusLabel()} · Kapasitas: ${table.capacity}',
                          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (table.status != TableStatus.empty)
              SatButton(
                label: 'Pesanan Baru',
                icon: Icons.add,
                expanded: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(table: table),
                    ),
                  );
                },
              ),
            if (table.status == TableStatus.empty) ...[
              const SizedBox(height: AppSpacing.lg),
              SatButton(
                label: 'Mulai Pesanan Baru',
                icon: Icons.restaurant_menu,
                expanded: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(table: table),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (tableOrders.isNotEmpty) ...[
              const Text('Pesanan Aktif', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.onBackground)),
              const SizedBox(height: AppSpacing.md),
              ...tableOrders.map((order) => _OrderCard(order: order)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border.all(color: AppColors.secondaryOverride, width: 1),
        borderRadius: BorderRadius.circular(AppShapes.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.toUpperCase()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  order.status.label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColors.onTertiaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('${item.quantity}x ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                Expanded(
                  child: Text(item.name, style: const TextStyle(fontSize: 14, color: AppColors.onSurface)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class AppShapes {
  AppShapes._();
  static const double sm = 4;
}
