import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_dto.freezed.dart';
part 'table_dto.g.dart';

@freezed
abstract class TableDto with _$TableDto {
  const factory TableDto({
    required String id,
    required String zoneId,
    required String? label,
    @Default(0) int pax,
    @Default(2) int capacity,
    @Default(true) bool active,
    @Default('available') String status,
    @Default(0) int openAmount,
    @Default(0) int readyCount,
    String? lastActorId,
    String? lockedBy,
    String? lockedByName,
    DateTime? lockedAt,
    DateTime? lockExpiresAt,
    DateTime? openedAt,
    String? guestName,
    String? guestNotes,
    String? reservationId,
    String? currentVisitId,
    DateTime? billClosedAt,
    String? moneyState,
  }) = _TableDto;

  factory TableDto.fromJson(Map<String, dynamic> json) =>
      _$TableDtoFromJson(json);
}

@freezed
abstract class UpdateTablePaxDto with _$UpdateTablePaxDto {
  const factory UpdateTablePaxDto({required int pax}) = _UpdateTablePaxDto;

  factory UpdateTablePaxDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateTablePaxDtoFromJson(json);
}

@freezed
abstract class UpdateTableHandlerDto with _$UpdateTableHandlerDto {
  const factory UpdateTableHandlerDto({required String userId}) =
      _UpdateTableHandlerDto;

  factory UpdateTableHandlerDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateTableHandlerDtoFromJson(json);
}
