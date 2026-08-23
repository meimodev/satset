// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PairClaimResponseDto _$PairClaimResponseDtoFromJson(
  Map<String, dynamic> json,
) => _PairClaimResponseDto(
  deviceToken: json['deviceToken'] as String,
  fingerprint: json['fingerprint'] as String,
  serverPublicKey: json['serverPublicKey'] as String,
);

Map<String, dynamic> _$PairClaimResponseDtoToJson(
  _PairClaimResponseDto instance,
) => <String, dynamic>{
  'deviceToken': instance.deviceToken,
  'fingerprint': instance.fingerprint,
  'serverPublicKey': instance.serverPublicKey,
};
