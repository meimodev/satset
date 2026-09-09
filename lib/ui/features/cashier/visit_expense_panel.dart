import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/visit_expense_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';
import 'package:satset/ui/features/tables/visit_expense_sheet.dart';

/// What this visit has cost the venue (ADR-0130), on the [[Cashier]]'s bill.
///
/// **Read-only about the money.** It reports what already left the till; it
/// moves no total, no outstanding and no receipt, and `recomputeBill` has never
/// heard of it. The cashier sees it because they are about to close a bill and
/// should know the party cost Rp 40.000 to serve — not because it changes what
/// the guest owes.
///
/// The record button is here as well as on the floor, so a [[Kedai]] venue with
/// `menuHome` on and no table detail still reaches the feature.
class VisitExpensePanel extends ConsumerWidget {
  final String visitId;
  final bool billOpen;
  final bool showEmpty;

  /// Table detail records from its header and only needs a nonzero summary.
  final bool summaryOnly;
  final String? tableId;
  const VisitExpensePanel({
    super.key,
    required this.visitId,
    required this.billOpen,
    this.showEmpty = false,
    this.summaryOnly = false,
    this.tableId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(venueSettingsProvider.select((c) => c.tableExpenseOn));
    if (!on) return const SizedBox.shrink();

    final sc = context.sat;
    final l10n = context.l10n;
    final summary = ref.watch(visitExpensesProvider(visitId));
    final canSpend = ref.watch(
      authStateProvider.select((s) => s.has(Capability.recordTableExpense)),
    );
    // After bill close there is nothing to record against and nothing to say —
    // a closed bill with no expenses is not a fact worth a card.
    final total = summary.valueOrNull?.total ?? 0;
    if (summaryOnly && summary.hasValue && total == 0 && !summary.hasError) {
      return const SizedBox.shrink();
    }
    if (!showEmpty &&
        summary.hasValue &&
        total == 0 &&
        !(canSpend && billOpen)) {
      return const SizedBox.shrink();
    }

    return SatCard.plain(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tableExpTitle,
                  style: SatType.labelM(color: sc.textMd),
                ),
              ),
              if (summary.isLoading)
                const SatSpinner(size: SatSpinnerSize.xs)
              else if (summary.hasValue)
                Text(formatIDR(total), style: SatType.monoM(color: sc.textHi)),
            ],
          ),
          if (summary.hasError) ...[
            const SizedBox(height: Sp.s2),
            Text(l10n.tableExpOffline, style: SatType.bodyS(color: sc.textLo)),
            SatButton.outline(
              label: l10n.retry,
              onTap: () => ref.invalidate(visitExpensesProvider(visitId)),
            ),
          ] else if (summary.valueOrNull?.offline == true) ...[
            const SizedBox(height: Sp.s2),
            Text(
              l10n.tableExpProvisional,
              style: SatType.bodyS(color: sc.textLo),
            ),
          ] else if (showEmpty && summary.hasValue && total == 0) ...[
            const SizedBox(height: Sp.s2),
            Text(l10n.tableExpNone, style: SatType.bodyS(color: sc.textLo)),
          ],
          if (summary.valueOrNull?.expenses.isNotEmpty == true) ...[
            const SizedBox(height: Sp.s3),
            Divider(height: 1, color: sc.border0),
            const SizedBox(height: Sp.s1),
          ],
          for (final e in summary.valueOrNull?.expenses ?? const []) ...[
            const SizedBox(height: Sp.s3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Venue-authored, so ARB-exempt.
                      Text(
                        e.categoryName,
                        style: SatType.bodyS(color: sc.textHi),
                      ),
                      if (e.note.isNotEmpty) ...[
                        const SizedBox(height: Sp.s1),
                        Text(e.note, style: SatType.bodyS(color: sc.textLo)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Text(
                  formatIDR(e.amount),
                  style: SatType.monoS(color: sc.textMd),
                ),
              ],
            ),
          ],
          if (!summaryOnly && canSpend && billOpen) ...[
            const SizedBox(height: Sp.s3),
            SatButton.outline(
              label: l10n.tableExpNew,
              icon: Icons.shopping_bag_rounded,
              onTap: () => showVisitExpenseSheet(
                context,
                visitId: visitId,
                tableId: tableId,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
