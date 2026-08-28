// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PrinterDto _$PrinterDtoFromJson(Map<String, dynamic> json) => _PrinterDto(
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

Map<String, dynamic> _$PrinterDtoToJson(_PrinterDto instance) =>
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
