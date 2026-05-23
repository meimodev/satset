// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WsEventDtoImpl _$$WsEventDtoImplFromJson(Map<String, dynamic> json) =>
    _$WsEventDtoImpl(
      v: (json['v'] as num?)?.toInt() ?? 1,
      type: json['type'] as String,
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ts: DateTime.parse(json['ts'] as String),
    );

Map<String, dynamic> _$$WsEventDtoImplToJson(_$WsEventDtoImpl instance) =>
    <String, dynamic>{
      'v': instance.v,
      'type': instance.type,
      'payload': instance.payload,
      'ts': instance.ts.toIso8601String(),
    };
