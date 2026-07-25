// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discount_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiscountPresetDtoImpl _$$DiscountPresetDtoImplFromJson(
  Map<String, dynamic> json,
) => _$DiscountPresetDtoImpl(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  scope: json['scope'] as String? ?? 'order',
  kind: json['kind'] as String? ?? 'percent',
  value: (json['value'] as num?)?.toInt() ?? 0,
  active: json['active'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$DiscountPresetDtoImplToJson(
  _$DiscountPresetDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'scope': instance.scope,
  'kind': instance.kind,
  'value': instance.value,
  'active': instance.active,
  'sortOrder': instance.sortOrder,
};

_$AppliedDiscountDtoImpl _$$AppliedDiscountDtoImplFromJson(
  Map<String, dynamic> json,
) => _$AppliedDiscountDtoImpl(
  id: json['id'] as String,
  ticketId: json['ticketId'] as String?,
  presetId: json['presetId'] as String?,
  name: json['name'] as String? ?? '',
  kind: json['kind'] as String? ?? 'percent',
  value: (json['value'] as num?)?.toInt() ?? 0,
  amount: (json['amount'] as num?)?.toInt() ?? 0,
  byUserId: json['byUserId'] as String?,
  approvedByUserId: json['approvedByUserId'] as String?,
);

Map<String, dynamic> _$$AppliedDiscountDtoImplToJson(
  _$AppliedDiscountDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'ticketId': instance.ticketId,
  'presetId': instance.presetId,
  'name': instance.name,
  'kind': instance.kind,
  'value': instance.value,
  'amount': instance.amount,
  'byUserId': instance.byUserId,
  'approvedByUserId': instance.approvedByUserId,
};
