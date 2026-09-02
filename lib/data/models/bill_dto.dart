/// Hand-written parse models for the settlement (`/settlement/*`) API. Plain
/// Dart — no codegen — since the bill shape is read-mostly and assembled
/// server-side. See ADR-0023 and CONTEXT.md (Bill / Split bill / Payment).
library;

import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

import 'package:satset/data/models/member_dto.dart';
import 'package:satset/domain/models/ticket_modifier.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Decode a line's snapshotted add-ons. The server emits `modifiersJson` as
/// the raw stored JSON string (a list of {groupId, optionId, label,
/// priceDelta}); be defensive about a string vs already-decoded list.
List<TicketModifier> _modifiers(Object? raw) {
  if (raw == null) return const [];
  final decoded = raw is String
      ? (raw.trim().isEmpty ? const [] : jsonDecode(raw))
      : raw;
  if (decoded is! List) return const [];
  return [
    for (final m in decoded)
      if (m is Map)
        TicketModifier(
          groupId: m['groupId'] as String? ?? '',
          optionId: m['optionId'] as String? ?? '',
          label: m['label'] as String? ?? '',
          priceDelta: _int(m['priceDelta']),
        ),
  ];
}

/// Lighter row for the cashier's payable list. Keyed by [[Visit]] now — a
/// `detached` summary is a freed-table bill still owing (ADR-0024).
class BillSummary {
  final String visitId;
  final String tableId;
  final String? tableLabel;

  /// dineIn | takeaway — drives the cashier's "Bawa pulang" copy. ADR-0026.
  final String kind;
  final String status;
  final bool detached;
  final DateTime? tableFreedAt;
  final int pax;
  final String? guestName;

  /// The card leads with the zone (dine-in) or the [channel] (takeaway), and
  /// states how long the party has been sitting.
  final String zoneId;
  final DateTime? openedAt;

  /// bungkus | telepon | gofood | grab, empty for dine-in. The card's channel
  /// pill — a takeaway's stand-in for a dine-in's zone. ADR-0066.
  final String channel;

  /// An aggregator already settled this order, so there is nothing to collect.
  /// Not derived from [channel]: an aggregator order can be cash-on-delivery.
  final bool prepaid;
  final int total;
  final int paidAmount;
  final int outstanding;
  final int receiptCount;

  /// Sent, non-voided lines on the bill — the card's `N item` pill.
  final int lineCount;

  /// The bill-scope discount's name, or null. The card states it by name; the
  /// amount alone would read as an unexplained cut. ADR-0070.
  final String? billDiscountLabel;

  /// The [[Pelanggan (member)]] on this bill, by name — the card's member pill.
  final String? memberName;

  /// How much of this bill has already been discharged onto a member's
  /// [[Piutang]] tab (ADR-0098), net of refunded legs. 0 on an ordinary bill.
  ///
  /// Live, not only in history: a [[Split bill]] whose struk B went on account
  /// is still open at struk A, and that is exactly the bill a cashier settles
  /// the rest of without noticing a tab was taken.
  final int piutangAmount;

  /// Letter + paid-ness per receipt, in bill order — the `/kasir` card's
  /// progress strip. Empty on a bill nobody has paid into yet. ADR-0063.
  final List<BillSummaryReceipt> receipts;

  /// itemized | even | **mixed**. A description of what the receipts are, not a
  /// setting — mode is chosen per payment since ADR-0067, so one bill can hold
  /// both kinds.
  final String mode;
  final bool fullySettled;

  const BillSummary({
    required this.visitId,
    required this.tableId,
    required this.tableLabel,
    required this.kind,
    required this.status,
    required this.detached,
    required this.tableFreedAt,
    required this.pax,
    required this.guestName,
    required this.zoneId,
    required this.openedAt,
    required this.channel,
    required this.prepaid,
    required this.total,
    required this.paidAmount,
    required this.outstanding,
    required this.receiptCount,
    required this.lineCount,
    required this.billDiscountLabel,
    required this.memberName,
    this.piutangAmount = 0,
    required this.receipts,
    required this.mode,
    required this.fullySettled,
  });

  bool get isTakeaway => kind == 'takeaway';
  bool get isOnAccount => piutangAmount > 0;

  /// Amount receipts on this bill, and how many are settled — the card's
  /// `Bagi 3 · 1 bayar` pill. An amount receipt carries no letter (ADR-0063),
  /// so it is counted rather than named.
  int get evenShareCount =>
      receipts.where((r) => r.label.startsWith('Bagian ')).length;
  int get evenSharesPaid =>
      receipts.where((r) => r.label.startsWith('Bagian ') && r.paid).length;

  factory BillSummary.fromJson(Map<String, dynamic> j) => BillSummary(
    visitId: j['visitId'] as String? ?? '',
    tableId: j['tableId'] as String,
    tableLabel: j['tableLabel'] as String?,
    kind: j['kind'] as String? ?? 'dineIn',
    status: j['status'] as String? ?? 'occupied',
    detached: j['detached'] as bool? ?? false,
    tableFreedAt: DateTime.tryParse(j['tableFreedAt'] as String? ?? ''),
    pax: _int(j['pax']),
    guestName: j['guestName'] as String?,
    zoneId: j['zoneId'] as String? ?? '',
    openedAt: DateTime.tryParse(j['openedAt'] as String? ?? ''),
    channel: j['channel'] as String? ?? '',
    prepaid: j['prepaid'] as bool? ?? false,
    total: _int(j['total']),
    paidAmount: _int(j['paidAmount']),
    outstanding: _int(j['outstanding']),
    receiptCount: _int(j['receiptCount']),
    lineCount: _int(j['lineCount']),
    billDiscountLabel: j['billDiscountLabel'] as String?,
    memberName: j['memberName'] as String?,
    piutangAmount: _int(j['piutangAmount']),
    receipts: [
      for (final r in (j['receipts'] as List? ?? const []))
        BillSummaryReceipt.fromJson((r as Map).cast<String, dynamic>()),
    ],
    mode: j['mode'] as String? ?? 'itemized',
    fullySettled: j['fullySettled'] as bool? ?? false,
  );
}

/// One receipt as it appears on the `/kasir` list — its [[Split bill]] letter
/// and whether it is settled. Deliberately thinner than [BillReceipt]: the
/// list only draws a strip of badges, and a payable payload spans every open
/// visit in the venue. ADR-0063.
class BillSummaryReceipt {
  final String label;
  final bool paid;

  const BillSummaryReceipt({required this.label, required this.paid});

  factory BillSummaryReceipt.fromJson(Map<String, dynamic> j) =>
      BillSummaryReceipt(
        label: j['label'] as String? ?? '',
        paid: j['paid'] as bool? ?? false,
      );
}

/// One page of cashier history (`/settlement/history`). Roughly three screens
/// of bill cards on a tablet, so the first fetch covers a normal day whole.
const historyPageSize = 60;

/// The most rows that endpoint will ever hand back, however far a cashier
/// scrolls. The client grows its limit and refetches (ADR-0079), and every
/// `tableSession.closed` refetches at whatever limit is current — so an
/// unbounded limit would leave a busy venue re-sending a fat payload on every
/// bill close for the rest of the shift. Older bills are the reports' job.
const historyPageCeiling = 300;

/// One page of cashier history, plus how many rows the window actually holds.
///
/// [total] is not `rows.length` — it counts the whole day-window server-side,
/// while [rows] is only the newest page of it. The Lunas count reads [total];
/// counting loaded rows is the bug ADR-0072 documented for the audit log and
/// ADR-0079 kept out of here.
class PastBillPage {
  final List<PastBillSummary> rows;
  final int total;

  /// Every rupiah in the window that went out on a member's tab (ADR-0098).
  /// Window-wide and **unfiltered**, so switching the Piutang filter on does
  /// not change the number the chip carrying it reads.
  final int piutangTotal;

  const PastBillPage({
    required this.rows,
    required this.total,
    this.piutangTotal = 0,
  });

  static const empty = PastBillPage(rows: [], total: 0);

  /// Whether the server is holding rows this page didn't ask for.
  bool get hasMore => rows.length < total;
}

/// A closed bill in the cashier's per-table history (last 7 days), from a
/// snapshotted TableSession. See ADR-0024.
class PastBillSummary {
  final String sessionId;
  final String tableId;
  final String? tableLabel;

  /// dineIn | takeaway — frozen at snapshot. Drives the card's chip + layout
  /// (Bawa pulang glyph vs table-label chip). ADR-0026.
  final String kind;

  /// Channel + prepaid, frozen at snapshot so a closed GoFood order still reads
  /// as one in the cashier's Lunas segment. ADR-0066.
  final String channel;
  final bool prepaid;
  final int pax;
  final DateTime closedAt;
  final int netTotal;
  final int lossAmount;
  final int ticketCount;

  /// How much of this closed bill was discharged onto a member's [[Piutang]]
  /// tab (ADR-0098), net of any leg since refunded. 0 on an ordinary bill.
  ///
  /// The bill is still **Lunas** — the claim was discharged, the revenue was
  /// booked. This is the separate, orthogonal fact that somebody still owes
  /// the venue for it.
  final int piutangAmount;

  const PastBillSummary({
    required this.sessionId,
    required this.tableId,
    required this.tableLabel,
    required this.kind,
    required this.channel,
    required this.prepaid,
    required this.pax,
    required this.closedAt,
    required this.netTotal,
    required this.lossAmount,
    required this.ticketCount,
    this.piutangAmount = 0,
  });

  bool get isWriteOff => lossAmount > 0;
  bool get isOnAccount => piutangAmount > 0;
  bool get isTakeaway => kind == 'takeaway';

  factory PastBillSummary.fromJson(Map<String, dynamic> j) => PastBillSummary(
    sessionId: j['sessionId'] as String,
    tableId: j['tableId'] as String? ?? '',
    tableLabel: j['tableLabel'] as String?,
    kind: j['kind'] as String? ?? 'dineIn',
    channel: j['channel'] as String? ?? '',
    prepaid: j['prepaid'] as bool? ?? false,
    pax: _int(j['pax']),
    closedAt:
        DateTime.tryParse(j['closedAt'] as String? ?? '') ?? SatClock.now(),
    netTotal: _int(j['netTotal']),
    lossAmount: _int(j['lossAmount']),
    ticketCount: _int(j['ticketCount']),
    piutangAmount: _int(j['piutangAmount']),
  );
}

class BillLine {
  final String ticketId;
  final String itemId;
  final String name;
  final String variantName;
  final int qty;
  final int unitPrice;
  final int lineTotal;
  final int assignedUnits;
  final String? note;
  final String status;
  final String? memberId;
  final String? memberName;
  final bool memberLocked;

  /// Add-ons the guest chose, snapshotted at order time. Shown under the line.
  final List<TicketModifier> modifiers;

  /// When the line was fired to the kitchen — the `(table, sentAt)` batch key
  /// the cashier lines are grouped by. Null on legacy rows.
  final DateTime? sentAt;

  const BillLine({
    required this.ticketId,
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.assignedUnits,
    required this.note,
    required this.status,
    this.memberId,
    this.memberName,
    this.memberLocked = false,
    required this.modifiers,
    required this.sentAt,
  });

  int get unassignedUnits => (qty - assignedUnits).clamp(0, qty);

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
    ticketId: j['ticketId'] as String,
    itemId: j['itemId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    variantName: j['variantName'] as String? ?? '',
    qty: _int(j['qty']),
    unitPrice: _int(j['unitPrice']),
    lineTotal: _int(j['lineTotal']),
    assignedUnits: _int(j['assignedUnits']),
    note: j['note'] as String?,
    status: j['status'] as String? ?? 'sent',
    memberId: j['memberId'] as String?,
    memberName: j['memberName'] as String?,
    memberLocked: j['memberLocked'] == true,
    modifiers: _modifiers(j['modifiersJson']),
    sentAt: DateTime.tryParse(j['sentAt'] as String? ?? ''),
  );
}

class BillPayment {
  /// Live payment id (`id`) or, on a past-bill snapshot, the session-payment id
  /// (`paymentId`). Keys the proof-photo fetch route (ADR-0025).
  final String id;
  final String method;
  final int amount;
  final bool isRefund;

  /// On a refund row, the payment it unwinds (ADR-0121). Null on a payment and
  /// on a refund written before the tender lock came off — a struk could hold
  /// only one method then, so there was no leg to name.
  final String? refundsPaymentId;
  final int? tendered;
  final String? note;
  final DateTime at;

  /// True when a mandatory non-cash proof photo is attached and fetchable.
  final bool hasPhoto;

  const BillPayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.isRefund,
    required this.refundsPaymentId,
    required this.tendered,
    required this.note,
    required this.at,
    required this.hasPhoto,
  });

  factory BillPayment.fromJson(Map<String, dynamic> j) => BillPayment(
    id: (j['id'] ?? j['paymentId']) as String? ?? '',
    method: j['method'] as String? ?? 'tunai',
    amount: _int(j['amount']),
    isRefund: j['isRefund'] as bool? ?? false,
    refundsPaymentId: j['refundsPaymentId'] as String?,
    tendered: (j['tendered'] as num?)?.toInt(),
    note: j['note'] as String?,
    at: DateTime.tryParse(j['at'] as String? ?? '') ?? SatClock.now(),
    hasPhoto: j['hasPhoto'] as bool? ?? false,
  );
}

class BillReceiptLine {
  final String ticketId;
  final int qtyUnits;
  const BillReceiptLine(this.ticketId, this.qtyUnits);
}

/// An applied [[Diskon (discount)]] on a receipt. `ticketId == null` ⇒ a
/// whole-order discount; set ⇒ a line discount on that line's units.
///
/// `name`/`kind`/`value` were snapshotted when the discount was applied — never
/// re-read from the live preset, so a later preset edit cannot rewrite what a
/// settled bill said (ADR-0037).
class BillDiscount {
  final String id;
  final String? ticketId;
  final String? presetId;
  final String name;
  final String kind; // percent | fixed
  final int value; // bps (percent) | rupiah (fixed)
  final int amount;
  final String? approvedByUserId;

  /// manual | member | redeem — which authority gave this away (ADR-0094).
  /// Only a `manual` row is the cashier's to add and remove from the discount
  /// button; the other two belong to the member panel.
  final String source;

  const BillDiscount({
    required this.id,
    required this.ticketId,
    required this.presetId,
    required this.name,
    required this.kind,
    required this.value,
    required this.amount,
    required this.approvedByUserId,
    this.source = 'manual',
  });

  bool get isLine => ticketId != null;

  /// "Diskon Member 10%" — what prints on the money doc and shows in the UI.
  String get label =>
      kind == 'percent' ? '$name ${(value / 100).toStringAsFixed(0)}%' : name;

  factory BillDiscount.fromJson(Map<String, dynamic> j) => BillDiscount(
    id: (j['id'] ?? j['discountId']) as String? ?? '',
    ticketId: j['ticketId'] as String?,
    presetId: j['presetId'] as String?,
    name: j['name'] as String? ?? 'Diskon',
    kind: j['kind'] as String? ?? 'percent',
    value: _int(j['value']),
    amount: _int(j['amount']),
    approvedByUserId: j['approvedByUserId'] as String?,
    source: j['source'] as String? ?? 'manual',
  );
}

class BillReceipt {
  final String id;
  final String mode;
  final String label;
  final int subtotal;
  final int discountAmount;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status;
  final int paidNet;

  /// The [[Pemilik struk]] — who this share is *for* (ADR-0118). Null at a
  /// venue without the `memberSplit` mode and on any share nobody named, whose
  /// money is the [[Pemilik tagihan]]'s.
  final String? memberId;

  /// The same member carried whole, so the Siapa step can show a points balance
  /// without a round trip. Null when [memberId] names someone since deleted —
  /// the share was still theirs (ADR-0092), so the id outlives the person and
  /// the UI renders its own placeholder.
  final MemberDto? member;
  final List<BillReceiptLine> lines;
  final List<BillPayment> payments;
  final List<BillDiscount> discounts;

  const BillReceipt({
    required this.id,
    required this.mode,
    required this.label,
    required this.subtotal,
    required this.discountAmount,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.paidNet,
    required this.memberId,
    required this.member,
    required this.lines,
    required this.payments,
    required this.discounts,
  });

  bool get isPaid => status == 'paid';
  int get outstanding => (total - paidNet).clamp(0, 1 << 31);

  /// What one **leg** still has to give back (ADR-0121): its own amount, less
  /// every refund already written against it.
  ///
  /// A `piutang` leg counts. It hands nothing back from the drawer — the
  /// refund writes a [[Piutang]] reversal instead — which is ADR-0098's rule
  /// kept intact by inheriting the method rather than by hiding the leg.
  int refundableOf(BillPayment leg) {
    if (leg.isRefund) return 0;
    var left = leg.amount;
    for (final p in payments) {
      if (p.refundsPaymentId == leg.id) left += p.amount;
    }
    return left < 0 ? 0 : left;
  }

  /// The legs a refund may still target, in the order they were taken. This is
  /// what the refund sheet lists — a refund names a leg, never a method, since
  /// two `tunai` legs on one struk are indistinguishable by method.
  List<BillPayment> get refundableLegs => [
    for (final p in payments)
      if (!p.isRefund && refundableOf(p) > 0) p,
  ];

  /// Everything still refundable across the struk — the button's gate and the
  /// figure the sheet caps against when no leg is picked yet.
  int get refundable {
    var sum = 0;
    for (final p in payments) {
      if (!p.isRefund) sum += refundableOf(p);
    }
    return sum;
  }

  /// The **cashier's own** whole-order discount, if any.
  ///
  /// Filtered to `manual` since ADR-0118: order scope now holds one slot per
  /// source, the same way bill scope has since ADR-0094, so the member's tier
  /// discount and a redemption sit alongside this one rather than in it.
  /// Returning the first non-line row would put a member's give-back behind
  /// the cashier's own discount button, where removing it would silently take
  /// back points.
  BillDiscount? get orderDiscount => _orderDiscountOf('manual');

  /// The [[Pemilik struk]]'s standing tier discount on this share.
  BillDiscount? get memberDiscount => _orderDiscountOf('member');

  /// Their points redemption against this share.
  BillDiscount? get redeemDiscount => _orderDiscountOf('redeem');

  BillDiscount? _orderDiscountOf(String source) {
    for (final d in discounts) {
      if (!d.isLine && d.source == source) return d;
    }
    return null;
  }

  /// The line discount on [ticketId], if any. At most one per line.
  BillDiscount? lineDiscount(String ticketId) {
    for (final d in discounts) {
      if (d.ticketId == ticketId) return d;
    }
    return null;
  }

  factory BillReceipt.fromJson(Map<String, dynamic> j) => BillReceipt(
    id: j['id'] as String,
    mode: j['mode'] as String? ?? 'itemized',
    label: j['label'] as String? ?? '',
    subtotal: _int(j['subtotal']),
    discountAmount: _int(j['discountAmount']),
    serviceAmount: _int(j['serviceAmount']),
    taxAmount: _int(j['taxAmount']),
    total: _int(j['total']),
    status: j['status'] as String? ?? 'unpaid',
    paidNet: _int(j['paidNet']),
    memberId: j['memberId'] as String?,
    member: j['member'] == null
        ? null
        : MemberDto.fromJson((j['member'] as Map).cast<String, dynamic>()),
    lines: [
      for (final l in (j['lines'] as List? ?? const []))
        BillReceiptLine(
          (l as Map)['ticketId'] as String,
          _int((l)['qtyUnits']),
        ),
    ],
    payments: [
      for (final p in (j['payments'] as List? ?? const []))
        BillPayment.fromJson((p as Map).cast<String, dynamic>()),
    ],
    discounts: [
      for (final d in (j['discounts'] as List? ?? const []))
        BillDiscount.fromJson((d as Map).cast<String, dynamic>()),
    ],
  );
}

class Bill {
  final String visitId;
  final String tableId;
  final String? tableLabel;

  /// dineIn | takeaway — ADR-0026.
  final String kind;
  final String status;
  final bool detached;
  final DateTime? tableFreedAt;
  final DateTime? billClosedAt;
  final int pax;
  final String? guestName;

  /// Takeaway channel + prepaid flag. ADR-0066.
  final String channel;
  final bool prepaid;

  /// itemized | even | **mixed** — a description of the receipts, not a
  /// setting. Mode is chosen per payment since ADR-0067.
  final String mode;
  final int subtotal;

  /// Total give-back on this bill (line + whole-order + bill scope).
  final int discountAmount;

  /// The bill-scope discounts — they belong to the visit rather than to any
  /// receipt, so the totals ladder reads them from here. ADR-0070, a list since
  /// ADR-0094: one slot per [[Sumber diskon (discount source)|source]].
  final List<BillDiscount> billDiscounts;

  /// The [[Pelanggan (member)]] on this bill, or null. The [[Pemilik tagihan]]
  /// since ADR-0118: they own the bill, and any money no share claims is
  /// theirs.
  final MemberDto? member;

  /// Whether this venue may name a [[Pemilik struk]] per receipt (ADR-0118).
  ///
  /// Server-composed in `MemberConfig.splitEnabled` — the mode key, the
  /// `members` module and the owner's own switch, ANDed once. Read it rather
  /// than re-deriving the same AND from a module list, the rule ADR-0107 puts
  /// on every floor surface.
  final bool splitEnabled;
  final bool ticketAttribution;
  final int serviceAmount;
  final int taxAmount;
  final int total;

  /// Where a whole-order discount sits in the stack (ADR-0038) — drives the
  /// Diskon row's position on the money doc, which must match the arithmetic.
  final bool taxAfterDiscount;
  final int paidAmount;
  final int outstanding;
  final bool fullyAssigned;
  final bool fullySettled;
  final List<BillLine> lines;
  final List<BillReceipt> receipts;

  const Bill({
    required this.visitId,
    required this.tableId,
    required this.tableLabel,
    required this.kind,
    required this.status,
    required this.detached,
    required this.tableFreedAt,
    required this.billClosedAt,
    required this.pax,
    required this.guestName,
    required this.channel,
    required this.prepaid,
    required this.mode,
    required this.subtotal,
    required this.discountAmount,
    required this.billDiscounts,
    required this.member,
    required this.splitEnabled,
    this.ticketAttribution = false,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.taxAfterDiscount,
    required this.paidAmount,
    required this.outstanding,
    required this.fullyAssigned,
    required this.fullySettled,
    required this.lines,
    required this.receipts,
  });

  bool get isTakeaway => kind == 'takeaway';

  /// The cashier's own bill discount — the one slot the discount button fills
  /// and empties. A member discount or a redemption is the member panel's.
  BillDiscount? get billDiscount {
    for (final d in billDiscounts) {
      if (d.source == 'manual') return d;
    }
    return null;
  }

  /// The live points redemption on this bill, or null.
  BillDiscount? get redeemDiscount {
    for (final d in billDiscounts) {
      if (d.source == 'redeem') return d;
    }
    return null;
  }

  /// Grow a raw subtotal by this bill's own effective service+tax rate.
  ///
  /// Derived from the bill rather than re-read from settings, so a preview can
  /// never disagree with the total printed above it — and it lives here rather
  /// than beside either caller because the Per item confirm button and the
  /// printed [[Rincian pilihan]] slip must state the same number.
  int prorate(int amount) {
    if (amount <= 0 || subtotal <= 0) return amount.clamp(0, 1 << 31);
    return (amount * total / subtotal).round();
  }

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
    visitId: j['visitId'] as String? ?? '',
    tableId: j['tableId'] as String,
    tableLabel: j['tableLabel'] as String?,
    kind: j['kind'] as String? ?? 'dineIn',
    status: j['status'] as String? ?? 'occupied',
    detached: j['detached'] as bool? ?? false,
    tableFreedAt: DateTime.tryParse(j['tableFreedAt'] as String? ?? ''),
    billClosedAt: DateTime.tryParse(j['billClosedAt'] as String? ?? ''),
    pax: _int(j['pax']),
    guestName: j['guestName'] as String?,
    channel: j['channel'] as String? ?? '',
    prepaid: j['prepaid'] as bool? ?? false,
    mode: j['mode'] as String? ?? 'itemized',
    subtotal: _int(j['subtotal']),
    discountAmount: _int(j['discountAmount']),
    billDiscounts: [
      for (final d in (j['billDiscounts'] as List? ?? const []))
        BillDiscount.fromJson((d as Map).cast<String, dynamic>()),
    ],
    member: j['member'] == null
        ? null
        : MemberDto.fromJson((j['member'] as Map).cast<String, dynamic>()),
    // Absent on an older server: fail closed, exactly as the mode key does.
    splitEnabled: j['splitEnabled'] == true,
    ticketAttribution: j['ticketAttribution'] == true,
    serviceAmount: _int(j['serviceAmount']),
    taxAmount: _int(j['taxAmount']),
    total: _int(j['total']),
    taxAfterDiscount: j['taxAfterDiscount'] as bool? ?? true,
    paidAmount: _int(j['paidAmount']),
    outstanding: _int(j['outstanding']),
    fullyAssigned: j['fullyAssigned'] as bool? ?? false,
    fullySettled: j['fullySettled'] as bool? ?? false,
    lines: [
      for (final l in (j['lines'] as List? ?? const []))
        BillLine.fromJson((l as Map).cast<String, dynamic>()),
    ],
    receipts: [
      for (final r in (j['receipts'] as List? ?? const []))
        BillReceipt.fromJson((r as Map).cast<String, dynamic>()),
    ],
  );
}
