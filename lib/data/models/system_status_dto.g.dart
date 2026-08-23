// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SystemStatusDto _$SystemStatusDtoFromJson(Map<String, dynamic> json) =>
    _SystemStatusDto(
      startedAt: DateTime.parse(json['startedAt'] as String),
      uptimeMs: (json['uptimeMs'] as num?)?.toInt() ?? 0,
      listenAddress: json['listenAddress'] as String? ?? '0.0.0.0',
      port: (json['port'] as num?)?.toInt() ?? 7443,
      tlsCertExpiry: DateTime.parse(json['tlsCertExpiry'] as String),
      tlsCertIssuedAt: DateTime.parse(json['tlsCertIssuedAt'] as String),
      tlsFingerprint: json['tlsFingerprint'] as String? ?? '',
      activeSessions: (json['activeSessions'] as num?)?.toInt() ?? 0,
      pairedDevices: (json['pairedDevices'] as num?)?.toInt() ?? 0,
      requestCountRecent: (json['requestCountRecent'] as num?)?.toInt() ?? 0,
      p50LatencyMs: (json['p50LatencyMs'] as num?)?.toInt() ?? 0,
      p95LatencyMs: (json['p95LatencyMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SystemStatusDtoToJson(_SystemStatusDto instance) =>
    <String, dynamic>{
      'startedAt': instance.startedAt.toIso8601String(),
      'uptimeMs': instance.uptimeMs,
      'listenAddress': instance.listenAddress,
      'port': instance.port,
      'tlsCertExpiry': instance.tlsCertExpiry.toIso8601String(),
      'tlsCertIssuedAt': instance.tlsCertIssuedAt.toIso8601String(),
      'tlsFingerprint': instance.tlsFingerprint,
      'activeSessions': instance.activeSessions,
      'pairedDevices': instance.pairedDevices,
      'requestCountRecent': instance.requestCountRecent,
      'p50LatencyMs': instance.p50LatencyMs,
      'p95LatencyMs': instance.p95LatencyMs,
    };

_KdsStationDto _$KdsStationDtoFromJson(Map<String, dynamic> json) =>
    _KdsStationDto(
      station: json['station'] as String,
      pendingTickets: (json['pendingTickets'] as num?)?.toInt() ?? 0,
      staffOnline: (json['staffOnline'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$KdsStationDtoToJson(_KdsStationDto instance) =>
    <String, dynamic>{
      'station': instance.station,
      'pendingTickets': instance.pendingTickets,
      'staffOnline': instance.staffOnline,
    };

_QueueDepthDto _$QueueDepthDtoFromJson(Map<String, dynamic> json) =>
    _QueueDepthDto(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStation:
          (json['byStation'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
    );

Map<String, dynamic> _$QueueDepthDtoToJson(_QueueDepthDto instance) =>
    <String, dynamic>{'total': instance.total, 'byStation': instance.byStation};
