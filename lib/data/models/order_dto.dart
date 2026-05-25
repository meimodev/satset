import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_dto.freezed.dart';
part 'order_dto.g.dart';

@freezed
class CartLineDto with _$CartLineDto {
  const factory CartLineDto({
    required String itemId,
    required String name,
    required String variantId,
    required String variantName,
    required String station,
    required List<String> modifierOptionIds,
    required String? specialInstructions,
    required String course,
    required int qty,
    required int unitPrice,
  }) = _CartLineDto;

  factory CartLineDto.fromJson(Map<String, dynamic> json) =>
      _$CartLineDtoFromJson(json);
}

@freezed
class SubmitOrderRequestDto with _$SubmitOrderRequestDto {
  const factory SubmitOrderRequestDto({
    required String tableId,
    required String idempotencyKey,
    required List<CartLineDto> lines,
    String? actorId,
  }) = _SubmitOrderRequestDto;

  factory SubmitOrderRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitOrderRequestDtoFromJson(json);
}

@freezed
class SubmitOrderResponseDto with _$SubmitOrderResponseDto {
  const factory SubmitOrderResponseDto({
    required List<String> ticketIds,
  }) = _SubmitOrderResponseDto;

  factory SubmitOrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitOrderResponseDtoFromJson(json);
}
