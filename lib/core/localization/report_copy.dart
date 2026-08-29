/// Rendering for the codes the server puts on the wire.
///
/// ADR-0085. The embedded server has a language of its own — the *host tablet's*
/// — and a report composed there would arrive at a phone in whatever the kitchen
/// tablet happens to be set to. So the server sends a stable code and the reader
/// renders it, the same rule the audit log already runs on. Nothing here is a
/// widget: the PDF and CSV exporters read these too, and they hold an [AppL10n]
/// rather than a `BuildContext`.
///
/// Every resolver falls back to the code itself. A code this build has never
/// heard of is a venue-authored or newer-server value, and showing it raw beats
/// showing a blank.
library;

import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

/// Canonical void reasons (ADR-0006). Same six the void sheet offers, so a
/// report names a void with the words the waiter picked.
String voidReasonLabel(AppL10n l, String code) => switch (code) {
  'wrongOrder' => l.vrsWrongOrder,
  'customerChange' => l.vrsCustomerChange,
  'outOfStock' => l.vrsOutOfStock,
  'kitchenError' => l.vrsKitchenError,
  'comp' => l.vrsComp,
  'other' => l.vrsOther,
  _ => code,
};

/// The one-line "what this reason means" the void sheet shows under each
/// choice. Report surfaces list reasons without it.
String voidReasonDesc(AppL10n l, String code) => switch (code) {
  'wrongOrder' => l.vrsWrongOrderDesc,
  'customerChange' => l.vrsCustomerChangeDesc,
  'outOfStock' => l.vrsOutOfStockDesc,
  'kitchenError' => l.vrsKitchenErrorDesc,
  'other' => l.vrsOtherDesc,
  _ => '',
};

/// Seeded modifier groups. A venue-authored group falls through to its own id,
/// which is the venue's own name for it and must not be translated.
String modifierGroupLabel(AppL10n l, String groupId) => switch (groupId) {
  'spice' => l.modGroupSpice,
  'extras' => l.modGroupExtras,
  'sauce' => l.modGroupSauce,
  'protein' => l.modGroupProtein,
  _ => groupId,
};

/// One unified station for now — the KDS has never split (see kitchen_screen).
/// `Dapur` is the same station under the name the order-taking flow passes on
/// the query string; `Bar` reads the same in both languages and falls through.
String stationLabel(AppL10n l, String station) => switch (station) {
  'kitchen' || 'Dapur' => l.rptStationKitchen,
  _ => station,
};

/// A void whose acting waiter is no longer resolvable — a deleted user, or a
/// row written before the actor was recorded.
String staffName(AppL10n l, String id, String name) =>
    id == 'unknown' ? l.rptUnknownStaff : name;

/// The headline number on a tile. A money tile carries the amount and is
/// rendered here; everything else (a minute count, a seated/booked ratio) is
/// already a string the server formatted.
String kpiValue(AppL10n l, KpiTileDto k) =>
    k.rupiah == null ? k.value : formatCompactIDR(l, k.rupiah!);

/// The eight report headline tiles.
String kpiLabel(AppL10n l, KpiTileDto k) => switch (k.key) {
  'net' => l.rptKpiNet,
  'gross' => l.rptKpiGross,
  'taxService' => l.rptKpiTaxService,
  'void' => l.rptKpiVoid,
  'turnTime' => l.rptKpiTurnTime,
  'prep' => l.rptKpiPrep,
  'pickup' => l.rptKpiPickup,
  'reservations' => l.rptKpiReservations,
  _ => k.label,
};

/// The caption under a headline tile. The counts ride along in
/// [KpiTileDto.args] in the order the message declares them.
String kpiSub(AppL10n l, KpiTileDto k) {
  int arg(int i) => i < k.args.length ? k.args[i] : 0;
  return switch (k.key) {
    'net' => l.rptSubNet(arg(0), arg(1)),
    'gross' => l.rptSubGross(arg(0)),
    'taxService' => l.rptSubTaxService,
    'void' => l.rptSubVoid(arg(0)),
    'turnTime' => l.rptSubTurnTime,
    'prep' => l.rptSubPrep,
    'pickup' => l.rptSubPickup,
    'reservations' => l.rptSubReservations(arg(0), arg(1)),
    _ => k.sub,
  };
}

/// Why the host refused a replayed order (ADR-0090). The queue carries the
/// server's `code`; the sentence is composed here, like every other code that
/// crosses the layer (ADR-0085).
String sendFailureText(AppL10n l, String? code) => switch (code) {
  'forbidden' => l.sendFailBlocked,
  'visit_changed' => l.sendFailVisitChanged,
  'bill_closed' => l.sendFailBillClosed,
  'expired' => l.sendFailExpired,
  'blocked' => l.sendFailBlocked,
  _ => l.sendFailOther,
};

/// Why a void did not happen (ADR-0006). The sheet resolves the exception to
/// a code and the words are composed here, like every other code that crosses
/// the layer (ADR-0085). An unknown code still renders a sentence.
///
/// The two 403 flavours are a real distinction, not a nicety: "your role
/// cannot void" is a permissions problem, "this one needs a manager" is the
/// deliberate comp gate, and a waiter told the wrong one either stops trying
/// or goes looking for the wrong person.
String voidFailureText(AppL10n l, String? code) => switch (code) {
  'forbidden' => l.voidFailForbidden,
  'forbidden_comp' => l.voidFailNeedsManager,
  'illegal_transition' => l.voidFailAlreadyMoved,
  'reason_required' => l.voidFailReasonRequired,
  'send_queue_full' => l.sendQueueFull,
  _ => l.voidFailOther,
};

/// Why the host refused a decision on a guest order (ADR-0105). Same shape as
/// [sendFailureText] and for the same reason: the server sends a code, the
/// words are composed here, and an unknown code still renders a sentence.
///
/// Accepting can genuinely fail — the stock refusal rolls the whole accept
/// back, so the intent is still on the queue and whoever pressed the button
/// has to be told that rather than left looking at a row that did not move.
String guestDecisionFailureText(AppL10n l, String? code) => switch (code) {
  'accept_rejected_by_stock' => l.soFailStock,
  'already_decided' => l.soFailDecided,
  'not_found' => l.soFailGone,
  _ => l.soFailOther,
};
