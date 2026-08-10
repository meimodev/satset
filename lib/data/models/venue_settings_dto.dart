import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:satset/domain/use_cases/bill_math.dart';

part 'venue_settings_dto.freezed.dart';
part 'venue_settings_dto.g.dart';

@freezed
class VenueSettingsDto with _$VenueSettingsDto {
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
