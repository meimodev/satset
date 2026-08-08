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
    /// Money-shaped audit rows for the off-site owner (ADR-0086), who has
    /// no route to the venue log. Empty on the admin's own snapshot, which
    /// reads the live log instead.
    @Default(MoneyAuditSectionDto()) MoneyAuditSectionDto moneyAudit,
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
  const factory NamedIdDto({required String id, required String name}) =
      _NamedIdDto;

  factory NamedIdDto.fromJson(Map<String, dynamic> json) =>
      _$NamedIdDtoFromJson(json);
}

@freezed
class KpiTileDto with _$KpiTileDto {
  const factory KpiTileDto({
    /// Stable id for the tile, rendered by `kpiLabel`/`kpiSub` at read time
    /// (ADR-0085). [label] and [sub] survive only as the fallback for a code
    /// this build does not know.
    @Default('') String key,

    /// The caption's counts, in the order its message declares them.
    @Default(<int>[]) List<int> args,
    @Default('') String label,

    /// Money tiles ship the amount, not its rendering — `jt` and `rb` are
    /// Indonesian words and the reader picks its own (`kpiValue`). Tiles that
    /// are not money (a duration, a ratio) keep using [value].
    int? rupiah,
    @Default('') String value,
    @Default('') String sub,
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
    TakeawaySplitDto? takeaway,
  }) = _SalesSectionDto;

  factory SalesSectionDto.fromJson(Map<String, dynamic> json) =>
      _$SalesSectionDtoFromJson(json);
}

/// Dine-in vs takeaway (Bawa pulang) split for the sales section. See ADR-0026.
@freezed
class TakeawaySplitDto with _$TakeawaySplitDto {
  const factory TakeawaySplitDto({
    @Default(0) int count,
    @Default(0) int net,
    @Default(0) int dineInCount,
    @Default(0) int dineInNet,
  }) = _TakeawaySplitDto;

  factory TakeawaySplitDto.fromJson(Map<String, dynamic> json) =>
      _$TakeawaySplitDtoFromJson(json);
}

@freezed
class CoverDayDto with _$CoverDayDto {
  const factory CoverDayDto({
    /// ISO weekday, 1 = Monday. Spelled by [formatWeekdayShort] at read time.
    @Default(1) int dow,
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

/// Speed-of-service rollup (ADR-0013, amended by ADR-0043). Prep time =
/// kitchen clock (`firedAt ?? sentAt`) → ready; pickup lag = ready→served.
/// Medians, since service times are right-skewed.
///
/// [slaPct] is now **% of courses** that hit their own resolved target, not %
/// of lines against one venue number. Every field carries a default so a
/// snapshot published by an older host (ADR-0036 — host and owner can be on
/// different builds) still parses instead of blanking the section.
@freezed
class SpeedSectionDto with _$SpeedSectionDto {
  const factory SpeedSectionDto({
    @Default(0) int prepMedianMin,
    @Default(0) int pickupMedianMin,
    @Default(0.0) double slaPct,

    /// The venue *default* target — no longer the only target in play.
    @Default(15) int prepTargetMins,
    @Default(0) int sampleSize,
    @Default(<SpeedItemDto>[]) List<SpeedItemDto> slowItems,
    // ADR-0044 additions.
    @Default(4) int pickupTargetMins,
    @Default(0.0) double pickupSlaPct,
    @Default(0) int courseSampleSize,
    @Default(0) int greetMedianMin,
    @Default(0.0) double greetBreachPct,
    @Default(7) int ungreetedMins,
    @Default(0) int greetSampleSize,
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
    // The station code only — its words come from `stationLabel` at read time
    // (ADR-0085). The server stopped sending a `label` and this stayed
    // required, which failed the whole snapshot's parse.
    required String station,
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
    @Default('') String label,
    @Default(0) int count,
    @Default(0) int lostRupiah,
  }) = _VoidReasonDto;

  factory VoidReasonDto.fromJson(Map<String, dynamic> json) =>
      _$VoidReasonDtoFromJson(json);
}

/// The money half of the venue log, published to the cloud for the off-site
/// owner (ADR-0086).
///
/// Rows only — no proof-photo bytes. Blobs stay on the LAN (ADR-0036 §"No proof
/// photos off-site"); an owner who sees a figure they dislike names the row for
/// the on-site admin to open.
@freezed
class MoneyAuditSectionDto with _$MoneyAuditSectionDto {
  const factory MoneyAuditSectionDto({
    @Default(<MoneyAuditRowDto>[]) List<MoneyAuditRowDto> rows,

    /// True when the range held more rows than were published. The snapshot is
    /// a Firestore document with a hard ceiling, so the cap is real and the
    /// owner is told rather than shown a quietly short list.
    @Default(false) bool truncated,
  }) = _MoneyAuditSectionDto;

  factory MoneyAuditSectionDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyAuditSectionDtoFromJson(json);
}

/// One published audit row. Mirrors the venue log's own wire shape, structured
/// half included, so the owner composes the sentence in **their** language
/// (ADR-0085) rather than reading the venue device's frozen [title].
///
/// No `paymentId`: the photo it would name is unreachable from off-site, and
/// an indicator that cannot be tapped is worse than none.
@freezed
class MoneyAuditRowDto with _$MoneyAuditRowDto {
  const factory MoneyAuditRowDto({
    required String id,
    required String type,
    @Default('') String at,
    @Default('') String title,
    String? kind,
    @Default(<String, String>{}) Map<String, String> params,
    String? actorName,
    String? tableLabel,
    int? amountCents,
  }) = _MoneyAuditRowDto;

  factory MoneyAuditRowDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyAuditRowDtoFromJson(json);
}

@freezed
class StaffVoidDto with _$StaffVoidDto {
  const factory StaffVoidDto({
    required String id,
    required String name,
    @Default(0) int count,
    @Default(0) int lostRupiah,
    @Default('other') String topReasonCode,
  }) = _StaffVoidDto;

  factory StaffVoidDto.fromJson(Map<String, dynamic> json) =>
      _$StaffVoidDtoFromJson(json);
}
