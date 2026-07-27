import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';

class ReadyToast extends StatelessWidget {
  final ReadyAlert alert;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  const ReadyToast({
    super.key,
    required this.alert,
    required this.onView,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 56, 12, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: SatBox.d(
          // Green wash derived from the palette's own `success` rather than a
          // fixed pair of greens — under `neonHijau` a baked-in emerald would
          // fight the accent it sits next to.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(sc.success.withValues(alpha: 0.30), sc.bg2),
              Color.alphaBlend(sc.success.withValues(alpha: 0.12), sc.bg1),
            ],
          ),
          borderRadius: SatR.a(18),
          border: SatB.all(color: sc.success.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: satShadowInk.withValues(alpha: 0.55),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: SatBox.d(color: sc.success, borderRadius: SatR.a(12)),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_active,
                size: 18,
                color: sc.successInk,
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siap di pass · ${alert.what}',
                    style: SatType.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      letterSpacing: -0.13,
                      color: sc.textHi,
                    ),
                  ),
                  const SizedBox(height: Sp.sHair),
                  Text(
                    alert.isTakeaway
                        ? [
                            alert.tableLabel.toUpperCase(),
                            if (alert.zone.isNotEmpty) alert.zone.toUpperCase(),
                            'SEKARANG',
                          ].join(' · ')
                        : 'MEJA ${alert.tableLabel} · ${alert.zone.toUpperCase()} · SEKARANG',
                    style: SatType.mono(
                      size: 11,
                      color: sc.textMd,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                backgroundColor: sc.success.withValues(alpha: 0.18),
                foregroundColor: sc.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s3,
                  vertical: Sp.s1h,
                ),
                shape: RoundedRectangleBorder(borderRadius: SatR.a(10)),
              ),
              child: Text(
                'Ambil',
                style: SatType.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: sc.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
