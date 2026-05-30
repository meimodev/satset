import 'package:freezed_annotation/freezed_annotation.dart';

part 'reports_dto.freezed.dart';
part 'reports_dto.g.dart';

@freezed
class ReportsSnapshotDto with _$ReportsSnapshotDto {
  const factory ReportsSnapshotDto({
    required String generatedAt,
    required String rangeFrom,
    required String rangeTo,
    required String range,
    required FilterOptionsDto filterOptions,
    required SalesSectionDto sales,
    required StaffSectionDto staff,
    required MenuSectionDto menu,
    required OpsSectionDto ops,
  }) = _ReportsSnapshotDto;

  factory ReportsSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$ReportsSnapshotDtoFromJson(json);
}

@freezed
class FilterOptionsDto with _$FilterOptionsDto {
  const factory FilterOptionsDto({
    @Default(<NamedIdDto>[]) List<NamedIdDto> servers,
    @Default(<NamedIdDto>[]) List<NamedIdDto> zones,
    @Default(<NamedIdDto>[]) List<NamedIdDto> categories,
  }) = _FilterOptionsDto;

  factory FilterOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$FilterOptionsDtoFromJson(json);
}

@freezed
class NamedIdDto with _$NamedIdDto {
  const factory NamedIdDto({
    required String id,
    required String name,
  }) = _NamedIdDto;

  factory NamedIdDto.fromJson(Map<String, dynamic> json) =>
      _$NamedIdDtoFromJson(json);
}

@freezed
class KpiTileDto with _$KpiTileDto {
  const factory KpiTileDto({
    required String label,
    required String value,
    required String sub,
  }) = _KpiTileDto;

  factory KpiTileDto.fromJson(Map<String, dynamic> json) =>
      _$KpiTileDtoFromJson(json);
}

@freezed
class SalesSectionDto with _$SalesSectionDto {
  const factory SalesSectionDto({
    @Default(<KpiTileDto>[]) List<KpiTileDto> kpis,
    @Default(<CoverDayDto>[]) List<CoverDayDto> coverTrend,
    @Default(<double>[]) List<double> hourly,
  }) = _SalesSectionDto;

  factory SalesSectionDto.fromJson(Map<String, dynamic> json) =>
      _$SalesSectionDtoFromJson(json);
}

@freezed
class CoverDayDto with _$CoverDayDto {
  const factory CoverDayDto({
    required String day,
    required int thisWeek,
    required int lastWeek,
  }) = _CoverDayDto;

  factory CoverDayDto.fromJson(Map<String, dynamic> json) =>
      _$CoverDayDtoFromJson(json);
}

@freezed
class StaffSectionDto with _$StaffSectionDto {
  const factory StaffSectionDto({
    @Default(<StaffRowDto>[]) List<StaffRowDto> rows,
    @Default(<StaffUpsellDto>[]) List<StaffUpsellDto> upsell,
  }) = _StaffSectionDto;

  factory StaffSectionDto.fromJson(Map<String, dynamic> json) =>
      _$StaffSectionDtoFromJson(json);
}

@freezed
class StaffRowDto with _$StaffRowDto {
  const factory StaffRowDto({
    required String id,
    required String name,
    @Default(0) int covers,
    @Default(0) int items,
    @Default(0) int avgTicket,
    @Default(0.0) double voidPct,
    @Default(0) int net,
    @Default(0) int sessions,
  }) = _StaffRowDto;

  factory StaffRowDto.fromJson(Map<String, dynamic> json) =>
      _$StaffRowDtoFromJson(json);
}

@freezed
class StaffUpsellDto with _$StaffUpsellDto {
  const factory StaffUpsellDto({
    required String id,
    required String name,
    @Default(0.0) double rate,
  }) = _StaffUpsellDto;

  factory StaffUpsellDto.fromJson(Map<String, dynamic> json) =>
      _$StaffUpsellDtoFromJson(json);
}

@freezed
class MenuSectionDto with _$MenuSectionDto {
  const factory MenuSectionDto({
    @Default(<MenuItemRowDto>[]) List<MenuItemRowDto> top,
    @Default(<MenuItemRowDto>[]) List<MenuItemRowDto> slow,
    @Default(<ModifierAttachDto>[]) List<ModifierAttachDto> modifierAttach,
    @Default(<CategoryShareDto>[]) List<CategoryShareDto> categoryMix,
    @Default(<MatrixItemDto>[]) List<MatrixItemDto> matrix,
    @Default(<BasketPairDto>[]) List<BasketPairDto> basketPairs,
  }) = _MenuSectionDto;

  factory MenuSectionDto.fromJson(Map<String, dynamic> json) =>
      _$MenuSectionDtoFromJson(json);
}

@freezed
class MenuItemRowDto with _$MenuItemRowDto {
  const factory MenuItemRowDto({
    required String itemId,
    required String name,
    @Default(0) int qty,
    @Default(0) int revenue,
    @Default(0) int marginPct,
    @Default(0.0) double fill,
  }) = _MenuItemRowDto;

  factory MenuItemRowDto.fromJson(Map<String, dynamic> json) =>
      _$MenuItemRowDtoFromJson(json);
}

@freezed
class ModifierAttachDto with _$ModifierAttachDto {
  const factory ModifierAttachDto({
    required String group,
    @Default(0.0) double rate,
  }) = _ModifierAttachDto;

  factory ModifierAttachDto.fromJson(Map<String, dynamic> json) =>
      _$ModifierAttachDtoFromJson(json);
}

@freezed
class CategoryShareDto with _$CategoryShareDto {
  const factory CategoryShareDto({
    required String id,
    required String name,
    @Default(0.0) double shareThisWeek,
    @Default(0.0) double shareLastWeek,
  }) = _CategoryShareDto;

  factory CategoryShareDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryShareDtoFromJson(json);
}

@freezed
class MatrixItemDto with _$MatrixItemDto {
  const factory MatrixItemDto({
    required String itemId,
    required String name,
    @Default(0.0) double popularity,
    @Default(0.0) double margin,
    required String quadrant,
  }) = _MatrixItemDto;

  factory MatrixItemDto.fromJson(Map<String, dynamic> json) =>
      _$MatrixItemDtoFromJson(json);
}

@freezed
class BasketPairDto with _$BasketPairDto {
  const factory BasketPairDto({
    required String itemA,
    required String itemB,
    @Default(0) int count,
    @Default(0.0) double rate,
  }) = _BasketPairDto;

  factory BasketPairDto.fromJson(Map<String, dynamic> json) =>
      _$BasketPairDtoFromJson(json);
}

@freezed
class OpsSectionDto with _$OpsSectionDto {
  const factory OpsSectionDto({
    @Default(<KpiTileDto>[]) List<KpiTileDto> kpis,
    @Default(SpeedSectionDto()) SpeedSectionDto speed,
    @Default(<StationRowDto>[]) List<StationRowDto> stations,
    @Default(<List<double>>[]) List<List<double>> heatmap,
    required ReservationStatsDto reservations,
    @Default(<VoidReasonDto>[]) List<VoidReasonDto> voidReasons,
    @Default(<StaffVoidDto>[]) List<StaffVoidDto> voidByStaff,
  }) = _OpsSectionDto;

  factory OpsSectionDto.fromJson(Map<String, dynamic> json) =>
      _$OpsSectionDtoFromJson(json);
}

/// Speed-of-service rollup (ADR-0013). Prep time = sent→ready (kitchen),
/// pickup lag = ready→served (food at the pass). Medians, since service
/// times are right-skewed.
@freezed
class SpeedSectionDto with _$SpeedSectionDto {
  const factory SpeedSectionDto({
    @Default(0) int prepMedianMin,
    @Default(0) int pickupMedianMin,
    @Default(0.0) double slaPct,
    @Default(15) int prepTargetMins,
    @Default(0) int sampleSize,
    @Default(<SpeedItemDto>[]) List<SpeedItemDto> slowItems,
  }) = _SpeedSectionDto;

  factory SpeedSectionDto.fromJson(Map<String, dynamic> json) =>
      _$SpeedSectionDtoFromJson(json);
}

@freezed
class SpeedItemDto with _$SpeedItemDto {
  const factory SpeedItemDto({
    @Default('') String itemId,
    @Default('') String name,
    @Default(0.0) double avgPrepMin,
    @Default(0) int count,
  }) = _SpeedItemDto;

  factory SpeedItemDto.fromJson(Map<String, dynamic> json) =>
      _$SpeedItemDtoFromJson(json);
}

@freezed
class StationRowDto with _$StationRowDto {
  const factory StationRowDto({
    required String station,
    required String label,
    @Default(0) int qty,
    @Default(0.0) double utilization,
  }) = _StationRowDto;

  factory StationRowDto.fromJson(Map<String, dynamic> json) =>
      _$StationRowDtoFromJson(json);
}

@freezed
class ReservationStatsDto with _$ReservationStatsDto {
  const factory ReservationStatsDto({
    @Default(0) int booked,
    @Default(0) int seated,
    @Default(0) int noShow,
    @Default(0) int cancelled,
  }) = _ReservationStatsDto;

  factory ReservationStatsDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationStatsDtoFromJson(json);
}

@freezed
class VoidReasonDto with _$VoidReasonDto {
  const factory VoidReasonDto({
    required String code,
    required String label,
    @Default(0) int count,
    @Default(0) int lostRupiah,
  }) = _VoidReasonDto;

  factory VoidReasonDto.fromJson(Map<String, dynamic> json) =>
      _$VoidReasonDtoFromJson(json);
}

@freezed
class StaffVoidDto with _$StaffVoidDto {
  const factory StaffVoidDto({
    required String id,
    required String name,
    @Default(0) int count,
    @Default(0) int lostRupiah,
    @Default('other') String topReasonCode,
    @Default('Lainnya') String topReasonLabel,
  }) = _StaffVoidDto;

  factory StaffVoidDto.fromJson(Map<String, dynamic> json) =>
      _$StaffVoidDtoFromJson(json);
}
