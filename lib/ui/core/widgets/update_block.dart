import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/app_version.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/release_gate_repository.dart';
import 'package:satset/data/services/app_update_service.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';

/// The mandatory-update block (ADR-0087). Covers everything, cannot be
/// dismissed, and arrives the moment the floor does — not at the next launch.
///
/// **A layer in the app builder, not a pushed route.** Pushing it would mean
/// push/pop bookkeeping against a state that can lift again, and a rung in the
/// redirect ladder would put a fifth conditional into the thing ADR-0078 exists
/// to keep loop-safe. A `Stack` above the router is above the floating tab bar
/// for the structural reason ADR-0061 gives, needs no lifecycle, and cannot be
/// popped by the back button.
///
/// **It never stops the embedded server.** A host that tore its server down
/// while blocked would tell every client "host offline" instead of "fetch an
/// admin", which is the wrong instruction at the worst possible moment.
class UpdateBlock extends ConsumerWidget {
  const UpdateBlock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked =
        ref.watch(updateVerdictProvider) == UpdateVerdict.blocked;
    return Stack(
      children: [
        child,
        if (blocked)
          const Positioned.fill(
            child: PopScope(canPop: false, child: _BlockBody()),
          ),
      ],
    );
  }
}

class _BlockBody extends ConsumerWidget {
  const _BlockBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final min = ref.watch(releaseGateProvider).min ?? '';
    // The Main Device is the only device that can act. Every other one — a
    // staff client and an admin-client alike — is told who to fetch, because
    // updating a hand-distributed app means a person holding the device.
    final isHost = ref.watch(isHostDeviceProvider);
    final install = ref.watch(appUpdateServiceProvider);

    return Material(
      color: sc.bg0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(Sp.s5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.system_update_alt_rounded,
                  size: 40,
                  color: sc.urgent,
                ),
                const SizedBox(height: Sp.s4),
                Text(
                  context.l10n.updateBlockedTitle,
                  style: SatType.h2(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s2),
                Text(
                  context.l10n.updateBlockedBody(AppVersion.value, min),
                  style: SatType.bodyM(color: sc.textDim),
                ),
                const SizedBox(height: Sp.s4),
                if (isHost)
                  _HostAction(install: install)
                else
                  Text(
                    context.l10n.updateBlockedAskAdmin,
                    style: SatType.bodyM(color: sc.textHi),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HostAction extends ConsumerWidget {
  const _HostAction({required this.install});

  final UpdateInstall install;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    // A failure here is a dead end unless it offers a way back — this screen is
    // the only thing the operator can reach.
    final note = switch (install) {
      UpdateDownloading(:final percent) =>
        context.l10n.updateDownloading(percent ?? 0),
      UpdateOpening() => context.l10n.updateInstalling,
      UpdateFailed() => context.l10n.updateFailed,
      UpdateNeedsPermission() => context.l10n.updatePermissionNeeded,
      UpdateIdle() => null,
    };
    final busy = install is UpdateDownloading || install is UpdateOpening;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note != null) ...[
          Text(note, style: SatType.labelS(color: sc.textDim)),
          const SizedBox(height: Sp.s2),
        ],
        SatButton.primary(
          label: install is UpdateFailed || install is UpdateNeedsPermission
              ? context.l10n.updateRetry
              : context.l10n.updateAction,
          icon: Icons.download_rounded,
          onTap: busy
              ? null
              : () => ref
                    .read(appUpdateServiceProvider.notifier)
                    .downloadAndInstall(),
        ),
      ],
    );
  }
}
