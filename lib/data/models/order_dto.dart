import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_dto.freezed.dart';
part 'order_dto.g.dart';

/// One chosen add-on on an outgoing order line. The client builds these
/// (it holds the menu); the server stores them verbatim. See
/// docs/adr/0011-ticket-modifier-snapshot.md.
@freezed
abstract class CartModifierDto with _$CartModifierDto {
  const factory CartModifierDto({
    required String groupId,
    required String optionId,
    required String label,
    required int priceDelta,
  }) = _CartModifierDto;

  factory CartModifierDto.fromJson(Map<String, dynamic> json) =>
      _$CartModifierDtoFromJson(json);
}

@freezed
abstract class CartLineDto with _$CartLineDto {
  const factory CartLineDto({
    required String itemId,
    required String name,
    required String variantId,
    required String variantName,
    String? memberId,
    required List<CartModifierDto> modifiers,
    required String? note,
    required String course,
    required int qty,
    required int unitPrice,
  }) = _CartLineDto;

  factory CartLineDto.fromJson(Map<String, dynamic> json) =>
      _$CartLineDtoFromJson(json);
}

@freezed
abstract class SubmitOrderRequestDto with _$SubmitOrderRequestDto {
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
abstract class SubmitOrderResponseDto with _$SubmitOrderResponseDto {
  const factory SubmitOrderResponseDto({
    required List<String> ticketIds,

    /// The visit the lines were filed under. Lets the sending device seed the
    /// table's currentVisitId immediately, before the tableUpdated echo lands,
    /// so its lines resolve without a flash of empty. See ADR-0034.
    String? visitId,

    /// Lines the server refused for want of ingredients (ADR-0041). Only the
    /// offending lines are dropped — the rest of the order still lands — so
    /// this must be surfaced, or lines vanish silently.
    @Default(<RejectedLineDto>[]) List<RejectedLineDto> rejected,
    @Default(<String>[]) List<String> attributionWarnings,
  }) = _SubmitOrderResponseDto;

  factory SubmitOrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitOrderResponseDtoFromJson(json);
}

@freezed
abstract class RejectedLineDto with _$RejectedLineDto {
  const factory RejectedLineDto({
    required String itemId,
    @Default('') String name,
    @Default('') String variantName,

    /// Names of the bahan that fell short — so the waiter is told *what* ran
    /// out rather than just "no".
    @Default(<String>[]) List<String> ingredients,
  }) = _RejectedLineDto;

  factory RejectedLineDto.fromJson(Map<String, dynamic> json) =>
      _$RejectedLineDtoFromJson(json);
}
