// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WsEventDto _$WsEventDtoFromJson(Map<String, dynamic> json) => _WsEventDto(
  v: (json['v'] as num?)?.toInt() ?? 1,
  type: json['type'] as String,
  payload:
      json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  ts: DateTime.parse(json['ts'] as String),
);

Map<String, dynamic> _$WsEventDtoToJson(_WsEventDto instance) =>
    <String, dynamic>{
      'v': instance.v,
      'type': instance.type,
      'payload': instance.payload,
      'ts': instance.ts.toIso8601String(),
    };
