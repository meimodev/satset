import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'auth/auth_state.dart';
import 'widgets/top_app_bar.dart';

class SatSetApp extends ConsumerWidget {
  const SatSetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.isAuthenticated;
    final currentLoc = router.routerDelegate.currentConfiguration.uri.path;

    return MaterialApp.router(
      title: 'SatSet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF322214),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF4A3728),
          onPrimaryContainer: Color(0xFFBBA08C),
          secondary: Color(0xFF6A5C4D),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFEFDDC9),
          onSecondaryContainer: Color(0xFF6E6051),
          tertiary: Color(0xFF2F2317),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFF46392B),
          onTertiaryContainer: Color(0xFFB5A290),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          surface: Color(0xFFFBF9F4),
          onSurface: Color(0xFF1B1C19),
          onSurfaceVariant: Color(0xFF4E453E),
          outline: Color(0xFF80756D),
          outlineVariant: Color(0xFFD2C4BB),
          surfaceTint: Color(0xFF705A49),
          inverseSurface: Color(0xFF30312E),
          inversePrimary: Color(0xFFDEC1AC),
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF9F4),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A3728),
            foregroundColor: const Color(0xFFFFFFFF),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4A3728),
            side: const BorderSide(color: Color(0xFFA39382)),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFA39382)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFA39382)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A3728), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFF0EEE9),
          indicatorColor: const Color(0xFF4A3728).withValues(alpha: 0.2),
        ),
      ),
      routerConfig: router,
      builder: (context, child) {
        final showTopBar = isLoggedIn && currentLoc != '/login';
        return Column(
          children: [
            if (showTopBar) const TopAppBar(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
