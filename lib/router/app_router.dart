import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:satset/ui/features/shell/app_shell.dart';
import 'package:satset/ui/features/tables/tables_screen.dart';
import 'package:satset/ui/features/tables/table_detail_screen.dart';
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
import 'package:satset/ui/features/admin/audit_screen.dart';
import 'package:satset/ui/features/admin/kas_screen.dart';
import 'package:satset/ui/features/admin/opname_screen.dart';
import 'package:satset/ui/features/admin/members_screen.dart';
import 'package:satset/ui/features/admin/venue_settings_screen.dart';
import 'package:satset/ui/features/admin/system_screen.dart';
import 'package:satset/ui/features/admin/staff_screen.dart';
import 'package:satset/ui/features/cashier/cashier_screen.dart';
import 'package:satset/ui/features/_book/book_screen.dart';

/// Which capabilities open a location. **Any** of them is enough — a list
/// rather than a single capability because one screen (`/kas`) is genuinely
/// reachable by two unrelated authorities, and encoding that as "the lower one"
/// would lock out an owner whose role happens not to carry it.
List<Capability>? _capabilityFor(String loc) {
  if (loc.startsWith('/kitchen')) return const [Capability.viewKds];
  if (loc.startsWith('/kasir')) return const [Capability.settleBill];
  if (loc.startsWith('/table/') ||
      loc.startsWith('/orders') ||
      loc.startsWith('/order/') ||
      loc.startsWith('/takeaway')) {
    return const [Capability.takeOrder];
  }
  if (loc.startsWith('/venue-settings')) return const [Capability.editSettings];
  if (loc.startsWith('/alerts')) return const [Capability.editSettings];
  if (loc.startsWith('/stock')) return const [Capability.manageIngredients];
  if (loc.startsWith('/reports')) return const [Capability.viewReports];
  // Same permission as reports: both answer "what really happened in my
  // venue". Admin rows inside the log carry a second `manageStaff` check
  // server-side (ADR-0072) — the route gate cannot express that.
  if (loc.startsWith('/audit')) return const [Capability.viewReports];
  // The box has two authorities, per §Kas kecil: `manageCash` posts expenses,
  // `editSettings` funds and counts. Either one opens the screen — `/venue` sits
  // behind `manageStaff`, so the hub cannot be the supervisor's door — and which
  // of the three actions each may take is enforced per-route, server-side.
  if (loc.startsWith('/kas')) {
    return const [Capability.manageCash, Capability.editSettings];
  }
  if (loc.startsWith('/venue/diskon')) return const [Capability.editSettings];
  // The directory-keeper's screen (ADR-0092). Reading it is open to the till
  // server-side, but the till reaches a member through the bill overlay — this
  // route is where records are changed, so it wants the keeper's authority.
  if (loc.startsWith('/members')) return const [Capability.manageMembers];
  // The stocktake archive (ADR-0096). Two authorities, like `/kas`: the person
  // who counts holds `manageIngredients`, the person who reads the variance
  // back holds `viewReports`, and they are rarely the same person.
  if (loc.startsWith('/opname')) {
    return const [Capability.viewReports, Capability.manageIngredients];
  }
  // Each of these mirrors the capability the server already demands of the
  // writes the screen makes. They used to share one `manageStaff` arm, which
  // meant a menu editor holding `editMenu` was bounced to /forbidden and only
  // an admin could open the screen their own capability was made for.
  if (loc.startsWith('/menuadm')) return const [Capability.editMenu];
  if (loc.startsWith('/zone-admin')) return const [Capability.editSettings];
  // `/system` is the seed and sample-data screen; every route behind it is
  // `manageStaff` server-side, and so is the hub that leads to it.
  if (loc.startsWith('/staff') ||
      loc.startsWith('/system') ||
      loc.startsWith('/venue')) {
    return const [Capability.manageStaff];
  }
  return null;
}

/// Holds the one frame between an unmatched location and the bounce to `/pin`.
/// Deliberately blank: the user is about to land on a screen they recognise,
/// and a flash of error copy they have no time to read is worse than nothing.
class _RouteFallback extends StatelessWidget {
  const _RouteFallback();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/pin');
    });
    return const SizedBox.shrink();
  }
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

      // `/book` rides in the bypass set so the gallery renders on a device
      // that has never been paired — which is most of the time you want it.
      const onboardingRoutes = {
        '/pin',
        '/onboarding',
        '/forbidden',
        if (kDebugMode) '/book',
      };

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
      } else if (loggedIn && paired && loc == '/pin') {
        // `paired` is load-bearing, not belt-and-braces. Admin sign-out clears
        // `apiConfigProvider` and the auth state in two steps, and in the gap
        // between them the app is logged in but unpaired — a state this branch
        // used to answer with `/venue`, which the pair gate above immediately
        // bounced back to `/pin`. That ping-pong tripped go_router's redirect
        // limit and put the venue's own admin in front of a bare English
        // "Page Not Found". See ADR-0078.
        final mode = prefs?.appMode() ?? AppMode.unset;
        decision = mode == AppMode.server ? '/venue' : '/tables';
      } else if (loggedIn) {
        final needed = _capabilityFor(loc);
        // Fail-closed: none of the route's capabilities denies the route.
        if (needed != null && !needed.any(auth.has)) {
          decision = '/forbidden';
        }
      }
      if (decision != null && decision != loc) {
        SatLog.nav('redirect $loc → $decision');
      }
      return decision;
    },
    // No location in the app is allowed to go unmatched, so reaching here is a
    // bug — but a bug that used to surface as go_router's bare English "Page
    // Not Found" in front of a waiter mid-shift. Log the location that failed
    // (the only way to name it after the fact) and land on `/pin`, which is
    // safe for every session kind: the redirect above bounces a super admin
    // straight to `/fleet` and a report owner to `/owner`. See ADR-0078.
    errorBuilder: (_, state) {
      SatLog.nav('route not found: ${state.uri} err=${state.error}');
      return const _RouteFallback();
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const ModeSelectScreen()),
      GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      // Debug-only widget gallery. `kDebugMode` is a const, so in a release
      // build this route and the PinScreen button that reaches it are both
      // tree-shaken away.
      if (kDebugMode)
        GoRoute(path: '/book', builder: (_, _) => const BookScreen()),
      GoRoute(path: '/fleet', builder: (_, _) => const FleetConsoleScreen()),
      GoRoute(path: '/owner', builder: (_, _) => const OwnerReportScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/kitchen', builder: (_, _) => const KitchenScreen()),
          GoRoute(path: '/kasir', builder: (_, _) => const CashierScreen()),
          GoRoute(path: '/venue', builder: (_, _) => const VenueHubScreen()),
          GoRoute(
            path: '/venue-settings',
            builder: (_, _) => const VenueSettingsScreen(),
          ),
          GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
          GoRoute(
            path: '/zone-admin',
            builder: (_, _) => const ZoneAdminScreen(),
          ),
          GoRoute(path: '/menuadm', builder: (_, _) => const MenuAdminScreen()),
          GoRoute(path: '/stock', builder: (_, _) => const StockScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/audit', builder: (_, _) => const AuditScreen()),
          GoRoute(path: '/kas', builder: (_, _) => const KasScreen()),
          GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
          GoRoute(path: '/opname', builder: (_, _) => const OpnameScreen()),
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
        builder: (_, s) => TableDetailScreen(tableId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (_, s) => MenuScreen(tableId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'review',
            builder: (_, s) => ReviewScreen(tableId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'sent',
            builder: (_, s) {
              final stations = (s.uri.queryParameters['stations'] ?? 'Dapur')
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
        builder: (_, s) => MenuAdminItemScreen(id: s.pathParameters['id']!),
      ),
      // Preset diskon catalogue (ADR-0037), pushed from Venue Settings.
      GoRoute(
        path: '/venue/diskon',
        builder: (_, _) => const DiscountPresetsScreen(),
      ),
    ],
  );
});
