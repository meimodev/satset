import 'dart:ui';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/guest_orders_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/ui/core/widgets/admin_grace_banner.dart';
import 'package:satset/ui/core/widgets/exit_guard.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';

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
    final showKasir = ref.watch(authStateProvider).has(Capability.settleBill);
    // Mandiri is a destination only when the venue master switch is on — see
    // CONTEXT.md "Guest ordering switches". The per-table opt-in deliberately
    // does not enter into it: one table falling back to waiter service says
    // nothing about the other tables still ordering.
    final showGuest =
        ref.watch(authStateProvider).has(Capability.takeOrder) &&
        ref.watch(
          venueSettingsProvider.select((s) => s.guestOrderingEnabled),
        );
    final guestCount = ref.watch(guestOrdersProvider).length;
    final zones = ref.watch(zonesProvider);
    final zoneName = zones.isEmpty ? '—' : zones.first.name;
    final venueName = ref.watch(
      venueSettingsProvider.select((s) => s.displayName),
    );

    if (l.useTabletShell) {
      return ExitGuard(
        child: TabletShell(
          activeTab: activeTab,
          readyCount: ready,
          kitchenCount: kitchenCount,
          showKasir: showKasir,
          showGuest: showGuest,
          guestCount: guestCount,
          crumbs: _crumbsFor(loc, activeTab, zoneName, venueName),
          child: Column(
            children: [
              const AdminGraceBanner(),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return ExitGuard(
      child: Scaffold(
        backgroundColor: sc.bg0,
        body: Column(
          children: [
            const SatAppBar(),
            const AdminGraceBanner(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 12,
                    child: _FloatingTabBar(
                      active: activeTab,
                      readyCount: ready,
                      showKasir: showKasir,
                      showGuest: showGuest,
                      guestCount: guestCount,
                    ),
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
    if (loc.startsWith('/guestorders')) return 'guest';
    if (loc.startsWith('/orders')) return 'orders';
    if (loc.startsWith('/kitchen')) return 'kitchen';
    if (loc.startsWith('/venue')) return 'venue';
    if (loc.startsWith('/zone-admin')) return 'venue';
    if (loc.startsWith('/menuadm')) return 'venue';
    if (loc.startsWith('/system')) return 'venue';
    if (loc.startsWith('/staff')) return 'venue';
    if (loc.startsWith('/reports')) return 'venue';
    if (loc.startsWith('/kasir')) return 'kasir';
    if (loc.startsWith('/me')) return 'me';
    return 'tables';
  }

  List<String> _crumbsFor(
    String loc,
    String activeTab,
    String zoneName,
    String venueName,
  ) {
    final venue = venueName.isEmpty ? AppStrings.venueHubTitle : venueName;
    switch (activeTab) {
      case 'orders':
        return [AppStrings.crumbTeras, AppStrings.crumbPesananSaya];
      case 'guest':
        return [AppStrings.crumbTeras, AppStrings.crumbPesananMandiri];
      case 'me':
        return ['Maya Anjani', AppStrings.crumbRingkasanShift];
      case 'kitchen':
        return ['Stasiun', AppStrings.crumbAntrianPersiapan];
      case 'venue':
        if (loc.startsWith('/zone-admin')) {
          return [AppStrings.venueHubTitle, AppStrings.zoneAdminTitle];
        }
        if (loc.startsWith('/menuadm')) {
          return [AppStrings.venueHubTitle, AppStrings.crumbMenuAdmin];
        }
        if (loc.startsWith('/system')) {
          return [AppStrings.venueHubTitle, AppStrings.venueHubSectionSystem];
        }
        if (loc.startsWith('/staff')) {
          return [AppStrings.venueHubTitle, AppStrings.crumbStafAkun];
        }
        if (loc.startsWith('/reports')) {
          return [AppStrings.venueHubTitle, AppStrings.crumbLaporanShift];
        }
        return [AppStrings.venueHubTitle, AppStrings.crumbKonfigurasi];
      default:
        return [venue, zoneName];
    }
  }
}

class _FloatingTabBar extends StatelessWidget {
  final String active;
  final int readyCount;
  final bool showKasir;
  final bool showGuest;
  final int guestCount;
  const _FloatingTabBar({
    required this.active,
    required this.readyCount,
    this.showKasir = false,
    this.showGuest = false,
    this.guestCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final bar = Container(
      height: 64,
      decoration: SatBox.d(
        color: SatShape.veil(sc.scrim, 0.92),
        borderRadius: SatR.a(22),
        border: SatB.all(color: sc.border1),
        boxShadow: switch (SatShape.skin) {
          SatSkin.brutal => SatShape.hardShadow(5),
          // Floating chrome is exactly what Glow's larger lift is for.
          SatSkin.glow => SatShape.liftLg,
          SatSkin.lembut => [
            BoxShadow(
              color: satShadowInk.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        },
      ),
      padding: const EdgeInsets.all(Sp.s1),
      child: Row(
        children: [
          _Tab(
            id: 'tables',
            label: AppStrings.tabMeja,
            icon: Icons.grid_view_rounded,
            active: active == 'tables',
            onTap: () => context.go('/tables'),
          ),
          _Tab(
            id: 'orders',
            label: AppStrings.tabPesanan,
            icon: Icons.description_outlined,
            active: active == 'orders',
            badge: readyCount,
            badgeAlert: readyCount > 0,
            onTap: () => context.go('/orders'),
          ),
          if (showGuest)
            _Tab(
              id: 'guest',
              label: AppStrings.tabMandiri,
              icon: Icons.qr_code_2,
              active: active == 'guest',
              badge: guestCount,
              badgeAlert: guestCount > 0,
              onTap: () => context.go('/guestorders'),
            ),
          if (showKasir)
            _Tab(
              id: 'kasir',
              label: AppStrings.tabKasir,
              icon: Icons.point_of_sale_rounded,
              active: active == 'kasir',
              onTap: () => context.go('/kasir'),
            ),
          _Tab(
            id: 'me',
            label: AppStrings.tabSaya,
            icon: Icons.person_outline_rounded,
            active: active == 'me',
            onTap: () => context.go('/me'),
          ),
        ],
      ),
    );
    // Neither the brutal nor the glow skin does frosted glass — an opaque slab
    // on a shadow. Glow's has to fall outside the clip a blur would need.
    if (!SatShape.lembut) return bar;
    return ClipRRect(
      borderRadius: SatR.a(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: bar,
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

  /// Mirrors [TabletSideRail]'s rail button — one active treatment, learned
  /// once, whichever slab the nav happens to live on.
  ///
  /// The rail's brutal-paper case is the one that cannot come across: there the
  /// rail *is* the accent, so both states sit on a bright ground and take ink.
  /// The phone bar is a scrim over the page, so paper behaves like every other
  /// skin here and fills the active tab with the accent.
  Color _fill(SatColors sc) => switch (SatShape.skin) {
    SatSkin.lembut => sc.bg3,
    SatSkin.brutal || SatSkin.glow => sc.accent,
  };

  Color _fg(SatColors sc) {
    if (!active) return sc.textLo;
    return switch (SatShape.skin) {
      SatSkin.lembut => sc.textHi,
      SatSkin.brutal || SatSkin.glow => sc.accentInk,
    };
  }

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
              // Flat under glow, like the rail's pill: the skin lifts cards,
              // not chrome that is already part of the bar. Brutal keeps its
              // ink rule so the active tab reads as a block cut out of the bar.
              decoration: SatBox.d(
                color: active ? _fill(sc) : Colors.transparent,
                borderRadius: SatR.a(18),
                border: SatShape.brutal && active
                    ? SatB.all(color: SatShape.ink)
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: _fg(sc)),
                  const SizedBox(height: Sp.s1),
                  Text(label, style: SatType.bodyS(color: _fg(sc))),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 8,
                right: 22,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Sp.s1),
                  decoration: SatBox.d(
                    color: badgeAlert ? sc.success : sc.accent,
                    borderRadius: SatR.a(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: SatType.caption(
                      color: badgeAlert ? sc.successInk : sc.accentInk,
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
