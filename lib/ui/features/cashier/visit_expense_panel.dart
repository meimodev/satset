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
  const VisitExpensePanel({
    super.key,
    required this.visitId,
    required this.billOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      venueSettingsProvider.select((c) => c.tableExpenseOn),
    );
    if (!on) return const SizedBox.shrink();

    final sc = context.sat;
    final l10n = context.l10n;
    final summary = ref.watch(visitExpensesProvider(visitId));
    final canSpend = ref.watch(
      authStateProvider.select(
        (s) => s.has(Capability.recordTableExpense),
      ),
    );
    // After bill close there is nothing to record against and nothing to say —
    // a closed bill with no expenses is not a fact worth a card.
    final total = summary.valueOrNull?.total ?? 0;
    if (total == 0 && !(canSpend && billOpen)) return const SizedBox.shrink();

    return SatCard.plain(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tableExpTitle,
                  style: SatType.labelS(color: sc.textLo),
                ),
              ),
              Text(
                formatIDR(total),
                style: SatType.monoL(color: sc.textHi),
              ),
            ],
          ),
          for (final e in summary.valueOrNull?.expenses ?? const []) ...[
            const SizedBox(height: Sp.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    // Venue-authored, so ARB-exempt.
                    e.note.isEmpty ? e.categoryName : '${e.categoryName} · ${e.note}',
                    style: SatType.bodyS(color: sc.textLo),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Text(
                  formatIDR(e.amount),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
          ],
          if (canSpend && billOpen) ...[
            const SizedBox(height: Sp.s3),
            SatButton.outline(
              label: l10n.tableExpNew,
              icon: Icons.shopping_bag_rounded,
              onTap: () => showVisitExpenseSheet(context, visitId: visitId),
            ),
          ],
        ],
      ),
    );
  }
}
