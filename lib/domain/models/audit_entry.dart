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

  const AuditEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.tableId,
    required this.when,
    this.approvedBy,
    this.reason,
  });
}
