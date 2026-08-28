import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_status_dto.freezed.dart';
part 'system_status_dto.g.dart';

@freezed
abstract class SystemStatusDto with _$SystemStatusDto {
  const factory SystemStatusDto({
    required DateTime startedAt,
    @Default(0) int uptimeMs,
    @Default('0.0.0.0') String listenAddress,
    @Default(7443) int port,
    required DateTime tlsCertExpiry,
    required DateTime tlsCertIssuedAt,
    @Default('') String tlsFingerprint,
    @Default(0) int activeSessions,
    @Default(0) int pairedDevices,
    @Default(0) int requestCountRecent,
    @Default(0) int p50LatencyMs,
    @Default(0) int p95LatencyMs,
  }) = _SystemStatusDto;

  factory SystemStatusDto.fromJson(Map<String, dynamic> json) =>
      _$SystemStatusDtoFromJson(json);
}

@freezed
abstract class KdsStationDto with _$KdsStationDto {
  const factory KdsStationDto({
    required String station,
    @Default(0) int pendingTickets,
    @Default(0) int staffOnline,
  }) = _KdsStationDto;

  factory KdsStationDto.fromJson(Map<String, dynamic> json) =>
      _$KdsStationDtoFromJson(json);
}

@freezed
abstract class QueueDepthDto with _$QueueDepthDto {
  const factory QueueDepthDto({
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> byStation,
  }) = _QueueDepthDto;

  factory QueueDepthDto.fromJson(Map<String, dynamic> json) =>
      _$QueueDepthDtoFromJson(json);
}
