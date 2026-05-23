import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'router/app_router.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';

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
      builder: (context, child) {
        final bg = Theme.of(context).scaffoldBackgroundColor;
        return ColoredBox(
          color: bg,
          child: SafeArea(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
