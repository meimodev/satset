import 'package:flutter/material.dart';

enum SatBreak { compact, medium, expanded, tablet }

class SatLayout {
  final Size size;
  final Orientation orientation;
  final EdgeInsets padding;
  final SatBreak br;

  const SatLayout._(this.size, this.orientation, this.padding, this.br);

  factory SatLayout.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final br = w >= 1024
        ? SatBreak.tablet
        : (w < 600
              ? SatBreak.compact
              : (w < 905 ? SatBreak.medium : SatBreak.expanded));
    return SatLayout._(mq.size, mq.orientation, mq.padding, br);
  }

  bool get isCompact => br == SatBreak.compact;
  bool get isMedium => br == SatBreak.medium;
  bool get isExpanded => br == SatBreak.expanded;
  bool get isTablet => br == SatBreak.tablet;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  bool get useTabletShell => isTablet;
  bool get useSideRail {
    if (isTablet) return true;
    if (br == SatBreak.expanded) return true;
    if (br == SatBreak.medium && isLandscape) return true;
    if (br == SatBreak.compact && isLandscape && size.height < 480) return true;
    return false;
  }

  double get sideRailWidth => isTablet ? 76 : (isExpanded ? 96 : 80);

  double get topInset => padding.top + (isLandscape && isCompact ? 8 : 24);
  double get bottomInset => padding.bottom + (useSideRail ? 16 : 92);

  double get gutter {
    if (isTablet) return 32;
    if (isExpanded) return 24;
    if (isMedium) return 20;
    return 16;
  }

  double get contentMaxWidth {
    switch (br) {
      case SatBreak.compact:
        return double.infinity;
      case SatBreak.medium:
        return 760;
      case SatBreak.expanded:
        return 1120;
      case SatBreak.tablet:
        return double.infinity;
    }
  }

  int gridCount({required double minTileWidth}) {
    if (isTablet) return 4;
    final usable = size.width.clamp(320, contentMaxWidth) - (gutter * 2);
    final rail = useSideRail ? sideRailWidth : 0;
    final c = ((usable - rail) / minTileWidth).floor();
    return c.clamp(2, 6);
  }

  int responsiveColumns(double containerWidth, {double minTileWidth = 170}) {
    final c = (containerWidth / minTileWidth).floor();
    return c.clamp(2, 6);
  }
}

/// Dimensions, not spacing.
///
/// `Sp` stops at 48 and says why: above that a number is the *shape of a thing*
/// — a panel, a row, a mark — and naming it on the spacing scale invites the
/// wrong one to be reached for. This is where those live instead, so the
/// sign-in surfaces stop carrying four bare literals that only agree by luck.
class SatSize {
  SatSize._();

  /// The sign-in panel. Wide enough for a full email address at body size,
  /// narrow enough that the eye does not travel between a label and its field.
  /// The tablet layout gives it a deeper inset, not a wider box.
  static const double authPanel = 480;

  /// The same panel where it holds a message rather than a form — the
  /// host-occupied screen, the password change. Prose reads narrower.
  static const double authPanelNarrow = 420;

  /// The panel's own inset. Deliberately off the spacing scale: it is the
  /// panel's shape, not a gap between two things inside it.
  static const double authPanelInset = 56;

  /// A pressable row — the mode toggle's pill, a large field. Above the 48 the
  /// scale stops at because principle 1 sizes this for a moving thumb, not for
  /// the grid.
  static const double control = 52;
}

extension SatLayoutX on BuildContext {
  SatLayout get layout => SatLayout.of(this);
}

class SatPageScaffold extends StatelessWidget {
  final Widget child;
  final bool constrainWidth;
  const SatPageScaffold({
    super.key,
    required this.child,
    this.constrainWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    if (!constrainWidth || l.isCompact || l.isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
        child: child,
      ),
    );
  }
}
