import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'router/app_router.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/widgets/alert_host.dart';

class SatSetApp extends ConsumerWidget {
  const SatSetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // One theme, one code path — brightness is a property of the selected
    // SatTheme, so there is no darkTheme/themeMode pair. See ADR-0045.
    final theme = ref.watch(satThemeProvider);
    return MaterialApp.router(
      title: 'SatSet',
      debugShowCheckedModeBanner: false,
      theme: satTheme(theme),
      routerConfig: router,
      builder: (context, child) {
        final bg = Theme.of(context).scaffoldBackgroundColor;
        return ColoredBox(
          color: bg,
          child: SafeArea(
            // ponytail: a ceiling, not a fix. The dense boards (KDS, table
            // detail, cashier bill) are built from fixed-height rows, so an
            // Android font scale of 2.0 clips them silently in release. The
            // clamp bounds that everywhere at once instead of auditing ~600
            // fixed dimensions. It also caps how far a user can enlarge text,
            // so it is a deliberate trade, not free: the real fix is
            // min-height constraints on those rows, after which this ceiling
            // should rise.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: AlertHost(child: child ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }
}
