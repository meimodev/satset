import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/locale_view_model.dart';

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
            Text(context.l10n.fbdNoAccess),
            const SizedBox(height: Sp.s4),
            SatButton.primary(
              label: context.l10n.back,
              onTap: () => context.go('/tables'),
            ),
          ],
        ),
      ),
    );
  }
}
