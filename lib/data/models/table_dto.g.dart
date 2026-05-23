// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableDtoImpl _$$TableDtoImplFromJson(Map<String, dynamic> json) =>
    _$TableDtoImpl(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      label: json['label'] as String?,
      pax: (json['pax'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      status: json['status'] as String? ?? 'available',
      openAmount: (json['openAmount'] as num?)?.toInt() ?? 0,
      readyCount: (json['readyCount'] as num?)?.toInt() ?? 0,
      lastActorId: json['lastActorId'] as String?,
    );

Map<String, dynamic> _$$TableDtoImplToJson(_$TableDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'zoneId': instance.zoneId,
      'label': instance.label,
      'pax': instance.pax,
      'active': instance.active,
      'status': instance.status,
      'openAmount': instance.openAmount,
      'readyCount': instance.readyCount,
      'lastActorId': instance.lastActorId,
    };

_$UpdateTablePaxDtoImpl _$$UpdateTablePaxDtoImplFromJson(
  Map<String, dynamic> json,
) => _$UpdateTablePaxDtoImpl(pax: (json['pax'] as num).toInt());

Map<String, dynamic> _$$UpdateTablePaxDtoImplToJson(
  _$UpdateTablePaxDtoImpl instance,
) => <String, dynamic>{'pax': instance.pax};

_$UpdateTableHandlerDtoImpl _$$UpdateTableHandlerDtoImplFromJson(
  Map<String, dynamic> json,
) => _$UpdateTableHandlerDtoImpl(userId: json['userId'] as String);

Map<String, dynamic> _$$UpdateTableHandlerDtoImplToJson(
  _$UpdateTableHandlerDtoImpl instance,
) => <String, dynamic>{'userId': instance.userId};
