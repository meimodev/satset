/// The petty cash boxes — the venue's named tins of physical cash for small
/// outgoings, kept as one append-only ledger whose balance is `SUM(delta)`.
///
/// **Not the drawer.** The drawer holds sales cash arriving through payments;
/// the box holds a float that only ever pays money out. Nothing links the two.
/// See §Kas kecil in CONTEXT.md, ADR-0088 (it cannot go negative) and ADR-0089
/// (it is not revenue).
///
/// A venue holds **one or more** boxes (ADR-0131). Every movement names the
/// [CashBox] it moved and every balance is derived over that box alone: a tin
/// that cannot pay is refused even while another tin is full, because the notes
/// are in a different drawer in a different room.
///
/// Plain Dart, no Flutter and no codegen: the server writes these rows and the
/// client renders them, so the model sits below both.
library;

/// One named tin (ADR-0131).
///
/// The name is **venue content**, like a zone's or a menu item's — never an ARB
/// key, and never localised. A box is retired by clearing [active], never
/// deleted: a closed month's rows must still be able to name where the money
/// came from.
class CashBox {
  final String id;
  final String name;
  final bool active;
  final int sortOrder;

  /// `SUM(delta)` over this box's rows, computed server-side on every read.
  /// Never summed client-side — a client holds one page of the ledger and
  /// cannot see what it does not hold.
  final int balance;

  const CashBox({
    required this.id,
    required this.name,
    required this.balance,
    this.active = true,
    this.sortOrder = 0,
  });
}

/// Which of the four movements a row is.
///
/// The name is **persisted** in `cash_entries.kind` — never rename one, for the
/// same reason `AuditKind` names are frozen: the string is the join to the ARB
/// template, and a rename orphans every row already written.
enum CashEntryKind {
  /// Money into the box. Positive delta. Gated on `editSettings` — the owner
  /// funds the box.
  topUp,

  /// Money out of the box. Negative delta, names a [CashCategory] and carries an
  /// optional photo of whatever receipt existed. Gated on `manageCash`.
  expense,

  /// Opname kas. The counter enters the **absolute** cash found and the server
  /// writes the difference; the delta on this row *is* the variance. Gated on
  /// `editSettings`.
  count,

  /// A counter-entry against exactly one earlier row, carrying a mandatory
  /// note. Delta is the negation of what it reverses.
  reversal,
}

CashEntryKind? cashEntryKindFromName(String? name) {
  if (name == null) return null;
  for (final k in CashEntryKind.values) {
    if (k.name == name) return k;
  }
  return null;
}

/// One **[[Kategori kas (cash category)]]** — the venue's own word for what
/// money left a box for (ADR-0135).
///
/// **Owned by a box**, which is why [boxId] is here and not inferred: Kas Dapur
/// lists what a kitchen tin buys and the bar tin lists its own. The word is
/// venue content, like a [CashBox]'s name — never an ARB key, never localised,
/// never a code. It replaced a closed enum of five, which survive as seeded
/// rows the venue may rename.
///
/// Retired by clearing [active], never deleted: a removed row would orphan
/// every expense filed under it and the ledger would render an id where a word
/// should be.
class CashCategory {
  final String boxId;
  final String id;
  final String name;
  final bool active;
  final int sortOrder;

  const CashCategory({
    required this.boxId,
    required this.id,
    required this.name,
    this.active = true,
    this.sortOrder = 0,
  });
}

/// One immutable movement of the box.
///
/// Rows are never edited and never deleted — a mistake is corrected by a
/// [CashEntryKind.reversal] naming the row it undoes, at most once per row and
/// with no time limit.
class CashEntry {
  final String id;

  /// The [CashBox] this movement moved (ADR-0131).
  final String boxId;

  final CashEntryKind kind;

  /// Signed rupiah, plain integers — the box is counted in notes, never in
  /// fractions of a rupiah, so there is no `micro` scaling here as there is on
  /// an ingredient's cost. Positive into the box, negative out of it.
  final int delta;

  /// The [CashCategory] this expense was filed under — its **id**, scoped to
  /// this row's [boxId]. Set on an expense, null on every other kind: a
  /// transfer leg bought nothing and a count moved nothing.
  final String? categoryId;

  /// The category's word **as it stands right now**, resolved server-side on
  /// every read rather than snapshotted (ADR-0135). A rename is therefore
  /// retroactive here, while the audit trail keeps what it wrote at the time.
  /// Null when the row carries no category.
  final String? categoryName;

  /// Optional on a top-up, an expense and a count; **required** on a reversal,
  /// which exists to explain something. Enforced server-side.
  final String? note;

  /// The row this one reverses, set only on a [CashEntryKind.reversal]. At most
  /// one reversal may point at any given row.
  final String? reversesId;

  /// The other leg of a transfer between two boxes, if this row is one. A
  /// transfer is an ordinary expense out of one box paired with an ordinary
  /// top-up into another, so nothing that already sums a box needs a new arm —
  /// but the two legs live and die together, and `reverseCash` undoes both.
  final String? transferPeerId;

  /// Set on a row that has been reversed, pointing at the reversal. This is the
  /// one field a row ever gains after the fact, and it is a link rather than an
  /// edit: nothing about what happened is rewritten.
  final String? reversedById;

  /// Absolute cash the counter reported, set only on a [CashEntryKind.count].
  /// Kept alongside [delta] because the variance alone cannot be read back into
  /// what was physically in the box.
  final int? countedAmount;

  /// True when an expense carries a photo. The bytes are never in this model or
  /// in a list payload — they load through the photo route, the same discipline
  /// `Payments.photo` keeps.
  final bool hasPhoto;

  final String? actorUserId;

  /// Attribution as it stood when the movement happened, snapshotted so a later
  /// rename or deletion cannot rewrite the trail.
  final String? actorName;

  final DateTime at;

  const CashEntry({
    required this.id,
    required this.boxId,
    required this.kind,
    required this.delta,
    required this.at,
    this.categoryId,
    this.categoryName,
    this.transferPeerId,
    this.note,
    this.reversesId,
    this.reversedById,
    this.countedAmount,
    this.hasPhoto = false,
    this.actorUserId,
    this.actorName,
  });

  /// A row already undone cannot be undone again, and a reversal is not itself
  /// reversible — that way lies a chain nobody can read.
  bool get canReverse =>
      reversedById == null && kind != CashEntryKind.reversal;
}
