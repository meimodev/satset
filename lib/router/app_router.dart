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
import 'package:satset/ui/features/admin/expense_categories_screen.dart';
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
import 'package:satset/ui/features/admin/self_order_admin_screen.dart';
import 'package:satset/ui/features/admin/self_order_screen.dart';
import 'package:satset/ui/features/admin/member_report_screen.dart';
import 'package:satset/ui/features/admin/opname_screen.dart';
import 'package:satset/ui/features/admin/members_screen.dart';
import 'package:satset/ui/features/admin/venue_day_screen.dart';
import 'package:satset/ui/features/admin/venue_settings_screen.dart';
import 'package:satset/ui/features/admin/system_screen.dart';
import 'package:satset/ui/features/admin/staff_screen.dart';
import 'package:satset/ui/features/cashier/cashier_screen.dart';
import 'package:satset/ui/features/_book/book_screen.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';

/// Which capabilities open a location. **Any** of them is enough — a list
/// rather than a single capability because one screen (`/kas`) is genuinely
/// reachable by two unrelated authorities, and encoding that as "the lower one"
/// would lock out an owner whose role happens not to carry it.
List<Capability>? capabilitiesFor(String loc) {
  if (loc.startsWith('/kitchen')) return const [Capability.viewKds];
  if (loc.startsWith('/kasir')) return const [Capability.settleBill];
  if (loc.startsWith('/table/') ||
      loc.startsWith('/orders') ||
      loc.startsWith('/order/') ||
      // The [[Kedai]] home tab (ADR-0109) — the same table-less draft flow
      // `/order/new` opens, mounted inside the shell so the rail survives it.
      loc.startsWith('/counter') ||
      loc.startsWith('/takeaway')) {
    return const [Capability.takeOrder];
  }
  if (loc.startsWith('/venue-settings')) return const [Capability.editSettings];
  // Buka / tutup kedai (ADR-0111). Two authorities, and the two the act is
  // actually made of: `openDrawer` opens, `closeShift` closes. Either one opens
  // the screen — the person who unlocks in the morning and the person who
  // counts at night are often not the same — and each half renders only for
  // whoever holds it. Matched **before** the bare `/venue` arm below, which is
  // a prefix of this path and would otherwise put it behind `manageStaff`.
  if (loc.startsWith('/venue-day')) {
    return const [Capability.openDrawer, Capability.closeShift];
  }
  if (loc.startsWith('/alerts')) return const [Capability.editSettings];
  // Stock has two authorities, cut between the catalogue and the ledger
  // (ADR-0132): `manageIngredients` authors a bahan, `adjustStock` moves its
  // numbers. Either one opens the screen and each half renders for whoever
  // holds it — the `/kas` shape. Narrowing to `manageIngredients` is what left
  // the seeded Manager, who holds only `adjustStock`, bounced to /forbidden
  // from the screen their capability is named after.
  if (loc.startsWith('/stock')) {
    return const [Capability.manageIngredients, Capability.adjustStock];
  }
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
  // [[Pesan mandiri]], configuration half (ADR-0106) — codes, guest menu,
  // rules. One authority, matching the writes: every route this screen calls
  // demands `editSettings` server-side. Must be tested before `/selforder`,
  // which is a prefix of it.
  if (loc.startsWith('/selforder-admin')) {
    return const [Capability.editSettings];
  }
  // The queue (ADR-0105, ADR-0106). Two authorities, like `/kas`: `takeOrder`
  // decides a guest's order, which is a waiter's act and why this is a nav
  // destination rather than a hub child; `editSettings` is kept because the
  // server hands an owner the queue read, and narrowing the client to
  // `takeOrder` would lock them out of a screen they are allowed to see.
  if (loc.startsWith('/selforder')) {
    return const [Capability.takeOrder, Capability.editSettings];
  }
  if (loc.startsWith('/venue/diskon')) return const [Capability.editSettings];
  // The venue's own [[Pengeluaran kunjungan]] vocabulary (ADR-0130). The
  // owner's authority, like the preset catalogue beside it.
  if (loc.startsWith('/venue/pengeluaran')) {
    return const [Capability.editSettings];
  }
  // The member report. Two authorities, like `/kas` and `/opname`: the person
  // who enrols the guests keeps the directory, the person who reads their
  // spending back reads reports, and they are rarely the same one. Matched
  // before `/members` for legibility — the paths do not actually collide, and
  // a later rename that made them collide would be silent.
  if (loc.startsWith('/member-report')) {
    return const [Capability.viewReports, Capability.manageMembers];
  }
  // The directory-keeper's screen (ADR-0092). Reading it is open to the till
  // server-side, but the till reaches a member through the bill overlay — this
  // route is where records are changed, so it wants the keeper's authority.
  if (loc.startsWith('/members')) return const [Capability.manageMembers];
  // The stocktake archive (ADR-0096). Three authorities: the person who reads
  // the variance back holds `viewReports`, and *either* stock capability opens
  // it, because ADR-0132 §1 puts the count itself wholly on the ledger side —
  // gating the archive on `manageIngredients` alone left the holder of
  // `adjustStock`, who walks the count, locked out of their own closed
  // sessions. Reads take either capability; that is the same rule.
  if (loc.startsWith('/opname')) {
    return const [
      Capability.viewReports,
      Capability.manageIngredients,
      Capability.adjustStock,
    ];
  }
  // Each of these mirrors the capability the server already demands of the
  // writes the screen makes. They used to share one `manageStaff` arm, which
  // meant a menu editor holding `editMenu` was bounced to /forbidden and only
  // an admin could open the screen their own capability was made for.
  // Two authorities, and the menu list is where the second one is spent:
  // `markSoldOut` is the staff availability toggle (CONTEXT.md §soldOut), and
  // the seeded Kitchen role holds it with no `editMenu`, so gating on `editMenu`
  // alone left that capability enforced server-side and reachable from nowhere.
  // A `markSoldOut`-only holder gets the list and the toggle, nothing else —
  // see `menuPermissionProvider`.
  if (loc.startsWith('/menuadm')) {
    return const [Capability.editMenu, Capability.markSoldOut];
  }
  if (loc.startsWith('/zone-admin')) return const [Capability.editSettings];
  // `/system` is the seed and sample-data screen; every route behind it is
  // `manageStaff` server-side, and so is the hub that leads to it.
  if (loc.startsWith('/staff') || loc.startsWith('/system')) {
    return const [Capability.manageStaff];
  }
  // The hub itself is a **catalogue, not an authority** (ADR-0134). It used to
  // share the `manageStaff` arm above, which made an admin capability the door
  // to `/stock`, `/kas`, `/opname` and `/reports` — screens whose own gates say
  // somebody else entirely. Now it opens to whoever can open at least one thing
  // inside it, and the tiles filter to exactly those. `/venue-settings`,
  // `/venue-day`, `/venue/diskon` and `/venue/pengeluaran` are matched by their
  // own arms above; this one is the bare hub.
  if (loc.startsWith('/venue')) return venueHubCapabilities;
  return null;
}

/// Every capability that opens *something* on the Venue hub, derived from the
/// hub's own tile list. Holding one of them is what makes the hub worth
/// entering — and it is the same predicate the rail spends to decide whether
/// the Venue slot renders, so a visible slot can never bounce to `/forbidden`.
final venueHubCapabilities = <Capability>{
  for (final r in venueHubRoutes) ...?capabilitiesFor(r),
}.toList(growable: false);

/// Where a fresh sign-in lands.
///
/// Server mode lands on the Venue hub — **unless this person holds nothing
/// that opens it**, which used to end a successful sign-in on `/forbidden`
/// (a waiter signing in on the host tablet). The hub's gate is computable
/// now, so the landing asks it (ADR-0134). Everyone else lands on the home
/// destination, which a [[Kedai]] moves to the menu (ADR-0109).
///
/// Pure, and separated from `redirect` so it can be tested without a router:
/// the three inputs are all the answer depends on.
String landingFor({
  required AppMode mode,
  required bool hubOpens,
  required bool counterHome,
}) {
  if (mode == AppMode.server && hubOpens) return '/venue';
  return counterHome ? '/counter' : '/tables';
}

/// Whether [auth] may open [loc] — the redirect's own test, exposed so a
/// surface that *offers* a route uses the same answer as the guard that
/// enforces it. An ungated route (null) is open, exactly as `redirect` reads it.
bool canOpenRoute(AuthState auth, String loc) {
  final needed = capabilitiesFor(loc);
  return needed == null || needed.any(auth.has);
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

/// Whether this session's home is the [[Kedai]] menu rather than the floor
/// (ADR-0109). Read, not watched — `redirect` is not a build, and it re-runs
/// off the refresh listenable, which venue settings feed.
bool counterHome(Ref ref, AuthState auth) => showCounterHome(
  menuHomeEnabled: ref.read(venueSettingsProvider).counterOn(counterMenuHome),
  canTakeOrder: auth.has(Capability.takeOrder),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  // Re-evaluate redirects when auth or prefs change without re-creating the
  // GoRouter instance. Rebuilding the provider would replace MaterialApp's
  // routerConfig and reset Navigator state mid-sign-in.
  ref.listen(authStateProvider, (_, _) => refresh.bump());
  ref.listen(prefsServiceProvider, (_, _) => refresh.bump());
  ref.listen(apiConfigProvider, (_, _) => refresh.bump());
  // A freshly paired client signs in before `/venue/settings` has answered, so
  // the counter switch is false for a beat. Bump when it lands or the venue
  // would sit on a floor it does not use until the next navigation.
  //
  // The *status* provider, deliberately, not the settings themselves:
  // `VenueSettingsRepository` fetches once from its constructor and gives up
  // when nothing is paired yet, so listening to it here would build it at app
  // start — before pairing — and leave the venue on defaults forever.
  ref.listen(venueSettingsStatusProvider, (_, _) => refresh.bump());
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
        decision = landingFor(
          mode: prefs?.appMode() ?? AppMode.unset,
          hubOpens: venueHubCapabilities.any(auth.has),
          counterHome: counterHome(ref, auth),
        );
      } else if (loggedIn) {
        // A counter shop has no floor (ADR-0109): its home tab is the menu and
        // nothing offers `/tables`. Anything still pointing there — an order
        // flow's back fallback, a stale deep link, or the landing decision
        // above taken in the beat before venue settings arrived on a freshly
        // paired client — belongs on the menu instead.
        if (loc == '/tables' && counterHome(ref, auth)) {
          decision = '/counter';
        }
        final needed = capabilitiesFor(loc);
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
          // [[Kedai]] home (ADR-0109). Deliberately the *same* screen and the
          // same cart key as `/order/new` — a counter has one order pad, and a
          // second draft flow with its own cart is how an order gets typed
          // twice. What differs is only that this one lives inside the shell,
          // so a cashier can reach the till without leaving the pad first.
          GoRoute(
            path: '/counter',
            builder: (_, _) => Consumer(
              builder: (_, ref, _) => MenuScreen(
                tableId: ref.watch(draftOrderIdProvider),
                tableless: true,
                inShell: true,
              ),
            ),
          ),
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
          GoRoute(
            path: '/venue-day',
            builder: (_, _) => const VenueDayScreen(),
          ),
          GoRoute(
            path: '/selforder',
            builder: (_, _) => const SelfOrderScreen(),
          ),
          GoRoute(
            path: '/selforder-admin',
            builder: (_, _) => const SelfOrderAdminScreen(),
          ),
          GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
          GoRoute(
            path: '/member-report',
            builder: (_, _) => const MemberReportScreen(),
          ),
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
      // Pengeluaran kunjungan categories (ADR-0130), pushed from Venue
      // Settings for the same reason: list-shaped and edited rarely.
      GoRoute(
        path: '/venue/pengeluaran',
        builder: (_, _) => const ExpenseCategoriesScreen(),
      ),
    ],
  );
});
