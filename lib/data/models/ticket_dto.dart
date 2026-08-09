import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_dto.freezed.dart';
part 'ticket_dto.g.dart';

/// Wire shape of one snapshotted add-on on a sent line. See
/// docs/adr/0011-ticket-modifier-snapshot.md.
@freezed
class TicketModifierDto with _$TicketModifierDto {
  const factory TicketModifierDto({
    @Default('') String groupId,
    @Default('') String optionId,
    @Default('') String label,
    @Default(0) int priceDelta,
  }) = _TicketModifierDto;

  factory TicketModifierDto.fromJson(Map<String, dynamic> json) =>
      _$TicketModifierDtoFromJson(json);
}

@freezed
class TicketDto with _$TicketDto {
  const factory TicketDto({
    required String id,
    required String tableId,

    /// Stable bill key (ADR-0024). Lets the KDS/board label table-less
    /// (takeaway) lines via the visit. Nullable for pre-v29 rows.
    String? visitId,
    required String itemId,
    required String name,
    @Default('') String variantName,
    required String course,
    @Default(1) int qty,
    @Default(<TicketModifierDto>[]) List<TicketModifierDto> modifiers,
    String? note,
    required int price,
    required String status,
    required DateTime sentAt,

    /// When the waiter keyed the line, when that is not when the host received
    /// it. Null on every ordinary send; non-null only for a line delivered off
    /// a terputus handset's queue. Never age a line from this — `sentAt` is
    /// what the kitchen's clocks mean. See ADR-0090.
    DateTime? capturedAt,

    /// Who delivered a backlog someone else captured. ADR-0090.
    String? replayedByUserId,

    /// Stamped on the `held → sent` fire. Null on a normal send. ADR-0043.
    DateTime? firedAt,
    DateTime? readyAt,
    DateTime? servedAt,
    String? voidReason,
    String? voidReasonCode,
    String? voidApprovedBy,
    String? createdByUserId,
    String? voidedByUserId,
  }) = _TicketDto;

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);
}

@freezed
class TicketTransitionRequestDto with _$TicketTransitionRequestDto {
  const factory TicketTransitionRequestDto({
    required String status,
    String? voidReason,
    String? voidReasonCode,
  }) = _TicketTransitionRequestDto;

  factory TicketTransitionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TicketTransitionRequestDtoFromJson(json);
}
