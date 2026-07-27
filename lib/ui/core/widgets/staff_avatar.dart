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
/// Shared across the floor grid, the Pesanan board, table-detail line items,
/// the staff admin list, the tablet rail and the profile header, so the same
/// person reads as the same swatch everywhere. That promise is the whole point
/// of the widget: three screens used to inline their own version with a
/// different darkening and glyph weight, and the same waiter looked like two
/// different people between the rail and the list.
class StaffAvatar extends StatelessWidget {
  final String initials;
  final int? colorHex;
  final double size;
  final bool mine;

  /// Used when the account has no colour of its own — the staff admin list
  /// falls back to the role's colour rather than the house orange, so an
  /// unconfigured account still groups visually with its peers.
  final Color? fallbackColor;

  /// Squares the avatar under the brutal skin. Off by default: ADR-0047 keeps
  /// small round pips round, and only the surfaces where the avatar is big
  /// enough to read as a nameplate (the tablet rail at 42px) opt in.
  final bool squareUnderBrutal;

  // Not const: the initials and colour are read off [actor] in the initialiser.
  StaffAvatar({
    super.key,
    required AppUser actor,
    this.size = 22,
    this.mine = false,
    this.fallbackColor,
    this.squareUnderBrutal = false,
  }) : initials = actor.initials,
       colorHex = actor.avatarColorHex;

  /// For callers holding a view-model row rather than an [AppUser] — the
  /// profile header, whose model carries shift progress alongside the identity.
  const StaffAvatar.raw({
    super.key,
    required this.initials,
    required this.colorHex,
    this.size = 22,
    this.mine = false,
    this.fallbackColor,
    this.squareUnderBrutal = false,
  });

  static const _fallback = 0xFFFF9233;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final base = colorHex != null
        ? Color(colorHex!)
        : (fallbackColor ?? const Color(_fallback));
    final square = squareUnderBrutal && SatShape.brutal;
    return Container(
      width: size,
      height: size,
      decoration: SatBox.d(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, darken(base)],
        ),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        border: SatB.all(
          color: mine ? sc.accent : Colors.transparent,
          width: mine ? 2 : 0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: SatType.mono(
          size: size * 0.42,
          weight: FontWeight.w700,
          color: onFill(base),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
