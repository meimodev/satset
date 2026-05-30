import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _VenueSettingsDto;

  factory VenueSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$VenueSettingsDtoFromJson(json);
}
