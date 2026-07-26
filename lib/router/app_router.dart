import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/log/sat_nav_observer.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/features/auth/views/pin_screen.dart';
import 'package:satset/ui/features/fleet/fleet_console_screen.dart';
import 'package:satset/ui/features/owner/owner_report_screen.dart';
import 'package:satset/ui/features/onboarding/views/forbidden_screen.dart';
import 'package:satset/ui/features/onboarding/views/mode_select_screen.dart';
import 'package:satset/ui/features/onboarding/views/pair_screen.dart';
import 'package:satset/ui/features/shell/app_shell.dart';
import 'package:satset/ui/features/tables/tables_screen.dart';
import 'package:satset/ui/features/tables/table_detail_screen.dart';
import 'package:satset/ui/features/guest_orders/guest_orders_screen.dart';
import 'package:satset/ui/features/orders/orders_screen.dart';
import 'package:satset/ui/features/me/me_screen.dart';
import 'package:satset/ui/features/menu/menu_screen.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/ui/features/review/review_screen.dart';
import 'package:satset/ui/features/sent/sent_screen.dart';
import 'package:satset/ui/features/takeaway/takeaway_detail_screen.dart';
import 'package:satset/ui/features/admin/discount_presets_screen.dart';
import 'package:satset/ui/features/admin/kitchen_screen.dart';
import 'package:satset/ui/features/admin/zone_admin_screen.dart';
import 'package:satset/ui/features/admin/menu_admin_screen.dart';
import 'package:satset/ui/features/admin/stock_screen.dart';
import 'package:satset/ui/features/admin/menu_admin_item_screen.dart';
import 'package:satset/ui/features/admin/reports_screen.dart';
import 'package:satset/ui/features/admin/venue_hub_screen.dart';
import 'package:satset/ui/features/admin/alerts_screen.dart';
import 'package:satset/ui/features/admin/venue_settings_screen.dart';
import 'package:satset/ui/features/admin/system_screen.dart';
import 'package:satset/ui/features/admin/staff_screen.dart';
import 'package:satset/ui/features/cashier/cashier_screen.dart';

Capability? _capabilityFor(String loc) {
  if (loc.startsWith('/kitchen')) return Capability.viewKds;
  if (loc.startsWith('/kasir')) return Capability.settleBill;
  if (loc.startsWith('/table/') ||
      loc.startsWith('/orders') ||
      loc.startsWith('/order/') ||
      loc.startsWith('/guestorders') ||
      loc.startsWith('/takeaway')) {
    return Capability.takeOrder;
  }
  if (loc.startsWith('/venue-settings')) return Capability.editSettings;
  if (loc.startsWith('/alerts')) return Capability.editSettings;
  if (loc.startsWith('/stock')) return Capability.manageIngredients;
  if (loc.startsWith('/reports')) return Capability.viewReports;
  if (loc.startsWith('/venue/diskon')) return Capability.editSettings;
  if (loc.startsWith('/menuadm') || loc.startsWith('/staff') ||
      loc.startsWith('/system') ||
      loc.startsWith('/zone-admin') || loc.startsWith('/venue')) {
    return Capability.manageStaff;
  }
  return null;
}

class _RouterRefresh extends ChangeNotifier {
  void bump() {
    if (hasListeners) notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  // Re-evaluate redirects when auth or prefs change without re-creating the
  // GoRouter instance. Rebuilding the provider would replace MaterialApp's
  // routerConfig and reset Navigator state mid-sign-in.
  ref.listen(authStateProvider, (_, _) => refresh.bump());
  ref.listen(prefsServiceProvider, (_, _) => refresh.bump());
  ref.listen(apiConfigProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/pin',
    refreshListenable: refresh,
    observers: [SatNavObserver()],
    redirect: (context, state) async {
      final loc = state.uri.path;
      final auth = ref.read(authStateProvider);
      final prefs = ref.read(prefsServiceProvider).valueOrNull;
      final paired = ref.read(apiConfigProvider) != null;
      final loggedIn = auth.isAuthenticated;
      String? decision;

      const onboardingRoutes = {'/pin', '/onboarding', '/pair', '/forbidden'};

      // Fleet super admin: a cloud-only session with no local server and no
      // pairing. It bypasses the hard pair gate entirely and owns `/fleet`.
      // See ADR-0016.
      if (auth.isSuperAdmin) {
        if (loc != '/fleet') decision = '/fleet';
        if (decision != null && decision != loc) {
          SatLog.nav('redirect $loc → $decision');
        }
        return decision;
      }
      // Report owner: a cloud-only read-only session, no server, no pairing. It
      // owns `/owner` and bypasses the hard pair gate like the super admin.
      // See ADR-0036.
      if (auth.isOwner) {
        if (loc != '/owner') decision = '/owner';
        if (decision != null && decision != loc) {
          SatLog.nav('redirect $loc → $decision');
        }
        return decision;
      }
      // A non-super may never sit on the fleet route; a non-owner never on /owner.
      if (loc == '/fleet' || loc == '/owner') {
        decision = '/pin';
      } else
      // Hard pair-required gate: until ApiConfig is populated nothing else
      // may render — repos start empty so any data screen would be blank
      // anyway, and we never want to ship UI that depends on stale memory.
      // PinScreen carries the inline mode-select + pair flow that populates
      // apiConfigProvider.
      if (!paired && !onboardingRoutes.contains(loc)) {
        decision = '/pin';
      } else if (!loggedIn && !onboardingRoutes.contains(loc)) {
        decision = '/pin';
      } else if (loggedIn && loc == '/pin') {
        final mode = prefs?.appMode() ?? AppMode.unset;
        decision = mode == AppMode.server ? '/venue' : '/tables';
      } else if (loggedIn) {
        final needed = _capabilityFor(loc);
        // Fail-closed: missing capability denies the route.
        if (needed != null && !auth.has(needed)) {
          decision = '/forbidden';
        }
      }
      if (decision != null && decision != loc) {
        SatLog.nav('redirect $loc → $decision');
      }
      return decision;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const ModeSelectScreen()),
      GoRoute(path: '/pair', builder: (_, _) => const PairScreen()),
      GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      GoRoute(path: '/fleet', builder: (_, _) => const FleetConsoleScreen()),
      GoRoute(path: '/owner', builder: (_, _) => const OwnerReportScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(
              path: '/guestorders',
              builder: (_, _) => const GuestOrdersScreen()),
          GoRoute(path: '/kitchen', builder: (_, _) => const KitchenScreen()),
          GoRoute(path: '/kasir', builder: (_, _) => const CashierScreen()),
          GoRoute(path: '/venue', builder: (_, _) => const VenueHubScreen()),
          GoRoute(
              path: '/venue-settings',
              builder: (_, _) => const VenueSettingsScreen()),
          GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
          GoRoute(path: '/zone-admin', builder: (_, _) => const ZoneAdminScreen()),
          GoRoute(path: '/menuadm', builder: (_, _) => const MenuAdminScreen()),
          GoRoute(path: '/stock', builder: (_, _) => const StockScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/system', builder: (_, _) => const SystemScreen()),
          GoRoute(path: '/staff', builder: (_, _) => const StaffScreen()),
          GoRoute(path: '/me', builder: (_, _) => const MeScreen()),
        ],
      ),
      // Table flow lives outside the shell so a root-navigator push gives a
      // full-page transition. Nesting it under ShellRoute caused the outgoing
      // tables page to flash bare during the push (AppShell rebuilds with
      // the new loc and removes its Scaffold before the transition ends).
      GoRoute(
        path: '/table/:id',
        builder: (_, s) =>
            TableDetailScreen(tableId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (_, s) =>
                MenuScreen(tableId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'review',
            builder: (_, s) =>
                ReviewScreen(tableId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'sent',
            builder: (_, s) {
              final stations =
                  (s.uri.queryParameters['stations'] ?? 'Dapur')
                      .split(',')
                      .where((x) => x.isNotEmpty)
                      .toList();
              return SentScreen(
                tableId: s.pathParameters['id']!,
                stations: stations.isEmpty ? const ['Dapur'] : stations,
              );
            },
          ),
        ],
      ),
      // Table-less menu-first draft flow (ADR-0026). Lives outside the shell
      // like the table flow so pushes get full-page transitions. The cart key
      // is the transient draftOrderIdProvider uuid; the table is chosen at the
      // review/commit step.
      GoRoute(
        path: '/order/new',
        builder: (_, _) => Consumer(
          builder: (_, ref, _) => MenuScreen(
            tableId: ref.watch(draftOrderIdProvider),
            tableless: true,
          ),
        ),
        routes: [
          GoRoute(
            path: 'review',
            builder: (_, _) => Consumer(
              builder: (_, ref, _) => ReviewScreen(
                tableId: ref.watch(draftOrderIdProvider),
                tableless: true,
              ),
            ),
          ),
        ],
      ),
      // Takeaway (Bawa pulang) detail + add-items flow (ADR-0026). Outside the
      // shell for full-page transitions, like the table flow. The cart key is
      // the takeaway visit id.
      GoRoute(
        path: '/takeaway/:visitId',
        builder: (_, s) =>
            TakeawayDetailScreen(visitId: s.pathParameters['visitId']!),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (_, s) => MenuScreen(
              tableId: s.pathParameters['visitId']!,
              tableless: true,
              takeawayVisitId: s.pathParameters['visitId']!,
            ),
          ),
          GoRoute(
            path: 'review',
            builder: (_, s) => ReviewScreen(
              tableId: s.pathParameters['visitId']!,
              tableless: true,
              takeawayVisitId: s.pathParameters['visitId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/menuadm/:id',
        builder: (_, s) =>
            MenuAdminItemScreen(id: s.pathParameters['id']!),
      ),
      // Preset diskon catalogue (ADR-0037), pushed from Venue Settings.
      GoRoute(
        path: '/venue/diskon',
        builder: (_, _) => const DiscountPresetsScreen(),
      ),
    ],
  );
});
