import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dummy_data.dart';
import '../../design/spacing.dart';
import 'widgets/ticket_card.dart';

final ordersProvider = StateProvider((ref) => DummyData.orders);

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = (screenWidth / 220).floor().clamp(2, 6);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xl + 80,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 0.55,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        if (index >= orders.length) return const SizedBox.shrink();
        return TicketCard(
          order: orders[index],
          onStatusChange: (newStatus) {
            final current = ref.read(ordersProvider);
            if (index >= current.length) return;
            final updated = current.toList();
            updated[index] = current[index].copyWith(status: newStatus);
            ref.read(ordersProvider.notifier).state = updated;
          },
        );
      },
    );
  }
}
