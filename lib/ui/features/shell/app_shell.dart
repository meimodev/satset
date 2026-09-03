import 'dart:ui';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/data/services/member_mirror.dart';
import 'package:satset/data/services/send_queue_drain.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/ui/features/shell/send_result_dialog.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/discount_presets_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/self_order_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
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
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';

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
  '/counter': 'counter',
  '/tables': 'tables',
  '/orders': 'orders',
  '/kitchen': 'kitchen',
  '/kasir': 'kasir',
  '/selforder': 'tamu',
  '/me': 'me',
};

/// The name a rail destination goes by — the same entry the rail button renders,
/// so the trail and the rail cannot disagree about what a destination is called.
String? railLabel(AppL10n l10n, String railId) => switch (railId) {
  'counter' => l10n.tabMenu,
  'tables' => l10n.tabMeja,
  'orders' => l10n.tabPesanan,
  'kitchen' => l10n.tabAntrian,
  'kasir' => l10n.tabKasir,
  'tamu' => l10n.tabTamu,
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
  '/selforder-admin' => l10n.soAdminTitle,
  '/venue-day' => l10n.vdayTitle,
  _ => null,
};

/// Whether the guest-queue destination exists for this user (ADR-0106).
///
/// Two conditions, both necessary: the guest socket is bound at all, and this
/// person is the one who decides a guest order. A destination that renders an
/// "off" empty state to a waiter is a tab that costs a tap to learn nothing.
bool showGuestQueue({
  required bool guestOrderingEnabled,
  required bool canTakeOrder,
}) => guestOrderingEnabled && canTakeOrder;

/// Whether the home destination is the menu rather than the floor — the
/// [[Kedai]] switch `menuHome` (ADR-0109).
///
/// **Hide, don't refuse.** `/tables` stays a legal route and every table row
/// stays written; what the switch changes is which destination the rail offers
/// and where a sign-in lands. A counter shop with four stools can still be
/// walked to its floor by a deep link, and flipping the switch back finds the
/// tables exactly as they were.
///
/// [canTakeOrder] because the destination *is* the order pad: showing it to a
/// cashier who cannot open an order buys a tab that 403s.
bool showCounterHome({
  required bool menuHomeEnabled,
  required bool canTakeOrder,
}) => menuHomeEnabled && canTakeOrder;

/// Whether the [[KDS / Antrian Persiapan]] slot belongs on the rail (ADR-0115).
///
/// [[Tanpa antrian persiapan]] removes it, with two deliberate survivals — both
/// of which *show* rather than refuse, because the route itself stays legal:
///
/// * [queueLive] — flipping the mode on mid-shift leaves lines already cooking,
///   and `sent → served` is not a waiter's move. The slot outlives its own
///   removal until the last of them is out, then disappears on its own.
/// * [kdsOnlyUser] — a cook whose role is `viewKds` and nothing else lands on
///   `/kitchen`. Hiding the slot from *them* is the one case where hiding is
///   indistinguishable from locking the device.
bool showKdsSlot({
  required bool bypassKds,
  required bool queueLive,
  required bool kdsOnlyUser,
}) => !bypassKds || queueLive || kdsOnlyUser;

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
    // Warm the [[Preset diskon]] catalogue here rather than at the picker
    // (ADR-0128). The repository is lazy, so the first watch used to be the
    // cashier opening the sheet — and if that first watch happened on a dark
    // handset the fetch failed and the list stayed empty until reconnect.
    // Constructing it on the shell means the cache is painted and the fetch is
    // spent while the venue still has a host.
    ref.watch(discountPresetsRepositoryProvider);
    // The [[Salinan pelanggan]] fills here for the same reason, and with more
    // riding on it: its whole value is being *already there* when the host goes
    // away, so nothing may wait for a cashier to open the lookup sheet
    // (ADR-0129).
    ref.watch(memberMirrorSyncProvider);
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
    final showKasir = ref.watch(
      authStateProvider.select((s) => s.has(Capability.settleBill)),
    );
    // [[Pesan mandiri]] (ADR-0106). Off means the guest socket does not exist,
    // so the destination does not either — this is not a screen worth showing
    // empty. `takeOrder` because the one act on it is deciding a guest order.
    final showTamu = showGuestQueue(
      guestOrderingEnabled: ref.watch(
        venueSettingsProvider.select((v) => v.guestOrderingOn),
      ),
      canTakeOrder: ref.watch(
        authStateProvider.select((s) => s.has(Capability.takeOrder)),
      ),
    );
    final guestPending = showTamu
        ? ref.watch(selfOrderProvider.select((s) => s.pending.length))
        : 0;
    final showKds = showKdsSlot(
      bypassKds: ref.watch(venueSettingsProvider.select((v) => v.bypassKds)),
      queueLive: ref.watch(kitchenQueueLiveProvider),
      kdsOnlyUser: ref.watch(
        authStateProvider.select(
          (s) =>
              s.has(Capability.viewKds) && !s.has(Capability.takeOrder),
        ),
      ),
    );
    final counterHome = showCounterHome(
      menuHomeEnabled: ref.watch(
        venueSettingsProvider.select((v) => v.counterOn(counterMenuHome)),
      ),
      canTakeOrder: ref.watch(
        authStateProvider.select((s) => s.has(Capability.takeOrder)),
      ),
    );
    final userName = ref.watch(
      authStateProvider.select((s) => s.user?.name ?? ''),
    );

    if (l.useTabletShell) {
      return ExitGuard(
        child: TabletShell(
          activeTab: activeTab,
          readyCount: ready,
          kitchenCount: kitchenCount,
          showKds: showKds,
          showKasir: showKasir,
          showTamu: showTamu,
          counterHome: counterHome,
          guestPending: guestPending,
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
                  // The bar floats over the page, so the page is told how
                  // much of its own bottom it cannot use. Nothing below this
                  // point re-derives the number from MediaQuery.
                  Positioned.fill(
                    child: ShellInset(
                      bottom: _tabBarGap + _tabBarHeight,
                      child: child,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: _tabBarGap,
                    child: _FloatingTabBar(
                      active: activeTab,
                      readyCount: ready,
                      showKasir: showKasir,
                      showTamu: showTamu,
                      counterHome: counterHome,
                      guestPending: guestPending,
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

/// Geometry of the floating phone tab bar, in one place. `ShellInset`
/// publishes the sum downward, so no screen re-guesses either number.
const double _tabBarGap = 12;
const double _tabBarHeight = 64;

class _FloatingTabBar extends StatelessWidget {
  final String active;
  final int readyCount;
  final bool showKasir;
  final bool showTamu;
  final bool counterHome;
  final int guestPending;
  const _FloatingTabBar({
    required this.active,
    required this.readyCount,
    this.showKasir = false,
    this.showTamu = false,
    this.counterHome = false,
    this.guestPending = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final bar = Container(
      height: _tabBarHeight,
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
          // One slot, two destinations (ADR-0109): the home tab is the floor
          // or the menu, never both — a counter shop that keeps its floor tab
          // has learned two ways to start an order and picks the wrong one
          // under pressure.
          if (counterHome)
            _Tab(
              id: 'counter',
              label: context.l10n.tabMenu,
              icon: Icons.restaurant_menu_rounded,
              active: active == 'counter',
              onTap: () => context.go('/counter'),
            )
          else
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
          if (showTamu)
            _Tab(
              id: 'tamu',
              label: context.l10n.tabTamu,
              icon: Icons.qr_code_2_outlined,
              active: active == 'tamu',
              // Accent, not the alert green: green is the ready-line meaning
              // already learned one tab to the left, and a waiting guest is a
              // job to pick up rather than a plate to run.
              badge: guestPending,
              onTap: () => context.go('/selforder'),
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
