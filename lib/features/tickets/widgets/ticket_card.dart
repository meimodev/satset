import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../models/order.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.order,
    this.onStatusChange,
  });

  final Order order;
  final ValueChanged<OrderStatus>? onStatusChange;

  Color get _urgencyColor {
    final elapsed = order.elapsed;
    if (elapsed.inMinutes > 12) return AppColors.urgencyRed;
    if (elapsed.inMinutes > 5) return AppColors.urgencyAmber;
    return AppColors.urgencyGreen;
  }

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.received:
        return AppColors.primary;
      case OrderStatus.cooking:
        return AppColors.urgencyAmber;
      case OrderStatus.ready:
        return AppColors.urgencyGreen;
      case OrderStatus.served:
        return AppColors.outline;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String get _elapsedText {
    final elapsed = order.elapsed;
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(
          top: BorderSide(color: _urgencyColor, width: 3),
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          right: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          left: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.displayLabel} · ${order.displayType}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${order.id.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'WAKTU',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: _urgencyColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _elapsedText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _urgencyColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                children: order.items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      border: item != order.items.last
                          ? const Border(
                              bottom: BorderSide(color: AppColors.surfaceVariant),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.notes != null || item.modifierNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              item.notes ?? item.modifierNames.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Status buttons
          if (onStatusChange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
              child: Row(
                children: [
                  if (order.status != OrderStatus.cooking)
                    Expanded(
                      child: _StatusButton(
                        label: OrderStatus.received.actionLabel,
                        icon: Icons.soup_kitchen,
                        color: AppColors.urgencyAmber,
                        onTap: () => onStatusChange!(OrderStatus.cooking),
                      ),
                    ),
                  if (order.status == OrderStatus.cooking) ...[
                    Expanded(
                      child: _StatusButton(
                        label: OrderStatus.cooking.actionLabel,
                        icon: Icons.check_circle_outline,
                        color: AppColors.urgencyGreen,
                        onTap: () => onStatusChange!(OrderStatus.ready),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
