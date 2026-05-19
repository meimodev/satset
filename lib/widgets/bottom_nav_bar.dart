import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_state.dart';
import '../../models/user.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final location = GoRouterState.of(context).uri.path;

    int rawIndex() {
      if (location.startsWith('/matrix')) return 1;
      if (location.startsWith('/tickets')) return 2;
      if (location.startsWith('/admin')) return 3;
      return 0;
    }

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: 'ZONA',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'MATRIKS',
      ),
      const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        selectedIcon: Icon(Icons.confirmation_number),
        label: 'TIKET',
      ),
    ];

    if (user != null && (user.role == UserRole.manager || user.role == UserRole.admin)) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'ADMIN',
        ),
      );
    }

    final selectedIndex = rawIndex().clamp(0, destinations.length - 1).toInt();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final clamped = index.clamp(0, destinations.length - 1).toInt();
          switch (clamped) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/matrix');
              break;
            case 2:
              context.go('/tickets');
              break;
            case 3:
              context.go('/admin');
              break;
          }
        },
        destinations: destinations,
      ),
    );
  }
}
