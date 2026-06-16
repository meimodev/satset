import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(right: BorderSide(color: sc.border0)),
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: sc.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('S',
          style: SatType.mono(
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
      child: Container(width: 36, height: 1, color: sc.border0),
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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? sc.bg3 : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: isActive ? sc.textHi : sc.textLo),
                    const SizedBox(height: 2),
                    Text(label,
                        style: SatType.sans(
                          size: 10,
                          weight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: isActive ? sc.textHi : sc.textLo,
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
                      decoration: BoxDecoration(
                        color: alert ? sc.success : sc.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badge',
                        style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          color: alert ? const Color(0xFF0A0A0A) : sc.accentInk,
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/me'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? sc.accentBorder : Colors.transparent,
                width: 2,
              ),
              boxShadow: active
                  ? [BoxShadow(color: sc.bg1, blurRadius: 0, spreadRadius: 3)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [base, dark],
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
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(18),
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
      decoration: BoxDecoration(
        color: bg ?? sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
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
