import 'package:freezed_annotation/freezed_annotation.dart';

part 'pair_dto.freezed.dart';
part 'pair_dto.g.dart';

/// What `POST /pair/auto-claim` returns once the server has written the device
/// row. `serverPublicKey` is reserved for a future signed-payload/mTLS flow and
/// is currently empty (ADR-0003).
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
