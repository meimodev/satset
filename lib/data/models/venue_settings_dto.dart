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
    @Default(false) bool taxEnabled,
    @Default(1100) int taxRateBps,
    @Default(false) bool serviceEnabled,
    @Default('percent') String serviceMode,
    @Default(500) int serviceRateBps,
    @Default(0) int serviceFixedAmount,
    @Default(4) int businessDayStartHour,
    @Default(15) int prepTargetMins,
    @Default(false) bool guestOrderingEnabled,
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
      );
}
