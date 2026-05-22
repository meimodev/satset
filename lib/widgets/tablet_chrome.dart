import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/colors.dart';
import '../design/typography.dart';

class TabletShell extends StatelessWidget {
  final String activeTab;
  final int readyCount;
  final Widget child;
  final List<String> crumbs;
  final Widget? crumbLeading;
  final bool offline;

  const TabletShell({
    super.key,
    required this.activeTab,
    required this.readyCount,
    required this.child,
    required this.crumbs,
    this.crumbLeading,
    this.offline = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: Row(
        children: [
          TabletSideRail(active: activeTab, readyCount: readyCount),
          Expanded(
            child: Column(
              children: [
                TabletTopBar(
                  crumbs: crumbs,
                  leading: crumbLeading,
                  offline: offline,
                ),
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
  const TabletSideRail({super.key, required this.active, required this.readyCount});

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
                  _RailBtn(id: 'kds', label: 'KDS', icon: Icons.local_fire_department_outlined, route: '/kds', active: active),
                  _RailDiv(),
                  _RailBtn(id: 'floor', label: 'Lantai', icon: Icons.place_outlined, route: '/floor', active: active),
                  _RailBtn(id: 'menuadm', label: 'Menu', icon: Icons.menu_rounded, route: '/menuadm', active: active),
                  _RailBtn(id: 'reports', label: 'Laporan', icon: Icons.auto_awesome_outlined, route: '/reports', active: active),
                  _RailDiv(),
                  _RailBtn(id: 'settings', label: 'Sistem', icon: Icons.wifi_rounded, route: '/settings', active: active),
                  _RailBtn(id: 'staff', label: 'Staf', icon: Icons.person_outline_rounded, route: '/staff', active: active),
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

class _AvatarBtn extends StatelessWidget {
  final bool active;
  const _AvatarBtn({required this.active});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9233), Color(0xFFD96030)],
                ),
              ),
              alignment: Alignment.center,
              child: Text('MA',
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

class TabletTopBar extends StatelessWidget {
  final List<String> crumbs;
  final Widget? leading;
  final bool offline;
  const TabletTopBar({super.key, required this.crumbs, this.leading, this.offline = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Flexible(child: _Crumbs(items: crumbs)),
          const Spacer(),
          _SyncPill(offline: offline),
          const SizedBox(width: 14),
          Text('18:14 · Sab',
              style: SatType.mono(
                size: 13,
                color: sc.textMd,
                letterSpacing: 0.52,
              )),
        ],
      ),
    );
  }
}

class _Crumbs extends StatelessWidget {
  final List<String> items;
  const _Crumbs({required this.items});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('›', style: SatType.mono(size: 12, color: sc.textDim)),
        ));
      }
      children.add(Text(
        items[i],
        overflow: TextOverflow.ellipsis,
        style: SatType.mono(
          size: 12,
          weight: i == items.length - 1 ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: 0.48,
          color: i == items.length - 1 ? sc.textHi : sc.textMd,
        ),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _SyncPill extends StatelessWidget {
  final bool offline;
  const _SyncPill({required this.offline});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final dotColor = offline ? sc.warn : sc.success;
    final softColor = offline ? sc.warnSoft : sc.successSoft;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: softColor, blurRadius: 0, spreadRadius: 3)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            offline ? 'HANYA LAN · CLOUD TUNGGU' : 'LIVE · LAN',
            style: SatType.mono(
              size: 11,
              weight: FontWeight.w500,
              letterSpacing: 0.66,
              color: sc.textMd,
            ),
          ),
        ],
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
          if (trailing != null) trailing!,
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
                if (headerTrailing != null) headerTrailing!,
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
