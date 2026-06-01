import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/ui/core/state/view_mode_view_model.dart';
import 'package:satset/ui/core/widgets/exit_guard.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_view_model.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final ready = ref.watch(totalReadyCountProvider);
    final kitchenCount = ref.watch(kitchenNewOrderCountProvider);
    final loc = GoRouterState.of(context).uri.path;
    final l = context.layout;

    final activeTab = _activeFor(loc);
    final forcePhone = ref.watch(forcePhoneViewProvider);
    final zones = ref.watch(zonesProvider);
    final zoneName = zones.isEmpty ? '—' : zones.first.name;
    final venueName = ref.watch(
        venueSettingsProvider.select((s) => s.displayName));

    if (l.useTabletShell && !forcePhone) {
      return ExitGuard(
        child: TabletShell(
          activeTab: activeTab,
          readyCount: ready,
          kitchenCount: kitchenCount,
          crumbs: _crumbsFor(loc, activeTab, zoneName, venueName),
          child: child,
        ),
      );
    }

    return ExitGuard(
      child: Scaffold(
        backgroundColor: sc.bg0,
        body: Column(
          children: [
            const SatAppBar(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 12,
                    child: _FloatingTabBar(active: activeTab, readyCount: ready),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activeFor(String loc) {
    if (loc.startsWith('/orders')) return 'orders';
    if (loc.startsWith('/kitchen')) return 'kitchen';
    if (loc.startsWith('/venue')) return 'venue';
    if (loc.startsWith('/floor')) return 'venue';
    if (loc.startsWith('/menuadm')) return 'venue';
    if (loc.startsWith('/system')) return 'venue';
    if (loc.startsWith('/staff')) return 'venue';
    if (loc.startsWith('/reports')) return 'venue';
    if (loc.startsWith('/me')) return 'me';
    return 'tables';
  }

  List<String> _crumbsFor(
      String loc, String activeTab, String zoneName, String venueName) {
    final venue = venueName.isEmpty ? 'Venue' : venueName;
    switch (activeTab) {
      case 'orders':
        return ['Teras', 'Pesanan saya'];
      case 'me':
        return ['Maya Anjani', 'Ringkasan shift'];
      case 'kitchen':
        return ['Stasiun', 'Antrian Persiapan'];
      case 'venue':
        if (loc.startsWith('/floor')) return ['Venue', 'Atur lantai'];
        if (loc.startsWith('/menuadm')) return ['Venue', 'Menu admin'];
        if (loc.startsWith('/system')) return ['Venue', 'Sistem'];
        if (loc.startsWith('/staff')) return ['Venue', 'Staf & akun'];
        if (loc.startsWith('/reports')) return ['Venue', 'Laporan shift'];
        return ['Venue', 'Konfigurasi'];
      default:
        return [venue, zoneName];
    }
  }
}

class _FloatingTabBar extends StatelessWidget {
  final String active;
  final int readyCount;
  const _FloatingTabBar({required this.active, required this.readyCount});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? const Color(0xEB1C1F23)
        : const Color(0xDBFFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sc.border1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _Tab(
                id: 'tables',
                label: 'Meja',
                icon: Icons.grid_view_rounded,
                active: active == 'tables',
                onTap: () => context.go('/tables'),
              ),
              _Tab(
                id: 'orders',
                label: 'Pesanan',
                icon: Icons.description_outlined,
                active: active == 'orders',
                badge: readyCount,
                badgeAlert: readyCount > 0,
                onTap: () => context.go('/orders'),
              ),
              _Tab(
                id: 'me',
                label: 'Saya',
                icon: Icons.person_outline_rounded,
                active: active == 'me',
                onTap: () => context.go('/me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool active;
  final int badge;
  final bool badgeAlert;
  final VoidCallback onTap;

  const _Tab({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge = 0,
    this.badgeAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: active ? sc.bg4 : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: active ? sc.textHi : sc.textLo),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: SatType.sans(
                      size: 10,
                      weight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: active ? sc.textHi : sc.textLo,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 8,
                right: 22,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: badgeAlert ? sc.success : sc.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 0,
                      color: badgeAlert ? const Color(0xFF0A0A0A) : sc.accentInk,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
