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

  /// Enrol a member captured while the host was gone (ADR-0129).
  ///
  /// The one kind with **no [[Visit]]** — it rides [kVenueScopeVisitId], the
  /// chain drained ahead of every per-visit one, because an attach that names
  /// a member the host has never heard of must land second.
  enrolMember,

  // ── the floor (ADR-0139) ────────────────────────────────────────────────
  //
  // These four were `SendIntentKind` values on a separate prefs FIFO until
  // ADR-0139 merged the stores. They live here for one reason: the seat must
  // land before the order, the order before the void, and the void before the
  // payment. Two backlogs with independent sequences cannot carry one causal
  // chain — merging them makes the ordering structural instead of coordinated.

  /// Seat a table on a [[Kunjungan tertangkap]] this device minted.
  ///
  /// Carries the **client-minted visit id** — the first act of the chain and
  /// the one that names it. Every event behind it references that id, which is
  /// why it cannot live in a different store than they do.
  seatTable,

  /// Send lines onto the visit. The [[Baris tertangkap]].
  submitOrder,

  /// Void one captured or delivered line (ADR-0114).
  ///
  /// Never collapsed against the [submitOrder] that created the line, even
  /// when both are captured and neither has been offered: a void is the
  /// venue's fraud control, and "the line was removed before anyone saw it" is
  /// the shape of theft (ADR-0139 §6).
  voidTicket,

  /// File a [[Pengeluaran kunjungan]] (ADR-0130).
  ///
  /// On the chain but **not of the money**: one append-only row, never read
  /// back, and it never reaches `recomputeBill`. Its photo lives in
  /// `QueuedPhotos`, keyed by this event's id.
  tableExpense,
}

/// The chain visit-less acts share.
///
/// Not a real visit and never looked up as one: it is the [[Antrean setelmen]]
/// admitting that not everything it carries hangs off a bill. Drained first,
/// and excluded from the local-authority test below like every other
/// member-scope act.
const kVenueScopeVisitId = '__venue__';

extension SettlementEventScope on SettlementEventKind {
  /// Does this act confer no [[Kunjungan otoritatif-lokal|local authority]]?
  ///
  /// A [[Waiter|pelayan]] tagging a regular at order time captures an act on
  /// **their** handset; if that made the [[Visit]] local-authoritative there,
  /// the till settling the same bill would hit ADR-0116's two-islanded-devices
  /// case as routine rather than as the exception it is (ADR-0129).
  ///
  /// A redemption is deliberately **not** in here: it takes money off the
  /// bill, so it is a settlement act that happens to name a member.
  ///
  /// The floor kinds are **not** in here either, and that is ADR-0139's whole
  /// point: a captured order earns authority exactly as money does, or the
  /// host's correct-but-short answer gets cached over the truth.
  bool get isMemberScope => switch (this) {
    SettlementEventKind.attachMember ||
    SettlementEventKind.detachMember ||
    SettlementEventKind.assignTicketMembers ||
    SettlementEventKind.attachReceiptMember ||
    SettlementEventKind.detachReceiptMember ||
    SettlementEventKind.enrolMember => true,
    _ => false,
  };

  /// Is this act one the floor captured, rather than the till? (ADR-0139)
  ///
  /// Used to decide what a drain sends where, and what the floor screens
  /// render. Not a money question — see [putsMoneyInTheDrawer] for that.
  bool get isFloorAct => switch (this) {
    SettlementEventKind.seatTable ||
    SettlementEventKind.submitOrder ||
    SettlementEventKind.voidTicket ||
    SettlementEventKind.tableExpense => true,
    _ => false,
  };

  /// Does this act mean cash has already changed hands, or a bill was declared
  /// settled?
  ///
  /// The test for **chain-scoped expiry** (ADR-0139 §8). A business-day
  /// rollover retires a captured order — *an order nobody wants this morning
  /// is right to drop* — unless somewhere in that visit's chain money landed,
  /// in which case nothing in the chain expires. ADR-0130 drew the same line
  /// for a [[Pengeluaran kunjungan]]: *money already spent is not*.
  ///
  /// Deliberately narrow. A discount or a minted receipt changes what is
  /// **owed**, not what was **taken**, and a chain holding only those is still
  /// yesterday's abandoned bill. An expense is excluded for the opposite
  /// reason: it never expires on its own terms, so it needs no help from here.
  bool get putsMoneyInTheDrawer => switch (this) {
    SettlementEventKind.recordPayment ||
    SettlementEventKind.refund ||
    SettlementEventKind.closeBill => true,
    _ => false,
  };
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

  /// The [[Table|meja]] this act happened at, when there is one (ADR-0139).
  ///
  /// Null for a takeaway visit, for the venue-scope chain, and for every act
  /// the till takes on a bill it did not seat. Denormalised out of [payload]
  /// deliberately: the floor screens ask *what has this table got captured on
  /// it*, and answering that by first resolving table → visit means trusting a
  /// link that a cold boot may not have restored yet.
  final String? tableId;

  /// When the cashier did it. Rides to the host and is honoured there, so
  /// money lands in the shift that collected it (ADR-0123).
  final DateTime capturedAt;

  final String actorId;

  /// `pending` | `acknowledged` | `parked`. Acknowledged effects remain until
  /// the host snapshot is durable. Parked means a refusal halted this chain.
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
    this.tableId,
    this.actorId = '',
    this.status = 'pending',
    this.failCode,
  });

  bool get isAcknowledged => status == 'acknowledged';

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
