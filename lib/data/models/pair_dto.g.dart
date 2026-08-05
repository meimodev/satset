// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
