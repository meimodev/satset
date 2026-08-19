/// [[Pesan mandiri]] wire DTOs (ADR-0105).
///
/// `status` and `rejectReasonCode` are **codes, never sentences** (ADR-0085) —
/// the words are composed at read time in `lib/core/localization/`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'self_order_dto.freezed.dart';
part 'self_order_dto.g.dart';

/// One chosen option on a guest line. The wire carries `groupId`, `optionId`
/// and `priceDelta` too; the queue card reads the label and nothing else, and
/// unlisted keys are dropped rather than modelled for a caller that has none.
@freezed
abstract class GuestLineModDto with _$GuestLineModDto {
  const factory GuestLineModDto({@Default('') String label}) = _GuestLineModDto;

  factory GuestLineModDto.fromJson(Map<String, dynamic> json) =>
      _$GuestLineModDtoFromJson(json);
}

@freezed
abstract class GuestOrderLineDto with _$GuestOrderLineDto {
  const factory GuestOrderLineDto({
    required String id,
    required String itemId,
    required String name,
    @Default('') String variantName,
    @Default(1) int qty,
    String? note,
    @Default(0) int unitPrice,
    @Default([]) List<GuestLineModDto> modifiers,
  }) = _GuestOrderLineDto;

  factory GuestOrderLineDto.fromJson(Map<String, dynamic> json) =>
      _$GuestOrderLineDtoFromJson(json);
}

@freezed
abstract class GuestOrderDto with _$GuestOrderDto {
  const factory GuestOrderDto({
    required String id,
    required String tableId,
    String? tableLabel,
    @Default('pending') String status,
    required DateTime submittedAt,
    DateTime? decidedAt,
    String? rejectReasonCode,
    /// Who accepted or rejected it. Staff-only — the guest page is told what
    /// happened, never by whom.
    String? decidedBy,
    @Default(0) int subtotal,
    @Default([]) List<GuestOrderLineDto> lines,
  }) = _GuestOrderDto;

  factory GuestOrderDto.fromJson(Map<String, dynamic> json) =>
      _$GuestOrderDtoFromJson(json);
}

/// One table's [[Kode meja]] and its per-table opt-in.
@freezed
abstract class GuestTableDto with _$GuestTableDto {
  const factory GuestTableDto({
    required String id,
    String? label,
    @Default('') String zoneId,
    @Default('') String zoneName,
    @Default(0) int seats,
    @Default('') String code,
    @Default(true) bool enabled,
  }) = _GuestTableDto;

  factory GuestTableDto.fromJson(Map<String, dynamic> json) =>
      _$GuestTableDtoFromJson(json);
}

/// One row of the [[Menu tamu]] tab: what the guest page shows, resolved the
/// same way the guest page resolves it.
@freezed
abstract class GuestMenuItemDto with _$GuestMenuItemDto {
  const factory GuestMenuItemDto({
    required String id,
    required String name,
    @Default('') String categoryId,
    @Default('') String description,
    @Default(0) int basePrice,
    @Default(false) bool featured,
    @Default(true) bool visible,
    @Default(false) bool soldOut,
    @Default(false) bool alcohol,

    /// `auto` | `forceIn` | `forceOut`, already expired server-side — a force
    /// that outlived its business day arrives as `auto`.
    @Default('auto') String stockOverride,
  }) = _GuestMenuItemDto;

  factory GuestMenuItemDto.fromJson(Map<String, dynamic> json) =>
      _$GuestMenuItemDtoFromJson(json);
}

/// The hero numbers, for the current business day. Derived server-side on
/// read — nothing stores a self-order total.
@freezed
abstract class GuestStatsDto with _$GuestStatsDto {
  const factory GuestStatsDto({
    @Default(0) int total,
    @Default(0) int pending,
    @Default(0) int accepted,
    @Default(0) int rejected,
    @Default(0) int value,
    @Default(0) int medianWaitSecs,
  }) = _GuestStatsDto;

  factory GuestStatsDto.fromJson(Map<String, dynamic> json) =>
      _$GuestStatsDtoFromJson(json);
}
