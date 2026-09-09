/// Project a cached [[Bill (tab)]] forward over the [[Antrean setelmen]]
/// (ADR-0123). Pure: no Flutter, no Drift, no IO.
///
/// The offline bill **is** `lastServerBill + localEvents` run through this, and
/// the post-drain bill is the same events run through the ordinary routes. Both
/// ends share [recomputeBill], so the only thing this file may do is *move the
/// parts around* — it must never compute money. A second money rule here is
/// exactly the drift ADR-0123 exists to prevent.
///
/// It works on the host's own bill JSON rather than a parsed model, so what
/// comes out is byte-for-byte the shape `Bill.fromJson` already eats.
library;

import 'dart:convert';

import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/bill_recompute.dart';

/// Venue facts the projection needs that the bill JSON does not carry.
class ProjectionConfig {
  final TaxServiceConfig tax;

  /// Rupiah per [[Poin]] — what a redemption is worth (`memberPointValue`).
  final int pointValue;

  const ProjectionConfig({required this.tax, this.pointValue = 1000});
}

/// Apply [events] to [billJson] in order and return the resulting bill JSON.
///
/// [billJson] is left untouched; a deep copy is mutated.
Map<String, dynamic> projectBill(
  Map<String, dynamic> billJson,
  List<SettlementEvent> events,
  ProjectionConfig cfg,
) {
  final bill = _deepCopy(billJson);
  for (final e in events) {
    if (e.isParked) continue;
    _apply(bill, e, cfg);
  }
  return _recompute(bill, cfg);
}


/// The base a [[Kunjungan tertangkap]] projects onto (ADR-0139).
///
/// Every other bill this device shows starts life as the host's own JSON,
/// prefetched while online. A visit minted dark has no such snapshot and never
/// will until it drains — so the seat event mints one here instead, empty, and
/// the chain behind it fills it in exactly as it fills in a cached one.
///
/// It states only what the device actually knows: who it is, where it is, how
/// many people. **Every money figure is left at zero on purpose** — they are
/// [recomputeBill]'s to write, and pre-filling one would be this file computing
/// money, which is the single thing it may never do. `splitEnabled` and
/// `ticketAttribution` come from the cached venue settings the caller holds
/// (ADR-0128), not from a guess.
Map<String, dynamic> capturedBillSeed({
  required String visitId,
  required String tableId,
  String? tableLabel,
  required DateTime openedAt,
  int pax = 1,
  String? guestName,
  String kind = 'dinein',
  String channel = '',
  bool splitEnabled = false,
  bool ticketAttribution = false,
  bool taxAfterDiscount = false,
}) => <String, dynamic>{
  'visitId': visitId,
  'tableId': tableId,
  'tableLabel': tableLabel,
  'kind': kind,
  'status': 'open',
  'detached': false,
  'tableFreedAt': null,
  'billClosedAt': null,
  'pax': pax,
  'guestName': guestName,
  'channel': channel,
  'prepaid': false,
  'openedAt': openedAt.toIso8601String(),
  'mode': 'itemized',
  'subtotal': 0,
  'discountAmount': 0,
  'billDiscounts': <Map<String, dynamic>>[],
  'member': null,
  'splitEnabled': splitEnabled,
  'ticketAttribution': ticketAttribution,
  'serviceAmount': 0,
  'taxAmount': 0,
  'total': 0,
  'taxAfterDiscount': taxAfterDiscount,
  'paidAmount': 0,
  'outstanding': 0,
  'fullyAssigned': false,
  'fullySettled': false,
  'lines': <Map<String, dynamic>>[],
  'receipts': <Map<String, dynamic>>[],
};

// ── event application ───────────────────────────────────────────────────────

List<Map<String, dynamic>> _list(Map<String, dynamic> m, String key) {
  final raw = m[key];
  if (raw is List) {
    return [for (final x in raw) (x as Map).cast<String, dynamic>()];
  }
  return <Map<String, dynamic>>[];
}

Map<String, dynamic>? _receiptOf(Map<String, dynamic> bill, String? id) {
  if (id == null) return null;
  for (final r in _list(bill, 'receipts')) {
    if (r['id'] == id) return r;
  }
  return null;
}

void _apply(
  Map<String, dynamic> bill,
  SettlementEvent e,
  ProjectionConfig cfg,
) {
  final receipts = (bill['receipts'] as List).cast<Map<String, dynamic>>();
  switch (e.kind) {
    case SettlementEventKind.mintReceipt:
      receipts.add(_newReceipt(bill, e));

    case SettlementEventKind.deleteReceipt:
      receipts.removeWhere((r) => r['id'] == e.arg<String>('receiptId'));

    case SettlementEventKind.assignLine:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      final lines = (rec['lines'] as List).cast<Map<String, dynamic>>();
      final ticketId = e.arg<String>('ticketId');
      final qty = e.intArg('qtyUnits');
      lines.removeWhere((l) => l['ticketId'] == ticketId);
      // Zero is how the till un-assigns; the row goes rather than sitting at 0,
      // which is what the assign route does server-side.
      if (qty > 0) lines.add({'ticketId': ticketId, 'qtyUnits': qty});

    case SettlementEventKind.splitEven:
      // Shares are cut from the untracked remainder (ADR-0067) — nothing
      // existing is torn down, so the projection only adds.
      final ids = [
        for (final x in (e.payload['ids'] as List? ?? const [])) x as String,
      ];
      final shares = distributeEvenRounded(
        _outstandingUnclaimed(bill),
        ids.length,
      );
      for (var i = 0; i < ids.length; i++) {
        receipts.add(_emptyReceipt(id: ids[i], mode: 'even', total: shares[i]));
      }

    case SettlementEventKind.applyDiscount:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      final ds = (rec['discounts'] as List).cast<Map<String, dynamic>>();
      final source = e.arg<String>('source') ?? 'manual';
      final ticketId = e.arg<String>('ticketId');
      // One slot per source (ADR-0094), enforced by a partial index on the
      // host — so the projection replaces rather than stacks a second row.
      ds.removeWhere((d) => d['source'] == source && d['ticketId'] == ticketId);
      ds.add(_discountRow(e, source: source, ticketId: ticketId));

    case SettlementEventKind.removeDiscount:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      (rec['discounts'] as List).removeWhere(
        (d) => (d as Map)['id'] == e.arg<String>('discountId'),
      );

    case SettlementEventKind.applyBillDiscount:
      final ds = (bill['billDiscounts'] as List).cast<Map<String, dynamic>>();
      final source = e.arg<String>('source') ?? 'manual';
      ds.removeWhere((d) => d['source'] == source);
      ds.add(_discountRow(e, source: source, ticketId: null));

    case SettlementEventKind.removeBillDiscount:
      (bill['billDiscounts'] as List).removeWhere(
        (d) => (d as Map)['source'] == (e.arg<String>('source') ?? 'manual'),
      );

    case SettlementEventKind.attachMember:
      bill['memberId'] = e.arg<String>('memberId');

    case SettlementEventKind.detachMember:
      bill['memberId'] = null;
      bill['member'] = null;
      // The tier discount and any redemption are the member's, so they leave
      // with them — the host clears both slots on detach.
      (bill['billDiscounts'] as List).removeWhere(
        (d) => (d as Map)['source'] != 'manual',
      );

    case SettlementEventKind.assignTicketMembers:
      final ids = (e.payload['ticketIds'] as List? ?? const []).toSet();
      for (final line in _list(bill, 'lines')) {
        if (ids.contains(line['ticketId'])) {
          line['memberId'] = e.arg<String>('memberId');
        }
      }

    case SettlementEventKind.attachReceiptMember:
      _receiptOf(bill, e.arg<String>('receiptId'))?['memberId'] = e.arg<String>(
        'memberId',
      );

    case SettlementEventKind.detachReceiptMember:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      rec['memberId'] = null;
      rec['member'] = null;
      (rec['discounts'] as List).removeWhere(
        (d) => (d as Map)['source'] != 'manual',
      );

    case SettlementEventKind.redeemPoints:
      final ds = (bill['billDiscounts'] as List).cast<Map<String, dynamic>>();
      ds.removeWhere((d) => d['source'] == 'redeem');
      ds.add(_redeemRow(e, cfg));

    case SettlementEventKind.removeRedeem:
      (bill['billDiscounts'] as List).removeWhere(
        (d) => (d as Map)['source'] == 'redeem',
      );

    case SettlementEventKind.redeemOnReceipt:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      final ds = (rec['discounts'] as List).cast<Map<String, dynamic>>();
      ds.removeWhere((d) => d['source'] == 'redeem' && d['ticketId'] == null);
      ds.add(_redeemRow(e, cfg));

    case SettlementEventKind.removeReceiptRedeem:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      (rec['discounts'] as List).removeWhere(
        (d) => (d as Map)['source'] == 'redeem' && (d)['ticketId'] == null,
      );

    case SettlementEventKind.recordPayment:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      (rec['payments'] as List).add({
        'id': e.id,
        'method': e.arg<String>('method') ?? 'tunai',
        'amount': e.intArg('amount'),
        'isRefund': false,
        'refundsPaymentId': null,
        'tendered': e.payload['tendered'],
        'cashierUserId': e.actorId.isEmpty ? null : e.actorId,
        'note': e.arg<String>('note'),
        'at': e.capturedAt.toIso8601String(),
        // A proof photo is captured to a file and uploaded on drain — it never
        // rides the projection, which only has to make the money add up.
        'hasPhoto': false,
      });

    case SettlementEventKind.refund:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      if (rec == null) return;
      final legId = e.arg<String>('paymentId');
      final pays = (rec['payments'] as List).cast<Map<String, dynamic>>();
      final leg = pays.where((p) => p['id'] == legId).firstOrNull;
      pays.add({
        'id': e.id,
        // Inherited, never chosen: a refund is the leg running backwards.
        'method': leg?['method'] ?? 'tunai',
        'amount': -e.intArg('amount'),
        'isRefund': true,
        'refundsPaymentId': legId,
        'tendered': null,
        'cashierUserId': e.actorId.isEmpty ? null : e.actorId,
        'note': e.arg<String>('note'),
        'at': e.capturedAt.toIso8601String(),
        'hasPhoto': false,
      });

    case SettlementEventKind.reopenReceipt:
      final rec = _receiptOf(bill, e.arg<String>('receiptId'));
      // A reopen drops the receipt's payments — the money is being unwound so
      // the cashier can re-take it, which is what the host's route does.
      (rec?['payments'] as List?)?.clear();

    case SettlementEventKind.closeBill:
      bill['billClosedAt'] = e.capturedAt.toIso8601String();

    case SettlementEventKind.reopenBill:
      bill['billClosedAt'] = null;

    case SettlementEventKind.enrolMember:
      // Nothing. An enrolment hangs off no bill and moves no money — it rides
      // the journal only so one queue has one drain order (ADR-0129). The act
      // that *attaches* the new member is a separate event, and that one this
      // projection does apply.
      break;

    // ── the floor (ADR-0139) ────────────────────────────────────────────────

    case SettlementEventKind.seatTable:
      // Nothing here. A seat does not change a bill; it *is* the bill's
      // existence, and by the time this runs the base has already been minted
      // by [capturedBillSeed]. Applying it again would be a second opinion
      // about a fact the base already states.
      break;

    case SettlementEventKind.submitOrder:
      // The [[Baris tertangkap]] entering the bill — the whole of ADR-0139 in
      // one arm. These are ordinary lines the moment they land: the guest is
      // charged for them, they can be assigned to a receipt, discounted and
      // paid. `lineTotal` is `unitPrice * qty` because the cart already folded
      // every modifier delta into `unitPrice`, which is exactly what the host
      // does with the same wire (`price: l['unitPrice']`, `lineTotal:
      // price * qty`). Computing it differently here would be this file
      // inventing money, which it may never do.
      final lines = (bill['lines'] as List).cast<Map<String, dynamic>>();
      for (final raw in (e.payload['lines'] as List? ?? const [])) {
        final l = (raw as Map).cast<String, dynamic>();
        final ticketId = l['ticketId'] as String?;
        // A line with no client-minted ticket id cannot be assigned, voided or
        // referenced by a receipt, so it is dropped rather than shown: a line
        // the cashier can see and cannot act on is worse than one that is
        // honestly missing (ADR-0139 §2 mints these at capture).
        if (ticketId == null || ticketId.isEmpty) continue;
        if (lines.any((x) => x['ticketId'] == ticketId)) continue;
        final qty = (l['qty'] as num?)?.toInt() ?? 1;
        final unitPrice = (l['unitPrice'] as num?)?.toInt() ?? 0;
        lines.add({
          'ticketId': ticketId,
          'itemId': l['itemId'] ?? '',
          'name': l['name'] ?? l['itemId'] ?? '',
          'variantName': l['variantName'] ?? '',
          'qty': qty,
          'unitPrice': unitPrice,
          'lineTotal': unitPrice * qty,
          'assignedUnits': 0,
          'note': l['note'],
          // Not `sent`. Nothing was sent — the host has never heard of this
          // line. `captured` is what the badge reads off, and every money rule
          // that asks "is this line live" treats it as live, because the guest
          // is eating it.
          'status': 'captured',
          'memberId': l['memberId'],
          'memberName': l['memberName'],
          'memberLocked': false,
          'modifiersJson': jsonEncode(l['modifiers'] ?? const []),
          // The moment the waiter keyed it. The host will re-stamp this at
          // drain from the same `capturedAt`, so the two agree.
          'sentAt': e.capturedAt.toIso8601String(),
        });
      }

    case SettlementEventKind.voidTicket:
      // Voids the line wherever it came from — a captured one or a delivered
      // one the host already knows. Never *removes* it: a void is a fact about
      // a line, and a line that vanishes is a line nobody can audit
      // (ADR-0139 §6). `recomputeBill` is what drops a voided line's money.
      final vid = e.arg<String>('ticketId');
      for (final l in (bill['lines'] as List).cast<Map<String, dynamic>>()) {
        if (l['ticketId'] == vid) l['status'] = 'voided';
      }

    case SettlementEventKind.tableExpense:
      // Nothing, and deliberately so. The guest pays in full: a
      // [[Pengeluaran kunjungan]] is a cost the venue absorbed, never a
      // give-back, so the bill total, its receipts and its outstanding must
      // not learn it happened (ADR-0130). It rides the chain for ordering
      // only.
      break;
  }
}

Map<String, dynamic> _newReceipt(Map<String, dynamic> bill, SettlementEvent e) {
  final mode = e.arg<String>('mode') == 'even' ? 'even' : 'itemized';
  final rec = _emptyReceipt(
    id: e.id,
    mode: mode,
    total: mode == 'even' ? e.intArg('total') : 0,
    label: e.arg<String>('label'),
    memberId: e.arg<String>('memberId'),
  );
  final lines = (rec['lines'] as List).cast<Map<String, dynamic>>();
  if (e.payload['assignAll'] == true) {
    // Every unit nobody has claimed yet — the host's `_assignAllUnassigned`.
    for (final l in _list(bill, 'lines')) {
      final free = (l['qty'] as int? ?? 0) - (l['assignedUnits'] as int? ?? 0);
      if (free > 0) {
        lines.add({'ticketId': l['ticketId'], 'qtyUnits': free});
      }
    }
  }
  for (final l in (e.payload['lines'] as List? ?? const [])) {
    final m = (l as Map).cast<String, dynamic>();
    lines.add({'ticketId': m['ticketId'], 'qtyUnits': m['qtyUnits']});
  }
  return rec;
}

Map<String, dynamic> _emptyReceipt({
  required String id,
  required String mode,
  int total = 0,
  String? label,
  String? memberId,
}) => {
  'id': id,
  'mode': mode,
  'label': label ?? '',
  'subtotal': 0,
  'discountAmount': 0,
  'serviceAmount': 0,
  'taxAmount': 0,
  'total': total,
  'status': 'unpaid',
  'paidNet': 0,
  'memberId': memberId,
  'member': null,
  'discounts': <Map<String, dynamic>>[],
  'lines': <Map<String, dynamic>>[],
  'payments': <Map<String, dynamic>>[],
};

Map<String, dynamic> _discountRow(
  SettlementEvent e, {
  required String source,
  required String? ticketId,
}) => {
  'id': e.id,
  'ticketId': ticketId,
  'presetId': e.arg<String>('presetId'),
  // Null rather than a word: a name is copy, and copy does not cross a layer
  // (ADR-0085). The DTO renders its own fallback.
  'name': e.arg<String>('name'),
  'kind': e.arg<String>('kind') ?? 'percent',
  'value': e.intArg('value'),
  // Derived by the recompute below, never carried on the event.
  'amount': 0,
  'source': source,
  'byUserId': e.actorId.isEmpty ? null : e.actorId,
  'approvedByUserId': null,
  'at': e.capturedAt.toIso8601String(),
};

/// A redemption is a **fixed** give-back: the points were quoted to the guest at
/// today's rate, so a later base change must not re-price them.
Map<String, dynamic> _redeemRow(SettlementEvent e, ProjectionConfig cfg) => {
  'id': e.id,
  'ticketId': null,
  'presetId': null,
  'name': e.arg<String>('name'),
  'kind': 'fixed',
  'value': e.intArg('points') * cfg.pointValue,
  'amount': 0,
  'source': 'redeem',
  'byUserId': e.actorId.isEmpty ? null : e.actorId,
  'approvedByUserId': null,
  'at': e.capturedAt.toIso8601String(),
};

/// What no receipt has claimed yet, for cutting even shares off the remainder.
int _outstandingUnclaimed(Map<String, dynamic> bill) {
  final total = bill['total'] as int? ?? 0;
  final claimed = _list(
    bill,
    'receipts',
  ).fold<int>(0, (a, r) => a + (r['total'] as int? ?? 0));
  final left = total - claimed;
  return left < 0 ? 0 : left;
}

// ── the recompute, delegated ────────────────────────────────────────────────

Map<String, dynamic> _recompute(
  Map<String, dynamic> bill,
  ProjectionConfig cfg,
) {
  final lines = _list(bill, 'lines');
  final receipts = _list(bill, 'receipts');

  final rcLines = [
    for (final l in lines)
      RcLine(
        ticketId: l['ticketId'] as String,
        unitPrice: l['unitPrice'] as int? ?? 0,
        qty: l['qty'] as int? ?? 0,
      ),
  ];
  final rcReceipts = [
    for (final r in receipts)
      RcReceipt(
        id: r['id'] as String,
        mode: r['mode'] as String? ?? 'itemized',
        amountTotal: r['total'] as int? ?? 0,
      ),
  ];
  final rcAssigns = [
    for (final r in receipts)
      for (final l in _list(r, 'lines'))
        RcAssign(
          receiptId: r['id'] as String,
          ticketId: l['ticketId'] as String,
          qtyUnits: l['qtyUnits'] as int? ?? 0,
        ),
  ];
  final rcDiscounts = <RcDiscount>[
    for (final r in receipts)
      for (final d in _list(r, 'discounts'))
        RcDiscount(
          id: d['id'] as String,
          receiptId: r['id'] as String,
          ticketId: d['ticketId'] as String?,
          kind: d['kind'] as String? ?? 'percent',
          value: d['value'] as int? ?? 0,
        ),
    for (final d in _list(bill, 'billDiscounts'))
      RcDiscount(
        id: d['id'] as String,
        receiptId: null,
        ticketId: null,
        kind: d['kind'] as String? ?? 'percent',
        value: d['value'] as int? ?? 0,
      ),
  ];
  final paid = <String, int>{
    for (final r in receipts)
      r['id'] as String: _list(
        r,
        'payments',
      ).fold<int>(0, (a, p) => a + (p['amount'] as int? ?? 0)),
  };

  final res = recomputeBill(
    lines: rcLines,
    receipts: rcReceipts,
    assigns: rcAssigns,
    discounts: rcDiscounts,
    paidByReceipt: paid,
    cfg: cfg.tax,
  );

  for (final l in lines) {
    l['assignedUnits'] = res.assignedUnits[l['ticketId']] ?? 0;
  }
  for (final r in receipts) {
    final id = r['id'] as String;
    r['status'] = res.statuses[id] ?? 'unpaid';
    r['paidNet'] = paid[id] ?? 0;
    final m = res.receipts[id];
    if (m != null) {
      r['subtotal'] = m.subtotal;
      r['discountAmount'] = m.discountAmount;
      r['serviceAmount'] = m.serviceAmount;
      r['taxAmount'] = m.taxAmount;
      r['total'] = m.total;
    }
    for (final d in _list(r, 'discounts')) {
      d['amount'] = res.discountAmounts[d['id']] ?? 0;
    }
  }
  for (final d in _list(bill, 'billDiscounts')) {
    d['amount'] = res.discountAmounts[d['id']] ?? 0;
  }

  final anyAmount = receipts.any((r) => r['mode'] == 'even');
  final anyItemized = receipts.any((r) => r['mode'] != 'even');
  bill['mode'] = anyAmount && anyItemized
      ? 'mixed'
      : anyAmount
      ? 'even'
      : 'itemized';

  final paidNet = paid.values.fold<int>(0, (a, b) => a + b);
  bill['subtotal'] = res.billBreak.subtotal;
  bill['discountAmount'] = res.billLineDiscount + res.billBreak.discountAmount;
  bill['serviceAmount'] = res.billBreak.serviceAmount;
  bill['taxAmount'] = res.billBreak.taxAmount;
  bill['total'] = res.billTotal;
  bill['taxAfterDiscount'] = cfg.tax.taxAfterDiscount;
  bill['paidAmount'] = paidNet;
  bill['outstanding'] = (res.billTotal - paidNet).clamp(0, 1 << 31);
  bill['fullyAssigned'] = res.fullyAssigned;
  bill['fullySettled'] =
      res.fullyAssigned &&
      receipts.isNotEmpty &&
      // Match the host: zero-total receipts owe nothing even while editable.
      receipts.every((r) => (r['paidNet'] as int) >= (r['total'] as int));
  return bill;
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> m) {
  Object? copy(Object? v) {
    if (v is Map) {
      return <String, dynamic>{
        for (final e in v.entries) e.key as String: copy(e.value),
      };
    }
    if (v is List) return [for (final x in v) copy(x)];
    return v;
  }

  return copy(m) as Map<String, dynamic>;
}
