import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

class ReadyBanner extends StatelessWidget {
  const ReadyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.successSoft,
        borderRadius: SatR.a(12),
        border: SatB.all(color: sc.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 14, color: sc.success),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              'Item siap diambil di pass — tandai disajikan di bawah',
              style: SatType.bodyS(color: sc.success),
            ),
          ),
        ],
      ),
    );
  }
}
