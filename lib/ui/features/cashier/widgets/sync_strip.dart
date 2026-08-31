import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/send_queue_drain.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/pulse_dot.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';

/// What the [[Antrean setelmen]] is doing, on the `/kasir` header (ADR-0123).
///
/// Two facts, deliberately separate: **the venue is catching up** (the pulse,
/// while a drain is in flight) and **this much has not landed yet** (the count,
/// which outlives the drain when a chain parks on a refusal). Absent entirely
/// when there is nothing pending — a strip that is always there is a strip
/// nobody reads.
class SettlementSyncStrip extends ConsumerWidget {
  const SettlementSyncStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final j = ref.watch(settlementJournalProvider);
    if (j.pendingVisits.isEmpty && !j.draining) return const SizedBox.shrink();
    final parked = j.parkedVisits.isNotEmpty;
    // Parked is a refusal waiting on a human; pending is only in transit.
    final hue = parked ? sc.urgent : sc.warn;
    return Container(
      margin: const EdgeInsets.only(top: Sp.s3),
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2),
      decoration: BoxDecoration(
        color: sc.bg2,
        borderRadius: SatR.md,
        border: Border.all(color: hue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          PulseDot(color: hue, pulse: j.draining),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              j.draining
                  ? context.l10n.cshSyncDraining
                  : context.l10n.cshSyncPending(j.pendingVisits.length),
              style: SatType.labelM().copyWith(color: sc.textHi),
            ),
          ),
        ],
      ),
    );
  }
}

/// Surfaces a refused chain the moment a drain reports one.
///
/// Heavier than the [[Hasil pengiriman]] on purpose: a refused settlement is
/// cash already in the drawer, so it blocks rather than passing as a snackbar,
/// and acknowledging it is an explicit act.
class SettlementRefusalListener extends ConsumerStatefulWidget {
  final Widget child;
  const SettlementRefusalListener({super.key, required this.child});

  @override
  ConsumerState<SettlementRefusalListener> createState() =>
      _SettlementRefusalListenerState();
}

class _SettlementRefusalListenerState
    extends ConsumerState<SettlementRefusalListener> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<SettlementReport?>(settlementReportProvider, (_, next) {
      if (next == null || next.failures.isEmpty || _showing) return;
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(next));
    });
    return widget.child;
  }

  Future<void> _open(SettlementReport report) async {
    final failures = report.failures;
    await showSatSheet<void>(
      context,
      // Not dismissible: the money is real and the cashier has to look at it.
      dismissible: false,
      builder: (ctx) => _RefusalSheet(failures: failures),
    );
    if (!mounted) return;
    // Acknowledging clears the chains: the difference is now a human's
    // problem, and the audit row the host wrote is where it lives.
    for (final c in failures) {
      await ref.read(settlementJournalProvider.notifier).acknowledge(c.visitId);
    }
    ref.read(settlementReportProvider.notifier).state = null;
    _showing = false;
  }
}

class _RefusalSheet extends StatelessWidget {
  final List<ChainOutcome> failures;
  const _RefusalSheet({required this.failures});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.l10n;
    final stranded = failures.fold<int>(0, (a, c) => a + c.strandedAmount);
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Sp.s4) +
            const EdgeInsets.only(bottom: Sp.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l.cshSyncRefusedTitle,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            Text(
              l.cshSyncRefusedBody(failures.length),
              style: SatType.bodyM().copyWith(color: sc.textMd),
            ),
            if (stranded > 0) ...[
              const SizedBox(height: Sp.s3),
              Text(
                l.cshSyncStranded(formatIDR(stranded)),
                style: SatType.h3().copyWith(color: sc.urgent),
              ),
            ],
            const SizedBox(height: Sp.s4),
            SatButton.primary(
              label: l.cshSyncAck,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
