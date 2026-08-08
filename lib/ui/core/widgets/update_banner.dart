import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/app_version.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/services/app_update_service.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Shell notice that a newer build is out (ADR-0087). Third in the stack under
/// [AdminGraceBanner] and [VenueBillingBanner], and quieter than both: nothing
/// is wrong, something is merely available.
///
/// **Main Device only** — `serverRuntimeProvider` non-null. Not a capability
/// check, because this is not about privilege: it is the one device that can
/// act. A waiter cannot install, and an unactionable strip on a 360dp handset
/// competes with the phone bar budget (ADR-0062) for no gain.
///
/// No sheet, no snooze, no release notes. Two version numbers is the whole
/// message — CI notes are `--generate-notes`, which is English commit subjects
/// on a screen where every other word is localised.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isHostDeviceProvider)) return const SizedBox.shrink();
    if (ref.watch(updateVerdictProvider) != UpdateVerdict.recommended) {
      return const SizedBox.shrink();
    }
    final latest = ref.watch(releaseGateProvider).latest;
    if (latest == null) return const SizedBox.shrink();

    final sc = context.sat;
    final install = ref.watch(appUpdateServiceProvider);
    final fg = sc.info;
    final line = switch (install) {
      UpdateDownloading(:final percent) when percent != null =>
        context.l10n.updateDownloading(percent),
      UpdateDownloading() => context.l10n.updateDownloading(0),
      UpdateOpening() => context.l10n.updateInstalling,
      UpdateFailed() => context.l10n.updateFailed,
      UpdateNeedsPermission() => context.l10n.updatePermissionNeeded,
      UpdateIdle() => context.l10n.updateAvailable(latest, AppVersion.value),
    };
    final busy = install is UpdateDownloading || install is UpdateOpening;
    final cta = install is UpdateFailed || install is UpdateNeedsPermission
        ? context.l10n.updateRetry
        : context.l10n.updateAction;

    return Semantics(
      button: true,
      label: '$line $cta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy
              ? null
              : () =>
                    ref.read(appUpdateServiceProvider.notifier).downloadAndInstall(),
          borderRadius: SatR.a(12),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(Sp.s3, Sp.s2, Sp.s3, 0),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3,
              vertical: Sp.s2h,
            ),
            decoration: SatBox.d(
              color: sc.infoSoft,
              borderRadius: SatR.a(12),
              border: SatB.all(color: fg.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.system_update_alt_rounded, size: 16, color: fg),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(line, style: SatType.labelS(color: fg)),
                ),
                if (!busy)
                  Text(cta, style: SatType.labelS(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
