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

/// Which movement a [[Piutang]] row is (ADR-0098).
///
/// The name is **persisted** in `member_debts.kind` — same rule as above, never
/// rename one.
enum MemberDebtKind {
  /// Raised with the `piutang` payment that discharged a receipt. Positive.
  charge,

  /// A collection at the till, carrying its own method. Negative.
  payment,

  /// Written against a [charge] when the receipt that raised it is reopened.
  /// Automatic — reachable only while the visit still exists.
  reversal,

  /// Gave up collecting. Negative, mandatory reason, `refund` capability.
  writeOff,

  /// A hand correction. Exists because a snapshotted visit has no receipt left
  /// to reopen, so without it a typo could only be fixed by a [writeOff] —
  /// and the bad-debt figure would stop meaning "money we lost".
  adjust,
}

MemberDebtKind? memberDebtKindFromName(String? name) {
  if (name == null) return null;
  for (final k in MemberDebtKind.values) {
    if (k.name == name) return k;
  }
  return null;
}

/// One immutable movement of a member's [[Piutang]] balance.
class MemberDebtEntry {
  final String id;
  final String memberId;
  final MemberDebtKind kind;

  /// Signed rupiah — positive charged, negative collected or forgiven.
  final int delta;

  /// The payment that raised a [MemberDebtKind.charge]. The only join back to
  /// the bill that survives bill close.
  final String? paymentId;

  /// Table label frozen at write time, so a row names its bill after the visit
  /// is gone. Empty on anything but a charge.
  final String billLabel;

  /// Collection method on [MemberDebtKind.payment]; null otherwise.
  final String? method;
  final String? note;

  /// Whether a proof photo was stored — the bytes are fetched on demand, never
  /// carried in a list payload (ADR-0025).
  final bool hasPhoto;
  final String? actorName;
  final DateTime at;

  const MemberDebtEntry({
    required this.id,
    required this.memberId,
    required this.kind,
    required this.delta,
    required this.at,
    this.paymentId,
    this.billLabel = '',
    this.method,
    this.note,
    this.hasPhoto = false,
    this.actorName,
  });

  factory MemberDebtEntry.fromJson(Map<String, dynamic> j) => MemberDebtEntry(
    id: j['id'] as String? ?? '',
    memberId: j['memberId'] as String? ?? '',
    kind: memberDebtKindFromName(j['kind'] as String?) ?? MemberDebtKind.adjust,
    delta: (j['delta'] as num?)?.toInt() ?? 0,
    paymentId: j['paymentId'] as String?,
    billLabel: j['billLabel'] as String? ?? '',
    method: j['method'] as String?,
    note: j['note'] as String?,
    hasPhoto: j['hasPhoto'] as bool? ?? false,
    actorName: j['actorName'] as String?,
    at: DateTime.tryParse(j['at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );
}

/// A member's [[Piutang]] standing, as the till and the directory read it.
class MemberDebt {
  /// `SUM(delta)` — never stored, never negative.
  final int balance;

  /// Resolved limit: the member's own, or the venue default when they have
  /// none. `0` means no tab.
  final int limit;
  final List<MemberDebtEntry> entries;

  /// Null when the member's limit is the venue default rather than their own —
  /// what the editor needs to show an empty field instead of a copied number.
  final int? ownLimit;

  const MemberDebt({
    this.balance = 0,
    this.limit = 0,
    this.entries = const [],
    this.ownLimit,
  });

  /// What may still go on the tab. Never negative, so the till can compare it
  /// against an amount without guarding the sign.
  int get headroom => (limit - balance).clamp(0, limit);

  factory MemberDebt.fromJson(Map<String, dynamic> j) => MemberDebt(
    balance: (j['balance'] as num?)?.toInt() ?? 0,
    limit: (j['limit'] as num?)?.toInt() ?? 0,
    ownLimit: (j['ownLimit'] as num?)?.toInt(),
    entries: [
      for (final e in (j['entries'] as List? ?? const []))
        MemberDebtEntry.fromJson(e as Map<String, dynamic>),
    ],
  );
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

/// One member who owes, as the directory list and the report both read them.
class Debtor {
  final String memberId;
  final String name;
  final String phone;
  final int balance;

  /// When the oldest still-unsettled charge was raised — derived by walking the
  /// ledger FIFO, never stored. Null when nothing is outstanding.
  final DateTime? oldestUnpaidAt;
  final DateTime? lastPaymentAt;

  const Debtor({
    required this.memberId,
    required this.name,
    required this.balance,
    this.phone = '',
    this.oldestUnpaidAt,
    this.lastPaymentAt,
  });

  /// How long the oldest unsettled charge has been standing. Null when nothing
  /// is — the caller compares this against the venue's overdue setting, which
  /// is a credit policy rather than a fact.
  int? ageInDaysAt(DateTime now) => oldestUnpaidAt == null
      ? null
      : now.difference(oldestUnpaidAt!).inDays.clamp(0, 99999);

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'name': name,
    'phone': phone,
    'balance': balance,
    'oldestUnpaidAt': oldestUnpaidAt?.toIso8601String(),
    'lastPaymentAt': lastPaymentAt?.toIso8601String(),
  };

  factory Debtor.fromJson(Map<String, dynamic> j) => Debtor(
    memberId: j['memberId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    balance: (j['balance'] as num?)?.toInt() ?? 0,
    oldestUnpaidAt: DateTime.tryParse(
      j['oldestUnpaidAt'] as String? ?? '',
    )?.toLocal(),
    lastPaymentAt: DateTime.tryParse(
      j['lastPaymentAt'] as String? ?? '',
    )?.toLocal(),
  );
}

/// Where a [[Pelanggan (member)]] lives, as far as anyone here cares.
///
/// **Record-keeping only.** Nothing searches an address, groups by one, reports
/// on one or prints one on a slip — which is why it is four optional fields on
/// the person rather than an entity with a table of its own.
///
/// The three administrative levels hold a **name**, snapshotted at write time,
/// never a Kemendagri wilayah code: the picker's vocabulary is bundled and may
/// be replaced, and a stored code would let that replacement rewrite a record
/// somebody already saved. Nothing joins on these.
///
/// **Any prefix is legal** — [kabupaten] alone is a valid, useful answer. The
/// whole thing empty is the normal case.
class MemberAddress {
  /// Picked from the bundled Sulawesi Utara vocabulary. Empty for a guest from
  /// anywhere else, whose address lives entirely in [text].
  final String? kabupaten;
  final String? kecamatan;
  final String? kelurahan;

  /// The street line **only** — `Jl. Sam Ratulangi No. 12`. Never a repeat of
  /// the three above; two spellings of one fact is one fact too many.
  final String? text;

  const MemberAddress({
    this.kabupaten,
    this.kecamatan,
    this.kelurahan,
    this.text,
  });

  bool get isEmpty =>
      (kabupaten ?? '').isEmpty &&
      (kecamatan ?? '').isEmpty &&
      (kelurahan ?? '').isEmpty &&
      (text ?? '').isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Street first, then outward — how an Indonesian address is read aloud and
  /// how it would be written on an envelope. Levels the guest did not give are
  /// simply absent; there is no placeholder for an unknown kecamatan.
  String get oneLine => [
    if ((text ?? '').isNotEmpty) text!,
    if ((kelurahan ?? '').isNotEmpty) 'Kel. $kelurahan',
    if ((kecamatan ?? '').isNotEmpty) 'Kec. $kecamatan',
    if ((kabupaten ?? '').isNotEmpty) kabupaten!,
  ].join(', ');

  Map<String, dynamic> toJson() => {
    'kabupaten': kabupaten,
    'kecamatan': kecamatan,
    'kelurahan': kelurahan,
    'text': text,
  };

  static String? _clean(Object? v) {
    final s = (v as String?)?.trim() ?? '';
    return s.isEmpty ? null : s;
  }

  factory MemberAddress.fromJson(Map<String, dynamic> j) => MemberAddress(
    kabupaten: _clean(j['kabupaten']),
    kecamatan: _clean(j['kecamatan']),
    kelurahan: _clean(j['kelurahan']),
    text: _clean(j['text']),
  );

  MemberAddress copyWith({
    Object? kabupaten = _keep,
    Object? kecamatan = _keep,
    Object? kelurahan = _keep,
    Object? text = _keep,
  }) => MemberAddress(
    kabupaten: kabupaten == _keep ? this.kabupaten : kabupaten as String?,
    kecamatan: kecamatan == _keep ? this.kecamatan : kecamatan as String?,
    kelurahan: kelurahan == _keep ? this.kelurahan : kelurahan as String?,
    text: text == _keep ? this.text : text as String?,
  );

  /// Sentinel, because every field here is nullable and `null` therefore has to
  /// mean "clear it" rather than "leave it".
  static const _keep = Object();
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

  /// Optional and usually empty. Rides every payload the directory and the till
  /// share, but only the directory draws it — a bill overlay is for settling,
  /// and an address there is a line between the cashier and the total.
  final MemberAddress address;
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

  /// `SUM(delta)` over the [[Piutang]] ledger — derived like [points], never
  /// stored, never negative. Zero when the venue runs no tabs.
  final int debt;

  /// Resolved credit limit: this member's own if they have one, otherwise the
  /// venue default. `0` means no tab. Carried on the list row so the till can
  /// show remaining credit without a second call.
  final int debtLimit;

  /// This member's *own* limit, null when they inherit the venue default —
  /// what the editor needs to show an empty field rather than a copy.
  final int? ownDebtLimit;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinedAt,
    this.code = '',
    this.note,
    this.birthday,
    this.address = const MemberAddress(),
    this.points = 0,
    this.punchProgress = 0,
    this.visitCount = 0,
    this.lifetimeSpend = 0,
    this.lastVisitAt,
    this.debt = 0,
    this.debtLimit = 0,
    this.ownDebtLimit,
  });

  /// What may still go on the tab. Never negative.
  int get debtHeadroom => (debtLimit - debt).clamp(0, debtLimit);
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
