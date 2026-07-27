import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/spacing.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: Sp.s3),
            const Text('Akses tidak diizinkan'),
            const SizedBox(height: Sp.s4),
            FilledButton(
              onPressed: () => context.go('/tables'),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
