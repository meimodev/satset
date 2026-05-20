import 'package:flutter/material.dart';
import '../design/colors.dart';
import '../design/typography.dart';
import '../state/ready_alert_provider.dart';

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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C5F3F), Color(0xFF163A23)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sc.success.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 36,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: sc.success,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.notifications_active,
                  size: 18, color: Color(0xFF0A0A0A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Siap di pass · ${alert.what}',
                      style: SatType.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        letterSpacing: -0.13,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    'MEJA ${alert.tableId} · ${alert.zone.toUpperCase()} · SEKARANG',
                    style: SatType.mono(
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.78),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Ambil',
                  style: SatType.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
