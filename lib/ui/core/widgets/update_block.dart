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
import 'package:satset/ui/core/widgets/update_action.dart';

/// The mandatory-update block (ADR-0130). Covers everything, cannot be
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
///
/// **Every device installs from here** (ADR-0131). This is the one place the
/// action is ungated: the screen is already full-screen and already
/// interrupting, so the button costs no quiet, and self-rescue matters most on
/// a device that is out of service.
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
    // Every device installs from here, ungated (ADR-0131, reversing ADR-0130).
    // A device below `min` is out of service; refusing to let it unblock itself
    // protects nobody and turns a two-minute install into a stranded handset
    // waiting for someone with an admin session to walk over.
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
                _InstallAction(install: install),
                const SizedBox(height: Sp.s3),
                // Kept, and demoted to a footnote. Every device can install
                // now, but a device whose holder cannot get past Android's
                // "install unknown apps" dialog still needs to be told who to
                // fetch, and this screen is the only thing they can reach.
                Text(
                  context.l10n.updateBlockedAskAdmin,
                  style: SatType.labelS(color: sc.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallAction extends ConsumerWidget {
  const _InstallAction({required this.install});

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
          onTap: busy ? null : () => startUpdate(context, ref),
        ),
      ],
    );
  }
}
