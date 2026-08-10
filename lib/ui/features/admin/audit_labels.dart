import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Short pill label for the venue log's Jenis / Type column.
///
/// Lived in `domain/models/audit_entry.dart` beside the enum until ADR-0083,
/// on the reasoning that a label set has to move with its values or a new type
/// ships rendering its raw enum name. That reasoning still holds — but `domain/`
/// may not import Flutter, and `AppL10n` does. So the *switch* moved here and
/// the guarantee moved with it: this is exhaustive over [AuditType], so adding
/// a value breaks the build here rather than leaking `AuditType.foo` onto a
/// compliance screen.
String auditTypeLabel(AppL10n l10n, AuditType t) => switch (t) {
  AuditType.fire => l10n.auditTypeFire,
  AuditType.modify => l10n.auditTypeModify,
  AuditType.voidItem => l10n.auditTypeVoidItem,
  AuditType.comp => l10n.auditTypeComp,
  AuditType.tableMoved => l10n.auditTypeTableMoved,
  AuditType.paymentRecorded => l10n.auditTypePaymentRecorded,
  AuditType.refund => l10n.auditTypeRefund,
  AuditType.discountApplied => l10n.auditTypeDiscountApplied,
  AuditType.discountRemoved => l10n.auditTypeDiscountRemoved,
  AuditType.billReopened => l10n.auditTypeBillReopened,
  AuditType.billClosed => l10n.auditTypeBillClosed,
  AuditType.cashMovement => l10n.auditTypeCashMovement,
  AuditType.memberChanged => l10n.auditTypeMemberChanged,
  AuditType.stockCounted => l10n.auditTypeStockCounted,
  AuditType.menuKilled => l10n.auditTypeMenuKilled,
  AuditType.menuRestored => l10n.auditTypeMenuRestored,
  AuditType.staffCreated => l10n.auditTypeStaffCreated,
  AuditType.staffDeleted => l10n.auditTypeStaffDeleted,
  AuditType.staffDisabled => l10n.auditTypeStaffDisabled,
  AuditType.staffEnabled => l10n.auditTypeStaffEnabled,
  AuditType.staffRoleChanged => l10n.auditTypeStaffRoleChanged,
  AuditType.staffPinSet => l10n.auditTypeStaffPinSet,
  AuditType.staffPinReset => l10n.auditTypeStaffPinReset,
  AuditType.roleCreated => l10n.auditTypeRoleCreated,
  AuditType.roleRenamed => l10n.auditTypeRoleRenamed,
  AuditType.roleDeleted => l10n.auditTypeRoleDeleted,
  AuditType.roleColorChanged => l10n.auditTypeRoleColorChanged,
  AuditType.roleCapabilityChanged => l10n.auditTypeRoleCapabilityChanged,
};

/// The six types the audit screen tallies into tiles.
String auditTileLabel(AppL10n l10n, AuditType t) => switch (t) {
  AuditType.voidItem => l10n.auditTileVoid,
  AuditType.comp => l10n.auditTileComp,
  AuditType.discountApplied => l10n.auditTileDiscount,
  AuditType.refund => l10n.auditTileRefund,
  AuditType.menuKilled => l10n.auditTileKilled,
  AuditType.modify => l10n.auditTileModify,
  // Not a tallied type — the tile grid only ever walks `auditSummaryTypes`.
  _ => auditTypeLabel(l10n, t),
};
