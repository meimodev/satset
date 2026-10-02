import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/pulse_dot.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// Captured records stay visible until the host has accepted them.
class SettlementSyncStrip extends ConsumerWidget {
  const SettlementSyncStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(settlementJournalProvider);
    final repairVisits = {
      for (final e in journal.events)
        if (e.needsRepair) e.visitId,
    };
    final visibleVisits = {...journal.pendingVisits, ...repairVisits};
    if (visibleVisits.isEmpty && !journal.draining) {
      return const SizedBox.shrink();
    }
    final sc = context.sat;
    final color =
        repairVisits.isNotEmpty || journal.events.any((e) => e.hasSyncError)
        ? sc.urgent
        : sc.warn;
    return Padding(
      padding: const EdgeInsets.only(top: Sp.s3),
      child: Row(
        children: [
          PulseDot(color: color, pulse: journal.draining),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              journal.draining
                  ? context.l10n.cshSyncDraining
                  : repairVisits.isNotEmpty
                  ? context.l10n.cshSyncRepair
                  : journal.events.any((e) => e.hasSyncError)
                  ? context.l10n.cshSyncError
                  : context.l10n.cshSyncPending(visibleVisits.length),
              style: SatType.labelM().copyWith(color: color),
            ),
          ),
          if (repairVisits.isNotEmpty)
            IconButton(
              onPressed: () => _repairCaptured(
                context,
                ref,
                journal.events.firstWhere((e) => e.needsRepair),
              ),
              tooltip: context.l10n.cshRepairTitle,
              icon: Icon(Icons.build_outlined, color: color),
            ),
        ],
      ),
    );
  }
}

Future<void> _repairCaptured(
  BuildContext context,
  WidgetRef ref,
  SettlementEvent event,
) async {
  final money =
      event.kind == SettlementEventKind.recordPayment ||
      event.kind == SettlementEventKind.refund;
  final amount = TextEditingController(
    text: event.payload['amount']?.toString(),
  );
  final receipt = TextEditingController(
    text: event.arg<String>('receiptId') ?? '',
  );
  final payment = TextEditingController(
    text: event.arg<String>('paymentId') ?? '',
  );
  final data = TextEditingController(
    text: jsonEncode({...event.payload}..remove('_syncPolicy')),
  );
  String? error;
  try {
    await showSatDialog<void>(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(context.l10n.cshRepairTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${event.kind.name} · ${event.visitId}'),
                  if (money) ...[
                    SatField.number(
                      controller: amount,
                      hint: context.l10n.cshRepairAmount,
                    ),
                    SatField.text(
                      controller: receipt,
                      hint: context.l10n.cshRepairReceipt,
                    ),
                    if (event.kind == SettlementEventKind.refund)
                      SatField.text(
                        controller: payment,
                        hint: context.l10n.cshRepairPayment,
                      ),
                  ] else
                    SatField.text(
                      controller: data,
                      maxLines: 8,
                      hint: context.l10n.cshRepairData,
                    ),
                  if (error != null)
                    Text(error!, style: TextStyle(color: context.sat.urgent)),
                ],
              ),
            ),
            actions: [
              SatButton.ghost(
                onTap: () => Navigator.pop(dialogContext),
                label: MaterialLocalizations.of(context).cancelButtonLabel,
              ),
              SatButton.primary(
                onTap: () async {
                  try {
                    final payload = money
                        ? <String, dynamic>{
                            ...event.payload,
                            'amount': int.parse(amount.text.trim()),
                            'receiptId': receipt.text.trim(),
                            if (event.kind == SettlementEventKind.refund)
                              'paymentId': payment.text.trim(),
                          }
                        : (jsonDecode(data.text) as Map)
                              .cast<String, dynamic>();
                    await ref
                        .read(settlementJournalProvider.notifier)
                        .repairAndResend(event.id, payload);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await ref.read(settlementJournalProvider.notifier).drain();
                  } catch (_) {
                    if (dialogContext.mounted) {
                      setState(() => error = context.l10n.cshRepairInvalid);
                    }
                  }
                },
                label: context.l10n.cshRepairSend,
              ),
            ],
          );
        },
      ),
    );
  } finally {
    amount.dispose();
    receipt.dispose();
    payment.dispose();
    data.dispose();
  }
}
