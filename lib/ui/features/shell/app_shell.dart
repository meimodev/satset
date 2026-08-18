import 'dart:ui';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/send_queue_drain.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/ui/features/shell/send_result_dialog.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/widgets/admin_grace_banner.dart';
import 'package:satset/ui/core/widgets/update_banner.dart';
import 'package:satset/ui/core/widgets/venue_billing_banner.dart';
import 'package:satset/ui/core/widgets/exit_guard.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';

/// First path segment of [loc], e.g. `/menuadm` for `/menuadm/42`. Shell routes
/// are matched on this rather than on `startsWith`, so a destination can never
/// be swallowed by a shorter sibling — `/menuadm` used to answer to `/me`.
String _firstSegment(String loc) {
  final parts = loc.split('/');
  return parts.length > 1 ? '/${parts[1]}' : '/';
}

/// Shell routes that are a rail destination in their own right. Everything not
/// listed belongs to the Venue hub — the default points at `venue`, not
/// `tables`. See ADR-0058:
/// the hub grows children (Stok, Peringatan, …) far more often than the app
/// grows top-level destinations, and an unlisted hub child used to light up
/// Meja. A *new top-level destination* must be added here or it will read as
/// Venue.
///
/// Route → rail id. Stays `const` and label-free so [activeTabFor] remains a
/// pure function: which tab owns a path is a routing fact, not a display one,
/// and it is asked for by tests and by `redirect` where no locale exists.
/// Naming is [railLabel]'s job.
const _railRoutes = <String, String>{
  '/tables': 'tables',
  '/orders': 'orders',
  '/kitchen': 'kitchen',
  '/kasir': 'kasir',
  '/me': 'me',
};

/// The name a rail destination goes by — the same entry the rail button renders,
/// so the trail and the rail cannot disagree about what a destination is called.
String? railLabel(AppL10n l10n, String railId) => switch (railId) {
  'tables' => l10n.tabMeja,
  'orders' => l10n.tabPesanan,
  'kitchen' => l10n.tabAntrian,
  'kasir' => l10n.tabKasir,
  'me' => l10n.tabSaya,
  _ => null,
};

/// Venue hub children → their crumb trail's tail segment. One table feeds both
/// the rail (anything absent is `venue`) and the crumb, so the two can no longer
/// drift apart the way two parallel switches did. A hub path with no entry gets
/// the bare `[Venue]` trail rather than borrowing another screen's label.
String? venueHubCrumb(AppL10n l10n, String path) => switch (path) {
  '/venue-settings' => l10n.crumbKonfigurasi,
  '/alerts' => l10n.alertsTitle,
  '/zone-admin' => l10n.zoneAdminTitle,
  '/menuadm' => l10n.crumbMenuAdmin,
  '/stock' => l10n.venueHubSectionStock,
  '/reports' => l10n.crumbLaporanShift,
  '/system' => l10n.venueHubSectionSystem,
  '/staff' => l10n.crumbStafAkun,
  _ => null,
};

/// Which rail item owns [loc].
String activeTabFor(String loc) => _railRoutes[_firstSegment(loc)] ?? 'venue';

/// The crumb trail for [loc], *without* the venue name — `SatAppBar` prepends
/// that for every trail in the app, shell or pushed, so it is not repeated here.
///
/// One shape, no per-route cases: the destination that owns [loc], then the hub
/// child's own label if it is one. `/me`'s tail is [userName] instead of `Saya`:
/// on shared hardware "which account am I in?" is a live question, and the rail
/// avatar shows initials only. An unnamed user falls back to the label.
List<String> crumbsFor(AppL10n l10n, String loc, String userName) {
  final id = _railRoutes[_firstSegment(loc)];
  if (id == null) {
    // Venue hub: the hub itself, then the child screen if this path is one.
    return [l10n.tabVenue, ?venueHubCrumb(l10n, _firstSegment(loc))];
  }
  return [id == 'me' && userName.isNotEmpty ? userName : railLabel(l10n, id)!];
}

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    // Nobody else holds it, and a drain trigger nobody holds never subscribes.
    // The shell outlives every tab, which is the lifetime a backlog needs.
    ref.watch(sendQueueDrainProvider);
    // A clean drain stays silent — the lines landing on the table say it. Only
    // a refusal, a stock drop or a stalled drain is worth a blocking overlay.
    ref.listen<SendReport?>(sendReportProvider, (_, r) {
      if (r == null) return;
      ref.read(sendReportProvider.notifier).state = null;
      if (r.failures.isEmpty && !r.interrupted) return;
      showSendResultDialog(context, r);
    });
    // The transport error bus. Repositories push here from anywhere; the shell
    // is the only subscriber, because it is the only widget that outlives the
    // screen an error was raised on (ADR-0103).
    ref.listen<AsyncValue<AppError>>(appErrorProvider, (_, next) {
      final err = next.value;
      if (err == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final tone = switch (err.level) {
        AppErrorLevel.error => sc.urgent,
        AppErrorLevel.warning => sc.warn,
        AppErrorLevel.info => sc.info,
      };
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: sc.bg2,
            content: Row(
              children: [
                Container(
                  width: Sp.s1,
                  height: Sp.s5,
                  decoration: SatBox.d(color: tone, borderRadius: SatR.a(2)),
                ),
                const SizedBox(width: Sp.s3),
                Expanded(
                  child: Text(
                    err.message,
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                ),
              ],
            ),
          ),
        );
    });
    final ready = ref.watch(totalReadyCountProvider);
    final kitchenCount = ref.watch(kitchenNewOrderCountProvider);
    final loc = GoRouterState.of(context).uri.path;
    final l = context.layout;

    final activeTab = activeTabFor(loc);
    final showKasir = ref.watch(authStateProvider).has(Capability.settleBill);
    final userName = ref.watch(
      authStateProvider.select((s) => s.user?.name ?? ''),
    );

    if (l.useTabletShell) {
      return ExitGuard(
        child: TabletShell(
          activeTab: activeTab,
          readyCount: ready,
          kitchenCount: kitchenCount,
          showKasir: showKasir,
          crumbs: crumbsFor(context.l10n, loc, userName),
          child: Column(
            children: [
              // Connectivity before commerce: the grace banner is a countdown to
              // the server refusing to boot, which is operational and immediate.
              // A subscription is neither.
              const AdminGraceBanner(),
              const VenueBillingBanner(),
              const UpdateBanner(),
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
            const VenueBillingBanner(),
            const UpdateBanner(),
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
}

class _FloatingTabBar extends StatelessWidget {
  final String active;
  final int readyCount;
  final bool showKasir;
  const _FloatingTabBar({
    required this.active,
    required this.readyCount,
    this.showKasir = false,
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
            label: context.l10n.tabMeja,
            icon: Icons.grid_view_rounded,
            active: active == 'tables',
            onTap: () => context.go('/tables'),
          ),
          _Tab(
            id: 'orders',
            label: context.l10n.tabPesanan,
            icon: Icons.description_outlined,
            active: active == 'orders',
            badge: readyCount,
            badgeAlert: readyCount > 0,
            onTap: () => context.go('/orders'),
          ),
          if (showKasir)
            _Tab(
              id: 'kasir',
              label: context.l10n.tabKasir,
              icon: Icons.point_of_sale_rounded,
              active: active == 'kasir',
              onTap: () => context.go('/kasir'),
            ),
          _Tab(
            id: 'me',
            label: context.l10n.tabSaya,
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
