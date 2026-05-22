import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/layout.dart';
import '../../design/typography.dart';

class StubScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;

  const StubScreen({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, l.topInset, 0, l.bottomInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: sc.bg2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.border1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: sc.textMd),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: SatType.sans(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.2,
                color: sc.textHi,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? 'Segera hadir',
              style: SatType.sans(
                size: 13,
                weight: FontWeight.w400,
                color: sc.textLo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
