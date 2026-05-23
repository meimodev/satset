import 'package:freezed_annotation/freezed_annotation.dart';

part 'pair_dto.freezed.dart';
part 'pair_dto.g.dart';

/// Payload encoded in pairing QR codes.
@freezed
class PairQrPayloadDto with _$PairQrPayloadDto {
  const factory PairQrPayloadDto({
    required String host,
    required int port,
    required String fingerprint,
    required String token,
  }) = _PairQrPayloadDto;

  factory PairQrPayloadDto.fromJson(Map<String, dynamic> json) =>
      _$PairQrPayloadDtoFromJson(json);
}

@freezed
class PairClaimRequestDto with _$PairClaimRequestDto {
  const factory PairClaimRequestDto({
    required String token,
    required String deviceId,
    required String deviceLabel,
    required String publicKey,
  }) = _PairClaimRequestDto;

  factory PairClaimRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PairClaimRequestDtoFromJson(json);
}

@freezed
class PairClaimResponseDto with _$PairClaimResponseDto {
  const factory PairClaimResponseDto({
    required String deviceToken,
    required String fingerprint,
    required String serverPublicKey,
  }) = _PairClaimResponseDto;

  factory PairClaimResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PairClaimResponseDtoFromJson(json);
}
