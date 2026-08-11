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

    /// The petty cash box over the same window (§Kas kecil). Its own section
    /// because none of it is revenue (ADR-0089) — no figure here appears in
    /// [sales], and no figure in [sales] is net of it.
    @Default(KasSectionDto()) KasSectionDto kas,

    /// [[Keanggotaan (membership)]] over the same window. Its own section for
    /// the mirror-image reason [kas] is: points are a claim on future takings,
    /// not a channel — folding a give-away into [sales] would let it read as
    /// revenue (ADR-0095).
    @Default(MembersSectionDto()) MembersSectionDto members,

    /// [[Piutang]] over the same window (ADR-0098). Its own section again: a
    /// collection is not revenue — the sale was booked the night it was eaten —
    /// so nothing here may be added to [sales]. The exception runs the other
    /// way: [PiutangSectionDto.writtenOff] is republished as
    /// [SalesSectionDto.badDebt], because a loss belongs beside what it was
    /// lost against.
    @Default(PiutangSectionDto()) PiutangSectionDto piutang,

    /// Attendance over the same window. Deliberately not part of [staff]: that
    /// section is what someone sold, this one is whether they were here, and a
    /// slow Tuesday must not read as a slack one.
    @Default(JamKerjaSectionDto()) JamKerjaSectionDto jamKerja,
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

    /// [[Piutang]] given up on in this window — the one figure that crosses in
    /// from [ReportsSnapshotDto.piutang] (ADR-0098). A tab written off weeks
    /// after close is a real loss against revenue already booked, so it is
    /// shown here rather than left in its own section where an owner reading
    /// [kpis] would never meet it. Read-only: no KPI is net of it.
    @Default(0) int badDebt,
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
/// The petty cash box over a report window.
///
/// [opening] + [inflow] − [outflow] + [variance] = [closing]. The variance term
/// is what a count found that the ledger did not know: it moves the closing
/// balance without being money in or out, and keeping it separate is the only
/// way a shortfall reads as a shortfall rather than as a purchase.
///
/// [byCategory] is keyed by `CashCategory.name` — a code, not a word, resolved
/// at read time (ADR-0085).
@freezed
class KasSectionDto with _$KasSectionDto {
  const factory KasSectionDto({
    @Default(0) int opening,
    @Default(0) int inflow,
    @Default(0) int outflow,
    @Default(0) int variance,
    @Default(0) int closing,
    @Default(<String, int>{}) Map<String, int> byCategory,

    /// Movements in the window. Zero is what the empty line keys off — a box
    /// with a balance and no movements is still nothing to report on.
    @Default(0) int count,
  }) = _KasSectionDto;

  factory KasSectionDto.fromJson(Map<String, dynamic> json) =>
      _$KasSectionDtoFromJson(json);
}

/// The Jam kerja (attendance) block — [[Shift]] hours per staff member.
///
/// Hours come only from shifts somebody signed out of. A shift the business-day
/// rollover had to retire contributes to [JamKerjaRowDto.unclosed] and nothing
/// else, because its length is an artefact of the boundary rather than a
/// measurement (ADR-0097).
@freezed
class JamKerjaSectionDto with _$JamKerjaSectionDto {
  const factory JamKerjaSectionDto({
    @Default(<JamKerjaRowDto>[]) List<JamKerjaRowDto> staff,

    /// The venue's rollover hour, so the screen can turn [
    /// JamKerjaRowDto.medianFirstIn] back into a clock time.
    @Default(4) int dayStartHour,

    /// Shifts nobody signed out of, across everyone. The section's headline
    /// caveat: a venue with a high number here is not reading real hours.
    @Default(0) int unclosed,
  }) = _JamKerjaSectionDto;

  factory JamKerjaSectionDto.fromJson(Map<String, dynamic> json) =>
      _$JamKerjaSectionDtoFromJson(json);
}

/// One staff member's attendance over the window.
@freezed
class JamKerjaRowDto with _$JamKerjaRowDto {
  const factory JamKerjaRowDto({
    required String id,
    required String name,

    /// Minutes actually worked — closed shifts only.
    @Default(0) int minutes,
    @Default(0) int shifts,

    /// Distinct business days with at least one shift. Lower than [shifts]
    /// whenever a day was split by a handover.
    @Default(0) int days,
    @Default(0) int unclosed,

    /// Median minutes **after the venue's rollover** that this person clocked
    /// in — not a wall clock, so it compares across venues with different
    /// business-day starts. Null when they never clocked in.
    int? medianFirstIn,

    /// The last thing an unclosed shift of theirs actually did. The honest
    /// answer to "when did they really stop"; null when nothing they did in it
    /// was auditable.
    String? lastSeen,
  }) = _JamKerjaRowDto;

  factory JamKerjaRowDto.fromJson(Map<String, dynamic> json) =>
      _$JamKerjaRowDtoFromJson(json);
}

/// The [[Keanggotaan (membership)]] block.
///
/// The comparison is the point: [avgMemberBill] against [avgGuestBill] is the
/// only figure that says whether the program is worth running. [pointsEarned]
/// and [pointsRedeemed] are the window's flow; [pointsOutstanding] is the whole
/// standing liability, because points never expire (ADR-0095) — a window's view
/// of what the venue owes would always understate it.
@freezed
class MembersSectionDto with _$MembersSectionDto {
  const factory MembersSectionDto({
    /// False ⇒ the venue does not run a program, and the section is not drawn.
    @Default(false) bool enabled,

    /// The points program runs (or not) independently of membership. False ⇒
    /// the points figures and the ranked list's points column are **hidden**,
    /// not zeroed — a zero says "earned nothing", which is a different and
    /// false statement from "this venue does not run points".
    @Default(false) bool pointsEnabled,
    @Default(0) int enrolled,
    @Default(0) int activeMembers,
    @Default(0) int memberBills,
    @Default(0) int memberNet,
    @Default(0) int guestBills,
    @Default(0) int guestNet,
    @Default(0) int avgMemberBill,
    @Default(0) int avgGuestBill,
    @Default(0) int pointsEarned,
    @Default(0) int pointsRedeemed,
    @Default(0) int pointsAdjusted,
    @Default(0) int pointsOutstanding,

    /// Rupiah the outstanding points would cost at today's rate. An estimate by
    /// construction — the rate can move before they are spent.
    @Default(0) int liabilityEstimate,
    @Default(<MemberTopRowDto>[]) List<MemberTopRowDto> top,

    /// Members who traded in the window beyond the end of [top]. Shown as a
    /// tail count, so the hundredth name never reads as the last one.
    @Default(0) int topTruncated,
  }) = _MembersSectionDto;

  factory MembersSectionDto.fromJson(Map<String, dynamic> json) =>
      _$MembersSectionDtoFromJson(json);
}

/// The [[Piutang]] block — what the venue is owed, and what moved (ADR-0098).
///
/// [opening] and [closing] are **venue-wide outstanding**, not window sums: a
/// receivable does not reset at midnight the way takings do.
/// `opening + charged − collected − writtenOff − adjusted = closing`.
///
/// [byMethod] is keyed by payment-method code, resolved at read time (ADR-0085).
@freezed
class PiutangSectionDto with _$PiutangSectionDto {
  const factory PiutangSectionDto({
    /// False ⇒ the venue runs no tabs, and the section is not drawn.
    @Default(false) bool enabled,
    @Default(0) int opening,
    @Default(0) int charged,
    @Default(0) int collected,
    @Default(0) int writtenOff,

    /// Signed: which way a hand correction went is the finding.
    @Default(0) int adjusted,
    @Default(0) int closing,
    @Default(<String, int>{}) Map<String, int> byMethod,

    /// The venue's credit policy, not a fact — what counts as late is a setting.
    @Default(30) int overdueDays,
    @Default(0) int overdueTotal,
    @Default(0) int debtorCount,
    @Default(<DebtorRowDto>[]) List<DebtorRowDto> debtors,

    /// True when [debtors] is a capped page and the full list lives on
    /// `/members`. A report is read on a tablet; a hundred-row table is not.
    @Default(false) bool debtorsTruncated,
  }) = _PiutangSectionDto;

  factory PiutangSectionDto.fromJson(Map<String, dynamic> json) =>
      _$PiutangSectionDtoFromJson(json);
}

/// One member who owes. [oldestUnpaidAt] is derived FIFO at read time — there
/// is no due-date column and no invoice allocation (ADR-0098).
@freezed
class DebtorRowDto with _$DebtorRowDto {
  const factory DebtorRowDto({
    @Default('') String memberId,
    @Default('') String name,
    @Default('') String phone,
    @Default(0) int balance,
    DateTime? oldestUnpaidAt,
    DateTime? lastPaymentAt,
  }) = _DebtorRowDto;

  factory DebtorRowDto.fromJson(Map<String, dynamic> json) =>
      _$DebtorRowDtoFromJson(json);
}

/// One member on the window's spend leaderboard. [name] is null when the member
/// has since been deleted — the trade stands, the person does not (ADR-0092).
@freezed
class MemberTopRowDto with _$MemberTopRowDto {
  const factory MemberTopRowDto({
    @Default('') String memberId,
    String? name,
    @Default(0) int visits,
    @Default(0) int spend,

    /// Points earned in the window. Hidden by the section when the points
    /// program is off; see [MembersSectionDto.pointsEnabled].
    @Default(0) int points,
  }) = _MemberTopRowDto;

  const MemberTopRowDto._();

  /// What one visit was worth on average. Derived, never sent — the two figures
  /// it divides are already on the wire.
  int get avgSpend => visits == 0 ? 0 : spend ~/ visits;

  factory MemberTopRowDto.fromJson(Map<String, dynamic> json) =>
      _$MemberTopRowDtoFromJson(json);
}

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
