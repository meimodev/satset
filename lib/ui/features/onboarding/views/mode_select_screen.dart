import 'package:flutter/material.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/ui/features/onboarding/view_models/mode_select_view_model.dart';
import 'package:satset/ui/core/design/spacing.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(modeSelectViewModelProvider);
    final vm = ref.read(modeSelectViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sp.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Sp.s6),
              Text(
                context.l10n.onbPickMode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Sp.s2),
              Text(context.l10n.onbPickModeSub),
              const SizedBox(height: Sp.s6),
              _ModeCard(
                title: context.l10n.onbModeServer,
                subtitle: context.l10n.onbModeServerSub,
                onTap: s.busy
                    ? null
                    : () async {
                        await vm.choose(AppMode.server);
                        if (context.mounted) context.go('/pin');
                      },
              ),
              const SizedBox(height: Sp.s3),
              _ModeCard(
                title: context.l10n.onbModeClient,
                subtitle: context.l10n.onbModeClientSub,
                onTap: s.busy
                    ? null
                    : () async {
                        await vm.choose(AppMode.client);
                        // Pairing lives on the sign-in screen: it browses mDNS
                        // and auto-claims the server you pick (ADR-0080).
                        if (context.mounted) context.go('/pin');
                      },
              ),
              if (s.error != null) ...[
                const SizedBox(height: Sp.s4),
                Text(
                  s.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Sp.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Sp.s1),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
