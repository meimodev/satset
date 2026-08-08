import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'router/app_router.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';
import 'package:satset/ui/core/widgets/alert_host.dart';
import 'package:satset/ui/core/widgets/update_block.dart';

class SatSetApp extends ConsumerWidget {
  const SatSetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // One theme, one code path — brightness is a property of the selected
    // SatTheme, so there is no darkTheme/themeMode pair. See ADR-0045.
    final theme = ref.watch(satThemeProvider);
    // Device-local, hard-defaulted to Indonesian, never resolved from the
    // platform locale. See ADR-0083. Registering the delegates also fixes
    // Material's own widgets — date pickers, the Cut/Copy/Paste menu — which
    // rendered in English inside an Indonesian app for want of a delegate.
    final locale = ref.watch(satLocaleProvider);
    return MaterialApp.router(
      title: 'SatSet',
      debugShowCheckedModeBanner: false,
      theme: satTheme(theme),
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
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
              // Outermost of the two hosts: a device below the release floor
              // must not be reachable by a ready toast either. See ADR-0087.
              child: UpdateBlock(
                child: AlertHost(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        );
      },
    );
  }
}
