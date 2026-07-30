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
      return false;
  }
}

/// Short pill label for the venue log's Jenis column. Kept beside the enum for
/// the same reason as `ticketStatusLabel` — the label set has to move with the
/// values, or a new type ships rendering its raw enum name.
String auditTypeLabel(AuditType t) => switch (t) {
  AuditType.fire => 'Kirim',
  AuditType.modify => 'Ubah',
  AuditType.voidItem => 'Batal',
  AuditType.comp => 'Gratis',
  AuditType.tableMoved => 'Pindah',
  AuditType.paymentRecorded => 'Bayar',
  AuditType.refund => 'Refund',
  AuditType.discountApplied => 'Diskon',
  AuditType.discountRemoved => 'Diskon−',
  AuditType.billReopened => 'Buka',
  AuditType.billClosed => 'Tutup',
  AuditType.menuKilled => 'Stop jual',
  AuditType.menuRestored => 'Jual lagi',
  AuditType.staffCreated => 'Staf +',
  AuditType.staffDeleted => 'Staf −',
  AuditType.staffDisabled => 'Nonaktif',
  AuditType.staffEnabled => 'Aktif',
  AuditType.staffRoleChanged => 'Peran',
  AuditType.staffPinSet => 'PIN',
  AuditType.staffPinReset => 'PIN reset',
  AuditType.roleCreated => 'Peran +',
  AuditType.roleRenamed => 'Peran ubah',
  AuditType.roleDeleted => 'Peran −',
  AuditType.roleColorChanged => 'Peran warna',
  AuditType.roleCapabilityChanged => 'Hak akses',
};

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
  /// money is not the point, and on rows written before v42.
  final int? amountCents;

  /// Actor attribution as it stood when the act happened. Snapshotted server-
  /// side so a later rename or deletion cannot rewrite the trail; null on
  /// pre-v42 rows, where the server falls back to a live join. Both null means
  /// nobody is on record — the venue log renders that as "Sistem".
  final String? actorName;
  final String? actorRoleName;

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
  });
}
