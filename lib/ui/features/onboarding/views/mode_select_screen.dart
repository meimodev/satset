import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/ui/features/onboarding/view_models/mode_select_view_model.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(modeSelectViewModelProvider);
    final vm = ref.read(modeSelectViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Pilih mode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Tablet ini akan jadi server atau klien?'),
              const SizedBox(height: 24),
              _ModeCard(
                title: 'Server',
                subtitle: 'Tablet ini host venue. Database lokal di sini.',
                onTap: s.busy
                    ? null
                    : () async {
                        await vm.choose(AppMode.server);
                        if (context.mounted) context.go('/pin');
                      },
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: 'Klien',
                subtitle:
                    'Tablet ini ambil order, terhubung ke server lewat LAN.',
                onTap: s.busy
                    ? null
                    : () async {
                        await vm.choose(AppMode.client);
                        if (context.mounted) context.go('/pair');
                      },
              ),
              if (s.error != null) ...[
                const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
