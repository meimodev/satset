import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_dto.freezed.dart';
part 'ticket_dto.g.dart';

@freezed
class TicketDto with _$TicketDto {
  const factory TicketDto({
    required String id,
    required String tableId,
    required String itemId,
    required String name,
    @Default('') String variantName,
    required String course,
    required String station,
    @Default(1) int qty,
    @Default(<String>[]) List<String> modifiers,
    String? specialInstructions,
    required int price,
    required String status,
    required DateTime sentAt,
    String? voidReason,
    String? voidApprovedBy,
    String? createdByUserId,
  }) = _TicketDto;

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);
}

@freezed
class TicketTransitionRequestDto with _$TicketTransitionRequestDto {
  const factory TicketTransitionRequestDto({
    required String status,
    String? voidReason,
  }) = _TicketTransitionRequestDto;

  factory TicketTransitionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TicketTransitionRequestDtoFromJson(json);
}
