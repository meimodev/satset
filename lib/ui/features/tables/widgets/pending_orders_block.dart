import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';

/// The **pesanan tertunda** this table is holding — lines a terputus handset
/// captured and has not delivered.
///
/// Rendered off the send queue rather than faked into the ticket map on purpose
/// (ADR-0090): the kitchen has never seen these, no stock has moved and a bill
/// must not be able to reach them. Keeping them out of `tickets` makes all
/// three true by construction instead of by three separate filters.
///
/// Renders nothing when the queue holds nothing for this table, so the caller
/// can place it unconditionally.
class PendingOrdersBlock extends ConsumerWidget {
  const PendingOrdersBlock({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intents = ref.watch(pendingOrdersForTableProvider(tableId));
    if (intents.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s3),
      child: SatCard.section(
        header: l.sendQueueTertunda,
        headerTrailing: SatChip.tag(
          label: l.sendQueuePending(
            intents.fold<int>(0, (n, i) => n + i.lines.length),
          ),
          hue: SatChipHue.warn,
          size: SatChipSize.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final intent in intents)
              _PendingIntent(
                intent: intent,
                onRemoveLine: (i) {
                  final rest = [...intent.lines]..removeAt(i);
                  // Empty means the order is gone — `rewriteLines` discards the
                  // intent rather than queueing a send with nothing in it.
                  ref
                      .read(sendQueueProvider.notifier)
                      .rewriteLines(intent.id, rest);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingIntent extends StatelessWidget {
  const _PendingIntent({required this.intent, required this.onRemoveLine});

  final SendIntent intent;
  final void Function(int index) onRemoveLine;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, line) in intent.lines.indexed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(line['qty'] as num?)?.toInt() ?? 1}× '
                    '${(line['name'] as String?) ?? ''}',
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                ),
                // Removing a line nobody has cooked is just deleting the
                // request: no void reason to collect, no kitchen to tell, no
                // stock to return. That is the whole reason these live outside
                // `tickets` — a sent line could never be dropped this cheaply.
                SatIconButton.danger(
                  icon: Icons.close,
                  tooltip: l.delete,
                  onTap: () => onRemoveLine(i),
                ),
              ],
            ),
          Text(
            l.sendQueueCapturedAt(
              formatClockId(intent.capturedAt.toIso8601String()),
            ),
            style: SatType.bodyS(color: sc.textDim),
          ),
        ],
      ),
    );
  }
}
