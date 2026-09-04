/// A **[[Pengeluaran kunjungan]]** — cash a [[Waiter|pelayan]] spent on a party
/// while serving it, out of the money that [[Visit|kunjungan]] is producing
/// (ADR-0130).
///
/// **Not [[Kas kecil (petty cash)]].** The box is a standing venue float that
/// only ever leaves the venue and is deliberately not revenue (ADR-0089); this
/// is money out of one visit's own takings and *is* revenue-affecting. Nothing
/// here moves a box balance and no top-up funds it.
///
/// Plain Dart, no Flutter and no codegen — the server writes these rows and the
/// client renders them, so the model sits below both, exactly as `CashEntry`
/// does.
library;

/// One immutable outgoing against a visit.
///
/// Rows are **never edited and never deleted**. That is not "not yet": the cash
/// already left, so there is nothing to correct, and a reversal here would be a
/// second way to say a thing that did not happen.
class VisitExpense {
  /// Client-minted, and doubles as the idempotency key.
  final String id;
  final String visitId;

  /// The category **id**. Its word is venue-authored and lives on the category
  /// row, so a renamed category renames its history — which is the point of a
  /// venue's own vocabulary.
  final String categoryId;

  /// The category's name as it reads right now. Denormalised on read only,
  /// never stored on the expense.
  final String categoryName;

  /// Positive. This ledger only ever pays out.
  final int amount;
  final String note;

  /// A photo is mandatory (ADR-0130), so this is always true on a row the
  /// writer produced. It stays a flag rather than bytes for `cashEntryJson`'s
  /// reason: a list of expenses must not carry a list of images.
  final bool hasPhoto;

  final String? actorUserId;
  final String? actorName;
  final DateTime at;

  const VisitExpense({
    required this.id,
    required this.visitId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.at,
    this.note = '',
    this.hasPhoto = true,
    this.actorUserId,
    this.actorName,
  });
}

/// The venue's own word for what an expense was for.
///
/// Venue-authored, unlike `CashCategory`'s closed set, and **soft-deleted
/// only** — [active] hides it from the picker while every row filed under it
/// keeps rendering its name.
class VisitExpenseCategory {
  final String id;
  final String name;
  final bool active;
  final int sortOrder;

  const VisitExpenseCategory({
    required this.id,
    required this.name,
    this.active = true,
    this.sortOrder = 0,
  });
}
