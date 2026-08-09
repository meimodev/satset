enum AuditType {
  fire,
  modify,
  voidItem,
  comp,
  tableMoved,
  paymentRecorded,
  refund,
  discountApplied,
  discountRemoved,
  billReopened,
  billClosed,

  /// A human pulled an item off the menu mid-service, or put it back. Only
  /// the manual toggle writes these — auto-sold-out at zero stock is derived
  /// from the stock trail and would otherwise bury the human decisions this
  /// log exists to record.
  menuKilled,
  menuRestored,

  /// Any movement of the petty cash box — top-up, expense, count, reversal.
  /// **One** type covering all four on purpose: the type axis drives the venue
  /// log's filter chips, and four near-identical chips reading Kas would crowd
  /// the bar to say one thing. Which movement it was lives on the [AuditKind]
  /// (`cashToppedUp` / `cashSpent` / `cashCounted` / `cashReversed`), which is
  /// the sentence axis and where that distinction belongs.
  cashMovement,

  /// Any act against a [[Pelanggan (member)]] — enrolled, deleted, merged,
  /// points adjusted by hand, points redeemed. **One** type for all five, for
  /// the reason [cashMovement] is one: the type axis drives the log's filter
  /// chips, and five chips reading Pelanggan say one thing five times. Which
  /// act it was lives on the [AuditKind].
  memberChanged,
  staffCreated,
  staffDeleted,
  staffDisabled,
  staffEnabled,
  staffRoleChanged,
  staffPinSet,
  staffPinReset,
  roleCreated,
  roleRenamed,
  roleDeleted,
  roleColorChanged,
  roleCapabilityChanged,
}

/// True for audit types that expose user/role admin actions. Hide from
/// non-managers in the audit feed.
bool isAdminAuditType(AuditType t) {
  switch (t) {
    case AuditType.staffCreated:
    case AuditType.staffDeleted:
    case AuditType.staffDisabled:
    case AuditType.staffEnabled:
    case AuditType.staffRoleChanged:
    case AuditType.staffPinSet:
    case AuditType.staffPinReset:
    case AuditType.roleCreated:
    case AuditType.roleRenamed:
    case AuditType.roleDeleted:
    case AuditType.roleColorChanged:
    case AuditType.roleCapabilityChanged:
      return true;
    case AuditType.fire:
    case AuditType.modify:
    case AuditType.voidItem:
    case AuditType.comp:
    case AuditType.tableMoved:
    case AuditType.paymentRecorded:
    case AuditType.refund:
    case AuditType.discountApplied:
    case AuditType.discountRemoved:
    case AuditType.billReopened:
    case AuditType.billClosed:
    case AuditType.menuKilled:
    case AuditType.menuRestored:
    // A money act, and it sits with the money acts: a supervisor reading the
    // log should see the box move without holding `manageStaff`.
    case AuditType.cashMovement:
    // A redemption is money off a bill and an adjustment moves a balance a
    // guest believes in — both belong beside the other money acts, readable by
    // any `viewReports` supervisor rather than gated behind `manageStaff`.
    case AuditType.memberChanged:
      return false;
  }
}

class AuditEntry {
  final String id;
  final AuditType type;
  final String title;
  final String tableId;
  final String when;
  final String? approvedBy;
  final String? reason;

  /// Who performed the audited act. Always stamped server-side from the JWT —
  /// attribution for a void or comp is evidence (ADR-0006), never a
  /// client-supplied field.
  ///
  /// Null on legacy rows written before attribution existed. Such rows belong
  /// to nobody, and on a personal screen they are shown to **nobody** — the
  /// opposite of the [[Pesanan board]]'s unowned rule, because an unattributed
  /// void surfaced on every handset would leak the venue's integrity log.
  final String? actorUserId;

  /// What the act was worth, as a magnitude — see the DB column doc. Direction
  /// lives in [type], so nothing downstream has to interpret a sign. Null when
  /// money is not the point, and on rows written before v43.
  final int? amountCents;

  /// Actor attribution as it stood when the act happened. Snapshotted server-
  /// side so a later rename or deletion cannot rewrite the trail; null on
  /// pre-v43 rows, where the server falls back to a live join. Both null means
  /// nobody is on record — the venue log renders that as "Sistem".
  final String? actorName;
  final String? actorRoleName;

  /// Which sentence this row is, as an `AuditKind` name — the structured half
  /// of ADR-0085. Null on rows written before v47, which carry only [title].
  ///
  /// Deliberately a `String` and not the enum: a client one release behind a
  /// server must be able to hold a kind it has no template for and still show
  /// the row. `auditText` does the widening and falls back on its own.
  final String? kind;

  /// Named parameters for [kind]'s template. Empty when [kind] is null.
  ///
  /// Values are pre-rendered where they are not language: money is formatted
  /// rupiah at write time (ADR-0084) and venue-authored names — a discount
  /// preset, a menu item — are stored as the venue wrote them. What stays as a
  /// key is what the reader's language actually changes: a payment method, a
  /// course, a receipt label.
  final Map<String, String> params;

  /// The payment whose proof photo this row can pull up, or null when there is
  /// no image — see the DB column doc (ADR-0086). Non-null is the whole
  /// has-photo test: the server writes it only when a photo exists, so the log
  /// never offers a tap that leads to a 404.
  final String? paymentId;

  const AuditEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.tableId,
    required this.when,
    this.approvedBy,
    this.reason,
    this.actorUserId,
    this.amountCents,
    this.actorName,
    this.actorRoleName,
    this.kind,
    this.params = const {},
    this.paymentId,
  });
}
