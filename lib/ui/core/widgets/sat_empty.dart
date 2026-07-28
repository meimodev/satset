import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// The "nothing here yet" state (ADR-0055).
///
/// Six private versions of this existed — `_Empty` twice, `_EmptyDetail`,
/// `_EmptyState`, `_EmptyQueue`, `_EmptyZone` — at four icon sizes and three
/// type pairings.
///
/// [body] is where the next action goes, in words. An empty screen that only
/// says "kosong" tells a new hire nothing about what to do about it, which is
/// the whole reason this state gets a widget rather than a centred string.
class SatEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;

  /// One way out — 'Buat preset', 'Tambah meja'. Optional: some empties are
  /// simply a state the room is in, not a thing to fix.
  final Widget? action;

  const SatEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Sp.s10, color: sc.textLo),
            const SizedBox(height: Sp.s3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SatType.labelL(color: sc.textHi),
            ),
            if (body != null) ...[
              const SizedBox(height: Sp.s1h),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: SatType.bodyM(color: sc.textLo),
              ),
            ],
            if (action != null) ...[const SizedBox(height: Sp.s4), action!],
          ],
        ),
      ),
    );
  }
}

/// A caps label above a section that is not inside a card. The card version is
/// [SatCard.section]'s own header; this is for the loose stacks — a settings
/// list, the me screen's activity groups.
class SatSectionLabel extends StatelessWidget {
  final String label;
  final EdgeInsets padding;

  const SatSectionLabel(
    this.label, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: Sp.s1h),
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: padding,
      child: Text(
        label.toUpperCase(),
        style: SatType.caption(color: sc.textLo),
      ),
    );
  }
}
