import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Initials-in-colored-circle avatar for a staff member. Background is the
/// account's [AppUser.avatarColorHex] (soft-unique per venue), falling back to
/// a neutral orange for legacy rows. Set [mine] to ring the current user's own
/// avatar with the accent color.
///
/// Shared across the floor grid, the Pesanan board, and table-detail line
/// items so the same person reads as the same swatch everywhere.
class StaffAvatar extends StatelessWidget {
  final AppUser actor;
  final double size;
  final bool mine;
  const StaffAvatar({
    super.key,
    required this.actor,
    this.size = 22,
    this.mine = false,
  });

  static const _fallback = 0xFFFF9233;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final base = Color(actor.avatarColorHex ?? _fallback);
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.36), base);
    return Container(
      width: size,
      height: size,
      decoration: SatBox.d(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
        shape: BoxShape.circle,
        border: SatB.all(
          color: mine ? sc.accent : Colors.transparent,
          width: mine ? 2 : 0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        actor.initials,
        style: SatType.mono(
          size: size * 0.42,
          weight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
