import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'router/app_router.dart';
import 'state/theme_provider.dart';

class SatSetApp extends ConsumerWidget {
  const SatSetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SatSet',
      debugShowCheckedModeBanner: false,
      theme: satLightTheme(),
      darkTheme: satDarkTheme(),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
