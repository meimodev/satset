// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceDtoImpl _$$DeviceDtoImplFromJson(Map<String, dynamic> json) =>
    _$DeviceDtoImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      revoked: json['revoked'] as bool? ?? false,
      lastSessionAt: json['lastSessionAt'] == null
          ? null
          : DateTime.parse(json['lastSessionAt'] as String),
      lastSessionUserId: json['lastSessionUserId'] as String?,
      sessionActive: json['sessionActive'] as bool? ?? false,
    );

Map<String, dynamic> _$$DeviceDtoImplToJson(_$DeviceDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'pairedAt': instance.pairedAt.toIso8601String(),
      'revoked': instance.revoked,
      'lastSessionAt': instance.lastSessionAt?.toIso8601String(),
      'lastSessionUserId': instance.lastSessionUserId,
      'sessionActive': instance.sessionActive,
    };
