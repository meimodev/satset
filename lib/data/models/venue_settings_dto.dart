import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/models/venue_module.dart';

part 'venue_settings_dto.freezed.dart';
part 'venue_settings_dto.g.dart';

@freezed
abstract class VenueSettingsDto with _$VenueSettingsDto {
  const factory VenueSettingsDto({
    @Default('default') String id,
    @Default('Warung Sebelah') String displayName,
    @Default('') String legalName,
    @Default('') String address,
    @Default('') String phone,
    @Default('') String receiptHeader,
    @Default('') String receiptFooter,
    // Receipt branding block (ADR-0033). Logo bytes are NOT carried here — they
    // ride the side-endpoint /venue/logo, cache-busted by logoRev.
    @Default('') String receiptTagline,
    @Default('') String receiptSocial,
    @Default('') String receiptThankYou,
    @Default('') String receiptQrUrl,
    @Default('') String receiptQrCaption,
    @Default(0) int logoRev,
    @Default(false) bool taxEnabled,
    @Default(1100) int taxRateBps,
    @Default(false) bool serviceEnabled,
    @Default('percent') String serviceMode,
    @Default(500) int serviceRateBps,
    @Default(0) int serviceFixedAmount,

    /// Where a whole-order discount sits in the stack (ADR-0038). Default true
    /// = DPP-correct (the discount reduces the base service and tax compute
    /// from). Line discounts are always pre-tax and ignore this.
    @Default(true) bool taxAfterDiscount,
    @Default(4) int businessDayStartHour,
    @Default(15) int prepTargetMins,
    // Service timings (ADR-0043/0044). `prepTargetMins` above is now the
    // venue *default* every item with a null `prepTime` inherits.
    @Default(4) int pickupTargetMins,
    @Default(7) int ungreetedMins,
    @Default(5) int ungreetedEscalateMins,
    @Default(90) int longStayMins,
    @Default(20) int idleTableMins,
    @Default(15) int reservationGraceMins,

    @Default(true) bool ungreetedAlertEnabled,
    @Default(true) bool pickupAlertEnabled,
    // Per-event alert sound choice (ADR-0035). Each holds a preset id from
    // `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
    // original fixed cues exactly.
    @Default('alert') String soundNewOrder,
    @Default('chime') String soundReady,
    @Default('alert') String soundVoid,
    @Default('alert') String soundOverdue,
    @Default('chime') String soundUngreeted,
    @Default('chime') String soundPickup,

    // Membership (ADR-0091). Off by default — a venue opts in, and until it
    // does the member row, the directory and the receipt lines do not exist.
    @Default(false) bool membersEnabled,

    /// Whether the [[Salinan pelanggan]] mirrors to this device (ADR-0129).
    /// Defaults **true**, unlike every other flag on this DTO: it is the one
    /// switch whose safe answer is on, because the feature it gates is what a
    /// device falls back to when it can ask nobody anything.
    @Default(true) bool memberMirrorEnabled,
    @Default(false) bool memberPointsEnabled,
    @Default(false) bool memberPunchEnabled,

    /// The [[Preset diskon]] nominated as the standing member discount, or null
    /// for a venue running membership on points and stempel alone (ADR-0094).
    String? memberPresetId,
    @Default(1) int memberEarnPerThousand,
    @Default(1000) int memberPointValue,
    @Default(10) int memberRedeemMin,
    String? memberPunchItemId,
    @Default(10) int memberPunchTarget,

    // Piutang (ADR-0098). Nested under [membersEnabled] — a venue that keeps no
    // guest directory cannot run tabs against guests it does not keep.
    @Default(false) bool memberDebtEnabled,

    /// The venue-wide credit limit a member falls back to when they have none
    /// of their own. **0 is the shipped default and means "no tab"** — turning
    /// the feature on trusts nobody until an owner names a number.
    @Default(0) int memberDebtLimit,

    /// How long a tab may stand before the report calls it overdue. A credit
    /// policy, not a fact, which is why it is a setting.
    @Default(30) int memberDebtOverdueDays,

    // [[Pesan mandiri]] (ADR-0105). Off by default — a venue opts in, and until
    // it does the cleartext guest listener does not bind at all.
    @Default(false) bool guestOrderingEnabled,
    @Default(true) bool guestNoteEnabled,

    /// The service window, in minutes from midnight. **Equal values mean no
    /// window** (the default): a guest may order whenever the server is up.
    @Default(0) int guestHoursStartMin,
    @Default(0) int guestHoursEndMin,
    @Default(20) int guestMaxItems,
    @Default(4) int guestSessionHours,
    @Default('chime') String soundGuestPending,

    /// Whether a [[Waiter|pelayan]] may record a [[Pengeluaran kunjungan]]
    /// against the visit they are serving (ADR-0130). Off by default — a venue
    /// opts in, and the [[Modul|mode key]] `tableExpense` has to be held on top.
    @Default(false) bool tableExpenseEnabled,

    /// The [[Modul]] set the venue holds (ADR-0107). Cloud-owned and mirrored
    /// down; no screen writes it.
    ///
    /// **Null means never mirrored** and reads as entitled to everything — an
    /// empty list is the different, real answer "holds no module". A client that
    /// draws a locked tile must check for null first, or an upgraded venue sees
    /// padlocks on features it pays for.
    List<String>? modules,

    /// The [[Kedai]] mode switches that are on (ADR-0109). Cloud-owned and
    /// mirrored down beside [modules]; no screen writes it.
    ///
    /// **Null and empty mean the same thing** here, unlike [modules]: a mode
    /// fails closed, so a venue that has never mirrored is a restaurant. Read
    /// through [counterOn], which also ANDs the mode key itself — a switch
    /// without the mode is half a shape.
    List<String>? counterConfig,
  }) = _VenueSettingsDto;

  factory VenueSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$VenueSettingsDtoFromJson(json);
}

/// Maps the venue settings wire DTO onto the pure-domain [TaxServiceConfig]
/// so client-side estimates (cart pane, review screen) run the *same*
/// service-then-tax math as server settlement — see bill_math.dart and
/// CONTEXT.md "Tax & service charge".
extension VenueSettingsTaxCfg on VenueSettingsDto {
  TaxServiceConfig toTaxServiceConfig() => TaxServiceConfig(
    taxEnabled: taxEnabled,
    taxRateBps: taxRateBps,
    serviceEnabled: serviceEnabled,
    serviceMode: serviceMode,
    serviceRateBps: serviceRateBps,
    serviceFixedAmount: serviceFixedAmount,
    taxAfterDiscount: taxAfterDiscount,
  );
}

/// Entitlement (ADR-0107) composed with the owner's switch — the pair a floor
/// surface has to ask about, since a venue that did not buy the [[Modul]] must
/// not be shown the affordance at all. `modules == null` is "never mirrored",
/// which reads as entitled; the hub's locked tile is the one place the two
/// halves are deliberately told apart.
extension VenueSettingsModules on VenueSettingsDto {
  bool hasModule(String key) => modules?.contains(key) ?? true;

  /// Whether this venue is a counter shop at all (ADR-0109). Fails **closed**,
  /// which is the whole reason it is not [hasModule]: the fail-open that
  /// protects a paid feature would reshape every unmirrored restaurant.
  bool get counterMode => modules?.contains(modeCounterService) ?? false;

  /// Whether [key] — one of `counterSwitchKeys` — is on.
  bool counterOn(String key) =>
      counterMode && (counterConfig?.contains(key) ?? false);

  /// Whether this venue has no prep queue (ADR-0115). Fails **closed**, like
  /// [counterMode] and for the same reason, and is **independent of it** — a
  /// counter shop may still run a cook line.
  ///
  /// This is the client half of the read; the server decides what a line is
  /// *born* as, and every surface here only decides what to draw.
  bool get bypassKds => modules?.contains(modeBypassKds) ?? false;
  bool get membersOn => membersEnabled && hasModule(moduleMembers);

  /// The mirror needs membership itself, the entitlement, and the owner's own
  /// switch — composed here, so no screen ANDs it for itself (ADR-0107 §3).
  bool get memberMirrorOn => membersOn && memberMirrorEnabled;

  /// Whether a share of a split bill may name its own [[Pemilik struk]]
  /// (ADR-0118). Fails **closed**, like the other mode keys, and ANDs with
  /// [membersOn] — attribution with no membership to attribute to is a picker
  /// that can only 404.
  ///
  /// The floor reads this, never the bare mode key, for the reason ADR-0107
  /// puts on every sellable gate: the AND belongs in one place.
  bool get memberSplitOn =>
      membersOn && (modules?.contains(modeMemberSplit) ?? false);
  bool get guestOrderingOn =>
      guestOrderingEnabled && hasModule(moduleSelfOrder);

  /// Whether the floor may record a [[Pengeluaran kunjungan]] (ADR-0130).
  /// Fails **closed**, like the other mode keys, and ANDs with the owner's own
  /// switch — the pair, in one place, for the reason ADR-0107 puts on every
  /// gate: a surface that reads the bare preference leaves an unentitled venue
  /// a button whose only outcome is a 404.
  ///
  /// This says whether the venue *does this at all*. Whether the person
  /// holding the handset may is `Capability.recordTableExpense`, and both have
  /// to be true before the affordance is drawn.
  bool get tableExpenseOn =>
      tableExpenseEnabled && (modules?.contains(modeTableExpense) ?? false);

  /// Whether this venue calls a [[Meja]] a **Layanan · Service** (ADR-0127).
  /// Fails **closed**, like the other mode keys, and ANDs with nothing — it is
  /// vocabulary, not entitlement, so there is no owner switch beneath it.
  ///
  /// Read in exactly one place, `SatLocaleNotifier`: it picks the locale and
  /// every string in the app follows. A screen that asks this for itself is a
  /// review finding — that is a copy branch, and copy lives in the ARB.
  bool get serviceTerm => modules?.contains(modeServiceTerm) ?? false;
}
