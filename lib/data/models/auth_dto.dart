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

    /// Start of the caller's open shift, server-authoritative (ADR-0097). Null
    /// when they have no open shift — after signing out, or once the
    /// business-day boundary has retired a forgotten one.
    String? shiftStartedAt,

    /// Whether this host records shifts at all, which is the only thing that
    /// makes a null [shiftStartedAt] readable. A host that keeps shifts sends
    /// true and its null means *no open shift*; a legacy host omits the field
    /// and its null means *no opinion*, so the client falls back to its own
    /// `loginAt`. Without the distinction the fallback fires on a retired
    /// shift and the app bar counts up against a row the server has closed.
    @Default(false) bool shiftTracked,
  }) = _MeDto;

  factory MeDto.fromJson(Map<String, dynamic> json) => _$MeDtoFromJson(json);
}
