import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_state.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/components/sat_input.dart';
import '../../design/components/sat_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Harap isi nama pengguna dan kata sandi');
      return;
    }

    final success = ref.read(authStateProvider.notifier).login(username, password);
    if (success) {
      context.go('/');
    } else {
      setState(() => _error = 'Nama pengguna atau kata sandi salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo area
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'SatSet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Solusi Cepat, Kerja Akurat.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SatInput(
                  label: 'Nama Pengguna',
                  controller: _usernameController,
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: AppSpacing.md),
                SatInput(
                  label: 'Kata Sandi',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 14, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SatButton(
                  label: 'Masuk',
                  expanded: true,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pengguna tersedia: admin, chef, waiter, manager',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'Kata sandi apa saja bisa (mode demo)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
