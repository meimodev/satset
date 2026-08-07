import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/generic_seed.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// The one surface for sample data (ADR-0073): the mandatory first-run prompt,
/// the progress of a running job, the failed/interrupted recovery, and the
/// clear action reached later from Admin → Settings.
///
/// Non-dismissible on purpose. The admin answers once — load or skip — and the
/// answer is written server-side, venue-wide, so it never returns. There is no
/// X, no tap-outside and no back button, because "mandatory" that a stray tap
/// escapes is not mandatory.
///
/// Progress lives here rather than in a Venue Hub banner for one reason: the
/// job dies if the app is backgrounded and there is no resume (ADR-0053 §9), so
/// the honest UI keeps the admin on this screen instead of letting them wander
/// into half-populated data.
Future<void> showSeedDataDialog(BuildContext context) => showSatDialog<void>(
  context,
  dismissible: false,
  builder: (_) => const _SeedDataDialog(),
);

class _SeedDataDialog extends ConsumerStatefulWidget {
  const _SeedDataDialog();

  @override
  ConsumerState<_SeedDataDialog> createState() => _SeedDataDialogState();
}

class _SeedDataDialogState extends ConsumerState<_SeedDataDialog> {
  /// True once this dialog started the job, so the "Selesai" state is only
  /// shown to the admin who waited for it — not to someone opening the dialog
  /// from Settings on an already-seeded venue.
  bool _ranHere = false;
  bool _finished = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final st = ref.watch(genericSeedProvider);
    final ctrl = ref.read(genericSeedProvider.notifier);

    if (_ranHere && !st.seeding && st.hasSampleData && !_finished) {
      _finished = true;
    }

    final phase = st.phase;
    final running = st.seeding;

    return PopScope(
      // The Android back button is the last way out of a "mandatory" dialog.
      canPop: false,
      child: AlertDialog(
        title: Text(
          context.l10n.venueHubSeedTitle,
          style: SatType.h3(color: sc.textHi),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _error ??
                  switch (true) {
                    _ when _finished => context.l10n.venueHubSeedBodyDone,
                    _ when running => context.l10n.venueHubSeedBodyRunning,
                    _ when phase == SeedPromptPhase.failed =>
                      context.l10n.venueHubSeedBodyFailed,
                    _ when phase == SeedPromptPhase.incomplete =>
                      context.l10n.venueHubSeedBodyIncomplete,
                    _ when st.hasSampleData =>
                      context.l10n.venueHubSeedBodyLoaded,
                    _ => context.l10n.venueHubSeedBody,
                  },
              style: SatType.bodyM(
                color: _error == null ? sc.textMd : sc.urgent,
              ),
            ),
            if (running) ...[
              const SizedBox(height: Sp.s6),
              ClipRRect(
                borderRadius: SatR.pill,
                child: LinearProgressIndicator(
                  value: st.progress,
                  minHeight: Sp.s2,
                  backgroundColor: sc.bg3,
                  color: sc.accent,
                ),
              ),
              const SizedBox(height: Sp.s2),
              Text(
                '${context.l10n.venueHubSeedProgress} · '
                '${context.l10n.venueHubSeedDays(st.daysDone, st.daysTotal)}',
                style: SatType.caption(color: sc.textDim),
              ),
            ],
          ],
        ),
        actions: _actions(context, st, ctrl, running: running),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    GenericSeedState st,
    GenericSeedController ctrl, {
    required bool running,
  }) {
    // Nothing to offer while the job runs: leaving is what breaks it.
    if (running) return const [];

    if (_finished) {
      return [
        SatButton.primary(
          label: context.l10n.venueHubSeedBtnDone,
          onTap: () => Navigator.of(context).pop(),
        ),
      ];
    }

    final broken =
        st.phase == SeedPromptPhase.incomplete ||
        st.phase == SeedPromptPhase.failed;

    return [
      SatButton.ghost(
        label: context.l10n.venueHubSeedBtnSkip,
        onTap: st.loading
            ? null
            : () async {
                await ctrl.skip();
                if (context.mounted) Navigator.of(context).pop();
              },
      ),
      if (st.hasSampleData || broken)
        SatButton.danger(
          label: broken
              ? context.l10n.venueHubSeedBtnClearRetry
              : context.l10n.venueHubSeedBtnClear,
          busy: st.loading,
          onTap: st.loading
              ? null
              : () => _run(() async {
                  await ctrl.clear();
                  if (broken) await _start(ctrl);
                }),
        ),
      if (!st.hasSampleData && !broken)
        SatButton.primary(
          label: context.l10n.venueHubSeedBtnLoad,
          busy: st.loading,
          onTap: st.loading ? null : () => _run(() => _start(ctrl)),
        ),
    ];
  }

  Future<void> _start(GenericSeedController ctrl) async {
    await ctrl.seed();
    if (mounted) setState(() => _ranHere = true);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.venueHubSeedError);
    }
  }
}
