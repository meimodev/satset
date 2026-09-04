import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit_expense_dto.freezed.dart';
part 'visit_expense_dto.g.dart';

/// One **[[Pengeluaran kunjungan]]** as it reaches the floor (ADR-0130).
///
/// The photo is a flag, never bytes: a visit's list must stay a few KB no
/// matter how many receipts were shot, and the image is reached by its own
/// route.
@freezed
abstract class VisitExpenseDto with _$VisitExpenseDto {
  const factory VisitExpenseDto({
    required String id,
    @Default('') String visitId,
    @Default('') String categoryId,

    /// The venue's own word, resolved server-side. Venue-authored content, so
    /// it is ARB-exempt — like a menu item's name.
    @Default('') String categoryName,
    @Default(0) int amount,
    @Default('') String note,
    @Default(true) bool hasPhoto,
    String? actorUserId,
    String? actorName,
    DateTime? at,
  }) = _VisitExpenseDto;

  factory VisitExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$VisitExpenseDtoFromJson(json);
}

/// The venue's vocabulary for what an expense was for.
///
/// Venue-authored, unlike the petty cash box's closed `CashCategory` set, and
/// **soft-deleted only** — an inactive one is hidden from the picker while
/// every row filed under it keeps rendering its name.
@freezed
abstract class VisitExpenseCategoryDto with _$VisitExpenseCategoryDto {
  const factory VisitExpenseCategoryDto({
    required String id,
    @Default('') String name,
    @Default(true) bool active,
    @Default(0) int sortOrder,
  }) = _VisitExpenseCategoryDto;

  factory VisitExpenseCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$VisitExpenseCategoryDtoFromJson(json);
}

/// What a visit has cost so far, and how much room is left under the cap.
///
/// The two numbers travel together because they are only meaningful together:
/// a sheet that knows the spend but not the cap cannot say what is left, and
/// that sentence is the whole point of showing either.
@freezed
abstract class VisitExpenseSummaryDto with _$VisitExpenseSummaryDto {
  const factory VisitExpenseSummaryDto({
    @Default(<VisitExpenseDto>[]) List<VisitExpenseDto> expenses,
    @Default(0) int total,

    /// The visit's subtotal of sent, non-voided lines — pre-tax, pre-discount.
    @Default(0) int cap,

    /// True when this was assembled on the device rather than answered by the
    /// host — the cap came from the cached bill and [total] counts only what
    /// this handset has queued (ADR-0130).
    ///
    /// It is **advisory**: an expense another device already synced is not in
    /// it, so the number can read generously. The server re-checks the cap
    /// inside its transaction at drain, which is where the guard actually
    /// lives; this flag exists so the sheet can say the figure is provisional
    /// rather than quietly implying it is not.
    @Default(false) bool offline,
  }) = _VisitExpenseSummaryDto;

  factory VisitExpenseSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VisitExpenseSummaryDtoFromJson(json);
}

extension VisitExpenseRoom on VisitExpenseSummaryDto {
  /// What may still be spent against this visit. Never negative: a bill that
  /// shrank after the fact leaves the expenses standing (ADR-0130), so the room
  /// simply reads zero rather than going backwards.
  int get remaining => (cap - total).clamp(0, cap);
}
