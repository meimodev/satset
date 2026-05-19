import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../auth/screens/login_screen.dart';
import '../features/zone_map/zone_map_screen.dart';
import '../features/product_matrix/product_matrix_screen.dart';
import '../features/tickets/tickets_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/table_detail/table_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/dummy_data.dart';
import '../models/venue_table.dart';
import '../models/user.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.uri.path;

      if (!isLoggedIn && loc != '/login') return '/login';
      if (isLoggedIn && loc == '/login') return '/';

      if (loc == '/admin') {
        final role = authState.user?.role;
        if (role != UserRole.manager && role != UserRole.admin) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => BottomNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ZoneMapScreen(),
          ),
          GoRoute(
            path: '/matrix',
            builder: (_, _) => const ProductMatrixScreen(),
          ),
          GoRoute(
            path: '/tickets',
            builder: (_, _) => const TicketsScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, _) => const AdminScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/table/:tableId',
        builder: (_, state) {
          final id = state.pathParameters['tableId']!;
          final table = DummyData.tables.firstWhere(
            (t) => t.id == id,
            orElse: () => const VenueTable(id: '0', zoneId: '', label: '?'),
          );
          return TableDetailScreen(table: table);
        },
      ),
    ],
  );
});
