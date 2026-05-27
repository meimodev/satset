// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrinterDtoImpl _$$PrinterDtoImplFromJson(Map<String, dynamic> json) =>
    _$PrinterDtoImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      host: json['host'] as String,
      port: (json['port'] as num?)?.toInt() ?? 9100,
      kind: json['kind'] as String? ?? 'escpos',
      enabled: json['enabled'] as bool? ?? true,
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PrinterDtoImplToJson(_$PrinterDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'host': instance.host,
      'port': instance.port,
      'kind': instance.kind,
      'enabled': instance.enabled,
      'lastSeenAt': instance.lastSeenAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
