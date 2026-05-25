// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PinLoginRequestDtoImpl _$$PinLoginRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PinLoginRequestDtoImpl(
  pin: json['pin'] as String,
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$$PinLoginRequestDtoImplToJson(
  _$PinLoginRequestDtoImpl instance,
) => <String, dynamic>{'pin': instance.pin, 'deviceId': instance.deviceId};

_$AdminLoginRequestDtoImpl _$$AdminLoginRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$AdminLoginRequestDtoImpl(
  email: json['email'] as String,
  password: json['password'] as String,
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$$AdminLoginRequestDtoImplToJson(
  _$AdminLoginRequestDtoImpl instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'deviceId': instance.deviceId,
};

_$SessionDtoImpl _$$SessionDtoImplFromJson(Map<String, dynamic> json) =>
    _$SessionDtoImpl(
      token: json['token'] as String,
      userId: json['userId'] as String,
      roleId: json['roleId'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$SessionDtoImplToJson(_$SessionDtoImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'roleId': instance.roleId,
      'capabilities': instance.capabilities,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_$MeDtoImpl _$$MeDtoImplFromJson(Map<String, dynamic> json) => _$MeDtoImpl(
  userId: json['userId'] as String,
  name: json['name'] as String,
  initials: json['initials'] as String,
  roleId: json['roleId'] as String,
  zoneAssigned: json['zoneAssigned'] as String?,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$MeDtoImplToJson(_$MeDtoImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'initials': instance.initials,
      'roleId': instance.roleId,
      'zoneAssigned': instance.zoneAssigned,
      'capabilities': instance.capabilities,
    };
