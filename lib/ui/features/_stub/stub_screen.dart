import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';

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
    return Padding(
      // Not `SatLayout.topInset` — that token clears a status bar for screens with no
      // chrome above them, and this one always renders under SatAppBar.
      padding: EdgeInsets.fromLTRB(0, Sp.s6, 0, context.shellInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: SatBox.d(
                color: sc.bg2,
                borderRadius: SatR.a(20),
                border: SatB.all(color: sc.border1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: sc.textMd),
            ),
            const SizedBox(height: Sp.s5),
            Text(title, style: SatType.h2(color: sc.textHi)),
            const SizedBox(height: Sp.s2),
            Text(
              subtitle ?? 'Segera hadir',
              style: SatType.bodyM(color: sc.textLo),
            ),
          ],
        ),
      ),
    );
  }
}
