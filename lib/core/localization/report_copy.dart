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

/// The eight report headline tiles. [KpiTileDto.value] is already formatted by
/// the server: it is money or a minute count, and money never localises
/// (ADR-0084).
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
