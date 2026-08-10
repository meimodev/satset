import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/domain/models/ingredient.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/receipt_label.dart';
import 'package:satset/domain/models/stock_count.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Display name for a stored payment-method code (`tunai` | `kartu` | `qris` |
/// `transfer` | `lainnya` — CONTEXT.md, [[Payment (manual confirmation)]]).
///
/// The wire value is the Indonesian word and always will be: it is a database
/// enum, not copy, and renaming it would rewrite settled history. This is the
/// one place that turns it into something a person reads, because before this
/// the same five-entry map was hand-copied into the cashier screen, both the
/// accounting and order-history exporters, and the receipt builder — four
/// tables that agreed only by luck, one of which a translation pass would
/// inevitably have missed.
///
/// Falls through to the raw code for a value this build does not know, so an
/// older row never renders as a blank cell on a bank reconciliation.
String paymentMethodLabel(AppL10n l10n, String method) => switch (method) {
  'tunai' || 'cash' => l10n.payMethodCash,
  'kartu' || 'card' => l10n.payMethodCard,
  'qris' => l10n.payMethodQris,
  'transfer' => l10n.payMethodTransfer,
  'lainnya' => l10n.payMethodOther,
  _ => method,
};

/// The methods a cashier may pick, in the order the settle pane offers them.
///
/// The English aliases above are **read-only**: the sample seed writes `cash` /
/// `card`, so history holds both spellings and the renderer has to know it.
/// Nothing new is ever written under them.
const paymentMethods = ['tunai', 'kartu', 'qris', 'transfer', 'lainnya'];

/// Display name for a course, keyed by the serial id persisted on a ticket
/// (`Course.serialId`). The names themselves still live in
/// `domain/models/course.dart`, which carries no `AppL10n`; this is the reader.
String courseLabel(AppL10n l10n, String serialId) => switch (serialId) {
  'drinks-now' => l10n.courseDrinksNow,
  'starters' => l10n.courseStarters,
  'mains' => l10n.courseMains,
  'sides' => l10n.courseSides,
  'desserts' => l10n.courseDesserts,
  'fire-now' => l10n.courseFireNow,
  _ => serialId,
};

/// Prose form of a receipt label — the `A` / `1/3` stored in `Receipt.label`.
///
/// A letter reads as a guest, an `i/n` as a part (ADR-0068). Anything else
/// passes through: rows written before ADR-0085 hold the finished Indonesian
/// sentence (`Bagian 1/3`), and re-rendering them is impossible, so they stay
/// as recorded — the same fallback the audit log takes.
///
/// Splitting the letter test out (`isReceiptLetter`, `receiptPartOf`) keeps the
/// *shape* rules in `domain/models/receipt_label.dart`, where the server and
/// the printed slip can reach them without an `AppL10n`.
String receiptTitle(AppL10n l10n, String label) {
  final t = label.trim();
  if (t.isEmpty) return l10n.receiptDefault;
  if (isReceiptLetter(t)) return l10n.receiptGuest(t);
  final part = receiptPartOf(t);
  if (part != null) return l10n.receiptPart(part.$1, part.$2);
  return t;
}

/// Display name of a [StockDimension] — the ramp an ingredient's unit lives on.
///
/// Lives here, not on the enum, because it is copy: the unit *labels*
/// (`kg`, `butir`, `siung`) are venue vocabulary and stay as authored.
String stockDimensionLabel(AppL10n l10n, StockDimension d) => switch (d) {
  StockDimension.mass => l10n.stkDimMass,
  StockDimension.volume => l10n.stkDimVolume,
  StockDimension.count => l10n.stkDimCount,
};

/// Display name for a capability. The enum carries only its key: the words are
/// copy and belong in the ARB, and a permission list that reads "Take order" in
/// an Indonesian build is the one screen an owner has to get right.
String capabilityLabel(AppL10n l10n, Capability c) => switch (c) {
  Capability.takeOrder => l10n.capTakeOrder,
  Capability.modifyOrder => l10n.capModifyOrder,
  Capability.voidItem => l10n.capVoidItem,
  Capability.compItem => l10n.capCompItem,
  Capability.viewKds => l10n.capViewKds,
  Capability.openDrawer => l10n.capOpenDrawer,
  Capability.applyDiscount => l10n.capApplyDiscount,
  Capability.settleBill => l10n.capSettleBill,
  Capability.refund => l10n.capRefund,
  Capability.closeShift => l10n.capCloseShift,
  Capability.manageCash => l10n.capManageCash,
  Capability.editMenu => l10n.capEditMenu,
  Capability.markSoldOut => l10n.capMarkSoldOut,
  Capability.adjustStock => l10n.capAdjustStock,
  Capability.manageIngredients => l10n.capManageIngredients,
  Capability.overrideStock => l10n.capOverrideStock,
  Capability.manageMembers => l10n.capManageMembers,
  Capability.manageStaff => l10n.capManageStaff,
  Capability.manageRoles => l10n.capManageRoles,
  Capability.viewReports => l10n.capViewReports,
  Capability.editSettings => l10n.capEditSettings,
};

/// One line saying what a capability actually lets a person do. The labels
/// alone don't separate `adjustStock` from `manageIngredients` from
/// `overrideStock` — the grid this replaced had no room to say, and an owner
/// guessing at those three is how a waiter ends up able to sell past empty.
String capabilityDescription(AppL10n l10n, Capability c) => switch (c) {
  Capability.takeOrder => l10n.capTakeOrderDesc,
  Capability.modifyOrder => l10n.capModifyOrderDesc,
  Capability.voidItem => l10n.capVoidItemDesc,
  Capability.compItem => l10n.capCompItemDesc,
  Capability.viewKds => l10n.capViewKdsDesc,
  Capability.openDrawer => l10n.capOpenDrawerDesc,
  Capability.applyDiscount => l10n.capApplyDiscountDesc,
  Capability.settleBill => l10n.capSettleBillDesc,
  Capability.refund => l10n.capRefundDesc,
  Capability.closeShift => l10n.capCloseShiftDesc,
  Capability.manageCash => l10n.capManageCashDesc,
  Capability.editMenu => l10n.capEditMenuDesc,
  Capability.markSoldOut => l10n.capMarkSoldOutDesc,
  Capability.adjustStock => l10n.capAdjustStockDesc,
  Capability.manageIngredients => l10n.capManageIngredientsDesc,
  Capability.overrideStock => l10n.capOverrideStockDesc,
  Capability.manageMembers => l10n.capManageMembersDesc,
  Capability.manageStaff => l10n.capManageStaffDesc,
  Capability.manageRoles => l10n.capManageRolesDesc,
  Capability.viewReports => l10n.capViewReportsDesc,
  Capability.editSettings => l10n.capEditSettingsDesc,
};

/// Heading for a group of capabilities. The groups existed on the enum long
/// before anything rendered them — the grid iterated in group order and drew no
/// headers, so the grouping was structure nobody could see.
String capabilityGroupLabel(AppL10n l10n, CapabilityGroup g) => switch (g) {
  CapabilityGroup.orders => l10n.capGrpOrders,
  CapabilityGroup.money => l10n.capGrpMoney,
  CapabilityGroup.inventory => l10n.capGrpInventory,
  CapabilityGroup.admin => l10n.capGrpAdmin,
  CapabilityGroup.kitchen => l10n.capGrpKitchen,
};

/// Display name for a staff role. The enum name is persisted and is the join to
/// the ARB entry — see the note on [capabilityLabel].
String userRoleLabel(AppL10n l10n, UserRole r) => switch (r) {
  UserRole.waiter => l10n.roleWaiter,
  UserRole.kitchen => l10n.roleKitchen,
  UserRole.admin => l10n.roleAdmin,
};

/// Display name for a ticket status. Same rule as the roles: the enum travels
/// on the wire, the words do not.
String ticketStatusLabel(AppL10n l10n, TicketStatus s) => switch (s) {
  TicketStatus.draft => l10n.tstatDraft,
  TicketStatus.acknowledged => l10n.tstatAcknowledged,
  TicketStatus.sent => l10n.tstatSent,
  TicketStatus.prep => l10n.tstatPrep,
  TicketStatus.cooked => l10n.tstatCooked,
  TicketStatus.ready => l10n.tstatReady,
  TicketStatus.served => l10n.tstatServed,
  TicketStatus.held => l10n.tstatHeld,
  TicketStatus.voided => l10n.tstatVoided,
};

/// Display name for a reservation status.
String reservationStatusLabel(AppL10n l10n, ReservationStatus s) => switch (s) {
  ReservationStatus.pending => l10n.resStatPending,
  ReservationStatus.seated => l10n.resStatSeated,
  ReservationStatus.noShow => l10n.resStatNoShow,
  ReservationStatus.cancelled => l10n.resStatCancelled,
};

/// Why stock moved (ADR-0041). The reason is stored by `name`; only the
/// movement history renders it.
String stockReasonLabel(AppL10n l10n, StockReason r) => switch (r) {
  StockReason.sale => l10n.stkReasonSale,
  StockReason.voidReturn => l10n.stkReasonVoidReturn,
  StockReason.waste => l10n.stkReasonWaste,
  StockReason.receive => l10n.stkReasonReceive,
  StockReason.adjust => l10n.stkReasonAdjust,
  StockReason.produce => l10n.stkReasonProduce,
};

/// What a petty cash expense was for. Stored by `name` (see [CashCategory]) and
/// rendered on the Kas ledger, its post sheet, the Kas report section and the
/// audit sentence — one resolver so all four agree.
String cashCategoryLabel(AppL10n l10n, CashCategory c) => switch (c) {
  CashCategory.ingredients => l10n.cashCatIngredients,
  CashCategory.operations => l10n.cashCatOperations,
  CashCategory.transport => l10n.cashCatTransport,
  CashCategory.dailyWage => l10n.cashCatDailyWage,
  CashCategory.other => l10n.cashCatOther,
};

/// Same, from the raw persisted key — what an audit row and a report section
/// carry. Falls through to the key so a category written by a newer build never
/// renders blank.
String cashCategoryKeyLabel(AppL10n l10n, String key) {
  final c = cashCategoryFromName(key);
  return c == null ? key : cashCategoryLabel(l10n, c);
}

/// Whether an opname claims to have seen every bahan (ADR-0096). The claim is
/// the difference between "we counted March" and "we counted some things in
/// March", so it is rendered wherever a session is.
String stockCountScopeLabel(AppL10n l10n, StockCountScopeKind s) =>
    switch (s) {
      StockCountScopeKind.full => l10n.stkOpnameScopeFull,
      StockCountScopeKind.partial => l10n.stkOpnameScopePartial,
    };

/// Which movement of the petty cash box a row is.
String cashEntryKindLabel(AppL10n l10n, CashEntryKind k) => switch (k) {
  CashEntryKind.topUp => l10n.cashKindTopUp,
  CashEntryKind.expense => l10n.cashKindExpense,
  CashEntryKind.count => l10n.cashKindCount,
  CashEntryKind.reversal => l10n.cashKindReversal,
};

/// Which movement of a [[Poin]] ledger a row is.
String memberPointKindLabel(AppL10n l10n, MemberPointKind k) => switch (k) {
  MemberPointKind.earn => l10n.memPointKindEarn,
  MemberPointKind.redeem => l10n.memPointKindRedeem,
  MemberPointKind.adjust => l10n.memPointKindAdjust,
  MemberPointKind.reversal => l10n.memPointKindReversal,
};

/// Display name for a bundled alert clip. Ids that are already words in both
/// languages (`alarm`, `chime`, `marimba`, `pop`, `ting`…) fall through to a
/// title-cased id rather than carrying a redundant ARB pair.
String alertSoundLabel(AppL10n l10n, String id) => switch (id) {
  kNoneSoundId => l10n.sndSilent,
  'bell' => l10n.sndBell,
  'click' => l10n.sndClick,
  'critical_alarm' => l10n.sndCriticalAlarm,
  'doorbell' => l10n.sndDoorbell,
  'facility_alarm' => l10n.sndFacilityAlarm,
  'game_alarm' => l10n.sndGameAlarm,
  'happy_bell' => l10n.sndHappyBell,
  'harp' => l10n.sndHarp,
  'remove' => l10n.sndRemove,
  'short_alarm' => l10n.sndShortAlarm,
  'start' => l10n.sndStart,
  _ => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1),
};

/// The words for a [StaffException]. Codes only cross the layer (ADR-0085); an
/// unknown one renders as itself so a newer server never shows a blank toast.
String staffErrorMessage(AppL10n l10n, StaffException e) => switch (e.code) {
  'pinPoolExhausted' => l10n.staffErrPinPoolExhausted,
  'pinLength' => l10n.staffErrPinLength,
  'pinInUse' => l10n.staffErrPinInUse,
  'pinUpdateFailed' => l10n.staffErrPinUpdateFailed(e.arg),
  'lastAdmin' => l10n.staffErrLastAdmin,
  _ => e.code,
};
