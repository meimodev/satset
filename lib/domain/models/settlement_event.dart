/// One act on a [[Bill (tab)]] the [[Cashier|kasir]] performed, captured rather
/// than delivered (ADR-0123). Pure: no Flutter, no Drift.
library;

/// What a captured act asks the host to do.
///
/// **Every name here is persisted** in `settlement_events.kind` — never rename
/// one, the same rule `AuditKind` and `CashEntryKind` carry.
///
/// One value per state-changing settlement route, and nothing else. Printing is
/// deliberately absent: it is a side effect, not state, and a reprint after the
/// drain is a fresh act rather than a replay of an old one. Reads are absent for
/// the obvious reason.
enum SettlementEventKind {
  mintReceipt,
  deleteReceipt,
  assignLine,
  splitEven,
  applyDiscount,
  removeDiscount,
  applyBillDiscount,
  removeBillDiscount,
  attachMember,
  detachMember,
  assignTicketMembers,
  attachReceiptMember,
  detachReceiptMember,
  redeemPoints,
  removeRedeem,
  redeemOnReceipt,
  removeReceiptRedeem,
  recordPayment,
  refund,
  reopenReceipt,
  closeBill,
  reopenBill,
}

/// Read a persisted kind back, tolerating one written by a newer build.
SettlementEventKind? settlementKindFromName(String? name) {
  if (name == null) return null;
  for (final k in SettlementEventKind.values) {
    if (k.name == name) return k;
  }
  return null;
}

/// One entry in the [[Antrean setelmen]].
///
/// [id] is both the id of whatever row the act mints — receipt, payment,
/// discount — and the idempotency key its replay carries. One value, because
/// the two are the same claim: *this act, once*.
class SettlementEvent {
  final String id;
  final String visitId;

  /// Order within the visit. A settlement is a chain, not a set.
  final int seq;

  final SettlementEventKind kind;
  final Map<String, dynamic> payload;

  /// When the cashier did it. Rides to the host and is honoured there, so
  /// money lands in the shift that collected it (ADR-0123).
  final DateTime capturedAt;

  final String actorId;

  /// `pending` | `parked`. Parked means this visit's chain hit a refusal at or
  /// before this event and it has not been offered.
  final String status;

  /// The host's refusal `code`, on the one event that was actually refused.
  final String? failCode;

  const SettlementEvent({
    required this.id,
    required this.visitId,
    required this.seq,
    required this.kind,
    required this.payload,
    required this.capturedAt,
    this.actorId = '',
    this.status = 'pending',
    this.failCode,
  });

  bool get isParked => status == 'parked';

  T? arg<T>(String key) {
    final v = payload[key];
    return v is T ? v : null;
  }

  int intArg(String key) {
    final v = payload[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }
}
