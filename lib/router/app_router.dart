import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/features/auth/views/pin_screen.dart';
import 'package:satset/ui/features/onboarding/views/forbidden_screen.dart';
import 'package:satset/ui/features/onboarding/views/mode_select_screen.dart';
import 'package:satset/ui/features/onboarding/views/pair_screen.dart';
import 'package:satset/ui/features/shell/app_shell.dart';
import 'package:satset/ui/features/tables/tables_screen.dart';
import 'package:satset/ui/features/tables/table_detail_screen.dart';
import 'package:satset/ui/features/orders/orders_screen.dart';
import 'package:satset/ui/features/me/me_screen.dart';
import 'package:satset/ui/features/menu/menu_screen.dart';
import 'package:satset/ui/features/review/review_screen.dart';
import 'package:satset/ui/features/sent/sent_screen.dart';
import 'package:satset/ui/features/admin/kitchen_screen.dart';
import 'package:satset/ui/features/admin/floor_screen.dart';
import 'package:satset/ui/features/admin/menu_admin_screen.dart';
import 'package:satset/ui/features/admin/menu_admin_item_screen.dart';
import 'package:satset/ui/features/admin/reports_screen.dart';
import 'package:satset/ui/features/admin/venue_hub_screen.dart';
import 'package:satset/ui/features/admin/settings_screen.dart';
import 'package:satset/ui/features/admin/staff_screen.dart';

Capability? _capabilityFor(String loc) {
  if (loc.startsWith('/kitchen')) return Capability.viewKds;
  if (loc.startsWith('/table/') || loc.startsWith('/orders')) {
    return Capability.takeOrder;
  }
  if (loc.startsWith('/menuadm') || loc.startsWith('/staff') ||
      loc.startsWith('/reports') || loc.startsWith('/settings') ||
      loc.startsWith('/floor') || loc.startsWith('/venue')) {
    return Capability.manageStaff;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final prefs = ref.watch(prefsServiceProvider).valueOrNull;
  final storage = ref.watch(secureStorageServiceProvider);

  return GoRouter(
    initialLocation: '/pin',
    redirect: (context, state) async {
      final loc = state.uri.path;
      final mode = prefs?.appMode() ?? AppMode.unset;

      if (mode == AppMode.unset && loc != '/onboarding') return '/onboarding';
      if (mode != AppMode.unset && loc == '/onboarding') return '/pin';

      if (mode == AppMode.client) {
        final fp = await storage.readServerFingerprint();
        final paired = fp != null && fp.isNotEmpty;
        if (!paired && loc != '/pair') return '/pair';
        if (paired && loc == '/pair') return '/pin';
      }

      final loggedIn = auth.isAuthenticated;
      if (!loggedIn && loc != '/pin' && loc != '/onboarding' && loc != '/pair') {
        return '/pin';
      }
      if (loggedIn && loc == '/pin') return '/tables';

      if (loggedIn) {
        final needed = _capabilityFor(loc);
        // Fail-closed: missing capability denies the route. There is no
        // bypass for empty capability sets — those users must be sent to
        // /forbidden until the server grants them caps.
        if (needed != null && !auth.has(needed)) {
          return '/forbidden';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const ModeSelectScreen()),
      GoRoute(path: '/pair', builder: (_, _) => const PairScreen()),
      GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/kitchen', builder: (_, _) => const KitchenScreen()),
          GoRoute(path: '/venue', builder: (_, _) => const VenueHubScreen()),
          GoRoute(path: '/floor', builder: (_, _) => const FloorScreen()),
          GoRoute(path: '/menuadm', builder: (_, _) => const MenuAdminScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: '/staff', builder: (_, _) => const StaffScreen()),
          GoRoute(path: '/me', builder: (_, _) => const MeScreen()),
        ],
      ),
      GoRoute(
        path: '/menuadm/:id',
        builder: (_, s) =>
            MenuAdminItemScreen(id: s.pathParameters['id']!),
      ),
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
    ],
  );
});
