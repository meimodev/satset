import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../state/tables_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final ready = ref.watch(totalReadyCountProvider);
    final loc = GoRouterState.of(context).uri.path;

    String activeTab;
    if (loc.startsWith('/orders')) {
      activeTab = 'orders';
    } else if (loc.startsWith('/me')) {
      activeTab = 'me';
    } else {
      activeTab = 'tables';
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 8,
            right: 8,
            bottom: 20,
            child: _FloatingTabBar(active: activeTab, readyCount: ready),
          ),
        ],
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final String active;
  final int readyCount;
  const _FloatingTabBar({required this.active, required this.readyCount});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? const Color(0xEB1C1F23)
        : const Color(0xDBFFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sc.border1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _Tab(
                id: 'tables',
                label: 'Meja',
                icon: Icons.grid_view_rounded,
                active: active == 'tables',
                onTap: () => context.go('/tables'),
              ),
              _Tab(
                id: 'orders',
                label: 'Pesanan',
                icon: Icons.receipt_long_rounded,
                active: active == 'orders',
                badge: readyCount,
                badgeAlert: readyCount > 0,
                onTap: () => context.go('/orders'),
              ),
              _Tab(
                id: 'me',
                label: 'Saya',
                icon: Icons.person_outline_rounded,
                active: active == 'me',
                onTap: () => context.go('/me'),
              ),
            ],
          ),
        ),
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
              decoration: BoxDecoration(
                color: active ? sc.bg4 : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: active ? sc.textHi : sc.textLo),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: SatType.sans(
                      size: 10,
                      weight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: active ? sc.textHi : sc.textLo,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 8,
                right: 14,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: badgeAlert ? sc.success : sc.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 0,
                      color: badgeAlert ? const Color(0xFF0A0A0A) : sc.accentInk,
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
