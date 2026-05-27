import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Canonical status values exchanged with the server. Mirrored in
/// `domain/models/reservation.dart` as a typed enum.
class ReservationStatusKey {
  ReservationStatusKey._();
  static const pending = 'pending';
  static const seated = 'seated';
  static const noShow = 'noShow';
  static const cancelled = 'cancelled';
}

@freezed
class ReservationDto with _$ReservationDto {
  const factory ReservationDto({
    required String id,
    required String name,
    String? phone,
    @Default(1) int partySize,
    required DateTime expectedAt,
    @Default('pending') String status,
    String? zoneId,
    String? tableId,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ReservationDto;

  factory ReservationDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationDtoFromJson(json);
}

@freezed
class CreateReservationDto with _$CreateReservationDto {
  const factory CreateReservationDto({
    required String name,
    String? phone,
    @Default(1) int partySize,
    required DateTime expectedAt,
    String? zoneId,
    String? tableId,
    String? notes,
  }) = _CreateReservationDto;

  factory CreateReservationDto.fromJson(Map<String, dynamic> json) =>
      _$CreateReservationDtoFromJson(json);
}

@freezed
class PatchReservationDto with _$PatchReservationDto {
  const factory PatchReservationDto({
    String? name,
    String? phone,
    int? partySize,
    DateTime? expectedAt,
    String? status,
    String? zoneId,
    String? tableId,
    String? notes,
  }) = _PatchReservationDto;

  factory PatchReservationDto.fromJson(Map<String, dynamic> json) =>
      _$PatchReservationDtoFromJson(json);
}
