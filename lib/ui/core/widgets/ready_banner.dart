import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

class ReadyBanner extends StatelessWidget {
  const ReadyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sc.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sc.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 14, color: sc.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Item siap diambil di pass — tandai disajikan di bawah',
              style: SatType.sans(size: 12, weight: FontWeight.w500, color: sc.success),
            ),
          ),
        ],
      ),
    );
  }
}
