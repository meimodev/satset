import 'package:freezed_annotation/freezed_annotation.dart';

part 'discount_dto.freezed.dart';
part 'discount_dto.g.dart';

/// A [[Preset diskon]] — the owner-defined discount a [[Cashier]] picks from.
/// Cashiers never type a rate (ADR-0037).
@freezed
abstract class DiscountPresetDto with _$DiscountPresetDto {
  const factory DiscountPresetDto({
    required String id,
    @Default('') String name,

    /// `order` (whole receipt) | `line` (one bill line). The picker only offers
    /// presets valid for what the cashier tapped — this is what stops a fixed
    /// whole-bill amount landing on a single cheap line.
    @Default('order') String scope,

    /// `percent` (value in basis points) | `fixed` (value in rupiah).
    @Default('percent') String kind,
    @Default(0) int value,
    @Default(true) bool active,
    @Default(0) int sortOrder,
  }) = _DiscountPresetDto;

  factory DiscountPresetDto.fromJson(Map<String, dynamic> json) =>
      _$DiscountPresetDtoFromJson(json);
}

/// An applied discount on a receipt, as carried on the bill payload.
/// `ticketId == null` ⇒ whole-order discount; set ⇒ a line discount.
///
/// `name`/`kind`/`value` are the values snapshotted at apply time, NOT read
/// live from the preset — render and report from these so a later preset edit
/// never rewrites what a settled bill said (ADR-0037).
@freezed
abstract class AppliedDiscountDto with _$AppliedDiscountDto {
  const factory AppliedDiscountDto({
    required String id,
    String? ticketId,
    String? presetId,
    @Default('') String name,
    @Default('percent') String kind,
    @Default(0) int value,
    @Default(0) int amount,
    String? byUserId,
    String? approvedByUserId,
  }) = _AppliedDiscountDto;

  factory AppliedDiscountDto.fromJson(Map<String, dynamic> json) =>
      _$AppliedDiscountDtoFromJson(json);
}

extension DiscountPresetLabel on DiscountPresetDto {
  /// "Member 10%" / "Potongan 25rb" — the label printed on the money doc and
  /// shown in the picker.
  bool get isPercent => kind == 'percent';
  bool get isLineScope => scope == 'line';
}
