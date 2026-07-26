import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';

class TabletShell extends StatelessWidget {
  final String activeTab;
  final int readyCount;
  final int kitchenCount;
  final bool showKasir;
  final bool showGuest;
  final int guestCount;
  final Widget child;
  final List<String> crumbs;

  const TabletShell({
    super.key,
    required this.activeTab,
    required this.readyCount,
    required this.kitchenCount,
    this.showKasir = false,
    this.showGuest = false,
    this.guestCount = 0,
    required this.child,
    required this.crumbs,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: Row(
        children: [
          TabletSideRail(
              active: activeTab,
              readyCount: readyCount,
              kitchenCount: kitchenCount,
              showKasir: showKasir,
              showGuest: showGuest,
              guestCount: guestCount),
          Expanded(
            child: Column(
              children: [
                SatAppBar(crumbs: crumbs, showAvatar: false),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabletSideRail extends StatelessWidget {
  final String active;
  final int readyCount;
  final int kitchenCount;
  final bool showKasir;
  final bool showGuest;
  final int guestCount;
  const TabletSideRail({
    super.key,
    required this.active,
    required this.readyCount,
    required this.kitchenCount,
    this.showKasir = false,
    this.showGuest = false,
    this.guestCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: 76,
      decoration: SatBox.d(
        // The paper skin fills the whole rail with the accent and lets the
        // nav blocks read as cut-outs; midnight keeps the surface and inverts
        // the blocks instead. Same rule, heavier than a card's (neo.css §7).
        color: SatShape.brutalPaper ? sc.accent : sc.bg1,
        border: Border(
          right: BorderSide(
            color: sc.border0,
            width: SatShape.brutal ? 4 : 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Mark(),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _RailBtn(id: 'tables', label: 'Meja', icon: Icons.grid_view_rounded, route: '/tables', active: active),
                  _RailBtn(id: 'orders', label: 'Pesanan', icon: Icons.description_outlined, route: '/orders', active: active, badge: readyCount, alert: readyCount > 0),
                  if (showGuest)
                    _RailBtn(id: 'guest', label: 'Mandiri', icon: Icons.qr_code_2, route: '/guestorders', active: active, badge: guestCount, alert: guestCount > 0),
                  _RailBtn(id: 'kitchen', label: 'Antrian', icon: Icons.receipt_long_outlined, route: '/kitchen', active: active, badge: kitchenCount),
                  if (showKasir)
                    _RailBtn(id: 'kasir', label: 'Kasir', icon: Icons.point_of_sale_rounded, route: '/kasir', active: active),
                  _RailDiv(),
                  _RailBtn(id: 'venue', label: 'Venue', icon: Icons.storefront_outlined, route: '/venue', active: active),
                ],
              ),
            ),
          ),
          _AvatarBtn(active: active == 'me'),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // The mark always opposes the rail: ink block on the siren rail, siren
    // block on the dark one. On paper that means the logo, not the rail, is
    // the black slab.
    final onAccentRail = SatShape.brutalPaper;
    return Container(
      width: 40,
      height: 40,
      decoration: SatBox.d(
        color: onAccentRail ? SatShape.ink : sc.accent,
        borderRadius: SatR.a(12),
        border: SatShape.brutal ? SatB.all(color: SatShape.ink) : null,
        boxShadow: SatShape.brutal ? SatShape.hardShadow() : null,
      ),
      alignment: Alignment.center,
      child: Text('S',
          style: SatShape.brutal
              ? SatType.display(
                  size: 20,
                  letterSpacing: -0.8,
                  color: onAccentRail ? sc.accent : sc.accentInk,
                )
              : SatType.mono(
                  size: 20,
                  weight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: sc.accentInk,
                )),
    );
  }
}

class _RailDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
          width: 36, height: SatShape.brutal ? 3 : 1, color: sc.border0),
    );
  }
}

class _RailBtn extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final String active;
  final int badge;
  final bool alert;
  const _RailBtn({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.active,
    this.badge = 0,
    this.alert = false,
  });

  /// On paper the rail is the accent itself, so both states sit on a bright
  /// ground and take ink. On midnight the active block *is* the accent, so
  /// only it flips to accent ink.
  Color _fg(SatColors sc, bool isActive) {
    if (!SatShape.brutal) return isActive ? sc.textHi : sc.textLo;
    if (SatShape.brutalPaper) return SatShape.ink;
    return isActive ? sc.accentInk : sc.textMd;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isActive = active == id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: SatR.a(14),
          child: Container(
            width: 56,
            height: 56,
            // Brutal marks the active tab as a lifted block cut out of the
            // rail — paper drops to the surface colour, midnight rises to the
            // accent. Idle tabs read straight off the rail, so their label
            // takes the rail's own ink rather than the ramp's dim greys.
            decoration: SatBox.d(
              color: SatShape.brutal
                  ? (isActive
                      ? (SatShape.brutalPaper ? sc.bg1 : sc.accent)
                      : Colors.transparent)
                  : (isActive ? sc.bg3 : Colors.transparent),
              borderRadius: SatR.a(14),
              border: SatShape.brutal && isActive
                  ? SatB.all(color: SatShape.ink)
                  : null,
              boxShadow: SatShape.brutal && isActive
                  ? SatShape.hardShadow()
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: _fg(sc, isActive)),
                    const SizedBox(height: 2),
                    Text(SatShape.caps(label),
                        // The active block's 3px rule eats 6px of the 56px
                        // tile, and uppercase at +0.06em tracking runs past
                        // what is left — "MANDIRI" wrapped to two lines and
                        // overflowed the column. One line, sized to fit it.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.sans(
                          size: SatShape.brutal ? 9 : 10,
                          weight:
                              SatShape.brutal ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: SatShape.brutal ? 0.6 : 0.2,
                          color: _fg(sc, isActive),
                        )),
                  ],
                ),
                if (badge > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: SatBox.d(
                        color: alert ? sc.success : sc.accent,
                        borderRadius: SatR.a(8),
                        // Thinner than the 3px rule — a 16px pip fattened to
                        // the full width would be all border and no count.
                        border: SatShape.brutal
                            ? Border.all(color: SatShape.ink, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badge',
                        style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          color: alert ? sc.successInk : sc.accentInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarBtn extends ConsumerWidget {
  final bool active;
  const _AvatarBtn({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final user = ref.watch(authStateProvider).user;
    final initials = (user?.initials.isNotEmpty ?? false) ? user!.initials : '—';
    final base = Color(user?.avatarColorHex ?? 0xFFFF9233);
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.32), base);
    // ADR-0047 keeps status pips round because a radius token cannot reach
    // `BoxShape.circle`. The rail avatar is the one the source design squares
    // explicitly, and at 42px it reads as a nameplate rather than a pip.
    final shape = SatShape.brutal ? BoxShape.rectangle : BoxShape.circle;
    final border = SatShape.brutal ? null : const CircleBorder();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        shape: border,
        child: InkWell(
          customBorder: border,
          onTap: () => context.go('/me'),
          child: Container(
            width: 46,
            height: 46,
            decoration: SatBox.d(
              shape: shape,
              border: SatShape.brutal
                  ? null
                  : SatB.all(
                      color: active ? sc.accentBorder : Colors.transparent,
                      width: 2,
                    ),
              boxShadow: active
                  ? (SatShape.brutal
                      ? null
                      : [BoxShadow(color: sc.bg1, blurRadius: 0, spreadRadius: 3)])
                  : null,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 42,
              decoration: SatBox.d(
                shape: shape,
                border: SatShape.brutal ? SatB.all(color: SatShape.ink) : null,
                boxShadow:
                    SatShape.brutal && active ? SatShape.hardShadow() : null,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: SatShape.brutal ? [base, base] : [base, dark],
                ),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: SatType.mono(
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class TabletSectionHead extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? trailing;
  const TabletSectionHead({super.key, required this.title, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: SatType.sans(
                      size: 32,
                      weight: FontWeight.w600,
                      letterSpacing: -0.8,
                      height: 1.05,
                      color: sc.textHi,
                    )),
                if (sub != null) ...[
                  const SizedBox(height: 6),
                  Text(sub!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.mono(
                        size: 11,
                        color: sc.textLo,
                        letterSpacing: 0.66,
                      )),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class TabletCard extends StatelessWidget {
  final String? header;
  final Widget? headerTrailing;
  final Widget child;
  final EdgeInsets padding;
  const TabletCard({
    super.key,
    this.header,
    this.headerTrailing,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(18),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    header!.toUpperCase(),
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: sc.textLo,
                    ),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class TabletStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? bg;
  final Color? valueColor;
  const TabletStatTile({super.key, required this.value, required this.label, this.bg, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: bg ?? sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: SatType.mono(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.44,
                height: 1,
                color: valueColor ?? sc.textHi,
              )),
          const SizedBox(height: 8),
          Text(label.toUpperCase(),
              style: SatType.mono(
                size: 10,
                color: sc.textLo,
                letterSpacing: 0.6,
                weight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
