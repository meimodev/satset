import 'package:flutter/material.dart';

import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/ui/core/design/colors.dart';

/// Visual + label mapping for [AuditType]. Lives in the UI layer so the domain
/// model carries no Flutter imports, and in one file so the personal feed
/// ("Saya") and the venue log speak the same vocabulary — a void has to look
/// like a void on both screens or the colour stops being a signal.
///
/// The icon set is deliberately shared while the *shape* is not: the personal
/// feed draws a soft-backed icon puck, the venue log a short text pill. Both
/// read [auditTone].
typedef AuditTone = ({IconData icon, Color bg, Color fg});

AuditTone auditTone(AuditType t, SatColors sc) => switch (t) {
  AuditType.voidItem => (
    icon: Icons.delete_outline,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  AuditType.comp => (
    icon: Icons.card_giftcard_rounded,
    bg: sc.warnSoft,
    fg: sc.warn,
  ),
  AuditType.modify => (icon: Icons.edit_outlined, bg: sc.infoSoft, fg: sc.info),
  AuditType.fire => (
    icon: Icons.local_fire_department,
    bg: sc.accentSoft,
    fg: sc.accentText,
  ),
  AuditType.tableMoved => (
    icon: Icons.swap_horiz_rounded,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.paymentRecorded => (
    icon: Icons.payments_outlined,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  AuditType.refund => (icon: Icons.undo_rounded, bg: sc.warnSoft, fg: sc.warn),
  AuditType.discountApplied => (
    icon: Icons.sell_outlined,
    bg: sc.warnSoft,
    fg: sc.warn,
  ),
  AuditType.discountRemoved => (
    icon: Icons.sell_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.billReopened => (
    icon: Icons.lock_open_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.billClosed => (
    icon: Icons.receipt_long_outlined,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  // Deliberately `info` and not `success`: one hue covers all four movements,
  // and green on money leaving the box would read as revenue — which petty cash
  // never is (ADR-0089).
  AuditType.cashMovement => (
    icon: Icons.savings_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.memberChanged => (
    icon: Icons.badge_outlined,
    bg: sc.violetSoft,
    fg: sc.violet,
  ),
  // `warn`, not `success`: money on a tab is money not yet in the drawer, and
  // it should not read like a settled payment does.
  AuditType.debtMovement => (
    icon: Icons.account_balance_wallet_outlined,
    bg: sc.warnSoft,
    fg: sc.warn,
  ),
  // `warn`, not `urgent`: a variance is a discrepancy to look at, not an
  // emergency, and `urgent` stays scarce.
  AuditType.stockCounted => (
    icon: Icons.inventory_2_outlined,
    bg: sc.warnSoft,
    fg: sc.warn,
  ),
  // `urgent` is earned here and nowhere else in this switch: waste is value
  // destroyed on purpose, which is the one stock act a reader should stop on.
  AuditType.stockWasted => (
    icon: Icons.delete_outline,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  // `violet`: a sale, but not one the menu can account for — it should read as
  // distinct from the ordinary order acts a reader scrolls past.
  AuditType.openItemSold => (
    icon: Icons.edit_note_outlined,
    bg: sc.violetSoft,
    fg: sc.violet,
  ),
  // `info`: a guest ordering for themselves is a normal service event, not a
  // discrepancy and not money. It should read as traffic, not as a finding.
  AuditType.selfOrder => (
    icon: Icons.qr_code_2_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.menuKilled => (
    icon: Icons.remove_circle_outline,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  AuditType.menuRestored => (
    icon: Icons.add_circle_outline,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  AuditType.staffCreated => (
    icon: Icons.person_add_alt_1,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  AuditType.staffDeleted => (
    icon: Icons.person_remove,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  AuditType.staffDisabled => (
    icon: Icons.block,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  AuditType.staffEnabled => (
    icon: Icons.check_circle_outline,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  AuditType.staffRoleChanged => (
    icon: Icons.badge_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.staffPinSet => (
    icon: Icons.lock_reset,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.staffPinReset => (
    icon: Icons.lock_reset,
    bg: sc.warnSoft,
    fg: sc.warn,
  ),
  AuditType.roleCreated => (
    icon: Icons.shield_outlined,
    bg: sc.successSoft,
    fg: sc.success,
  ),
  AuditType.roleRenamed => (
    icon: Icons.edit_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.roleDeleted => (
    icon: Icons.shield_outlined,
    bg: sc.urgentSoft,
    fg: sc.urgent,
  ),
  AuditType.roleColorChanged => (
    icon: Icons.palette_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
  AuditType.roleCapabilityChanged => (
    icon: Icons.key_outlined,
    bg: sc.infoSoft,
    fg: sc.info,
  ),
};
