import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/members_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/features/admin/members_screen.dart';

/// The [[Pelanggan (member)]] row on a live bill (ADR-0093).
///
/// Membership pays out here and nowhere else: this is the only surface where a
/// guest's points turn into money off, because it is the only surface that
/// knows what they owe. Everything it can do is refused server-side once a
/// payment lands — a quote the guest was already given is not re-priced.
class MemberPanel extends ConsumerWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;

  const MemberPanel({
    super.key,
    required this.bill,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(venueSettingsProvider);
    // The venue never opted in, so there is no row to draw — not an empty one.
    if (!cfg.membersEnabled) return const SizedBox.shrink();

    final sc = context.sat;
    final l10n = context.l10n;
    final member = bill.member;
    // Frozen at the first payment, exactly like a bill discount (ADR-0068).
    final live = bill.billClosedAt == null && bill.paidAmount == 0;

    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s3h),
      child: member == null
          ? Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: sc.textLo),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    l10n.cshMemberNone,
                    style: SatType.bodyM(color: sc.textLo),
                  ),
                ),
                SatButton.outline(
                  label: l10n.cshMemberFind,
                  icon: Icons.person_search_outlined,
                  size: SatButtonSize.sm,
                  onTap: live ? () => _lookup(context, ref) : null,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: sc.accentText),
                    const SizedBox(width: Sp.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: SatType.labelM(color: sc.textHi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            member.phone,
                            style: SatType.mono(color: sc.textLo),
                          ),
                        ],
                      ),
                    ),
                    if (cfg.memberPointsEnabled)
                      SatChip.tag(
                        label: l10n.memPoints(member.points),
                        hue: SatChipHue.accent,
                        size: SatChipSize.sm,
                      ),
                    if (member.punchRewardDue) ...[
                      const SizedBox(width: Sp.s2),
                      // The reward is a comp through the ordinary void-with-comp
                      // flow, so this is a reminder, not a button: the cashier
                      // comps the free portion on the line itself.
                      SatChip.tag(
                        label: l10n.memRewardDue,
                        hue: SatChipHue.success,
                        size: SatChipSize.sm,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Sp.s2h),
                Row(
                  children: [
                    if (cfg.memberPointsEnabled)
                      Expanded(
                        child: bill.redeemDiscount == null
                            ? SatButton.outline(
                                label: l10n.cshMemberRedeem,
                                icon: Icons.redeem_outlined,
                                size: SatButtonSize.sm,
                                onTap: live && member.points > 0
                                    ? () => _redeem(context, ref, member)
                                    : null,
                              )
                            : SatButton.outline(
                                label: l10n.cshMemberRedeemUndo(
                                  formatIDR(bill.redeemDiscount!.amount),
                                ),
                                icon: Icons.undo_rounded,
                                size: SatButtonSize.sm,
                                onTap: live
                                    ? () => run(
                                        () => repo.removeRedeem(bill.visitId),
                                      )
                                    : null,
                              ),
                      ),
                    const SizedBox(width: Sp.s2),
                    SatButton.ghost(
                      label: l10n.cshMemberDetach,
                      size: SatButtonSize.sm,
                      onTap: live
                          ? () => run(() => repo.detachMember(bill.visitId))
                          : null,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _lookup(BuildContext context, WidgetRef ref) async {
    final picked = await showSatSheet<MemberDto>(
      context,
      builder: (_) => const _LookupSheet(),
    );
    if (picked == null) return;
    await run(() => repo.attachMember(bill.visitId, picked.id));
  }

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    MemberDto member,
  ) async {
    final points = await showSatSheet<int>(
      context,
      builder: (_) => _RedeemSheet(member: member, bill: bill),
    );
    if (points == null || points <= 0) return;
    await run(() => repo.redeemPoints(bill.visitId, points));
  }
}

/// Find the guest, or enrol them on the spot. One sheet, because at the till
/// "who are you" and "let's sign you up" are the same thirty seconds.
class _LookupSheet extends ConsumerStatefulWidget {
  const _LookupSheet();

  @override
  ConsumerState<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends ConsumerState<_LookupSheet> {
  final _q = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(membersProvider.notifier).search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(membersProvider.notifier).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final results = ref.watch(membersProvider).members;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.s5,
          0,
          Sp.s5,
          MediaQuery.of(context).viewInsets.bottom + Sp.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cshMemberFind,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            SatField.search(
              controller: _q,
              hint: l10n.memSearchHint,
              autofocus: true,
              onChanged: _onQuery,
            ),
            const SizedBox(height: Sp.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        l10n.memEmptyTitle,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: Sp.s1h),
                      itemBuilder: (_, i) => SatButton.outline(
                        label: '${results[i].name} · ${results[i].phone}',
                        onTap: () => Navigator.of(context).pop(results[i]),
                      ),
                    ),
            ),
            const SizedBox(height: Sp.s3),
            SatButton.primary(
              label: l10n.cshMemberEnrol,
              icon: Icons.person_add_alt_1_rounded,
              onTap: () async {
                final made = await showSatSheet<MemberDto>(
                  context,
                  // What the cashier typed is almost always the number they
                  // just read off the guest's phone.
                  builder: (_) => MemberFormSheet(initialPhone: _q.text.trim()),
                );
                if (made != null && context.mounted) {
                  Navigator.of(context).pop(made);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// How many points to spend. The ceiling is the smaller of what they have and
/// what this bill can absorb — spending points on nothing is the one outcome
/// worth designing against.
class _RedeemSheet extends ConsumerStatefulWidget {
  final MemberDto member;
  final Bill bill;
  const _RedeemSheet({required this.member, required this.bill});

  @override
  ConsumerState<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends ConsumerState<_RedeemSheet> {
  final _points = TextEditingController();

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_points.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cfg = ref.watch(venueSettingsProvider);
    final room =
        widget.bill.total - widget.bill.serviceAmount - widget.bill.taxAmount;
    final maxByBill = cfg.memberPointValue <= 0
        ? 0
        : room ~/ cfg.memberPointValue;
    final max = widget.member.points < maxByBill
        ? widget.member.points
        : maxByBill;
    final ok = _value >= cfg.memberRedeemMin && _value <= max;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.s5,
          0,
          Sp.s5,
          MediaQuery.of(context).viewInsets.bottom + Sp.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cshMemberRedeem,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            Text(
              l10n.cshMemberRedeemMax(max),
              style: SatType.bodyS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s3),
            SatField.number(
              controller: _points,
              label: l10n.memFieldDelta,
              hint: '',
              autofocus: true,
              // The rupiah the points are about to become, updated as they are
              // typed: points are an abstraction, money is not.
              helperText: l10n.cshMemberRedeemWorth(
                formatIDR(_value * cfg.memberPointValue),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Sp.s4),
            SatButton.primary(
              label: l10n.cshMemberRedeem,
              onTap: ok ? () => Navigator.of(context).pop(_value) : null,
            ),
            const SizedBox(height: Sp.s2),
            SatButton.ghost(
              label: l10n.cshMemberRedeemAll,
              onTap: max >= cfg.memberRedeemMin
                  ? () => Navigator.of(context).pop(max)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
