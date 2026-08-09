import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// **Hasil pengiriman** — what the host did with a replayed backlog.
///
/// Only opens when something needs a human: an order the host refused, a line
/// the kitchen had no stock for, or a drain that stalled. A clean drain says
/// nothing at all, because the lines simply appearing on the table *is* the
/// confirmation, and a waiter mid-rush should not have to dismiss good news.
///
/// Non-dismissible for the same reason the seed prompt is: these are orders a
/// guest is waiting for that the kitchen never received. A tap outside is not
/// an acknowledgement (ADR-0090).
Future<void> showSendResultDialog(BuildContext context, SendReport report) =>
    showSatDialog<void>(
      context,
      dismissible: false,
      builder: (_) => _SendResultDialog(report: report),
    );

class _SendResultDialog extends ConsumerWidget {
  const _SendResultDialog({required this.report});

  final SendReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l = context.l10n;
    final tables = ref.watch(tablesProvider);
    final delivered = report.outcomes
        .where((o) => o.kind == SendOutcomeKind.delivered)
        .length;

    String tableName(String id) => tables
        .where((t) => t.id == id)
        .map((t) => t.displayName)
        .firstOrNull ??
        id;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l.sendResultTitle, style: SatType.h3(color: sc.textHi)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (delivered > 0)
                Text(
                  l.sendResultAllOk(delivered),
                  style: SatType.bodyM(color: sc.textMd),
                ),
              if (report.failures.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s1),
                  child: Text(
                    l.sendResultFailedHeading,
                    style: SatType.labelS(color: sc.urgent),
                  ),
                ),
                for (final o in report.failures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.s2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tableName(o.intent.tableId),
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        for (final line in _reasons(context, o))
                          Text(
                            line,
                            style: SatType.bodyS(color: sc.textLo),
                          ),
                      ],
                    ),
                  ),
              ],
              if (report.interrupted)
                Padding(
                  padding: const EdgeInsets.only(top: Sp.s2),
                  child: Text(
                    l.sendFailBlocked,
                    style: SatType.bodyS(color: sc.warn),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          SatButton.primary(
            label: l.sendResultAcknowledge,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// One line per thing that went wrong with this intent. A refusal has exactly
  /// one; a delivered order with stock rejections has one per dropped line,
  /// worded the same way an online send words them (ADR-0041).
  List<String> _reasons(BuildContext context, SendOutcome o) {
    final l = context.l10n;
    return switch (o.kind) {
      SendOutcomeKind.expired => [l.sendFailExpired],
      SendOutcomeKind.refused => [sendFailureText(l, o.code)],
      SendOutcomeKind.delivered => [
        for (final r in o.rejectedLines)
          l.tktNotSent(
            [
              (r['name'] as String?) ?? '',
              if (((r['variantName'] as String?) ?? '').isNotEmpty)
                r['variantName'] as String,
            ].join(' '),
            ((r['ingredients'] as List?) ?? const []).isEmpty
                ? l.tktOutOfStock
                : l.tktOutOfStockNamed(
                    (r['ingredients'] as List).join(', '),
                  ),
          ),
      ],
    };
  }
}
