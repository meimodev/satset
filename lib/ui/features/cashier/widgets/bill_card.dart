import 'package:flutter/material.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/domain/models/receipt_label.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/features/cashier/receipt_badge.dart';
import 'package:satset/ui/core/design/channel_visuals.dart';

/// What a bill card is showing. A closed bill renders in the *same* card as a
/// live one so the Semua segment is not two vocabularies — only the amount's
/// caption changes.
enum BillCardState { open, partial, settled, writeOff }

/// One payable bill on the `/kasir` grid.
///
/// Stacked rows, per the design source: identity (the name, and the status
/// pill hard against the far edge), the zone or channel it belongs to, the
/// amount that matters, a paid-progress bar, a pill row of everything else true
/// about the bill, and a foot that names who owns it and what tapping does. The
/// amount is the point — it is the only thing at display size, and the caption
/// under it says which number it is, because "Rp 340.000" means the opposite
/// thing on a settled bill than on an open one.
///
/// The card's outline repeats the status colour, so the state is legible from
/// the grid without reading the pill. An open bill has no status, so it takes
/// the neutral `border0` — on Perlu Ditagih, where most bills are open, a
/// coloured outline on every card would mean nothing.
class BillCard extends StatelessWidget {
  final String label;
  final BillCardState state;

  /// Dine-in leads with its zone; a takeaway leads with its [channel] pill.
  final Zone? zone;
  final SatChannel? channel;

  /// `4 tamu` for dine-in, the guest name for a takeaway.
  final String who;

  /// The big number, and the caption naming which number it is.
  final int amount;
  final String amountCaption;

  final int paid;
  final int total;
  final int lineCount;
  final DateTime? since;

  /// `duduk` for a seated party, `masuk` for a takeaway that arrived.
  final String sinceVerb;

  /// Extra facts, each earned: a bill discount by name, a detached table, an
  /// even split's tally, a prepaid aggregator order.
  final String? discountLabel;
  final bool detached;
  final int evenShares;
  final int evenSharesPaid;
  final bool prepaid;

  /// Itemized receipts only — an amount receipt has no letter (ADR-0063).
  final List<BillSummaryReceipt> letters;

  final String footNote;
  final VoidCallback onTap;

  const BillCard({
    super.key,
    required this.label,
    required this.state,
    required this.zone,
    required this.channel,
    required this.who,
    required this.amount,
    required this.amountCaption,
    required this.paid,
    required this.total,
    required this.lineCount,
    required this.since,
    required this.sinceVerb,
    required this.discountLabel,
    required this.detached,
    required this.evenShares,
    required this.evenSharesPaid,
    required this.prepaid,
    required this.letters,
    required this.footNote,
    required this.onTap,
  });

  /// Build straight off the live payable payload.
  factory BillCard.fromSummary(
    BillSummary b, {
    required Zone? zone,
    required VoidCallback onTap,
  }) {
    final settled = b.fullySettled;
    final partial = !settled && b.paidAmount > 0;
    return BillCard(
      label: b.isTakeaway
          ? (b.tableLabel ?? 'Bawa pulang')
          : (b.tableLabel ?? '—'),
      state: settled
          ? BillCardState.settled
          : partial
          ? BillCardState.partial
          : BillCardState.open,
      zone: b.isTakeaway ? null : zone,
      channel: b.isTakeaway ? SatChannel.from(b.channel) : null,
      who: b.isTakeaway
          ? (b.guestName?.trim().isNotEmpty == true
                ? b.guestName!.trim()
                : 'Tanpa nama')
          : '${b.pax} tamu',
      amount: settled ? b.total : b.outstanding,
      amountCaption: settled ? 'total dibayar' : 'sisa tagihan',
      paid: b.paidAmount,
      total: b.total,
      lineCount: b.lineCount,
      since: b.openedAt,
      sinceVerb: b.isTakeaway ? 'masuk' : 'duduk',
      discountLabel: b.billDiscountLabel,
      detached: b.detached,
      evenShares: b.evenShareCount,
      evenSharesPaid: b.evenSharesPaid,
      prepaid: b.prepaid,
      letters: [
        for (final r in b.receipts)
          if (isReceiptLetter(r.label.trim())) r,
      ],
      footNote: settled ? 'Lihat struk' : 'Tagih',
      onTap: onTap,
    );
  }

  /// Build off a closed snapshot, so the Lunas segment reads the same.
  factory BillCard.fromPastBill(
    PastBillSummary p, {
    required VoidCallback onTap,
  }) => BillCard(
    label: p.tableLabel ?? (p.isTakeaway ? 'Bawa pulang' : '—'),
    state: p.isWriteOff ? BillCardState.writeOff : BillCardState.settled,
    zone: null,
    channel: p.isTakeaway ? SatChannel.from(p.channel) : null,
    who: p.isTakeaway ? 'Bawa pulang' : '${p.pax} tamu',
    amount: p.isWriteOff ? p.lossAmount : p.netTotal,
    amountCaption: p.isWriteOff ? 'tak tertagih' : 'total dibayar',
    paid: p.isWriteOff ? 0 : p.netTotal,
    total: p.netTotal,
    lineCount: p.ticketCount,
    since: p.closedAt,
    sinceVerb: 'tutup',
    discountLabel: null,
    detached: false,
    evenShares: 0,
    evenSharesPaid: 0,
    prepaid: p.prepaid,
    letters: const [],
    footNote: 'Lihat struk',
    onTap: onTap,
  );

  (Color, String)? _statePill(SatColors sc) => switch (state) {
    BillCardState.settled => (sc.success, 'Lunas'),
    BillCardState.partial => (sc.info, 'Sebagian'),
    BillCardState.writeOff => (sc.urgent, 'Tak tertagih'),
    BillCardState.open => null,
  };

  /// The zone (dine-in) or channel (takeaway) this bill belongs to, or null
  /// when neither is known — every past dine-in bill, which carries no zone.
  Widget? _tag() {
    if (channel != null) {
      return SatChip.tag(
        label: channel!.label,
        hue: channel!.hue,
        size: SatChipSize.sm,
      );
    }
    if (zone != null) {
      // Full name, not `short`: this card has a row to itself and the dense
      // floor grids are what `short` was cut for.
      return SatChip.tag(label: zone!.name, size: SatChipSize.sm);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final pill = _statePill(sc);
    final tag = _tag();
    // The bar only earns its row while money is partly in. On an untouched or
    // a finished bill it would be a flat rule saying nothing.
    final showBar =
        paid > 0 && total > 0 && state != BillCardState.settled &&
        state != BillCardState.writeOff;
    final pct = total == 0 ? 0 : ((paid / total) * 100).round();

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: '$label, ${pill?.$2 ?? 'belum bayar'}, ${formatIDR(amount)}',
        child: PressScale(
          child: Material(
            color: sc.bg1,
            shape: RoundedRectangleBorder(
              borderRadius: SatR.a(16),
              // The pill's colour, or the neutral rule when there is no status.
              side: SatB.side(color: pill?.$1 ?? sc.border0, width: 1.5),
            ),
            child: InkWell(
              borderRadius: SatR.a(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Sp.s3h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _identity(sc, pill),
                    if (tag != null) ...[
                      const SizedBox(height: Sp.s2),
                      tag,
                    ],
                    const SizedBox(height: Sp.s3),
                    _amount(sc),
                    if (showBar) ...[
                      const SizedBox(height: Sp.s2h),
                      _progress(sc, pct),
                    ],
                    const SizedBox(height: Sp.s2h),
                    _pills(sc),
                    const SizedBox(height: Sp.s3),
                    _foot(sc),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The name and nothing else on the left, the status hard against the right.
  /// The name gets a second line before it will ellipsize — real labels ("Meja
  /// 12", "Bawa pulang") never reach it, so the truncation is a guard against
  /// the card's fixed height rather than something a cashier meets.
  Widget _identity(SatColors sc, (Color, String)? pill) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: SatType.h3(color: sc.textHi),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (pill != null) ...[
        const SizedBox(width: Sp.s2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s2,
            vertical: Sp.sHair,
          ),
          decoration: SatBox.d(
            color: pill.$1.withValues(alpha: 0.15),
            borderRadius: SatR.a(6),
          ),
          child: Text(pill.$2, style: SatType.labelS(color: pill.$1)),
        ),
      ],
    ],
  );

  Widget _amount(SatColors sc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        formatIDR(amount),
        style: SatType.monoL(
          color: state == BillCardState.writeOff
              ? sc.urgent
              : state == BillCardState.settled
              ? sc.textMd
              : sc.textHi,
        ),
      ),
      const SizedBox(height: Sp.sHair),
      Text(amountCaption, style: SatType.labelS(color: sc.textLo)),
    ],
  );

  Widget _progress(SatColors sc, int pct) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: SatR.a(4),
        child: LinearProgressIndicator(
          value: (pct / 100).clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: sc.bg3,
          valueColor: AlwaysStoppedAnimation(sc.info),
        ),
      ),
      const SizedBox(height: Sp.s1),
      Text(
        '${formatIDR(paid)} masuk · $pct%',
        style: SatType.labelS(color: sc.textLo),
      ),
    ],
  );

  Widget _pills(SatColors sc) {
    final elapsed = since == null
        ? null
        : formatElapsedId(SatClock.now().difference(since!));
    return Wrap(
      spacing: Sp.s1,
      runSpacing: Sp.s1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SatChip.tag(label: '$lineCount item', size: SatChipSize.sm),
        if (elapsed != null)
          SatChip.tag(
            label: '$sinceVerb $elapsed',
            icon: Icons.schedule_rounded,
            size: SatChipSize.sm,
          ),
        // The waiter freed the table and the money never landed — the one bill
        // on this screen that means "go find someone". ADR-0066.
        if (detached)
          SatChip.tag(
            label: 'Meja ditutup',
            hue: SatChipHue.warn,
            size: SatChipSize.sm,
          ),
        if (discountLabel != null)
          SatChip.tag(
            label: discountLabel!,
            hue: SatChipHue.warn,
            size: SatChipSize.sm,
          ),
        // An amount receipt has no identity to name, so the split is counted
        // rather than lettered (ADR-0063).
        if (evenShares > 0)
          SatChip.tag(
            label: 'Bagi $evenShares · $evenSharesPaid bayar',
            hue: SatChipHue.info,
            size: SatChipSize.sm,
          ),
        if (prepaid)
          SatChip.tag(
            label: 'Prabayar aplikasi',
            hue: SatChipHue.success,
            size: SatChipSize.sm,
          ),
        // Who is still owing, without opening the bill. ADR-0063.
        for (final r in letters)
          ReceiptBadge(r.label.trim(), filled: r.paid, dense: true),
      ],
    );
  }

  Widget _foot(SatColors sc) => Row(
    children: [
      Expanded(
        child: Text(
          who,
          style: SatType.bodyS(color: sc.textLo),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Text(footNote, style: SatType.labelM(color: sc.accentText)),
      const SizedBox(width: Sp.s1),
      Icon(Icons.chevron_right_rounded, size: 16, color: sc.accentText),
    ],
  );
}
