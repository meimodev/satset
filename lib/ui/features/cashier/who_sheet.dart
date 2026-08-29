import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/features/cashier/member_panel.dart';

/// The **Siapa** step — who each share of a split bill is *for* (ADR-0118).
///
/// Deliberately not [MemberPanel] scoped to a receipt: the bill already has a
/// member row, and a second one that looks the same but means "this slip only"
/// is how a cashier attaches the wrong guest to the whole bill. This is one
/// screen that shows every share at once, because the question it answers —
/// "who is A, who is B" — is asked about the split, not about one slip.
///
/// Live, not a snapshot: attaching on the first row must show up on that row
/// while the sheet is still open, so it watches [billDetailProvider] rather
/// than holding the bill it was opened with.
Future<void> showWhoSheet(
  BuildContext context, {
  required String visitId,
  required Bill bill,
  required Future<void> Function(Future<Bill> Function()) run,
  required SettlementRepository repo,
}) => showSatSheet<void>(
  context,
  builder: (_) =>
      _WhoSheet(visitId: visitId, fallback: bill, run: run, repo: repo),
);

class _WhoSheet extends ConsumerWidget {
  final String visitId;
  final Bill fallback;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;

  const _WhoSheet({
    required this.visitId,
    required this.fallback,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final bill = ref.watch(billDetailProvider(visitId)).valueOrNull ?? fallback;
    final owner = bill.member;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: Sp.s5,
          right: Sp.s5,
          bottom: Sp.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(l10n.cshWho, style: SatType.h3(color: sc.textHi)),
            ),
            Text(l10n.cshWhoHint, style: SatType.bodyS(color: sc.textLo)),
            const SizedBox(height: Sp.s3),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bill.receipts.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                itemBuilder: (_, i) => _WhoRow(
                  bill: bill,
                  receipt: bill.receipts[i],
                  run: run,
                  repo: repo,
                ),
              ),
            ),
            const SizedBox(height: Sp.s3),
            // The backstop, stated rather than left to be discovered at close:
            // money no share claims is the [[Pemilik tagihan]]'s (ADR-0118 §1).
            Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 16,
                  color: sc.textLo,
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    owner == null
                        ? l10n.cshWhoRestNone
                        : l10n.cshWhoRest(owner.name),
                    style: SatType.bodyS(color: sc.textLo),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One share: its letter, its money, and who it is for.
class _WhoRow extends ConsumerWidget {
  final Bill bill;
  final BillReceipt receipt;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;

  const _WhoRow({
    required this.bill,
    required this.receipt,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cfg = ref.watch(venueSettingsProvider);
    // Frozen with the money (ADR-0118 §5). The server checks this receipt's own
    // payments, which is stricter than the bill being closed — a paid share on
    // an open bill is settled and its points are already struck.
    final live = bill.billClosedAt == null && receipt.payments.isEmpty;
    final m = receipt.member;

    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(receipt.label, style: SatType.labelL(color: sc.textHi)),
              const SizedBox(width: Sp.s2h),
              Expanded(
                child: Text(
                  formatIDR(receipt.total),
                  style: SatType.mono(color: sc.textLo),
                ),
              ),
              if (!live)
                SatChip.tag(
                  label: l10n.cshWhoPaid,
                  hue: SatChipHue.success,
                  size: SatChipSize.sm,
                ),
            ],
          ),
          const SizedBox(height: Sp.s2),
          if (m == null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    // An id with nobody behind it is a member since deleted:
                    // the share was still theirs (ADR-0092), so say so rather
                    // than offering a slot that looks empty.
                    receipt.memberId == null
                        ? l10n.cshWhoUnset
                        : l10n.cshWhoGone,
                    style: SatType.bodyM(color: sc.textLo),
                  ),
                ),
                SatButton.outline(
                  label: l10n.cshMemberFind,
                  icon: Icons.person_search_outlined,
                  size: SatButtonSize.sm,
                  onTap: live ? () => _pick(context) : null,
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: sc.accentText),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: SatType.labelM(color: sc.textHi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(m.phone, style: SatType.mono(color: sc.textLo)),
                    ],
                  ),
                ),
                if (cfg.memberPointsEnabled)
                  SatChip.tag(
                    label: l10n.memPoints(m.points),
                    hue: SatChipHue.accent,
                    size: SatChipSize.sm,
                  ),
              ],
            ),
            const SizedBox(height: Sp.s2h),
            Row(
              children: [
                if (cfg.memberPointsEnabled)
                  Expanded(
                    child: receipt.redeemDiscount == null
                        ? SatButton.outline(
                            label: l10n.cshMemberRedeem,
                            icon: Icons.redeem_outlined,
                            size: SatButtonSize.sm,
                            onTap: live && m.points > 0
                                ? () => _redeem(context, ref, m)
                                : null,
                          )
                        : SatButton.outline(
                            label: l10n.cshMemberRedeemUndo(
                              formatIDR(receipt.redeemDiscount!.amount),
                            ),
                            icon: Icons.undo_rounded,
                            size: SatButtonSize.sm,
                            onTap: live
                                ? () => run(
                                    () => repo.removeReceiptRedeem(receipt.id),
                                  )
                                : null,
                          ),
                  ),
                const SizedBox(width: Sp.s2),
                SatButton.ghost(
                  label: l10n.cshMemberDetach,
                  size: SatButtonSize.sm,
                  onTap: live
                      ? () => run(() => repo.detachReceiptMember(receipt.id))
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showSatSheet<MemberDto>(
      context,
      builder: (_) => const MemberLookupSheet(),
    );
    if (picked == null) return;
    await run(() => repo.attachReceiptMember(receipt.id, picked.id));
  }

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    MemberDto member,
  ) async {
    final cfg = ref.read(venueSettingsProvider);
    // What *this share* can absorb, not the bill: spending a guest's points on
    // money someone else is paying is the one outcome worth designing against.
    final room = receipt.total - receipt.serviceAmount - receipt.taxAmount;
    final points = await showSatSheet<int>(
      context,
      builder: (_) => RedeemSheet(
        points: member.points,
        room: room,
        pointValue: cfg.memberPointValue,
        minPoints: cfg.memberRedeemMin,
      ),
    );
    if (points == null || points <= 0) return;
    await run(() => repo.redeemOnReceipt(receipt.id, points));
  }
}
