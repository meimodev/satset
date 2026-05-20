import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../auth/screens/pin_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/tables/tables_screen.dart';
import '../features/tables/table_detail_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/me/me_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/review/review_screen.dart';
import '../features/sent/sent_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/pin',
    redirect: (context, state) {
      final loc = state.uri.path;
      final loggedIn = auth.isAuthenticated;
      if (!loggedIn && loc != '/pin') return '/pin';
      if (loggedIn && loc == '/pin') return '/tables';
      return null;
    },
    routes: [
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/me', builder: (_, _) => const MeScreen()),
        ],
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
