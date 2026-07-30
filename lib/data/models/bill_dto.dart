/// Hand-written parse models for the settlement (`/settlement/*`) API. Plain
/// Dart — no codegen — since the bill shape is read-mostly and assembled
/// server-side. See ADR-0023 and CONTEXT.md (Bill / Split bill / Payment).
library;

import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';

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
    required this.receipts,
    required this.mode,
    required this.fullySettled,
  });

  bool get isTakeaway => kind == 'takeaway';

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
  });

  bool get isWriteOff => lossAmount > 0;
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

  const BillDiscount({
    required this.id,
    required this.ticketId,
    required this.presetId,
    required this.name,
    required this.kind,
    required this.value,
    required this.amount,
    required this.approvedByUserId,
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
    required this.lines,
    required this.payments,
    required this.discounts,
  });

  bool get isPaid => status == 'paid';
  int get outstanding => (total - paidNet).clamp(0, 1 << 31);

  /// The whole-order discount, if any. At most one (ADR-0037, no stacking).
  BillDiscount? get orderDiscount {
    for (final d in discounts) {
      if (!d.isLine) return d;
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

  /// The one bill-scope discount, or null — it belongs to the visit rather
  /// than to any receipt, so the totals ladder reads it from here. ADR-0070.
  final BillDiscount? billDiscount;
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
    required this.billDiscount,
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
    billDiscount: j['billDiscount'] == null
        ? null
        : BillDiscount.fromJson(
            (j['billDiscount'] as Map).cast<String, dynamic>(),
          ),
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
