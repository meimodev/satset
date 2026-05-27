// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueSettingsDtoImpl _$$VenueSettingsDtoImplFromJson(
  Map<String, dynamic> json,
) => _$VenueSettingsDtoImpl(
  id: json['id'] as String? ?? 'default',
  displayName: json['displayName'] as String? ?? 'Warung Sebelah',
  legalName: json['legalName'] as String? ?? '',
  address: json['address'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  receiptHeader: json['receiptHeader'] as String? ?? '',
  receiptFooter: json['receiptFooter'] as String? ?? '',
  taxEnabled: json['taxEnabled'] as bool? ?? false,
  taxRateBps: (json['taxRateBps'] as num?)?.toInt() ?? 1100,
  serviceEnabled: json['serviceEnabled'] as bool? ?? false,
  serviceMode: json['serviceMode'] as String? ?? 'percent',
  serviceRateBps: (json['serviceRateBps'] as num?)?.toInt() ?? 500,
  serviceFixedAmount: (json['serviceFixedAmount'] as num?)?.toInt() ?? 0,
  businessDayStartHour: (json['businessDayStartHour'] as num?)?.toInt() ?? 4,
);

Map<String, dynamic> _$$VenueSettingsDtoImplToJson(
  _$VenueSettingsDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'legalName': instance.legalName,
  'address': instance.address,
  'phone': instance.phone,
  'receiptHeader': instance.receiptHeader,
  'receiptFooter': instance.receiptFooter,
  'taxEnabled': instance.taxEnabled,
  'taxRateBps': instance.taxRateBps,
  'serviceEnabled': instance.serviceEnabled,
  'serviceMode': instance.serviceMode,
  'serviceRateBps': instance.serviceRateBps,
  'serviceFixedAmount': instance.serviceFixedAmount,
  'businessDayStartHour': instance.businessDayStartHour,
};
