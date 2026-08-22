// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PinLoginRequestDto _$PinLoginRequestDtoFromJson(Map<String, dynamic> json) =>
    _PinLoginRequestDto(
      pin: json['pin'] as String,
      deviceId: json['deviceId'] as String,
    );

Map<String, dynamic> _$PinLoginRequestDtoToJson(_PinLoginRequestDto instance) =>
    <String, dynamic>{'pin': instance.pin, 'deviceId': instance.deviceId};

_AdminLoginRequestDto _$AdminLoginRequestDtoFromJson(
  Map<String, dynamic> json,
) => _AdminLoginRequestDto(
  email: json['email'] as String,
  password: json['password'] as String,
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$AdminLoginRequestDtoToJson(
  _AdminLoginRequestDto instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'deviceId': instance.deviceId,
};

_SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => _SessionDto(
  token: json['token'] as String,
  userId: json['userId'] as String,
  roleId: json['roleId'] as String,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$SessionDtoToJson(_SessionDto instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'roleId': instance.roleId,
      'capabilities': instance.capabilities,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_MeDto _$MeDtoFromJson(Map<String, dynamic> json) => _MeDto(
  userId: json['userId'] as String,
  name: json['name'] as String,
  initials: json['initials'] as String,
  roleId: json['roleId'] as String,
  zoneAssigned: json['zoneAssigned'] as String?,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  avatarColorHex: (json['avatarColorHex'] as num?)?.toInt(),
  shiftStartedAt: json['shiftStartedAt'] as String?,
  shiftTracked: json['shiftTracked'] as bool? ?? false,
);

Map<String, dynamic> _$MeDtoToJson(_MeDto instance) => <String, dynamic>{
  'userId': instance.userId,
  'name': instance.name,
  'initials': instance.initials,
  'roleId': instance.roleId,
  'zoneAssigned': instance.zoneAssigned,
  'capabilities': instance.capabilities,
  'avatarColorHex': instance.avatarColorHex,
  'shiftStartedAt': instance.shiftStartedAt,
  'shiftTracked': instance.shiftTracked,
};
