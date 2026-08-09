/// A [[Pelanggan (member)]] — a person the venue recognises across visits, and
/// the [[Poin]] ledger hanging off them.
///
/// **The phone number is the identity** (ADR-0092). There is no anonymous
/// member: a guest who will not give a number simply is not one.
///
/// Plain Dart, no Flutter and no codegen: the server writes these rows and the
/// client renders them, so the model sits below both — the same shape
/// `cash_entry.dart` keeps.
library;

/// Which movement a [[Poin]] row is.
///
/// The name is **persisted** in `member_points.kind` — never rename one, for
/// the same reason `CashEntryKind` names are frozen: the string is the join to
/// the ARB template, and a rename orphans every row already written.
enum MemberPointKind {
  /// Earned at bill close, once per visit (ADR-0095). Positive.
  earn,

  /// Spent as money off a live bill. Negative.
  redeem,

  /// A hand correction under `manageMembers`, carrying a mandatory reason and
  /// an audit row. The only movement with no bill behind it.
  adjust,

  /// Written against an [earn] when its bill is reopened. A re-close earns
  /// afresh rather than un-reversing this.
  reversal,
}

MemberPointKind? memberPointKindFromName(String? name) {
  if (name == null) return null;
  for (final k in MemberPointKind.values) {
    if (k.name == name) return k;
  }
  return null;
}

/// One immutable movement of a member's points balance.
class MemberPointEntry {
  final String id;
  final String memberId;
  final MemberPointKind kind;

  /// Signed points — positive earned, negative spent or reversed.
  final int delta;

  /// The visit behind it, on every kind but [MemberPointKind.adjust].
  final String? visitId;

  /// The bill figure an earn was computed from (net of discount, excluding
  /// service and tax). Kept so a balance can be explained later without
  /// re-deriving it against a rate that may since have changed.
  final int baseAmount;
  final String? note;
  final String? actorUserId;

  /// Attribution frozen at write time, so a later rename cannot rewrite it.
  final String? actorName;
  final DateTime at;

  const MemberPointEntry({
    required this.id,
    required this.memberId,
    required this.kind,
    required this.delta,
    required this.at,
    this.visitId,
    this.baseAmount = 0,
    this.note,
    this.actorUserId,
    this.actorName,
  });
}

/// A member as a reader sees them — the record plus the two derived figures
/// nothing stores: the points balance and the punch card's progress.
class Member {
  final String id;
  final String name;

  /// Digits only, normalised at write time so `0812…`, `+62812…` and `62812…`
  /// cannot become three people.
  final String phone;

  /// Short code printed on the receipt and read back over the counter. Display
  /// only — [phone] is the key.
  final String code;
  final String? note;

  /// Date only. Feeds the directory's "ulang tahun bulan ini" filter and
  /// nothing else — there is deliberately no birthday rules engine.
  final DateTime? birthday;
  final DateTime joinedAt;

  /// `SUM(delta)` over the ledger. **Derived, never stored** — money must not
  /// have two answers, exactly as in the petty cash box.
  final int points;

  /// Paid, non-voided, non-comped units of the venue's punch item bought since
  /// the last reward, derived from settled history. Zero when no program runs.
  final int punchProgress;

  /// Lifetime figures, read from snapshotted history rather than the live
  /// directory — a merged or anonymised past still counts.
  final int visitCount;
  final int lifetimeSpend;
  final DateTime? lastVisitAt;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinedAt,
    this.code = '',
    this.note,
    this.birthday,
    this.points = 0,
    this.punchProgress = 0,
    this.visitCount = 0,
    this.lifetimeSpend = 0,
    this.lastVisitAt,
  });
}

/// Strip a typed phone number to the digits that identify it.
///
/// `+62 813-3700-2244`, `0813 3700 2244` and `62 813 3700 2244` are one person,
/// and a directory that disagrees is a directory with three of them. Indonesian
/// numbers are normalised to the local `0…` form because that is what a cashier
/// reads off a guest's screen.
String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('620')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('62')) {
    digits = '0${digits.substring(2)}';
  }
  return digits;
}
