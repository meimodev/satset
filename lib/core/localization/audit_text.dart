import 'package:satset/core/localization/labels.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Turn a structured audit row into the sentence a person reads — ADR-0085.
///
/// The row stores *what happened* (`kind` + params); the words are composed
/// here, in the reader's language, every time the log is drawn. Two devices
/// looking at the same row in different languages see the same event.
///
/// **Rows written before ADR-0085 have no kind** and fall back to the stored
/// `title` — Indonesian, permanently. That is not a gap to be closed later: the
/// sentence is genuinely what was recorded, and inventing structure for it
/// would be guessing at history. Same for a kind this build does not know,
/// which is how an older client survives a newer server.
String auditText(AppL10n l, AuditEntry e) {
  final kind = auditKindFromName(e.kind);
  if (kind == null) return e.title;
  final p = e.params;
  String s(String key) => p[key] ?? '';
  return switch (kind) {
    AuditKind.fire => l.auditFire(courseLabel(l, s('course')), s('table')),
    AuditKind.modify => l.auditModify(s('name')),
    AuditKind.modifyQty => l.auditModifyQty(
      s('oldQty'),
      s('newQty'),
      s('name'),
    ),
    AuditKind.modifyAtTable => l.auditModifyAtTable(s('name'), s('table')),
    AuditKind.voidItem => l.auditVoidItem(s('qty'), s('name'), s('amount')),
    AuditKind.voidItemAtTable => l.auditVoidItemAtTable(s('name'), s('table')),
    AuditKind.comp => l.auditComp(s('qty'), s('name'), s('amount')),
    AuditKind.tableMoved => l.auditTableMoved(s('src'), s('tgt')),

    AuditKind.paymentRecorded => l.auditPaymentRecorded(
      s('amount'),
      paymentMethodLabel(l, s('method')),
      receiptTitle(l, s('label')),
    ),
    AuditKind.paymentAtTable => l.auditPaymentAtTable(
      paymentMethodLabel(l, s('method')),
      s('table'),
    ),
    AuditKind.refund => l.auditRefund(
      s('amount'),
      paymentMethodLabel(l, s('method')),
      receiptTitle(l, s('label')),
    ),

    AuditKind.discountApplied => l.auditDiscountApplied(s('name')),
    AuditKind.discountAppliedLine => l.auditDiscountAppliedLine(s('name')),
    AuditKind.discountRemoved => l.auditDiscountRemoved(s('name')),
    AuditKind.discountBillApplied => l.auditDiscountBillApplied(s('name')),
    AuditKind.discountBillRemoved => l.auditDiscountBillRemoved(s('name')),
    AuditKind.discountAtTable => l.auditDiscountAtTable(
      s('percent'),
      s('table'),
    ),

    AuditKind.billReopenedReceipt => l.auditBillReopenedReceipt(
      receiptTitle(l, s('label')),
    ),
    AuditKind.billReopened => l.auditBillReopened(s('table')),
    AuditKind.billClosed => l.auditBillClosed(s('table')),
    AuditKind.billWrittenOff => l.auditBillWrittenOff(s('amount'), s('table')),

    AuditKind.menuKilled => l.auditMenuKilled(s('name')),
    AuditKind.menuRestored => l.auditMenuRestored(s('name')),

    AuditKind.staffCreated => l.auditStaffCreated(s('name')),
    AuditKind.staffDeleted => l.auditStaffDeleted(s('name')),
    AuditKind.staffDisabled => l.auditStaffDisabled(s('name')),
    AuditKind.staffEnabled => l.auditStaffEnabled(s('name')),
    AuditKind.staffPinSet => l.auditStaffPinSet(s('name')),
    AuditKind.staffPinReset => l.auditStaffPinReset(s('name')),
    AuditKind.staffRoleChanged => l.auditStaffRoleChanged(
      s('name'),
      s('from'),
      s('to'),
    ),
    AuditKind.roleCreated => l.auditRoleCreated(s('name')),
    AuditKind.roleDeleted => l.auditRoleDeleted(s('name')),
    AuditKind.roleColorChanged => l.auditRoleColorChanged(s('name')),
    AuditKind.roleRenamed => l.auditRoleRenamed(s('from'), s('to')),
    AuditKind.roleCapabilityChanged => l.auditRoleCapabilityChanged(
      s('name'),
      s('changes'),
    ),

    AuditKind.sampleDataLoaded => l.auditSampleDataLoaded,
  };
}
