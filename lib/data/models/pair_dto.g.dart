// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PairQrPayloadDtoImpl _$$PairQrPayloadDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PairQrPayloadDtoImpl(
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  fingerprint: json['fingerprint'] as String,
  token: json['token'] as String,
);

Map<String, dynamic> _$$PairQrPayloadDtoImplToJson(
  _$PairQrPayloadDtoImpl instance,
) => <String, dynamic>{
  'host': instance.host,
  'port': instance.port,
  'fingerprint': instance.fingerprint,
  'token': instance.token,
};

_$PairClaimRequestDtoImpl _$$PairClaimRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PairClaimRequestDtoImpl(
  token: json['token'] as String,
  deviceId: json['deviceId'] as String,
  deviceLabel: json['deviceLabel'] as String,
  publicKey: json['publicKey'] as String,
);

Map<String, dynamic> _$$PairClaimRequestDtoImplToJson(
  _$PairClaimRequestDtoImpl instance,
) => <String, dynamic>{
  'token': instance.token,
  'deviceId': instance.deviceId,
  'deviceLabel': instance.deviceLabel,
  'publicKey': instance.publicKey,
};

_$PairClaimResponseDtoImpl _$$PairClaimResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PairClaimResponseDtoImpl(
  deviceToken: json['deviceToken'] as String,
  fingerprint: json['fingerprint'] as String,
  serverPublicKey: json['serverPublicKey'] as String,
);

Map<String, dynamic> _$$PairClaimResponseDtoImplToJson(
  _$PairClaimResponseDtoImpl instance,
) => <String, dynamic>{
  'deviceToken': instance.deviceToken,
  'fingerprint': instance.fingerprint,
  'serverPublicKey': instance.serverPublicKey,
};
