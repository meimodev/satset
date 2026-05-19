import 'package:flutter/material.dart';
import '../../design/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_state.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      leading: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 28),
      ),
      title: const Text(
        'SatSet',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
