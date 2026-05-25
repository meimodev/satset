/// Wire DTOs for the LAN auth endpoints.
///
/// These types are intentionally JSON-shaped; repositories own the
/// translation to/from `lib/domain/models/*`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dto.freezed.dart';
part 'auth_dto.g.dart';

@freezed
class PinLoginRequestDto with _$PinLoginRequestDto {
  const factory PinLoginRequestDto({
    required String pin,
    required String deviceId,
  }) = _PinLoginRequestDto;

  factory PinLoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PinLoginRequestDtoFromJson(json);
}

@freezed
class AdminLoginRequestDto with _$AdminLoginRequestDto {
  const factory AdminLoginRequestDto({
    required String email,
    required String password,
    required String deviceId,
  }) = _AdminLoginRequestDto;

  factory AdminLoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AdminLoginRequestDtoFromJson(json);
}

@freezed
class SessionDto with _$SessionDto {
  const factory SessionDto({
    required String token,
    required String userId,
    required String roleId,
    required List<String> capabilities,
    required DateTime expiresAt,
  }) = _SessionDto;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);
}

@freezed
class MeDto with _$MeDto {
  const factory MeDto({
    required String userId,
    required String name,
    required String initials,
    required String roleId,
    required String? zoneAssigned,
    required List<String> capabilities,
    int? avatarColorHex,
  }) = _MeDto;

  factory MeDto.fromJson(Map<String, dynamic> json) => _$MeDtoFromJson(json);
}
